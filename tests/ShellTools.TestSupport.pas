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
procedure CheckHR(AValue: HResult; const AOperation: string);

procedure CheckFileContextMenu(const AMenu: IContextMenu;
  AProjectFile: Boolean);

implementation

uses
  System.Win.Registry, System.IOUtils, System.Types,
  System.Generics.Collections, Vcl.Graphics,
  Winapi.Messages, Winapi.ActiveX, DUnitX.TestFramework,
  DelphiDevShellTools.Misc;

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

procedure CheckHR(AValue: HResult; const AOperation: string);
begin
  Assert.IsTrue(Succeeded(AValue), Format('%s failed: HRESULT %.8x',
    [AOperation, Cardinal(AValue)]));
end;

// Exercise a real file selection and the command-ID contract used by Explorer.
procedure CheckFileContextMenu(const AMenu: IContextMenu; AProjectFile: Boolean);
const
  cFirstCommand = 1000;
  cLastCommand = 32767;
var
  LFileName: string;
  LItem: IShellItem;
  LData: IDataObject;
  LInit: IShellExtInit;
  LReservedCount: UINT;
  LChecksumSignatures: TDictionary<UInt64, string>;
  LCopyLeafCount: Integer;
  LCopyMenuCount: Integer;

  function MenuBitmapSignature(
    const ABitmap: Winapi.Windows.TBitmap): UInt64;
  const
    cFnvOffsetBasis = UInt64($CBF29CE484222325);
    cFnvPrime = UInt64($00000100000001B3);
  begin
    Assert.IsTrue(ABitmap.bmBits <> nil,
      'Menu bitmap must expose DIB pixels');
    Result := cFnvOffsetBasis;
    var LByteCount := Abs(ABitmap.bmHeight) * ABitmap.bmWidthBytes;
    var LPixels := PByte(ABitmap.bmBits);
    for var LIndex := 0 to LByteCount - 1 do
    begin
      Result := Result xor LPixels^;
      Result := Result * cFnvPrime;
      Inc(LPixels);
    end;
  end;

  procedure CheckMenuIds(AHandle: HMENU; AInsideCopyMenu: Boolean);
  var
    LCaption: array[0..255] of Char;
    LInfo: TMenuItemInfo;
    LMeasure: TMeasureItemStruct;
    LDraw: TDrawItemStruct;
    LMenuBitmap: Winapi.Windows.TBitmap;
    LMenu3: IContextMenu3;
    LOmittedResult: ^LRESULT;
  begin
    for var LPosition := 0 to GetMenuItemCount(AHandle) - 1 do
    begin
      ZeroMemory(@LInfo, SizeOf(LInfo));
      LInfo.cbSize := SizeOf(LInfo);
      LInfo.fMask := MIIM_ID or MIIM_FTYPE or MIIM_SUBMENU or MIIM_DATA or
        MIIM_BITMAP;
      Assert.IsTrue(GetMenuItemInfo(AHandle, LPosition, True, LInfo));
      if (LInfo.fType and MFT_OWNERDRAW) = 0 then
      begin
        ZeroMemory(@LCaption, SizeOf(LCaption));
        GetMenuString(AHandle, LPosition, LCaption, Length(LCaption),
          MF_BYPOSITION);
        Assert.IsFalse(SameText(string(LCaption), 'Check for updates'),
          'The retired updater must not appear in the shell menu');
        if SameText(string(LCaption), 'Copy') then
        begin
          Assert.IsTrue(LInfo.hSubMenu <> 0,
            'Copy must be a submenu');
          Inc(LCopyMenuCount);
        end
        else if Pos('Copy ', string(LCaption)) = 1 then
        begin
          Assert.IsTrue(AInsideCopyMenu,
            string(LCaption) + ' must be inside the Copy submenu');
          Inc(LCopyLeafCount);
        end;
        if IsVistaOrLater and
           ((Pos('Calculate ', string(LCaption)) = 1) or
            SameText(string(LCaption), 'Copy') or
            (Pos('Copy ', string(LCaption)) = 1)) then
        begin
          Assert.IsTrue(LInfo.hbmpItem <> 0,
            string(LCaption) + ' must have a menu bitmap');
          ZeroMemory(@LMenuBitmap, SizeOf(LMenuBitmap));
          Assert.IsTrue(GetObject(LInfo.hbmpItem, SizeOf(LMenuBitmap),
            @LMenuBitmap) <> 0, string(LCaption));
          Assert.AreEqual(32, LMenuBitmap.bmBitsPixel, string(LCaption));
          if (LInfo.hSubMenu = 0) and
             (Pos('Calculate ', string(LCaption)) = 1) then
          begin
            var LSignature := MenuBitmapSignature(LMenuBitmap);
            if LChecksumSignatures.ContainsKey(LSignature) then
              Assert.Fail(string(LCaption) + ' matches ' +
                LChecksumSignatures.Items[LSignature]);
            LChecksumSignatures.Add(LSignature, string(LCaption));
          end;
        end;
      end;
      if not AProjectFile then
        Assert.IsTrue((LInfo.fType and MFT_OWNERDRAW) = 0,
          'Ordinary Pascal-file actions must stay native');
      if (LInfo.fType and MFT_OWNERDRAW) <> 0 then
      begin
        Assert.IsTrue(AProjectFile,
          'Only project information may be owner-drawn');
        Assert.IsTrue(Supports(AMenu, IContextMenu3, LMenu3));
        LOmittedResult := nil;
        ZeroMemory(@LMeasure, SizeOf(LMeasure));
        LMeasure.CtlType := ODT_MENU;
        LMeasure.itemID := LInfo.wID;
        LMeasure.itemData := LInfo.dwItemData;
        CheckHR(LMenu3.HandleMenuMsg2(WM_MEASUREITEM, 0,
          LPARAM(@LMeasure), LOmittedResult^), 'Measure panel');
        Assert.IsTrue((LMeasure.itemWidth > 0) and
          (LMeasure.itemHeight > 0));
        var LBitmap := Vcl.Graphics.TBitmap.Create;
        try
          LBitmap.SetSize(LMeasure.itemWidth, LMeasure.itemHeight);
          ZeroMemory(@LDraw, SizeOf(LDraw));
          LDraw.CtlType := ODT_MENU;
          LDraw.itemID := LInfo.wID;
          LDraw.itemData := LInfo.dwItemData;
          LDraw.hDC := LBitmap.Canvas.Handle;
          LDraw.rcItem := Rect(0, 0, LBitmap.Width, LBitmap.Height);
          CheckHR(LMenu3.HandleMenuMsg2(WM_DRAWITEM, 0,
            LPARAM(@LDraw), LOmittedResult^), 'Draw panel');
        finally
          LBitmap.Free;
        end;
      end;
      if (LInfo.fType and MFT_SEPARATOR) = 0 then
        Assert.IsTrue((LInfo.wID >= cFirstCommand) and
          (LInfo.wID < cFirstCommand + LReservedCount) and
          (LInfo.wID <= cLastCommand),
          Format('Menu ID %d is outside the reported range %d..%d',
            [LInfo.wID, cFirstCommand,
             cFirstCommand + LReservedCount - 1]));
      if LInfo.hSubMenu <> 0 then
        CheckMenuIds(LInfo.hSubMenu, SameText(string(LCaption), 'Copy'));
    end;
  end;

begin
  LCopyLeafCount := 0;
  LCopyMenuCount := 0;
  LChecksumSignatures := TDictionary<UInt64, string>.Create;
  try
    LFileName := TPath.Combine(TPath.GetTempPath, 'ShellMenu-' +
      TGUID.NewGuid.ToString + '.pas');
    if AProjectFile then
    begin
      LFileName := ChangeFileExt(LFileName, '.dproj');
      TFile.WriteAllText(LFileName,
        '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">' +
        '<PropertyGroup><ProjectVersion>18.6</ProjectVersion><Config>Release</Config>' +
        '<Platform>Win64</Platform><FrameworkType>VCL</FrameworkType><AppType>Library</AppType>' +
        '<ProjectGuid>{12345678-1234-1234-1234-123456789012}</ProjectGuid></PropertyGroup>' +
        '<ProjectExtensions><BorlandProject><Platforms><Platform value="Win32">True</Platform>' +
        '<Platform value="Win64">True</Platform></Platforms></BorlandProject></ProjectExtensions></Project>');
    end
    else
      TFile.WriteAllText(LFileName,
        'unit Example; interface implementation end.');
    try
      CheckHR(SHCreateItemFromParsingName(PChar(LFileName), nil, IShellItem,
        LItem), 'Create selected file');
      CheckHR(LItem.BindToHandler(nil, BHID_DataObject, IDataObject, LData),
        'Create file data object');
      Assert.IsTrue(Supports(AMenu, IShellExtInit, LInit));
      CheckHR(LInit.Initialize(nil, LData, 0),
        'Initialize Pascal file selection');
      var LPopup := CreatePopupMenu;
      Assert.IsTrue(LPopup <> 0);
      try
        var LResultCode := AMenu.QueryContextMenu(LPopup, 0, cFirstCommand,
          cLastCommand, CMF_NORMAL);
        CheckHR(LResultCode, 'QueryContextMenu');
        LReservedCount := Cardinal(LResultCode) and $FFFF;
        Assert.IsTrue(GetMenuItemCount(LPopup) > 0,
          'Pascal selection must create a menu');
        CheckMenuIds(LPopup, False);
      finally
        DestroyMenu(LPopup);
      end;
    finally
      TFile.Delete(LFileName);
    end;
    Assert.AreEqual(1, LCopyMenuCount, 'Exactly one Copy submenu is required');
    Assert.AreEqual(6, LCopyLeafCount,
      'Every clipboard command must be grouped in the Copy submenu');
    if IsVistaOrLater then
      Assert.AreEqual<NativeInt>(7, LChecksumSignatures.Count,
        'Every checksum algorithm must expose a composed icon');
  finally
    LChecksumSignatures.Free;
  end;
end;

end.
