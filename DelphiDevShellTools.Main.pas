//**************************************************************************************************
//
// Unit DelphiDevShellTools.Main
// COM shell-extension entry point
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
// The Original Code is DelphiDevShellTools.Main.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.Main;

interface

uses
  Winapi.Windows, Winapi.ActiveX, Winapi.ShlObj, System.Win.ComObj,
  DelphiDevShellTools_TLB, DelphiDevShellTools.ShellMenu;

type
  TDelphiDevShellToolsContextMenu = class(TAutoObject, IDelphiDevShellToolsContextMenu,
    IShellExtInit, IContextMenu, IContextMenu2, IContextMenu3)
  private
    FMenu: TShellMenu;
  protected
    function IShellExtInit.Initialize = ShellExtInitialize;
    function ShellExtInitialize(pidlFolder: PItemIDList; lpdobj: IDataObject; hKeyProgID: HKEY): HResult; stdcall;
    function QueryContextMenu(Menu: HMENU; indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult; stdcall;
    function InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult; stdcall;
    function GetCommandString(idCmd: UINT_PTR; uFlags: UINT; pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult; stdcall;
    //IContextMenu2
    function HandleMenuMsg(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HResult; stdcall;
    //IContextMenu3
    function HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
  public
    procedure Initialize; override;
    destructor Destroy; override;
  end;

implementation

uses System.Win.ComServ, DelphiDevShellTools.ComRegistration;

procedure TDelphiDevShellToolsContextMenu.Initialize;
begin
  inherited;
  // COM factories use CreateFromFactory, which calls this virtual initializer.
  FMenu := TShellMenu.Create;
end;

destructor TDelphiDevShellToolsContextMenu.Destroy;
begin
  FMenu.Free;
  inherited;
end;

function TDelphiDevShellToolsContextMenu.ShellExtInitialize(pidlFolder: PItemIDList;
  lpdobj: IDataObject; hKeyProgID: HKEY): HResult;
begin
  Result := FMenu.ShellExtInitialize(pidlFolder, lpdobj, hKeyProgID);
end;

function TDelphiDevShellToolsContextMenu.QueryContextMenu(Menu: HMENU;
  indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult;
begin
  Result := FMenu.QueryContextMenu(Menu, indexMenu, idCmdFirst, idCmdLast, uFlags);
end;

function TDelphiDevShellToolsContextMenu.InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult;
begin
  Result := FMenu.InvokeCommand(lpici);
end;

function TDelphiDevShellToolsContextMenu.GetCommandString(idCmd: UINT_PTR; uFlags: UINT;
  pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult;
begin
  Result := FMenu.GetCommandString(idCmd, uFlags, pwReserved, pszName, cchMax);
end;

function TDelphiDevShellToolsContextMenu.HandleMenuMsg(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HResult; stdcall;
begin
  Result := FMenu.HandleMenuMsg(uMsg, WParam, LParam);
end;

function TDelphiDevShellToolsContextMenu.HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
begin
  Result := FMenu.HandleMenuMsg2(uMsg, wParam, lParam, lpResult);
end;

initialization
  TDelphiDevShellObjectFactory.Create(ComServer, TDelphiDevShellToolsContextMenu,
    CLASS_DelphiDevShellToolsContextMenu, ciMultiInstance, tmApartment);
end.
