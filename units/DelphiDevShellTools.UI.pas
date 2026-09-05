//**************************************************************************************************
//
// Unit DelphiDevShellTools.UI
// Shared DPI-aware drawing helpers for generated user-interface images.
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
// The Original Code is DelphiDevShellTools.UI.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.UI;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.Types,
  Vcl.Graphics,
  Vcl.StdCtrls;

type
  TDevShellThemeKind = (dstLight, dstDark);

  TDevShellTheme = record
    const cFontName: string = 'Segoe UI';
    const cFontSize = 9;
    const cBadgeFontSize = 8;
  public
    Kind: TDevShellThemeKind;
    HighContrast: Boolean;
    BackgroundColor: TColor;
    TextColor: TColor;
    MutedColor: TColor;
    PrimaryColor: TColor;
    SecondaryColor: TColor;
    SuccessColor: TColor;
    WarningColor: TColor;
    DangerColor: TColor;
    class function DarkTheme: TDevShellTheme; static;
    class function LightTheme: TDevShellTheme; static;
    class function ActiveTheme: TDevShellTheme; static;
  end;

  TDevShellBadgeRole = (
    dsbrMuted,
    dsbrPrimary,
    dsbrSecondary,
    dsbrSuccess,
    dsbrWarning,
    dsbrDanger
  );

  TDevShellBadgeLabel = class(TCustomLabel)
  private
    FBadgeRole: TDevShellBadgeRole;
    FCornerRadius: Integer;
    FTheme: TDevShellTheme;
    procedure SetBadgeRole(AValue: TDevShellBadgeRole);
    procedure SetCornerRadius(AValue: Integer);
  protected
    procedure AdjustBounds; override;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplyTheme(const ATheme: TDevShellTheme);
    function NaturalWidth: Integer;
  published
    property Align;
    property Anchors;
    property BadgeRole: TDevShellBadgeRole read FBadgeRole write SetBadgeRole
      default dsbrPrimary;
    property Caption;
    property Constraints;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius
      default 4;
    property Enabled;
    property Font;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property Visible;
  end;

const
  cBulletIconNames: array[0..6] of string = (
    'bullet_green.ico',
    'bullet_orange.ico',
    'bullet_pink.ico',
    'bullet_purple.ico',
    'bullet_red.ico',
    'bullet_white.ico',
    'bullet_yellow.ico'
  );

function IsWindowsLightTheme: Boolean;
function ResolveMenuSurfaceTheme(ADC: HDC;
  const ABounds: TRect): TDevShellTheme;
function DevShellBadgeNaturalWidth(ADC: HDC; const ACaption: string;
  ADpi: Integer): Integer;
function DevShellBadgeHeight(ADC: HDC; ADpi: Integer): Integer;
procedure DrawDevShellBadge(ADC: HDC; const ABounds: TRect;
  const ACaption: string; const ATheme: TDevShellTheme;
  ARole: TDevShellBadgeRole; ADpi: Integer; AEnabled: Boolean = True;
  ACornerRadius: Integer = 4);
function TryGetBulletColor(const AIconName: string;
  const ATheme: TDevShellTheme; out AColor: TColor): Boolean;
procedure AddBuiltInBulletIconNames(AItems: TStrings);
procedure DrawAntialiasedSphere(const ACanvas: TCanvas; const ABounds: TRect;
  AColor: TColor; const ATheme: TDevShellTheme);
procedure CreateBulletBitmap(ABitmap: TBitmap; AColor: TColor; ASize: Integer;
  const ATheme: TDevShellTheme);
function CreateBulletIcon(AColor: TColor; ASize: Integer;
  const ATheme: TDevShellTheme): HICON;

implementation

uses
  System.Math,
  System.SysUtils,
  System.Win.Registry,
  Vcl.Controls,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ;

const
  cBadgeHorizontalPadding = 8;
  cBadgeVerticalPadding = 3;

function GPColor(AColor: TColor; AAlpha: Byte = 255): TGPColor;
begin
  var LRGBColor := ColorToRGB(AColor);
  Result := MakeColor(AAlpha, GetRValue(LRGBColor), GetGValue(LRGBColor),
    GetBValue(LRGBColor));
end;

function BlendColor(AColor, ATarget: TColor; AAmount: Single): TColor;
begin
  var LAmount: Single := EnsureRange(AAmount, 0.0, 1.0);
  var LColorRGB := ColorToRGB(AColor);
  var LTargetRGB := ColorToRGB(ATarget);
  Result := TColor(RGB(
    Round(GetRValue(LColorRGB) +
      (GetRValue(LTargetRGB) - GetRValue(LColorRGB)) * LAmount),
    Round(GetGValue(LColorRGB) +
      (GetGValue(LTargetRGB) - GetGValue(LColorRGB)) * LAmount),
    Round(GetBValue(LColorRGB) +
      (GetBValue(LTargetRGB) - GetBValue(LColorRGB)) * LAmount)));
end;

function BadgeAccentColor(const ATheme: TDevShellTheme;
  ARole: TDevShellBadgeRole): TColor;
begin
  case ARole of
    dsbrMuted: Result := ATheme.MutedColor;
    dsbrPrimary: Result := ATheme.PrimaryColor;
    dsbrSecondary: Result := ATheme.SecondaryColor;
    dsbrSuccess: Result := ATheme.SuccessColor;
    dsbrWarning: Result := ATheme.WarningColor;
    dsbrDanger: Result := ATheme.DangerColor;
  else
    Result := ATheme.TextColor;
  end;
end;

function CreateRoundedRectanglePath(const ARect: TRect;
  ARadius: Single): TGPGraphicsPath;
begin
  Result := TGPGraphicsPath.Create;
  var LLeft := ARect.Left + 0.5;
  var LTop := ARect.Top + 0.5;
  var LRight := ARect.Right - 0.5;
  var LBottom := ARect.Bottom - 0.5;
  var LRadius := EnsureRange(ARadius, 0.0,
    Min((LRight - LLeft) / 2.0, (LBottom - LTop) / 2.0));
  if LRadius <= 0.0 then
  begin
    Result.AddRectangle(MakeRect(LLeft, LTop, LRight - LLeft,
      LBottom - LTop));
    Exit;
  end;
  var LDiameter := LRadius * 2.0;
  Result.AddArc(LLeft, LTop, LDiameter, LDiameter, 180, 90);
  Result.AddLine(LLeft + LRadius, LTop, LRight - LRadius, LTop);
  Result.AddArc(LRight - LDiameter, LTop, LDiameter, LDiameter, 270, 90);
  Result.AddLine(LRight, LTop + LRadius, LRight, LBottom - LRadius);
  Result.AddArc(LRight - LDiameter, LBottom - LDiameter, LDiameter,
    LDiameter, 0, 90);
  Result.AddLine(LRight - LRadius, LBottom, LLeft + LRadius, LBottom);
  Result.AddArc(LLeft, LBottom - LDiameter, LDiameter, LDiameter, 90, 90);
  Result.AddLine(LLeft, LBottom - LRadius, LLeft, LTop + LRadius);
  Result.CloseFigure;
end;

procedure DrawRoundedRectangle(ADC: HDC; const ABounds: TRect;
  AFillColor, ABorderColor: TColor; ARadius, ABorderWidth: Single);
begin
  var LGraphics := TGPGraphics.Create(ADC);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LPath := CreateRoundedRectanglePath(ABounds, ARadius);
    try
      var LBrush := TGPSolidBrush.Create(GPColor(AFillColor));
      try
        LGraphics.FillPath(LBrush, LPath);
      finally
        LBrush.Free;
      end;
      var LPen := TGPPen.Create(GPColor(ABorderColor), ABorderWidth);
      try
        LPen.SetLineJoin(LineJoinRound);
        LGraphics.DrawPath(LPen, LPath);
      finally
        LPen.Free;
      end;
    finally
      LPath.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;

function ColorIsLight(AColor: TColor): Boolean;
begin
  var LColor := ColorToRGB(AColor);
  Result := GetRValue(LColor) + GetGValue(LColor) + GetBValue(LColor) >= 384;
end;

function IsHighContrastEnabled: Boolean;
var
  LContrast: THighContrast;
begin
  ZeroMemory(@LContrast, SizeOf(LContrast));
  LContrast.cbSize := SizeOf(LContrast);
  Result := SystemParametersInfo(SPI_GETHIGHCONTRAST, SizeOf(LContrast),
    @LContrast, 0) and
    ((LContrast.dwFlags and HCF_HIGHCONTRASTON) <> 0);
end;

function IsWindowsLightTheme: Boolean;
const
  cPersonalizeKey =
    'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';
begin
  Result := ColorIsLight(TColor(GetSysColor(COLOR_MENU)));
  try
    var LRegistry := TRegistry.Create(KEY_READ);
    try
      LRegistry.RootKey := HKEY_CURRENT_USER;
      if LRegistry.OpenKeyReadOnly(cPersonalizeKey) and
         LRegistry.ValueExists('AppsUseLightTheme') then
        Result := LRegistry.ReadInteger('AppsUseLightTheme') <> 0;
    finally
      LRegistry.Free;
    end;
  except
    // Retain the system-menu fallback when personalization is unavailable.
  end;
end;

class function TDevShellTheme.DarkTheme: TDevShellTheme;
begin
  Result := Default(TDevShellTheme);
  Result.Kind := dstDark;
  Result.BackgroundColor := BlendColor(clWebBlack, clWebWhite, 0.17);
  Result.TextColor := clWebWhiteSmoke;
  Result.MutedColor := clWebSilver;
  Result.PrimaryColor := clWebCornflowerBlue;
  Result.SecondaryColor := clWebMediumTurquoise;
  Result.SuccessColor := clWebDarkSeaGreen;
  Result.WarningColor := clWebSandyBrown;
  Result.DangerColor := clWebIndianRed;
end;

class function TDevShellTheme.LightTheme: TDevShellTheme;
begin
  Result := Default(TDevShellTheme);
  Result.Kind := dstLight;
  Result.BackgroundColor := clWebSnow;
  Result.TextColor := BlendColor(clWebBlack, clWebWhite, 0.08);
  Result.MutedColor := clWebDarkSlateGray;
  Result.PrimaryColor := clWebSteelBlue;
  Result.SecondaryColor := clWebTeal;
  Result.SuccessColor := clWebForestGreen;
  Result.WarningColor := clWebChocolate;
  Result.DangerColor := clWebIndianRed;
end;

class function TDevShellTheme.ActiveTheme: TDevShellTheme;
begin
  if IsWindowsLightTheme then
    Result := LightTheme
  else
    Result := DarkTheme;
  Result.HighContrast := IsHighContrastEnabled;
  if not Result.HighContrast then
    Exit;
  Result.BackgroundColor := TColor(GetSysColor(COLOR_MENU));
  Result.TextColor := TColor(GetSysColor(COLOR_MENUTEXT));
  Result.MutedColor := Result.TextColor;
  Result.PrimaryColor := Result.TextColor;
  Result.SecondaryColor := Result.TextColor;
  Result.SuccessColor := Result.TextColor;
  Result.WarningColor := Result.TextColor;
  Result.DangerColor := Result.TextColor;
end;

function ResolveMenuSurfaceTheme(ADC: HDC;
  const ABounds: TRect): TDevShellTheme;
begin
  Result := TDevShellTheme.ActiveTheme;
  if Result.HighContrast or (ADC = 0) or ABounds.IsEmpty then
    Exit;
  var LPixel := GetPixel(ADC, ABounds.Left + 1, ABounds.Top + 1);
  if (LPixel <> CLR_INVALID) and (LPixel <> 0) and
     (ColorIsLight(TColor(LPixel)) = (Result.Kind = dstLight)) then
    Result.BackgroundColor := TColor(LPixel);
end;

function CreateBadgeFont(ADpi: Integer): HFONT;
begin
  Result := CreateFont(-MulDiv(TDevShellTheme.cBadgeFontSize,
    Max(96, ADpi), 72), 0, 0, 0, FW_NORMAL, 0, 0, 0, DEFAULT_CHARSET,
    OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS, CLEARTYPE_QUALITY,
    DEFAULT_PITCH, PChar(TDevShellTheme.cFontName));
end;

function DevShellBadgeNaturalWidth(ADC: HDC; const ACaption: string;
  ADpi: Integer): Integer;
var
  LFont: HFONT;
  LSaved: Integer;
  LTextSize: TSize;
begin
  Result := MulDiv(cBadgeHorizontalPadding * 2, Max(96, ADpi), 96);
  if ADC = 0 then
    Exit;
  LFont := CreateBadgeFont(ADpi);
  if LFont = 0 then
    Exit;
  try
    LSaved := SaveDC(ADC);
    if LSaved = 0 then
      Exit;
    try
      SelectObject(ADC, LFont);
      if GetTextExtentPoint32(ADC, PChar(ACaption), Length(ACaption),
         LTextSize) then
        Inc(Result, LTextSize.cx);
    finally
      RestoreDC(ADC, LSaved);
    end;
  finally
    DeleteObject(LFont);
  end;
end;

function DevShellBadgeHeight(ADC: HDC; ADpi: Integer): Integer;
var
  LFont: HFONT;
  LSaved: Integer;
  LTextSize: TSize;
begin
  Result := MulDiv(17, Max(96, ADpi), 96);
  if ADC = 0 then
    Exit;
  LFont := CreateBadgeFont(ADpi);
  if LFont = 0 then
    Exit;
  try
    LSaved := SaveDC(ADC);
    if LSaved = 0 then
      Exit;
    try
      SelectObject(ADC, LFont);
      if GetTextExtentPoint32(ADC, 'Hg', 2, LTextSize) then
        Result := LTextSize.cy +
          MulDiv(cBadgeVerticalPadding * 2, Max(96, ADpi), 96);
    finally
      RestoreDC(ADC, LSaved);
    end;
  finally
    DeleteObject(LFont);
  end;
end;

procedure DrawDevShellBadge(ADC: HDC; const ABounds: TRect;
  const ACaption: string; const ATheme: TDevShellTheme;
  ARole: TDevShellBadgeRole; ADpi: Integer; AEnabled: Boolean;
  ACornerRadius: Integer);
begin
  if (ADC = 0) or ABounds.IsEmpty or (ACaption = '') then
    Exit;
  var LAccentColor := BadgeAccentColor(ATheme, ARole);
  if not AEnabled then
    LAccentColor := ATheme.MutedColor;
  var LFillColor := ATheme.BackgroundColor;
  if not ATheme.HighContrast then
    LFillColor := BlendColor(ATheme.BackgroundColor, LAccentColor, 0.10);
  var LFont := CreateBadgeFont(ADpi);
  if LFont = 0 then
    Exit;
  try
    var LSaved := SaveDC(ADC);
    if LSaved = 0 then
      Exit;
    try
      SelectObject(ADC, LFont);
      IntersectClipRect(ADC, ABounds.Left, ABounds.Top, ABounds.Right,
        ABounds.Bottom);
      DrawRoundedRectangle(ADC, ABounds, LFillColor, LAccentColor,
        MulDiv(ACornerRadius, Max(96, ADpi), 96),
        Max(1.0, Max(96, ADpi) / 96.0));
      SetBkMode(ADC, TRANSPARENT);
      SetTextColor(ADC, ColorToRGB(LAccentColor));
      var LTextRect := ABounds;
      InflateRect(LTextRect,
        -MulDiv(cBadgeHorizontalPadding, Max(96, ADpi), 96), 0);
      DrawText(ADC, PChar(ACaption), Length(ACaption), LTextRect,
        DT_SINGLELINE or DT_CENTER or DT_VCENTER or DT_NOPREFIX or
        DT_END_ELLIPSIS);
    finally
      RestoreDC(ADC, LSaved);
    end;
  finally
    DeleteObject(LFont);
  end;
end;

{ TDevShellBadgeLabel }

constructor TDevShellBadgeLabel.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  AutoSize := False;
  Transparent := True;
  ShowAccelChar := False;
  FBadgeRole := dsbrPrimary;
  FCornerRadius := 4;
  ApplyTheme(TDevShellTheme.ActiveTheme);
  SetBounds(0, 0, NaturalWidth, ScaleValue(28));
end;

procedure TDevShellBadgeLabel.AdjustBounds;
begin
  if not (csReading in ComponentState) then
    Width := NaturalWidth;
end;

procedure TDevShellBadgeLabel.ChangeScale(M, D: Integer;
  isDpiChange: Boolean);
begin
  inherited;
  AdjustBounds;
end;

procedure TDevShellBadgeLabel.ApplyTheme(const ATheme: TDevShellTheme);
begin
  FTheme := ATheme;
  Font.Name := TDevShellTheme.cFontName;
  Font.Size := TDevShellTheme.cBadgeFontSize;
  Font.Color := BadgeAccentColor(FTheme, FBadgeRole);
  AdjustBounds;
  Invalidate;
end;

function TDevShellBadgeLabel.NaturalWidth: Integer;
begin
  var LMeasureBitmap := TBitmap.Create;
  try
    LMeasureBitmap.Canvas.Font.Assign(Font);
    Result := DevShellBadgeNaturalWidth(LMeasureBitmap.Canvas.Handle,
      Caption, CurrentPPI);
  finally
    LMeasureBitmap.Free;
  end;
end;

procedure TDevShellBadgeLabel.SetBadgeRole(AValue: TDevShellBadgeRole);
begin
  if FBadgeRole = AValue then
    Exit;
  FBadgeRole := AValue;
  Font.Color := BadgeAccentColor(FTheme, FBadgeRole);
  Invalidate;
end;

procedure TDevShellBadgeLabel.SetCornerRadius(AValue: Integer);
begin
  var LRadius := Max(0, AValue);
  if FCornerRadius = LRadius then
    Exit;
  FCornerRadius := LRadius;
  Invalidate;
end;

procedure TDevShellBadgeLabel.Paint;
begin
  Canvas.Font.Assign(Font);
  DrawDevShellBadge(Canvas.Handle, ClientRect, Caption, FTheme, FBadgeRole,
    CurrentPPI, Enabled, FCornerRadius);
end;

procedure DrawSphere(const AGraphics: TGPGraphics; const ABounds: TGPRectF;
  AColor: TColor; const ATheme: TDevShellTheme);
begin
  if (ABounds.Width <= 0.0) or (ABounds.Height <= 0.0) then
    Exit;

  var LLightColor := BlendColor(AColor, ATheme.TextColor, 0.58);
  var LDarkColor := BlendColor(AColor, ATheme.BackgroundColor, 0.42);
  var LBorderWidth: Single := Max(1.0,
    Min(ABounds.Width, ABounds.Height) / 14.0);
  var LCirclePath := TGPGraphicsPath.Create;
  try
    LCirclePath.AddEllipse(ABounds);
    var LGradient := TGPLinearGradientBrush.Create(ABounds,
      GPColor(LLightColor), GPColor(LDarkColor), LinearGradientModeVertical);
    try
      AGraphics.FillPath(LGradient, LCirclePath);
    finally
      LGradient.Free;
    end;

    var LHighlightBounds := MakeRect(ABounds.X + ABounds.Width * 0.20,
      ABounds.Y + ABounds.Height * 0.13, ABounds.Width * 0.48,
      ABounds.Height * 0.34);
    var LHighlightPath := TGPGraphicsPath.Create;
    try
      LHighlightPath.AddEllipse(LHighlightBounds);
      var LHighlight := TGPSolidBrush.Create(
        GPColor(ATheme.TextColor, 118));
      try
        AGraphics.FillPath(LHighlight, LHighlightPath);
      finally
        LHighlight.Free;
      end;
    finally
      LHighlightPath.Free;
    end;

    var LBorderPen := TGPPen.Create(
      GPColor(BlendColor(AColor, ATheme.BackgroundColor, 0.55)),
      LBorderWidth);
    try
      LBorderPen.SetLineJoin(LineJoinRound);
      AGraphics.DrawPath(LBorderPen, LCirclePath);
    finally
      LBorderPen.Free;
    end;
  finally
    LCirclePath.Free;
  end;
end;

function TryGetBulletColor(const AIconName: string;
  const ATheme: TDevShellTheme; out AColor: TColor): Boolean;
begin
  var LName := LowerCase(ExtractFileName(AIconName));
  Result := True;
  if LName = 'bullet_green.ico' then
    AColor := ATheme.SuccessColor
  else if LName = 'bullet_orange.ico' then
    AColor := ATheme.WarningColor
  else if LName = 'bullet_pink.ico' then
    AColor := ATheme.DangerColor
  else if LName = 'bullet_purple.ico' then
    AColor := ATheme.PrimaryColor
  else if LName = 'bullet_red.ico' then
    AColor := ATheme.DangerColor
  else if LName = 'bullet_white.ico' then
    AColor := ATheme.TextColor
  else if LName = 'bullet_yellow.ico' then
    AColor := ATheme.WarningColor
  else
  begin
    AColor := clNone;
    Result := False;
  end;
end;

procedure AddBuiltInBulletIconNames(AItems: TStrings);
begin
  if AItems = nil then
    Exit;
  for var LIconName in cBulletIconNames do
    if AItems.IndexOf(LIconName) < 0 then
      AItems.Add(LIconName);
end;

procedure DrawAntialiasedSphere(const ACanvas: TCanvas; const ABounds: TRect;
  AColor: TColor; const ATheme: TDevShellTheme);
begin
  if (ACanvas = nil) or (ABounds.Width <= 0) or (ABounds.Height <= 0) then
    Exit;
  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    LGraphics.SetCompositingMode(CompositingModeSourceOver);
    var LInset: Single := Max(1.0,
      Min(ABounds.Width, ABounds.Height) / 16.0);
    var LSphereBounds := MakeRect(ABounds.Left + LInset,
      ABounds.Top + LInset, ABounds.Width - LInset * 2.0,
      ABounds.Height - LInset * 2.0);
    DrawSphere(LGraphics, LSphereBounds, AColor, ATheme);
  finally
    LGraphics.Free;
  end;
end;

procedure CreateBulletBitmap(ABitmap: TBitmap; AColor: TColor; ASize: Integer;
  const ATheme: TDevShellTheme);
var
  LHandle: HBITMAP;
begin
  if (ABitmap = nil) or (ASize <= 0) then
    Exit;
  var LGPBitmap := TGPBitmap.Create(ASize, ASize, PixelFormat32bppPARGB);
  try
    var LGraphics := TGPGraphics.Create(LGPBitmap);
    try
      LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
      LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
      LGraphics.SetCompositingMode(CompositingModeSourceCopy);
      LGraphics.Clear(MakeColor(0, 0, 0, 0));
      LGraphics.SetCompositingMode(CompositingModeSourceOver);
      var LInset: Single := Max(1.0, ASize / 16.0);
      DrawSphere(LGraphics, MakeRect(LInset, LInset,
        ASize - LInset * 2.0, ASize - LInset * 2.0), AColor, ATheme);
    finally
      LGraphics.Free;
    end;
    if LGPBitmap.GetHBITMAP(MakeColor(0, 0, 0, 0), LHandle) <> Ok then
      raise EInvalidGraphic.Create('Unable to create the bullet bitmap.');
    ABitmap.Handle := LHandle;
    ABitmap.PixelFormat := pf32bit;
  finally
    LGPBitmap.Free;
  end;
end;

function CreateBulletIcon(AColor: TColor; ASize: Integer;
  const ATheme: TDevShellTheme): HICON;
var
  LIconInfo: TIconInfo;
  LMaskBits: TBytes;
begin
  Result := 0;
  if ASize <= 0 then
    Exit;
  var LBitmap := TBitmap.Create;
  try
    CreateBulletBitmap(LBitmap, AColor, ASize, ATheme);
    var LMaskStride := ((ASize + 15) div 16) * 2;
    SetLength(LMaskBits, LMaskStride * ASize);
    FillChar(LMaskBits[0], Length(LMaskBits), 0);
    FillChar(LIconInfo, SizeOf(LIconInfo), 0);
    LIconInfo.fIcon := True;
    LIconInfo.hbmColor := LBitmap.Handle;
    LIconInfo.hbmMask := CreateBitmap(ASize, ASize, 1, 1, @LMaskBits[0]);
    if LIconInfo.hbmMask <> 0 then
    try
      Result := CreateIconIndirect(LIconInfo);
    finally
      DeleteObject(LIconInfo.hbmMask);
    end;
  finally
    LBitmap.Free;
  end;
end;

end.
