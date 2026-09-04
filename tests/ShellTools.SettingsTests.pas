//**************************************************************************************************
//
// Unit ShellTools.SettingsTests
// Shared unit for the Delphi Dev Shell Tools
// https://github.com/RRUZ/delphi-dev-shell-tools
//
// The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy of the
// License at http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
// ANY KIND, either express or implied. See the License for the specific language governing rights
// and limitations under the License.
//
// The Original Code is ShellTools.SettingsTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.SettingsTests;

interface

uses DUnitX.TestFramework;

type
  [TestFixture]
  TSettingsTests = class
  private
    FRoot, FLegacy, FConfig: string;
    procedure WriteLegacy(const Versions: string = '<ROW Version="8" Name="RAD Studio 2010"/>');
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure MigrationPreservesCustomizationAndBackup;
    [Test] procedure AmbiguousAndMissingVersionAssignmentsRequireReview;
    [Test] procedure DuplicateLegacyIDsRequireReview;
    [Test] procedure ExplicitResolutionUsesStableIDs;
    [Test] procedure ConcurrentMigrationIsRepeatable;
    [Test] procedure AtomicSavePreservesBackupAndRejectsStaleChanges;
    [Test] procedure CorruptAndFutureSettingsAreNotOverwritten;
    [Test] procedure BrokenLegacyFilesRemainRecoverable;
    [Test] procedure MissingLegacyFilesCreateUsableSettings;
    [Test] procedure CancelledEditsDoNotPersist;
    [Test] procedure StableVersionIDsAreUnique;
  end;

implementation

uses System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Threading,
  System.Generics.Collections, Winapi.ActiveX, System.Win.ComObj, Datasnap.DBClient,
  DelphiDevShellTools.SettingsStore, DelphiDevShellTools.DelphiVersions;

procedure TSettingsTests.Setup;
begin
  FRoot := TPath.GetTempPath + 'DDS-Settings-' + TGUID.NewGuid.ToString;
  FLegacy := FRoot + '\legacy';
  FConfig := FRoot + '\user';
  ForceDirectories(FLegacy + '\ico');
end;

procedure TSettingsTests.TearDown;
begin
  if DirectoryExists(FRoot) then TDirectory.Delete(FRoot, True);
end;

procedure TSettingsTests.WriteLegacy(const Versions: string);
begin
  TFile.WriteAllText(FLegacy + '\Settings.ini', '[Global]'#13#10'ShowInfoDProj=0'#13#10'CustomFlag=keep'#13#10, TEncoding.UTF8);
  TFile.WriteAllText(FLegacy + '\DelphiVersions.db', '<DATAPACKET><ROWDATA>' + Versions + '</ROWDATA></DATAPACKET>', TEncoding.UTF8);
  TFile.WriteAllText(FLegacy + '\Tools.db', '<?xml version="1.0" encoding="utf-8"?><DATAPACKET><ROWDATA>' +
    '<ROW Name="' + #$65E5#$672C + ' tool" Group="Delphi Tools" Menu="My tool" Extensions=".pas" Script="echo %PATH%! &amp; ^ ( ) &#xD;&#xA;echo ' + #$65E5#$672C + '" DelphiVersion="8" RunAs="TRUE" Image="custom.ico"/>' +
    '<ROW Name="Other" Group="External Tools" Menu="Other" Extensions=".pas" Script="echo keep" RunAs="FALSE" Image="custom.ico"/>' +
    '</ROWDATA></DATAPACKET>', TEncoding.UTF8);
  TFile.WriteAllBytes(FLegacy + '\ico\custom.ico', TBytes.Create(0, 1, 2, 255));
  TFile.WriteAllText(FLegacy + '\macros.xml', '<Macros/>');
end;

procedure TSettingsTests.MigrationPreservesCustomizationAndBackup;
var Doc, Command: TJSONObject; Backup, Original: string;
begin
  WriteLegacy;
  Original := TFile.ReadAllText(FLegacy + '\Tools.db');
  Doc := LoadConfiguration(FConfig, FLegacy);
  try
    Backup := Doc.GetValue<string>('legacyBackup');
    Assert.AreEqual(Original, TFile.ReadAllText(Backup + '\Tools.db'));
    Assert.AreEqual(Original, TFile.ReadAllText(FLegacy + '\Tools.db'));
    Assert.IsTrue(TFile.ReadAllBytes(Backup + '\ico\custom.ico')[3] = 255);
    Assert.IsTrue(TFile.ReadAllBytes(FConfig + '\ico\custom.ico')[3] = 255);
    Assert.AreEqual('keep', Doc.GetValue<TJSONObject>('settings').GetValue<string>('CustomFlag'));
    Command := Doc.GetValue<TJSONArray>('commands').Items[0] as TJSONObject;
    Assert.AreEqual(#$65E5#$672C + ' tool', Command.GetValue<string>('name'));
    Assert.AreEqual('echo %PATH%! & ^ ( ) '#13#10'echo ' + #$65E5#$672C, Command.GetValue<string>('script'));
    Assert.IsTrue(Command.GetValue<Boolean>('runAs'));
    Assert.AreEqual('delphi:2010', Command.GetValue<string>('versionId'));
    Assert.AreEqual('', Command.GetValue<string>('review'));
  finally
    Doc.Free;
  end;
end;

procedure TSettingsTests.AmbiguousAndMissingVersionAssignmentsRequireReview;
var Doc, Command: TJSONObject; Data: TClientDataSet;
begin
  WriteLegacy('<ROW Version="8" Name="RAD Studio XE6"/>');
  Doc := LoadConfiguration(FConfig, FLegacy);
  Data := TClientDataSet.Create(nil);
  try
    Command := Doc.GetValue<TJSONArray>('commands').Items[0] as TJSONObject;
    Assert.AreEqual('', Command.GetValue<string>('versionId'));
    Assert.IsTrue(Command.GetValue<string>('review') <> '');
    LoadTools(Data, Doc);
    Assert.IsFalse(CommandAllowsVersion(Data, Delphi13Florence));
    // The known historical conflict: catalogue 14 = XE6, enum 14 = Appmethod.
    Assert.AreEqual('appmethod:1.13', DelphiVersionID(TDelphiVersions(14)));
    Assert.AreEqual('delphi:xe6', DelphiVersionID(DelphiXE6));
  finally
    Data.Free;
    Doc.Free;
  end;
  Doc := LoadConfiguration(FRoot + '\missing-map', FRoot + '\empty');
  try
    Assert.AreEqual<Integer>(0, Doc.GetValue<TJSONArray>('commands').Count);
  finally
    Doc.Free;
  end;
end;

procedure TSettingsTests.DuplicateLegacyIDsRequireReview;
var Doc: TJSONObject;
begin
  WriteLegacy('<ROW Version="8" Name="RAD Studio 2010"/><ROW Version="8" Name="RAD Studio 2010"/>');
  Doc := LoadConfiguration(FConfig, FLegacy);
  try
    Assert.IsTrue((Doc.GetValue<TJSONArray>('commands').Items[0] as TJSONObject).GetValue<string>('review') <> '');
  finally
    Doc.Free;
  end;
end;

procedure TSettingsTests.ExplicitResolutionUsesStableIDs;
var Doc, Saved: TJSONObject; Data: TClientDataSet; ID: string;
begin
  WriteLegacy('');
  Doc := LoadConfiguration(FConfig, FLegacy);
  Data := TClientDataSet.Create(nil);
  try
    LoadTools(Data, Doc);
    Assert.IsFalse(CommandAllowsVersion(Data, Delphi13Florence));
    ID := Data.FieldByName('Id').AsString;
    Data.Edit;
    Data.FieldByName('VersionId').AsString := 'delphi:12';
    Data.FieldByName('Name').AsString := 'Renamed';
    Data.Post;
    StoreTools(Data, Doc);
    SaveConfiguration(FConfig, Doc);
    Saved := LoadConfiguration(FConfig, FLegacy);
    try
      LoadTools(Data, Saved);
      Assert.AreEqual(ID, Data.FieldByName('Id').AsString);
      Assert.IsFalse(CommandAllowsVersion(Data, Delphi11Alexandria));
      Assert.IsTrue(CommandAllowsVersion(Data, Delphi12Athens));
      Assert.AreEqual('', Data.FieldByName('Review').AsString);
      Assert.IsTrue((Saved.GetValue<TJSONArray>('commands').Items[0] as TJSONObject).GetValue<Boolean>('runAs'));
    finally
      Saved.Free;
    end;
  finally
    Data.Free;
    Doc.Free;
  end;
end;

procedure TSettingsTests.ConcurrentMigrationIsRepeatable;
var First, Second: ITask; JobA, JobB: TProc; A, B, Original: string; Doc: TJSONObject;
begin
  WriteLegacy;
  JobA := procedure
    var Value: TJSONObject;
    begin
      OleCheck(CoInitialize(nil));
      try
        Value := LoadConfiguration(FConfig, FLegacy);
        try A := Value.ToJSON; finally Value.Free; end;
      finally CoUninitialize; end;
    end;
  JobB := procedure
    var Value: TJSONObject;
    begin
      OleCheck(CoInitialize(nil));
      try
        Value := LoadConfiguration(FConfig, FLegacy);
        try B := Value.ToJSON; finally Value.Free; end;
      finally CoUninitialize; end;
    end;
  First := TTask.Run(JobA);
  Second := TTask.Run(JobB);
  TTask.WaitForAll([First, Second]);
  Assert.AreEqual(A, B);
  Original := TFile.ReadAllText(FConfig + '\settings.json');
  TFile.WriteAllText(FLegacy + '\Tools.db', 'changed after migration');
  Doc := LoadConfiguration(FConfig, FLegacy);
  try Assert.AreEqual(A, Doc.ToJSON); finally Doc.Free; end;
  Assert.AreEqual(Original, TFile.ReadAllText(FConfig + '\settings.json'));
  Assert.AreEqual<Integer>(1, Length(TDirectory.GetDirectories(FConfig, 'legacy-backup-*')));
end;

procedure TSettingsTests.AtomicSavePreservesBackupAndRejectsStaleChanges;
var A, B: TJSONObject; Original, Updated: string;
begin
  WriteLegacy;
  A := LoadConfiguration(FConfig, FLegacy);
  B := LoadConfiguration(FConfig, FLegacy);
  try
    Original := TFile.ReadAllText(FConfig + '\settings.json');
    PutJSON(A.GetValue<TJSONObject>('settings'), 'CustomFlag', TJSONString.Create('edited'));
    SaveConfiguration(FConfig, A);
    Updated := TFile.ReadAllText(FConfig + '\settings.json');
    Assert.AreEqual(Original, TFile.ReadAllText(FConfig + '\settings.json.bak'));
    Assert.WillRaise(procedure begin SaveConfiguration(FConfig, B); end, EInOutError);
    Assert.AreEqual(Updated, TFile.ReadAllText(FConfig + '\settings.json'));
    Assert.AreEqual<Integer>(0, Length(TDirectory.GetFiles(FConfig, '*.tmp')));
  finally
    A.Free;
    B.Free;
  end;
end;

procedure TSettingsTests.CorruptAndFutureSettingsAreNotOverwritten;
var Doc: TJSONObject; Name: string;
begin
  WriteLegacy;
  Doc := LoadConfiguration(FConfig, FLegacy);
  Doc.Free;
  Name := FConfig + '\settings.json';
  TFile.WriteAllText(Name, 'broken');
  Assert.WillRaise(procedure begin LoadConfiguration(FConfig, FLegacy).Free; end, EConvertError);
  Assert.AreEqual('broken', TFile.ReadAllText(Name));
  TFile.WriteAllText(Name, '{"schemaVersion":99}');
  Assert.WillRaise(procedure begin LoadConfiguration(FConfig, FLegacy).Free; end, EConvertError);
  Assert.AreEqual('{"schemaVersion":99}', TFile.ReadAllText(Name));
end;

procedure TSettingsTests.BrokenLegacyFilesRemainRecoverable;
var Backups: TArray<string>;
begin
  WriteLegacy;
  TFile.WriteAllText(FLegacy + '\Tools.db', '<broken');
  Assert.WillRaise(procedure begin LoadConfiguration(FConfig, FLegacy).Free; end, EConvertError);
  Assert.IsFalse(FileExists(FConfig + '\settings.json'));
  Backups := TDirectory.GetDirectories(FConfig, 'legacy-backup-*');
  Assert.AreEqual<Integer>(1, Length(Backups));
  Assert.AreEqual('<broken', TFile.ReadAllText(Backups[0] + '\Tools.db'));
end;

procedure TSettingsTests.MissingLegacyFilesCreateUsableSettings;
var Doc: TJSONObject;
begin
  Doc := LoadConfiguration(FConfig, FLegacy);
  try
    Assert.AreEqual(1, Doc.GetValue<Integer>('schemaVersion'));
    Assert.AreEqual<Integer>(0, Doc.GetValue<TJSONArray>('commands').Count);
    Assert.IsTrue(DirectoryExists(FConfig + '\ico'));
    SaveConfiguration(FConfig, Doc);
  finally
    Doc.Free;
  end;
end;

procedure TSettingsTests.CancelledEditsDoNotPersist;
var Doc: TJSONObject; Data: TClientDataSet; Original: string;
begin
  WriteLegacy;
  Doc := LoadConfiguration(FConfig, FLegacy);
  Data := TClientDataSet.Create(nil);
  try
    Original := TFile.ReadAllText(FConfig + '\settings.json');
    LoadTools(Data, Doc);
    Data.Edit;
    Data.FieldByName('Script').AsString := 'unsaved';
    Data.Post;
    Assert.AreEqual(Original, TFile.ReadAllText(FConfig + '\settings.json'));
  finally
    Data.Free;
    Doc.Free;
  end;
end;

procedure TSettingsTests.StableVersionIDsAreUnique;
var Version, Decoded: TDelphiVersions; IDs: TDictionary<string, Boolean>;
begin
  IDs := TDictionary<string, Boolean>.Create;
  try
    for Version := Low(TDelphiVersions) to High(TDelphiVersions) do
    begin
      Assert.IsFalse(IDs.ContainsKey(DelphiVersionID(Version)));
      IDs.Add(DelphiVersionID(Version), True);
      Assert.IsTrue(TryDelphiVersionID(DelphiVersionID(Version), Decoded));
      Assert.AreEqual(Ord(Version), Ord(Decoded));
    end;
    Assert.IsFalse(TryDelphiVersionID('14', Decoded));
  finally
    IDs.Free;
  end;
end;

end.
