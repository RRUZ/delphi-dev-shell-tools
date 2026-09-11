//**************************************************************************************************
//
// Unit ShellTools.SettingsModelTests
// Tests custom-tool selection and editing against isolated copies of the legacy fixtures.
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
// The Original Code is ShellTools.SettingsModelTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.SettingsModelTests;

interface

uses
  DUnitX.TestFramework, System.JSON, Datasnap.DBClient, Data.DB,
  DelphiDevShellTools.GUI.SettingsModel;

type
  [TestFixture]
  TSettingsModelTests = class
  private
    FRoot: string;
    FDocument: TJSONObject;
    FTools, FVersions: TClientDataSet;
    FModel: TSettingsToolsModel;
    procedure CreateModel;
    procedure RejectPost(ADataSet: TDataSet);
    procedure SetFirstReview(const AReview, AVersion: string);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure SelectingEveryCopiedToolSavesWithoutError;
    [Test] procedure EditsRoundTripWithoutChangingIdentity;
    [Test] procedure ModelCanToggleEnabledWhileReviewStaysReadOnly;
    [Test] procedure OrdinaryEditPreservesUnresolvedReview;
    [Test] procedure ChoosingValidVersionResolvesAssignment;
    [Test] procedure DisabledCommandStaysDisabledAfterVersionChange;
    [Test] procedure FailedPostRollsBackEveryField;
    [Test] procedure StaleEditorCannotOverwriteAnotherTool;
    [Test] procedure ReadViewAndSavePreserveSelection;
    [Test] procedure CancelLeavesSnapshotAndFixtureUnchanged;
    [Test] procedure AppendDeleteAndEmptyState;
    [Test] procedure SavePreservesUnknownCommandMetadata;
    [Test] procedure IconAndVersionChoicesAreCompleteAndUnique;
    [TestCase('Blank', '')]
    [TestCase('Unknown', 'delphi:999')]
    procedure InvalidVersionCannotValidate(const AVersion: string);
    [Test] procedure ExtensionChipsRoundTrip;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DelphiDevShellTools.SettingsStore, DelphiDevShellTools.Icons;

procedure TSettingsModelTests.Setup;
begin
  FRoot := TPath.Combine(TPath.GetTempPath, 'DDS-Model-' + TGUID.NewGuid.ToString);
  ForceDirectories(FRoot + '\legacy');
  var LFixture := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) +
    '..\..\fixtures\CustomTools');
  for var LName in ['Tools.db', 'DelphiVersions.db', 'Settings.ini', 'macros.xml'] do
    TFile.Copy(TPath.Combine(LFixture, LName), FRoot + '\legacy\' + LName);
  FDocument := LoadConfiguration(FRoot + '\config', FRoot + '\legacy');
  FTools := TClientDataSet.Create(nil);
  FVersions := TClientDataSet.Create(nil);
end;

procedure TSettingsModelTests.TearDown;
begin
  FModel.Free;
  FModel := nil;
  FVersions.Free;
  FTools.Free;
  FDocument.Free;
  if DirectoryExists(FRoot) then
    TDirectory.Delete(FRoot, True);
end;

procedure TSettingsModelTests.CreateModel;
begin
  FModel := TSettingsToolsModel.Create(FTools, FVersions, FDocument);
end;

procedure TSettingsModelTests.SetFirstReview(const AReview, AVersion: string);
begin
  var LCommand := FDocument.GetValue<TJSONArray>('commands').Items[0] as TJSONObject;
  LCommand.RemovePair('review').Free;
  LCommand.AddPair('review', AReview);
  LCommand.RemovePair('versionId').Free;
  LCommand.AddPair('versionId', AVersion);
end;

procedure TSettingsModelTests.SelectingEveryCopiedToolSavesWithoutError;
begin
  CreateModel;
  Assert.AreEqual(14, FModel.Count);
  Assert.AreEqual('Formatter Delphi', FModel.Current.Name);
  for var LPass := 1 to 3 do
    for var LIndex := 0 to FModel.Count - 1 do
    begin
      // ToolListChange saves the previous editor before moving its dataset.
      FModel.UpdateCurrent(FModel.Current);
      var LExpected := FModel.ItemAt(LIndex);
      FModel.SelectIndex(LIndex);
      Assert.AreEqual(LExpected.Id, FModel.Current.Id);
      Assert.AreEqual(LIndex, FModel.SelectedIndex);
    end;
  FModel.SelectIndex(2);
  Assert.AreEqual('ppdep', FModel.Current.Name);
end;

procedure TSettingsModelTests.EditsRoundTripWithoutChangingIdentity;
begin
  CreateModel;
  var LValue := FModel.Current;
  var LId := LValue.Id;
  LValue.Name := 'Unicode ' + #$65E5#$672C;
  LValue.GroupName := 'External Tools';
  LValue.MenuLabel := 'Test $NAME$';
  LValue.Extensions := '.pas,.dpr';
  LValue.Script := 'echo %PATH% & ^ !'#13#10'pause';
  LValue.ImageKey := 'wrench';
  LValue.VersionId := '*';
  LValue.RunAsAdministrator := True;
  FModel.UpdateCurrent(LValue);
  FModel.SelectIndex(2);
  FModel.SelectIndex(0);
  Assert.AreEqual(LValue.Name, FModel.Current.Name);
  Assert.AreEqual(LValue.Script, FModel.Current.Script);
  Assert.AreEqual(LId, FModel.Current.Id);
  Assert.IsTrue(FModel.Current.RunAsAdministrator);
  FModel.Save(FDocument);
  var LSaved := FDocument.GetValue<TJSONArray>('commands').Items[0] as TJSONObject;
  Assert.AreEqual(LValue.Script, LSaved.GetValue<string>('script'));
  Assert.AreEqual(LValue.ImageKey, LSaved.GetValue<string>('image'));
end;

procedure TSettingsModelTests.ModelCanToggleEnabledWhileReviewStaysReadOnly;
begin
  CreateModel;
  var LValue := FModel.Current;
  LValue.Enabled := False;
  FModel.UpdateCurrent(LValue);
  Assert.AreEqual(cDisabledCommandReview, FModel.Current.Review);
  Assert.IsTrue(FTools.FieldByName('Review').ReadOnly);
  LValue := FModel.Current;
  LValue.Enabled := True;
  FModel.UpdateCurrent(LValue);
  Assert.IsTrue(FModel.Current.Enabled);
  Assert.AreEqual('', FModel.Current.Review);
  Assert.IsTrue(FTools.FieldByName('Review').ReadOnly);
end;

procedure TSettingsModelTests.OrdinaryEditPreservesUnresolvedReview;
begin
  SetFirstReview('Resolve legacy version conflict', '');
  CreateModel;
  var LValue := FModel.Current;
  LValue.Name := 'Renamed unresolved command';
  FModel.UpdateCurrent(LValue);
  Assert.AreEqual('Resolve legacy version conflict', FModel.Current.Review);
  Assert.IsFalse(FModel.Current.Enabled);
end;

procedure TSettingsModelTests.ChoosingValidVersionResolvesAssignment;
begin
  SetFirstReview('Resolve legacy version conflict', '');
  CreateModel;
  var LValue := FModel.Current;
  LValue.VersionId := 'delphi:13';
  FModel.UpdateCurrent(LValue);
  Assert.AreEqual('', FModel.Current.Review);
  Assert.IsTrue(FModel.Current.Enabled);
  Assert.AreEqual('', TSettingsToolsModel.Validate(FModel.Current));
end;

procedure TSettingsModelTests.DisabledCommandStaysDisabledAfterVersionChange;
begin
  SetFirstReview(cDisabledCommandReview, '*');
  CreateModel;
  var LValue := FModel.Current;
  LValue.VersionId := 'delphi:13';
  FModel.UpdateCurrent(LValue);
  FModel.Save(FDocument);
  Assert.AreEqual(cDisabledCommandReview,
    (FDocument.GetValue<TJSONArray>('commands').Items[0] as TJSONObject).GetValue<string>('review'));
end;

procedure TSettingsModelTests.RejectPost(ADataSet: TDataSet);
begin
  raise EDatabaseError.Create('Injected post failure');
end;

procedure TSettingsModelTests.FailedPostRollsBackEveryField;
begin
  CreateModel;
  var LBefore := FModel.Current;
  var LValue := LBefore;
  LValue.Name := 'Must roll back';
  LValue.Enabled := False;
  FTools.BeforePost := RejectPost;
  Assert.WillRaise(procedure begin FModel.UpdateCurrent(LValue); end, EDatabaseError);
  FTools.BeforePost := nil;
  Assert.IsTrue(FTools.State = dsBrowse);
  Assert.AreEqual(LBefore.Name, FModel.Current.Name);
  Assert.AreEqual(LBefore.Review, FModel.Current.Review);
  Assert.IsTrue(FTools.FieldByName('Review').ReadOnly);
  FModel.SelectIndex(2);
  Assert.AreEqual('ppdep', FModel.Current.Name);
end;

procedure TSettingsModelTests.StaleEditorCannotOverwriteAnotherTool;
begin
  CreateModel;
  var LStale := FModel.Current;
  FModel.SelectIndex(2);
  Assert.WillRaise(procedure begin FModel.UpdateCurrent(LStale); end, EDatabaseError);
  Assert.AreEqual('ppdep', FModel.Current.Name);
end;

procedure TSettingsModelTests.ReadViewAndSavePreserveSelection;
begin
  CreateModel;
  FModel.SelectIndex(2);
  for var LIndex := 0 to FModel.Count - 1 do
    Assert.IsTrue(FModel.ItemAt(LIndex).Id <> '');
  FModel.HasReviews;
  Assert.AreEqual(2, FModel.SelectedIndex);
  FModel.Save(FDocument);
  Assert.AreEqual(2, FModel.SelectedIndex);
  Assert.AreEqual('ppdep', FModel.Current.Name);
end;

procedure TSettingsModelTests.CancelLeavesSnapshotAndFixtureUnchanged;
begin
  var LBefore := FDocument.ToJSON;
  var LDatabase := TFile.ReadAllText(FRoot + '\legacy\Tools.db');
  CreateModel;
  var LValue := FModel.Current;
  LValue.Name := 'Unsaved name';
  FModel.UpdateCurrent(LValue);
  Assert.AreEqual(LBefore, FDocument.ToJSON);
  Assert.AreEqual(LDatabase, TFile.ReadAllText(FRoot + '\legacy\Tools.db'));
  var LReload := LoadConfiguration(FRoot + '\config', FRoot + '\legacy');
  try
    Assert.AreEqual(LBefore, LReload.ToJSON);
  finally
    LReload.Free;
  end;
end;

procedure TSettingsModelTests.AppendDeleteAndEmptyState;
begin
  CreateModel;
  FModel.Append;
  Assert.AreEqual(15, FModel.Count);
  Assert.IsTrue(FModel.Current.Id.StartsWith('command:'));
  Assert.AreEqual('*', FModel.Current.VersionId);
  Assert.AreEqual('wrench', FModel.Current.ImageKey);
  FModel.DeleteCurrent;
  Assert.AreEqual(14, FModel.Count);
  while FModel.Count > 0 do FModel.DeleteCurrent;
  Assert.AreEqual(-1, FModel.SelectedIndex);
  Assert.AreEqual('', FModel.Current.Id);
  FModel.SelectIndex(100);
  FModel.DeleteCurrent;
  Assert.AreEqual('', FModel.ItemAt(0).Id);
  FModel.Append;
  Assert.AreEqual(0, FModel.SelectedIndex);
end;

procedure TSettingsModelTests.SavePreservesUnknownCommandMetadata;
begin
  var LCommand := FDocument.GetValue<TJSONArray>('commands').Items[0] as TJSONObject;
  LCommand.AddPair('futureProperty', 'keep me');
  CreateModel;
  var LValue := FModel.Current;
  LValue.Name := 'Renamed';
  FModel.UpdateCurrent(LValue);
  FModel.Save(FDocument);
  Assert.AreEqual('keep me',
    (FDocument.GetValue<TJSONArray>('commands').Items[0] as TJSONObject).GetValue<string>('futureProperty'));
end;

procedure TSettingsModelTests.IconAndVersionChoicesAreCompleteAndUnique;
var
  LDescriptor: TProjectIconDescriptor;
begin
  CreateModel;
  var LNames := TStringList.Create;
  try
    var LIds := TStringList.Create;
    try
      FModel.FillVersionItems(LNames, LIds);
      Assert.AreEqual(LNames.Count, LIds.Count);
      Assert.AreEqual('*', LIds[0]);
      Assert.IsTrue(LIds.IndexOf('delphi:13') >= 0);
      for var LIndex := 0 to LIds.Count - 1 do
        Assert.AreEqual(LIndex, LIds.IndexOf(LIds[LIndex]));
      FModel.FillIconItems(LNames);
      for var LIndex := 0 to LNames.Count - 1 do
      begin
        Assert.IsTrue(TryGetProjectIcon(LNames[LIndex], LDescriptor));
        Assert.AreEqual(LIndex, LNames.IndexOf(LNames[LIndex]));
      end;
      for var LIndex := 0 to FModel.Count - 1 do
        Assert.IsTrue(TryGetProjectIcon(FModel.ItemAt(LIndex).ImageKey, LDescriptor));
    finally
      LIds.Free;
    end;
  finally
    LNames.Free;
  end;
end;

procedure TSettingsModelTests.InvalidVersionCannotValidate(const AVersion: string);
begin
  CreateModel;
  var LValue := FModel.Current;
  LValue.VersionId := AVersion;
  Assert.IsTrue(TSettingsToolsModel.Validate(LValue) <> '');
end;

procedure TSettingsModelTests.ExtensionChipsRoundTrip;
begin
  var LExtensions := TSettingsToolsModel.SplitExtensions('pas; .dpr, inc');
  Assert.AreEqual('.pas,.dpr,.inc', TSettingsToolsModel.JoinExtensions(LExtensions));
  Assert.AreEqual<NativeInt>(0, Length(TSettingsToolsModel.SplitExtensions(' ,; ')));
end;

end.
