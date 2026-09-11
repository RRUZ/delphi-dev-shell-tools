//**************************************************************************************************
//
// Unit DelphiDevShellTools.UI
// Shared theme, flat controls and DPI-aware drawing helpers.
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
  Winapi.Messages,
  System.Classes,
  System.Types,
  System.UITypes,
  Vcl.Controls,
  Vcl.ComCtrls,
  Vcl.ControlList,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.ImgList,
  Vcl.StdCtrls,
  Vcl.Themes;

const
  cDevShellComboBoxButtonWidth = 26;

type
  TDevShellThemeKind = (dstLight, dstDark);
  TDevShellChevronDirection = (dscdUp, dscdDown, dscdLeft, dscdRight);

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
    AccentColor: TColor;
    PrimaryColor: TColor;
    SecondaryColor: TColor;
    SuccessColor: TColor;
    WarningColor: TColor;
    DangerColor: TColor;
    class function DarkTheme: TDevShellTheme; static;
    class function LightTheme: TDevShellTheme; static;
    class function ActiveTheme: TDevShellTheme; static;
  end;

  // Palette rendering over Delphi 13's native combo selection/scrolling machinery.
  TDevShellComboBoxStyleHook = class(TComboBoxStyleHook)
  private
    FPaintingPopup: Boolean;
    procedure PaintItem(ACanvas: TCanvas; AIndex: Integer;
      const ARect: TRect; ASelected, AComboEdit: Boolean);
    procedure PaintPopup(ADC: HDC);
    procedure PaintPopupScrollBar(ACanvas: TCanvas; const ABounds: TRect);
  protected
    procedure PaintBorder(ACanvas: TCanvas); override;
    procedure DrawItem(ACanvas: TCanvas; AIndex: Integer;
      const ARect: TRect; ASelected: Boolean); override;
    procedure WndProc(var AMessage: TMessage); override;
    procedure ListBoxWndProc(var AMessage: TMessage); override;
  end;

  // Override only VCL's virtual scrollbar painters; input remains in the base hooks.
  TDevShellMemoStyleHook = class(TMemoStyleHook)
  protected
    procedure DrawVertScroll(ADC: HDC); override;
    procedure DrawHorzScroll(ADC: HDC); override;
    procedure DrawBorder; override;
    procedure WndProc(var AMessage: TMessage); override;
  end;

  TDevShellControlListStyleHook = class(TScrollingStyleHook)
  protected
    procedure DrawVertScroll(ADC: HDC); override;
    procedure DrawHorzScroll(ADC: HDC); override;
    procedure DrawBorder; override;
  end;

  TDevShellListViewStyleHook = class(TListViewStyleHook)
  protected
    procedure DrawVertScroll(ADC: HDC); override;
    procedure DrawHorzScroll(ADC: HDC); override;
    procedure DrawBorder; override;
  end;

  TDevShellCheckBoxStyleHook = class(TCheckBoxStyleHook)
  protected
    procedure Paint(ACanvas: TCanvas); override;
    procedure PaintBackground(ACanvas: TCanvas); override;
  end;

  TSimpleUIButtonImagePosition = (buipLeft, buipRight, buipTop, buipBottom);

  TSimpleUIButtonPalette = record
    Background: TColor;
    HotBackground: TColor;
    PressedBackground: TColor;
    DisabledBackground: TColor;
    Border: TColor;
    HotBorder: TColor;
    PressedBorder: TColor;
    FocusedBorder: TColor;
    DisabledBorder: TColor;
    Text: TColor;
    HotText: TColor;
    PressedText: TColor;
    DisabledText: TColor;
  end;

  TSimpleUIButton = class(TCustomControl)
  private
    FBackgroundColor: TColor;
    FHotBackgroundColor: TColor;
    FPressedBackgroundColor: TColor;
    FDisabledBackgroundColor: TColor;
    FBorderColor: TColor;
    FHotBorderColor: TColor;
    FPressedBorderColor: TColor;
    FFocusedBorderColor: TColor;
    FDisabledBorderColor: TColor;
    FTextColor: TColor;
    FHotTextColor: TColor;
    FPressedTextColor: TColor;
    FDisabledTextColor: TColor;
    FBorderWidth: Single;
    FCornerRadius: Integer;
    FContentPadding: Integer;
    FImageSpacing: Integer;
    FImages: TCustomImageList;
    FImageChangeLink: TChangeLink;
    FImageIndex: System.UITypes.TImageIndex;
    FImageName: System.UITypes.TImageName;
    FImagePosition: TSimpleUIButtonImagePosition;
    FHot: Boolean;
    FPressed: Boolean;
    FKeyboardPressed: Boolean;
    FActive: Boolean;
    FDefault: Boolean;
    FCancel: Boolean;
    FModalResult: TModalResult;
    procedure CMCancelMode(var AMessage: TCMCancelMode); message CM_CANCELMODE;
    procedure CMDialogChar(var AMessage: TCMDialogChar); message CM_DIALOGCHAR;
    procedure CMDialogKey(var AMessage: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMEnabledChanged(var AMessage: TMessage); message CM_ENABLEDCHANGED;
    procedure CMFocusChanged(var AMessage: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure CMMouseEnter(var AMessage: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var AMessage: TMessage); message CM_MOUSELEAVE;
    procedure CMTextChanged(var AMessage: TMessage); message CM_TEXTCHANGED;
    procedure WMEraseBkgnd(var AMessage: TWMEraseBkgnd); message WM_ERASEBKGND;
    procedure ImagesChanged(Sender: TObject);
    function ResolveImageIndex: System.UITypes.TImageIndex;
    procedure SetBackgroundColor(const AValue: TColor);
    procedure SetBorderColor(const AValue: TColor);
    procedure SetBorderWidth(const AValue: Single);
    procedure SetCancel(const AValue: Boolean);
    procedure SetContentPadding(const AValue: Integer);
    procedure SetCornerRadius(const AValue: Integer);
    procedure SetDefault(const AValue: Boolean);
    procedure SetDisabledBackgroundColor(const AValue: TColor);
    procedure SetDisabledBorderColor(const AValue: TColor);
    procedure SetDisabledTextColor(const AValue: TColor);
    procedure SetFocusedBorderColor(const AValue: TColor);
    procedure SetHotBackgroundColor(const AValue: TColor);
    procedure SetHotBorderColor(const AValue: TColor);
    procedure SetHotTextColor(const AValue: TColor);
    procedure SetImageIndex(const AValue: System.UITypes.TImageIndex);
    procedure SetImageName(const AValue: System.UITypes.TImageName);
    procedure SetImagePosition(const AValue: TSimpleUIButtonImagePosition);
    procedure SetImages(const AValue: TCustomImageList);
    procedure SetImageSpacing(const AValue: Integer);
    procedure SetPressedBackgroundColor(const AValue: TColor);
    procedure SetPressedBorderColor(const AValue: TColor);
    procedure SetPressedTextColor(const AValue: TColor);
    procedure SetTextColor(const AValue: TColor);
  protected
    procedure KeyDown(var AKey: Word; AShift: TShiftState); override;
    procedure KeyUp(var AKey: Word; AShift: TShiftState); override;
    procedure MouseDown(AButton: TMouseButton; AShift: TShiftState;
      X, Y: Integer); override;
    procedure MouseUp(AButton: TMouseButton; AShift: TShiftState;
      X, Y: Integer); override;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ApplyPalette(const APalette: TSimpleUIButtonPalette);
    procedure Click; override;
  published
    property Action;
    property Align;
    property Anchors;
    property BackgroundColor: TColor read FBackgroundColor
      write SetBackgroundColor;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property BorderWidth: Single read FBorderWidth write SetBorderWidth;
    property Cancel: Boolean read FCancel write SetCancel default False;
    property Caption;
    property Constraints;
    property ContentPadding: Integer read FContentPadding
      write SetContentPadding;
    property CornerRadius: Integer read FCornerRadius write SetCornerRadius;
    property Cursor;
    property Default: Boolean read FDefault write SetDefault default False;
    property DisabledBackgroundColor: TColor read FDisabledBackgroundColor
      write SetDisabledBackgroundColor;
    property DisabledBorderColor: TColor read FDisabledBorderColor
      write SetDisabledBorderColor;
    property DisabledTextColor: TColor read FDisabledTextColor
      write SetDisabledTextColor;
    property Enabled;
    property FocusedBorderColor: TColor read FFocusedBorderColor
      write SetFocusedBorderColor;
    property Font;
    property Height;
    property Hint;
    property HotBackgroundColor: TColor read FHotBackgroundColor
      write SetHotBackgroundColor;
    property HotBorderColor: TColor read FHotBorderColor
      write SetHotBorderColor;
    property HotTextColor: TColor read FHotTextColor write SetHotTextColor;
    property ImageIndex: System.UITypes.TImageIndex read FImageIndex
      write SetImageIndex;
    property ImageName: System.UITypes.TImageName read FImageName
      write SetImageName;
    property ImagePosition: TSimpleUIButtonImagePosition read FImagePosition
      write SetImagePosition default buipLeft;
    property Images: TCustomImageList read FImages write SetImages;
    property ImageSpacing: Integer read FImageSpacing write SetImageSpacing;
    property Left;
    property ModalResult: TModalResult read FModalResult write FModalResult
      default mrNone;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property PressedBackgroundColor: TColor read FPressedBackgroundColor
      write SetPressedBackgroundColor;
    property PressedBorderColor: TColor read FPressedBorderColor
      write SetPressedBorderColor;
    property PressedTextColor: TColor read FPressedTextColor
      write SetPressedTextColor;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property TextColor: TColor read FTextColor write SetTextColor;
    property Top;
    property Visible;
    property Width;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
    property OnMouseDown;
    property OnMouseEnter;
    property OnMouseLeave;
    property OnMouseMove;
    property OnMouseUp;
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
procedure SetDevShellThemeOverride(AThemeKind: TDevShellThemeKind);
procedure ClearDevShellThemeOverride;
function BlendColor(AColor, ATarget: TColor; AAmount: Single): TColor;

function ResolveMenuSurfaceTheme(ADC: HDC;
  const ABounds: TRect): TDevShellTheme;
procedure DrawRoundedRectangle(ADC: HDC; const ABounds: TRect;
  AFillColor, ABorderColor: TColor; ARadius, ABorderWidth: Single);
procedure DrawAntialiasedRoundedRectangle(const ACanvas: TCanvas;
  const ARect: TRect; AFillColor, ABorderColor: TColor; ARadius,
  ABorderWidth: Single);
function DevShellButtonPalette(
  const ATheme: TDevShellTheme): TSimpleUIButtonPalette;
procedure ApplyDevShellThemeToButton(AButton: TSimpleUIButton;
  const ATheme: TDevShellTheme);
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
procedure DrawDevShellChevron(const ACanvas: TCanvas; const ACenter: TPoint;
  AColor: TColor; ADirection: TDevShellChevronDirection;
  ADeviceScale: Single = 1.0);
procedure SetDevShellFont(AControl: TControl; const AFontName: string;
  APointSize: Integer);

implementation

uses
  System.Math,
  System.SysUtils,
  System.Win.Registry,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ;

var
  GHasDevShellThemeOverride: Boolean;
  GDevShellThemeOverride: TDevShellThemeKind;

type
  TDevShellFontControl = class(TControl);
  TDevShellCheckBoxAccess = class(TCustomCheckBox);

const
  cBadgeHorizontalPadding = 8;
  cBadgeVerticalPadding = 3;
  cInputCornerRadius = 2;

procedure SetDevShellFont(AControl: TControl; const AFontName: string;
  APointSize: Integer);
begin
  TDevShellFontControl(AControl).Font.Name := AFontName;
  var LDesignHeight := -MulDiv(APointSize, 96, 72);
  var LPPI := Round(96 * AControl.ScaleFactor);
  TDevShellFontControl(AControl).Font.ChangeScale(LDesignHeight, LPPI, 96,
    True);
end;

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

procedure DrawDevShellChevron(const ACanvas: TCanvas; const ACenter: TPoint;
  AColor: TColor; ADirection: TDevShellChevronDirection;
  ADeviceScale: Single);
begin
  var LRGBColor := ColorToRGB(AColor);
  var LColor := MakeColor(255, GetRValue(LRGBColor), GetGValue(LRGBColor),
    GetBValue(LRGBColor));
  var LHalfWidth := 3.0 * ADeviceScale;
  var LHalfHeight := 2.0 * ADeviceScale;
  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LPen := TGPPen.Create(LColor, 1.6 * ADeviceScale);
    try
      LPen.SetLineJoin(LineJoinRound);
      LPen.SetStartCap(LineCapRound);
      LPen.SetEndCap(LineCapRound);
      case ADirection of
        dscdUp:
          begin
            LGraphics.DrawLine(LPen, ACenter.X - LHalfWidth,
              ACenter.Y + (LHalfHeight / 2), ACenter.X,
              ACenter.Y - LHalfHeight);
            LGraphics.DrawLine(LPen, ACenter.X,
              ACenter.Y - LHalfHeight, ACenter.X + LHalfWidth,
              ACenter.Y + (LHalfHeight / 2));
          end;
        dscdDown:
          begin
            LGraphics.DrawLine(LPen, ACenter.X - LHalfWidth,
              ACenter.Y - (LHalfHeight / 2), ACenter.X,
              ACenter.Y + LHalfHeight);
            LGraphics.DrawLine(LPen, ACenter.X,
              ACenter.Y + LHalfHeight, ACenter.X + LHalfWidth,
              ACenter.Y - (LHalfHeight / 2));
          end;

        dscdLeft:
          begin
            LGraphics.DrawLine(LPen, ACenter.X + (LHalfHeight / 2),
              ACenter.Y - LHalfWidth, ACenter.X - LHalfHeight, ACenter.Y);
            LGraphics.DrawLine(LPen, ACenter.X - LHalfHeight, ACenter.Y,
              ACenter.X + (LHalfHeight / 2), ACenter.Y + LHalfWidth);
          end;
        dscdRight:
          begin
            LGraphics.DrawLine(LPen, ACenter.X - (LHalfHeight / 2),
              ACenter.Y - LHalfWidth, ACenter.X + LHalfHeight, ACenter.Y);
            LGraphics.DrawLine(LPen, ACenter.X + LHalfHeight, ACenter.Y,
              ACenter.X - (LHalfHeight / 2), ACenter.Y + LHalfWidth);
          end;
      end;
    finally
      LPen.Free;
    end;
  finally
    LGraphics.Free;
  end;
end;


procedure TDevShellCheckBoxStyleHook.PaintBackground(ACanvas: TCanvas);
begin
    var LSavedDC := SaveDC(ACanvas.Handle);
  try
    var LBackgroundColor := TDevShellTheme.ActiveTheme.BackgroundColor;
    if Control.Parent is TPanel then
      LBackgroundColor := TDevShellFontControl(Control.Parent).Color;
    ACanvas.Brush.Color := LBackgroundColor;
    ACanvas.FillRect(Control.ClientRect);
  finally
    var LDC := ACanvas.Handle;
    ACanvas.Refresh;
    RestoreDC(LDC, LSavedDC);
  end;
end;

procedure TDevShellCheckBoxStyleHook.Paint(ACanvas: TCanvas);
begin
  var LSavedDC := SaveDC(ACanvas.Handle);
  try
    var LBounds := Control.ClientRect;
    IntersectClipRect(ACanvas.Handle, LBounds.Left, LBounds.Top,
      LBounds.Right, LBounds.Bottom);
    PaintBackground(ACanvas);
    var LTheme := TDevShellTheme.ActiveTheme;
    var LScale := Control.CurrentPPI / 96;
    var LSize := Min(Round(14 * LScale), Min(LBounds.Width, LBounds.Height));
    var LBox := Rect(0, (LBounds.Height - LSize) div 2,
      LSize, (LBounds.Height + LSize) div 2);
    // Match Vcl.StdCtrls.TCheckBoxStyleHook.RightAlignment, including RTL.
    var LRightAligned := (Control.BiDiMode = bdRightToLeft) or
      ((GetWindowLong(Handle, GWL_STYLE) and BS_RIGHTBUTTON) <> 0);
    if LRightAligned then
      OffsetRect(LBox, LBounds.Width - LSize, 0);
    var LState := SendMessage(Handle, BM_GETCHECK, 0, 0);
    var LUIState := SendMessage(Handle, WM_QUERYUISTATE, 0, 0);
    var LFocused := Control.Focused and ((LUIState and UISF_HIDEFOCUS) = 0);
    var LPressed := Pressed or
      ((SendMessage(Handle, BM_GETSTATE, 0, 0) and BST_PUSHED) <> 0);
    var LBorder := BlendColor(LTheme.BackgroundColor, LTheme.MutedColor, 0.75);
    var LFill := LTheme.BackgroundColor;
    var LMark := LTheme.AccentColor;
    if Control.Enabled then
    begin
      if (LState <> BST_UNCHECKED) or MouseInControl or LFocused then
        LBorder := LTheme.AccentColor;
      if LState <> BST_UNCHECKED then
        LFill := BlendColor(LTheme.BackgroundColor, LTheme.AccentColor, 0.16);
      if MouseInControl then
        LFill := BlendColor(LFill, LTheme.AccentColor, 0.10);
      if LPressed then
        LFill := BlendColor(LFill, LTheme.AccentColor, 0.20);
    end
    else
    begin
      LBorder := BlendColor(LTheme.BackgroundColor, LTheme.MutedColor, 0.35);
      LMark := LTheme.MutedColor;
    end;
    DrawAntialiasedRoundedRectangle(ACanvas, LBox, LFill, LBorder,
      3 * LScale, LScale);
    if LState <> BST_UNCHECKED then
    begin
      var LGraphics := TGPGraphics.Create(ACanvas.Handle);
      try
        LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
        LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
        var LPen := TGPPen.Create(GPColor(LMark), 1.7 * LScale);
        try
          LPen.SetStartCap(LineCapRound);
          LPen.SetEndCap(LineCapRound);
          LPen.SetLineJoin(LineJoinRound);
          if LState = BST_INDETERMINATE then
            LGraphics.DrawLine(LPen, LBox.Left + LSize * 0.28,
              LBox.Top + LSize * 0.5, LBox.Left + LSize * 0.72,
              LBox.Top + LSize * 0.5)
          else
          begin
            LGraphics.DrawLine(LPen, LBox.Left + LSize * 0.24,
              LBox.Top + LSize * 0.50, LBox.Left + LSize * 0.43,
              LBox.Top + LSize * 0.70);
            LGraphics.DrawLine(LPen, LBox.Left + LSize * 0.43,
              LBox.Top + LSize * 0.70, LBox.Left + LSize * 0.77,
              LBox.Top + LSize * 0.29);
          end;
        finally
          LPen.Free;
        end;
      finally
        LGraphics.Free;
      end;
    end;
    var LTextRect := LBounds;
    if LRightAligned then
      LTextRect.Right := LBox.Left - Round(3 * LScale)
    else
      LTextRect.Left := LBox.Right + Round(3 * LScale);
    ACanvas.Font.Assign(TDevShellFontControl(Control).Font);
    if Control.Enabled then
      ACanvas.Font.Color := LTheme.TextColor
    else
      ACanvas.Font.Color := LTheme.MutedColor;
    SetBkMode(ACanvas.Handle, TRANSPARENT);
    var LFlags: Cardinal := DT_EXPANDTABS;
    if TDevShellCheckBoxAccess(Control).WordWrap then
      LFlags := LFlags or DT_WORDBREAK
    else
      LFlags := LFlags or DT_SINGLELINE;
    LFlags := Control.DrawTextBiDiModeFlags(LFlags);
    if (LUIState and UISF_HIDEACCEL) <> 0 then
      LFlags := LFlags or DT_HIDEPREFIX;
    var LCaption := Text;
    var LMeasured := LTextRect;
    DrawText(ACanvas.Handle, PChar(LCaption), Length(LCaption),
      LMeasured, LFlags or DT_CALCRECT);
    LTextRect.Top := Max(0, (LBounds.Height - LMeasured.Height) div 2);
    DrawText(ACanvas.Handle, PChar(LCaption), Length(LCaption),
      LTextRect, LFlags);
    if LFocused then
    begin
      var LFocusRect := LBounds;
      InflateRect(LFocusRect, -1, -1);
      DrawAntialiasedRoundedRectangle(ACanvas, LFocusRect, clNone,
        LTheme.AccentColor, 3 * LScale, LScale);
    end;
  finally
    var LDC := ACanvas.Handle;
    ACanvas.Refresh;
    RestoreDC(LDC, LSavedDC);
  end;
end;

function ScrollPartColor(const ATheme: TDevShellTheme;
  AState: TThemedScrollBar; AEnabled, AThumb: Boolean): TColor;
begin
  if not AEnabled or (AState in [tsArrowBtnUpDisabled, tsArrowBtnDownDisabled,
    tsArrowBtnLeftDisabled, tsArrowBtnRightDisabled,
    tsThumbBtnHorzDisabled, tsThumbBtnVertDisabled]) then
    Exit(BlendColor(ATheme.BackgroundColor, ATheme.MutedColor, 0.35));
  case AState of
    tsArrowBtnUpPressed, tsArrowBtnDownPressed,
    tsArrowBtnLeftPressed, tsArrowBtnRightPressed,
    tsThumbBtnHorzPressed, tsThumbBtnVertPressed:
      Result := ATheme.AccentColor;
    tsArrowBtnUpHot, tsArrowBtnDownHot,
    tsArrowBtnLeftHot, tsArrowBtnRightHot,
    tsThumbBtnHorzHot, tsThumbBtnVertHot:
      Result := BlendColor(ATheme.MutedColor, ATheme.AccentColor, 0.65);
  else
    if AThumb then
      Result := BlendColor(ATheme.BackgroundColor, ATheme.MutedColor, 0.62)
    else
      Result := ATheme.MutedColor;
  end;
end;

procedure PaintDevShellScrollBar(ADC: HDC; AControl: TWinControl;
  const ABounds, AThumb, AFirstButton, ALastButton: TRect;
  AThumbState, AFirstState, ALastState: TThemedScrollBar; AVertical: Boolean);
var
  LFirstDirection, LLastDirection: TDevShellChevronDirection;
begin
  if (ADC = 0) or ABounds.IsEmpty then
    Exit;
  // Vcl.Forms.TScrollWindow supplies a DC whose origin is already shifted to
  // the control window. Use the base hook's rectangles for exact hit alignment.
  var LSavedDC := SaveDC(ADC);
  try
    IntersectClipRect(ADC, ABounds.Left, ABounds.Top,
      ABounds.Right, ABounds.Bottom);
    var LCanvas := TCanvas.Create;
    try
      LCanvas.Handle := ADC;
      var LTheme := TDevShellTheme.ActiveTheme;
      var LScale := AControl.CurrentPPI / 96;
      LCanvas.Brush.Color := LTheme.BackgroundColor;
      LCanvas.FillRect(ABounds);
      var LEnabled := AControl.Enabled and not AThumb.IsEmpty;
      if LEnabled then
      begin
        var LThumb := AThumb;
        var LInset := Max(1, Round(4 * LScale));
        if AVertical then
          InflateRect(LThumb, -Min(LInset, (LThumb.Width - 2) div 2), -1)
        else
          InflateRect(LThumb, -1, -Min(LInset, (LThumb.Height - 2) div 2));
        DrawAntialiasedRoundedRectangle(LCanvas, LThumb,
          ScrollPartColor(LTheme, AThumbState, True, True), clNone,
          Min(LThumb.Width, LThumb.Height) / 2, 0);
      end;
      if AVertical then
      begin
        LFirstDirection := dscdUp;
        LLastDirection := dscdDown;
      end
      else
      begin
        LFirstDirection := dscdLeft;
        LLastDirection := dscdRight;
      end;
      DrawDevShellChevron(LCanvas, AFirstButton.CenterPoint,
        ScrollPartColor(LTheme, AFirstState, LEnabled, False),
        LFirstDirection, LScale);
      DrawDevShellChevron(LCanvas, ALastButton.CenterPoint,
        ScrollPartColor(LTheme, ALastState, LEnabled, False),
        LLastDirection, LScale);
    finally
      LCanvas.Handle := 0;
      LCanvas.Free;
    end;
  finally
    RestoreDC(ADC, LSavedDC);
  end;
end;

procedure PaintDevShellScrollFrame(AControl: TWinControl);
var
  LWindowRect, LClientRect: TRect;
  LClientOrigin: TPoint;
begin
  if not AControl.HandleAllocated then
    Exit;
  var LDC := GetWindowDC(AControl.Handle);
  if LDC = 0 then
    Exit;
  try
    var LSavedDC := SaveDC(LDC);
    try
      GetWindowRect(AControl.Handle, LWindowRect);
      GetClientRect(AControl.Handle, LClientRect);
      LClientOrigin := Point(0, 0);
      ClientToScreen(AControl.Handle, LClientOrigin);
      OffsetRect(LClientRect, LClientOrigin.X - LWindowRect.Left,
        LClientOrigin.Y - LWindowRect.Top);
      OffsetRect(LWindowRect, -LWindowRect.Left, -LWindowRect.Top);
      ExcludeClipRect(LDC, LClientRect.Left, LClientRect.Top,
        LClientRect.Right, LClientRect.Bottom);
      var LCanvas := TCanvas.Create;
      try
        LCanvas.Handle := LDC;
        var LTheme := TDevShellTheme.ActiveTheme;
        LCanvas.Brush.Color := LTheme.BackgroundColor;
        // Also covers the square where horizontal and vertical bars meet.
        LCanvas.FillRect(LWindowRect);
        if ((GetWindowLong(AControl.Handle, GWL_STYLE) and WS_BORDER) <> 0) or
          ((GetWindowLong(AControl.Handle, GWL_EXSTYLE) and WS_EX_CLIENTEDGE) <> 0) then
          DrawAntialiasedRoundedRectangle(LCanvas, LWindowRect, clNone,
            BlendColor(LTheme.BackgroundColor, LTheme.MutedColor, 0.4),
            2 * AControl.ScaleFactor, AControl.ScaleFactor);
      finally
        LCanvas.Handle := 0;
        LCanvas.Free;
      end;
    finally
      RestoreDC(LDC, LSavedDC);
    end;
  finally
    ReleaseDC(AControl.Handle, LDC);
  end;
end;

procedure TDevShellMemoStyleHook.DrawVertScroll(ADC: HDC);
begin
  PaintDevShellScrollBar(ADC, Control, VertScrollRect, VertSliderRect,
    VertUpButtonRect, VertDownButtonRect, VertSliderState,
    VertUpState, VertDownState, True);
end;

procedure TDevShellMemoStyleHook.DrawHorzScroll(ADC: HDC);
begin
  PaintDevShellScrollBar(ADC, Control, HorzScrollRect, HorzSliderRect,
    HorzUpButtonRect, HorzDownButtonRect, HorzSliderState,
    HorzUpState, HorzDownState, False);
end;

procedure TDevShellMemoStyleHook.DrawBorder;
begin
  PaintDevShellScrollFrame(Control);
end;

procedure TDevShellControlListStyleHook.DrawVertScroll(ADC: HDC);
begin
  PaintDevShellScrollBar(ADC, Control, VertScrollRect, VertSliderRect,
    VertUpButtonRect, VertDownButtonRect, VertSliderState,
    VertUpState, VertDownState, True);
end;

procedure TDevShellControlListStyleHook.DrawHorzScroll(ADC: HDC);
begin
  PaintDevShellScrollBar(ADC, Control, HorzScrollRect, HorzSliderRect,
    HorzUpButtonRect, HorzDownButtonRect, HorzSliderState,
    HorzUpState, HorzDownState, False);
end;

procedure TDevShellControlListStyleHook.DrawBorder;
begin
  PaintDevShellScrollFrame(Control);
end;

procedure TDevShellListViewStyleHook.DrawVertScroll(ADC: HDC);
begin
  PaintDevShellScrollBar(ADC, Control, VertScrollRect, VertSliderRect,
    VertUpButtonRect, VertDownButtonRect, VertSliderState,
    VertUpState, VertDownState, True);
end;

procedure TDevShellListViewStyleHook.DrawHorzScroll(ADC: HDC);
begin
  PaintDevShellScrollBar(ADC, Control, HorzScrollRect, HorzSliderRect,
    HorzUpButtonRect, HorzDownButtonRect, HorzSliderState,
    HorzUpState, HorzDownState, False);
end;

procedure TDevShellListViewStyleHook.DrawBorder;
begin
  PaintDevShellScrollFrame(Control);
end;

procedure TDevShellMemoStyleHook.WndProc(var AMessage: TMessage);
begin
  // TMemoStyleHook.UpdateColors is private and normally substitutes VSF colors.
  // Keep the native memo and caret, but supply the same palette as its bars.
  case AMessage.Msg of
    CN_CTLCOLORMSGBOX..CN_CTLCOLORSTATIC:
      begin
        var LTheme := TDevShellTheme.ActiveTheme;
        Brush.Color := LTheme.BackgroundColor;
        if Control.Enabled then
          FontColor := LTheme.TextColor
        else
          FontColor := LTheme.MutedColor;
        SetTextColor(AMessage.WParam, ColorToRGB(FontColor));
        SetBkColor(AMessage.WParam, ColorToRGB(Brush.Color));
        AMessage.Result := LRESULT(Brush.Handle);
        Handled := True;
        Exit;
      end;
  end;
  inherited WndProc(AMessage);
end;

procedure TDevShellComboBoxStyleHook.PaintBorder(ACanvas: TCanvas);
var
  LInfo: TComboBoxInfo;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  Brush.Color := LTheme.BackgroundColor;
  FontColor := LTheme.TextColor;
  var LCombo := TComboBox(Control);
  var LBounds := Control.ClientRect;
  var LSavedDC := SaveDC(ACanvas.Handle);
  try
    // VCL keeps an actual EDIT child for editable combos. Never paint over it.
    LInfo := Default(TComboBoxInfo);
    LInfo.cbSize := SizeOf(LInfo);
    if GetComboBoxInfo(Handle, LInfo) and
       (LCombo.Style in [csDropDown, csSimple]) then
      ExcludeClipRect(ACanvas.Handle, LInfo.rcItem.Left, LInfo.rcItem.Top,
        LInfo.rcItem.Right, LInfo.rcItem.Bottom);
    ACanvas.Brush.Color := LTheme.BackgroundColor;
    ACanvas.FillRect(LBounds);
    var LBorder := BlendColor(LTheme.TextColor, LTheme.BackgroundColor, 0.78);
    var LArrow := LTheme.MutedColor;
    if Control.Enabled and (Focused or MouseInControl or LCombo.DroppedDown) then
    begin
      LBorder := LTheme.AccentColor;
      LArrow := LTheme.TextColor;
    end;
    DrawAntialiasedRoundedRectangle(ACanvas, LBounds,
      LTheme.BackgroundColor, LBorder,
      MulDiv(cInputCornerRadius, Control.CurrentPPI, 96),
      Max(Single(1), Single(Control.CurrentPPI / 96.0)));
    if LCombo.Style = csSimple then
      Exit;
    // Use the VCL button geometry: it is also used for hit testing and text clipping.
    var LButton := ButtonRect;
    var LDivider := LButton.Left;
    if Control.BiDiMode = bdRightToLeft then
      LDivider := LButton.Right;
    ACanvas.Pen.Color := BlendColor(LTheme.TextColor, LTheme.BackgroundColor, 0.88);
    ACanvas.Pen.Width := 1;
    ACanvas.MoveTo(LDivider, LButton.Top + 3);
    ACanvas.LineTo(LDivider, LButton.Bottom - 3);
    var LDirection := dscdDown;
    if LCombo.DroppedDown then
      LDirection := dscdUp;
    DrawDevShellChevron(ACanvas, LButton.CenterPoint, LArrow,
      LDirection, Control.CurrentPPI / 96.0);
  finally
    // SaveDC restores GDI objects without updating TCanvas's cached state.
    var LDC := ACanvas.Handle;
    ACanvas.Refresh;
    RestoreDC(LDC, LSavedDC);
  end;
end;

procedure TDevShellComboBoxStyleHook.PaintItem(ACanvas: TCanvas;
  AIndex: Integer; const ARect: TRect; ASelected, AComboEdit: Boolean);
var
  LState: TOwnerDrawState;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LCombo := TComboBox(Control);
  var LSavedDC := SaveDC(ACanvas.Handle);
  try
    IntersectClipRect(ACanvas.Handle, ARect.Left, ARect.Top,
      ARect.Right, ARect.Bottom);
    ACanvas.Font.Assign(LCombo.Font);
    ACanvas.Font.Color := LTheme.TextColor;
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := LTheme.BackgroundColor;
    if not Control.Enabled then
      ACanvas.Font.Color := LTheme.MutedColor
    else if ASelected and not AComboEdit then
      ACanvas.Brush.Color := BlendColor(LTheme.AccentColor,
        LTheme.BackgroundColor, 0.82);
    ACanvas.FillRect(ARect);
    if (AIndex < 0) or (AIndex >= LCombo.Items.Count) then
      Exit;
    if Assigned(LCombo.OnDrawItem) then
    begin
      LState := [];
      if AComboEdit then Include(LState, odComboBoxEdit);
      if ASelected and not AComboEdit then Include(LState, odSelected);
      if not Control.Enabled then Include(LState, odDisabled);
      var LPreviousDC := LCombo.Canvas.Handle;
      LCombo.Canvas.Handle := ACanvas.Handle;
      try
        LCombo.Canvas.Font.Assign(ACanvas.Font);
        LCombo.Canvas.Brush.Assign(ACanvas.Brush);
        LCombo.OnDrawItem(LCombo, AIndex, ARect, LState);
      finally
        LCombo.Canvas.Handle := LPreviousDC;
      end;
    end
    else
    begin
      var LTextRect := ARect;
      InflateRect(LTextRect, -MulDiv(5, Control.CurrentPPI, 96), 0);
      var LFlags: Cardinal := DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS or DT_NOPREFIX;
      if Control.BiDiMode = bdRightToLeft then
        LFlags := LFlags or DT_RIGHT or DT_RTLREADING;
      var LText := LCombo.Items[AIndex];
      SetBkMode(ACanvas.Handle, TRANSPARENT);
      DrawText(ACanvas.Handle, PChar(LText), Length(LText), LTextRect, LFlags);
    end;
  finally
    // SaveDC restores GDI objects without updating TCanvas's cached state.
    var LDC := ACanvas.Handle;
    ACanvas.Refresh;
    RestoreDC(LDC, LSavedDC);
  end;
end;

procedure TDevShellComboBoxStyleHook.DrawItem(ACanvas: TCanvas;
  AIndex: Integer; const ARect: TRect; ASelected: Boolean);
begin
  PaintItem(ACanvas, AIndex, ARect, False, True);
end;

procedure TDevShellComboBoxStyleHook.WndProc(var AMessage: TMessage);
var
  LItem: TDrawItemStruct;
begin
  case AMessage.Msg of
    WM_CTLCOLORMSGBOX..WM_CTLCOLORSTATIC,
    CN_CTLCOLORMSGBOX..CN_CTLCOLORSTATIC:
      begin
        var LTheme := TDevShellTheme.ActiveTheme;
        Brush.Color := LTheme.BackgroundColor;
        FontColor := LTheme.TextColor;
        if not Control.Enabled then FontColor := LTheme.MutedColor;
        SetTextColor(AMessage.WParam, ColorToRGB(FontColor));
        SetBkColor(AMessage.WParam, ColorToRGB(Brush.Color));
        AMessage.Result := LRESULT(Brush.Handle);
        Handled := True;
        Exit;
      end;
  end;
  if ((AMessage.Msg = WM_DRAWITEM) or (AMessage.Msg = CN_DRAWITEM)) and
     (AMessage.LParam <> 0) then
  begin
    LItem := PDrawItemStruct(AMessage.LParam)^;
    LItem.itemState := LItem.itemState and not ODS_FOCUS;
    var LOriginalItem := AMessage.LParam;
    AMessage.LParam := LPARAM(@LItem);
    try
      // Keep VCL's canvas binding and owner-draw event dispatch. The palette
      // selection and combo border already communicate keyboard focus.
      inherited WndProc(AMessage);
    finally
      AMessage.LParam := LOriginalItem;
    end;
    Exit;
  end;
  inherited WndProc(AMessage);
end;

procedure TDevShellComboBoxStyleHook.PaintPopup(ADC: HDC);
var
  LWindowRect, LClientRect, LItemRect: TRect;
  LOrigin: TPoint;
begin
  if FPaintingPopup or (ListHandle = 0) or not IsWindowVisible(ListHandle) then
    Exit;
  FPaintingPopup := True;
  try
    GetWindowRect(ListHandle, LWindowRect);
    GetClientRect(ListHandle, LClientRect);
    LOrigin := Point(0, 0);
    ClientToScreen(ListHandle, LOrigin);
    Dec(LOrigin.X, LWindowRect.Left);
    Dec(LOrigin.Y, LWindowRect.Top);
    OffsetRect(LWindowRect, -LWindowRect.Left, -LWindowRect.Top);
    var LDC := ADC;
    if LDC = 0 then LDC := GetWindowDC(ListHandle);
    if LDC = 0 then Exit;
    try
      var LCanvas := TCanvas.Create;
      try
        LCanvas.Handle := LDC;
        try
          var LSavedDC := SaveDC(LDC);
          try
            var LTheme := TDevShellTheme.ActiveTheme;
            var LOwnerDraw := TComboBox(Control).Style in
              [csOwnerDrawFixed, csOwnerDrawVariable];
            if LOwnerDraw then
              ExcludeClipRect(LDC, LOrigin.X, LOrigin.Y,
                LOrigin.X + LClientRect.Width, LOrigin.Y + LClientRect.Height);
            LCanvas.Brush.Color := LTheme.BackgroundColor;
            LCanvas.FillRect(LWindowRect);
            LCanvas.Brush.Color := BlendColor(LTheme.TextColor,
              LTheme.BackgroundColor, 0.78);
            LCanvas.FrameRect(LWindowRect);
            var LTop := Integer(SendMessage(ListHandle, LB_GETTOPINDEX, 0, 0));
            var LCount := Integer(SendMessage(ListHandle, LB_GETCOUNT, 0, 0));
            var LSelected := Integer(SendMessage(ListHandle, LB_GETCURSEL, 0, 0));
            // LB_GETITEMRECT also handles variable-height owner-drawn rows.
            if not LOwnerDraw then
            for var LIndex := Max(0, LTop) to LCount - 1 do
            begin
              if SendMessage(ListHandle, LB_GETITEMRECT, LIndex,
                LPARAM(@LItemRect)) = LB_ERR then Break;
              if LItemRect.Top >= LClientRect.Bottom then Break;
              LItemRect.Bottom := Min(LItemRect.Bottom, LClientRect.Bottom);
              OffsetRect(LItemRect, LOrigin.X, LOrigin.Y);
              PaintItem(LCanvas, LIndex, LItemRect, LIndex = LSelected, False);
            end;
            if GetWindowLong(ListHandle, GWL_STYLE) and WS_VSCROLL <> 0 then
              PaintPopupScrollBar(LCanvas, LWindowRect);
          finally
            RestoreDC(LDC, LSavedDC);
          end;
        finally
          LCanvas.Handle := 0;
        end;
      finally
        LCanvas.Free;
      end;
    finally
      if ADC = 0 then ReleaseDC(ListHandle, LDC);
    end;
  finally
    FPaintingPopup := False;
  end;
end;

procedure TDevShellComboBoxStyleHook.PaintPopupScrollBar(ACanvas: TCanvas;
  const ABounds: TRect);
begin
  // Match Vcl.StdCtrls.ListBoxVert*Rect: inherited VCL owns drag, capture,
  // repeat timers and scrolling. Only the pixels are replaced here.
  var LTheme := TDevShellTheme.ActiveTheme;
  var LScroll := ABounds;
  InflateRect(LScroll, -1, -1);
  if Control.BiDiMode <> bdRightToLeft then
    LScroll.Left := LScroll.Right - GetSystemMetrics(SM_CXVSCROLL)
  else
    LScroll.Right := LScroll.Left + GetSystemMetrics(SM_CXVSCROLL);
  ACanvas.Brush.Color := LTheme.BackgroundColor;
  ACanvas.FillRect(LScroll);
  var LButtonHeight := Min(GetSystemMetrics(SM_CYVTHUMB), LScroll.Height div 2);
  var LUp := LScroll;
  LUp.Bottom := LUp.Top + LButtonHeight;
  var LDown := LScroll;
  LDown.Top := LDown.Bottom - LButtonHeight;
  DrawDevShellChevron(ACanvas, LUp.CenterPoint, LTheme.MutedColor,
    dscdUp, Control.CurrentPPI / 96.0);
  DrawDevShellChevron(ACanvas, LDown.CenterPoint, LTheme.MutedColor,
    dscdDown, Control.CurrentPPI / 96.0);
  var LCount := Integer(SendMessage(ListHandle, LB_GETCOUNT, 0, 0));
  var LTop := Integer(SendMessage(ListHandle, LB_GETTOPINDEX, 0, 0));
  var LItemHeight := Integer(SendMessage(ListHandle, LB_GETITEMHEIGHT, 0, 0));
  if (LCount <= 0) or (LItemHeight <= 0) then Exit;
  var LTrackSize := LDown.Top - LUp.Bottom;
  var LVisible := Min(LCount - LTop,
    (ABounds.Height - 2 + LItemHeight - 1) div LItemHeight);
  var LThumbHeight := Round(LVisible * LItemHeight /
    (1.0 + LCount * LItemHeight) * LTrackSize);
  var LMinSize := GetSystemMetrics(SM_CXHTHUMB) div 2;
  if LThumbHeight < LMinSize then
  begin
    Dec(LTrackSize, LMinSize - LThumbHeight + 1);
    LThumbHeight := LMinSize;
  end;
  var LThumb := LScroll;
  LThumb.Top := LUp.Bottom + Round(LTop / LCount * LTrackSize);
  LThumb.Bottom := LThumb.Top + LThumbHeight;
  if LTop + LVisible >= LCount then
  begin
    LThumb.Bottom := LDown.Top;
    LThumb.Top := LThumb.Bottom - LThumbHeight;
  end;
  InflateRect(LThumb, -Max(2, LScroll.Width div 4), 0);
  var LThumbColor := BlendColor(LTheme.MutedColor, LTheme.BackgroundColor, 0.45);
  DrawAntialiasedRoundedRectangle(ACanvas, LThumb, LThumbColor,
    clNone, LThumb.Width / 2, 0);
end;

procedure TDevShellComboBoxStyleHook.ListBoxWndProc(var AMessage: TMessage);
begin
  inherited ListBoxWndProc(AMessage);
  case AMessage.Msg of
    WM_PAINT, WM_NCPAINT, WM_MOUSEMOVE, WM_NCMOUSEMOVE,
    WM_MOUSELEAVE, WM_NCMOUSELEAVE, WM_LBUTTONDOWN, WM_LBUTTONUP,
    WM_NCLBUTTONDOWN, WM_NCLBUTTONUP, WM_MOUSEWHEEL, WM_TIMER,
    WM_KEYDOWN, WM_KEYUP, LB_SETTOPINDEX, LB_SETCURSEL:
      PaintPopup(0);
    WM_PRINT:
      if AMessage.WParam <> 0 then PaintPopup(AMessage.WParam);
  end;
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

procedure DrawAntialiasedRoundedRectangle(const ACanvas: TCanvas;
  const ARect: TRect; AFillColor, ABorderColor: TColor; ARadius,
  ABorderWidth: Single);
begin
  if (ARect.Width <= 0) or (ARect.Height <= 0) then
    Exit;

  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    var LPath := CreateRoundedRectanglePath(ARect, ARadius);
    try
      if AFillColor <> clNone then
      begin
        var LBrush := TGPSolidBrush.Create(GPColor(AFillColor));
        try
          LGraphics.FillPath(LBrush, LPath);
        finally
          LBrush.Free;
        end;
      end;
      if (ABorderColor <> clNone) and (ABorderWidth > 0.0) then
      begin
        var LPen := TGPPen.Create(GPColor(ABorderColor), ABorderWidth);
        try
          LPen.SetLineJoin(LineJoinRound);
          LGraphics.DrawPath(LPen, LPath);
        finally
          LPen.Free;
        end;
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
  // Match the mockup's navy canvas.  Individual cards use a restrained
  // foreground blend, keeping their edge visible without a charcoal cast.
  Result.BackgroundColor := RGB($10, $21, $33);
  Result.TextColor := RGB($EA, $F3, $FF);
  Result.MutedColor := RGB($9C, $B8, $D8);
  Result.AccentColor := RGB($0A, $84, $FF);
  Result.PrimaryColor := RGB($21, $96, $FF);
  Result.SecondaryColor := RGB($16, $D9, $E8);
  Result.SuccessColor := RGB($70, $D9, $8C);
  Result.WarningColor := RGB($FD, $B2, $4A);
  Result.DangerColor := RGB($FF, $6B, $77);
end;

class function TDevShellTheme.LightTheme: TDevShellTheme;
begin
  Result := Default(TDevShellTheme);
  Result.Kind := dstLight;
  Result.BackgroundColor := clWebSnow;
  Result.TextColor := BlendColor(clWebBlack, clWebWhite, 0.08);
  Result.MutedColor := clWebDarkSlateGray;
  Result.AccentColor := clHighlight;
  Result.PrimaryColor := clWebSteelBlue;
  Result.SecondaryColor := clWebTeal;
  Result.SuccessColor := clWebForestGreen;
  Result.WarningColor := clWebChocolate;
  Result.DangerColor := clWebIndianRed;
end;

class function TDevShellTheme.ActiveTheme: TDevShellTheme;
begin
  if GHasDevShellThemeOverride then
  begin
    if GDevShellThemeOverride = dstLight then
      Result := LightTheme
    else
      Result := DarkTheme;
  end
  else if IsWindowsLightTheme then
    Result := LightTheme
  else
    Result := DarkTheme;
  Result.HighContrast := IsHighContrastEnabled;
  if not Result.HighContrast then
    Exit;
  Result.BackgroundColor := TColor(GetSysColor(COLOR_MENU));
  Result.TextColor := TColor(GetSysColor(COLOR_MENUTEXT));
  Result.MutedColor := Result.TextColor;
  Result.AccentColor := TColor(GetSysColor(COLOR_HIGHLIGHT));
  Result.PrimaryColor := Result.TextColor;
  Result.SecondaryColor := Result.TextColor;
  Result.SuccessColor := Result.TextColor;
  Result.WarningColor := Result.TextColor;
  Result.DangerColor := Result.TextColor;
end;

procedure SetDevShellThemeOverride(AThemeKind: TDevShellThemeKind);
begin
  GDevShellThemeOverride := AThemeKind;
  GHasDevShellThemeOverride := True;
end;

procedure ClearDevShellThemeOverride;
begin
  GHasDevShellThemeOverride := False;
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

{ TSimpleUIButton }

constructor TSimpleUIButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csClickEvents, csCaptureMouse,
    csDoubleClicks, csOpaque];
  DoubleBuffered := True;
  ParentColor := True;
  TabStop := True;
  SetBounds(0, 0, 80, 25);
  FBackgroundColor := clBtnFace;
  FHotBackgroundColor := clBtnHighlight;
  FPressedBackgroundColor := clBtnShadow;
  FDisabledBackgroundColor := clBtnFace;
  FBorderColor := clBtnShadow;
  FHotBorderColor := clHighlight;
  FPressedBorderColor := clHighlight;
  FFocusedBorderColor := clHighlight;
  FDisabledBorderColor := clBtnShadow;
  FTextColor := clBtnText;
  FHotTextColor := clBtnText;
  FPressedTextColor := clBtnText;
  FDisabledTextColor := clGrayText;
  FBorderWidth := 1.0;
  FCornerRadius := 4;
  FContentPadding := 8;
  FImageSpacing := 6;
  FImageIndex := -1;
  FImagePosition := buipLeft;
  FModalResult := mrNone;
  FImageChangeLink := TChangeLink.Create;
  FImageChangeLink.OnChange := ImagesChanged;
end;

destructor TSimpleUIButton.Destroy;
begin
  Images := nil;
  FImageChangeLink.Free;
  inherited;
end;

procedure TSimpleUIButton.ApplyPalette(
  const APalette: TSimpleUIButtonPalette);
begin
  FBackgroundColor := APalette.Background;
  FHotBackgroundColor := APalette.HotBackground;
  FPressedBackgroundColor := APalette.PressedBackground;
  FDisabledBackgroundColor := APalette.DisabledBackground;
  FBorderColor := APalette.Border;
  FHotBorderColor := APalette.HotBorder;
  FPressedBorderColor := APalette.PressedBorder;
  FFocusedBorderColor := APalette.FocusedBorder;
  FDisabledBorderColor := APalette.DisabledBorder;
  FTextColor := APalette.Text;
  FHotTextColor := APalette.HotText;
  FPressedTextColor := APalette.PressedText;
  FDisabledTextColor := APalette.DisabledText;
  Invalidate;
end;

procedure TSimpleUIButton.Click;
begin
  var LForm := GetParentForm(Self);
  if Assigned(LForm) then
    LForm.ModalResult := FModalResult;
  inherited;
end;

procedure TSimpleUIButton.CMCancelMode(var AMessage: TCMCancelMode);
begin
  inherited;
  if AMessage.Sender <> Self then
  begin
    FPressed := False;
    FKeyboardPressed := False;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.CMDialogChar(var AMessage: TCMDialogChar);
begin
  if IsAccel(AMessage.CharCode, Caption) and CanFocus then
  begin
    Click;
    AMessage.Result := 1;
  end
  else
    inherited;
end;

procedure TSimpleUIButton.CMDialogKey(var AMessage: TCMDialogKey);
begin
  if ((((AMessage.CharCode = VK_RETURN) and FActive) or
    ((AMessage.CharCode = VK_ESCAPE) and FCancel)) and
    (KeyDataToShiftState(AMessage.KeyData) = []) and CanFocus) then
  begin
    Click;
    AMessage.Result := 1;
  end
  else
    inherited;
end;

procedure TSimpleUIButton.CMEnabledChanged(var AMessage: TMessage);
begin
  inherited;
  FPressed := False;
  FKeyboardPressed := False;
  Invalidate;
end;

procedure TSimpleUIButton.CMFocusChanged(var AMessage: TCMFocusChanged);
begin
  if AMessage.Sender is TSimpleUIButton then
    FActive := AMessage.Sender = Self
  else
    FActive := FDefault;
  inherited;
  Invalidate;
end;

procedure TSimpleUIButton.CMMouseEnter(var AMessage: TMessage);
begin
  inherited;
  FHot := True;
  Invalidate;
end;

procedure TSimpleUIButton.CMMouseLeave(var AMessage: TMessage);
begin
  inherited;
  FHot := False;
  Invalidate;
end;

procedure TSimpleUIButton.CMTextChanged(var AMessage: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TSimpleUIButton.ImagesChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TSimpleUIButton.KeyDown(var AKey: Word; AShift: TShiftState);
begin
  inherited;
  if Enabled and (AKey = VK_SPACE) and not FKeyboardPressed then
  begin
    FKeyboardPressed := True;
    Invalidate;
    AKey := 0;
  end;
end;

procedure TSimpleUIButton.KeyUp(var AKey: Word; AShift: TShiftState);
begin
  inherited;
  if FKeyboardPressed and (AKey = VK_SPACE) then
  begin
    FKeyboardPressed := False;
    Invalidate;
    Click;
    AKey := 0;
  end;
end;

procedure TSimpleUIButton.MouseDown(AButton: TMouseButton;
  AShift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Enabled and (AButton = mbLeft) then
  begin
    if CanFocus then
      SetFocus;
    FPressed := True;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.MouseUp(AButton: TMouseButton; AShift: TShiftState;
  X, Y: Integer);
begin
  inherited;
  if AButton = mbLeft then
  begin
    FPressed := False;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.Notification(AComponent: TComponent;
  Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    Images := nil;
end;

procedure TSimpleUIButton.Paint;
begin
  if (ClientWidth <= 0) or (ClientHeight <= 0) then
    Exit;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);

  var LBackgroundColor := FBackgroundColor;
  var LBorderColor := FBorderColor;
  var LTextColor := FTextColor;
  if not Enabled then
  begin
    LBackgroundColor := FDisabledBackgroundColor;
    LBorderColor := FDisabledBorderColor;
    LTextColor := FDisabledTextColor;
  end
  else if FPressed or FKeyboardPressed then
  begin
    LBackgroundColor := FPressedBackgroundColor;
    LBorderColor := FPressedBorderColor;
    LTextColor := FPressedTextColor;
  end
  else if FHot then
  begin
    LBackgroundColor := FHotBackgroundColor;
    LBorderColor := FHotBorderColor;
    LTextColor := FHotTextColor;
  end;
  if Focused and Enabled then
    LBorderColor := FFocusedBorderColor;

  DrawAntialiasedRoundedRectangle(Canvas, ClientRect, LBackgroundColor,
    LBorderColor, ScaleValue(FCornerRadius),
    ScaleValue(Round(FBorderWidth * 10.0)) / 10.0);

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := LTextColor;
  var LContentRect := ClientRect;
  InflateRect(LContentRect, -ScaleValue(FContentPadding), 0);
  if (LContentRect.Width <= 0) or (LContentRect.Height <= 0) then
    Exit;

  var LImageIndex := ResolveImageIndex;
  var LHasImage := LImageIndex >= 0;
  var LHasText := Caption <> '';
  var LImageWidth := 0;
  var LImageHeight := 0;
  if LHasImage then
  begin
    LImageWidth := FImages.Width;
    LImageHeight := FImages.Height;
  end;
  var LSpacing := 0;
  if LHasImage and LHasText then
    LSpacing := ScaleValue(FImageSpacing);

  var LTextMeasureRect := Rect(0, 0, 0, 0);
  if LHasText then
    DrawText(Canvas.Handle, PChar(Caption), Length(Caption),
      LTextMeasureRect, DT_CALCRECT or DT_SINGLELINE);
  var LTextWidth := LTextMeasureRect.Width;
  var LTextHeight := LTextMeasureRect.Height;
  var LImageRect := TRect.Empty;
  var LTextRect := TRect.Empty;

  if FImagePosition in [buipLeft, buipRight] then
  begin
    var LAvailableTextWidth := Max(0, LContentRect.Width - LImageWidth -
      LSpacing);
    LTextWidth := Min(LTextWidth, LAvailableTextWidth);
    var LGroupWidth := LImageWidth + LSpacing + LTextWidth;
    var LLeft := LContentRect.Left + Max(0,
      (LContentRect.Width - LGroupWidth) div 2);
    var LImageTop := LContentRect.Top +
      (LContentRect.Height - LImageHeight) div 2;
    if FImagePosition = buipLeft then
    begin
      LImageRect := Rect(LLeft, LImageTop, LLeft + LImageWidth,
        LImageTop + LImageHeight);
      LTextRect := Rect(LImageRect.Right + LSpacing, LContentRect.Top,
        LImageRect.Right + LSpacing + LTextWidth, LContentRect.Bottom);
    end
    else
    begin
      LTextRect := Rect(LLeft, LContentRect.Top, LLeft + LTextWidth,
        LContentRect.Bottom);
      LImageRect := Rect(LTextRect.Right + LSpacing, LImageTop,
        LTextRect.Right + LSpacing + LImageWidth,
        LImageTop + LImageHeight);
    end;
  end
  else
  begin
    var LAvailableTextHeight := Max(0, LContentRect.Height - LImageHeight -
      LSpacing);
    LTextHeight := Min(LTextHeight, LAvailableTextHeight);
    var LGroupHeight := LImageHeight + LSpacing + LTextHeight;
    var LTop := LContentRect.Top + Max(0,
      (LContentRect.Height - LGroupHeight) div 2);
    var LImageLeft := LContentRect.Left +
      (LContentRect.Width - LImageWidth) div 2;
    if FImagePosition = buipTop then
    begin
      LImageRect := Rect(LImageLeft, LTop, LImageLeft + LImageWidth,
        LTop + LImageHeight);
      LTextRect := Rect(LContentRect.Left, LImageRect.Bottom + LSpacing,
        LContentRect.Right, LImageRect.Bottom + LSpacing + LTextHeight);
    end
    else
    begin
      LTextRect := Rect(LContentRect.Left, LTop, LContentRect.Right,
        LTop + LTextHeight);
      LImageRect := Rect(LImageLeft, LTextRect.Bottom + LSpacing,
        LImageLeft + LImageWidth,
        LTextRect.Bottom + LSpacing + LImageHeight);
    end;
  end;

  if LHasImage then
    FImages.Draw(Canvas, LImageRect.Left, LImageRect.Top, LImageIndex,
      Enabled);
  if LHasText then
    DrawText(Canvas.Handle, PChar(Caption), Length(Caption), LTextRect,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS);
end;

function TSimpleUIButton.ResolveImageIndex: System.UITypes.TImageIndex;
begin
  Result := -1;
  if not Assigned(FImages) then
    Exit;
  var LImageName := FImageName;
  Result := FImageIndex;
  FImages.CheckIndexAndName(Result, LImageName);
  if (Result < 0) or (Result >= FImages.Count) then
    Result := -1;
end;

procedure TSimpleUIButton.SetBackgroundColor(const AValue: TColor);
begin
  if FBackgroundColor <> AValue then
  begin
    FBackgroundColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetBorderColor(const AValue: TColor);
begin
  if FBorderColor <> AValue then
  begin
    FBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetBorderWidth(const AValue: Single);
begin
  var LValue := Max(0.0, AValue);
  if not SameValue(FBorderWidth, LValue) then
  begin
    FBorderWidth := LValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetCancel(const AValue: Boolean);
begin
  FCancel := AValue;
end;

procedure TSimpleUIButton.SetContentPadding(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FContentPadding <> LValue then
  begin
    FContentPadding := LValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetCornerRadius(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FCornerRadius <> LValue then
  begin
    FCornerRadius := LValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetDefault(const AValue: Boolean);
begin
  if FDefault <> AValue then
  begin
    FDefault := AValue;
    FActive := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetDisabledBackgroundColor(const AValue: TColor);
begin
  if FDisabledBackgroundColor <> AValue then
  begin
    FDisabledBackgroundColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetDisabledBorderColor(const AValue: TColor);
begin
  if FDisabledBorderColor <> AValue then
  begin
    FDisabledBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetDisabledTextColor(const AValue: TColor);
begin
  if FDisabledTextColor <> AValue then
  begin
    FDisabledTextColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetFocusedBorderColor(const AValue: TColor);
begin
  if FFocusedBorderColor <> AValue then
  begin
    FFocusedBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetHotBackgroundColor(const AValue: TColor);
begin
  if FHotBackgroundColor <> AValue then
  begin
    FHotBackgroundColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetHotBorderColor(const AValue: TColor);
begin
  if FHotBorderColor <> AValue then
  begin
    FHotBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetHotTextColor(const AValue: TColor);
begin
  if FHotTextColor <> AValue then
  begin
    FHotTextColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetImageIndex(
  const AValue: System.UITypes.TImageIndex);
begin
  if (FImageIndex <> AValue) or (FImageName <> '') then
  begin
    FImageIndex := AValue;
    FImageName := '';
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetImageName(
  const AValue: System.UITypes.TImageName);
begin
  if (FImageName <> AValue) or (FImageIndex <> -1) then
  begin
    FImageName := AValue;
    FImageIndex := -1;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetImagePosition(
  const AValue: TSimpleUIButtonImagePosition);
begin
  if FImagePosition <> AValue then
  begin
    FImagePosition := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetImages(const AValue: TCustomImageList);
begin
  if FImages = AValue then
    Exit;
  if Assigned(FImages) then
  begin
    FImages.UnRegisterChanges(FImageChangeLink);
    FImages.RemoveFreeNotification(Self);
  end;
  FImages := AValue;
  if Assigned(FImages) then
  begin
    FImages.RegisterChanges(FImageChangeLink);
    FImages.FreeNotification(Self);
  end;
  Invalidate;
end;

procedure TSimpleUIButton.SetImageSpacing(const AValue: Integer);
begin
  var LValue := Max(0, AValue);
  if FImageSpacing <> LValue then
  begin
    FImageSpacing := LValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetPressedBackgroundColor(const AValue: TColor);
begin
  if FPressedBackgroundColor <> AValue then
  begin
    FPressedBackgroundColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetPressedBorderColor(const AValue: TColor);
begin
  if FPressedBorderColor <> AValue then
  begin
    FPressedBorderColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetPressedTextColor(const AValue: TColor);
begin
  if FPressedTextColor <> AValue then
  begin
    FPressedTextColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.SetTextColor(const AValue: TColor);
begin
  if FTextColor <> AValue then
  begin
    FTextColor := AValue;
    Invalidate;
  end;
end;

procedure TSimpleUIButton.WMEraseBkgnd(var AMessage: TWMEraseBkgnd);
begin
  AMessage.Result := 1;
end;

function DevShellButtonPalette(
  const ATheme: TDevShellTheme): TSimpleUIButtonPalette;
const
  cButtonBackgroundBlend = 0.94;
  cButtonHotBackgroundBlend = 0.88;
  cButtonPressedBackgroundBlend = 0.74;
  cButtonDisabledBackgroundBlend = 0.98;
  cButtonBorderBlend = 0.78;
begin
  Result.Background := BlendColor(ATheme.TextColor,
    ATheme.BackgroundColor, cButtonBackgroundBlend);
  Result.HotBackground := BlendColor(ATheme.AccentColor,
    ATheme.BackgroundColor, cButtonHotBackgroundBlend);
  Result.PressedBackground := BlendColor(ATheme.AccentColor,
    ATheme.BackgroundColor, cButtonPressedBackgroundBlend);
  Result.DisabledBackground := BlendColor(ATheme.TextColor,
    ATheme.BackgroundColor, cButtonDisabledBackgroundBlend);
  Result.Border := BlendColor(ATheme.TextColor,
    ATheme.BackgroundColor, cButtonBorderBlend);
  Result.HotBorder := ATheme.AccentColor;
  Result.PressedBorder := ATheme.AccentColor;
  Result.FocusedBorder := ATheme.AccentColor;
  Result.DisabledBorder := ATheme.MutedColor;
  Result.Text := ATheme.TextColor;
  Result.HotText := ATheme.TextColor;
  Result.PressedText := ATheme.TextColor;
  Result.DisabledText := ATheme.MutedColor;
end;

procedure ApplyDevShellThemeToButton(AButton: TSimpleUIButton;
  const ATheme: TDevShellTheme);
begin
  if not Assigned(AButton) then
    Exit;
  AButton.ApplyPalette(DevShellButtonPalette(ATheme));
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

initialization
  TCustomStyleEngine.RegisterStyleHook(TCheckBox, TDevShellCheckBoxStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TCustomCheckBox, TDevShellCheckBoxStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TMemo, TDevShellMemoStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TCustomMemo, TDevShellMemoStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TControlList, TDevShellControlListStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TCustomControlList, TDevShellControlListStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TListView, TDevShellListViewStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TCustomListView, TDevShellListViewStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TComboBox,
    TDevShellComboBoxStyleHook);
  TCustomStyleEngine.RegisterStyleHook(TCustomComboBox,
    TDevShellComboBoxStyleHook);
  RegisterClass(TSimpleUIButton);

finalization
  TCustomStyleEngine.UnRegisterStyleHook(TCheckBox, TDevShellCheckBoxStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TCustomCheckBox, TDevShellCheckBoxStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TMemo, TDevShellMemoStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TCustomMemo, TDevShellMemoStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TControlList, TDevShellControlListStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TCustomControlList, TDevShellControlListStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TListView, TDevShellListViewStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TCustomListView, TDevShellListViewStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TComboBox,
    TDevShellComboBoxStyleHook);
  TCustomStyleEngine.UnRegisterStyleHook(TCustomComboBox,
    TDevShellComboBoxStyleHook);
  UnRegisterClass(TSimpleUIButton);

end.
