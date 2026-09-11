//**************************************************************************************************
//
// Unit DelphiDevShellTools.SettingsStore
// Versioned per-user settings, legacy migration and atomic persistence with recovery.
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
// The Original Code is DelphiDevShellTools.SettingsStore.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.SettingsStore;

interface

uses System.JSON, Datasnap.DBClient, DelphiDevShellTools.DelphiVersions;

const
  cDisabledCommandReview = 'Disabled by user.';

function UserSettingsDirectory: string;
function LegacySettingsDirectory: string;
function LoadConfiguration(const Directory, LegacyDirectory: string): TJSONObject;
function LoadUserConfiguration: TJSONObject;
procedure SaveConfiguration(const Directory: string; Document: TJSONObject);
procedure LoadTools(Data: TClientDataSet; Document: TJSONObject = nil);
procedure StoreTools(Data: TClientDataSet; Document: TJSONObject);
procedure LoadVersionChoices(Data: TClientDataSet);
function CommandAllowsVersion(Data: TClientDataSet; Version: TDelphiVersions): Boolean;
procedure PutJSON(Obj: TJSONObject; const Name: string; Value: TJSONValue);

implementation

uses Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.IniFiles,
  System.Variants, System.Win.ComObj, System.Win.Registry, System.Generics.Collections,
  Data.DB, MidasLib;

function UserSettingsDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA')) + 'DelphiDevShellTools\Config';
end;

function LegacySettingsDirectory: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('ProgramData')) + 'DelphiDevShellTools';
end;

procedure PutJSON(Obj: TJSONObject; const Name: string; Value: TJSONValue);
var Pair: TJSONPair;
begin
  Pair := Obj.RemovePair(Name);
  Pair.Free;
  Obj.AddPair(Name, Value);
end;

function LockConfiguration(const Directory: string): THandle;
var I: Integer; Code: Cardinal;
begin
  ForceDirectories(Directory);
  for I := 0 to 199 do
  begin
    Result := CreateFile(PChar(Directory + '\config.lock'), GENERIC_READ or GENERIC_WRITE,
      0, nil, OPEN_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
    if Result <> INVALID_HANDLE_VALUE then Exit;
    Code := GetLastError;
    if Code <> ERROR_SHARING_VIOLATION then RaiseLastOSError(Code);
    Sleep(10);
  end;
  raise EInOutError.Create('Settings are busy. Try again.');
end;

procedure Validate(Document: TJSONObject);
var Commands: TJSONArray; Value: TJSONValue; Obj: TJSONObject; IDs: TDictionary<string, Boolean>; ID: string;
begin
  if (Document = nil) or (Document.GetValue<Integer>('schemaVersion', 0) <> 1) then
    raise EConvertError.Create('Unsupported or damaged settings schema; the file was not changed.');
  if not (Document.GetValue('settings') is TJSONObject) or
     not (Document.GetValue('execution') is TJSONObject) or
     not (Document.GetValue('commands') is TJSONArray) then
    raise EConvertError.Create('Incomplete settings; restore settings.json.bak or the legacy backup.');
  Commands := Document.GetValue<TJSONArray>('commands');
  IDs := TDictionary<string, Boolean>.Create;
  try
    for Value in Commands do
    begin
      if not (Value is TJSONObject) then raise EConvertError.Create('Invalid command settings.');
      Obj := TJSONObject(Value);
      ID := Obj.GetValue<string>('id', '');
      if (ID = '') or IDs.ContainsKey(ID) then raise EConvertError.Create('Missing or duplicate command ID.');
      IDs.Add(ID, True);
      if not (Obj.GetValue('runAs') is TJSONBool) then raise EConvertError.Create('Invalid command elevation flag.');
      for ID in ['name', 'group', 'menu', 'extensions', 'script', 'image', 'versionId', 'review'] do
        if not (Obj.GetValue(ID) is TJSONString) then raise EConvertError.Create('Invalid command field: ' + ID);
    end;
  finally
    IDs.Free;
  end;
end;

function ReadDocument(const FileName: string): TJSONObject;
var Value: TJSONValue;
begin
  if TFile.GetSize(FileName) > 16 * 1024 * 1024 then raise EConvertError.Create('Settings exceed 16 MB.');
  Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName, TEncoding.UTF8));
  try
    if not (Value is TJSONObject) then raise EConvertError.Create('Damaged settings: ' + FileName + '. Restore the backup; this file was not changed.');
    Validate(TJSONObject(Value));
    Result := TJSONObject(Value);
    Value := nil;
  finally
    Value.Free;
  end;
end;

procedure WriteAtomic(const Directory: string; Document: TJSONObject);
var FileName, TempName, BackupTemp: string; Stream: TFileStream; Bytes: TBytes;
begin
  Validate(Document);
  FileName := Directory + '\settings.json';
  TempName := FileName + '.' + TGUID.NewGuid.ToString + '.tmp';
  BackupTemp := TempName + '.bak';
  try
    Bytes := TEncoding.UTF8.GetBytes(Document.Format(2) + #13#10);
    Stream := TFileStream.Create(TempName, fmCreate or fmShareExclusive);
    try
      if Length(Bytes) > 0 then Stream.WriteBuffer(Bytes[0], Length(Bytes));
      if not FlushFileBuffers(Stream.Handle) then RaiseLastOSError;
    finally
      Stream.Free;
    end;
    if FileExists(FileName) then
    begin
      TFile.Copy(FileName, BackupTemp);
      if not MoveFileEx(PChar(BackupTemp), PChar(FileName + '.bak'), MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then RaiseLastOSError;
    end;
    if not MoveFileEx(PChar(TempName), PChar(FileName), MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then RaiseLastOSError;
  finally
    if FileExists(TempName) then TFile.Delete(TempName);
    if FileExists(BackupTemp) then TFile.Delete(BackupTemp);
  end;
end;

procedure SaveConfiguration(const Directory: string; Document: TJSONObject);
var Lock: THandle; Current, Updated: TJSONObject; FileName, Revision: string;
begin
  Lock := LockConfiguration(Directory);
  try
    FileName := Directory + '\settings.json';
    if FileExists(FileName) then
    begin
      Current := ReadDocument(FileName);
      try
        if Current.GetValue<string>('revision', '') <> Document.GetValue<string>('revision', '') then
          raise EInOutError.Create('Settings changed in another window. Reopen Settings before saving.');
      finally
        Current.Free;
      end;
    end;
    Updated := Document.Clone as TJSONObject;
    try
      Revision := TGUID.NewGuid.ToString;
      PutJSON(Updated, 'revision', TJSONString.Create(Revision));
      WriteAtomic(Directory, Updated);
      PutJSON(Document, 'revision', TJSONString.Create(Revision));
    finally
      Updated.Free;
    end;
  finally
    CloseHandle(Lock);
  end;
end;

function LoadXML(const FileName: string): OleVariant;
begin
  Result := CreateOleObject('Msxml2.DOMDocument.6.0');
  Result.async := False;
  Result.resolveExternals := False;
  Result.setProperty('ProhibitDTD', True);
  if not Result.load(FileName) then raise EConvertError.Create('Cannot migrate ' + FileName + ': ' + VarToStr(Result.parseError.reason));
end;

procedure CopyLegacy(const Source, Target: string);
var Name, FileName, Relative: string;
begin
  ForceDirectories(Target);
  for Name in ['Settings.ini', 'Tools.db', 'DelphiVersions.db', 'macros.xml'] do
    if FileExists(Source + '\' + Name) then TFile.Copy(Source + '\' + Name, Target + '\' + Name, False);
  if DirectoryExists(Source + '\ico') then
    for FileName in TDirectory.GetFiles(Source + '\ico', '*', TSearchOption.soAllDirectories) do
    begin
      Relative := Copy(FileName, Length(ExcludeTrailingPathDelimiter(Source)) + 2, MaxInt);
      ForceDirectories(ExtractFileDir(Target + '\' + Relative));
      TFile.Copy(FileName, Target + '\' + Relative, False);
    end;
end;

function Migrate(const Directory, LegacyDirectory: string): TJSONObject;
var Backup, Name, LabelText, VersionID, Review, FileName: string;
  Ini: TMemIniFile; Keys: TStringList; Globals, Command, Execution: TJSONObject;
  Commands: TJSONArray; XML, Rows, Row: OleVariant; I, Number: Integer;
  Labels: TDictionary<Integer, string>; Version: TDelphiVersions; Registry: TRegistry;
begin
  Backup := Directory + '\legacy-backup-' + TGUID.NewGuid.ToString;
  CopyLegacy(LegacyDirectory, Backup);
  Result := TJSONObject.Create;
  Labels := TDictionary<Integer, string>.Create;
  try
    Result.AddPair('schemaVersion', TJSONNumber.Create(1));
    Result.AddPair('revision', TGUID.NewGuid.ToString);
    Result.AddPair('legacyBackup', Backup);
    Globals := TJSONObject.Create;
    Result.AddPair('settings', Globals);
    Ini := TMemIniFile.Create(Backup + '\Settings.ini');
    Keys := TStringList.Create;
    try
      Ini.ReadSection('Global', Keys);
      for Name in Keys do
        if not SameText(Name, 'CheckForUpdates') then
          Globals.AddPair(Name, Ini.ReadString('Global', Name, ''));
    finally
      Keys.Free;
      Ini.Free;
    end;
    if Globals.GetValue('CommonTaskExt') = nil then Globals.AddPair('CommonTaskExt', '.pas,.dpr,.dproj,.groupproj,.dfm,.fmx,.rc');
    if Globals.GetValue('OpenDelphiExt') = nil then Globals.AddPair('OpenDelphiExt', '.pas,.dpr,.dproj,.groupproj,.inc,.dpk');
    if Globals.GetValue('OpenLazarusExt') = nil then Globals.AddPair('OpenLazarusExt', '.lpi,.lpr,.pas');
    if Globals.GetValue('CheckSumExt') = nil then Globals.AddPair('CheckSumExt', '.pas,.dpr,.dproj,.exe,.dll');
    Execution := TJSONObject.Create;
    Result.AddPair('execution', Execution);
    // Import the earlier per-user preference once; future writes use JSON only.
    Registry := TRegistry.Create(KEY_READ);
    try
      Registry.RootKey := HKEY_CURRENT_USER;
      if Registry.OpenKeyReadOnly('Software\DelphiDevShellTools\Execution') then
      begin
        if Registry.ValueExists('PreferredInstallation') then
          Execution.AddPair('preferredInstallation', Registry.ReadString('PreferredInstallation'));
        Name := 'automatic';
        if Registry.ValueExists('PreferredVariant') then
          case Registry.ReadInteger('PreferredVariant') of
            1: Name := 'win32';
            2: Name := 'win64';
          end;
        Execution.AddPair('preferredVariant', Name);
      end;
    finally
      Registry.Free;
    end;
    FileName := Backup + '\DelphiVersions.db';
    if FileExists(FileName) then
    begin
      XML := LoadXML(FileName);
      Rows := XML.selectNodes('/DATAPACKET/ROWDATA/ROW');
      for I := 0 to Rows.length - 1 do
      begin
        Row := Rows.item(I);
        if not TryStrToInt(VarToStr(Row.getAttribute('Version')), Number) then Continue;
        LabelText := VarToStr(Row.getAttribute('Name'));
        if Labels.ContainsKey(Number) then LabelText := ''; // Duplicate IDs are ambiguous.
        Labels.AddOrSetValue(Number, LabelText);
      end;
    end;
    Commands := TJSONArray.Create;
    Result.AddPair('commands', Commands);
    FileName := Backup + '\Tools.db';
    if FileExists(FileName) then
    begin
      XML := LoadXML(FileName);
      Rows := XML.selectNodes('/DATAPACKET/ROWDATA/ROW');
      for I := 0 to Rows.length - 1 do
      begin
        Row := Rows.item(I);
        Command := TJSONObject.Create;
        Commands.Add(Command);
        Command.AddPair('id', 'command:' + TGUID.NewGuid.ToString);
        for Name in ['Name', 'Group', 'Menu', 'Extensions', 'Script', 'Image'] do
        begin
          LabelText := VarToStr(Row.getAttribute(Name));
          if Name = 'Script' then LabelText := AdjustLineBreaks(LabelText, tlbsCRLF);
          Command.AddPair(LowerCase(Name), LabelText);
        end;
        Command.AddPair('runAs', TJSONBool.Create(SameText(VarToStr(Row.getAttribute('RunAs')), 'TRUE') or
          (VarToStr(Row.getAttribute('RunAs')) = '1')));
        VersionID := '*';
        Review := '';
        Name := VarToStr(Row.getAttribute('DelphiVersion'));
        if Name <> '' then
        begin
          VersionID := '';
          LabelText := '';
          if TryStrToInt(Name, Number) then Labels.TryGetValue(Number, LabelText);
          Command.AddPair('legacyVersion', Name);
          Command.AddPair('legacyVersionName', LabelText);
          if TryStrToInt(Name, Number) and (Number >= Ord(Low(TDelphiVersions))) and
             (Number <= Ord(High(TDelphiVersions))) and
             TryDelphiVersionName(LabelText, Version) and (Ord(Version) = Number) then
            VersionID := DelphiVersionID(Version)
          else Review := 'Review minimum Delphi: legacy ID ' + Name + ' (' + LabelText + ') conflicts with or lacks the version catalogue.';
        end;
        Command.AddPair('versionId', VersionID);
        Command.AddPair('review', Review);
      end;
    end;
    ForceDirectories(Directory + '\ico');
    if DirectoryExists(Backup + '\ico') then
      for FileName in TDirectory.GetFiles(Backup + '\ico', '*', TSearchOption.soAllDirectories) do
      begin
        Name := Copy(FileName, Length(Backup) + 2, MaxInt);
        ForceDirectories(ExtractFileDir(Directory + '\' + Name));
        if not FileExists(Directory + '\' + Name) then TFile.Copy(FileName, Directory + '\' + Name);
      end;
    if FileExists(Backup + '\macros.xml') and not FileExists(Directory + '\macros.xml') then
      TFile.Copy(Backup + '\macros.xml', Directory + '\macros.xml');
    WriteAtomic(Directory, Result);
  except
    Result.Free;
    Labels.Free;
    raise;
  end;
  Labels.Free;
end;

function LoadConfiguration(const Directory, LegacyDirectory: string): TJSONObject;
var Lock: THandle;
begin
  Lock := LockConfiguration(Directory);
  try
    if FileExists(Directory + '\settings.json') then Result := ReadDocument(Directory + '\settings.json')
    else Result := Migrate(Directory, LegacyDirectory);
  finally
    CloseHandle(Lock);
  end;
end;

function LoadUserConfiguration: TJSONObject;
begin
  Result := LoadConfiguration(UserSettingsDirectory, LegacySettingsDirectory);
end;

procedure LoadTools(Data: TClientDataSet; Document: TJSONObject);
var OwnDocument, WasReadOnly: Boolean; Value: TJSONValue; Obj: TJSONObject; Name: string;
begin
  OwnDocument := Document = nil;
  if OwnDocument then Document := LoadUserConfiguration;
  WasReadOnly := Data.ReadOnly;
  Data.DisableControls;
  try
    Data.Close;
    Data.ReadOnly := False;
    Data.FieldDefs.Clear;
    Data.FieldDefs.Add('Id', ftWideString, 80);
    for Name in ['Name', 'Group', 'Menu', 'Extensions', 'Image', 'VersionId', 'Review'] do Data.FieldDefs.Add(Name, ftWideString, 2048);
    Data.FieldDefs.Add('Script', ftWideMemo);
    Data.FieldDefs.Add('RunAs', ftBoolean);
    Data.CreateDataSet;
    for Value in Document.GetValue<TJSONArray>('commands') do
    begin
      Obj := TJSONObject(Value);
      Data.Append;
      Data.FieldByName('Id').AsString := Obj.GetValue<string>('id');
      for Name in ['Name', 'Group', 'Menu', 'Extensions', 'Script', 'Image'] do
        Data.FieldByName(Name).AsString := Obj.GetValue<string>(LowerCase(Name));
      Data.FieldByName('VersionId').AsString := Obj.GetValue<string>('versionId');
      Data.FieldByName('Review').AsString := Obj.GetValue<string>('review');
      Data.FieldByName('RunAs').AsBoolean := Obj.GetValue<Boolean>('runAs');
      Data.Post;
    end;
    Data.First;
  finally
    Data.ReadOnly := WasReadOnly;
    Data.EnableControls;
    if OwnDocument then Document.Free;
  end;
end;

procedure StoreTools(Data: TClientDataSet; Document: TJSONObject);
var Commands, Previous: TJSONArray; Command: TJSONObject; Value: TJSONValue;
  Name, ID, VersionID: string; Version: TDelphiVersions;
begin
  Data.CheckBrowseMode;
  Previous := Document.GetValue<TJSONArray>('commands');
  Commands := TJSONArray.Create;
  Data.DisableControls;
  try
    Data.First;
    while not Data.Eof do
    begin
      ID := Data.FieldByName('Id').AsString;
      if ID = '' then ID := 'command:' + TGUID.NewGuid.ToString;
      Command := nil;
      for Value in Previous do
        if TJSONObject(Value).GetValue<string>('id') = ID then Command := Value.Clone as TJSONObject;
      if Command = nil then Command := TJSONObject.Create;
      Commands.Add(Command);
      PutJSON(Command, 'id', TJSONString.Create(ID));
      for Name in ['Name', 'Group', 'Menu', 'Extensions', 'Script', 'Image'] do
        PutJSON(Command, LowerCase(Name), TJSONString.Create(Data.FieldByName(Name).AsString));
      PutJSON(Command, 'runAs', TJSONBool.Create(Data.FieldByName('RunAs').AsBoolean));
      VersionID := Data.FieldByName('VersionId').AsString;
      Name := Data.FieldByName('Review').AsString;
      if SameText(Name, cDisabledCommandReview) then
        Name := cDisabledCommandReview
      else if (VersionID = '*') or TryDelphiVersionID(VersionID, Version) then Name := ''
      else if Name = '' then Name := 'Choose a minimum Delphi version before using this command.';
      PutJSON(Command, 'versionId', TJSONString.Create(VersionID));
      PutJSON(Command, 'review', TJSONString.Create(Name));
      Data.Next;
    end;
    PutJSON(Document, 'commands', Commands);
    Commands := nil;
  finally
    Commands.Free;
    Data.EnableControls;
  end;
end;

procedure LoadVersionChoices(Data: TClientDataSet);
var Version: TDelphiVersions;
begin
  Data.Close;
  Data.FieldDefs.Clear;
  Data.FieldDefs.Add('VersionId', ftWideString, 80);
  Data.FieldDefs.Add('Name', ftWideString, 100);
  Data.CreateDataSet;
  Data.AppendRecord(['*', 'Any Delphi version']);
  for Version := Low(TDelphiVersions) to High(TDelphiVersions) do
    Data.AppendRecord([DelphiVersionID(Version), DelphiVersionsNames[Version]]);
  Data.First;
end;

function CommandAllowsVersion(Data: TClientDataSet; Version: TDelphiVersions): Boolean;
var Minimum: TDelphiVersions; ID: string;
begin
  ID := Data.FieldByName('VersionId').AsString;
  Result := (Data.FieldByName('Review').AsString = '') and
    ((ID = '*') or (TryDelphiVersionID(ID, Minimum) and (Version >= Minimum)));
end;

end.
