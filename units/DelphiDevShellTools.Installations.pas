//**************************************************************************************************
//
// Unit DelphiDevShellTools.Installations
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
// The Original Code is DelphiDevShellTools.Installations.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.Installations;

interface

uses System.SysUtils, DelphiDevShellTools.Commands;

type
  TInstallationCandidate = record
    RegistryVersion, RootDirectory, App32, App64: string;
  end;
  TIDEInstallation = record
    Id, RegistryVersion, Name, RootDirectory, IDE32, IDE64: string;
    EnvironmentScript, Compiler32, Compiler64: string;
    function Executable(Variant: TIDEVariant): string;
    function SupportsPlatform(const Platform: string): Boolean;
  end;
  TFileProbe = reference to function(const Path: string): Boolean;

function NormalizeInstallations(const Candidates: TArray<TInstallationCandidate>;
  const Exists: TFileProbe): TArray<TIDEInstallation>;
function SelectInstallation(const Items: TArray<TIDEInstallation>; const Request: TCommandRequest;
  const PreferredId, DetectedVersion: string; PreferredVariant: TIDEVariant;
  ProjectRequiresDetection: Boolean; out Variant: TIDEVariant): Integer;
function DiscoverInstallations: TArray<TIDEInstallation>;
function InstallationName(const RegistryVersion: string): string;

implementation

uses Winapi.Windows, System.Win.Registry, System.Generics.Collections, System.IOUtils;

function TIDEInstallation.Executable(Variant: TIDEVariant): string;
begin
  case Variant of
    ivWin32: Result := IDE32;
    ivWin64: Result := IDE64;
  else
    if IDE64 <> '' then Result := IDE64 else Result := IDE32;
  end;
end;

function TIDEInstallation.SupportsPlatform(const Platform: string): Boolean;
begin
  Result := (SameText(Platform, 'Win32') and (Compiler32 <> '')) or
            (SameText(Platform, 'Win64') and (Compiler64 <> ''));
end;

function InstallationName(const RegistryVersion: string): string;
begin
  if RegistryVersion = '37.0' then Exit('Delphi 13 Florence');
  if RegistryVersion = '23.0' then Exit('Delphi 12 Athens');
  if RegistryVersion = '22.0' then Exit('Delphi 11 Alexandria');
  if RegistryVersion = '21.0' then Exit('Delphi 10.4 Sydney');
  Result := 'RAD Studio ' + RegistryVersion;
end;

function NormalizeInstallations(const Candidates: TArray<TInstallationCandidate>;
  const Exists: TFileProbe): TArray<TIDEInstallation>;
var Items: TList<TIDEInstallation>; C: TInstallationCandidate; Item, Prior: TIDEInstallation;
  I: Integer; Found: Boolean;

  function Existing(const Path: string): string;
  begin
    Result := '';
    if (Path <> '') and TPath.IsPathRooted(Path) and Exists(Path) then
      Result := ExcludeTrailingPathDelimiter(ExpandFileName(Path));
  end;

begin
  Items := TList<TIDEInstallation>.Create;
  try
    for C in Candidates do
    begin
      Item := Default(TIDEInstallation);
      Item.RegistryVersion := C.RegistryVersion;
      Item.RootDirectory := C.RootDirectory.Trim(['"']);
      Item.IDE32 := Existing(C.App32.Trim(['"']));
      Item.IDE64 := Existing(C.App64.Trim(['"']));
      if Item.RootDirectory = '' then
      begin
        if Item.IDE32 <> '' then Item.RootDirectory := ExtractFileDir(ExtractFileDir(Item.IDE32))
        else if Item.IDE64 <> '' then Item.RootDirectory := ExtractFileDir(ExtractFileDir(Item.IDE64));
      end;
      if (Item.RootDirectory = '') or not TPath.IsPathRooted(Item.RootDirectory) then Continue;
      Item.RootDirectory := ExcludeTrailingPathDelimiter(ExpandFileName(Item.RootDirectory));
      if Item.IDE32 = '' then Item.IDE32 := Existing(Item.RootDirectory + '\bin\bds.exe');
      if Item.IDE64 = '' then Item.IDE64 := Existing(Item.RootDirectory + '\bin64\bds.exe');
      if (Item.IDE32 = '') and (Item.IDE64 = '') then Continue;
      Item.Id := 'bds:' + C.RegistryVersion + ':' + LowerCase(Item.RootDirectory);
      Item.Name := InstallationName(C.RegistryVersion);
      Item.EnvironmentScript := Existing(Item.RootDirectory + '\bin\rsvars.bat');
      Item.Compiler32 := Existing(Item.RootDirectory + '\bin\dcc32.exe');
      Item.Compiler64 := Existing(Item.RootDirectory + '\bin\dcc64.exe');
      Found := False;
      for I := 0 to Items.Count - 1 do
        if SameText(Items[I].Id, Item.Id) then
        begin
          Prior := Items[I];
          if Prior.IDE32 = '' then Prior.IDE32 := Item.IDE32;
          if Prior.IDE64 = '' then Prior.IDE64 := Item.IDE64;
          Items[I] := Prior;
          Found := True;
          Break;
        end;
      if not Found then Items.Add(Item);
    end;
    Result := Items.ToArray;
  finally
    Items.Free;
  end;
end;

function SelectInstallation(const Items: TArray<TIDEInstallation>; const Request: TCommandRequest;
  const PreferredId, DetectedVersion: string; PreferredVariant: TIDEVariant;
  ProjectRequiresDetection: Boolean; out Variant: TIDEVariant): Integer;
var I: Integer;
begin
  Result := -1;
  Variant := Request.Variant;
  if Request.ProfileId <> '' then
  begin
    for I := 0 to High(Items) do if SameText(Items[I].Id, Request.ProfileId) then Result := I;
  end
  else
  begin
    if ProjectRequiresDetection and (DetectedVersion = '') then Exit;
    for I := 0 to High(Items) do if SameText(Items[I].Id, PreferredId) then Result := I;
    if Result < 0 then
      for I := 0 to High(Items) do if Items[I].RegistryVersion = DetectedVersion then
      begin
        Result := I;
        Break;
      end;
  end;
  if Result < 0 then Exit;
  if (Variant = ivAutomatic) and SameText(Items[Result].Id, PreferredId) then Variant := PreferredVariant;
  if Items[Result].Executable(Variant) = '' then Result := -1;
end;

function DiscoverInstallations: TArray<TIDEInstallation>;
const Versions: array[0..19] of string = ('37.0','23.0','22.0','21.0','20.0','19.0',
  '18.0','17.0','16.0','15.0','14.0','12.0','11.0','10.0','9.0','8.0','7.0','6.0','5.0','4.0');
var Candidates: TList<TInstallationCandidate>; Candidate: TInstallationCandidate;
  Registry: TRegistry; Hive: HKEY; View: REGSAM; Version, Prefix: string;
  function Read(const Name: string): string;
  begin
    Result := '';
    if Registry.ValueExists(Name) then Result := Registry.ReadString(Name);
  end;
begin
  Candidates := TList<TInstallationCandidate>.Create;
  try
    for Hive in TArray<HKEY>.Create(HKEY_CURRENT_USER, HKEY_LOCAL_MACHINE) do
      for View in TArray<REGSAM>.Create(KEY_WOW64_32KEY, KEY_WOW64_64KEY) do
      begin
        Registry := TRegistry.Create(KEY_READ or View);
        try
          Registry.RootKey := Hive;
          for Prefix in TArray<string>.Create('Software\Embarcadero\BDS\', 'Software\CodeGear\BDS\', 'Software\Borland\BDS\') do
            for Version in Versions do
              if Registry.OpenKeyReadOnly(Prefix + Version) then
              begin
                Candidate := Default(TInstallationCandidate);
                Candidate.RegistryVersion := Version;
                Candidate.RootDirectory := Read('RootDir');
                Candidate.App32 := Read('App');
                Candidate.App64 := Read('App x64');
                if Candidate.App64 = '' then Candidate.App64 := Read('Appx64');
                Candidates.Add(Candidate);
                Registry.CloseKey;
              end;
        finally
          Registry.Free;
        end;
      end;
    Result := NormalizeInstallations(Candidates.ToArray,
      function(const Path: string): Boolean
      begin
        Result := FileExists(Path);
      end);
  finally
    Candidates.Free;
  end;
end;

end.
