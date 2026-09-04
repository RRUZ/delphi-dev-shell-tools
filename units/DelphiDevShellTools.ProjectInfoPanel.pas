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
    Icon: HICON;
  end;

  TProjectInfoPanel = class
  private
    FRows: TArray<TProjectInfoRow>;
    FFont: HFONT;
    FResourceModule: HMODULE;
    FTitleIcon: HICON;
    FIconSize, FIconColumn: Integer;
    FDpi, FWidth, FHeight, FRowHeight, FPadding, FLabelWidth: Integer;
    function LoadPanelIcon(const Name: string): HICON;
    procedure AddRow(const Caption, Value: string; const IconName: string = '');
    procedure ReadProject(const FileName: string);
    procedure Measure;
  public
    constructor Create(const FileName: string; Dpi: Integer; ResourceModule: HMODULE = 0);
    destructor Destroy; override;
    function IsValid: Boolean;
    procedure Paint(DC: HDC; const Bounds: TRect; Background, Foreground: COLORREF);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Rows: TArray<TProjectInfoRow> read FRows;
  end;

function MenuDpi: Integer;
procedure MenuPanelColors(DC: HDC; const Bounds: TRect; out Background, Foreground: COLORREF);

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math,
  System.Win.Registry, Xml.XMLDoc, Xml.XMLIntf, DelphiDevShellTools.DelphiVersions;

function MenuDpi: Integer;
type
  TGetDpiForWindow = function(Window: HWND): UINT; stdcall;
var
  GetWindowDpi: TGetDpiForWindow;
  Position: TPoint;
  Window: HWND;
begin
  Result := 96;
  GetWindowDpi := GetProcAddress(GetModuleHandle('user32.dll'), 'GetDpiForWindow');
  if Assigned(GetWindowDpi) then
  begin
    GetCursorPos(Position);
    Window := WindowFromPoint(Position);
    if Window = 0 then Window := GetForegroundWindow;
    Result := GetWindowDpi(Window);
    if Result = 0 then Result := 96;
  end;
end;

procedure MenuPanelColors(DC: HDC; const Bounds: TRect; out Background, Foreground: COLORREF);
var
  Contrast: THighContrast;
  Registry: TRegistry;
  Dark: Boolean;
  Pixel: COLORREF;
begin
  Background := GetSysColor(COLOR_MENU);
  Foreground := GetSysColor(COLOR_MENUTEXT);
  ZeroMemory(@Contrast, SizeOf(Contrast));
  Contrast.cbSize := SizeOf(Contrast);
  if SystemParametersInfo(SPI_GETHIGHCONTRAST, SizeOf(Contrast), @Contrast, 0) and
     ((Contrast.dwFlags and HCF_HIGHCONTRASTON) <> 0) then Exit;
  Dark := False;
  Registry := TRegistry.Create(KEY_READ);
  try
    Registry.RootKey := HKEY_CURRENT_USER;
    if Registry.OpenKeyReadOnly('Software\Microsoft\Windows\CurrentVersion\Themes\Personalize') and
       Registry.ValueExists('AppsUseLightTheme') then
      Dark := Registry.ReadInteger('AppsUseLightTheme') = 0;
  finally
    Registry.Free;
  end;
  if Dark then
  begin
    Background := RGB(43, 43, 43);
    Foreground := RGB(245, 245, 245);
  end;
  // Reuse an already painted host-menu background when it matches this mode.
  // Do not sample the title/text area or trust an uninitialized black surface.
  Pixel := GetPixel(DC, Bounds.Left + 1, Bounds.Top + 1);
  if (Pixel <> CLR_INVALID) and (Pixel <> 0) and
     (((GetRValue(Pixel) + GetGValue(Pixel) + GetBValue(Pixel)) < 384) = Dark) then
    Background := Pixel;
end;

function TProjectInfoPanel.LoadPanelIcon(const Name: string): HICON;
begin
  Result := 0;
  if Name <> '' then
    Result := LoadImage(FResourceModule, PChar(Name), IMAGE_ICON,
      FIconSize, FIconSize, LR_DEFAULTCOLOR);
end;

procedure TProjectInfoPanel.AddRow(const Caption, Value, IconName: string);
var
  Index: Integer;
begin
  if Value = '' then Exit;
  Index := Length(FRows);
  SetLength(FRows, Index + 1);
  FRows[Index].Caption := Caption;
  FRows[Index].Value := Value;
  FRows[Index].Icon := LoadPanelIcon(IconName);
end;

procedure TProjectInfoPanel.ReadProject(const FileName: string);
const
  Namespace = 'http://schemas.microsoft.com/developer/msbuild/2003';
var
  Document: IXMLDocument;
  Root, Group, Node, Platforms, Platform: IXMLNode;
  I: Integer;
  Version, Targets, Framework, Target, PlatformIcon: string;
  Versions: SetDelphiVersions;

  function PropertyValue(const Name: string): string;
  var
    J: Integer;
    ValueNode: IXMLNode;
  begin
    Result := '';
    for J := 0 to Root.ChildNodes.Count - 1 do
    begin
      Group := Root.ChildNodes[J];
      if Group.LocalName <> 'PropertyGroup' then Continue;
      ValueNode := Group.ChildNodes.FindNode(Name, Namespace);
      if ValueNode <> nil then Exit(ValueNode.Text);
    end;
  end;

begin
  Document := LoadXMLData(TFile.ReadAllText(FileName));
  Root := Document.DocumentElement;
  if (Root = nil) or (Root.LocalName <> 'Project') or (Root.NamespaceURI <> Namespace) then Exit;
  Version := PropertyValue('ProjectVersion');
  Versions := GetDelphiVersions(FileName);
  if Length(Versions) > 0 then
    AddRow('Delphi version', DelphiVersionsNames[Versions[0]], 'delphi_ico')
  else
    AddRow('Delphi version', 'Not mapped (project format ' + Version + ')', 'delphi_ico');
  AddRow('Project type', PropertyValue('AppType'));
  Framework := PropertyValue('FrameworkType');
  if SameText(Framework, 'FMX') then
    AddRow('Framework', Framework, 'firemonkey_ico')
  else
    AddRow('Framework', Framework, 'vcl_ico');
  AddRow('GUID', PropertyValue('ProjectGuid'));
  AddRow('Build configuration', PropertyValue('Config'), 'buildconf_ico');
  Target := PropertyValue('Platform');
  PlatformIcon := 'platforms_ico';
  if SameText(Copy(Target, 1, 3), 'Win') then PlatformIcon := 'win_ico'
  else if SameText(Copy(Target, 1, 3), 'OSX') then PlatformIcon := 'osx_ico'
  else if SameText(Copy(Target, 1, 3), 'iOS') then PlatformIcon := 'ios_ico'
  else if SameText(Copy(Target, 1, 7), 'Android') then PlatformIcon := 'android_ico';
  AddRow('Target platform', Target, PlatformIcon);
  Node := Root.ChildNodes.FindNode('ProjectExtensions', Namespace);
  if Node <> nil then Node := Node.ChildNodes.FindNode('BorlandProject', Namespace);
  if Node <> nil then
  begin
    Platforms := Node.ChildNodes.FindNode('Platforms', Namespace);
    if Platforms <> nil then
    begin
      Targets := '';
      for I := 0 to Platforms.ChildNodes.Count - 1 do
      begin
        Platform := Platforms.ChildNodes[I];
        if (Platform.LocalName = 'Platform') and SameText(Platform.Text, 'True') then
        begin
          if Targets <> '' then Targets := Targets + ', ';
          Targets := Targets + string(Platform.Attributes['value']);
        end;
      end;
      AddRow('Available platforms', Targets, 'platforms_ico');
    end;
  end;
end;

constructor TProjectInfoPanel.Create(const FileName: string; Dpi: Integer; ResourceModule: HMODULE);
type
  TParametersForDpi = function(Action, Param: UINT; Data: Pointer; Flags, Dpi: UINT): BOOL; stdcall;
var
  Metrics: TNonClientMetrics;
  ParametersForDpi: TParametersForDpi;
  Loaded: Boolean;
begin
  inherited Create;
  FDpi := Max(96, Dpi);
  FIconSize := MulDiv(16, FDpi, 96);
  FIconColumn := FIconSize + MulDiv(6, FDpi, 96);
  FResourceModule := ResourceModule;
  if FResourceModule = 0 then FResourceModule := HInstance;
  FTitleIcon := LoadPanelIcon('logo_ico');
  ZeroMemory(@Metrics, SizeOf(Metrics));
  Metrics.cbSize := SizeOf(Metrics);
  ParametersForDpi := GetProcAddress(GetModuleHandle('user32.dll'), 'SystemParametersInfoForDpi');
  Loaded := False;
  if Assigned(ParametersForDpi) then
    Loaded := ParametersForDpi(SPI_GETNONCLIENTMETRICS, SizeOf(Metrics), @Metrics, 0, FDpi);
  if not Loaded then
  begin
    SystemParametersInfo(SPI_GETNONCLIENTMETRICS, SizeOf(Metrics), @Metrics, 0);
    Metrics.lfMenuFont.lfHeight := -MulDiv(12, FDpi, 96);
  end;
  FFont := CreateFontIndirect(Metrics.lfMenuFont);
  if FFont = 0 then RaiseLastOSError;
  ReadProject(FileName);
  Measure;
end;

destructor TProjectInfoPanel.Destroy;
var
  Row: TProjectInfoRow;
begin
  for Row in FRows do
    if Row.Icon <> 0 then DestroyIcon(Row.Icon);
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
  DC: HDC;
  Previous: HGDIOBJ;
  TextSize: TSize;
  Row: TProjectInfoRow;
  ValueWidth: Integer;
begin
  FPadding := MulDiv(10, FDpi, 96);
  DC := CreateCompatibleDC(0);
  if DC = 0 then RaiseLastOSError;
  Previous := SelectObject(DC, FFont);
  try
    GetTextExtentPoint32(DC, 'Hg', 2, TextSize);
    FRowHeight := Max(TextSize.cy, FIconSize) + MulDiv(6, FDpi, 96);
    FLabelWidth := 0;
    ValueWidth := 0;
    for Row in FRows do
    begin
      GetTextExtentPoint32(DC, PChar(Row.Caption), Length(Row.Caption), TextSize);
      FLabelWidth := Max(FLabelWidth, TextSize.cx);
      GetTextExtentPoint32(DC, PChar(Row.Value), Length(Row.Value), TextSize);
      ValueWidth := Max(ValueWidth, TextSize.cx);
    end;
    FWidth := Min(MulDiv(720, FDpi, 96), FPadding * 4 + FIconColumn + FLabelWidth + ValueWidth);
    FWidth := Max(MulDiv(380, FDpi, 96), FWidth);
    FHeight := FPadding * 2 + FRowHeight * (Length(FRows) + 1);
  finally
    SelectObject(DC, Previous);
    DeleteDC(DC);
  end;
end;

procedure TProjectInfoPanel.Paint(DC: HDC; const Bounds: TRect; Background, Foreground: COLORREF);
var
  Saved, Y: Integer;
  Brush: HBRUSH;
  Row: TProjectInfoRow;
  TextRect: TRect;
begin
  Saved := SaveDC(DC);
  if Saved = 0 then RaiseLastOSError;
  try
    IntersectClipRect(DC, Bounds.Left, Bounds.Top, Bounds.Right, Bounds.Bottom);
    Brush := CreateSolidBrush(Background);
    try
      FillRect(DC, Bounds, Brush);
    finally
      DeleteObject(Brush);
    end;
    SelectObject(DC, FFont);
    SetBkMode(DC, TRANSPARENT);
    SetTextColor(DC, Foreground);
    Y := Bounds.Top + FPadding;
    if FTitleIcon <> 0 then
      DrawIconEx(DC, Bounds.Left + FPadding, Y + (FRowHeight - FIconSize) div 2,
        FTitleIcon, FIconSize, FIconSize, 0, 0, DI_NORMAL);
    TextRect := Rect(Bounds.Left + FPadding + FIconColumn, Y, Bounds.Right - FPadding, Y + FRowHeight);
    DrawText(DC, 'Project information', -1, TextRect, DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
    Inc(Y, FRowHeight);
    for Row in FRows do
    begin
      if Row.Icon <> 0 then
        DrawIconEx(DC, Bounds.Left + FPadding, Y + (FRowHeight - FIconSize) div 2,
          Row.Icon, FIconSize, FIconSize, 0, 0, DI_NORMAL);
      TextRect := Rect(Bounds.Left + FPadding + FIconColumn, Y, Bounds.Left + FPadding + FIconColumn + FLabelWidth, Y + FRowHeight);
      DrawText(DC, PChar(Row.Caption), -1, TextRect, DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
      TextRect := Rect(Bounds.Left + FPadding * 3 + FIconColumn + FLabelWidth, Y, Bounds.Right - FPadding, Y + FRowHeight);
      DrawText(DC, PChar(Row.Value), -1, TextRect, DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
      Inc(Y, FRowHeight);
    end;
  finally
    RestoreDC(DC, Saved);
  end;
end;

end.
