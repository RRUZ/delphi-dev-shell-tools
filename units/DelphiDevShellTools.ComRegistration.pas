//**************************************************************************************************
//
// Unit DelphiDevShellTools.ComRegistration
// COM factory registration and architecture coexistence
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
// The Original Code is DelphiDevShellTools.ComRegistration.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.ComRegistration;

interface

uses System.Win.ComObj;

type
  TDelphiDevShellObjectFactory = class(TAutoObjectFactory)
  protected
    function GetProgID: string; override;
  public
    procedure UpdateRegistry(Register: Boolean); override;
  end;

implementation

uses DelphiDevShellTools.Logging,
  Winapi.Windows, Winapi.ShlObj, System.SysUtils, System.Win.Registry, DelphiDevShellTools.Misc;

function TDelphiDevShellObjectFactory.GetProgID: string;
begin
  Exit(EmptyStr);
end;

procedure TDelphiDevShellObjectFactory.UpdateRegistry(Register: Boolean);
var
  LRegistry: TRegistry;
  OtherArchitectureRegistered: Boolean;
begin
  log('TDelphiDevShellObjectFactory.UpdateRegistry Init');
  inherited UpdateRegistry(Register);
  // The context-menu key is shared by Win32 and Win64; Approved is per view.
  OtherArchitectureRegistered := False;
  if not Register then
  begin
    {$IFDEF WIN64}
    LRegistry := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
    {$ELSE}
    LRegistry := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
    {$ENDIF}
    try
      LRegistry.RootKey := HKEY_LOCAL_MACHINE;
      if LRegistry.OpenKeyReadOnly('Software\Classes\CLSID\' + GUIDToString(ClassID) + '\InprocServer32') then
        OtherArchitectureRegistered := LRegistry.ValueExists('') and (LRegistry.ReadString('') <> '');
    finally
      LRegistry.Free;
    end;
  end;
  LRegistry := TRegistry.Create;
  try
    LRegistry.RootKey := HKEY_LOCAL_MACHINE;
    if not LRegistry.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved', True) then
      Exit;

    if &Register then
      LRegistry.WriteString(GUIDToString(ClassID), Description)
    else
      LRegistry.DeleteValue(GUIDToString(ClassID));
  finally
    LRegistry.Free;
  end;

  if Register then
    CreateRegKey(Format('*\shellex\ContextMenuHandlers\%s', [ClassName]), '', GUIDToString(ClassID), HKEY_CLASSES_ROOT)
  else if not OtherArchitectureRegistered then
    DeleteRegKey(Format('*\shellex\ContextMenuHandlers\%s', [ClassName]));

  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
  log('TDelphiDevShellObjectFactory.UpdateRegistry Done');
end;

end.
