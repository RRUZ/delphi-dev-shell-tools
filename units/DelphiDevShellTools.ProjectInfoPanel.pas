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
  System.Types, Winapi.Windows, DelphiDevShellTools.UI;

type
  TProjectInfoValueKind = (pivkText, pivkBadge, pivkBadgeList);

  TProjectInfoRow = record
    Caption, Value: string;
    IconKey: string;
    ValueKind: TProjectInfoValueKind;
    BadgeRole: TDevShellBadgeRole;
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
      const AIconKey: string = '';
      AValueKind: TProjectInfoValueKind = pivkText;
      ABadgeRole: TDevShellBadgeRole = dsbrMuted);
    function BadgeValueWidth(ADC: HDC;
      const ARow: TProjectInfoRow): Integer;
    procedure DrawBadgeValue(ADC: HDC; const ABounds: TRect;
      const ARow: TProjectInfoRow; const ATheme: TDevShellTheme);
    procedure ReadProject(const AFileName: string);
    procedure Measure;
  public
    constructor Create(const AFileName: string; ADpi: Integer;
      AResourceModule: HMODULE = 0);
    destructor Destroy; override;
    function IsValid: Boolean;
    procedure Paint(ADC: HDC; const ABounds: TRect;
      const ATheme: TDevShellTheme);
    property Width: Integer read FWidth;
    property Height: Integer read FHeight;
    property Rows: TArray<TProjectInfoRow> read FRows;
  end;

function MenuDpi: Integer;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math,
  Vcl.Graphics, Xml.XMLDoc, Xml.XMLIntf,
  DelphiDevShellTools.DelphiVersions, DelphiDevShellTools.Icons;

const
  cBadgeSpacing = 4;

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

function TProjectInfoPanel.LoadPanelIcon(const AName: string): HICON;
begin
  Result := 0;
  if AName <> '' then
    Result := LoadImage(FResourceModule, PChar(AName), IMAGE_ICON,
      FIconSize, FIconSize, LR_DEFAULTCOLOR);
end;

procedure TProjectInfoPanel.AddRow(const ACaption, AValue, AIconKey: string;
  AValueKind: TProjectInfoValueKind; ABadgeRole: TDevShellBadgeRole);
begin
  if AValue = '' then
    Exit;
  var LIndex := Length(FRows);
  SetLength(FRows, LIndex + 1);
  FRows[LIndex].Caption := ACaption;
  FRows[LIndex].Value := AValue;
  FRows[LIndex].IconKey := AIconKey;
  FRows[LIndex].ValueKind := AValueKind;
  FRows[LIndex].BadgeRole := ABadgeRole;
end;

function TProjectInfoPanel.BadgeValueWidth(ADC: HDC;
  const ARow: TProjectInfoRow): Integer;
begin
  Result := 0;
  var LValues := ARow.Value.Split([',']);
  for var LValue in LValues do
  begin
    var LCaption := Trim(LValue);
    if LCaption = '' then
      Continue;
    if Result > 0 then
      Inc(Result, MulDiv(cBadgeSpacing, FDpi, 96));
    Inc(Result, DevShellBadgeNaturalWidth(ADC, LCaption, FDpi));
    if ARow.ValueKind = pivkBadge then
      Break;
  end;
end;

procedure TProjectInfoPanel.DrawBadgeValue(ADC: HDC;
  const ABounds: TRect; const ARow: TProjectInfoRow;
  const ATheme: TDevShellTheme);
begin
  var LHeight := Min(DevShellBadgeHeight(ADC, FDpi), ABounds.Height);
  var LX := ABounds.Left;
  var LValues := ARow.Value.Split([',']);
  for var LValue in LValues do
  begin
    var LCaption := Trim(LValue);
    if LCaption = '' then
      Continue;
    if LX >= ABounds.Right then
      Break;
    var LWidth := DevShellBadgeNaturalWidth(ADC, LCaption, FDpi);
    var LBadgeRect := Rect(LX, ABounds.Top + (ABounds.Height - LHeight) div 2,
      Min(LX + LWidth, ABounds.Right),
      ABounds.Top + (ABounds.Height + LHeight) div 2);
    DrawDevShellBadge(ADC, LBadgeRect, LCaption, ATheme, ARow.BadgeRole,
      FDpi);
    LX := LBadgeRect.Right + MulDiv(cBadgeSpacing, FDpi, 96);
    if ARow.ValueKind = pivkBadge then
      Break;
  end;
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
  LConfiguration: string;
  LTarget: string;
  LPlatformIcon: string;
  LBadgeRole: TDevShellBadgeRole;
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
    AddRow('Framework', LFramework, 'firemonkey', pivkBadge,
      dsbrSecondary)
  else
    AddRow('Framework', LFramework, 'vcl', pivkBadge, dsbrPrimary);
  AddRow('GUID', PropertyValue('ProjectGuid'));
  LConfiguration := PropertyValue('Config');
  LBadgeRole := dsbrMuted;
  if SameText(LConfiguration, 'Release') then
    LBadgeRole := dsbrSuccess
  else if SameText(LConfiguration, 'Debug') then
    LBadgeRole := dsbrWarning;
  AddRow('Build configuration', LConfiguration, 'buildconf', pivkBadge,
    LBadgeRole);
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
  AddRow('Target platform', LTarget, LPlatformIcon, pivkBadge, dsbrPrimary);
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
      AddRow('Available platforms', LTargets, 'platforms', pivkBadgeList,
        dsbrMuted);
    end;
  end;
end;

constructor TProjectInfoPanel.Create(const AFileName: string; ADpi: Integer;
  AResourceModule: HMODULE);
begin
  inherited Create;
  FDpi := Max(96, ADpi);
  FIconSize := MulDiv(16, FDpi, 96);
  FIconColumn := FIconSize + MulDiv(6, FDpi, 96);
  FResourceModule := AResourceModule;
  if FResourceModule = 0 then
    FResourceModule := HInstance;
  FTitleIcon := LoadPanelIcon('logo_ico');
  var LFontHeight := -MulDiv(TDevShellTheme.cFontSize, FDpi, 72);
  FFont := CreateFont(LFontHeight, 0, 0, 0, FW_NORMAL, 0, 0, 0,
    DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
    CLEARTYPE_QUALITY, DEFAULT_PITCH, PChar(TDevShellTheme.cFontName));
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
      FRowHeight := Max(Max(LTextSize.cy, FIconSize),
        DevShellBadgeHeight(LDC, FDpi)) + MulDiv(6, FDpi, 96);
      FLabelWidth := 0;
      LValueWidth := 0;
      for LRow in FRows do
      begin
        GetTextExtentPoint32(LDC, PChar(LRow.Caption),
          Length(LRow.Caption), LTextSize);
        FLabelWidth := Max(FLabelWidth, LTextSize.cx);
        if LRow.ValueKind = pivkText then
        begin
          GetTextExtentPoint32(LDC, PChar(LRow.Value), Length(LRow.Value),
            LTextSize);
          LValueWidth := Max(LValueWidth, LTextSize.cx);
        end
        else
          LValueWidth := Max(LValueWidth, BadgeValueWidth(LDC, LRow));
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
  const ATheme: TDevShellTheme);
var
  LBrush: HBRUSH;
  LRenderBatchActive: Boolean;
  LRow: TProjectInfoRow;
  LSaved: Integer;
  LSource: TProjectIconSource;
  LTextRect: TRect;
  LY: Integer;
begin
  LSaved := SaveDC(ADC);
  if LSaved = 0 then
    RaiseLastOSError;
  try
    IntersectClipRect(ADC, ABounds.Left, ABounds.Top, ABounds.Right,
      ABounds.Bottom);
    LBrush := CreateSolidBrush(ColorToRGB(ATheme.BackgroundColor));
    try
      FillRect(ADC, ABounds, LBrush);
    finally
      DeleteObject(LBrush);
    end;
    SelectObject(ADC, FFont);
    SetBkMode(ADC, TRANSPARENT);
    SetTextColor(ADC, ColorToRGB(ATheme.TextColor));
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
            ATheme, False, FResourceModule, LSource);
        end;
        LTextRect := Rect(ABounds.Left + FPadding + FIconColumn, LY,
          ABounds.Left + FPadding + FIconColumn + FLabelWidth,
          LY + FRowHeight);
        DrawText(ADC, PChar(LRow.Caption), -1, LTextRect,
          DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS);
        LTextRect := Rect(ABounds.Left + FPadding * 3 + FIconColumn +
          FLabelWidth, LY, ABounds.Right - FPadding, LY + FRowHeight);
        if LRow.ValueKind = pivkText then
          DrawText(ADC, PChar(LRow.Value), -1, LTextRect,
            DT_SINGLELINE or DT_VCENTER or DT_NOPREFIX or DT_END_ELLIPSIS)
        else
          DrawBadgeValue(ADC, LTextRect, LRow, ATheme);
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
