//**************************************************************************************************
//
// Unit ShellTools.TestSupport
// Shared DLL-loading, registry and real shell-menu validation helpers for tests.
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
// The Original Code is ShellTools.TestSupport.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.TestSupport;

interface

uses
  System.SysUtils, Winapi.Windows, Winapi.ShlObj;

const
  ShellClassId: TGUID = '{45DCA61E-3762-45B1-939D-2446C0DCAC25}';
  ShellClassKey = 'Software\Classes\CLSID\{45DCA61E-3762-45B1-939D-2446C0DCAC25}\InprocServer32';
  ShellHandlerKey = 'Software\Classes\*\shellex\ContextMenuHandlers\DelphiDevShellToolsContextMenu';
  ShellApprovedKey = 'Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved';

type
  TDllRegistration = function: HResult; stdcall;
  TDllGetClassObject = function(const ClassId, IID: TGUID; out Obj): HResult; stdcall;

function TestDllPath: string;
function LoadTestDll: HMODULE;
function ReadRegistryString(Root: HKEY; const Key: string; const Name: string = ''; RegistryView: REGSAM = 0): string;
function IsElevated: Boolean;
procedure CheckHR(Value: HResult; const Operation: string);

procedure CheckFileContextMenu(const Menu: IContextMenu; ProjectFile: Boolean);

implementation

uses
  System.Win.Registry, System.IOUtils, System.Types, Vcl.Graphics,
  Winapi.Messages, Winapi.ActiveX, DUnitX.TestFramework;

function TestDllPath: string;
begin
  Result := GetEnvironmentVariable('DDS_TEST_DLL');
  if Result = '' then
    raise Exception.Create('DDS_TEST_DLL is missing. Run these tests with Build.bat test.');
end;

function LoadTestDll: HMODULE;
begin
  Result := LoadLibrary(PChar(TestDllPath));
  if Result = 0 then
    RaiseLastOSError;
end;

function ReadRegistryString(Root: HKEY; const Key, Name: string; RegistryView: REGSAM): string;
var
  Registry: TRegistry;
begin
  Result := '';
  {$IFDEF WIN64}
  if RegistryView = 0 then RegistryView := KEY_WOW64_64KEY;
  {$ELSE}
  if RegistryView = 0 then RegistryView := KEY_WOW64_32KEY;
  {$ENDIF}
  Registry := TRegistry.Create(KEY_READ or RegistryView);
  try
    Registry.RootKey := Root;
    if Registry.OpenKeyReadOnly(Key) and Registry.ValueExists(Name) then
      Result := Registry.ReadString(Name);
  finally
    Registry.Free;
  end;
end;

function IsElevated: Boolean;
var
  Token: THandle;
  Elevation: TTokenElevation;
  Size: DWORD;
begin
  Result := False;
  if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Token) then Exit;
  try
    if GetTokenInformation(Token, TokenElevation, @Elevation, SizeOf(Elevation), Size) then
      Result := Elevation.TokenIsElevated <> 0;
  finally
    CloseHandle(Token);
  end;
end;

procedure CheckHR(Value: HResult; const Operation: string);
begin
  Assert.IsTrue(Succeeded(Value), Format('%s failed: HRESULT %.8x', [Operation, Cardinal(Value)]));
end;

// Exercise a real file selection and the command-ID contract used by Explorer.
procedure CheckFileContextMenu(const Menu: IContextMenu; ProjectFile: Boolean);
const
  FirstCommand = 1000;
  LastCommand = 32767;
var
  FileName: string;
  Item: IShellItem;
  Data: IDataObject;
  Init: IShellExtInit;
  Popup: HMENU;
  ResultCode: HResult;
  ReservedCount: UINT;

  procedure CheckMenuIds(Handle: HMENU);
  var
    Position: Integer;
    Caption: array[0..255] of Char;
    Info: TMenuItemInfo;
    Measure: TMeasureItemStruct;
    Draw: TDrawItemStruct;
    Bitmap: Vcl.Graphics.TBitmap;
    Menu3: IContextMenu3;
    OmittedResult: ^LRESULT;
  begin
    for Position := 0 to GetMenuItemCount(Handle) - 1 do
    begin
      ZeroMemory(@Info, SizeOf(Info));
      Info.cbSize := SizeOf(Info);
      Info.fMask := MIIM_ID or MIIM_FTYPE or MIIM_SUBMENU or MIIM_DATA;
      Assert.IsTrue(GetMenuItemInfo(Handle, Position, True, Info));
      if (Info.fType and MFT_OWNERDRAW) = 0 then
      begin
        ZeroMemory(@Caption, SizeOf(Caption));
        GetMenuString(Handle, Position, Caption, Length(Caption), MF_BYPOSITION);
        Assert.IsFalse(SameText(string(Caption), 'Check for updates'),
          'The retired updater must not appear in the shell menu');
      end;
      if not ProjectFile then
        Assert.IsTrue((Info.fType and MFT_OWNERDRAW) = 0,
          'Ordinary Pascal-file actions must stay native');
      if (Info.fType and MFT_OWNERDRAW) <> 0 then
      begin
        Assert.IsTrue(ProjectFile, 'Only project information may be owner-drawn');
        Assert.IsTrue(Supports(Menu, IContextMenu3, Menu3));
        OmittedResult := nil;
        ZeroMemory(@Measure, SizeOf(Measure));
        Measure.CtlType := ODT_MENU;
        Measure.itemID := Info.wID;
        Measure.itemData := Info.dwItemData;
        CheckHR(Menu3.HandleMenuMsg2(WM_MEASUREITEM, 0, LPARAM(@Measure), OmittedResult^), 'Measure panel');
        Assert.IsTrue((Measure.itemWidth > 0) and (Measure.itemHeight > 0));
        Bitmap := Vcl.Graphics.TBitmap.Create;
        try
          Bitmap.SetSize(Measure.itemWidth, Measure.itemHeight);
          ZeroMemory(@Draw, SizeOf(Draw));
          Draw.CtlType := ODT_MENU;
          Draw.itemID := Info.wID;
          Draw.itemData := Info.dwItemData;
          Draw.hDC := Bitmap.Canvas.Handle;
          Draw.rcItem := Rect(0, 0, Bitmap.Width, Bitmap.Height);
          CheckHR(Menu3.HandleMenuMsg2(WM_DRAWITEM, 0, LPARAM(@Draw), OmittedResult^), 'Draw panel');
        finally
          Bitmap.Free;
        end;
        Menu3 := nil;
      end;
      if (Info.fType and MFT_SEPARATOR) = 0 then
        Assert.IsTrue((Info.wID >= FirstCommand) and
          (Info.wID < FirstCommand + ReservedCount) and (Info.wID <= LastCommand),
          Format('Menu ID %d is outside the reported range %d..%d',
            [Info.wID, FirstCommand, FirstCommand + ReservedCount - 1]));
      if Info.hSubMenu <> 0 then CheckMenuIds(Info.hSubMenu);
    end;
  end;

begin
  FileName := TPath.Combine(TPath.GetTempPath, 'ShellMenu-' + TGUID.NewGuid.ToString + '.pas');
  if ProjectFile then
  begin
    FileName := ChangeFileExt(FileName, '.dproj');
    TFile.WriteAllText(FileName,
      '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">' +
      '<PropertyGroup><ProjectVersion>18.6</ProjectVersion><Config>Release</Config>' +
      '<Platform>Win64</Platform><FrameworkType>VCL</FrameworkType><AppType>Library</AppType>' +
      '<ProjectGuid>{12345678-1234-1234-1234-123456789012}</ProjectGuid></PropertyGroup>' +
      '<ProjectExtensions><BorlandProject><Platforms><Platform value="Win32">True</Platform>' +
      '<Platform value="Win64">True</Platform></Platforms></BorlandProject></ProjectExtensions></Project>');
  end
  else
    TFile.WriteAllText(FileName, 'unit Example; interface implementation end.');
  Popup := 0;
  try
    CheckHR(SHCreateItemFromParsingName(PChar(FileName), nil, IShellItem, Item), 'Create selected file');
    CheckHR(Item.BindToHandler(nil, BHID_DataObject, IDataObject, Data), 'Create file data object');
    Assert.IsTrue(Supports(Menu, IShellExtInit, Init));
    CheckHR(Init.Initialize(nil, Data, 0), 'Initialize Pascal file selection');
    Popup := CreatePopupMenu;
    Assert.IsTrue(Popup <> 0);
    ResultCode := Menu.QueryContextMenu(Popup, 0, FirstCommand, LastCommand, CMF_NORMAL);
    CheckHR(ResultCode, 'QueryContextMenu');
    ReservedCount := Cardinal(ResultCode) and $FFFF;
    Assert.IsTrue(GetMenuItemCount(Popup) > 0, 'Pascal selection must create a menu');
    CheckMenuIds(Popup);
  finally
    if Popup <> 0 then DestroyMenu(Popup);
    Init := nil;
    Data := nil;
    Item := nil;
    TFile.Delete(FileName);
  end;
end;

end.
