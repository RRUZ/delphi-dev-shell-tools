//**************************************************************************************************
//
// Unit DelphiDevShellTools.ProjectInfoPanel
// Project-information panel for the Delphi Dev Shell Tools
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
// The Original Code is DelphiDevShellTools.ProjectInfoPanel.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.ProjectInfoPanel;

interface

uses
  System.Types, Winapi.Windows;

type
  TProjectInfoRow = record
    Caption, Value: string;
    IconKey: string;
  end;

  TProjectInfoPanel = class
  private
    FRows: TArray<TProjectInfoRow>;
    FFont: HFONT;
    FResourceModule: HMODULE;
    FTitleIcon: HICON;
    FIconSize, FIconColumn: Integer;
    FDpi, FWidth, FHeight, FRowHeight, FPadding, FLabelWidth: Integer;
    function LoadPanelIcon(const AName: string): HICON;
    procedure AddRow(const ACaption, AValue: string;
      const AIconKey: string = '');
    procedure ReadProject(const AFileName: string);
    procedure Measure;
  public
    constructor Create(const AFileName: string; ADpi: Integer;
      AResourceModule: HMODULE = 0);
    destructor Destroy; override;
    function IsValid: Boolean;
    procedure Paint(ADC: HDC; const ABounds: TRect;
      ABackground, AForeground: COLORREF);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Rows: TArray<TProjectInfoRow> read FRows;
  end;

function MenuDpi: Integer;
procedure MenuThemeColors(out ABackground, AForeground: COLORREF;
  out AHighContrast: Boolean);
procedure MenuPanelColors(ADC: HDC; const ABounds: TRect;
  out ABackground, AForeground: COLORREF);

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math,
  System.Win.Registry, Vcl.Graphics, Xml.XMLDoc, Xml.XMLIntf,
  DelphiDevShellTools.DelphiVersions, DelphiDevShellTools.Icons;

function MenuDpi: Integer;
type
  TGetDpiForWindow = function(AWindow: HWND): UINT; stdcall;
var
  LGetWindowDpi: TGetDpiForWindow;
  LPosition: TPoint;
  LWindow: HWND;
begin
  Result := 96;
  LGetWindowDpi := GetProcAddress(GetModuleHandle('user32.dll'),
    'GetDpiForWindow');
  if Assigned(LGetWindowDpi) then
  begin
    GetCursorPos(LPosition);
    LWindow := WindowFromPoint(LPosition);
    if LWindow = 0 then
      LWindow := GetForegroundWindow;
    Result := LGetWindowDpi(LWindow);
    if Result = 0 then
      Result := 96;
  end;
end;

procedure MenuThemeColors(out ABackground, AForeground: COLORREF;
  out AHighContrast: Boolean);
var
  LContrast: THighContrast;
  LDark: Boolean;
begin
  ABackground := GetSysColor(COLOR_MENU);
  AForeground := GetSysColor(COLOR_MENUTEXT);
  AHighContrast := False;
  ZeroMemory(@LContrast, SizeOf(LContrast));
  LContrast.cbSize := SizeOf(LContrast);
  if SystemParametersInfo(SPI_GETHIGHCONTRAST, SizeOf(LContrast),
     @LContrast, 0) and
     ((LContrast.dwFlags and HCF_HIGHCONTRASTON) <> 0) then
  begin
    AHighContrast := True;
    Exit;
  end;
  LDark := False;
  var LRegistry := TRegistry.Create(KEY_READ);
  try
    LRegistry.RootKey := HKEY_CURRENT_USER;
    if LRegistry.OpenKeyReadOnly(
       'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize') and
       LRegistry.ValueExists('AppsUseLightTheme') then
      LDark := LRegistry.ReadInteger('AppsUseLightTheme') = 0;
  finally
    LRegistry.Free;
  end;
  if LDark then
  begin
    ABackground := RGB(43, 43, 43);
    AForeground := RGB(245, 245, 245);
  end;
end;

procedure MenuPanelColors(ADC: HDC; const ABounds: TRect;
  out ABackground, AForeground: COLORREF);
var
  LHighContrast: Boolean;
begin
  MenuThemeColors(ABackground, AForeground, LHighContrast);
  if LHighContrast then
    Exit;
  var LDark := (GetRValue(ABackground) + GetGValue(ABackground) +
    GetBValue(ABackground)) < 384;
  // Reuse an already painted host-menu background when it matches this mode.
  // Do not sample the title/text area or trust an uninitialized black surface.
  var LPixel := GetPixel(ADC, ABounds.Left + 1, ABounds.Top + 1);
  if (LPixel <> CLR_INVALID) and (LPixel <> 0) and
     (((GetRValue(LPixel) + GetGValue(LPixel) + GetBValue(LPixel)) < 384) =
       LDark) then
    ABackground := LPixel;
end;

function TProjectInfoPanel.LoadPanelIcon(const AName: string): HICON;
begin
  Result := 0;
  if AName <> '' then
    Result := LoadImage(FResourceModule, PChar(AName), IMAGE_ICON,
      FIconSize, FIconSize, LR_DEFAULTCOLOR);
end;

procedure TProjectInfoPanel.AddRow(const ACaption, AValue, AIconKey: string);
begin
  if AValue = '' then
    Exit;
  var LIndex := Length(FRows);
  SetLength(FRows, LIndex + 1);
  FRows[LIndex].Caption := ACaption;
  FRows[LIndex].Value := AValue;
  FRows[LIndex].IconKey := AIconKey;
end;

procedure TProjectInfoPanel.ReadProject(const AFileName: string);
const
  cNamespace = 'http://schemas.microsoft.com/developer/msbuild/2003';
var
  LDocument: IXMLDocument;
  LRoot: IXMLNode;
  LNode: IXMLNode;
  LPlatforms: IXMLNode;
  LPlatform: IXMLNode;
  LIndex: Integer;
  LVersion: string;
  LTargets: string;
  LFramework: string;
  LTarget: string;
  LPlatformIcon: string;
  LVersions: SetDelphiVersions;

  function PropertyValue(const AName: string): string;
  var
    LGroup: IXMLNode;
    LPropertyIndex: Integer;
    LValueNode: IXMLNode;
  begin
    Result := '';
    for LPropertyIndex := 0 to LRoot.ChildNodes.Count - 1 do
    begin
      LGroup := LRoot.ChildNodes[LPropertyIndex];
      if LGroup.LocalName <> 'PropertyGroup' then
        Continue;
      LValueNode := LGroup.ChildNodes.FindNode(AName, cNamespace);
      if LValueNode <> nil then
        Exit(LValueNode.Text);
    end;
  end;

begin
  LDocument := LoadXMLData(TFile.ReadAllText(AFileName));
  LRoot := LDocument.DocumentElement;
  if (LRoot = nil) or (LRoot.LocalName <> 'Project') or
     (LRoot.NamespaceURI <> cNamespace) then
    Exit;
  LVersion := PropertyValue('ProjectVersion');
  LVersions := GetDelphiVersions(AFileName);
  if Length(LVersions) > 0 then
    AddRow('Delphi version', DelphiVersionsNames[LVersions[0]], 'delphi')
  else
    AddRow('Delphi version', 'Not mapped (project format ' + LVersion +
      ')', 'delphi');
  AddRow('Project type', PropertyValue('AppType'));
  LFramework := PropertyValue('FrameworkType');
  if SameText(LFramework, 'FMX') then
    AddRow('Framework', LFramework, 'firemonkey')
  else
    AddRow('Framework', LFramework, 'vcl');
  AddRow('GUID', PropertyValue('ProjectGuid'));
  AddRow('Build configuration', PropertyValue('Config'), 'buildconf');
  LTarget := PropertyValue('Platform');
  LPlatformIcon := 'platforms';
  if SameText(Copy(LTarget, 1, 3), 'Win') then
    LPlatformIcon := 'win'
  else if SameText(Copy(LTarget, 1, 3), 'OSX') then
    LPlatformIcon := 'osx'
  else if SameText(Copy(LTarget, 1, 3), 'iOS') then
    LPlatformIcon := 'ios'
  else if SameText(Copy(LTarget, 1, 7), 'Android') then
    LPlatformIcon := 'android';
  AddRow('Target platform', LTarget, LPlatformIcon);
  LNode := LRoot.ChildNodes.FindNode('ProjectExtensions', cNamespace);
  if LNode <> nil then
    LNode := LNode.ChildNodes.FindNode('BorlandProject', cNamespace);
  if LNode <> nil then
  begin
    LPlatforms := LNode.ChildNodes.FindNode('Platforms', cNamespace);
    if LPlatforms <> nil then
    begin
      LTargets := '';
      for LIndex := 0 to LPlatforms.ChildNodes.Count - 1 do
      begin
        LPlatform := LPlatforms.ChildNodes[LIndex];
        if (LPlatform.LocalName = 'Platform') and
           SameText(LPlatform.Text, 'True') then
        begin
          if LTargets <> '' then
            LTargets := LTargets + ', ';
          LTargets := LTargets + string(LPlatform.Attributes['value']);
        end;
      end;
      AddRow('Available platforms', LTargets, 'platforms');
    end;
  end;
end;

constructor TProjectInfoPanel.Create(const AFileName: string; ADpi: Integer;
  AResourceModule: HMODULE);
type
  TParametersForDpi = function(AAction, AParam: UINT; AData: Pointer;
    AFlags, ADpi: UINT): BOOL; stdcall;
var
  LMetrics: TNonClientMetrics;
  LParametersForDpi: TParametersForDpi;
  LLoaded: Boolean;
begin
  inherited Create;
  FDpi := Max(96, ADpi);
  FIconSize := MulDiv(16, FDpi, 96);
  FIconColumn := FIconSize + MulDiv(6, FDpi, 96);
  FResourceModule := AResourceModule;
  if FResourceModule = 0 then
    FResourceModule := HInstance;
  FTitleIcon := LoadPanelIcon('logo_ico');
  ZeroMemory(@LMetrics, SizeOf(LMetrics));
  LMetrics.cbSize := SizeOf(LMetrics);
  LParametersForDpi := GetProcAddress(GetModuleHandle('user32.dll'),
    'SystemParametersInfoForDpi');
  LLoaded := False;
  if Assigned(LParametersForDpi) then
    LLoaded := LParametersForDpi(SPI_GETNONCLIENTMETRICS,
      SizeOf(LMetrics), @LMetrics, 0, FDpi);
  if not LLoaded then
  begin
    SystemParametersInfo(SPI_GETNONCLIENTMETRICS, SizeOf(LMetrics),
      @LMetrics, 0);
    LMetrics.lfMenuFont.lfHeight := -MulDiv(12, FDpi, 96);
  end;
  FFont := CreateFontIndirect(LMetrics.lfMenuFont);
  if FFont = 0 then
    RaiseLastOSError;
  ReadProject(AFileName);
  Measure;
end;

destructor TProjectInfoPanel.Destroy;
begin
  if FTitleIcon <> 0 then DestroyIcon(FTitleIcon);
  if FFont <> 0 then DeleteObject(FFont);
  inherited;
end;

function TProjectInfoPanel.IsValid: Boolean;
begin
  Result := Length(FRows) > 0;
end;

procedure TProjectInfoPanel.Measure;
var
  LDC: HDC;
  LPrevious: HGDIOBJ;
  LRow: TProjectInfoRow;
  LTextSize: TSize;
  LValueWidth: Integer;
begin
  FPadding := MulDiv(10, FDpi, 96);
  LDC := CreateCompatibleDC(0);
  if LDC = 0 then
    RaiseLastOSError;
  try
    LPrevious := SelectObject(LDC, FFont);
    if LPrevious = 0 then
      RaiseLastOSError;
    try
      GetTextExtentPoint32(LDC, 'Hg', 2, LTextSize);
      FRowHeight := Max(LTextSize.cy, FIconSize) + MulDiv(6, FDpi, 96);
      FLabelWidth := 0;
      LValueWidth := 0;
      for LRow in FRows do
      begin
        GetTextExtentPoint32(LDC, PChar(LRow.Caption),
          Length(LRow.Caption), LTextSize);
        FLabelWidth := Max(FLabelWidth, LTextSize.cx);
        GetTextExtentPoint32(LDC, PChar(LRow.Value), Length(LRow.Value),
          LTextSize);
        LValueWidth := Max(LValueWidth, LTextSize.cx);
      end;
      FWidth := Min(MulDiv(720, FDpi, 96), FPadding * 4 + FIconColumn +
        FLabelWidth + LValueWidth);
      FWidth := Max(MulDiv(380, FDpi, 96), FWidth);
      FHeight := FPadding * 2 + FRowHeight * (Length(FRows) + 1);
    finally
      SelectObject(LDC, LPrevious);
    end;
  finally
    DeleteDC(LDC);
  end;
end;

procedure TProjectInfoPanel.Paint(ADC: HDC; const ABounds: TRect;
  ABackground, AForeground: COLORREF);
var
  LBrush: HBRUSH;
  LHighContrast: Boolean;
  LRenderBatchActive: Boolean;
  LRow: TProjectInfoRow;
  LSaved: Integer;
  LSource: TProjectIconSource;
  LTextRect: TRect;
  LThemeBackground: COLORREF;
  LThemeForeground: COLORREF;
  LY: Integer;
begin
  LSaved := SaveDC(ADC);
  if LSaved = 0 then
    RaiseLastOSError;
  try
    IntersectClipRect(ADC, ABounds.Left, ABounds.Top, ABounds.Right,
      ABounds.Bottom);
    LBrush := CreateSolidBrush(ABackground);
    try
      FillRect(ADC, ABounds, LBrush);
    finally
      DeleteObject(LBrush);
    end;
    SelectObject(ADC, FFont);
    SetBkMode(ADC, TRANSPARENT);
    SetTextColor(ADC, AForeground);
    MenuThemeColors(LThemeBackground, LThemeForeground, LHighContrast);
    LRenderBatchActive := BeginProjectIconRenderBatch;
    try
      LY := ABounds.Top + FPadding;
      if FTitleIcon <> 0 then
        DrawIconEx(ADC, ABounds.Left + FPadding,
          LY + (FRowHeight - FIconSize) div 2, FTitleIcon, FIconSize,
          FIconSize, 0, 0, DI_NORMAL);
      LTextRect := Rect(ABounds.Left + FPadding + FIconColumn, LY,
        ABounds.Right - FPadding, LY + FRowHeight);
      DrawText(ADC, 'Project information', -1, LTextRect,
        DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
      Inc(LY, FRowHeight);
      for LRow in FRows do
      begin
        if LRow.IconKey <> '' then
        begin
          var LIconTop := LY + (FRowHeight - FIconSize) div 2;
          var LIconRect := Rect(ABounds.Left + FPadding, LIconTop,
            ABounds.Left + FPadding + FIconSize, LIconTop + FIconSize);
          TryDrawProjectIcon(ADC, LRow.IconKey, LIconRect,
            TColor(ABackground), TColor(AForeground), LHighContrast, False,
            FResourceModule, LSource);
        end;
        LTextRect := Rect(ABounds.Left + FPadding + FIconColumn, LY,
          ABounds.Left + FPadding + FIconColumn + FLabelWidth,
          LY + FRowHeight);
        DrawText(ADC, PChar(LRow.Caption), -1, LTextRect,
          DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
        LTextRect := Rect(ABounds.Left + FPadding * 3 + FIconColumn +
          FLabelWidth, LY, ABounds.Right - FPadding, LY + FRowHeight);
        DrawText(ADC, PChar(LRow.Value), -1, LTextRect,
          DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
        Inc(LY, FRowHeight);
      end;
    finally
      if LRenderBatchActive then
        EndProjectIconRenderBatch;
    end;
  finally
    RestoreDC(ADC, LSaved);
  end;
end;

end.
