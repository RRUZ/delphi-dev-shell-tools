//**************************************************************************************************
//
// Unit DelphiDevShellTools.GUI.Settings
// Edits menu preferences, IDE associations and custom tools in per-user settings.
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
// The Original Code is DelphiDevShellTools.GUI.Settings.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.GUI.Settings;

interface

uses
  System.JSON, Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, DelphiDevShellTools.Misc,
  DelphiDevShellTools.UI, DelphiDevShellTools.GUI.SettingsModel, Vcl.Imaging.pngimage, Vcl.ComCtrls, Data.DB,
  Datasnap.DBClient, Vcl.ControlList, Vcl.TitleBarCtrls, Vcl.ImgList;

type
  TPageControl = class(Vcl.ComCtrls.TPageControl)
  protected
    procedure AdjustClientRect(var ARect: TRect); override;
    procedure CreateParams(var Params: TCreateParams); override;
  end;

  // All manual geometry is calculated once in physical pixels after VCL has
  // committed the current PPI. Painting and child-control placement use the
  // same rectangles so a page cannot drift from its chrome at a new DPI.
  TSettingsLayoutMetrics = record
    TitleBarHeight: Integer;
    SideBarWidth: Integer;
    FooterHeight: Integer;
    HeaderHeight: Integer;
    PageMargin: Integer;
    Gutter: Integer;
    GeneralCard: TRect;
    MenuCommonCard: TRect;
    MenuDelphiCard: TRect;
    MenuLazarusCard: TRect;
    CustomToolsCard: TRect;
    CustomIdentityCard: TRect;
    CustomAvailabilityCard: TRect;
    CustomCommandCard: TRect;
    CustomMacrosCard: TRect;
    CustomPreviewCard: TRect;
  end;

  TFrmSettings = class(TForm)
    CheckBoxSubMenuOpenCmdRAD: TCheckBox;
    Panel2: TPanel;
    ButtonApply: TSimpleUIButton;
    ButtonCancel: TSimpleUIButton;
    CheckBoxShowInfoDProj: TCheckBox;
    CheckBoxSubMenuLazarus: TCheckBox;
    CheckBoxActivateLazarus: TCheckBox;
    CheckBoxSubMenuCommonTasks: TCheckBox;
    CheckBoxSubMenuMSBuild: TCheckBox;
    CheckBoxSubMenuMSBuildAnother: TCheckBox;
    CheckBoxSubMenuRunTouch: TCheckBox;
    CheckBoxSubMenuOpenDelphi: TCheckBox;
    CheckBoxSubMenuFormat: TCheckBox;
    Image1: TImage;
    Image2: TImage;
    Image3: TImage;
    CheckBoxSubMenuCompileRC: TCheckBox;
    CheckBoxSubMenuVCLStyles: TCheckBox;
    CheckBoxSubMenuFMXStyles: TCheckBox;
    PageControl1: TPageControl;
    TabSheet1: TTabSheet;
    Panel1: TPanel;
    PanelGeneral: TPanel;
    PaintBoxGeneral: TPaintBox;
    PaintBoxMenu: TPaintBox;
    PaintBoxGeneralInputBorders: TPaintBox;
    LabelFileExtensionsTitle: TLabel;
    PanelMenu: TPanel;
    PanelCustomTools: TPanel;
    PaintBoxCustomTools: TPaintBox;
    ButtonNewTool: TSimpleUIButton;
    ButtonDeleteTool: TSimpleUIButton;
    TabSheet2: TTabSheet;
    Label2: TLabel;
    EditCommonTaskExt: TEdit;
    EditOpenDelphiExt: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    EditOpenLazarusExt: TEdit;
    EditCheckSumExt: TEdit;
    Label6: TLabel;
    TabSheet3: TTabSheet;
    DataSource1: TDataSource;
    ClientDataSet1: TClientDataSet;
    Label7: TLabel;
    DBEditMenu: TEdit;
    DBEditName: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    DBMemoScript: TMemo;
    Label10: TLabel;
    DBEditExtensions: TEdit;
    Label11: TLabel;
    ListViewMacros: TListView;
    Label12: TLabel;
    BtnInsertMacro: TSimpleUIButton;
    DBComboBoxGroup: TComboBox;
    LabelDelphi: TLabel;
    DBLookupComboBoxDelphi: TComboBox;
    ClientDataSet2: TClientDataSet;
    DataSource2: TDataSource;
    DBGrid1: TControlList;
    DBComboBoxImage: TComboBox;
    Label14: TLabel;
    DBCheckBoxRunAs: TCheckBox;
    Image5: TImage;
    TitleBarPanel1: TTitleBarPanel;
    PanelSideBar: TPanel;
    SideBar: TControlList;
    PaintBoxSideBarBorder: TPaintBox;
    PanelSideBarFooter: TPanel;
    PaintBoxSideBarFooterBorder: TPaintBox;
    PanelViewHeader: TPanel;
    LabelViewTitle: TLabel;
    LabelViewDescription: TLabel;
    PaintBoxFooterBorder: TPaintBox;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonApplyClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnInsertMacroClick(Sender: TObject);
    procedure DBComboBoxImageDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure DBComboBoxGroupDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure ClientDataSet1AfterScroll(DataSet: TDataSet);
    procedure SideBarAfterDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure SideBarChange(Sender: TObject);
    procedure GeneralDecorationsPaint(Sender: TObject);
    procedure GeneralInputBordersPaint(Sender: TObject);
    procedure GeneralDecorationsMouseDown(Sender: TObject;
      Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure GeneralInputFocusChanged(Sender: TObject);
    procedure MenuDecorationsPaint(Sender: TObject);
    procedure CustomToolsDecorationsPaint(Sender: TObject);
    procedure ToolListAfterDrawItem(AIndex: Integer; ACanvas: TCanvas;
      ARect: TRect; AState: TOwnerDrawState);
    procedure ToolListChange(Sender: TObject);
    procedure CustomToolControlChanged(Sender: TObject);
    procedure CustomToolInputFocusChanged(Sender: TObject);
    procedure ListViewMacrosDrawItem(Sender: TCustomListView;
      Item: TListItem; Rect: TRect; State: TOwnerDrawState);
    procedure ListViewMacrosMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure ButtonNewToolClick(Sender: TObject);
    procedure ButtonDeleteToolClick(Sender: TObject);
    procedure ChromeBorderPaint(Sender: TObject);
    procedure TitleBarPanelPaint(Sender: TObject; Canvas: TCanvas;
      var ARect: TRect);
  private
    FSourceDocument: TJSONObject;
    FSnapshotOnly: Boolean;
    FMacroDirectory: string;
    FSettings: TSettings;
    FActiveSideBarIndex: Integer;
    FUpdatingSideBar: Boolean;
    FLoadingCustomTool: Boolean;
    FToolsModel: TSettingsToolsModel;
    FVersionIds: TStringList;
    FCustomToolButtonImages: TImageList;
    FMacroRowImages: TImageList;
    FMacroNames: TStringList;
    FMacroDescriptions: TStringList;
    FCustomEnabled: TCheckBox;
    FGeneralExtensionPanels: array[0..3] of TFlowPanel;
    FExtensionsPanel: TFlowPanel;
    FMacroSearch: TEdit;
    FMenuPreview: TLabel;
    FValidateButton: TSimpleUIButton;
    FValidationStatus: TLabel;
    FFooterStatusLabel: TLabel;
    FFooterIconPaintBox: TPaintBox;
    FAboutPage: TTabSheet;
    FAboutPanel: TPanel;
    FAboutPaintBox: TPaintBox;
    FAboutLogo: TImage;
    FAboutProduct: TLabel;
    FAboutDescription: TLabel;
    FAboutVersionTitle: TLabel;
    FAboutVersion: TLabel;
    FAboutBuildTitle: TLabel;
    FAboutBuild: TLabel;
    FAboutArchitectureTitle: TLabel;
    FAboutArchitecture: TLabel;
    FAboutAuthorTitle: TLabel;
    FAboutAuthor: TLabel;
    FAboutRepositoryTitle: TLabel;
    FAboutLicenseTitle: TLabel;
    FAboutPhosphorTitle: TLabel;
    FAboutOpenSSLTitle: TLabel;
    FAboutRepositoryButton: TSimpleUIButton;
    FAboutPhosphorButton: TSimpleUIButton;
    FAboutOpenSSLButton: TSimpleUIButton;
    FAboutLicenseBadge: TDevShellBadgeLabel;
    FLayout: TSettingsLayoutMetrics;
    procedure ApplyProjectIcons;
    procedure ApplyProjectIcon(AImage: TImage; const AKey: string;
      ALogicalSize: Integer; const ATheme: TDevShellTheme);
    procedure ApplyControlTheme(AControl: TControl;
      const ATheme: TDevShellTheme; AInputColor: TColor);
    procedure ApplySettingsTheme;
    procedure ConfigureFooter;
    procedure CreateFooterStatus;
    procedure FooterIconPaint(Sender: TObject);
    procedure ConfigureSideBar;
    procedure ConfigureGeneralPage;
    procedure CreateGeneralExtensionPanels;
    procedure ConfigureMenuPage;
    procedure ConfigureCustomToolsPage;
    procedure CreateCustomToolsControls;
    procedure LoadSelectedTool;
    procedure SaveSelectedTool;
    procedure RefreshToolList;
    procedure RefreshExtensionChips;
    procedure RefreshGeneralExtensionChips;
    procedure ExtensionChipClick(Sender: TObject);
    procedure AddExtensionClick(Sender: TObject);
    procedure GeneralExtensionChipClick(Sender: TObject);
    procedure AddGeneralExtensionClick(Sender: TObject);
    function GeneralExtensionEdit(AIndex: Integer): TEdit;
    procedure MacroSearchChange(Sender: TObject);
    procedure ValidateCommandClick(Sender: TObject);
    procedure UpdateCommandPreview;
    procedure ConfigureAboutPage;
    procedure ConfigureTitleBar(const ATheme: TDevShellTheme);
    procedure RefreshTitleBarChrome;
    procedure RebuildCustomToolButtonImages(const ATheme: TDevShellTheme);
    procedure AboutDecorationsPaint(Sender: TObject);
    procedure AboutRepositoryClick(Sender: TObject);
    procedure AboutPhosphorClick(Sender: TObject);
    procedure AboutOpenSSLClick(Sender: TObject);
    procedure LoadAboutLogo;
    function GeneralInputBorderRect(AInput: TWinControl): TRect;
    procedure LoadMacros;
    procedure UpdateViewHeader(AIndex: Integer);
    function GetLayoutPPI: Integer;
    procedure ApplySettingsLayout;
  protected
    procedure ChangeScale(AM, AD: Integer; AIsDpiChange: Boolean); override;
    procedure WMSettingsRelayout(var AMessage: TMessage);
      message WM_APP + $412;
  public
    constructor CreateForDocument(AOwner: TComponent; ADocument: TJSONObject;
      const AMacroDirectory: string);
    procedure RefreshDpiLayout;
    procedure ApplyChangesToSnapshot;
    // TControl.CurrentPPI reports the current monitor in the standalone
    // capture host.  The form's PixelsPerInch is the VCL-committed DPI after
    // ScaleForPPI, so expose it to every manual layout calculation.
    property CurrentPPI: Integer read GetLayoutPPI;
    property Settings: TSettings Read FSettings Write FSettings;
    procedure LoadSettings;
  end;

var
  FrmSettings: TFrmSettings;

procedure ActivateSettingsVclStyle;

implementation

uses
  Winapi.ShellAPI, DelphiDevShellTools.Icons, DelphiDevShellTools.Logging, DelphiDevShellTools.Phosphor.Font,
  DelphiDevShellTools.GUI.ExtensionDialog, DelphiDevShellTools.GUI.MiscGUI, StrUtils, System.Math, System.Types,
  System.UITypes, System.Win.Registry, Vcl.Styles, Vcl.Themes, MidasLib;

{$R *.dfm}

type
  TControlAccess = class(TControl);

const
  cSettingsFontSize = TDevShellTheme.cFontSize;
  cCompactDataFontSize = cSettingsFontSize - 1;
  cDenseDataFontSize = cCompactDataFontSize - 1;
  cSideBarGeneral = 0;
  cSideBarMenu = 1;
  cSideBarCustomTools = 2;
  cSideBarAbout = 3;
  cDesignPPI = 96;
  cGeneralCardCornerRadius = 6;
  cGeneralCardBorderBlend = 0.87;
  cGeneralInputBorderBlend = 0.78;
  cCustomInputPaddingX = 8;
  cCustomInputRightPaddingX = 1;
  cCustomInputPaddingY = 4;
  cCustomListRowHeight = 23;
  cAboutValueLeft = 184;

function TFrmSettings.GetLayoutPPI: Integer;
begin
  Result := PixelsPerInch;
  if Result <= 0 then
    Result := cDesignPPI;
end;

procedure TFrmSettings.ApplySettingsLayout;
const
  cSettingsTitleBarHeight = 40;
  // One measured navigation surface owns all sidebar row geometry.
  cSideBarWidth = 204;

  function PageRect(AWidth, AHeight: Integer): TRect;
  begin
    Result := Rect(FLayout.PageMargin, FLayout.PageMargin,
      Max(FLayout.PageMargin + 1, AWidth - FLayout.PageMargin),
      Max(FLayout.PageMargin + 1, AHeight - FLayout.PageMargin));
  end;

  procedure SplitCustomColumns(const APage: TRect; out ATools, ACenter,
    ARight: TRect);
  var
    LAvailable, LToolsWidth, LCenterWidth, LRightWidth, LDeficit: Integer;
  begin
    LAvailable := APage.Width - 2 * FLayout.Gutter;
    LToolsWidth := Max(ScaleValue(140), LAvailable * 27 div 100);
    LRightWidth := Max(ScaleValue(190), LAvailable * 35 div 100);
    LCenterWidth := LAvailable - LToolsWidth - LRightWidth;
    LDeficit := ScaleValue(230) - LCenterWidth;
    if LDeficit > 0 then
    begin
      var LGive := Min(LDeficit, LToolsWidth - ScaleValue(128));
      Dec(LToolsWidth, LGive);
      Dec(LDeficit, LGive);
      LGive := Min(LDeficit, LRightWidth - ScaleValue(178));
      Dec(LRightWidth, LGive);
    end;
    LCenterWidth := LAvailable - LToolsWidth - LRightWidth;
    ATools := Rect(APage.Left, APage.Top, APage.Left + LToolsWidth,
      APage.Bottom);
    ACenter := Rect(ATools.Right + FLayout.Gutter, APage.Top,
      ATools.Right + FLayout.Gutter + LCenterWidth, APage.Bottom);
    ARight := Rect(ACenter.Right + FLayout.Gutter, APage.Top,
      APage.Right, APage.Bottom);
  end;

  procedure SplitVertical(const ARect: TRect; AFirstPercent,
    ASecondPercent: Integer; out AFirst, ASecond, AThird: TRect);
  var
    LAvailable, LFirstHeight, LSecondHeight: Integer;
  begin
    LAvailable := ARect.Height - 2 * FLayout.Gutter;
    LFirstHeight := LAvailable * AFirstPercent div 100;
    LSecondHeight := LAvailable * ASecondPercent div 100;
    AFirst := Rect(ARect.Left, ARect.Top, ARect.Right,
      ARect.Top + LFirstHeight);
    ASecond := Rect(ARect.Left, AFirst.Bottom + FLayout.Gutter, ARect.Right,
      AFirst.Bottom + FLayout.Gutter + LSecondHeight);
    AThird := Rect(ARect.Left, ASecond.Bottom + FLayout.Gutter, ARect.Right,
      ARect.Bottom);
  end;

  function AvailabilityCardHeight(const AColumn: TRect): Integer;
  var
    LExtensions: TArray<string>;
    LMetrics: TBitmap;
    LAvailableWidth, LRowWidth, LRows: Integer;

    procedure AddChipWidth(AWidth: Integer);
    begin
      if (LRowWidth > 0) and (LRowWidth + AWidth > LAvailableWidth) then
      begin
        Inc(LRows);
        LRowWidth := 0;
      end;
      Inc(LRowWidth, AWidth);
    end;

  begin
    // The card owns only the rows required by the selected tool. Spare height
    // returns to the flexible Command editor; wrapped badge rows stay intact.
    LAvailableWidth := Max(ScaleValue(1), AColumn.Width - ScaleValue(24));
    LRowWidth := 0;
    LRows := 1;
    if Assigned(DBEditExtensions) then
      LExtensions := TSettingsToolsModel.SplitExtensions(DBEditExtensions.Text)
    else
      LExtensions := nil;
    LMetrics := TBitmap.Create;
    try
      LMetrics.Canvas.Font.Assign(Font);
      LMetrics.Canvas.Font.Size := cCompactDataFontSize;
      for var LExtension in LExtensions do
        AddChipWidth(LMetrics.Canvas.TextWidth(LExtension + ' ' + #215) +
          ScaleValue(13));
      AddChipWidth(ScaleValue(28));
    finally
      LMetrics.Free;
    end;
    if LRows <= 1 then
      Result := ScaleValue(83)
    else
      Result := ScaleValue(106);
  end;

var
  LMenuPage, LCustomPage, LTools, LCenter, LRight: TRect;
  LMenuAvailable, LCommonHeight, LLazarusHeight: Integer;
  LIdentityHeight, LAvailabilityHeight, LMacrosHeight: Integer;
begin
  FLayout.TitleBarHeight := ScaleValue(cSettingsTitleBarHeight);
  FLayout.SideBarWidth := ScaleValue(cSideBarWidth);
  FLayout.FooterHeight := ScaleValue(58);
  // Keep the title and description together without spending a card-sized band
  // below them; the reclaimed space belongs to the working cards.
  FLayout.HeaderHeight := ScaleValue(44);
  FLayout.PageMargin := ScaleValue(12);
  FLayout.Gutter := ScaleValue(8);

  // These are the only shell geometry assignments. The aligned containers
  // determine the remaining page rectangle before page-local grids are built.
  CustomTitleBar.Height := FLayout.TitleBarHeight;
  TitleBarPanel1.Height := FLayout.TitleBarHeight;
  if Panel2.Parent <> Self then
    Panel2.Parent := Self;
  Panel1.Align := alNone;
  Panel2.Align := alNone;
  PanelSideBar.Align := alNone;
  PanelSideBarFooter.Visible := False;
  PanelSideBar.SetBounds(0, FLayout.TitleBarHeight, FLayout.SideBarWidth,
    Max(1, ClientHeight - FLayout.TitleBarHeight - FLayout.FooterHeight));
  Panel1.SetBounds(FLayout.SideBarWidth, FLayout.TitleBarHeight,
    Max(1, ClientWidth - FLayout.SideBarWidth),
    Max(1, ClientHeight - FLayout.TitleBarHeight - FLayout.FooterHeight));
  Panel2.SetBounds(0, ClientHeight - FLayout.FooterHeight, ClientWidth,
    FLayout.FooterHeight);
  Panel2.BringToFront;
  PanelViewHeader.Height := FLayout.HeaderHeight;
  Realign;

  FLayout.GeneralCard := PageRect(PanelGeneral.ClientWidth,
    PanelGeneral.ClientHeight);

  LMenuPage := PageRect(PanelMenu.ClientWidth, PanelMenu.ClientHeight);
  LMenuAvailable := LMenuPage.Height - 2 * FLayout.Gutter;
  LCommonHeight := Max(ScaleValue(112), LMenuAvailable * 29 div 100);
  // Two Lazarus rows need 49 + 24 + 19 logical pixels below the card top,
  // plus the lower breathing room.  The old 76px minimum clipped the second
  // row at the protected 880x552 client size.
  LLazarusHeight := Max(ScaleValue(94), LMenuAvailable * 22 div 100);
  if LCommonHeight + LLazarusHeight > LMenuAvailable - ScaleValue(143) then
    LLazarusHeight := Max(ScaleValue(94), LMenuAvailable - LCommonHeight -
      ScaleValue(143));
  FLayout.MenuCommonCard := Rect(LMenuPage.Left, LMenuPage.Top,
    LMenuPage.Right, LMenuPage.Top + LCommonHeight);
  FLayout.MenuDelphiCard := Rect(LMenuPage.Left,
    FLayout.MenuCommonCard.Bottom + FLayout.Gutter, LMenuPage.Right,
    LMenuPage.Bottom - LLazarusHeight - FLayout.Gutter);
  FLayout.MenuLazarusCard := Rect(LMenuPage.Left,
    FLayout.MenuDelphiCard.Bottom + FLayout.Gutter, LMenuPage.Right,
    LMenuPage.Bottom);

  LCustomPage := PageRect(PanelCustomTools.ClientWidth,
    PanelCustomTools.ClientHeight);
  SplitCustomColumns(LCustomPage, LTools, LCenter, LRight);
  FLayout.CustomToolsCard := LTools;
  // The Identity card keeps a compact, fixed three-row rhythm. Availability
  // is content-aware; Command owns every remaining pixel.
  LIdentityHeight := ScaleValue(170);
  LAvailabilityHeight := AvailabilityCardHeight(LCenter);
  FLayout.CustomIdentityCard := Rect(LCenter.Left, LCenter.Top,
    LCenter.Right, LCenter.Top + LIdentityHeight);
  FLayout.CustomAvailabilityCard := Rect(LCenter.Left,
    FLayout.CustomIdentityCard.Bottom + FLayout.Gutter, LCenter.Right,
    FLayout.CustomIdentityCard.Bottom + FLayout.Gutter + LAvailabilityHeight);
  FLayout.CustomCommandCard := Rect(LCenter.Left,
    FLayout.CustomAvailabilityCard.Bottom + FLayout.Gutter, LCenter.Right,
    LCenter.Bottom);
  // Search plus five macro rows is intrinsic content. Preview, validation,
  // and status share the single lower card from the reference.
  LMacrosHeight := Max(ScaleValue(206), LRight.Height - ScaleValue(132) -
    FLayout.Gutter);
  FLayout.CustomMacrosCard := Rect(LRight.Left, LRight.Top, LRight.Right,
    LRight.Top + LMacrosHeight);
  FLayout.CustomPreviewCard := Rect(LRight.Left,
    FLayout.CustomMacrosCard.Bottom + FLayout.Gutter, LRight.Right,
    LRight.Bottom);
end;

procedure ActivateSettingsVclStyle;
const
  cGlowStyleName = 'Glow';
begin
  if TDevShellTheme.ActiveTheme.Kind <> dstDark then
    Exit;

  TStyleManager.SetStyle(cGlowStyleName);
end;

procedure TPageControl.AdjustClientRect(var ARect: TRect);
begin
  ARect := ClientRect;
end;

procedure TPageControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style and not WS_BORDER;
  Params.ExStyle := Params.ExStyle and not WS_EX_CLIENTEDGE;
end;

function SideBarAccentColor(AIndex: Integer;
  const ATheme: TDevShellTheme): TColor;
begin
  case AIndex of
    cSideBarGeneral: Result := ATheme.PrimaryColor;
    cSideBarMenu: Result := ATheme.SecondaryColor;
    cSideBarCustomTools: Result := ATheme.WarningColor;
    cSideBarAbout: Result := ATheme.MutedColor;
  else
    Result := ATheme.TextColor;
  end;
end;

function TFrmSettings.GeneralInputBorderRect(AInput: TWinControl): TRect;
const
  cGeneralInputPaddingX = 4;
  cGeneralInputPaddingY = 3;
begin
  Result := AInput.BoundsRect;
  InflateRect(Result, MulDiv(cGeneralInputPaddingX, CurrentPPI,
    cDesignPPI), MulDiv(cGeneralInputPaddingY, CurrentPPI, cDesignPPI));
end;

procedure TFrmSettings.GeneralDecorationsPaint(Sender: TObject);
const
  cGeneralIconSize = 20;
  cGeneralIconCodes: array[0..3] of Word = (
    cPhListChecks, cPhCode, cPhCodeBlock, cPhFingerprint);
  cGeneralFeatureDescriptions: array[0..3] of string = (
    'File types used by Common Tasks.', 'File types shown in "Open with Delphi".',
    'File types used by Lazarus integration.',
    'File types used for checksum calculation.');
var
  LPhosphorFont: TPhosphorFont;

  procedure DrawFeatureIcon(AIndex: Integer; ALabel: TLabel;
    AColor: TColor);
  begin
    var LIconSize := ScaleValue(cGeneralIconSize);
    var LIconLeft := FLayout.GeneralCard.Left + ScaleValue(18);
    var LIconTop := ALabel.Top + (ALabel.Height - LIconSize) div 2;
    var LIconRect := Rect(LIconLeft, LIconTop, LIconLeft + LIconSize,
      LIconTop + LIconSize);
    LPhosphorFont.DrawDuotoneIcon(PaintBoxGeneral.Canvas.Handle,
      cGeneralIconCodes[AIndex], LIconRect, AColor, AColor, 76, False);
  end;

begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LCardRect := FLayout.GeneralCard;
  var LCardBorderColor := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  DrawAntialiasedRoundedRectangle(PaintBoxGeneral.Canvas, LCardRect,
    BlendColor(LTheme.BackgroundColor, LTheme.TextColor, 0.02),
    LCardBorderColor,
    MulDiv(cGeneralCardCornerRadius, CurrentPPI, cDesignPPI),
    Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));

  for var LIndex := 0 to High(FGeneralExtensionPanels) do
  begin
    var LPanel := FGeneralExtensionPanels[LIndex];
    if not Assigned(LPanel) then
      Continue;
    var LFrameRect := LPanel.BoundsRect;
    InflateRect(LFrameRect, MulDiv(1, CurrentPPI, cDesignPPI),
      MulDiv(1, CurrentPPI, cDesignPPI));
    DrawAntialiasedRoundedRectangle(PaintBoxGeneral.Canvas, LFrameRect,
      BlendColor(LTheme.BackgroundColor, LTheme.TextColor, 0.02),
      BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
        cGeneralInputBorderBlend), ScaleValue(6),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  PaintBoxGeneral.Canvas.Pen.Style := psSolid;
  PaintBoxGeneral.Canvas.Pen.Width := 1;
  PaintBoxGeneral.Canvas.Pen.Color := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  for var LIndex := 0 to 2 do
  begin
    // The separator follows the actual chip well. This prevents it cutting
    // through a second badge row when the page width or PPI changes.
    var LSeparatorY := FGeneralExtensionPanels[LIndex].BoundsRect.Bottom +
      ScaleValue(3);
    PaintBoxGeneral.Canvas.MoveTo(LCardRect.Left + ScaleValue(12),
      LSeparatorY);
    PaintBoxGeneral.Canvas.LineTo(LCardRect.Right - ScaleValue(12),
      LSeparatorY);
  end;

  PaintBoxGeneral.Canvas.Brush.Style := bsClear;
  PaintBoxGeneral.Canvas.Font.Name := TDevShellTheme.cFontName;
  PaintBoxGeneral.Canvas.Font.Size := cCompactDataFontSize;
  PaintBoxGeneral.Canvas.Font.Style := [];
  PaintBoxGeneral.Canvas.Font.Color := LTheme.MutedColor;
  for var LIndex := 0 to 3 do
  begin
    var LLabel := TArray<TLabel>.Create(Label2, Label3, Label4, Label6)[LIndex];
    var LDescriptionRect := LLabel.BoundsRect;
    LDescriptionRect.Top := LDescriptionRect.Bottom + ScaleValue(2);
    LDescriptionRect.Bottom := LDescriptionRect.Top +
      ScaleValue(30);
    DrawText(PaintBoxGeneral.Canvas.Handle,
      PChar(cGeneralFeatureDescriptions[LIndex]),
      Length(cGeneralFeatureDescriptions[LIndex]), LDescriptionRect,
      DT_LEFT or DT_WORDBREAK or DT_NOPREFIX);
  end;

  if not TryGetPhosphorFont(LPhosphorFont) then
    Exit;
  DrawFeatureIcon(0, Label2, LTheme.PrimaryColor);
  DrawFeatureIcon(1, Label3, LTheme.PrimaryColor);
  DrawFeatureIcon(2, Label4, LTheme.SecondaryColor);
  DrawFeatureIcon(3, Label6, LTheme.PrimaryColor);
end;

procedure TFrmSettings.GeneralInputBordersPaint(Sender: TObject);
begin
end;

procedure TFrmSettings.GeneralDecorationsMouseDown(Sender: TObject;
  Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button <> mbLeft then
    Exit;
  var LPoint := Point(X, Y);
  if GeneralInputBorderRect(EditCommonTaskExt).Contains(LPoint) then
    EditCommonTaskExt.SetFocus
  else if GeneralInputBorderRect(EditOpenDelphiExt).Contains(LPoint) then
    EditOpenDelphiExt.SetFocus
  else if GeneralInputBorderRect(EditOpenLazarusExt).Contains(LPoint) then
    EditOpenLazarusExt.SetFocus
  else if GeneralInputBorderRect(EditCheckSumExt).Contains(LPoint) then
    EditCheckSumExt.SetFocus;
end;

procedure TFrmSettings.GeneralInputFocusChanged(Sender: TObject);
begin
  PaintBoxGeneralInputBorders.Invalidate;
end;

function TFrmSettings.GeneralExtensionEdit(AIndex: Integer): TEdit;
begin
  case AIndex of
    0: Result := EditCommonTaskExt;
    1: Result := EditOpenDelphiExt;
    2: Result := EditOpenLazarusExt;
    3: Result := EditCheckSumExt;
  else
    raise EArgumentOutOfRangeException.Create('AIndex');
  end;
end;

procedure TFrmSettings.CreateGeneralExtensionPanels;
begin
  for var LIndex := 0 to High(FGeneralExtensionPanels) do
  begin
    var LPanel := TFlowPanel.Create(Self);
    LPanel.Parent := PanelGeneral;
    LPanel.BevelInner := bvNone;
    LPanel.BevelOuter := bvNone;
    LPanel.BorderStyle := bsNone;
    LPanel.ParentBackground := False;
    LPanel.StyleElements := LPanel.StyleElements - [seClient];
    LPanel.AutoWrap := True;
    LPanel.FlowStyle := fsLeftRightTopBottom;
    LPanel.Tag := LIndex;
    FGeneralExtensionPanels[LIndex] := LPanel;
    GeneralExtensionEdit(LIndex).Visible := False;
  end;
end;

procedure TFrmSettings.RefreshGeneralExtensionChips;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LPalette := DevShellButtonPalette(LTheme);
  LPalette.Background := BlendColor(LTheme.BackgroundColor, LTheme.TextColor,
    0.08);
  LPalette.Border := BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
    cGeneralInputBorderBlend);
  LPalette.HotBackground := BlendColor(LTheme.AccentColor,
    LTheme.BackgroundColor, 0.80);
  LPalette.HotBorder := LTheme.AccentColor;
  LPalette.FocusedBorder := LTheme.AccentColor;

  var LMetrics := TBitmap.Create;
  try
    for var LPanelIndex := 0 to High(FGeneralExtensionPanels) do
    begin
      var LPanel := FGeneralExtensionPanels[LPanelIndex];
      while LPanel.ControlCount > 0 do
        LPanel.Controls[0].Free;
      LPanel.Color := BlendColor(LTheme.BackgroundColor, LTheme.TextColor,
        0.06);
      var LExtensions := TSettingsToolsModel.SplitExtensions(
        GeneralExtensionEdit(LPanelIndex).Text);
      for var LIndex := 0 to High(LExtensions) do
      begin
        var LChip := TSimpleUIButton.Create(Self);
        LChip.Parent := LPanel;
        LChip.Caption := LExtensions[LIndex] + ' ' + #$00D7;
        LChip.Hint := LExtensions[LIndex];
        LChip.Tag := LPanelIndex;
        LChip.Font.Assign(Font);
        LChip.Font.Size := cCompactDataFontSize;
        LChip.AlignWithMargins := True;
        LChip.Margins.SetBounds(MulDiv(4, CurrentPPI, cDesignPPI),
          MulDiv(3, CurrentPPI, cDesignPPI), MulDiv(2, CurrentPPI,
          cDesignPPI), 0);
        LChip.ContentPadding := 3;
        LMetrics.Canvas.Font.Assign(LChip.Font);
        LChip.SetBounds(0, 0, LMetrics.Canvas.TextWidth(LChip.Caption) +
          MulDiv(13, CurrentPPI, cDesignPPI), MulDiv(22, CurrentPPI,
          cDesignPPI));
        LChip.ApplyPalette(LPalette);
        LChip.OnClick := GeneralExtensionChipClick;
      end;

      var LAddButton := TSimpleUIButton.Create(Self);
      LAddButton.Parent := LPanel;
      LAddButton.Caption := '+';
      LAddButton.Tag := LPanelIndex;
      LAddButton.Font.Assign(Font);
      LAddButton.AlignWithMargins := True;
      LAddButton.Margins.SetBounds(MulDiv(4, CurrentPPI, cDesignPPI),
        MulDiv(3, CurrentPPI, cDesignPPI), 0, 0);
      LAddButton.ContentPadding := 2;
      LAddButton.SetBounds(0, 0, MulDiv(28, CurrentPPI, cDesignPPI),
        MulDiv(22, CurrentPPI, cDesignPPI));
      LAddButton.ApplyPalette(LPalette);
      LAddButton.OnClick := AddGeneralExtensionClick;
      LPanel.Realign;
    end;
  finally
    LMetrics.Free;
  end;
  ConfigureGeneralPage;
  PaintBoxGeneral.Invalidate;
end;

procedure TFrmSettings.GeneralExtensionChipClick(Sender: TObject);
begin
  var LButton := TSimpleUIButton(Sender);
  var LValues := TStringList.Create;
  try
    var LRemoved := False;
    for var LExtension in TSettingsToolsModel.SplitExtensions(
      GeneralExtensionEdit(LButton.Tag).Text) do
      if not LRemoved and SameText(LExtension, LButton.Hint) then
        LRemoved := True
      else
        LValues.Add(LExtension);
    GeneralExtensionEdit(LButton.Tag).Text := StringReplace(LValues.CommaText,
      '"', '', [rfReplaceAll]);
  finally
    LValues.Free;
  end;
  RefreshGeneralExtensionChips;
end;

procedure TFrmSettings.AddGeneralExtensionClick(Sender: TObject);
begin
  var LButton := TSimpleUIButton(Sender);
  var LValue := '';
  var LPromptValue := LValue;
  if not TFrmExtensionDialog.Execute(Self, LPromptValue, LValue) then
    Exit;
  LValue := Trim(LValue);
  if LValue = '' then
    Exit;
  if not LValue.StartsWith('.') then
    LValue := '.' + LValue;
  var LExtensions := TSettingsToolsModel.SplitExtensions(
    GeneralExtensionEdit(LButton.Tag).Text);
  SetLength(LExtensions, Length(LExtensions) + 1);
  LExtensions[High(LExtensions)] := LValue;
  GeneralExtensionEdit(LButton.Tag).Text :=
    TSettingsToolsModel.JoinExtensions(LExtensions);
  RefreshGeneralExtensionChips;
end;

procedure TFrmSettings.ConfigureGeneralPage;
  procedure SetGeneralExtensionBounds(AIndex, ATop, AHeight,
    ALeft, AWidth: Integer);
  begin
    var LPanel := FGeneralExtensionPanels[AIndex];
    var LInset := Max(1, ScaleValue(1));
    LPanel.SetBounds(ALeft + LInset, ATop + LInset,
      Max(1, AWidth - 2 * LInset), Max(1, AHeight - 2 * LInset));
    LPanel.Realign;
  end;

  function RequiredWellHeight(AIndex, AWidth: Integer): Integer;
  var
    LUsedWidth, LRowHeight, LRequiredHeight: Integer;
  begin
    Result := ScaleValue(44);
    if (AIndex < Low(FGeneralExtensionPanels)) or
       (AIndex > High(FGeneralExtensionPanels)) then
      Exit;

    LUsedWidth := ScaleValue(4);
    LRowHeight := 0;
    LRequiredHeight := ScaleValue(3);
    for var LControlIndex := 0 to FGeneralExtensionPanels[AIndex].ControlCount - 1 do
    begin
      var LControl := FGeneralExtensionPanels[AIndex].Controls[LControlIndex];
      var LControlWidth := LControl.Width + LControl.Margins.Left +
        LControl.Margins.Right;
      var LControlHeight := LControl.Height + LControl.Margins.Top +
        LControl.Margins.Bottom;
      if (LUsedWidth > ScaleValue(4)) and
         (LUsedWidth + LControlWidth > AWidth) then
      begin
        Inc(LRequiredHeight, LRowHeight);
        LUsedWidth := ScaleValue(4);
        LRowHeight := 0;
      end;
      Inc(LUsedWidth, LControlWidth);
      LRowHeight := Max(LRowHeight, LControlHeight);
    end;
    if LRowHeight > 0 then
      Inc(LRequiredHeight, LRowHeight + ScaleValue(3));
    Result := Max(Result, LRequiredHeight);
  end;

var
  LCard: TRect;
  LRowTop, LInputLeft, LInputWidth, LLabelLeft, LLabelWidth, LAvailable,
    LExtra, LRowGap: Integer;
  LRowHeights: array[0..3] of Integer;
  LRowTops: array[0..3] of Integer;
begin
  PaintBoxGeneral.SendToBack;
  PaintBoxGeneralInputBorders.Visible := False;
  PaintBoxGeneralInputBorders.SetBounds(0, 0, PanelGeneral.ClientWidth,
    PanelGeneral.ClientHeight);
  LCard := FLayout.GeneralCard;
  LRowTop := LCard.Top + ScaleValue(39);
  LRowGap := ScaleValue(6);
  LInputLeft := Max(LCard.Left + ScaleValue(230),
    LCard.Left + LCard.Width * 42 div 100);
  LInputWidth := Max(ScaleValue(150), LCard.Right - ScaleValue(12) -
    LInputLeft);
  LLabelLeft := LCard.Left + ScaleValue(52);
  LLabelWidth := Max(ScaleValue(130), LInputLeft - LLabelLeft -
    ScaleValue(12));
  for var LIndex := 0 to High(LRowHeights) do
    LRowHeights[LIndex] := RequiredWellHeight(LIndex, LInputWidth);
  LAvailable := LCard.Bottom - LRowTop - ScaleValue(8) -
    3 * LRowGap;
  LExtra := Max(0, LAvailable - (LRowHeights[0] + LRowHeights[1] +
    LRowHeights[2] + LRowHeights[3]));
  for var LIndex := 0 to High(LRowHeights) do
  begin
    var LShare := LExtra div Length(LRowHeights);
    if LIndex < (LExtra mod Length(LRowHeights)) then
      Inc(LShare);
    Inc(LRowHeights[LIndex], LShare);
  end;
  LRowTops[0] := LRowTop;
  for var LIndex := 1 to High(LRowTops) do
    LRowTops[LIndex] := LRowTops[LIndex - 1] + LRowHeights[LIndex - 1] +
      LRowGap;

  LabelFileExtensionsTitle.SetBounds(LCard.Left + ScaleValue(16),
    LCard.Top + ScaleValue(15), LCard.Width - ScaleValue(32),
    ScaleValue(20));
  Label2.SetBounds(LLabelLeft, LRowTops[0] + ScaleValue(7), LLabelWidth,
    ScaleValue(18));
  Label3.SetBounds(LLabelLeft, LRowTops[1] + ScaleValue(7), LLabelWidth,
    ScaleValue(18));
  Label4.SetBounds(LLabelLeft, LRowTops[2] + ScaleValue(7), LLabelWidth,
    ScaleValue(18));
  Label6.SetBounds(LLabelLeft, LRowTops[3] + ScaleValue(7), LLabelWidth,
    ScaleValue(18));
  for var LLabel in TArray<TLabel>.Create(Label2, Label3, Label4, Label6) do
  begin
    LLabel.Font.Style := [fsBold];
    LLabel.Font.Size := cSettingsFontSize;
  end;
  for var LIndex := 0 to High(FGeneralExtensionPanels) do
    SetGeneralExtensionBounds(LIndex, LRowTops[LIndex], LRowHeights[LIndex],
      LInputLeft, LInputWidth);
  for var LIndex := 0 to High(FGeneralExtensionPanels) do
    FGeneralExtensionPanels[LIndex].BringToFront;
end;

procedure TFrmSettings.ConfigureMenuPage;
const
  cMenuCheckboxHeight = 19;

  procedure SetMenuCheckBoxBounds(ACheckBox: TCheckBox; const ACard: TRect;
    ALeft, ATop, ARight: Integer);
  begin
    ACheckBox.SetBounds(ALeft, ATop, Max(1, ARight - ALeft),
      ScaleValue(cMenuCheckboxHeight));
  end;

var
  LCommon, LDelphi, LLazarus: TRect;
  LInset, LCommonLeft, LMid, LLeftText, LRightText, LRowTop,
    LRowGap: Integer;
begin
  PaintBoxMenu.SendToBack;
  Image1.Visible := False;
  Image2.Visible := False;
  Image3.Visible := False;

  LCommon := FLayout.MenuCommonCard;
  LDelphi := FLayout.MenuDelphiCard;
  LLazarus := FLayout.MenuLazarusCard;
  for var LCompactControl in TArray<TControl>.Create(CheckBoxSubMenuCommonTasks,
    CheckBoxShowInfoDProj, CheckBoxSubMenuCompileRC, CheckBoxSubMenuOpenCmdRAD,
    CheckBoxSubMenuMSBuild, CheckBoxSubMenuMSBuildAnother, CheckBoxSubMenuRunTouch,
    CheckBoxSubMenuOpenDelphi, CheckBoxSubMenuFormat, CheckBoxSubMenuVCLStyles,
    CheckBoxSubMenuFMXStyles, CheckBoxActivateLazarus,
    CheckBoxSubMenuLazarus) do
  begin
    SetDevShellFont(LCompactControl, TDevShellTheme.cFontName,
      cDenseDataFontSize);
    TCheckBox(LCompactControl).WordWrap := True;
  end;
  LInset := ScaleValue(18);
  LCommonLeft := LCommon.Left + ScaleValue(54);
  LRowGap := ScaleValue(20);
  LRowTop := LCommon.Top + ScaleValue(50);

  SetMenuCheckBoxBounds(CheckBoxSubMenuCommonTasks, LCommon, LCommonLeft,
    LRowTop, LCommon.Right - LInset);
  SetMenuCheckBoxBounds(CheckBoxShowInfoDProj, LCommon, LCommonLeft,
    LRowTop + LRowGap, LCommon.Right - LInset);
  SetMenuCheckBoxBounds(CheckBoxSubMenuCompileRC, LCommon, LCommonLeft,
    LRowTop + 2 * LRowGap, LCommon.Right - LInset);

  LMid := LDelphi.Left + LDelphi.Width div 2;
  LLeftText := LDelphi.Left + ScaleValue(70);
  LRightText := LMid + ScaleValue(40);
  LRowTop := LDelphi.Top + ScaleValue(48);
  LRowGap := ScaleValue(20);
  SetMenuCheckBoxBounds(CheckBoxSubMenuOpenCmdRAD, LDelphi, LLeftText,
    LRowTop, LMid - ScaleValue(16));
  CheckBoxSubMenuOpenCmdRAD.Height := ScaleValue(28);
  SetMenuCheckBoxBounds(CheckBoxSubMenuMSBuild, LDelphi, LLeftText,
    LRowTop + ScaleValue(28), LMid - ScaleValue(16));
  SetMenuCheckBoxBounds(CheckBoxSubMenuMSBuildAnother, LDelphi, LLeftText,
    LRowTop + ScaleValue(48), LMid - ScaleValue(16));
  CheckBoxSubMenuMSBuildAnother.Height := ScaleValue(28);
  SetMenuCheckBoxBounds(CheckBoxSubMenuRunTouch, LDelphi, LLeftText,
    LRowTop + ScaleValue(76), LMid - ScaleValue(16));

  SetMenuCheckBoxBounds(CheckBoxSubMenuOpenDelphi, LDelphi, LRightText,
    LRowTop, LDelphi.Right - LInset);
  SetMenuCheckBoxBounds(CheckBoxSubMenuFormat, LDelphi, LRightText,
    LRowTop + LRowGap, LDelphi.Right - LInset);
  SetMenuCheckBoxBounds(CheckBoxSubMenuVCLStyles, LDelphi, LRightText,
    LRowTop + 2 * LRowGap, LDelphi.Right - LInset);
  SetMenuCheckBoxBounds(CheckBoxSubMenuFMXStyles, LDelphi, LRightText,
    LRowTop + 3 * LRowGap, LDelphi.Right - LInset);

  LRowTop := LLazarus.Top + ScaleValue(50);
  SetMenuCheckBoxBounds(CheckBoxActivateLazarus, LLazarus,
    LLazarus.Left + ScaleValue(54), LRowTop, LLazarus.Right - LInset);
  SetMenuCheckBoxBounds(CheckBoxSubMenuLazarus, LLazarus,
    LLazarus.Left + ScaleValue(74), LRowTop + ScaleValue(22),
    LLazarus.Right - LInset);
  PaintBoxMenu.Invalidate;
end;

procedure TFrmSettings.MenuDecorationsPaint(Sender: TObject);
const
  cMenuCardCornerRadius = 6;
  cMenuGroupIconSize = 20;
  cMenuCommandIconSize = 20;
  cMenuGroupIconCodes: array[0..2] of Word = (
    cPhListChecks, cPhCode, cPhCodeBlock);
  cMenuCommandIconCodes: array[0..7] of Word = (
    cPhAppWindow, cPhHammer, cPhHammer, cPhHandTap,
    cPhCode, cPhBracketsCurly, cPhBrowser, cPhFlame);
var
  LPhosphorFont: TPhosphorFont;

  procedure DrawCard(const ACard: TRect; const ATheme: TDevShellTheme);
  begin
    var LBorderColor := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, cGeneralCardBorderBlend);
    DrawAntialiasedRoundedRectangle(PaintBoxMenu.Canvas, ACard,
      BlendColor(ATheme.BackgroundColor, ATheme.TextColor, 0.02),
      LBorderColor,
      MulDiv(cMenuCardCornerRadius, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  procedure DrawGroupTitle(const ACaption: string; const ACard: TRect;
    const ATheme: TDevShellTheme);
  begin
    PaintBoxMenu.Canvas.Font.Name := TDevShellTheme.cFontName;
    PaintBoxMenu.Canvas.Font.Size := cSettingsFontSize + 1;
    PaintBoxMenu.Canvas.Font.Style := [fsBold];
    PaintBoxMenu.Canvas.Font.Color := ATheme.TextColor;
    PaintBoxMenu.Canvas.Brush.Style := bsClear;
    var LTextRect := Rect(ACard.Left + ScaleValue(54),
      ACard.Top + ScaleValue(12), ACard.Right - ScaleValue(16),
      ACard.Top + ScaleValue(32));
    DrawText(PaintBoxMenu.Canvas.Handle, PChar(ACaption), Length(ACaption),
      LTextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;

  procedure DrawMenuIcon(ACode: Word; ALeft, ATop: Integer;
    AColor: TColor; ASize: Integer);
  begin
    var LIconRect := Rect(ALeft, ATop, ALeft + ASize, ATop + ASize);
    LPhosphorFont.DrawDuotoneIcon(PaintBoxMenu.Canvas.Handle, ACode,
      LIconRect, AColor, AColor, 76, False);
  end;

  procedure DrawGroupDescription(const ACaption: string; const ACard: TRect;
    const ATheme: TDevShellTheme);
  begin
    PaintBoxMenu.Canvas.Font.Name := TDevShellTheme.cFontName;
    PaintBoxMenu.Canvas.Font.Size := cCompactDataFontSize;
    PaintBoxMenu.Canvas.Font.Style := [];
    PaintBoxMenu.Canvas.Font.Color := ATheme.MutedColor;
    PaintBoxMenu.Canvas.Brush.Style := bsClear;
    var LTextRect := Rect(ACard.Left + ScaleValue(54),
      ACard.Top + ScaleValue(31), ACard.Right - ScaleValue(16),
      ACard.Top + ScaleValue(45));
    DrawText(PaintBoxMenu.Canvas.Handle, PChar(ACaption), Length(ACaption),
      LTextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
  end;

  function CommandIconColor(AIndex: Integer;
    const ATheme: TDevShellTheme): TColor;
  begin
    case AIndex of
      0..2: Result := ATheme.PrimaryColor;
      3: Result := ATheme.SecondaryColor;
      4: Result := ATheme.SuccessColor;
      5: Result := ATheme.PrimaryColor;
      6: Result := ATheme.AccentColor;
      7: Result := ATheme.DangerColor;
    else
      Result := ATheme.TextColor;
    end;
  end;

begin
  var LTheme := TDevShellTheme.ActiveTheme;
  PaintBoxMenu.Canvas.Brush.Style := bsSolid;
  PaintBoxMenu.Canvas.Brush.Color := LTheme.BackgroundColor;
  PaintBoxMenu.Canvas.FillRect(PaintBoxMenu.ClientRect);
  DrawCard(FLayout.MenuCommonCard, LTheme);
  DrawCard(FLayout.MenuDelphiCard, LTheme);
  DrawCard(FLayout.MenuLazarusCard, LTheme);
  DrawGroupTitle('Common tasks', FLayout.MenuCommonCard, LTheme);
  DrawGroupTitle('Delphi tools', FLayout.MenuDelphiCard, LTheme);
  DrawGroupTitle('Lazarus', FLayout.MenuLazarusCard, LTheme);
  DrawGroupDescription('Configure the Common Tasks section in Explorer.',
    FLayout.MenuCommonCard, LTheme);
  DrawGroupDescription('Configure the Delphi tools section in Explorer.',
    FLayout.MenuDelphiCard, LTheme);
  DrawGroupDescription('Configure the Lazarus section in Explorer.',
    FLayout.MenuLazarusCard, LTheme);

  PaintBoxMenu.Canvas.Pen.Color := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralInputBorderBlend);
  PaintBoxMenu.Canvas.Pen.Style := psDot;
  PaintBoxMenu.Canvas.Pen.Width := 1;
  var LConnectorX := CheckBoxActivateLazarus.Left + ScaleValue(8);
  var LConnectorTop := CheckBoxActivateLazarus.Top +
    CheckBoxActivateLazarus.Height;
  var LConnectorBottom := CheckBoxSubMenuLazarus.Top +
    CheckBoxSubMenuLazarus.Height div 2;
  PaintBoxMenu.Canvas.MoveTo(LConnectorX, LConnectorTop);
  PaintBoxMenu.Canvas.LineTo(LConnectorX, LConnectorBottom);
  PaintBoxMenu.Canvas.LineTo(CheckBoxSubMenuLazarus.Left - ScaleValue(4),
    LConnectorBottom);
  PaintBoxMenu.Canvas.Pen.Style := psSolid;

  // The mockup deliberately separates the two Delphi-tools columns.  Keep the
  // line inside the card so it reads as structure without turning into a box.
  PaintBoxMenu.Canvas.Pen.Color := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  var LColumnDividerX := FLayout.MenuDelphiCard.Left +
    FLayout.MenuDelphiCard.Width div 2;
  PaintBoxMenu.Canvas.MoveTo(LColumnDividerX,
    FLayout.MenuDelphiCard.Top + ScaleValue(54));
  PaintBoxMenu.Canvas.LineTo(LColumnDividerX,
    FLayout.MenuDelphiCard.Bottom - ScaleValue(14));

  if not TryGetPhosphorFont(LPhosphorFont) then
    Exit;

  DrawMenuIcon(cMenuGroupIconCodes[0], FLayout.MenuCommonCard.Left +
    ScaleValue(18), FLayout.MenuCommonCard.Top + ScaleValue(12),
    LTheme.SecondaryColor, ScaleValue(cMenuGroupIconSize));
  DrawMenuIcon(cMenuGroupIconCodes[1], FLayout.MenuDelphiCard.Left +
    ScaleValue(18), FLayout.MenuDelphiCard.Top + ScaleValue(12),
    LTheme.PrimaryColor, ScaleValue(cMenuGroupIconSize));
  DrawMenuIcon(cMenuGroupIconCodes[2], FLayout.MenuLazarusCard.Left +
    ScaleValue(18), FLayout.MenuLazarusCard.Top + ScaleValue(12),
    LTheme.SecondaryColor, ScaleValue(cMenuGroupIconSize));

  for var LIndex := 0 to 3 do
  begin
    var LLeftControl := TArray<TCheckBox>.Create(CheckBoxSubMenuOpenCmdRAD,
      CheckBoxSubMenuMSBuild, CheckBoxSubMenuMSBuildAnother,
      CheckBoxSubMenuRunTouch)[LIndex];
    var LRightControl := TArray<TCheckBox>.Create(CheckBoxSubMenuOpenDelphi,
      CheckBoxSubMenuFormat, CheckBoxSubMenuVCLStyles,
      CheckBoxSubMenuFMXStyles)[LIndex];
    var LIconTop := LLeftControl.Top -
      (ScaleValue(cMenuCommandIconSize) - LLeftControl.Height) div 2;
    DrawMenuIcon(cMenuCommandIconCodes[LIndex], LLeftControl.Left -
      ScaleValue(30), LIconTop, CommandIconColor(LIndex, LTheme),
      ScaleValue(cMenuCommandIconSize));
    DrawMenuIcon(cMenuCommandIconCodes[LIndex + 4], LRightControl.Left -
      ScaleValue(30), LRightControl.Top -
      (ScaleValue(cMenuCommandIconSize) - LRightControl.Height) div 2,
      CommandIconColor(LIndex + 4, LTheme),
      ScaleValue(cMenuCommandIconSize));
  end;
end;

procedure TFrmSettings.CreateCustomToolsControls;
begin
  FMacroNames := TStringList.Create;
  FMacroDescriptions := TStringList.Create;

  FCustomEnabled := TCheckBox.Create(Self);
  FCustomEnabled.Parent := PanelCustomTools;
  FCustomEnabled.Caption := 'Enabled';
  FCustomEnabled.OnClick := CustomToolControlChanged;

  FExtensionsPanel := TFlowPanel.Create(Self);
  FExtensionsPanel.Parent := PanelCustomTools;
  FExtensionsPanel.BevelInner := bvNone;
  FExtensionsPanel.BevelOuter := bvNone;
  FExtensionsPanel.BorderStyle := bsNone;
  FExtensionsPanel.ParentBackground := False;
  FExtensionsPanel.StyleElements := FExtensionsPanel.StyleElements - [seClient];
  FExtensionsPanel.AutoWrap := True;
  FExtensionsPanel.FlowStyle := fsLeftRightTopBottom;

  FMacroSearch := TEdit.Create(Self);
  FMacroSearch.Parent := PanelCustomTools;
  FMacroSearch.AutoSize := False;
  FMacroSearch.BevelInner := bvNone;
  FMacroSearch.BevelOuter := bvNone;
  FMacroSearch.BorderStyle := bsNone;
  FMacroSearch.StyleName := 'Windows';
  FMacroSearch.TextHint := 'Search macros';
  FMacroSearch.OnChange := MacroSearchChange;
  FMacroSearch.OnEnter := CustomToolInputFocusChanged;
  FMacroSearch.OnExit := CustomToolInputFocusChanged;

  FMenuPreview := TLabel.Create(Self);
  FMenuPreview.Parent := PanelCustomTools;
  FMenuPreview.AutoSize := False;
  FMenuPreview.Layout := tlCenter;
  FMenuPreview.WordWrap := True;
  FMenuPreview.EllipsisPosition := epNone;
  FMenuPreview.ShowHint := True;

  FValidateButton := TSimpleUIButton.Create(Self);
  FValidateButton.Parent := PanelCustomTools;
  FValidateButton.Caption := 'Validate command';
  FValidateButton.ContentPadding := 7;
  FValidateButton.ImageSpacing := 6;
  FValidateButton.OnClick := ValidateCommandClick;

  FValidationStatus := TLabel.Create(Self);
  FValidationStatus.Parent := PanelCustomTools;
  FValidationStatus.AutoSize := False;
  FValidationStatus.Layout := tlCenter;

  DBEditName.OnEnter := CustomToolInputFocusChanged;
  DBEditName.OnExit := CustomToolInputFocusChanged;
  DBEditMenu.OnEnter := CustomToolInputFocusChanged;
  DBEditMenu.OnExit := CustomToolInputFocusChanged;
  DBMemoScript.OnEnter := CustomToolInputFocusChanged;
  DBMemoScript.OnExit := CustomToolInputFocusChanged;
  DBEditName.OnChange := CustomToolControlChanged;
  DBEditMenu.OnChange := CustomToolControlChanged;
  DBEditExtensions.OnChange := CustomToolControlChanged;
  DBMemoScript.OnChange := CustomToolControlChanged;
  DBComboBoxGroup.OnChange := CustomToolControlChanged;
  DBLookupComboBoxDelphi.OnChange := CustomToolControlChanged;
  DBComboBoxImage.OnChange := CustomToolControlChanged;
  DBCheckBoxRunAs.OnClick := CustomToolControlChanged;
end;

procedure TFrmSettings.SaveSelectedTool;
begin
  if FLoadingCustomTool or not Assigned(FToolsModel) or
     (FToolsModel.Count = 0) then
    Exit;
  var LTool := FToolsModel.Current;
  LTool.Name := DBEditName.Text;
  LTool.GroupName := DBComboBoxGroup.Text;
  LTool.MenuLabel := DBEditMenu.Text;
  LTool.Extensions := DBEditExtensions.Text;
  LTool.Script := DBMemoScript.Text;
  LTool.ImageKey := DBComboBoxImage.Text;
  if (DBLookupComboBoxDelphi.ItemIndex >= 0) and
     (DBLookupComboBoxDelphi.ItemIndex < FVersionIds.Count) then
    LTool.VersionId := FVersionIds[DBLookupComboBoxDelphi.ItemIndex];
  LTool.RunAsAdministrator := DBCheckBoxRunAs.Checked;
  LTool.Enabled := FCustomEnabled.Checked;

  FLoadingCustomTool := True;
  try
    FToolsModel.UpdateCurrent(LTool);
  finally
    FLoadingCustomTool := False;
  end;
end;

procedure TFrmSettings.LoadSelectedTool;
begin
  if not Assigned(FToolsModel) then
    Exit;
  FLoadingCustomTool := True;
  try
    DBGrid1.ItemCount := FToolsModel.Count;
    DBGrid1.ItemIndex := FToolsModel.SelectedIndex;
    var LHasTool := FToolsModel.Count > 0;
    for var LControl in TArray<TControl>.Create(DBEditName,
      DBComboBoxGroup, DBEditMenu, DBEditExtensions, DBMemoScript,
      DBLookupComboBoxDelphi, DBComboBoxImage, DBCheckBoxRunAs,
      FCustomEnabled, ButtonDeleteTool, FValidateButton) do
      LControl.Enabled := LHasTool;
    if LHasTool then
    begin
      var LTool := FToolsModel.Current;
      DBEditName.Text := LTool.Name;
      DBComboBoxGroup.ItemIndex := DBComboBoxGroup.Items.IndexOf(LTool.GroupName);
      DBEditMenu.Text := LTool.MenuLabel;
      DBEditExtensions.Text := LTool.Extensions;
      DBMemoScript.Text := LTool.Script;
      DBComboBoxImage.ItemIndex := DBComboBoxImage.Items.IndexOf(LTool.ImageKey);
      DBLookupComboBoxDelphi.ItemIndex := FVersionIds.IndexOf(LTool.VersionId);
      DBCheckBoxRunAs.Checked := LTool.RunAsAdministrator;
      FCustomEnabled.Checked := LTool.Enabled;
    end
    else
    begin
      DBEditName.Clear;
      DBEditMenu.Clear;
      DBEditExtensions.Clear;
      DBMemoScript.Clear;
      DBComboBoxGroup.ItemIndex := -1;
      DBComboBoxImage.ItemIndex := -1;
      DBLookupComboBoxDelphi.ItemIndex := -1;
      DBCheckBoxRunAs.Checked := False;
      FCustomEnabled.Checked := False;
    end;
  finally
    FLoadingCustomTool := False;
  end;
  // Extension content is now known, so recompute the content-aware card
  // before assigning child bounds. This releases blank badge space on short
  // lists and preserves two rows whenever their measured widths require it.
  ApplySettingsLayout;
  ConfigureCustomToolsPage;
  RefreshExtensionChips;
  UpdateCommandPreview;
  DBGrid1.Invalidate;
  PaintBoxCustomTools.Invalidate;
end;

procedure TFrmSettings.RefreshToolList;
begin
  if not Assigned(FToolsModel) then
    Exit;
  FLoadingCustomTool := True;
  try
    DBGrid1.ItemCount := FToolsModel.Count;
    DBGrid1.ItemIndex := FToolsModel.SelectedIndex;
  finally
    FLoadingCustomTool := False;
  end;
  DBGrid1.Invalidate;
end;

procedure TFrmSettings.CustomToolControlChanged(Sender: TObject);
begin
  if FLoadingCustomTool then
    Exit;
  SaveSelectedTool;
  // Version selection can resolve a pending migration review.  Enabled is
  // derived from that review field, so refresh the visible checkbox from the
  // model immediately instead of leaving a stale unchecked glyph behind.
  if (Sender = DBLookupComboBoxDelphi) and Assigned(FToolsModel) and
     (FToolsModel.Count > 0) then
  begin
    FLoadingCustomTool := True;
    try
      FCustomEnabled.Checked := FToolsModel.Current.Enabled;
    finally
      FLoadingCustomTool := False;
    end;
  end;
  if Sender = DBEditExtensions then
  begin
    ApplySettingsLayout;
    ConfigureCustomToolsPage;
    RefreshExtensionChips;
  end;
  UpdateCommandPreview;
  DBGrid1.Invalidate;
  PaintBoxCustomTools.Invalidate;
end;

procedure TFrmSettings.CustomToolInputFocusChanged(Sender: TObject);
begin
  PaintBoxCustomTools.Invalidate;
end;

procedure TFrmSettings.RefreshExtensionChips;
begin
  if not Assigned(FExtensionsPanel) then
    Exit;
  while FExtensionsPanel.ControlCount > 0 do
    FExtensionsPanel.Controls[0].Free;
  if not Assigned(FToolsModel) or (FToolsModel.Count = 0) then
    Exit;

  var LTheme := TDevShellTheme.ActiveTheme;
  var LPalette := DevShellButtonPalette(LTheme);
  LPalette.Background := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, 0.94);
  LPalette.Border := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralInputBorderBlend);
  LPalette.HotBackground := BlendColor(LTheme.AccentColor,
    LTheme.BackgroundColor, 0.88);
  LPalette.HotBorder := LTheme.AccentColor;
  LPalette.FocusedBorder := LTheme.AccentColor;

  var LMetrics := TBitmap.Create;
  try
    var LExtensions := TSettingsToolsModel.SplitExtensions(
      DBEditExtensions.Text);
    for var LIndex := 0 to High(LExtensions) do
    begin
      var LChip := TSimpleUIButton.Create(Self);
      LChip.Parent := FExtensionsPanel;
      LChip.Caption := LExtensions[LIndex] + ' ' + #$00D7;
      LChip.Tag := LIndex;
      LChip.Font.Assign(Font);
      LChip.Font.Size := cCompactDataFontSize;
      LChip.AlignWithMargins := True;
      LChip.Margins.SetBounds(0, 0,
        MulDiv(3, CurrentPPI, cDesignPPI), 0);
      LChip.ContentPadding := 2;
      LMetrics.Canvas.Font.Assign(LChip.Font);
      LChip.SetBounds(0, 0, LMetrics.Canvas.TextWidth(LChip.Caption) +
        MulDiv(10, CurrentPPI, cDesignPPI),
        MulDiv(22, CurrentPPI, cDesignPPI));
      LChip.ApplyPalette(LPalette);
      TControlAccess(LChip).Color := LPalette.Background;
      LChip.OnClick := ExtensionChipClick;
    end;
  finally
    LMetrics.Free;
  end;

  var LAddButton := TSimpleUIButton.Create(Self);
  LAddButton.Parent := FExtensionsPanel;
  LAddButton.Caption := '+';
  LAddButton.Font.Assign(Font);
  LAddButton.AlignWithMargins := True;
  LAddButton.Margins.SetBounds(0, 0, 0, 0);
  LAddButton.SetBounds(0, 0, MulDiv(28, CurrentPPI, cDesignPPI),
    MulDiv(22, CurrentPPI, cDesignPPI));
  LAddButton.ApplyPalette(LPalette);
  TControlAccess(LAddButton).Color := LPalette.Background;
  LAddButton.OnClick := AddExtensionClick;
  FExtensionsPanel.Realign;
end;
procedure TFrmSettings.ExtensionChipClick(Sender: TObject);
begin
  var LExtensions := TSettingsToolsModel.SplitExtensions(
    DBEditExtensions.Text);
  var LRemoveIndex := TControl(Sender).Tag;
  var LValues := TStringList.Create;
  try
    for var LIndex := 0 to High(LExtensions) do
      if LIndex <> LRemoveIndex then
        LValues.Add(LExtensions[LIndex]);
    DBEditExtensions.Text := StringReplace(LValues.CommaText, '"', '',
      [rfReplaceAll]);
  finally
    LValues.Free;
  end;
end;

procedure TFrmSettings.AddExtensionClick(Sender: TObject);
begin
  var LValue := '';
  var LPromptValue := LValue;
  if not TFrmExtensionDialog.Execute(Self, LPromptValue, LValue) then
    Exit;
  LValue := Trim(LValue);
  if LValue = '' then
    Exit;
  if not LValue.StartsWith('.') then
    LValue := '.' + LValue;
  var LExtensions := TSettingsToolsModel.SplitExtensions(
    DBEditExtensions.Text);
  SetLength(LExtensions, Length(LExtensions) + 1);
  LExtensions[High(LExtensions)] := LValue;
  DBEditExtensions.Text := TSettingsToolsModel.JoinExtensions(LExtensions);
end;

procedure TFrmSettings.MacroSearchChange(Sender: TObject);
begin
  ListViewMacros.Items.BeginUpdate;
  try
    ListViewMacros.Items.Clear;
    var LFilter := Trim(FMacroSearch.Text);
    for var LIndex := 0 to FMacroNames.Count - 1 do
      if (LFilter = '') or ContainsText(FMacroNames[LIndex], LFilter) or
         ContainsText(FMacroDescriptions[LIndex], LFilter) then
      begin
        var LItem := ListViewMacros.Items.Add;
        LItem.Caption := FMacroNames[LIndex];
        LItem.SubItems.Add(FMacroDescriptions[LIndex]);
      end;
  finally
    ListViewMacros.Items.EndUpdate;
  end;
end;

procedure TFrmSettings.UpdateCommandPreview;
begin
  if not Assigned(FMenuPreview) or not Assigned(FToolsModel) then
    Exit;
  if FToolsModel.Count = 0 then
  begin
    FMenuPreview.Caption := '';
    FValidationStatus.Caption := '';
    Exit;
  end;
  FMenuPreview.Caption := DBEditMenu.Text;
  FMenuPreview.Hint := FMenuPreview.Caption;
  DBEditMenu.Hint := DBEditMenu.Text;
  DBEditMenu.ShowHint := True;
  var LValidation := TSettingsToolsModel.Validate(FToolsModel.Current);
  if LValidation = '' then
    FValidationStatus.Caption := 'Ready'
  else
    FValidationStatus.Caption := LValidation;
end;

procedure TFrmSettings.ValidateCommandClick(Sender: TObject);
begin
  SaveSelectedTool;
  UpdateCommandPreview;
end;

procedure TFrmSettings.ConfigureCustomToolsPage;
const
  cCustomToolButtonWidth = 80;
  cCustomToolButtonHeight = 21;
  cCustomInputHeight = 22;
  cCustomComboItemHeight = 20;

  function ContentRect(const ACard: TRect): TRect;
  begin
    Result := ACard;
    InflateRect(Result, -ScaleValue(12), -ScaleValue(12));
  end;

  procedure SetInputBounds(AControl: TControl; const AFrame: TRect);
  var
    LPaddingX, LRightPaddingX, LPaddingY: Integer;
  begin
    LPaddingX := ScaleValue(cCustomInputPaddingX);
    LRightPaddingX := ScaleValue(cCustomInputRightPaddingX);
    LPaddingY := ScaleValue(cCustomInputPaddingY);
    AControl.SetBounds(AFrame.Left + LPaddingX, AFrame.Top + LPaddingY,
      Max(1, AFrame.Width - LPaddingX - LRightPaddingX),
      Max(1, AFrame.Height - 2 * LPaddingY));
  end;

var
  LTools, LIdentity, LAvailability, LCommand, LMacros, LPreview, LContent,
    LLeftColumn, LRightColumn, LFrame: TRect;
  LGap, LInputHeight, LHalfWidth: Integer;
begin
  PaintBoxCustomTools.SendToBack;
  Image5.Visible := False;
  Label12.Visible := False;

  LTools := FLayout.CustomToolsCard;
  LIdentity := FLayout.CustomIdentityCard;
  LAvailability := FLayout.CustomAvailabilityCard;
  LCommand := FLayout.CustomCommandCard;
  LMacros := FLayout.CustomMacrosCard;
  LPreview := FLayout.CustomPreviewCard;
  LGap := ScaleValue(8);
  LInputHeight := ScaleValue(cCustomInputHeight);

  LContent := ContentRect(LTools);
  ButtonNewTool.SetBounds(LContent.Right - ScaleValue(cCustomToolButtonWidth),
    LTools.Top + ScaleValue(5), ScaleValue(cCustomToolButtonWidth),
    ScaleValue(cCustomToolButtonHeight));
  ButtonDeleteTool.SetBounds(LContent.Right - ScaleValue(cCustomToolButtonWidth),
    LTools.Bottom - ScaleValue(31), ScaleValue(cCustomToolButtonWidth),
    ScaleValue(cCustomToolButtonHeight));
  DBGrid1.SetBounds(LContent.Left, LTools.Top + ScaleValue(31),
    LContent.Width, Max(ScaleValue(40), LTools.Height - ScaleValue(68)));
  DBGrid1.BorderStyle := bsNone;
  DBGrid1.ItemHeight := MulDiv(cCustomListRowHeight, CurrentPPI, cDesignPPI);
  DBGrid1.ItemMargins.Left := 0;
  DBGrid1.ItemMargins.Top := 0;
  DBGrid1.ItemMargins.Right := 0;
  DBGrid1.ItemMargins.Bottom := 0;
  ButtonNewTool.ContentPadding := 0;
  ButtonNewTool.ImageSpacing := 2;
  ButtonDeleteTool.ContentPadding := 0;
  ButtonDeleteTool.ImageSpacing := 2;

  LContent := ContentRect(LIdentity);
  LHalfWidth := (LContent.Width - LGap) div 2;
  LLeftColumn := Rect(LContent.Left, LContent.Top + ScaleValue(36),
    LContent.Left + LHalfWidth, LContent.Bottom);
  LRightColumn := Rect(LLeftColumn.Right + LGap, LLeftColumn.Top,
    LContent.Right, LContent.Bottom);
  Label7.SetBounds(LLeftColumn.Left, LContent.Top + ScaleValue(20),
    LLeftColumn.Width, ScaleValue(15));
  DBComboBoxGroup.SetBounds(LLeftColumn.Left, LLeftColumn.Top,
    LLeftColumn.Width, LInputHeight);
  Label8.SetBounds(LRightColumn.Left, LContent.Top + ScaleValue(20),
    LRightColumn.Width, ScaleValue(15));
  SetInputBounds(DBEditName, Rect(LRightColumn.Left, LRightColumn.Top,
    LRightColumn.Right, LRightColumn.Top + LInputHeight));

  LabelDelphi.SetBounds(LLeftColumn.Left, LLeftColumn.Top + LInputHeight +
    ScaleValue(7),
    LLeftColumn.Width, ScaleValue(15));
  DBLookupComboBoxDelphi.SetBounds(LLeftColumn.Left, LabelDelphi.Top +
    LabelDelphi.Height + ScaleValue(1), LLeftColumn.Width, LInputHeight);
  Label14.SetBounds(LRightColumn.Left, LabelDelphi.Top,
    LRightColumn.Width, ScaleValue(15));
  DBComboBoxImage.SetBounds(LRightColumn.Left, Label14.Top + Label14.Height +
    ScaleValue(1),
    Max(ScaleValue(50), LRightColumn.Width * 45 div 100), LInputHeight);
  FCustomEnabled.SetBounds(DBComboBoxImage.Left + DBComboBoxImage.Width +
    ScaleValue(8),
    DBComboBoxImage.Top, Max(ScaleValue(60), LRightColumn.Right -
    DBComboBoxImage.Left - DBComboBoxImage.Width - ScaleValue(8)),
    LInputHeight);

  // The third row follows the second with the same measured clearance as the
  // first-to-second transition.  It is intentionally not bottom-anchored:
  // anchoring was what collapsed the Menu Label into the preceding editors.
  Label9.SetBounds(LContent.Left, DBLookupComboBoxDelphi.Top + DBLookupComboBoxDelphi.Height +
    ScaleValue(7), LContent.Width, ScaleValue(15));
  LFrame := Rect(LContent.Left, Label9.Top + Label9.Height + ScaleValue(1),
    LContent.Right, Label9.Top + Label9.Height + ScaleValue(1) + LInputHeight);
  SetInputBounds(DBEditMenu, LFrame);

  LContent := ContentRect(LAvailability);
  Label11.SetBounds(LContent.Left, LContent.Top + ScaleValue(18),
    LContent.Width, ScaleValue(15));
  FExtensionsPanel.SetBounds(LContent.Left, LContent.Top + ScaleValue(35),
    LContent.Width, Max(ScaleValue(22), LContent.Bottom -
    (LContent.Top + ScaleValue(37))));
  DBEditExtensions.Visible := False;

  Label10.Visible := False;
  LContent := ContentRect(LCommand);
  // The command caption belongs to the card title row.  Keep the checkbox
  // aligned to that row instead of inheriting the content inset used by the
  // memo below it.
  DBCheckBoxRunAs.SetBounds(LContent.Right - ScaleValue(20),
    LCommand.Top + ScaleValue(8), ScaleValue(18), ScaleValue(20));
  LFrame := Rect(LContent.Left, LContent.Top + ScaleValue(24),
    LContent.Right, LContent.Bottom);
  SetInputBounds(DBMemoScript, LFrame);

  LContent := ContentRect(LMacros);
  LFrame := Rect(LContent.Left, LContent.Top + ScaleValue(25),
    LContent.Right, LContent.Top + ScaleValue(25) + LInputHeight);
  SetInputBounds(FMacroSearch, LFrame);
  ListViewMacros.SetBounds(LContent.Left, LFrame.Bottom + ScaleValue(8),
    LContent.Width, Max(ScaleValue(30), LContent.Bottom - LFrame.Bottom -
    ScaleValue(8)));
  BtnInsertMacro.Visible := False;

  // The preview, validation action, and status are one reading group.  The
  // former three percentage cards caused the preview to wrap and the status
  // to fight the macro list for height at the protected client size.
  LContent := ContentRect(LPreview);
  LFrame := Rect(LContent.Left, LContent.Top + ScaleValue(25),
    LContent.Right, LContent.Top + ScaleValue(25) + LInputHeight);
  FMenuPreview.SetBounds(LFrame.Left + ScaleValue(30), LFrame.Top,
    Max(ScaleValue(24), LFrame.Width - ScaleValue(30)), LFrame.Height);
  FMenuPreview.WordWrap := False;
  FMenuPreview.EllipsisPosition := epEndEllipsis;
  FValidateButton.SetBounds(LContent.Left, LFrame.Bottom + ScaleValue(12),
    Min(ScaleValue(156), LContent.Width), ScaleValue(28));
  FValidationStatus.SetBounds(LContent.Left + ScaleValue(28),
    FValidateButton.Top + FValidateButton.Height + ScaleValue(6),
    Max(ScaleValue(50), LContent.Width - ScaleValue(28)),
    Max(ScaleValue(20), LContent.Bottom - FValidateButton.Top -
      FValidateButton.Height -
      ScaleValue(6)));

  DBComboBoxGroup.ItemHeight := MulDiv(cCustomComboItemHeight,
    CurrentPPI, cDesignPPI);
  DBComboBoxGroup.Style := csOwnerDrawFixed;
  DBComboBoxGroup.OnDrawItem := DBComboBoxGroupDrawItem;
  DBLookupComboBoxDelphi.ItemHeight := MulDiv(cCustomComboItemHeight,
    CurrentPPI, cDesignPPI);
  DBComboBoxImage.ItemHeight := MulDiv(cCustomComboItemHeight,
    CurrentPPI, cDesignPPI);
  DBComboBoxImage.DropDownCount := 12;
  DBComboBoxImage.DropDownWidth := MulDiv(168, CurrentPPI, cDesignPPI);

  ListViewMacros.BorderStyle := bsNone;
  ListViewMacros.GridLines := False;
  ListViewMacros.OwnerDraw := True;
  ListViewMacros.OnDrawItem := ListViewMacrosDrawItem;
  ListViewMacros.ShowColumnHeaders := False;
  FMacroRowImages.ColorDepth := cd32Bit;
  FMacroRowImages.Width := 1;
  FMacroRowImages.Height := MulDiv(24, CurrentPPI, cDesignPPI);
  ListViewMacros.SmallImages := FMacroRowImages;
  if ListViewMacros.Columns.Count >= 2 then
  begin
    ListViewMacros.Columns[0].Width := MulDiv(90, CurrentPPI, cDesignPPI);
    ListViewMacros.Columns[1].Width := Max(1, ListViewMacros.ClientWidth -
      ListViewMacros.Columns[0].Width - GetSystemMetrics(SM_CXVSCROLL) -
      MulDiv(8, CurrentPPI, cDesignPPI));
  end;

  LabelDelphi.Caption := 'Minimum Delphi';
  Label11.Caption := 'File extensions';
  DBCheckBoxRunAs.Caption := '';
  DBCheckBoxRunAs.Alignment := taRightJustify;
  FCustomEnabled.Caption := 'Enabled';
  FCustomEnabled.Alignment := taLeftJustify;
  FExtensionsPanel.AutoWrap := True;
  FExtensionsPanel.FlowStyle := fsLeftRightTopBottom;
  ListViewMacros.ShowHint := True;
  ListViewMacros.OnMouseMove := ListViewMacrosMouseMove;
  PaintBoxCustomTools.Invalidate;
end;

procedure TFrmSettings.LoadAboutLogo;
begin
  var LPng := TPngImage.Create;
  try
    LPng.LoadFromResourceName(HInstance, 'SETTINGS_LOGO');
    FAboutLogo.Picture.Assign(LPng);
  finally
    LPng.Free;
  end;
end;

function NormalizeRegisteredPath(const APath: string): string;
begin
  Result := Trim(APath);
  if (Length(Result) >= 2) and (Result[1] = '"') and
     (Result[Length(Result)] = '"') then
    Result := Copy(Result, 2, Length(Result) - 2);
end;

function ReadRegisteredShellPath(ARootKey: HKEY;
  ARegistryView: LongWord): string;
const
  cShellClassKey =
    'Software\Classes\CLSID\{45DCA61E-3762-45B1-' +
    '939D-2446C0DCAC25}\InprocServer32';
begin
  Result := '';
  var LRegistry := TRegistry.Create(KEY_READ or ARegistryView);
  try
    LRegistry.RootKey := ARootKey;
    if LRegistry.OpenKeyReadOnly(cShellClassKey) and
       LRegistry.ValueExists('') then
      Result := NormalizeRegisteredPath(LRegistry.ReadString(''));
  finally
    LRegistry.Free;
  end;
end;

function ResolveShellExtensionPath: string;
begin
  for var LRegistryView in TArray<LongWord>.Create(KEY_WOW64_64KEY,
    KEY_WOW64_32KEY) do
    for var LRootKey in TArray<HKEY>.Create(HKEY_CURRENT_USER,
      HKEY_LOCAL_MACHINE) do
    begin
      Result := ReadRegisteredShellPath(LRootKey, LRegistryView);
      if FileExists(Result) then
        Exit;
    end;

  var LApplicationFolder := IncludeTrailingPathDelimiter(
    ExtractFilePath(Application.ExeName));
  for var LCandidate in TArray<string>.Create(
    LApplicationFolder + 'DelphiDevShellTools.dll',
    ExpandFileName(LApplicationFolder +
      '..\..\..\Win64\Release\DelphiDevShellTools.dll'),
    ExpandFileName(LApplicationFolder +
      '..\..\..\Win32\Release\DelphiDevShellTools.dll')) do
    if FileExists(LCandidate) then
      Exit(LCandidate);
  Result := '';
end;

function BinaryArchitectureCaption(const AFileName: string): string;
var
  LBinaryType: DWORD;
begin
  if (AFileName <> '') and GetBinaryType(PChar(AFileName), LBinaryType) then
    case LBinaryType of
      SCS_64BIT_BINARY: Exit('64-bit');
      SCS_32BIT_BINARY: Exit('32-bit');
    end;
  Result := Format('%d-bit', [SizeOf(Pointer) * 8]);
end;

procedure TFrmSettings.ConfigureAboutPage;
const
  cAboutLogoSize = 72;
  cAboutLabelLeft = 60;

  function CreateAboutLabel(const ACaption: string; AFontSize: Integer;
    ABold, AMuted: Boolean): TLabel;
  begin
    Result := TLabel.Create(Self);
    Result.Parent := FAboutPanel;
    Result.AutoSize := False;
    Result.Caption := ACaption;
    Result.Font.Name := TDevShellTheme.cFontName;
    Result.Font.Size := AFontSize;
    if ABold then
      Result.Font.Style := [fsBold];
    if AMuted then
      Result.Tag := 1;
  end;

  function CreateAboutLink(const ACaption: string;
    AOnClick: TNotifyEvent): TSimpleUIButton;
  begin
    Result := TSimpleUIButton.Create(Self);
    Result.Parent := FAboutPanel;
    Result.Caption := ACaption;
    Result.Cursor := crHandPoint;
    Result.ContentPadding := 0;
    Result.TabStop := False;
    Result.OnClick := AOnClick;
  end;

  procedure SetDesignBounds(AControl: TControl; ALeft, ATop, AWidth,
    AHeight: Integer);
  begin
    AControl.SetBounds(MulDiv(ALeft, CurrentPPI, cDesignPPI),
      MulDiv(ATop, CurrentPPI, cDesignPPI),
      MulDiv(AWidth, CurrentPPI, cDesignPPI),
      MulDiv(AHeight, CurrentPPI, cDesignPPI));
  end;

begin
  if not Assigned(FAboutPage) then
  begin
    FAboutPage := TTabSheet.Create(Self);
    FAboutPage.PageControl := PageControl1;
    FAboutPage.Caption := 'About';
    FAboutPage.TabVisible := False;

    FAboutPanel := TPanel.Create(Self);
    FAboutPanel.Parent := FAboutPage;
    FAboutPanel.Align := alClient;
    FAboutPanel.BevelInner := bvNone;
    FAboutPanel.BevelOuter := bvNone;
    FAboutPanel.BorderStyle := bsNone;
    FAboutPanel.ParentBackground := False;

    FAboutPaintBox := TPaintBox.Create(Self);
    FAboutPaintBox.Parent := FAboutPanel;
    FAboutPaintBox.Align := alClient;
    FAboutPaintBox.OnPaint := AboutDecorationsPaint;

    FAboutLogo := TImage.Create(Self);
    FAboutLogo.Parent := FAboutPanel;
    FAboutLogo.Center := True;
    FAboutLogo.Proportional := True;
    FAboutLogo.Stretch := True;

    FAboutProduct := CreateAboutLabel('Delphi Dev. Shell Tools', 16,
      True, False);
    FAboutDescription := CreateAboutLabel(
      'Shell Extension for Delphi Developers', 8, False, True);
    FAboutVersionTitle := CreateAboutLabel('Version', 9, False, True);
    FAboutVersion := CreateAboutLabel('', 12, True, False);
    FAboutBuildTitle := CreateAboutLabel('Build', 9, False, True);
    FAboutBuild := CreateAboutLabel('', 12, True, False);
    FAboutArchitectureTitle := CreateAboutLabel('Architecture', 9,
      False, True);
    FAboutArchitecture := CreateAboutLabel('', 12, True, False);
    FAboutAuthorTitle := CreateAboutLabel('Author', 9, False, True);
    FAboutAuthor := CreateAboutLabel('Rodrigo Ruz', 9, False, False);
    FAboutRepositoryTitle := CreateAboutLabel('Website / Repository', 9,
      False, True);
    FAboutLicenseTitle := CreateAboutLabel('License', 9, False, True);
    FAboutPhosphorTitle := CreateAboutLabel('Phosphor Icons', 9, False,
      True);
    FAboutOpenSSLTitle := CreateAboutLabel('OpenSSL Toolkit', 9, False,
      True);

    FAboutRepositoryButton := CreateAboutLink(
      'github.com/RRUZ/delphi-dev-shell-tools', AboutRepositoryClick);
    FAboutPhosphorButton := CreateAboutLink(
      'github.com/phosphor-icons', AboutPhosphorClick);
    FAboutOpenSSLButton := CreateAboutLink('openssl.org',
      AboutOpenSSLClick);

    FAboutLicenseBadge := TDevShellBadgeLabel.Create(Self);
    FAboutLicenseBadge.Parent := FAboutPanel;
    FAboutLicenseBadge.Caption := 'MPL 1.1';
    FAboutLicenseBadge.BadgeRole := dsbrPrimary;

    LoadAboutLogo;
    var LShellExtensionPath := ResolveShellExtensionPath;
    if LShellExtensionPath <> '' then
      FAboutVersion.Caption := GetFileVersion(LShellExtensionPath)
    else
      FAboutVersion.Caption := '';
    if FAboutVersion.Caption = '' then
      FAboutVersion.Caption := 'Not available';
    FAboutVersion.Hint := LShellExtensionPath;
    {$IFDEF DEBUG}
    FAboutBuild.Caption := 'Debug';
    {$ELSEIF Defined(RELEASE)}
    FAboutBuild.Caption := 'Release';
    {$ELSE}
    FAboutBuild.Caption := 'Custom';
    {$ENDIF}
    FAboutArchitecture.Caption := BinaryArchitectureCaption(
      LShellExtensionPath) + ' / ' + TOSVersion.Name;
    FAboutPaintBox.SendToBack;
  end;

  SetDesignBounds(FAboutLogo, 30, 30, cAboutLogoSize, cAboutLogoSize);
  SetDesignBounds(FAboutProduct, 120, 34, 420, 28);
  SetDesignBounds(FAboutDescription, 120, 64, 420, 20);
  SetDesignBounds(FAboutVersionTitle, 50, 130, 160, 18);
  SetDesignBounds(FAboutVersion, 50, 150, 170, 24);
  SetDesignBounds(FAboutBuildTitle, 280, 130, 160, 18);
  SetDesignBounds(FAboutBuild, 280, 150, 170, 24);
  SetDesignBounds(FAboutArchitectureTitle, 510, 130, 170, 18);
  SetDesignBounds(FAboutArchitecture, 510, 150, 180, 24);
  SetDesignBounds(FAboutAuthorTitle, cAboutLabelLeft, 215, 124, 20);
  SetDesignBounds(FAboutAuthor, cAboutValueLeft, 215, 260, 20);
  SetDesignBounds(FAboutRepositoryTitle, cAboutLabelLeft, 247, 124, 20);
  FAboutRepositoryTitle.AutoSize := False;
  SetDesignBounds(FAboutRepositoryButton, cAboutValueLeft, 243, 280, 28);
  SetDesignBounds(FAboutLicenseTitle, cAboutLabelLeft, 279, 124, 20);
  SetDesignBounds(FAboutLicenseBadge, cAboutValueLeft, 275, 70, 22);
  SetDesignBounds(FAboutPhosphorTitle, cAboutLabelLeft, 327, 124, 18);
  SetDesignBounds(FAboutPhosphorButton, cAboutValueLeft, 323, 220, 28);
  SetDesignBounds(FAboutOpenSSLTitle, cAboutLabelLeft, 363, 124, 18);
  SetDesignBounds(FAboutOpenSSLButton, cAboutValueLeft, 359, 180, 28);
  FAboutPaintBox.Invalidate;
end;

procedure TFrmSettings.AboutDecorationsPaint(Sender: TObject);
const
  cAboutCardLeft = 12;
  cAboutCardTop = 12;
  cAboutCardRight = 720;
  cAboutCardBottom = 400;
  cAboutIconLeft = 32;
  cAboutIconSize = 22;
  cAboutRowIconCodes: array[0..4] of Word = (
    cPhUser, cPhGithubLogo, cPhScales, cPhGithubLogo, cPhGlobe);
  cAboutRowIconTops: array[0..4] of Integer = (
    215, 247, 279, 327, 363);
var
  LPhosphorFont: TPhosphorFont;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LCanvas := FAboutPaintBox.Canvas;
  LCanvas.Brush.Style := bsSolid;
  LCanvas.Brush.Color := LTheme.BackgroundColor;
  LCanvas.FillRect(FAboutPaintBox.ClientRect);
  var LBorderColor := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  var LCardRect := Rect(MulDiv(cAboutCardLeft, CurrentPPI, cDesignPPI),
    MulDiv(cAboutCardTop, CurrentPPI, cDesignPPI),
    MulDiv(cAboutCardRight, CurrentPPI, cDesignPPI),
    MulDiv(cAboutCardBottom, CurrentPPI, cDesignPPI));
  DrawAntialiasedRoundedRectangle(LCanvas, LCardRect,
    LTheme.BackgroundColor, LBorderColor,
    MulDiv(cGeneralCardCornerRadius, CurrentPPI, cDesignPPI),
    Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  LCanvas.Pen.Color := LBorderColor;
  // Mirror the TDump Explorer About card cadence and leave a bottom margin.
  for var LTop in TArray<Integer>.Create(120, 195, 315) do
  begin
    LCanvas.MoveTo(MulDiv(30, CurrentPPI, cDesignPPI),
      MulDiv(LTop, CurrentPPI, cDesignPPI));
    LCanvas.LineTo(MulDiv(700, CurrentPPI, cDesignPPI),
      MulDiv(LTop, CurrentPPI, cDesignPPI));
  end;
  for var LLeft in TArray<Integer>.Create(245, 475) do
  begin
    LCanvas.MoveTo(MulDiv(LLeft, CurrentPPI, cDesignPPI),
      MulDiv(125, CurrentPPI, cDesignPPI));
    LCanvas.LineTo(MulDiv(LLeft, CurrentPPI, cDesignPPI),
      MulDiv(180, CurrentPPI, cDesignPPI));
  end;
  if TryGetPhosphorFont(LPhosphorFont) then
    for var LIndex := Low(cAboutRowIconCodes) to
      High(cAboutRowIconCodes) do
    begin
      var LIconRect := Rect(
        MulDiv(cAboutIconLeft, CurrentPPI, cDesignPPI),
        MulDiv(cAboutRowIconTops[LIndex], CurrentPPI, cDesignPPI),
        MulDiv(cAboutIconLeft + cAboutIconSize, CurrentPPI, cDesignPPI),
        MulDiv(cAboutRowIconTops[LIndex] + cAboutIconSize, CurrentPPI,
          cDesignPPI));
      LPhosphorFont.DrawDuotoneIcon(LCanvas.Handle,
        cAboutRowIconCodes[LIndex], LIconRect, LTheme.MutedColor,
        LTheme.MutedColor, 76, False);
    end;
end;

procedure TFrmSettings.AboutRepositoryClick(Sender: TObject);
const
  cAboutRepositoryURL = 'https://github.com/RRUZ/delphi-dev-shell-tools';
begin
  ShellExecute(Handle, 'open', PChar(cAboutRepositoryURL), nil, nil,
    SW_SHOWNORMAL);
end;

procedure TFrmSettings.AboutPhosphorClick(Sender: TObject);
const
  cAboutPhosphorURL = 'https://github.com/phosphor-icons';
begin
  ShellExecute(Handle, 'open', PChar(cAboutPhosphorURL), nil, nil,
    SW_SHOWNORMAL);
end;

procedure TFrmSettings.AboutOpenSSLClick(Sender: TObject);
const
  cAboutOpenSSLURL = 'https://www.openssl.org/';
begin
  ShellExecute(Handle, 'open', PChar(cAboutOpenSSLURL), nil, nil,
    SW_SHOWNORMAL);
end;

procedure TFrmSettings.RebuildCustomToolButtonImages(
  const ATheme: TDevShellTheme);
const
  cCustomButtonIconSize = 16;
var
  LPhosphorFont: TPhosphorFont;
begin
  if FCustomToolButtonImages = nil then
    Exit;

  var LIconSize := MulDiv(cCustomButtonIconSize, CurrentPPI, cDesignPPI);
  FCustomToolButtonImages.Clear;
  FCustomToolButtonImages.ColorDepth := cd32Bit;
  FCustomToolButtonImages.Masked := False;
  FCustomToolButtonImages.BkColor := clNone;
  FCustomToolButtonImages.Width := LIconSize;
  FCustomToolButtonImages.Height := LIconSize;
  if not TryGetPhosphorFont(LPhosphorFont) then
    Exit;

  var LBitmap := TBitmap.Create;
  try
    LPhosphorFont.RenderIconBitmap(LBitmap, cPhPlus, LIconSize,
      ATheme.SecondaryColor, pfwBold);
    FCustomToolButtonImages.Add(LBitmap, nil);
    LPhosphorFont.RenderDuotoneBitmap(LBitmap, cPhTrash, LIconSize,
      ATheme.DangerColor, ATheme.DangerColor, 76, True);
    FCustomToolButtonImages.Add(LBitmap, nil);
    LPhosphorFont.RenderDuotoneBitmap(LBitmap, cPhShieldCheck, LIconSize,
      ATheme.PrimaryColor, ATheme.PrimaryColor, 76, True);
    FCustomToolButtonImages.Add(LBitmap, nil);
  finally
    LBitmap.Free;
  end;
  ButtonNewTool.Images := FCustomToolButtonImages;
  ButtonNewTool.ImageIndex := 0;
  ButtonDeleteTool.Images := FCustomToolButtonImages;
  ButtonDeleteTool.ImageIndex := 1;
  if Assigned(FValidateButton) then
  begin
    FValidateButton.Images := FCustomToolButtonImages;
    FValidateButton.ImageIndex := 2;
  end;
end;

procedure TFrmSettings.CustomToolsDecorationsPaint(Sender: TObject);
const
  cCustomCardCornerRadius = 6;
  cCustomInputCornerRadius = 2;
var
  LPhosphorFont: TPhosphorFont;
  LIconSource: TProjectIconSource;

  function DesignRect(ALeft, ATop, ARight, ABottom: Integer): TRect;
  begin
    Result := Rect(MulDiv(ALeft, CurrentPPI, cDesignPPI),
      MulDiv(ATop, CurrentPPI, cDesignPPI),
      MulDiv(ARight, CurrentPPI, cDesignPPI),
      MulDiv(ABottom, CurrentPPI, cDesignPPI));
  end;

  procedure DrawCard(const ACard: TRect; const ATheme: TDevShellTheme);
  begin
    var LBorderColor := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, cGeneralCardBorderBlend);
    DrawAntialiasedRoundedRectangle(PaintBoxCustomTools.Canvas, ACard,
      BlendColor(ATheme.BackgroundColor, ATheme.TextColor, 0.02),
      LBorderColor,
      MulDiv(cCustomCardCornerRadius, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  procedure DrawCardTitle(const ACaption: string; const ACard: TRect;
    const ATheme: TDevShellTheme);
  begin
    PaintBoxCustomTools.Canvas.Font.Name := TDevShellTheme.cFontName;
    PaintBoxCustomTools.Canvas.Font.Size := cSettingsFontSize + 1;
    PaintBoxCustomTools.Canvas.Font.Style := [];
    PaintBoxCustomTools.Canvas.Font.Color := ATheme.TextColor;
    PaintBoxCustomTools.Canvas.Brush.Style := bsClear;
    var LTextRect := Rect(ACard.Left + ScaleValue(12),
      ACard.Top + ScaleValue(9), ACard.Right - ScaleValue(12),
      ACard.Top + ScaleValue(32));
    DrawText(PaintBoxCustomTools.Canvas.Handle, PChar(ACaption),
      Length(ACaption), LTextRect,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;

  procedure DrawInputBorder(AControl: TWinControl;
    AFrameReference: TControl; const ATheme: TDevShellTheme);
  begin
    var LPaddingX := MulDiv(cCustomInputPaddingX, CurrentPPI, cDesignPPI);
    var LRightPaddingX := MulDiv(cCustomInputRightPaddingX, CurrentPPI,
      cDesignPPI);
    var LPaddingY := MulDiv(cCustomInputPaddingY, CurrentPPI, cDesignPPI);
    var LBorderRect := AControl.BoundsRect;
    Dec(LBorderRect.Left, LPaddingX);
    Inc(LBorderRect.Right, LRightPaddingX);
    if Assigned(AFrameReference) then
    begin
      LBorderRect.Top := AFrameReference.Top;
      LBorderRect.Bottom := AFrameReference.Top + AFrameReference.Height;
    end
    else
      InflateRect(LBorderRect, 0, LPaddingY);
    var LBorderColor := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, cGeneralInputBorderBlend);
    if AControl.Focused then
      LBorderColor := ATheme.AccentColor;
    DrawAntialiasedRoundedRectangle(PaintBoxCustomTools.Canvas, LBorderRect,
      clNone, LBorderColor,
      MulDiv(cCustomInputCornerRadius, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  procedure DrawFixedInputBorder(const ARect: TRect; AFocused: Boolean;
    const ATheme: TDevShellTheme);
  begin
    var LBorderColor := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, cGeneralInputBorderBlend);
    if AFocused then
      LBorderColor := ATheme.AccentColor;
    DrawAntialiasedRoundedRectangle(PaintBoxCustomTools.Canvas, ARect,
      clNone, LBorderColor,
      MulDiv(cCustomInputCornerRadius, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  procedure DrawStatusIcon(const ATheme: TDevShellTheme);
  const
    cCheckCircle = $E184;
  begin
    if not Assigned(FToolsModel) or (FToolsModel.Count = 0) then
      Exit;
    if not TryGetPhosphorFont(LPhosphorFont) then
      Exit;
    var LStatusRect := Rect(FValidationStatus.Left - ScaleValue(25),
      FValidationStatus.Top + (FValidationStatus.Height - ScaleValue(18)) div 2,
      FValidationStatus.Left - ScaleValue(7),
      FValidationStatus.Top + (FValidationStatus.Height + ScaleValue(18)) div 2);
    var LValid := TSettingsToolsModel.Validate(FToolsModel.Current) = '';
    var LCode: Word := cCheckCircle;
    var LColor := ATheme.SuccessColor;
    if not LValid then
    begin
      LCode := cPhWarning;
      LColor := ATheme.WarningColor;
    end;
    LPhosphorFont.DrawDuotoneIcon(PaintBoxCustomTools.Canvas.Handle,
      LCode, LStatusRect, LColor, LColor, 76, False);
  end;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  PaintBoxCustomTools.Canvas.Brush.Style := bsSolid;
  PaintBoxCustomTools.Canvas.Brush.Color := LTheme.BackgroundColor;
  PaintBoxCustomTools.Canvas.FillRect(PaintBoxCustomTools.ClientRect);

  DrawCard(FLayout.CustomToolsCard, LTheme);
  DrawCard(FLayout.CustomIdentityCard, LTheme);
  DrawCard(FLayout.CustomAvailabilityCard, LTheme);
  DrawCard(FLayout.CustomCommandCard, LTheme);
  DrawCard(FLayout.CustomMacrosCard, LTheme);
  DrawCard(FLayout.CustomPreviewCard, LTheme);

  DrawCardTitle('Tools', FLayout.CustomToolsCard, LTheme);
  DrawCardTitle('Identity', FLayout.CustomIdentityCard, LTheme);
  DrawCardTitle('Availability', FLayout.CustomAvailabilityCard, LTheme);
  DrawCardTitle('Command', FLayout.CustomCommandCard, LTheme);
  DrawCardTitle('Macros', FLayout.CustomMacrosCard, LTheme);
  DrawCardTitle('Menu preview', FLayout.CustomPreviewCard, LTheme);
  PaintBoxCustomTools.Canvas.Brush.Style := bsClear;
  PaintBoxCustomTools.Canvas.Font.Name := TDevShellTheme.cFontName;
  // The title-row status must coexist with a shield and trailing checkbox in
  // the protected centre column.  Use the dense UI size so the full caption
  // remains visible at every PPI rather than being hard-clipped.
  PaintBoxCustomTools.Canvas.Font.Size := cDenseDataFontSize;
  PaintBoxCustomTools.Canvas.Font.Style := [];
  PaintBoxCustomTools.Canvas.Font.Color := LTheme.TextColor;
  // The Command heading occupies the left title slot.  Start this status
  // cluster after that slot so the shield never intersects the heading.
  var LRunAsRect := Rect(FLayout.CustomCommandCard.Left + ScaleValue(95),
    DBCheckBoxRunAs.Top, DBCheckBoxRunAs.Left - ScaleValue(7),
    DBCheckBoxRunAs.Top + DBCheckBoxRunAs.Height);
  var LRunAsTextRect := LRunAsRect;
  Inc(LRunAsTextRect.Left, ScaleValue(22));
  DrawText(PaintBoxCustomTools.Canvas.Handle, PChar('Run as administrator'),
    -1, LRunAsTextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or
    DT_NOPREFIX);

  DrawInputBorder(DBEditName, DBComboBoxGroup, LTheme);
  DrawInputBorder(DBEditMenu, nil, LTheme);
  var LSearchFrame := FMacroSearch.BoundsRect;
  InflateRect(LSearchFrame, ScaleValue(cCustomInputPaddingX),
    ScaleValue(cCustomInputPaddingY));
  DrawFixedInputBorder(LSearchFrame, FMacroSearch.Focused, LTheme);
  var LCommandFrame := DBMemoScript.BoundsRect;
  InflateRect(LCommandFrame, ScaleValue(cCustomInputPaddingX),
    ScaleValue(cCustomInputPaddingY));
  DrawFixedInputBorder(LCommandFrame, DBMemoScript.Focused, LTheme);
  var LPreviewFrame := FMenuPreview.BoundsRect;
  LPreviewFrame.Left := LPreviewFrame.Left - ScaleValue(30);
  InflateRect(LPreviewFrame, ScaleValue(1), ScaleValue(1));
  DrawFixedInputBorder(LPreviewFrame, False, LTheme);

  // A single divider separates the preview field from the validation action
  // and status while preserving the reference's one lower card.
  PaintBoxCustomTools.Canvas.Pen.Color := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  PaintBoxCustomTools.Canvas.Pen.Width := 1;
  PaintBoxCustomTools.Canvas.MoveTo(FLayout.CustomPreviewCard.Left +
    ScaleValue(12), FValidateButton.Top - ScaleValue(6));
  PaintBoxCustomTools.Canvas.LineTo(FLayout.CustomPreviewCard.Right -
    ScaleValue(12), FValidateButton.Top - ScaleValue(6));

  var LCommandDividerX := LCommandFrame.Left + ScaleValue(25);
  PaintBoxCustomTools.Canvas.Pen.Color := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  PaintBoxCustomTools.Canvas.Pen.Width := 1;
  PaintBoxCustomTools.Canvas.MoveTo(LCommandDividerX,
    LCommandFrame.Top + ScaleValue(1));
  PaintBoxCustomTools.Canvas.LineTo(LCommandDividerX,
    LCommandFrame.Bottom - ScaleValue(1));
  PaintBoxCustomTools.Canvas.Brush.Style := bsClear;
  PaintBoxCustomTools.Canvas.Font.Name := TDevShellTheme.cFontName;
  PaintBoxCustomTools.Canvas.Font.Size := cCompactDataFontSize;
  PaintBoxCustomTools.Canvas.Font.Style := [];
  PaintBoxCustomTools.Canvas.Font.Color := LTheme.MutedColor;
  var LLineOneRect := Rect(LCommandFrame.Left + ScaleValue(2),
    DBMemoScript.Top, LCommandDividerX - ScaleValue(3),
    DBMemoScript.Top + DBMemoScript.Font.Height + ScaleValue(8));
  DrawText(PaintBoxCustomTools.Canvas.Handle, PChar('1'), -1, LLineOneRect,
    DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  var LLineTwoRect := LLineOneRect;
  OffsetRect(LLineTwoRect, 0, LLineOneRect.Height);
  DrawText(PaintBoxCustomTools.Canvas.Handle, PChar('2'), -1, LLineTwoRect,
    DT_RIGHT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);

  if TryGetPhosphorFont(LPhosphorFont) then
  begin
    var LSearchRect := Rect(LSearchFrame.Left + ScaleValue(8),
      LSearchFrame.Top + (LSearchFrame.Height - ScaleValue(14)) div 2,
      LSearchFrame.Left + ScaleValue(22),
      LSearchFrame.Top + (LSearchFrame.Height + ScaleValue(14)) div 2);
    LPhosphorFont.DrawDuotoneIcon(PaintBoxCustomTools.Canvas.Handle,
      cPhMagnifyingGlass, LSearchRect, LTheme.MutedColor,
      LTheme.MutedColor, 76, False);

    var LAdminRect := Rect(LRunAsRect.Left, LRunAsRect.Top +
      (LRunAsRect.Height - ScaleValue(17)) div 2,
      LRunAsRect.Left + ScaleValue(17), LRunAsRect.Top +
      (LRunAsRect.Height + ScaleValue(17)) div 2);
    LPhosphorFont.DrawDuotoneIcon(PaintBoxCustomTools.Canvas.Handle,
      cPhShieldCheck, LAdminRect, LTheme.WarningColor,
      LTheme.WarningColor, 76, False);

  var LPreviewRect := Rect(LPreviewFrame.Left + ScaleValue(9),
      LPreviewFrame.Top + (LPreviewFrame.Height - ScaleValue(18)) div 2,
      LPreviewFrame.Left + ScaleValue(27), LPreviewFrame.Top +
      (LPreviewFrame.Height + ScaleValue(18)) div 2);
    if Assigned(FToolsModel) and (FToolsModel.Count > 0) then
      TryDrawProjectIcon(PaintBoxCustomTools.Canvas.Handle,
        FToolsModel.Current.ImageKey, LPreviewRect, LTheme, False,
        HInstance, LIconSource)
    else
      LPhosphorFont.DrawDuotoneIcon(PaintBoxCustomTools.Canvas.Handle,
        cPhCode, LPreviewRect, LTheme.PrimaryColor,
        LTheme.PrimaryColor, 76, False);
  end;
  DrawStatusIcon(LTheme);
end;

procedure TFrmSettings.ToolListAfterDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
const
  cCustomGridIconSize = 16;
var
  LSource: TProjectIconSource;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := LTheme.BackgroundColor;
  ACanvas.FillRect(ARect);

  if odSelected in AState then
  begin
    var LSelectionRect := ARect;
    InflateRect(LSelectionRect, -MulDiv(2, CurrentPPI, cDesignPPI),
      -MulDiv(1, CurrentPPI, cDesignPPI));
    var LSelectionColor := BlendColor(LTheme.AccentColor,
      LTheme.BackgroundColor, 0.72);
    DrawAntialiasedRoundedRectangle(ACanvas, LSelectionRect,
      LSelectionColor, LTheme.AccentColor,
      MulDiv(4, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  var LTool := FToolsModel.ItemAt(AIndex);
  var LToolName := LTool.Name;
  var LIconKey := LTool.ImageKey;
  var LIconSize := MulDiv(cCustomGridIconSize, CurrentPPI, cDesignPPI);
  var LIconLeft := ARect.Left + MulDiv(6, CurrentPPI, cDesignPPI);
  var LIconTop := ARect.Top + (ARect.Height - LIconSize) div 2;
  var LIconRect := System.Types.Rect(LIconLeft, LIconTop,
    LIconLeft + LIconSize, LIconTop + LIconSize);
  TryDrawProjectIcon(ACanvas.Handle, LIconKey, LIconRect, LTheme,
    False, HInstance, LSource);
  if StartsText('TDump ', LToolName) then
  begin
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Name := TDevShellTheme.cFontName;
    ACanvas.Font.Size := 6;
    ACanvas.Font.Style := [fsBold];
    ACanvas.Font.Color := LTheme.PrimaryColor;
    var LVariantText := Copy(LToolName, Length('TDump ') + 1, MaxInt);
    DrawText(ACanvas.Handle, PChar(LVariantText),
      Length(LVariantText), LIconRect,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Name := TDevShellTheme.cFontName;
  ACanvas.Font.Size := cCompactDataFontSize;
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := LTheme.TextColor;
  var LTextRect := ARect;
  LTextRect.Left := LIconRect.Right + MulDiv(8, CurrentPPI, cDesignPPI);
  DrawText(ACanvas.Handle, PChar(LToolName), Length(LToolName),
    LTextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
end;

procedure TFrmSettings.ToolListChange(Sender: TObject);
begin
  if FLoadingCustomTool or not Assigned(FToolsModel) then
    Exit;
  SaveSelectedTool;
  FToolsModel.SelectIndex(DBGrid1.ItemIndex);
  LoadSelectedTool;
end;

procedure TFrmSettings.ListViewMacrosDrawItem(Sender: TCustomListView;
  Item: TListItem; Rect: TRect; State: TOwnerDrawState);
var
  LPhosphorFont: TPhosphorFont;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LCanvas := TListView(Sender).Canvas;
  LCanvas.Brush.Style := bsSolid;
  LCanvas.Brush.Color := LTheme.BackgroundColor;
  LCanvas.FillRect(Rect);

  var LRowRect := Rect;
  InflateRect(LRowRect, -MulDiv(2, CurrentPPI, cDesignPPI),
    -MulDiv(2, CurrentPPI, cDesignPPI));
  var LRowColor := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, 0.94);
  var LBorderColor := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  if odSelected in State then
  begin
    LRowColor := BlendColor(LTheme.AccentColor,
      LTheme.BackgroundColor, 0.84);
    LBorderColor := LTheme.AccentColor;
  end;
  DrawAntialiasedRoundedRectangle(LCanvas, LRowRect, LRowColor,
    LBorderColor, MulDiv(4, CurrentPPI, cDesignPPI),
    Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));

  var LIconCode := cPhFileText;
  var LIconColor := LTheme.PrimaryColor;
  if SameText(Item.Caption, '$NAME$') then
  begin
    LIconCode := cPhLink;
    LIconColor := LTheme.AccentColor;
  end
  else if SameText(Item.Caption, '$PATH$') then
  begin
    LIconCode := cPhFolderOpen;
    LIconColor := LTheme.SecondaryColor;
  end
  else if SameText(Item.Caption, '$ONLYNAME$') then
    LIconColor := LTheme.MutedColor;
  if TryGetPhosphorFont(LPhosphorFont) then
  begin
    var LIconRect := System.Types.Rect(LRowRect.Left +
      MulDiv(6, CurrentPPI, cDesignPPI),
      LRowRect.Top + (LRowRect.Height - MulDiv(16, CurrentPPI,
        cDesignPPI)) div 2,
      LRowRect.Left + MulDiv(22, CurrentPPI, cDesignPPI),
      LRowRect.Top + (LRowRect.Height + MulDiv(16, CurrentPPI,
        cDesignPPI)) div 2);
    LPhosphorFont.DrawDuotoneIcon(LCanvas.Handle, LIconCode, LIconRect,
      LIconColor, LIconColor, 76, False);
  end;

  LCanvas.Brush.Style := bsClear;
  LCanvas.Font.Name := TDevShellTheme.cFontName;
  LCanvas.Font.Size := cCompactDataFontSize;
  LCanvas.Font.Style := [];
  LCanvas.Font.Color := LTheme.AccentColor;
  var LNameRect := LRowRect;
  LNameRect.Left := LNameRect.Left + MulDiv(29, CurrentPPI, cDesignPPI);
  // Macro names vary. Measure the active font instead of clipping them into
  // a fixed 65px column, while retaining a flexible description remainder.
  var LNameWidth := Max(MulDiv(65, CurrentPPI, cDesignPPI),
    LCanvas.TextWidth(Item.Caption) + MulDiv(6, CurrentPPI, cDesignPPI));
  LNameRect.Right := Min(LRowRect.Right - MulDiv(42, CurrentPPI, cDesignPPI),
    LNameRect.Left + LNameWidth);
  DrawText(LCanvas.Handle, PChar(Item.Caption), Length(Item.Caption),
    LNameRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);

  var LDescription := '';
  if Item.SubItems.Count > 0 then
    LDescription := Item.SubItems[0];
  LCanvas.Font.Color := LTheme.TextColor;
  var LDescriptionRect := LRowRect;
  LDescriptionRect.Left := LNameRect.Right + MulDiv(4, CurrentPPI,
    cDesignPPI);
  LDescriptionRect.Right := LRowRect.Right -
    MulDiv(6, CurrentPPI, cDesignPPI);
  DrawText(LCanvas.Handle, PChar(LDescription), Length(LDescription),
    LDescriptionRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
end;

procedure TFrmSettings.ListViewMacrosMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  LItem: TListItem;
  LHint: string;
begin
  LItem := ListViewMacros.GetItemAt(X, Y);
  if Assigned(LItem) then
  begin
    LHint := LItem.Caption;
    if LItem.SubItems.Count > 0 then
      LHint := LHint + sLineBreak + LItem.SubItems[0];
  end
  else
    LHint := '';
  if ListViewMacros.Hint <> LHint then
  begin
    ListViewMacros.Hint := LHint;
    Application.CancelHint;
  end;
end;

procedure TFrmSettings.ButtonNewToolClick(Sender: TObject);
begin
  SaveSelectedTool;
  FToolsModel.Append;
  RefreshToolList;
  DBGrid1.ItemIndex := FToolsModel.SelectedIndex;
  LoadSelectedTool;
  DBEditName.SetFocus;
end;

procedure TFrmSettings.ButtonDeleteToolClick(Sender: TObject);
begin
  if not Assigned(FToolsModel) or (FToolsModel.Count = 0) then
    Exit;
  var LToolName := FToolsModel.Current.Name;
  if MessageDlg(Format('Delete custom tool "%s"?', [LToolName]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    FToolsModel.DeleteCurrent;
    RefreshToolList;
    LoadSelectedTool;
  end;
end;

procedure TFrmSettings.ConfigureTitleBar(const ATheme: TDevShellTheme);
begin
  // TTitleBarPanel supplies the custom caption buttons when SystemButtons is
  // false, but VCL still honors BorderIcons when it decides which buttons to
  // create. Keep all three reference buttons enabled and palette-owned.
  BorderIcons := [biSystemMenu, biMinimize, biMaximize];
  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.SystemColors := False;
  CustomTitleBar.StyleColors := False;
  CustomTitleBar.SystemButtons := False;
  CustomTitleBar.CaptionAlignment := taLeftJustify;
  CustomTitleBar.ShowIcon := True;
  CustomTitleBar.Enabled := True;
  CustomTitleBar.BackgroundColor := ATheme.BackgroundColor;
  CustomTitleBar.ForegroundColor := ATheme.TextColor;
  CustomTitleBar.InactiveBackgroundColor := ATheme.BackgroundColor;
  CustomTitleBar.InactiveForegroundColor := ATheme.MutedColor;
  // Keep idle caption cells continuous with the title-band gradient.
  CustomTitleBar.ButtonBackgroundColor := BlendColor(ATheme.PrimaryColor,
    ATheme.BackgroundColor, 0.92);
  CustomTitleBar.ButtonForegroundColor := ATheme.TextColor;
  CustomTitleBar.ButtonHoverBackgroundColor := BlendColor(ATheme.AccentColor,
    ATheme.BackgroundColor, 0.82);
  CustomTitleBar.ButtonHoverForegroundColor := ATheme.TextColor;
  CustomTitleBar.ButtonPressedBackgroundColor := ATheme.AccentColor;
  CustomTitleBar.ButtonPressedForegroundColor := ATheme.TextColor;
  CustomTitleBar.ButtonInactiveBackgroundColor := BlendColor(ATheme.PrimaryColor,
    ATheme.BackgroundColor, 0.92);
  CustomTitleBar.ButtonInactiveForegroundColor := ATheme.MutedColor;
  RefreshTitleBarChrome;
end;

procedure TFrmSettings.RefreshTitleBarChrome;
begin
  if not TitleBarPanel1.HandleAllocated then
    Exit;
  // TCustomTitleBarPanel paints through its own buffered child window. It is
  // not guaranteed to repaint when only the form frame is invalidated.
  RedrawWindow(TitleBarPanel1.Handle, nil, 0,
    RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_UPDATENOW);
end;

procedure TFrmSettings.TitleBarPanelPaint(Sender: TObject; Canvas: TCanvas;
  var ARect: TRect);
var
  LTheme: TDevShellTheme;
  LColor: TColor;
  LBlend: Single;
  LIconSize: Integer;
  LCaptionRect: TRect;
begin
  LTheme := TDevShellTheme.ActiveTheme;
  Canvas.Pen.Style := psSolid;
  for var LRow := ARect.Top to ARect.Bottom - 1 do
  begin
    LBlend := 0.86 + 0.11 * (LRow - ARect.Top) /
      Max(1, ARect.Height - 1);
    LColor := BlendColor(LTheme.PrimaryColor, LTheme.BackgroundColor, LBlend);
    Canvas.Pen.Color := LColor;
    Canvas.MoveTo(ARect.Left, LRow);
    Canvas.LineTo(ARect.Right, LRow);
  end;
  // TTitleBarPanel invokes OnPaint after its default background work.  Draw
  // the branding here so the palette gradient cannot cover the caption.
  LIconSize := ScaleValue(20);
  if Icon.Handle <> 0 then
    DrawIconEx(Canvas.Handle, ScaleValue(14),
      (ARect.Height - LIconSize) div 2, Icon.Handle, LIconSize, LIconSize,
      0, 0, DI_NORMAL);
  if (Icon.Handle = 0) and (Application.Icon.Handle <> 0) then
    DrawIconEx(Canvas.Handle, ScaleValue(14),
      (ARect.Height - LIconSize) div 2, Application.Icon.Handle, LIconSize,
      LIconSize, 0, 0, DI_NORMAL);
  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(Font);
  Canvas.Font.Name := TDevShellTheme.cFontName;
  Canvas.Font.Size := cSettingsFontSize + 1;
  Canvas.Font.Style := [];
  Canvas.Font.Color := LTheme.TextColor;
  LCaptionRect := ARect;
  LCaptionRect.Left := ScaleValue(42);
  // Three 42-logical-pixel caption cells remain reserved for VCL.
  LCaptionRect.Right := Max(LCaptionRect.Left + 1,
    ARect.Right - 3 * ScaleValue(42));
  DrawText(Canvas.Handle, PChar(Caption), Length(Caption), LCaptionRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

procedure TFrmSettings.ChromeBorderPaint(Sender: TObject);
const
  cChromeBorderBlend = 0.84;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LBorderColor := BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
    cChromeBorderBlend);
  var LPaintBox := TPaintBox(Sender);
  LPaintBox.Canvas.Brush.Style := bsSolid;
  LPaintBox.Canvas.Brush.Color := LBorderColor;
  LPaintBox.Canvas.FillRect(LPaintBox.ClientRect);
end;

procedure TFrmSettings.ApplyProjectIcon(AImage: TImage; const AKey: string;
  ALogicalSize: Integer; const ATheme: TDevShellTheme);
var
  LSource: TProjectIconSource;
begin
  var LTargetSize := ImagePixelsForDpi(ALogicalSize, CurrentPPI);
  var LBitmap := TBitmap.Create;
  try
    if not TryRenderProjectIconForSurface(LBitmap, AKey, LTargetSize,
      ATheme, False, HInstance, LSource) then
      Exit;
    AImage.AutoSize := False;
    AImage.Stretch := True;
    AImage.Proportional := True;
    AImage.Center := True;
    AImage.Picture.Assign(LBitmap);
  finally
    LBitmap.Free;
  end;
end;

procedure TFrmSettings.ApplyProjectIcons;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LRenderBatchActive := BeginProjectIconRenderBatch;
  try
    ApplyProjectIcon(Image1, 'common', 32, LTheme);
    ApplyProjectIcon(Image2, 'lazarusmenu', 32, LTheme);
    ApplyProjectIcon(Image3, 'delphi', 32, LTheme);
    ApplyProjectIcon(Image5, 'shield', 16, LTheme);
  finally
    if LRenderBatchActive then
      EndProjectIconRenderBatch;
  end;
end;

procedure TFrmSettings.ApplyControlTheme(AControl: TControl;
  const ATheme: TDevShellTheme; AInputColor: TColor);
begin
  if AControl is TCustomCheckBox then
  begin
    // Native Windows checkbox captions ignore Font.Color under visual styles.
    // The registered checkbox hook supplies palette glyphs, backgrounds and text.
    TCustomCheckBox(AControl).StyleName := '';
    TCustomCheckBox(AControl).StyleElements :=
      TCustomCheckBox(AControl).StyleElements - [seFont];
    TControlAccess(AControl).Font.Color := ATheme.TextColor;
  end

  else if (AControl is TCustomEdit) or (AControl is TCustomComboBox) or
     (AControl is TCustomListView) then
  begin
    TControlAccess(AControl).StyleElements :=
      TControlAccess(AControl).StyleElements - [seFont, seClient];
    TControlAccess(AControl).Color := AInputColor;
    TControlAccess(AControl).Font.Color := ATheme.TextColor;
  end
  else if AControl is TPageControl then
  begin
    TControlAccess(AControl).StyleElements :=
      TControlAccess(AControl).StyleElements - [seFont, seClient, seBorder];
    TControlAccess(AControl).Color := ATheme.BackgroundColor;
    TControlAccess(AControl).Font.Color := ATheme.TextColor;
  end
  else if (AControl is TPanel) or (AControl is TTabSheet) or
          (AControl is TControlList) or
          (AControl is TRadioButton) or
          (AControl is TGroupBox) then
  begin
    TControlAccess(AControl).StyleElements :=
      TControlAccess(AControl).StyleElements - [seFont, seClient];
    TControlAccess(AControl).Color := ATheme.BackgroundColor;
    TControlAccess(AControl).Font.Color := ATheme.TextColor;
  end
  else if AControl is TLabel then
  begin
    TLabel(AControl).Transparent := True;
    TLabel(AControl).Font.Color := ATheme.TextColor;
  end;


  if AControl is TWinControl then
    for var LIndex := 0 to TWinControl(AControl).ControlCount - 1 do
      ApplyControlTheme(TWinControl(AControl).Controls[LIndex], ATheme,
        AInputColor);
end;

procedure TFrmSettings.ApplySettingsTheme;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LInputColor := BlendColor(LTheme.BackgroundColor, LTheme.TextColor,
    0.08);
  SetDevShellFont(Self, TDevShellTheme.cFontName, cSettingsFontSize);
  Font.Color := LTheme.TextColor;
  Color := LTheme.BackgroundColor;
  ApplyControlTheme(Self, LTheme, LInputColor);
  if Assigned(FFooterStatusLabel) then
    FFooterStatusLabel.Font.Color := LTheme.MutedColor;
  if Assigned(FFooterIconPaintBox) then
    FFooterIconPaintBox.Invalidate;
  PanelMenu.Color := BlendColor(LTheme.BackgroundColor, LTheme.TextColor,
    0.02);
  EditCommonTaskExt.Color := LTheme.BackgroundColor;
  EditOpenDelphiExt.Color := LTheme.BackgroundColor;
  EditOpenLazarusExt.Color := LTheme.BackgroundColor;
  EditCheckSumExt.Color := LTheme.BackgroundColor;
  for var LGeneralInput in TArray<TControl>.Create(EditCommonTaskExt,
    EditOpenDelphiExt, EditOpenLazarusExt, EditCheckSumExt) do
    SetDevShellFont(LGeneralInput, TDevShellTheme.cFontName,
      cCompactDataFontSize);
  RefreshGeneralExtensionChips;
  ConfigureTitleBar(LTheme);
  SideBar.Color := LTheme.BackgroundColor;
  SideBar.ItemColor := LTheme.BackgroundColor;
  SideBar.Font.Assign(Font);
  SideBar.Invalidate;
  ApplyDevShellThemeToButton(ButtonCancel, LTheme);
  ApplyDevShellThemeToButton(BtnInsertMacro, LTheme);
  var LApplyPalette := DevShellButtonPalette(LTheme);
  // Apply is the footer's primary action: use the filled accent treatment
  // from the reference, with palette-owned hover, pressed and focus states.
  LApplyPalette.Background := LTheme.AccentColor;
  LApplyPalette.HotBackground := BlendColor(LTheme.AccentColor,
    LTheme.TextColor, 0.84);
  LApplyPalette.PressedBackground := BlendColor(LTheme.AccentColor,
    LTheme.BackgroundColor, 0.70);
  LApplyPalette.DisabledBackground := BlendColor(LTheme.AccentColor,
    LTheme.BackgroundColor, 0.45);
  LApplyPalette.Border := LTheme.AccentColor;
  LApplyPalette.HotBorder := LTheme.AccentColor;
  LApplyPalette.PressedBorder := LTheme.AccentColor;
  LApplyPalette.FocusedBorder := LTheme.AccentColor;
  LApplyPalette.Text := LTheme.TextColor;
  LApplyPalette.HotText := LTheme.TextColor;
  LApplyPalette.PressedText := LTheme.TextColor;
  ButtonApply.ApplyPalette(LApplyPalette);
  ButtonApply.Font.Assign(Font);
  ButtonCancel.Font.Assign(Font);
  BtnInsertMacro.Font.Assign(Font);
  if Assigned(FMacroSearch) then
  begin
    FMacroSearch.StyleName := 'Windows';
    FMacroSearch.StyleElements := FMacroSearch.StyleElements -
      [seFont, seClient, seBorder];
    FMacroSearch.Color := LTheme.BackgroundColor;
    FMacroSearch.Font.Color := LTheme.TextColor;
    SetDevShellFont(FMacroSearch, TDevShellTheme.cFontName,
      cCompactDataFontSize);
    FExtensionsPanel.Color := LTheme.BackgroundColor;
    FExtensionsPanel.ParentBackground := False;
    SetDevShellFont(FCustomEnabled, TDevShellTheme.cFontName,
      cCompactDataFontSize);
    SetDevShellFont(FMenuPreview, TDevShellTheme.cFontName,
      cCompactDataFontSize);
    SetDevShellFont(FValidationStatus, TDevShellTheme.cFontName,
      cCompactDataFontSize);
    FMenuPreview.Font.Color := LTheme.TextColor;
    FValidationStatus.Font.Color := LTheme.TextColor;
    var LValidatePalette := DevShellButtonPalette(LTheme);
    LValidatePalette.Background := LTheme.BackgroundColor;
    LValidatePalette.Border := BlendColor(LTheme.TextColor,
      LTheme.BackgroundColor, cGeneralInputBorderBlend);
    LValidatePalette.HotBorder := LTheme.AccentColor;
    LValidatePalette.FocusedBorder := LTheme.AccentColor;
    FValidateButton.ApplyPalette(LValidatePalette);
    TControlAccess(FValidateButton).Color := LTheme.BackgroundColor;
    FValidateButton.Font.Assign(Font);
    FValidateButton.Font.Size := cCompactDataFontSize;
    RefreshExtensionChips;
  end;
  RebuildCustomToolButtonImages(LTheme);
  var LNewToolPalette := DevShellButtonPalette(LTheme);
  LNewToolPalette.Background := LTheme.BackgroundColor;
  LNewToolPalette.Border := LTheme.BackgroundColor;
  LNewToolPalette.Text := LTheme.SecondaryColor;
  LNewToolPalette.HotText := LTheme.SecondaryColor;
  LNewToolPalette.HotBorder := LTheme.SecondaryColor;
  LNewToolPalette.FocusedBorder := LTheme.SecondaryColor;
  ButtonNewTool.ApplyPalette(LNewToolPalette);
  TControlAccess(ButtonNewTool).Color := LTheme.BackgroundColor;
  ButtonNewTool.Font.Assign(Font);
  var LDeleteToolPalette := DevShellButtonPalette(LTheme);
  LDeleteToolPalette.Background := LTheme.BackgroundColor;
  LDeleteToolPalette.Border := LTheme.BackgroundColor;
  LDeleteToolPalette.Text := LTheme.DangerColor;
  LDeleteToolPalette.HotText := LTheme.DangerColor;
  LDeleteToolPalette.HotBorder := LTheme.DangerColor;
  LDeleteToolPalette.FocusedBorder := LTheme.DangerColor;
  ButtonDeleteTool.ApplyPalette(LDeleteToolPalette);
  TControlAccess(ButtonDeleteTool).Color := LTheme.BackgroundColor;
  ButtonDeleteTool.Font.Assign(Font);
  DBGrid1.Color := LTheme.BackgroundColor;
  DBGrid1.ItemColor := LTheme.BackgroundColor;
  DBGrid1.ItemSelectionOptions.SelectedColor := LTheme.BackgroundColor;
  DBGrid1.ItemSelectionOptions.FocusedColor := LTheme.BackgroundColor;
  // Match the TDump Explorer borderless edit setup after assigning StyleName:
  // StyleName can otherwise restore a native bevel or single-line border.
  DBEditMenu.StyleName := 'Windows';
  DBEditName.StyleName := 'Windows';
  DBEditExtensions.StyleName := 'Windows';
  DBEditMenu.AutoSize := False;
  DBEditName.AutoSize := False;
  DBEditExtensions.AutoSize := False;
  DBEditMenu.BevelInner := bvNone;
  DBEditName.BevelInner := bvNone;
  DBEditExtensions.BevelInner := bvNone;
  DBEditMenu.BevelOuter := bvNone;
  DBEditName.BevelOuter := bvNone;
  DBEditExtensions.BevelOuter := bvNone;
  DBEditMenu.BorderStyle := bsNone;
  DBEditName.BorderStyle := bsNone;
  DBEditExtensions.BorderStyle := bsNone;
  DBMemoScript.BorderStyle := bsNone;
  // Command lines remain intact; horizontal scrolling exposes long paths
  // instead of creating artificial wrapped lines in the compact viewport.
  DBMemoScript.WordWrap := False;
  DBMemoScript.ScrollBars := ssBoth;
  DBEditMenu.Color := LTheme.BackgroundColor;
  DBEditName.Color := LTheme.BackgroundColor;
  DBEditExtensions.Color := LTheme.BackgroundColor;
  DBMemoScript.Color := LTheme.BackgroundColor;
  DBComboBoxGroup.Color := LTheme.BackgroundColor;
  DBLookupComboBoxDelphi.Color := LTheme.BackgroundColor;
  DBComboBoxImage.Color := LTheme.BackgroundColor;
  ListViewMacros.Color := LTheme.BackgroundColor;
  for var LCompactControl in TArray<TControl>.Create(DBGrid1, ButtonNewTool,
    ButtonDeleteTool, Label7, DBComboBoxGroup, LabelDelphi,
    DBLookupComboBoxDelphi, Label8, DBEditName, Label9, DBEditMenu,
    Label14, DBComboBoxImage, Label11, DBEditExtensions, Label10,
    DBMemoScript, DBCheckBoxRunAs, ListViewMacros, BtnInsertMacro) do
    SetDevShellFont(LCompactControl, TDevShellTheme.cFontName,
      cCompactDataFontSize);
  DBGrid1.ItemHeight := MulDiv(cCustomListRowHeight, CurrentPPI, cDesignPPI);
  DBMemoScript.Font.Name := 'Consolas';
  DBMemoScript.Font.Size := cCompactDataFontSize;
  SetDevShellFont(LabelDelphi, TDevShellTheme.cFontName,
    cDenseDataFontSize);
  LabelViewTitle.Font.Color := LTheme.TextColor;
  LabelViewDescription.Font.Color := LTheme.TextColor;
  if Assigned(FAboutPaintBox) then
  begin
    FAboutProduct.Font.Color := LTheme.TextColor;
    FAboutVersion.Font.Color := LTheme.TextColor;
    FAboutBuild.Font.Color := LTheme.TextColor;
    FAboutArchitecture.Font.Color := LTheme.TextColor;
    FAboutAuthor.Font.Color := LTheme.TextColor;
    for var LLabel in TArray<TLabel>.Create(FAboutDescription,
      FAboutVersionTitle, FAboutBuildTitle, FAboutArchitectureTitle,
      FAboutAuthorTitle, FAboutRepositoryTitle, FAboutLicenseTitle,
      FAboutPhosphorTitle, FAboutOpenSSLTitle) do
      LLabel.Font.Color := LTheme.MutedColor;
    FAboutLicenseBadge.ApplyTheme(LTheme);
    var LRepositoryPalette := DevShellButtonPalette(LTheme);
    LRepositoryPalette.Background := LTheme.BackgroundColor;
    LRepositoryPalette.Border := LTheme.BackgroundColor;
    LRepositoryPalette.Text := LTheme.AccentColor;
    LRepositoryPalette.HotText := LTheme.AccentColor;
    LRepositoryPalette.PressedText := LTheme.AccentColor;
    FAboutRepositoryButton.ApplyPalette(LRepositoryPalette);
    FAboutPhosphorButton.ApplyPalette(LRepositoryPalette);
    FAboutOpenSSLButton.ApplyPalette(LRepositoryPalette);
    for var LAboutLink in TArray<TControl>.Create(FAboutRepositoryButton,
      FAboutPhosphorButton, FAboutOpenSSLButton) do
      SetDevShellFont(LAboutLink, TDevShellTheme.cFontName,
        cCompactDataFontSize);
    var LTextMetrics := TBitmap.Create;
    try
      LTextMetrics.Canvas.Font.Assign(FAboutRepositoryButton.Font);
      FAboutRepositoryButton.SetBounds(MulDiv(cAboutValueLeft, CurrentPPI,
        cDesignPPI), MulDiv(243, CurrentPPI, cDesignPPI),
        LTextMetrics.Canvas.TextWidth(FAboutRepositoryButton.Caption) +
          MulDiv(16, CurrentPPI, cDesignPPI),
        MulDiv(28, CurrentPPI, cDesignPPI));
      LTextMetrics.Canvas.Font.Assign(FAboutPhosphorButton.Font);
      FAboutPhosphorButton.SetBounds(MulDiv(cAboutValueLeft, CurrentPPI,
        cDesignPPI), MulDiv(323, CurrentPPI, cDesignPPI),
        LTextMetrics.Canvas.TextWidth(FAboutPhosphorButton.Caption) +
          MulDiv(16, CurrentPPI, cDesignPPI),
        MulDiv(28, CurrentPPI, cDesignPPI));
      LTextMetrics.Canvas.Font.Assign(FAboutOpenSSLButton.Font);
      FAboutOpenSSLButton.SetBounds(MulDiv(cAboutValueLeft, CurrentPPI,
        cDesignPPI), MulDiv(359, CurrentPPI, cDesignPPI),
        LTextMetrics.Canvas.TextWidth(FAboutOpenSSLButton.Caption) +
          MulDiv(16, CurrentPPI, cDesignPPI),
        MulDiv(28, CurrentPPI, cDesignPPI));
    finally
      LTextMetrics.Free;
    end;
    LRepositoryPalette.HotBorder := LTheme.BackgroundColor;
    LRepositoryPalette.PressedBorder := LTheme.BackgroundColor;
    LRepositoryPalette.FocusedBorder := LTheme.BackgroundColor;
    FAboutRepositoryButton.ApplyPalette(LRepositoryPalette);
    FAboutPhosphorButton.ApplyPalette(LRepositoryPalette);
    FAboutOpenSSLButton.ApplyPalette(LRepositoryPalette);
    FAboutPaintBox.Invalidate;
  end;
  PaintBoxSideBarBorder.Invalidate;
  PaintBoxSideBarFooterBorder.Invalidate;
  PaintBoxFooterBorder.Invalidate;
  PaintBoxGeneral.Invalidate;
  PaintBoxMenu.Invalidate;
  PaintBoxCustomTools.Invalidate;
  DBGrid1.Invalidate;
end;

procedure TFrmSettings.ConfigureFooter;
const
  cFooterButtonWidth = 95;
  cFooterButtonHeight = 32;
  cFooterButtonGap = 12;
  cFooterRightMargin = 13;
begin
  var LButtonWidth := ScaleValue(cFooterButtonWidth);
  var LButtonHeight := ScaleValue(cFooterButtonHeight);
  var LButtonGap := ScaleValue(cFooterButtonGap);
  var LRight := Panel2.ClientWidth -
    ScaleValue(cFooterRightMargin);
  ButtonCancel.SetBounds(LRight - LButtonWidth,
    (Panel2.ClientHeight - LButtonHeight) div 2, LButtonWidth,
    LButtonHeight);
  ButtonApply.SetBounds(ButtonCancel.Left - LButtonGap - LButtonWidth,
    ButtonCancel.Top, LButtonWidth, LButtonHeight);
  if Assigned(FFooterIconPaintBox) then
    FFooterIconPaintBox.SetBounds(ScaleValue(14), 0, ScaleValue(32),
      Panel2.ClientHeight);
  if Assigned(FFooterStatusLabel) then
    FFooterStatusLabel.SetBounds(ScaleValue(54), 0,
      Max(1, ButtonApply.Left - ScaleValue(66)),
      Panel2.ClientHeight);
end;

procedure TFrmSettings.CreateFooterStatus;
begin
  FFooterIconPaintBox := TPaintBox.Create(Self);
  FFooterIconPaintBox.Parent := Panel2;
  FFooterIconPaintBox.Align := alNone;
  FFooterIconPaintBox.OnPaint := FooterIconPaint;

  FFooterStatusLabel := TLabel.Create(Self);
  FFooterStatusLabel.Parent := Panel2;
  FFooterStatusLabel.AutoSize := False;
  FFooterStatusLabel.Alignment := taLeftJustify;
  FFooterStatusLabel.Layout := tlCenter;
  FFooterStatusLabel.ShowAccelChar := False;
  FFooterStatusLabel.Transparent := True;
  FFooterStatusLabel.Font.Assign(Font);
  FFooterStatusLabel.Font.Size := cSettingsFontSize;
  FFooterStatusLabel.Font.Color := TDevShellTheme.ActiveTheme.MutedColor;
end;

procedure TFrmSettings.FooterIconPaint(Sender: TObject);
begin
  var LPaintBox := TPaintBox(Sender);
  var LPhosphorFont: TPhosphorFont;
  if not TryGetPhosphorFont(LPhosphorFont) then
    Exit;
  var LIconSize := MulDiv(20, CurrentPPI, cDesignPPI);
  var LIconRect := Rect((LPaintBox.ClientWidth - LIconSize) div 2,
    (LPaintBox.ClientHeight - LIconSize) div 2,
    (LPaintBox.ClientWidth + LIconSize) div 2,
    (LPaintBox.ClientHeight + LIconSize) div 2);
  var LTheme := TDevShellTheme.ActiveTheme;
  LPhosphorFont.DrawDuotoneIcon(LPaintBox.Canvas.Handle, cPhGear, LIconRect,
    LTheme.MutedColor, LTheme.PrimaryColor, 76, False);
end;

procedure TFrmSettings.ConfigureSideBar;
const
  cSideBarItemCount = 4;
  cSideBarItemHeight = 62;
begin
  SideBar.ItemCount := cSideBarItemCount;
  SideBar.ItemHeight := MulDiv(cSideBarItemHeight, CurrentPPI, 96);
  SideBar.ItemWidth := 0;
  SideBar.ColumnLayout := cltSingle;
  SideBar.MultiSelect := False;
end;

procedure TFrmSettings.ChangeScale(AM, AD: Integer; AIsDpiChange: Boolean);
begin
  inherited ChangeScale(AM, AD, AIsDpiChange);
  // Vcl.Forms sends ChangeScale before it commits CurrentPPI and completes
  // its child-control scaling. Reflow after that transaction finishes.
  if not (csLoading in ComponentState) and HandleAllocated then
    PostMessage(Handle, WM_APP + $412, 0, 0);
end;

procedure TFrmSettings.WMSettingsRelayout(var AMessage: TMessage);
begin
  RefreshDpiLayout;
end;

procedure TFrmSettings.RefreshDpiLayout;
begin
  if csLoading in ComponentState then
    Exit;
  ApplySettingsLayout;
  ConfigureFooter;
  ConfigureSideBar;
  ConfigureGeneralPage;
  ConfigureMenuPage;
  ConfigureCustomToolsPage;
  ConfigureAboutPage;
  ApplySettingsTheme;
  ApplyProjectIcons;
  UpdateViewHeader(FActiveSideBarIndex);
  // Child scaling and page refresh can recreate their z-order at a DPI
  // transition. Reassert the shell footer last so it remains the single
  // cross-view footer and the sidebar-local footer cannot surface over it.
  PanelSideBarFooter.Visible := False;
  Panel2.BringToFront;
end;

procedure TFrmSettings.SideBarAfterDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
const
  cSideBarIconSize = 24;
  cSideBarHorizontalPadding = 14;
  cSideBarIconTextGap = 16;
  cSideBarCornerRadius = 6;
  cSideBarAccentWidth = 3;
  cSideBarHotFillBlend = 0.96;
  cSideBarHotBorderBlend = 0.86;
  cSideBarCaptions: array[cSideBarGeneral..cSideBarAbout] of string = (
    'General', 'Menu', 'Custom tools', 'About');
  cSideBarDescriptions: array[cSideBarGeneral..cSideBarAbout] of string = (
    'File extensions and integration', 'Explorer context menu',
    'Create and edit tools', 'Version and information');
  cSideBarIconCodes: array[cSideBarGeneral..cSideBarAbout] of Word = (
    cPhSlidersHorizontal, cPhListChecks, cPhToolbox, cPhInfo);
var
  LPhosphorFont: TPhosphorFont;
begin
  if (AIndex < cSideBarGeneral) or (AIndex > cSideBarAbout) then
    Exit;

  var LTheme := TDevShellTheme.ActiveTheme;
  var LAccentColor := SideBarAccentColor(AIndex, LTheme);
  var LSelectionColor := LTheme.AccentColor;
  var LFillColor := LTheme.BackgroundColor;
  var LBorderColor := LTheme.BackgroundColor;
  var LTextColor := LTheme.TextColor;
  if odSelected in AState then
  begin
    LFillColor := BlendColor(LTheme.AccentColor, LTheme.BackgroundColor,
      0.76);
    LBorderColor := BlendColor(LTheme.AccentColor, LTheme.BackgroundColor,
      0.48);
  end
  else if odHotLight in AState then
  begin
    LFillColor := BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
      cSideBarHotFillBlend);
    LBorderColor := BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
      cSideBarHotBorderBlend);
  end;

  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := LTheme.BackgroundColor;
  ACanvas.FillRect(ARect);
  // One asymmetric navigation rectangle is shared by every row state.
  var LItemRect := ARect;
  LItemRect.Left := LItemRect.Left + ScaleValue(8);
  // Together with the control-list frame, this yields the measured 7-logical
  // trailing inset while preserving the 204-logical-pixel sidebar envelope.
  LItemRect.Right := LItemRect.Right - ScaleValue(4);
  LItemRect.Top := LItemRect.Top + ScaleValue(2);
  LItemRect.Bottom := LItemRect.Bottom - ScaleValue(2);
  if (odSelected in AState) or (odHotLight in AState) or
     (odFocused in AState) then
    DrawAntialiasedRoundedRectangle(ACanvas, LItemRect, LFillColor,
      LBorderColor, MulDiv(cSideBarCornerRadius, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));

  if odSelected in AState then
  begin
    var LAccentRect := Rect(LItemRect.Left,
      LItemRect.Top + MulDiv(12, CurrentPPI, 96),
      LItemRect.Left + MulDiv(cSideBarAccentWidth, CurrentPPI, 96),
      LItemRect.Bottom - MulDiv(12, CurrentPPI, 96));
    DrawAntialiasedRoundedRectangle(ACanvas, LAccentRect, LSelectionColor,
      LSelectionColor, MulDiv(2, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  var LIconSize := MulDiv(cSideBarIconSize, CurrentPPI, 96);
  var LIconLeft := LItemRect.Left +
    MulDiv(cSideBarHorizontalPadding, CurrentPPI, 96);
  var LIconTop := LItemRect.Top + (LItemRect.Height - LIconSize) div 2;
  var LIconRect := Rect(LIconLeft, LIconTop, LIconLeft + LIconSize,
    LIconTop + LIconSize);
  if TryGetPhosphorFont(LPhosphorFont) then
    LPhosphorFont.DrawDuotoneIcon(ACanvas.Handle, cSideBarIconCodes[AIndex],
      LIconRect, LAccentColor, LAccentColor, 76, False);

  ACanvas.Font.Assign(SideBar.Font);
  ACanvas.Font.Style := [fsBold];
  ACanvas.Font.Color := LTextColor;
  ACanvas.Brush.Style := bsClear;
  var LTitleRect := LItemRect;
  LTitleRect.Left := LIconRect.Right +
    MulDiv(cSideBarIconTextGap, CurrentPPI, 96);
  LTitleRect.Top := LItemRect.Top + MulDiv(9, CurrentPPI, 96);
  LTitleRect.Bottom := LTitleRect.Top + MulDiv(18, CurrentPPI, 96);
  DrawText(ACanvas.Handle, PChar(cSideBarCaptions[AIndex]),
    Length(cSideBarCaptions[AIndex]), LTitleRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
    DT_NOPREFIX);
  // The fixed-width navigation is deliberately compact.  One point less on
  // the secondary line gives wrapped subtitles two complete text lines.
  ACanvas.Font.Size := Max(7, cCompactDataFontSize - 1);
  ACanvas.Font.Style := [];
  ACanvas.Font.Color := LTheme.MutedColor;
  var LDescriptionRect := LTitleRect;
  LDescriptionRect.Top := LTitleRect.Bottom + MulDiv(1, CurrentPPI, 96);
  LDescriptionRect.Bottom := LItemRect.Bottom - MulDiv(6, CurrentPPI, 96);
  DrawText(ACanvas.Handle, PChar(cSideBarDescriptions[AIndex]),
    Length(cSideBarDescriptions[AIndex]), LDescriptionRect,
    DT_LEFT or DT_WORDBREAK or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

procedure TFrmSettings.SideBarChange(Sender: TObject);
begin
  if FUpdatingSideBar then
    Exit;

  case SideBar.ItemIndex of
    cSideBarGeneral: PageControl1.ActivePage := TabSheet2;
    cSideBarMenu: PageControl1.ActivePage := TabSheet1;
    cSideBarCustomTools: PageControl1.ActivePage := TabSheet3;
    cSideBarAbout: PageControl1.ActivePage := FAboutPage;
  else
    Exit;
  end;
  FActiveSideBarIndex := SideBar.ItemIndex;
  UpdateViewHeader(FActiveSideBarIndex);
  SideBar.Invalidate;
  // Commit both paint owners together: the VCL title-bar panel has its own
  // buffered child surface and needs an explicit refresh after page switches.
  RefreshTitleBarChrome;
  RedrawWindow(Handle, nil, 0,
    RDW_INVALIDATE or RDW_ERASE or RDW_FRAME or RDW_ALLCHILDREN or RDW_UPDATENOW);
end;

procedure TFrmSettings.UpdateViewHeader(AIndex: Integer);
const
  cViewHeaderLeft = 20;
  cViewHeaderTitleTop = 6;
  cViewHeaderDescriptionTop = 29;
  cCustomViewHeaderLeft = 20;
  cCustomViewHeaderTitleTop = 6;
  cCustomViewHeaderDescriptionTop = 29;
  cViewTitles: array[cSideBarGeneral..cSideBarAbout] of string = (
    'General', 'Menu', 'Custom tools', 'About');
  cViewDescriptions: array[cSideBarGeneral..cSideBarAbout] of string = (
    'Configure the file extensions used by each shell feature.',
    'Choose how commands are grouped in the Explorer context menu.',
    'Create and edit Explorer context-menu tools.',
    'Application information, project links and third-party credits.');
var
  LHeaderLeft: Integer;
  LTitleTop: Integer;
  LDescriptionTop: Integer;
begin
  if (AIndex < cSideBarGeneral) or (AIndex > cSideBarAbout) then
    Exit;

  LHeaderLeft := cViewHeaderLeft;
  LTitleTop := cViewHeaderTitleTop;
  LDescriptionTop := cViewHeaderDescriptionTop;
  if AIndex = cSideBarCustomTools then
  begin
    LHeaderLeft := cCustomViewHeaderLeft;
    LTitleTop := cCustomViewHeaderTitleTop;
    LDescriptionTop := cCustomViewHeaderDescriptionTop;
  end;

  LabelViewTitle.SetBounds(MulDiv(LHeaderLeft, CurrentPPI, cDesignPPI),
    MulDiv(LTitleTop, CurrentPPI, cDesignPPI), LabelViewTitle.Width,
    LabelViewTitle.Height);
  LabelViewDescription.SetBounds(MulDiv(LHeaderLeft, CurrentPPI, cDesignPPI),
    MulDiv(LDescriptionTop, CurrentPPI, cDesignPPI),
    LabelViewDescription.Width, LabelViewDescription.Height);
  LabelViewTitle.Caption := cViewTitles[AIndex];
  LabelViewDescription.Caption := cViewDescriptions[AIndex];
  if Assigned(FFooterStatusLabel) then
  begin
    if AIndex = cSideBarGeneral then
      FFooterStatusLabel.Caption := 'Delphi Dev. Shell Tools   |   ' +
        'Configure file extensions and integrations for the Windows Explorer context menu.'
    else
      FFooterStatusLabel.Caption := 'Delphi Dev. Shell Tools   |   ' +
        cViewDescriptions[AIndex];
  end;
end;
procedure TFrmSettings.BtnInsertMacroClick(Sender: TObject);
begin
  if ListViewMacros.Selected <> nil then
  begin
    DBMemoScript.SelText := ListViewMacros.Selected.Caption;
    CustomToolControlChanged(DBMemoScript);
  end;
end;

procedure TFrmSettings.ApplyChangesToSnapshot;
begin
  SaveSelectedTool;

  FSettings.SubMenuOpenCmdRAD := CheckBoxSubMenuOpenCmdRAD.Checked;
  FSettings.SubMenuLazarus  := CheckBoxSubMenuLazarus.Checked;
  FSettings.ShowInfoDProj   := CheckBoxShowInfoDProj.Checked;
  FSettings.ActivateLazarus   := CheckBoxActivateLazarus.Checked;
  FSettings.SubMenuCommonTasks   := CheckBoxSubMenuCommonTasks.Checked;
  FSettings.SubMenuMSBuild     := CheckBoxSubMenuMSBuild.Checked;
  FSettings.SubMenuMSBuildAnother:= CheckBoxSubMenuMSBuildAnother.Checked;
  FSettings.SubMenuOpenDelphi     := CheckBoxSubMenuOpenDelphi.Checked;
  FSettings.SubMenuRunTouch     := CheckBoxSubMenuRunTouch.Checked;
  FSettings.SubMenuFormat       := CheckBoxSubMenuFormat.Checked;
  FSettings.SubMenuCompileRC    := CheckBoxSubMenuCompileRC.Checked;
  FSettings.SubMenuOpenVclStyle    := CheckBoxSubMenuVCLStyles.Checked;
  FSettings.SubMenuOpenFMXStyle    := CheckBoxSubMenuFMXStyles.Checked;
  FSettings.CommonTaskExt        := EditCommonTaskExt.Text;
  FSettings.OpenDelphiExt        := EditOpenDelphiExt.Text;
  FSettings.OpenLazarusExt       := EditOpenLazarusExt.Text;
  FSettings.CheckSumExt        := EditCheckSumExt.Text;
  FToolsModel.Save(FSettings.Document);
  UpdateSettingsDocument(FSettings);
end;

procedure TFrmSettings.ButtonApplyClick(Sender: TObject);
begin
  if MessageDlg('Do you want save the changes ?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    ApplyChangesToSnapshot;
    if not FSnapshotOnly then
      WriteSettings(FSettings);
    Close;
  end;
end;
procedure TFrmSettings.ButtonCancelClick(Sender: TObject);
begin
 Close();
end;

procedure TFrmSettings.ClientDataSet1AfterScroll(DataSet: TDataSet);
begin
  if Assigned(FToolsModel) and not FLoadingCustomTool then
    LoadSelectedTool;
end;

procedure TFrmSettings.DBComboBoxImageDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  LSource: TProjectIconSource;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LComboBox := TComboBox(Control);
  var LCanvas := LComboBox.Canvas;
  LCanvas.Brush.Style := bsSolid;
  if odComboBoxEdit in State then
    LCanvas.Brush.Color := LTheme.BackgroundColor
  else if odSelected in State then
    LCanvas.Brush.Color := BlendColor(LTheme.AccentColor,
      LTheme.BackgroundColor, 0.82)
  else
    LCanvas.Brush.Color := LTheme.BackgroundColor;
  LCanvas.FillRect(Rect);
  LCanvas.Font.Name := TDevShellTheme.cFontName;
  LCanvas.Font.Size := cCompactDataFontSize;
  LCanvas.Font.Color := LTheme.TextColor;

  if (Index < 0) or (Index >= LComboBox.Items.Count) then
    Exit;
  var LKey := LComboBox.Items[Index];
  var LTargetSize := ImagePixelsForDpi(MenuImageLogicalSize, CurrentPPI);
  var LImageRect := System.Types.Rect(Rect.Left +
    MulDiv(cCustomInputPaddingX, CurrentPPI, cDesignPPI),
    Rect.Top + (Rect.Height - LTargetSize) div 2,
    Rect.Left + MulDiv(cCustomInputPaddingX, CurrentPPI, cDesignPPI) +
      LTargetSize,
    Rect.Top + (Rect.Height - LTargetSize) div 2 + LTargetSize);
  TryDrawProjectIcon(LCanvas.Handle, LKey, LImageRect, LTheme, False,
    HInstance, LSource);
  if odComboBoxEdit in State then
    Exit;
  var LTextRect := Rect;
  LTextRect.Left := LImageRect.Right + MulDiv(6, CurrentPPI, cDesignPPI);
  var LCaption := ProjectIconDisplayName(LKey);
  DrawText(LCanvas.Handle, PChar(LCaption), Length(LCaption),
    LTextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
end;

procedure TFrmSettings.DBComboBoxGroupDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
const
  cCustomComboTextRightPadding = 1;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LComboBox := TComboBox(Control);
  var LCanvas := LComboBox.Canvas;
  LCanvas.Brush.Style := bsSolid;
  if odComboBoxEdit in State then
    LCanvas.Brush.Color := LTheme.BackgroundColor
  else if odSelected in State then
    LCanvas.Brush.Color := BlendColor(LTheme.AccentColor,
      LTheme.BackgroundColor, 0.82)
  else
    LCanvas.Brush.Color := LTheme.BackgroundColor;
  LCanvas.FillRect(Rect);
  LCanvas.Font.Name := TDevShellTheme.cFontName;
  LCanvas.Font.Size := cCompactDataFontSize;
  LCanvas.Font.Color := LTheme.TextColor;

  if (Index < 0) or (Index >= LComboBox.Items.Count) then
    Exit;
  var LTextRect := Rect;
  LTextRect.Left := LTextRect.Left +
    MulDiv(cCustomInputPaddingX, CurrentPPI, cDesignPPI);
  LTextRect.Right := LTextRect.Right -
    MulDiv(cCustomComboTextRightPadding, CurrentPPI, cDesignPPI);
  var LCaption := LComboBox.Items[Index];
  DrawText(LCanvas.Handle, PChar(LCaption), Length(LCaption), LTextRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

procedure TFrmSettings.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 // Only Apply writes the settings snapshot; Cancel and closing discard edits.
end;

constructor TFrmSettings.CreateForDocument(AOwner: TComponent;
  ADocument: TJSONObject; const AMacroDirectory: string);
begin
  if not Assigned(ADocument) then
    raise EArgumentNilException.Create('ADocument');
  FSnapshotOnly := True;
  FSourceDocument := ADocument;
  FMacroDirectory := AMacroDirectory;
  inherited Create(AOwner);
end;

procedure TFrmSettings.FormCreate(Sender: TObject);
begin
  Log('Settings FormCreate begin');
  TitleBarPanel1.OnPaint := TitleBarPanelPaint;
  FActiveSideBarIndex := cSideBarGeneral;
  FCustomToolButtonImages := TImageList.Create(Self);
  FMacroRowImages := TImageList.Create(Self);
  FVersionIds := TStringList.Create;
  CreateGeneralExtensionPanels;
  CreateCustomToolsControls;
  CreateFooterStatus;
  SideBar.OnAfterDrawItem := SideBarAfterDrawItem;
  SideBar.OnChange := SideBarChange;
  DBGrid1.OnAfterDrawItem := ToolListAfterDrawItem;
  DBGrid1.OnChange := ToolListChange;
  Log('Settings FormCreate configure controls');
  // The standalone Settings host normally creates the form at the monitor's
  // current PPI and does not call ScaleForPPI.  Seed the sole layout owner
  // before any page-local bounds are derived; otherwise the Menu paint cards
  // use the zero-valued record and only their child glyphs remain visible.
  ApplySettingsLayout;
  ConfigureFooter;
  ConfigureSideBar;
  ConfigureGeneralPage;
  ConfigureMenuPage;
  ConfigureCustomToolsPage;
  ConfigureAboutPage;
  PanelViewHeader.BringToFront;
  Log('Settings FormCreate apply theme');
  ApplySettingsTheme;
  Log('Settings FormCreate activate page');
  FUpdatingSideBar := True;
  try
    SideBar.ItemIndex := cSideBarGeneral;
    PageControl1.ActivePage := TabSheet2;
  finally
    FUpdatingSideBar := False;
  end;
  UpdateViewHeader(cSideBarGeneral);
  Log('Settings FormCreate configure data controls');
  ApplyProjectIcons;

  FSettings := TSettings.Create;
  Log('Settings FormCreate load settings');
  if Assigned(FSourceDocument) then
    Log('Settings FormCreate snapshot common=' +
      FSourceDocument.GetValue<TJSONObject>('settings').GetValue<string>(
        'CommonTaskExt', ''))
  else
    Log('Settings FormCreate no snapshot document');
  LoadSettings;
  // ReadSettings clones the document; the capture/test caller retains the
  // original JSON and can free it after form teardown.
  FSourceDocument := nil;
  FToolsModel := TSettingsToolsModel.Create(ClientDataSet1,
    ClientDataSet2, FSettings.Document);
  var LReviewLabel := TLabel.Create(Self);
  LReviewLabel.Parent := PanelCustomTools;
  LReviewLabel.Align := alTop;
  LReviewLabel.WordWrap := True;
  LReviewLabel.Caption := 'Commands with an assignment review are disabled. ' +
    'Select their minimum Delphi version, then Apply.';
  LReviewLabel.Visible := FToolsModel.HasReviews;
  FToolsModel.FillIconItems(DBComboBoxImage.Items);
  LoadMacros;
  FToolsModel.FillVersionItems(DBLookupComboBoxDelphi.Items, FVersionIds);
  RefreshToolList;
  LoadSelectedTool;
  ConfigureCustomToolsPage;
  ActiveControl := nil;
  Log('Settings FormCreate end');
end;

procedure TFrmSettings.FormDestroy(Sender: TObject);
begin
  FToolsModel.Free;
  FVersionIds.Free;
  FMacroDescriptions.Free;
  FMacroNames.Free;
  FSettings.Free;
end;

procedure TFrmSettings.LoadMacros;
begin
  FToolsModel.LoadMacroDefinitions(FMacroNames, FMacroDescriptions, FMacroDirectory);
  MacroSearchChange(FMacroSearch);
end;
procedure TFrmSettings.LoadSettings;
begin
  if FSnapshotOnly and not Assigned(FSourceDocument) then
    ReadSettings(FSettings, FSettings.Document)
  else
    ReadSettings(FSettings, FSourceDocument);
  CheckBoxSubMenuOpenCmdRAD.Checked:= FSettings.SubMenuOpenCmdRAD;
  CheckBoxSubMenuLazarus.Checked   := FSettings.SubMenuLazarus;
  CheckBoxSubMenuCommonTasks.Checked   := FSettings.SubMenuCommonTasks;
  CheckBoxShowInfoDProj.Checked    := FSettings.ShowInfoDProj;
  CheckBoxActivateLazarus.Checked  := FSettings.ActivateLazarus;
  CheckBoxSubMenuMSBuild.Checked  := FSettings.SubMenuMSBuild;
  CheckBoxSubMenuMSBuildAnother.Checked  := FSettings.SubMenuMSBuildAnother;
  CheckBoxSubMenuRunTouch.Checked  := FSettings.SubMenuRunTouch;
  CheckBoxSubMenuOpenDelphi.Checked  := FSettings.SubMenuOpenDelphi;
  CheckBoxSubMenuFormat.Checked  := FSettings.SubMenuFormat;
  CheckBoxSubMenuCompileRC.Checked:= FSettings.SubMenuCompileRC;
  CheckBoxSubMenuVCLStyles.Checked:= FSettings.SubMenuOpenVclStyle;
  CheckBoxSubMenuFMXStyles.Checked:= FSettings.SubMenuOpenFMXStyle;
  EditCommonTaskExt.Text          := FSettings.CommonTaskExt;
  EditOpenDelphiExt.Text          := FSettings.OpenDelphiExt;
  EditOpenLazarusExt.Text         := FSettings.OpenLazarusExt;
  EditCheckSumExt.Text            := FSettings.CheckSumExt;
  RefreshGeneralExtensionChips;
end;


end.
