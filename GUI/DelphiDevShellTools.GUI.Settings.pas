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
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, DelphiDevShellTools.Misc,
  DelphiDevShellTools.UI,
  Vcl.Imaging.pngimage, Vcl.ComCtrls, Vcl.DBCtrls, Vcl.Mask, Data.DB,
  Datasnap.DBClient, Vcl.Grids, Vcl.DBGrids, Vcl.ControlList, Vcl.Buttons,
  Vcl.TitleBarCtrls, Vcl.ImgList;

type
  TFlatPageControl = class(TPageControl)
  protected
    procedure AdjustClientRect(var ARect: TRect); override;
    procedure CreateParams(var Params: TCreateParams); override;
  end;

  TFlatDBGrid = class(TDBGrid)
  protected
    procedure UpdateScrollBar; override;
  end;

  TDevShellLookupComboBox = class(TDBLookupComboBox)
  public
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
  end;

  TDevShellDBComboBox = class(TDBComboBox)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  public
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); override;
  end;

  TDevShellLookupComboBoxStyleHook = class(TEditStyleHook)
  protected
    procedure PaintNC(ACanvas: TCanvas); override;
  end;

  TCustomControlBoundsAccess = class(TCustomControl)
  public
    procedure SetBounds(ALeft, ATop, AWidth, AHeight: Integer); reintroduce;
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
    PageControl1: TFlatPageControl;
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
    DBNavigator1: TDBNavigator;
    Label7: TLabel;
    DBEditMenu: TDBEdit;
    DBEditName: TDBEdit;
    Label8: TLabel;
    Label9: TLabel;
    DBMemoScript: TDBMemo;
    Label10: TLabel;
    DBEditExtensions: TDBEdit;
    Label11: TLabel;
    ListViewMacros: TListView;
    Label12: TLabel;
    BtnInsertMacro: TSimpleUIButton;
    DBComboBoxGroup: TDBComboBox;
    LabelDelphi: TLabel;
    DBLookupComboBoxDelphi: TDBLookupComboBox;
    ClientDataSet2: TClientDataSet;
    DataSource2: TDataSource;
    DBGrid1: TFlatDBGrid;
    DBComboBoxImage: TDBComboBox;
    Label14: TLabel;
    DBCheckBoxRunAs: TDBCheckBox;
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
    procedure DBGridToolsDrawColumnCell(Sender: TObject; const Rect: TRect;
      DataCol: Integer; Column: TColumn; State: TGridDrawState);
    procedure ListViewMacrosDrawItem(Sender: TCustomListView;
      Item: TListItem; Rect: TRect; State: TOwnerDrawState);
    procedure ButtonNewToolClick(Sender: TObject);
    procedure ButtonDeleteToolClick(Sender: TObject);
    procedure ChromeBorderPaint(Sender: TObject);
  private
    FSettings: TSettings;
    FActiveSideBarIndex: Integer;
    FUpdatingSideBar: Boolean;
    FCustomToolButtonImages: TImageList;
    FMacroRowImages: TImageList;
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
    procedure ApplyProjectIcons;
    procedure ApplyProjectIcon(AImage: TImage; const AKey: string;
      ALogicalSize: Integer; const ATheme: TDevShellTheme);
    procedure ApplyControlTheme(AControl: TControl;
      const ATheme: TDevShellTheme; AInputColor: TColor);
    procedure ApplySettingsTheme;
    procedure ConfigureFooter;
    procedure ConfigureSideBar;
    procedure ConfigureGeneralPage;
    procedure ConfigureMenuPage;
    procedure ConfigureCustomToolsPage;
    procedure ConfigureAboutPage;
    procedure MigrateCustomToolIconAssignments;
    procedure ConfigureTitleBar(const ATheme: TDevShellTheme);
    procedure RebuildCustomToolButtonImages(const ATheme: TDevShellTheme);
    procedure AboutDecorationsPaint(Sender: TObject);
    procedure AboutRepositoryClick(Sender: TObject);
    procedure AboutPhosphorClick(Sender: TObject);
    procedure AboutOpenSSLClick(Sender: TObject);
    procedure LoadAboutLogo;
    function GeneralInputBorderRect(AInput: TWinControl): TRect;
    procedure NewCommand(Data: TDataSet);
    procedure LoadMacros;
    procedure UpdateViewHeader(AIndex: Integer);
  protected
    procedure ChangeScale(AM, AD: Integer; AIsDpiChange: Boolean); override;
  public
    property Settings: TSettings Read FSettings Write FSettings;
    procedure LoadSettings;
  end;

var
  FrmSettings: TFrmSettings;

procedure ActivateSettingsVclStyle;

implementation

Uses
  Winapi.ShellAPI,
  DelphiDevShellTools.SettingsStore,
  DelphiDevShellTools.Icons,
  DelphiDevShellTools.Logging,
  DelphiDevShellTools.Phosphor.Font,
  DelphiDevShellTools.GUI.MiscGUI,
  StrUtils,
  System.Math,
  System.Types,
  System.UITypes,
  System.Win.Registry,
  Vcl.Styles,
  Vcl.Themes,
  ComObj,
  IOUtils,
  MidasLib;

{$R *.dfm}

type
  TControlAccess = class(TControl);
  TDBGridAccess = class(TDBGrid);

const
  cGlowStyleName = 'Glow';
  cSettingsFontSize = TDevShellTheme.cFontSize;
  cSideBarGeneral = 0;
  cSideBarMenu = 1;
  cSideBarCustomTools = 2;
  cSideBarAbout = 3;
  cSideBarItemCount = 4;
  cSideBarItemHeight = 56;
  cSideBarIconSize = 28;
  cSideBarHorizontalPadding = 8;
  cSideBarIconTextGap = 12;
  cSideBarCornerRadius = 6;
  cSideBarAccentWidth = 4;
  cDesignPPI = 96;
  cGeneralCardMargin = 24;
  cGeneralCardTop = 15;
  cGeneralCardBottomMargin = 32;
  cGeneralCardCornerRadius = 8;
  cGeneralCardBorderBlend = 0.87;
  cGeneralInputBorderBlend = 0.78;
  cChromeBorderBlend = 0.84;
  cSideBarSelectionFillBlend = 0.92;
  cSideBarSelectionBorderBlend = 0.78;
  cSideBarHotFillBlend = 0.96;
  cSideBarHotBorderBlend = 0.86;
  cSettingsTitleBarHeight = 45;
  cGeneralInputPaddingX = 8;
  cGeneralInputPaddingY = 11;
  cGeneralInputTextInsetX = 3;
  cGeneralInputFrameTopInset = 8;
  cGeneralInputFrameBottomInset = 1;
  cGeneralInputHeight = 18;
  cGeneralInputLeft = 109;
  cGeneralInputRightInset = 56;
  cGeneralTitleLeft = 47;
  cGeneralFeatureLabelLeft = 100;
  cGeneralFileExtensionsTop = 37;
  cGeneralFeatureFirstTop = 85;
  cGeneralFeatureRowGap = 106;
  cGeneralInputFirstTop = 119;
  cGeneralIconLeft = 46;
  cGeneralIconSize = 28;
  cMenuCardLeftMargin = 37;
  cMenuCardRightMargin = 29;
  cMenuCardTop = 16;
  cMenuCommonCardBottom = 181;
  cMenuDelphiCardTop = 190;
  cMenuDelphiCardBottom = 443;
  cMenuLazarusCardTop = 452;
  cMenuLazarusCardBottom = 586;
  cMenuCardCornerRadius = 8;
  cMenuGroupIconLeft = 49;
  cMenuGroupTitleLeft = 102;
  cMenuGroupTop = 14;
  cMenuGroupIconSize = 28;
  cMenuCommandIconSize = 28;
  cMenuCommonCheckboxLeft = 108;
  cMenuCommonFirstRowTop = 71;
  cMenuCommonRowGap = 35;
  cMenuLeftIconLeft = 99;
  cMenuLeftCheckboxLeft = 152;
  cMenuRightIconLeft = 602;
  cMenuRightCheckboxLeft = 655;
  cMenuDelphiFirstRowTop = 252;
  cMenuDelphiRowGap = 48;
  cMenuLazarusFirstRowTop = 509;
  cMenuLazarusChildLeft = 120;
  cMenuLazarusChildRowTop = 543;
  cMenuCheckboxHeight = 19;
  cMenuLeftCheckBoxWidth = 430;
  cMenuRightCheckBoxWidth = 300;
  cFooterButtonWidth = 135;
  cFooterButtonHeight = 42;
  cFooterButtonGap = 22;
  cFooterRightMargin = 12;
  cCustomCardTop = 9;
  cCustomCardBottom = 586;
  cCustomCardCornerRadius = 8;
  cCustomToolsCardLeft = 14;
  cCustomToolsCardRight = 247;
  cCustomEditorCardLeft = 255;
  cCustomEditorCardRight = 698;
  cCustomMacrosCardLeft = 706;
  cCustomMacrosCardRight = 1029;
  cCustomCardTitleTop = 22;
  cCustomToolsGridLeft = 20;
  cCustomToolsGridTop = 56;
  cCustomToolsGridWidth = 220;
  cCustomToolsGridHeight = 456;
  cCustomNewButtonLeft = 146;
  cCustomDeleteButtonLeft = 146;
  cCustomToolButtonWidth = 90;
  cCustomToolButtonHeight = 30;
  cCustomEditorLeft = 268;
  cCustomGroupWidth = 130;
  cCustomMinimumLeft = 415;
  cCustomMinimumWidth = 145;
  cCustomNameLeft = 577;
  cCustomNameWidth = 108;
  cCustomMenuWidth = 312;
  cCustomImageLeft = 591;
  cCustomImageWidth = 78;
  cCustomEditorWidth = 416;
  cCustomMacrosLeft = 714;
  cCustomMacrosWidth = 308;
  cCustomButtonIconSize = 18;
  cCustomGridIconSize = 22;
  cCustomInputHeight = 32;
  cCustomComboItemHeight = 29;
  cCustomInputPaddingX = 8;
  cCustomInputPaddingY = 4;
  cCustomInputTextOffsetY = 3;
  cCustomInputCornerRadius = 2;
  cCustomListRowHeight = 36;
  cCustomMacroRowHeight = 38;
  cCustomMacrosHeaderTop = 56;
  cCustomMacrosHeaderHeight = 34;
  cCustomMacrosListTop = 89;
  cCustomMacrosListHeight = 489;
  cSideBarCaptions: array[cSideBarGeneral..cSideBarAbout] of string = (
    'General', 'Menu', 'Custom tools', 'About');
  cSideBarIconCodes: array[cSideBarGeneral..cSideBarAbout] of Word = (
    cPhSlidersHorizontal, cPhListChecks, cPhToolbox, cPhInfo);
  cGeneralIconCodes: array[0..3] of Word = (
    cPhListChecks, cPhCode, cPhCodeBlock, cPhFingerprint);
  cMenuGroupIconCodes: array[0..2] of Word = (
    cPhListChecks, cPhCode, cPhCodeBlock);
  cMenuCommandIconCodes: array[0..7] of Word = (
    cPhAppWindow, cPhHammer, cPhHammer, cPhHandTap,
    cPhCode, cPhBracketsCurly, cPhBrowser, cPhFlame);
  cViewTitles: array[cSideBarGeneral..cSideBarAbout] of string = (
    'General', 'Menu', 'Custom tools', 'About');
  cViewDescriptions: array[cSideBarGeneral..cSideBarAbout] of string = (
    'Configure the file extensions used by each shell feature.',
    'Choose how commands are grouped in the Explorer context menu.',
    'Create and edit Explorer context-menu tools.',
    'Application information, project links and third-party credits.');
  cAboutCardLeft = 24;
  cAboutCardTop = 20;
  cAboutCardRight = 975;
  cAboutCardBottom = 568;
  cAboutLogoSize = 96;
  cAboutDetailLeft = 178;
  cAboutIconLeft = 48;
  cAboutLabelLeft = 82;
  cAboutIconSize = 22;
  cAboutThirdPartyLinkLeft = 260;
  cAboutRepositoryURL = 'https://github.com/RRUZ/delphi-dev-shell-tools';
  cAboutPhosphorURL = 'https://github.com/phosphor-icons';
  cAboutOpenSSLURL = 'https://www.openssl.org/';
  cShellClassKey =
    'Software\Classes\CLSID\{45DCA61E-3762-45B1-' +
    '939D-2446C0DCAC25}\InprocServer32';
  cAboutRowIconCodes: array[0..4] of Word = (
    cPhUser, cPhGithubLogo, cPhScales, cPhGithubLogo, cPhGlobe);
  cAboutRowIconTops: array[0..4] of Integer = (
    270, 306, 351, 418, 456);

procedure ActivateSettingsVclStyle;
begin
  if TDevShellTheme.ActiveTheme.Kind <> dstDark then
    Exit;

  TStyleManager.SetStyle(cGlowStyleName);
end;

procedure TFlatPageControl.AdjustClientRect(var ARect: TRect);
begin
  ARect := ClientRect;
end;

procedure TFlatPageControl.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style and not WS_BORDER;
  Params.ExStyle := Params.ExStyle and not WS_EX_CLIENTEDGE;
end;

procedure TFlatDBGrid.UpdateScrollBar;
begin
  inherited;
  ShowScrollBar(Handle, SB_VERT, False);
end;

procedure TDevShellLookupComboBox.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style and not WS_BORDER;
  Params.ExStyle := Params.ExStyle and not WS_EX_CLIENTEDGE;
end;

procedure TDevShellDBComboBox.CreateParams(var Params: TCreateParams);
begin
  inherited CreateParams(Params);
  Params.Style := Params.Style and not WS_BORDER;
  Params.ExStyle := Params.ExStyle and not WS_EX_CLIENTEDGE;
end;

procedure TDevShellDBComboBox.SetBounds(ALeft, ATop, AWidth,
  AHeight: Integer);
begin
  AutoSize := False;
  TCustomControlBoundsAccess(Self).SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TDevShellLookupComboBox.SetBounds(ALeft, ATop, AWidth,
  AHeight: Integer);
begin
  TCustomControlBoundsAccess(Self).SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TCustomControlBoundsAccess.SetBounds(ALeft, ATop, AWidth,
  AHeight: Integer);
begin
  inherited SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TDevShellLookupComboBox.Paint;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LButtonWidth := MulDiv(cDevShellComboBoxButtonWidth, CurrentPPI,
    cDesignPPI);
  var LBorderColor := BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
    cGeneralInputBorderBlend);
  if Focused then
    LBorderColor := BlendColor(LTheme.AccentColor, LTheme.BackgroundColor,
      0.55);
  var LControlRect := ClientRect;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := LTheme.BackgroundColor;
  Canvas.FillRect(ClientRect);
  DrawAntialiasedRoundedRectangle(Canvas, LControlRect,
    LTheme.BackgroundColor, LBorderColor,
    MulDiv(cCustomInputCornerRadius, CurrentPPI, cDesignPPI),
    Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));

  var LButtonRect := LControlRect;
  LButtonRect.Left := LButtonRect.Right - LButtonWidth;
  Canvas.Pen.Color := LBorderColor;
  Canvas.Pen.Width := 1;
  Canvas.MoveTo(LButtonRect.Left, LButtonRect.Top + 1);
  Canvas.LineTo(LButtonRect.Left, LButtonRect.Bottom - 1);
  var LTextRect := LControlRect;
  LTextRect.Left := LTextRect.Left +
    MulDiv(cCustomInputPaddingX, CurrentPPI, cDesignPPI);
  LTextRect.Right := LButtonRect.Left -
    MulDiv(cCustomInputPaddingX div 2, CurrentPPI, cDesignPPI);
  Canvas.Font.Assign(Font);
  Canvas.Font.Color := if Enabled then LTheme.TextColor else LTheme.MutedColor;
  Canvas.Brush.Style := bsClear;
  DrawText(Canvas.Handle, PChar(Text), Length(Text), LTextRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
  DrawDevShellChevron(Canvas,
    Point((LButtonRect.Left + LButtonRect.Right) div 2,
      (LButtonRect.Top + LButtonRect.Bottom) div 2), LTheme.MutedColor,
    dscdDown, CurrentPPI / cDesignPPI);
end;

procedure TDevShellLookupComboBoxStyleHook.PaintNC(ACanvas: TCanvas);
begin
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
begin
  Result := AInput.BoundsRect;
  InflateRect(Result, MulDiv(cGeneralInputPaddingX, CurrentPPI,
    cDesignPPI), MulDiv(cGeneralInputPaddingY, CurrentPPI, cDesignPPI));
end;

procedure TFrmSettings.GeneralDecorationsPaint(Sender: TObject);
var
  LPhosphorFont: TPhosphorFont;

  procedure DrawFeatureIcon(AIndex: Integer; ALabel: TLabel;
    AColor: TColor);
  begin
    var LIconSize := MulDiv(cGeneralIconSize, CurrentPPI, cDesignPPI);
    var LIconLeft := MulDiv(cGeneralIconLeft, CurrentPPI, cDesignPPI);
    var LIconTop := ALabel.Top + (ALabel.Height - LIconSize) div 2;
    var LIconRect := Rect(LIconLeft, LIconTop, LIconLeft + LIconSize,
      LIconTop + LIconSize);
    LPhosphorFont.DrawDuotoneIcon(PaintBoxGeneral.Canvas.Handle,
      cGeneralIconCodes[AIndex], LIconRect, AColor, AColor, 76, False);
  end;

begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LCardRect := Rect(
    MulDiv(cGeneralCardMargin, CurrentPPI, cDesignPPI),
    MulDiv(cGeneralCardTop, CurrentPPI, cDesignPPI),
    PaintBoxGeneral.ClientWidth -
      MulDiv(cGeneralCardMargin, CurrentPPI, cDesignPPI),
    PaintBoxGeneral.ClientHeight -
      MulDiv(cGeneralCardBottomMargin, CurrentPPI, cDesignPPI));
  var LCardBorderColor := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  DrawAntialiasedRoundedRectangle(PaintBoxGeneral.Canvas, LCardRect,
    LTheme.BackgroundColor, LCardBorderColor,
    MulDiv(cGeneralCardCornerRadius, CurrentPPI, cDesignPPI),
    Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));

  if not TryGetPhosphorFont(LPhosphorFont) then
    Exit;
  DrawFeatureIcon(0, Label2, LTheme.PrimaryColor);
  DrawFeatureIcon(1, Label3, LTheme.PrimaryColor);
  DrawFeatureIcon(2, Label4, LTheme.SecondaryColor);
  DrawFeatureIcon(3, Label6, LTheme.PrimaryColor);
end;

procedure TFrmSettings.GeneralInputBordersPaint(Sender: TObject);
  procedure DrawInput(AInput: TWinControl);
  begin
    var LTheme := TDevShellTheme.ActiveTheme;
    var LBorderColor := if AInput.Focused then LTheme.AccentColor else
      BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
        cGeneralInputBorderBlend);
    DrawAntialiasedRoundedRectangle(PaintBoxGeneralInputBorders.Canvas,
      GeneralInputBorderRect(AInput), clNone, LBorderColor,
      MulDiv(cCustomInputCornerRadius, CurrentPPI, cDesignPPI), 1);
  end;
begin
  DrawInput(EditCommonTaskExt);
  DrawInput(EditOpenDelphiExt);
  DrawInput(EditOpenLazarusExt);
  DrawInput(EditCheckSumExt);
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

procedure TFrmSettings.ConfigureGeneralPage;
  procedure SetDesignBounds(AControl: TControl; ALeft, ATop, AWidth,
    AHeight: Integer);
  begin
    AControl.SetBounds(MulDiv(ALeft, CurrentPPI, cDesignPPI),
      MulDiv(ATop, CurrentPPI, cDesignPPI),
      MulDiv(AWidth, CurrentPPI, cDesignPPI),
      MulDiv(AHeight, CurrentPPI, cDesignPPI));
  end;

  procedure SetGeneralInputBounds(AInput: TEdit; ATop: Integer);
  begin
    AInput.AutoSize := False;
    AInput.BorderStyle := bsNone;
    AInput.Left := MulDiv(cGeneralInputLeft + cGeneralInputTextInsetX,
      CurrentPPI, cDesignPPI);
    AInput.Top := MulDiv(ATop, CurrentPPI, cDesignPPI);
    AInput.Height := MulDiv(cGeneralInputHeight, CurrentPPI, cDesignPPI);
    AInput.Width := Max(1, PanelGeneral.ClientWidth - AInput.Left -
      MulDiv(cGeneralInputRightInset + cGeneralInputTextInsetX, CurrentPPI,
        cDesignPPI));
  end;

begin
  PaintBoxGeneral.SendToBack;
  PaintBoxGeneralInputBorders.BringToFront;
  PaintBoxGeneralInputBorders.SetBounds(0, 0, PanelGeneral.ClientWidth,
    PanelGeneral.ClientHeight);
  SetDesignBounds(LabelFileExtensionsTitle, cGeneralTitleLeft,
    cGeneralFileExtensionsTop,
    240, 20);
  SetDesignBounds(Label2, cGeneralFeatureLabelLeft, cGeneralFeatureFirstTop,
    300, 20);
  SetDesignBounds(Label3, cGeneralFeatureLabelLeft, cGeneralFeatureFirstTop +
    cGeneralFeatureRowGap, 300, 20);
  SetDesignBounds(Label4, cGeneralFeatureLabelLeft, cGeneralFeatureFirstTop +
    2 * cGeneralFeatureRowGap, 300, 20);
  SetDesignBounds(Label6, cGeneralFeatureLabelLeft, cGeneralFeatureFirstTop +
    3 * cGeneralFeatureRowGap, 340, 20);
  SetGeneralInputBounds(EditCommonTaskExt, cGeneralInputFirstTop);
  SetGeneralInputBounds(EditOpenDelphiExt, cGeneralInputFirstTop +
    cGeneralFeatureRowGap);
  SetGeneralInputBounds(EditOpenLazarusExt, cGeneralInputFirstTop +
    2 * cGeneralFeatureRowGap);
  SetGeneralInputBounds(EditCheckSumExt, cGeneralInputFirstTop +
    3 * cGeneralFeatureRowGap);
  EditCommonTaskExt.StyleName := 'Windows';
  EditOpenDelphiExt.StyleName := 'Windows';
  EditOpenLazarusExt.StyleName := 'Windows';
  EditCheckSumExt.StyleName := 'Windows';
end;

procedure TFrmSettings.ConfigureMenuPage;

  procedure SetMenuCheckBoxBounds(ACheckBox: TCheckBox; ALeft, ATop,
    AWidth: Integer);
  begin
    ACheckBox.SetBounds(MulDiv(ALeft, CurrentPPI, cDesignPPI),
      MulDiv(ATop, CurrentPPI, cDesignPPI),
      MulDiv(AWidth, CurrentPPI, cDesignPPI),
      MulDiv(cMenuCheckboxHeight, CurrentPPI, cDesignPPI));
  end;

begin
  PaintBoxMenu.SendToBack;
  Image1.Visible := False;
  Image2.Visible := False;
  Image3.Visible := False;

  SetMenuCheckBoxBounds(CheckBoxSubMenuCommonTasks,
    cMenuCommonCheckboxLeft, cMenuCommonFirstRowTop, 765);
  SetMenuCheckBoxBounds(CheckBoxShowInfoDProj, cMenuCommonCheckboxLeft,
    cMenuCommonFirstRowTop + cMenuCommonRowGap, 765);
  SetMenuCheckBoxBounds(CheckBoxSubMenuCompileRC,
    cMenuCommonCheckboxLeft,
    cMenuCommonFirstRowTop + 2 * cMenuCommonRowGap, 765);

  SetMenuCheckBoxBounds(CheckBoxSubMenuOpenCmdRAD, cMenuLeftCheckboxLeft,
    cMenuDelphiFirstRowTop, cMenuLeftCheckBoxWidth);
  SetMenuCheckBoxBounds(CheckBoxSubMenuMSBuild, cMenuLeftCheckboxLeft,
    cMenuDelphiFirstRowTop + cMenuDelphiRowGap, cMenuLeftCheckBoxWidth);
  SetMenuCheckBoxBounds(CheckBoxSubMenuMSBuildAnother,
    cMenuLeftCheckboxLeft,
    cMenuDelphiFirstRowTop + 2 * cMenuDelphiRowGap, cMenuLeftCheckBoxWidth);
  SetMenuCheckBoxBounds(CheckBoxSubMenuRunTouch, cMenuLeftCheckboxLeft,
    cMenuDelphiFirstRowTop + 3 * cMenuDelphiRowGap, cMenuLeftCheckBoxWidth);

  SetMenuCheckBoxBounds(CheckBoxSubMenuOpenDelphi,
    cMenuRightCheckboxLeft, cMenuDelphiFirstRowTop, cMenuRightCheckBoxWidth);
  SetMenuCheckBoxBounds(CheckBoxSubMenuFormat, cMenuRightCheckboxLeft,
    cMenuDelphiFirstRowTop + cMenuDelphiRowGap, cMenuRightCheckBoxWidth);
  SetMenuCheckBoxBounds(CheckBoxSubMenuVCLStyles,
    cMenuRightCheckboxLeft,
    cMenuDelphiFirstRowTop + 2 * cMenuDelphiRowGap, cMenuRightCheckBoxWidth);
  SetMenuCheckBoxBounds(CheckBoxSubMenuFMXStyles,
    cMenuRightCheckboxLeft,
    cMenuDelphiFirstRowTop + 3 * cMenuDelphiRowGap, cMenuRightCheckBoxWidth);

  SetMenuCheckBoxBounds(CheckBoxActivateLazarus,
    cMenuCommonCheckboxLeft, cMenuLazarusFirstRowTop, 765);
  SetMenuCheckBoxBounds(CheckBoxSubMenuLazarus, cMenuLazarusChildLeft,
    cMenuLazarusChildRowTop, 727);
  PaintBoxMenu.Invalidate;
end;

procedure TFrmSettings.MenuDecorationsPaint(Sender: TObject);
var
  LPhosphorFont: TPhosphorFont;

  procedure DrawCard(ATop, ABottom: Integer; const ATheme: TDevShellTheme);
  begin
    var LCardRect := Rect(
      MulDiv(cMenuCardLeftMargin, CurrentPPI, cDesignPPI),
      MulDiv(ATop, CurrentPPI, cDesignPPI),
      PaintBoxMenu.ClientWidth -
        MulDiv(cMenuCardRightMargin, CurrentPPI, cDesignPPI),
      MulDiv(ABottom, CurrentPPI, cDesignPPI));
    var LBorderColor := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, cGeneralCardBorderBlend);
    DrawAntialiasedRoundedRectangle(PaintBoxMenu.Canvas, LCardRect,
      ATheme.BackgroundColor, LBorderColor,
      MulDiv(cMenuCardCornerRadius, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  procedure DrawGroupTitle(const ACaption: string; ATop: Integer;
    const ATheme: TDevShellTheme);
  begin
    PaintBoxMenu.Canvas.Font.Name := TDevShellTheme.cFontName;
    PaintBoxMenu.Canvas.Font.Size := cSettingsFontSize + 2;
    PaintBoxMenu.Canvas.Font.Style := [fsBold];
    PaintBoxMenu.Canvas.Font.Color := ATheme.TextColor;
    PaintBoxMenu.Canvas.Brush.Style := bsClear;
    var LTextRect := Rect(
      MulDiv(cMenuGroupTitleLeft, CurrentPPI, cDesignPPI),
      MulDiv(ATop + cMenuGroupTop, CurrentPPI, cDesignPPI),
      PaintBoxMenu.ClientWidth -
      MulDiv(cMenuCardRightMargin, CurrentPPI, cDesignPPI),
      MulDiv(ATop + cMenuGroupTop + cMenuGroupIconSize,
        CurrentPPI, cDesignPPI));
    DrawText(PaintBoxMenu.Canvas.Handle, PChar(ACaption), Length(ACaption),
      LTextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;

  procedure DrawMenuIcon(ACode: Word; ALeft, ATop: Integer;
    AColor: TColor; ASize: Integer);
  begin
    var LIconRect := Rect(
      MulDiv(ALeft, CurrentPPI, cDesignPPI),
      MulDiv(ATop, CurrentPPI, cDesignPPI),
      MulDiv(ALeft + ASize, CurrentPPI, cDesignPPI),
      MulDiv(ATop + ASize, CurrentPPI, cDesignPPI));
    LPhosphorFont.DrawDuotoneIcon(PaintBoxMenu.Canvas.Handle, ACode,
      LIconRect, AColor, AColor, 76, False);
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
  DrawCard(cMenuCardTop, cMenuCommonCardBottom, LTheme);
  DrawCard(cMenuDelphiCardTop, cMenuDelphiCardBottom, LTheme);
  DrawCard(cMenuLazarusCardTop, cMenuLazarusCardBottom, LTheme);
  DrawGroupTitle('Common tasks', cMenuCardTop, LTheme);
  DrawGroupTitle('Delphi tools', cMenuDelphiCardTop, LTheme);
  DrawGroupTitle('Lazarus', cMenuLazarusCardTop, LTheme);

  PaintBoxMenu.Canvas.Pen.Color := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralInputBorderBlend);
  PaintBoxMenu.Canvas.Pen.Style := psDot;
  PaintBoxMenu.Canvas.Pen.Width := 1;
  var LConnectorX := MulDiv(cMenuCommonCheckboxLeft + 8,
    CurrentPPI, cDesignPPI);
  var LConnectorTop := MulDiv(cMenuLazarusFirstRowTop +
    cMenuCheckboxHeight, CurrentPPI, cDesignPPI);
  var LConnectorBottom := MulDiv(cMenuLazarusChildRowTop +
    cMenuCheckboxHeight div 2, CurrentPPI, cDesignPPI);
  PaintBoxMenu.Canvas.MoveTo(LConnectorX, LConnectorTop);
  PaintBoxMenu.Canvas.LineTo(LConnectorX, LConnectorBottom);
  PaintBoxMenu.Canvas.LineTo(MulDiv(cMenuLazarusChildLeft - 4,
    CurrentPPI, cDesignPPI), LConnectorBottom);
  PaintBoxMenu.Canvas.Pen.Style := psSolid;

  if not TryGetPhosphorFont(LPhosphorFont) then
    Exit;

  DrawMenuIcon(cMenuGroupIconCodes[0], cMenuGroupIconLeft,
    cMenuCardTop + cMenuGroupTop, LTheme.SecondaryColor,
    cMenuGroupIconSize);
  DrawMenuIcon(cMenuGroupIconCodes[1], cMenuGroupIconLeft,
    cMenuDelphiCardTop + cMenuGroupTop, LTheme.PrimaryColor,
    cMenuGroupIconSize);
  DrawMenuIcon(cMenuGroupIconCodes[2], cMenuGroupIconLeft,
    cMenuLazarusCardTop + cMenuGroupTop, LTheme.SecondaryColor,
    cMenuGroupIconSize);

  for var LIndex := 0 to 3 do
  begin
    var LIconTop := cMenuDelphiFirstRowTop +
      LIndex * cMenuDelphiRowGap -
      (cMenuCommandIconSize - cMenuCheckboxHeight) div 2;
    DrawMenuIcon(cMenuCommandIconCodes[LIndex], cMenuLeftIconLeft,
      LIconTop, CommandIconColor(LIndex, LTheme), cMenuCommandIconSize);
    DrawMenuIcon(cMenuCommandIconCodes[LIndex + 4], cMenuRightIconLeft,
      LIconTop, CommandIconColor(LIndex + 4, LTheme),
      cMenuCommandIconSize);
  end;
end;

procedure TFrmSettings.ConfigureCustomToolsPage;

  procedure SetDesignBounds(AControl: TControl; ALeft, ATop, AWidth,
    AHeight: Integer);
  begin
    AControl.SetBounds(MulDiv(ALeft, CurrentPPI, cDesignPPI),
      MulDiv(ATop, CurrentPPI, cDesignPPI),
      MulDiv(AWidth, CurrentPPI, cDesignPPI),
      MulDiv(AHeight, CurrentPPI, cDesignPPI));
  end;

  procedure SetDesignInputBounds(AControl: TControl; ALeft, ATop, AWidth,
    AHeight: Integer; ATextOffsetY: Integer = 0);
  begin
    SetDesignBounds(AControl, ALeft + cCustomInputPaddingX,
      ATop + cCustomInputPaddingY + ATextOffsetY,
      AWidth - 2 * cCustomInputPaddingX,
      AHeight - 2 * cCustomInputPaddingY - 2 * ATextOffsetY);
  end;

begin
  PaintBoxCustomTools.SendToBack;
  DBNavigator1.Visible := False;
  Image5.Visible := False;
  Label12.Visible := False;

  SetDesignBounds(DBGrid1, cCustomToolsGridLeft, cCustomToolsGridTop,
    cCustomToolsGridWidth, cCustomToolsGridHeight);
  DBGrid1.BorderStyle := bsNone;
  TDBGridAccess(DBGrid1).ScrollBars := ssNone;
  DBGrid1.DefaultDrawing := False;
  DBGrid1.Options := [dgRowSelect, dgAlwaysShowSelection, dgConfirmDelete,
    dgCancelOnExit];
  TDBGridAccess(DBGrid1).DefaultRowHeight := MulDiv(cCustomListRowHeight,
    CurrentPPI, cDesignPPI);
  for var LRow := 0 to TDBGridAccess(DBGrid1).RowCount - 1 do
    TDBGridAccess(DBGrid1).RowHeights[LRow] :=
      MulDiv(cCustomListRowHeight, CurrentPPI, cDesignPPI);
  if DBGrid1.Columns.Count > 0 then
    DBGrid1.Columns[0].Width := DBGrid1.ClientWidth;

  SetDesignBounds(ButtonNewTool, cCustomNewButtonLeft, 20,
    cCustomToolButtonWidth, cCustomToolButtonHeight);
  SetDesignBounds(ButtonDeleteTool, cCustomDeleteButtonLeft, 540,
    cCustomToolButtonWidth, cCustomToolButtonHeight);

  SetDesignBounds(Label7, cCustomEditorLeft, 30, cCustomGroupWidth, 17);
  SetDesignBounds(DBComboBoxGroup, cCustomEditorLeft, 57,
    cCustomGroupWidth, cCustomInputHeight);
  SetDesignBounds(LabelDelphi, cCustomMinimumLeft, 30,
    cCustomMinimumWidth, 17);
  SetDesignBounds(DBLookupComboBoxDelphi, cCustomMinimumLeft, 57,
    cCustomMinimumWidth, cCustomInputHeight);
  SetDesignBounds(Label8, cCustomNameLeft, 30, cCustomNameWidth, 17);
  SetDesignInputBounds(DBEditName, cCustomNameLeft, 57, cCustomNameWidth,
    cCustomInputHeight, cCustomInputTextOffsetY);

  SetDesignBounds(Label9, cCustomEditorLeft, 116, cCustomMenuWidth, 17);
  SetDesignInputBounds(DBEditMenu, cCustomEditorLeft, 138, cCustomMenuWidth,
    cCustomInputHeight, cCustomInputTextOffsetY);
  SetDesignBounds(Label14, cCustomImageLeft, 116, cCustomImageWidth, 17);
  SetDesignBounds(DBComboBoxImage, cCustomImageLeft, 138,
    cCustomImageWidth, cCustomInputHeight);

  SetDesignBounds(Label11, cCustomEditorLeft, 197,
    cCustomEditorWidth, 17);
  SetDesignInputBounds(DBEditExtensions, cCustomEditorLeft, 223,
    cCustomEditorWidth, cCustomInputHeight, cCustomInputTextOffsetY);
  SetDesignBounds(Label10, cCustomEditorLeft, 272,
    cCustomEditorWidth, 17);
  SetDesignInputBounds(DBMemoScript, cCustomEditorLeft, 297,
    cCustomEditorWidth, 232);
  SetDesignBounds(DBCheckBoxRunAs, 542, 547, 152, 22);

  SetDesignBounds(ListViewMacros, cCustomMacrosLeft + 2,
    cCustomMacrosListTop + 1, cCustomMacrosWidth - 4,
    cCustomMacrosListHeight - 2);
  SetDesignBounds(BtnInsertMacro, 881, 526, 95, 30);

  DBEditMenu.AutoSize := False;
  DBEditName.AutoSize := False;
  DBEditExtensions.AutoSize := False;
  DBEditMenu.BorderStyle := bsNone;
  DBEditName.BorderStyle := bsNone;
  DBEditExtensions.BorderStyle := bsNone;
  DBMemoScript.BorderStyle := bsNone;
  DBComboBoxGroup.ItemHeight := MulDiv(cCustomComboItemHeight,
    CurrentPPI, cDesignPPI);
  DBComboBoxGroup.Style := csOwnerDrawFixed;
  DBComboBoxGroup.OnDrawItem := DBComboBoxGroupDrawItem;
  DBComboBoxImage.ItemHeight := MulDiv(cCustomComboItemHeight,
    CurrentPPI, cDesignPPI);
  DBComboBoxImage.DropDownCount := 12;
  DBComboBoxImage.DropDownWidth := MulDiv(240, CurrentPPI, cDesignPPI);
  ListViewMacros.BorderStyle := bsNone;
  ListViewMacros.GridLines := False;
  ListViewMacros.OwnerDraw := True;
  ListViewMacros.OnDrawItem := ListViewMacrosDrawItem;
  ListViewMacros.ShowColumnHeaders := False;
  FMacroRowImages.ColorDepth := cd32Bit;
  FMacroRowImages.Width := 1;
  FMacroRowImages.Height := MulDiv(cCustomMacroRowHeight, CurrentPPI,
    cDesignPPI);
  ListViewMacros.SmallImages := FMacroRowImages;
  if ListViewMacros.Columns.Count >= 2 then
  begin
    ListViewMacros.Columns[0].Width := MulDiv(98, CurrentPPI, cDesignPPI);
    ListViewMacros.Columns[1].Width := Max(0, ListViewMacros.ClientWidth -
      ListViewMacros.Columns[0].Width - MulDiv(4, CurrentPPI, cDesignPPI));
  end;
  LabelDelphi.Caption := 'Minimum Delphi version';
  DBCheckBoxRunAs.Caption := 'Run as administrator';
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

    FAboutProduct := CreateAboutLabel('Delphi Dev. Shell Tools', 18,
      True, False);
    FAboutDescription := CreateAboutLabel(
      'Shell Extension for Delphi Developers', 9, False, True);
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

  SetDesignBounds(FAboutLogo, 55, 48, cAboutLogoSize, cAboutLogoSize);
  SetDesignBounds(FAboutProduct, cAboutDetailLeft, 52, 520, 32);
  SetDesignBounds(FAboutDescription, cAboutDetailLeft, 88, 620, 24);
  SetDesignBounds(FAboutVersionTitle, 64, 164, 180, 18);
  SetDesignBounds(FAboutVersion, 64, 185, 240, 26);
  SetDesignBounds(FAboutBuildTitle, 365, 164, 180, 18);
  SetDesignBounds(FAboutBuild, 365, 185, 180, 26);
  SetDesignBounds(FAboutArchitectureTitle, 665, 164, 220, 18);
  SetDesignBounds(FAboutArchitecture, 665, 185, 260, 42);
  SetDesignBounds(FAboutAuthorTitle, cAboutLabelLeft, 270, 96, 22);
  SetDesignBounds(FAboutAuthor, cAboutDetailLeft, 270, 430, 22);
  SetDesignBounds(FAboutRepositoryTitle, cAboutLabelLeft, 312, 210, 22);
  FAboutRepositoryTitle.AutoSize := True;
  SetDesignBounds(FAboutRepositoryButton, cAboutDetailLeft, 302, 300, 30);
  SetDesignBounds(FAboutLicenseTitle, cAboutLabelLeft, 354, 96, 22);
  SetDesignBounds(FAboutLicenseBadge, cAboutDetailLeft, 348, 80, 28);
  SetDesignBounds(FAboutPhosphorTitle, cAboutLabelLeft, 418, 150, 22);
  SetDesignBounds(FAboutPhosphorButton, cAboutThirdPartyLinkLeft, 408,
    235, 30);
  SetDesignBounds(FAboutOpenSSLTitle, cAboutLabelLeft, 456, 150, 22);
  SetDesignBounds(FAboutOpenSSLButton, cAboutThirdPartyLinkLeft, 446,
    140, 30);
  FAboutPaintBox.Invalidate;
end;

procedure TFrmSettings.AboutDecorationsPaint(Sender: TObject);
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
  for var LTop in TArray<Integer>.Create(140, 238, 394) do
  begin
    LCanvas.MoveTo(MulDiv(48, CurrentPPI, cDesignPPI),
      MulDiv(LTop, CurrentPPI, cDesignPPI));
    LCanvas.LineTo(MulDiv(951, CurrentPPI, cDesignPPI),
      MulDiv(LTop, CurrentPPI, cDesignPPI));
  end;
  for var LLeft in TArray<Integer>.Create(340, 640) do
  begin
    LCanvas.MoveTo(MulDiv(LLeft, CurrentPPI, cDesignPPI),
      MulDiv(158, CurrentPPI, cDesignPPI));
    LCanvas.LineTo(MulDiv(LLeft, CurrentPPI, cDesignPPI),
      MulDiv(222, CurrentPPI, cDesignPPI));
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
begin
  ShellExecute(Handle, 'open', PChar(cAboutRepositoryURL), nil, nil,
    SW_SHOWNORMAL);
end;

procedure TFrmSettings.AboutPhosphorClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(cAboutPhosphorURL), nil, nil,
    SW_SHOWNORMAL);
end;

procedure TFrmSettings.AboutOpenSSLClick(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar(cAboutOpenSSLURL), nil, nil,
    SW_SHOWNORMAL);
end;

procedure TFrmSettings.RebuildCustomToolButtonImages(
  const ATheme: TDevShellTheme);
var
  LPhosphorFont: TPhosphorFont;
begin
  if FCustomToolButtonImages = nil then
    Exit;

  var LIconSize := MulDiv(cCustomButtonIconSize, CurrentPPI, cDesignPPI);
  FCustomToolButtonImages.Clear;
  FCustomToolButtonImages.ColorDepth := cd32Bit;
  FCustomToolButtonImages.BkColor := clNone;
  FCustomToolButtonImages.Width := LIconSize;
  FCustomToolButtonImages.Height := LIconSize;
  if not TryGetPhosphorFont(LPhosphorFont) then
    Exit;

  var LBitmap := TBitmap.Create;
  try
    LPhosphorFont.RenderDuotoneBitmap(LBitmap, cPhPlus, LIconSize,
      ATheme.SecondaryColor, ATheme.SecondaryColor, 76, False);
    FCustomToolButtonImages.Add(LBitmap, nil);
    LPhosphorFont.RenderDuotoneBitmap(LBitmap, cPhTrash, LIconSize,
      ATheme.DangerColor, ATheme.DangerColor, 76, False);
    FCustomToolButtonImages.Add(LBitmap, nil);
  finally
    LBitmap.Free;
  end;
  ButtonNewTool.Images := FCustomToolButtonImages;
  ButtonNewTool.ImageIndex := 0;
  ButtonDeleteTool.Images := FCustomToolButtonImages;
  ButtonDeleteTool.ImageIndex := 1;
end;

procedure TFrmSettings.CustomToolsDecorationsPaint(Sender: TObject);
var
  LPhosphorFont: TPhosphorFont;

  procedure DrawCard(ALeft, ARight: Integer; const ATheme: TDevShellTheme);
  begin
    var LCardRect := Rect(MulDiv(ALeft, CurrentPPI, cDesignPPI),
      MulDiv(cCustomCardTop, CurrentPPI, cDesignPPI),
      MulDiv(ARight, CurrentPPI, cDesignPPI),
      MulDiv(cCustomCardBottom, CurrentPPI, cDesignPPI));
    var LBorderColor := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, cGeneralCardBorderBlend);
    DrawAntialiasedRoundedRectangle(PaintBoxCustomTools.Canvas, LCardRect,
      ATheme.BackgroundColor, LBorderColor,
      MulDiv(cCustomCardCornerRadius, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  procedure DrawCardTitle(const ACaption: string; ALeft: Integer;
    const ATheme: TDevShellTheme);
  begin
    PaintBoxCustomTools.Canvas.Font.Name := TDevShellTheme.cFontName;
    PaintBoxCustomTools.Canvas.Font.Size := cSettingsFontSize + 2;
    PaintBoxCustomTools.Canvas.Font.Style := [fsBold];
    PaintBoxCustomTools.Canvas.Font.Color := ATheme.TextColor;
    PaintBoxCustomTools.Canvas.Brush.Style := bsClear;
    var LTextRect := Rect(MulDiv(ALeft, CurrentPPI, cDesignPPI),
      MulDiv(cCustomCardTitleTop, CurrentPPI, cDesignPPI),
      PaintBoxCustomTools.ClientWidth,
      MulDiv(cCustomCardTitleTop + 24, CurrentPPI, cDesignPPI));
    DrawText(PaintBoxCustomTools.Canvas.Handle, PChar(ACaption),
      Length(ACaption), LTextRect,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;

  procedure DrawInputBorder(AControl: TWinControl;
    const ATheme: TDevShellTheme);
  begin
    var LBorderRect := AControl.BoundsRect;
    InflateRect(LBorderRect,
      MulDiv(cCustomInputPaddingX, CurrentPPI, cDesignPPI),
      MulDiv(cCustomInputPaddingY, CurrentPPI, cDesignPPI));
    if AControl is TDBEdit then
    begin
      var LTextOffsetY := MulDiv(cCustomInputTextOffsetY, CurrentPPI,
        cDesignPPI);
      Dec(LBorderRect.Top, LTextOffsetY);
      Inc(LBorderRect.Bottom, LTextOffsetY);
    end;
    var LBorderColor := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, cGeneralInputBorderBlend);
    DrawAntialiasedRoundedRectangle(PaintBoxCustomTools.Canvas, LBorderRect,
      clNone, LBorderColor,
      MulDiv(cCustomInputCornerRadius, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  procedure DrawMacrosTable(const ATheme: TDevShellTheme);
  begin
    var LTableRect := Rect(
      MulDiv(cCustomMacrosLeft, CurrentPPI, cDesignPPI),
      MulDiv(cCustomMacrosHeaderTop, CurrentPPI, cDesignPPI),
      MulDiv(cCustomMacrosLeft + cCustomMacrosWidth,
        CurrentPPI, cDesignPPI),
      MulDiv(cCustomMacrosListTop + cCustomMacrosListHeight,
        CurrentPPI, cDesignPPI));
    var LBorderColor := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, cGeneralCardBorderBlend);
    DrawAntialiasedRoundedRectangle(PaintBoxCustomTools.Canvas, LTableRect,
      ATheme.BackgroundColor, LBorderColor,
      MulDiv(4, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));

    var LHeaderRect := Rect(LTableRect.Left + 1, LTableRect.Top + 1,
      LTableRect.Right - 1,
      MulDiv(cCustomMacrosHeaderTop + cCustomMacrosHeaderHeight,
        CurrentPPI, cDesignPPI));
    PaintBoxCustomTools.Canvas.Brush.Style := bsSolid;
    PaintBoxCustomTools.Canvas.Brush.Color := BlendColor(ATheme.TextColor,
      ATheme.BackgroundColor, 0.96);
    PaintBoxCustomTools.Canvas.FillRect(LHeaderRect);
    PaintBoxCustomTools.Canvas.Pen.Color := LBorderColor;
    var LColumnDivider := MulDiv(cCustomMacrosLeft + 100,
      CurrentPPI, cDesignPPI);
    PaintBoxCustomTools.Canvas.MoveTo(LColumnDivider, LHeaderRect.Top);
    PaintBoxCustomTools.Canvas.LineTo(LColumnDivider, LHeaderRect.Bottom);
    PaintBoxCustomTools.Canvas.MoveTo(LHeaderRect.Left, LHeaderRect.Bottom);
    PaintBoxCustomTools.Canvas.LineTo(LHeaderRect.Right, LHeaderRect.Bottom);

    PaintBoxCustomTools.Canvas.Brush.Style := bsClear;
    PaintBoxCustomTools.Canvas.Font.Name := TDevShellTheme.cFontName;
    PaintBoxCustomTools.Canvas.Font.Size := cSettingsFontSize;
    PaintBoxCustomTools.Canvas.Font.Style := [fsBold];
    PaintBoxCustomTools.Canvas.Font.Color := ATheme.TextColor;
    var LNameRect := LHeaderRect;
    LNameRect.Left := LNameRect.Left +
      MulDiv(8, CurrentPPI, cDesignPPI);
    LNameRect.Right := LColumnDivider;
    DrawText(PaintBoxCustomTools.Canvas.Handle, PChar('Name'), -1, LNameRect,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
    var LDescriptionRect := LHeaderRect;
    LDescriptionRect.Left := LColumnDivider +
      MulDiv(8, CurrentPPI, cDesignPPI);
    DrawText(PaintBoxCustomTools.Canvas.Handle, PChar('Description'), -1,
      LDescriptionRect,
      DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;

begin
  var LTheme := TDevShellTheme.ActiveTheme;
  PaintBoxCustomTools.Canvas.Brush.Style := bsSolid;
  PaintBoxCustomTools.Canvas.Brush.Color := LTheme.BackgroundColor;
  PaintBoxCustomTools.Canvas.FillRect(PaintBoxCustomTools.ClientRect);
  DrawCard(cCustomToolsCardLeft, cCustomToolsCardRight, LTheme);
  DrawCard(cCustomEditorCardLeft, cCustomEditorCardRight, LTheme);
  DrawCard(cCustomMacrosCardLeft, cCustomMacrosCardRight, LTheme);
  DrawCardTitle('Tools', 28, LTheme);
  DrawCardTitle('Macros', cCustomMacrosLeft + 6, LTheme);
  DrawMacrosTable(LTheme);
  DrawInputBorder(DBEditName, LTheme);
  DrawInputBorder(DBEditMenu, LTheme);
  DrawInputBorder(DBEditExtensions, LTheme);
  DrawInputBorder(DBMemoScript, LTheme);

  if TryGetPhosphorFont(LPhosphorFont) then
  begin
    var LIconSize := MulDiv(20, CurrentPPI, cDesignPPI);
    var LIconLeft := MulDiv(514, CurrentPPI, cDesignPPI);
    var LIconTop := MulDiv(546, CurrentPPI, cDesignPPI);
    var LIconRect := Rect(LIconLeft, LIconTop, LIconLeft + LIconSize,
      LIconTop + LIconSize);
    LPhosphorFont.DrawDuotoneIcon(PaintBoxCustomTools.Canvas.Handle,
      cPhShieldCheck, LIconRect, LTheme.WarningColor, LTheme.WarningColor,
      76, False);
  end;
end;

procedure TFrmSettings.DBGridToolsDrawColumnCell(Sender: TObject;
  const Rect: TRect; DataCol: Integer; Column: TColumn;
  State: TGridDrawState);
var
  LSource: TProjectIconSource;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  DBGrid1.Canvas.Brush.Style := bsSolid;
  DBGrid1.Canvas.Brush.Color := LTheme.BackgroundColor;
  DBGrid1.Canvas.FillRect(Rect);

  if gdSelected in State then
  begin
    var LSelectionRect := Rect;
    InflateRect(LSelectionRect, -MulDiv(2, CurrentPPI, cDesignPPI),
      -MulDiv(1, CurrentPPI, cDesignPPI));
    var LSelectionColor := BlendColor(LTheme.AccentColor,
      LTheme.BackgroundColor, 0.72);
    DrawAntialiasedRoundedRectangle(DBGrid1.Canvas, LSelectionRect,
      LSelectionColor, LTheme.AccentColor,
      MulDiv(4, CurrentPPI, cDesignPPI),
      Max(Single(1.0), Single(CurrentPPI / cDesignPPI)));
  end;

  var LToolName := Column.Field.DisplayText;
  var LIconKey := Column.Field.DataSet.FieldByName('Image').AsString;
  var LIconSize := MulDiv(cCustomGridIconSize, CurrentPPI, cDesignPPI);
  var LIconLeft := Rect.Left + MulDiv(6, CurrentPPI, cDesignPPI);
  var LIconTop := Rect.Top + (Rect.Height - LIconSize) div 2;
  var LIconRect := System.Types.Rect(LIconLeft, LIconTop,
    LIconLeft + LIconSize, LIconTop + LIconSize);
  TryDrawProjectIcon(DBGrid1.Canvas.Handle, LIconKey, LIconRect, LTheme,
    False, HInstance, LSource);
  if StartsText('TDump ', LToolName) then
  begin
    DBGrid1.Canvas.Brush.Style := bsClear;
    DBGrid1.Canvas.Font.Name := TDevShellTheme.cFontName;
    DBGrid1.Canvas.Font.Size := 6;
    DBGrid1.Canvas.Font.Style := [fsBold];
    DBGrid1.Canvas.Font.Color := LTheme.PrimaryColor;
    var LVariantText := Copy(LToolName, Length('TDump ') + 1, MaxInt);
    DrawText(DBGrid1.Canvas.Handle, PChar(LVariantText),
      Length(LVariantText), LIconRect,
      DT_CENTER or DT_VCENTER or DT_SINGLELINE or DT_NOPREFIX);
  end;

  DBGrid1.Canvas.Brush.Style := bsClear;
  DBGrid1.Canvas.Font.Name := TDevShellTheme.cFontName;
  DBGrid1.Canvas.Font.Size := cSettingsFontSize;
  DBGrid1.Canvas.Font.Style := [];
  DBGrid1.Canvas.Font.Color := LTheme.TextColor;
  var LTextRect := Rect;
  LTextRect.Left := LIconRect.Right + MulDiv(8, CurrentPPI, cDesignPPI);
  DrawText(DBGrid1.Canvas.Handle, PChar(LToolName), Length(LToolName),
    LTextRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
end;

procedure TFrmSettings.ListViewMacrosDrawItem(Sender: TCustomListView;
  Item: TListItem; Rect: TRect; State: TOwnerDrawState);
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LCanvas := TListView(Sender).Canvas;
  var LRowColor := LTheme.BackgroundColor;
  if odSelected in State then
    LRowColor := BlendColor(LTheme.AccentColor,
      LTheme.BackgroundColor, 0.84);

  LCanvas.Brush.Style := bsSolid;
  LCanvas.Brush.Color := LRowColor;
  LCanvas.FillRect(Rect);

  var LDividerColor := BlendColor(LTheme.TextColor,
    LTheme.BackgroundColor, cGeneralCardBorderBlend);
  var LColumnDivider := Rect.Left + ListViewMacros.Columns[0].Width;
  LCanvas.Pen.Color := LDividerColor;
  LCanvas.MoveTo(LColumnDivider, Rect.Top);
  LCanvas.LineTo(LColumnDivider, Rect.Bottom);
  LCanvas.MoveTo(Rect.Left, Rect.Bottom - 1);
  LCanvas.LineTo(Rect.Right, Rect.Bottom - 1);

  LCanvas.Brush.Style := bsClear;
  LCanvas.Font.Name := TDevShellTheme.cFontName;
  LCanvas.Font.Size := cSettingsFontSize;
  LCanvas.Font.Style := [];
  LCanvas.Font.Color := LTheme.TextColor;
  var LNameRect := Rect;
  LNameRect.Left := LNameRect.Left +
    MulDiv(8, CurrentPPI, cDesignPPI);
  LNameRect.Right := LColumnDivider;
  DrawText(LCanvas.Handle, PChar(Item.Caption), Length(Item.Caption),
    LNameRect, DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);

  var LDescription := '';
  if Item.SubItems.Count > 0 then
    LDescription := Item.SubItems[0];
  var LDescriptionRect := Rect;
  LDescriptionRect.Left := LColumnDivider +
    MulDiv(8, CurrentPPI, cDesignPPI);
  DrawText(LCanvas.Handle, PChar(LDescription), Length(LDescription),
    LDescriptionRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or
      DT_NOPREFIX);
end;

procedure TFrmSettings.ButtonNewToolClick(Sender: TObject);
begin
  ClientDataSet1.Append;
  DBEditName.SetFocus;
end;

procedure TFrmSettings.ButtonDeleteToolClick(Sender: TObject);
begin
  if ClientDataSet1.IsEmpty then
    Exit;
  var LToolName := ClientDataSet1.FieldByName('Name').AsString;
  if MessageDlg(Format('Delete custom tool "%s"?', [LToolName]),
    mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    ClientDataSet1.Delete;
end;

procedure TFrmSettings.ConfigureTitleBar(const ATheme: TDevShellTheme);
begin
  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.Height := MulDiv(cSettingsTitleBarHeight, CurrentPPI,
    cDesignPPI);
  CustomTitleBar.SystemColors := False;
  CustomTitleBar.StyleColors := False;
  CustomTitleBar.SystemButtons := False;
  CustomTitleBar.ShowIcon := True;
  CustomTitleBar.Enabled := True;
  CustomTitleBar.BackgroundColor := ATheme.BackgroundColor;
  CustomTitleBar.ForegroundColor := ATheme.TextColor;
  CustomTitleBar.InactiveBackgroundColor := ATheme.BackgroundColor;
  CustomTitleBar.InactiveForegroundColor := ATheme.MutedColor;
  CustomTitleBar.ButtonBackgroundColor := ATheme.BackgroundColor;
  CustomTitleBar.ButtonForegroundColor := ATheme.TextColor;
  CustomTitleBar.ButtonHoverBackgroundColor := BlendColor(ATheme.AccentColor,
    ATheme.BackgroundColor, 0.82);
  CustomTitleBar.ButtonHoverForegroundColor := ATheme.TextColor;
  CustomTitleBar.ButtonPressedBackgroundColor := ATheme.AccentColor;
  CustomTitleBar.ButtonPressedForegroundColor := ATheme.TextColor;
  CustomTitleBar.ButtonInactiveBackgroundColor := ATheme.BackgroundColor;
  CustomTitleBar.ButtonInactiveForegroundColor := ATheme.MutedColor;
  TitleBarPanel1.Height := MulDiv(cSettingsTitleBarHeight, CurrentPPI,
    cDesignPPI);
  TitleBarPanel1.Invalidate;
end;

procedure TFrmSettings.ChromeBorderPaint(Sender: TObject);
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
    // Use the app style for the glyph/background and our palette for the text.
    TCustomCheckBox(AControl).StyleName := '';
    TCustomCheckBox(AControl).StyleElements :=
      TCustomCheckBox(AControl).StyleElements - [seFont];
    TControlAccess(AControl).Font.Color := ATheme.TextColor;
  end
  else if AControl is TDBLookupComboBox then
  begin
    TControlAccess(AControl).StyleElements :=
      TControlAccess(AControl).StyleElements - [seFont, seClient, seBorder];
    TControlAccess(AControl).Color := AInputColor;
    TControlAccess(AControl).Font.Color := ATheme.TextColor;
  end
  else if (AControl is TCustomEdit) or (AControl is TCustomComboBox) or
     (AControl is TCustomListView) or
     (AControl is TCustomGrid) then
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

  if AControl is TDBGrid then
  begin
    TDBGrid(AControl).FixedColor := BlendColor(ATheme.BackgroundColor,
      ATheme.TextColor, 0.12);
    TDBGrid(AControl).TitleFont.Color := ATheme.TextColor;
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
  EditCommonTaskExt.Color := LTheme.BackgroundColor;
  EditOpenDelphiExt.Color := LTheme.BackgroundColor;
  EditOpenLazarusExt.Color := LTheme.BackgroundColor;
  EditCheckSumExt.Color := LTheme.BackgroundColor;
  ConfigureTitleBar(LTheme);
  SideBar.Color := LTheme.BackgroundColor;
  SideBar.ItemColor := LTheme.BackgroundColor;
  SideBar.Font.Assign(Font);
  SideBar.Invalidate;
  ApplyDevShellThemeToButton(ButtonCancel, LTheme);
  ApplyDevShellThemeToButton(BtnInsertMacro, LTheme);
  var LApplyPalette := DevShellButtonPalette(LTheme);
  LApplyPalette.Border := LTheme.AccentColor;
  LApplyPalette.HotBorder := LTheme.AccentColor;
  LApplyPalette.PressedBorder := LTheme.AccentColor;
  LApplyPalette.FocusedBorder := LTheme.AccentColor;
  ButtonApply.ApplyPalette(LApplyPalette);
  ButtonApply.Font.Assign(Font);
  ButtonCancel.Font.Assign(Font);
  BtnInsertMacro.Font.Assign(Font);
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
  DBGrid1.FixedColor := LTheme.BackgroundColor;
  DBEditMenu.Color := LTheme.BackgroundColor;
  DBEditName.Color := LTheme.BackgroundColor;
  DBEditExtensions.Color := LTheme.BackgroundColor;
  DBMemoScript.Color := LTheme.BackgroundColor;
  DBComboBoxGroup.Color := LTheme.BackgroundColor;
  DBLookupComboBoxDelphi.Color := LTheme.BackgroundColor;
  DBComboBoxImage.Color := LTheme.BackgroundColor;
  ListViewMacros.Color := LTheme.BackgroundColor;
  TDBGridAccess(DBGrid1).DefaultRowHeight := MulDiv(cCustomListRowHeight,
    CurrentPPI, cDesignPPI);
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
begin
  var LButtonWidth := MulDiv(cFooterButtonWidth, CurrentPPI, cDesignPPI);
  var LButtonHeight := MulDiv(cFooterButtonHeight, CurrentPPI, cDesignPPI);
  var LButtonGap := MulDiv(cFooterButtonGap, CurrentPPI, cDesignPPI);
  var LRight := Panel2.ClientWidth -
    MulDiv(cFooterRightMargin, CurrentPPI, cDesignPPI);
  ButtonCancel.SetBounds(LRight - LButtonWidth,
    (Panel2.ClientHeight - LButtonHeight) div 2, LButtonWidth,
    LButtonHeight);
  ButtonApply.SetBounds(ButtonCancel.Left - LButtonGap - LButtonWidth,
    ButtonCancel.Top, LButtonWidth, LButtonHeight);
end;

procedure TFrmSettings.ConfigureSideBar;
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
  if not (csLoading in ComponentState) then
  begin
    ConfigureFooter;
    ConfigureSideBar;
    ConfigureMenuPage;
    ConfigureCustomToolsPage;
    ConfigureAboutPage;
    ApplySettingsTheme;
    ApplyProjectIcons;
  end;
end;

procedure TFrmSettings.SideBarAfterDrawItem(AIndex: Integer;
  ACanvas: TCanvas; ARect: TRect; AState: TOwnerDrawState);
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
    LFillColor := BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
      cSideBarSelectionFillBlend);
    LBorderColor := BlendColor(LTheme.TextColor, LTheme.BackgroundColor,
      cSideBarSelectionBorderBlend);
    LTextColor := LSelectionColor;
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
  var LItemRect := ARect;
  InflateRect(LItemRect, -MulDiv(2, CurrentPPI, 96),
    -MulDiv(2, CurrentPPI, 96));
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
  ACanvas.Font.Color := LTextColor;
  ACanvas.Brush.Style := bsClear;
  var LTextRect := LItemRect;
  LTextRect.Left := LIconRect.Right +
    MulDiv(cSideBarIconTextGap, CurrentPPI, 96);
  DrawText(ACanvas.Handle, PChar(cSideBarCaptions[AIndex]),
    Length(cSideBarCaptions[AIndex]), LTextRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
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
end;

procedure TFrmSettings.UpdateViewHeader(AIndex: Integer);
begin
  if (AIndex < cSideBarGeneral) or (AIndex > cSideBarAbout) then
    Exit;
  LabelViewTitle.Caption := cViewTitles[AIndex];
  LabelViewDescription.Caption := cViewDescriptions[AIndex];
end;

procedure TFrmSettings.BtnInsertMacroClick(Sender: TObject);
var
 sValue: string;
 iSelPos, iSelLen: Integer;
begin
 if ListViewMacros.Selected<>nil then
 begin
   //DBMemoScript.SelText:= ListViewMacros.Selected.Caption;
    sValue := DBMemoScript.Field.AsString;
    iSelPos := DBMemoScript.SelStart;
    iSelLen := DBMemoScript.SelLength;
    if iSelLen > 0 then
      Delete(sValue, iSelPos + 1, iSelLen);

    Insert(ListViewMacros.Selected.Caption, sValue, iSelPos + 1);
    if DBMemoScript.DataSource.State <> dsEdit then DBMemoScript.DataSource.Edit;
    DBMemoScript.Field.AsString := sValue;

 end;
end;

procedure TFrmSettings.ButtonApplyClick(Sender: TObject);
begin
  if MessageDlg('Do you want save the changes ?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin

    FSettings.SubMenuOpenCmdRAD := CheckBoxSubMenuOpenCmdRAD.Checked;
    FSettings.SubMenuLazarus    := CheckBoxSubMenuLazarus.Checked;
    FSettings.ShowInfoDProj     := CheckBoxShowInfoDProj.Checked;
    FSettings.ActivateLazarus   := CheckBoxActivateLazarus.Checked;
    FSettings.SubMenuCommonTasks   := CheckBoxSubMenuCommonTasks.Checked;
    FSettings.SubMenuMSBuild       := CheckBoxSubMenuMSBuild.Checked;
    FSettings.SubMenuMSBuildAnother:= CheckBoxSubMenuMSBuildAnother.Checked;
    FSettings.SubMenuOpenDelphi       := CheckBoxSubMenuOpenDelphi.Checked;
    FSettings.SubMenuRunTouch         := CheckBoxSubMenuRunTouch.Checked;
    FSettings.SubMenuFormat           := CheckBoxSubMenuFormat.Checked;
    FSettings.SubMenuCompileRC        := CheckBoxSubMenuCompileRC.Checked;
    FSettings.SubMenuOpenVclStyle        := CheckBoxSubMenuVCLStyles.Checked;
    FSettings.SubMenuOpenFMXStyle        := CheckBoxSubMenuFMXStyles.Checked;
    FSettings.CommonTaskExt              := EditCommonTaskExt.Text;
    FSettings.OpenDelphiExt              := EditOpenDelphiExt.Text;
    FSettings.OpenLazarusExt             := EditOpenLazarusExt.Text;
    FSettings.CheckSumExt                := EditCheckSumExt.Text;
    StoreTools(ClientDataSet1, FSettings.Document);
    WriteSettings(FSettings);
    Close();
    //LoadVCLStyle(ComboBoxVCLStyle.Text);

  end;
end;
procedure TFrmSettings.ButtonCancelClick(Sender: TObject);
begin
 Close();
end;

procedure TFrmSettings.ClientDataSet1AfterScroll(DataSet: TDataSet);
begin
  if ClientDataSet1.Active then
    if not StartsText('Delphi',
      ClientDataSet1.FieldByName('Group').AsString) and
      (ClientDataSet1.FieldByName('Review').AsString = '') then
    begin
      DBLookupComboBoxDelphi.Visible := False;
      LabelDelphi.Visible := False;
      DBComboBoxGroup.Width := MulDiv(cCustomNameLeft -
        cCustomEditorLeft - 10, CurrentPPI, cDesignPPI);
    end
    else
    begin
      DBLookupComboBoxDelphi.Visible := True;
      LabelDelphi.Visible := True;
      DBComboBoxGroup.Width := MulDiv(cCustomGroupWidth, CurrentPPI,
        cDesignPPI);
    end;
  if DBComboBoxImage.Items.Count > 0 then
    DBComboBoxImage.ItemIndex := DBComboBoxImage.Items.IndexOf(
      ClientDataSet1.FieldByName('Image').AsString);
end;

procedure TFrmSettings.NewCommand(Data: TDataSet);
begin
  Data.FieldByName('Id').AsString := 'command:' + TGUID.NewGuid.ToString;
  Data.FieldByName('VersionId').AsString := '*';
  Data.FieldByName('RunAs').AsBoolean := False;
  Data.FieldByName('Image').AsString := 'wrench';
end;

procedure TFrmSettings.DBComboBoxImageDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  LSource: TProjectIconSource;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LComboBox := TDBComboBox(Control);
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
  LCanvas.Font.Size := cSettingsFontSize;
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
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LComboBox := TDBComboBox(Control);
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
  LCanvas.Font.Size := cSettingsFontSize;
  LCanvas.Font.Color := LTheme.TextColor;

  if (Index < 0) or (Index >= LComboBox.Items.Count) then
    Exit;
  var LTextRect := Rect;
  LTextRect.Left := LTextRect.Left +
    MulDiv(cCustomInputPaddingX, CurrentPPI, cDesignPPI);
  LTextRect.Right := LTextRect.Right -
    MulDiv(cCustomInputPaddingX, CurrentPPI, cDesignPPI);
  var LCaption := LComboBox.Items[Index];
  DrawText(LCanvas.Handle, PChar(LCaption), Length(LCaption), LTextRect,
    DT_LEFT or DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS or DT_NOPREFIX);
end;

procedure TFrmSettings.MigrateCustomToolIconAssignments;
var
  LDescriptor: TProjectIconDescriptor;
begin
  ClientDataSet1.DisableControls;
  try
    ClientDataSet1.First;
    while not ClientDataSet1.Eof do
    begin
      var LIconKey := ClientDataSet1.FieldByName('Image').AsString;
      if not TryGetProjectIcon(LIconKey, LDescriptor) then
      begin
        LIconKey := DefaultCustomToolIconKey(
          ClientDataSet1.FieldByName('Name').AsString);
        ClientDataSet1.Edit;
        ClientDataSet1.FieldByName('Image').AsString := LIconKey;
        ClientDataSet1.Post;
      end;
      ClientDataSet1.Next;
    end;
    ClientDataSet1.First;
  finally
    ClientDataSet1.EnableControls;
  end;
end;

procedure TFrmSettings.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 // Only Apply writes the settings snapshot; Cancel and closing discard edits.
end;

procedure TFrmSettings.FormCreate(Sender: TObject);
begin
  Log('Settings FormCreate begin');
  FActiveSideBarIndex := cSideBarGeneral;
  FCustomToolButtonImages := TImageList.Create(Self);
  FMacroRowImages := TImageList.Create(Self);
  SideBar.OnAfterDrawItem := SideBarAfterDrawItem;
  SideBar.OnChange := SideBarChange;
  DBGrid1.OnDrawColumnCell := DBGridToolsDrawColumnCell;
  Log('Settings FormCreate configure controls');
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
  DBComboBoxGroup.DataField := 'Group';
  DBEditName.DataField := 'Name';
  DBEditMenu.DataField := 'Menu';
  DBEditExtensions.DataField := 'Extensions';
  DBMemoScript.DataField := 'Script';
  DBComboBoxImage.DataField := 'Image';
  DBCheckBoxRunAs.DataField := 'RunAs';
  DBLookupComboBoxDelphi.DataField := 'VersionId';
  DBLookupComboBoxDelphi.ListField := 'Name';
  DBLookupComboBoxDelphi.KeyField := 'VersionId';
  LabelDelphi.Caption := 'Minimum Delphi version';

  FSettings := TSettings.Create;
  Log('Settings FormCreate load settings');
  LoadSettings;
  LoadTools(ClientDataSet1, FSettings.Document);
  LoadVersionChoices(ClientDataSet2);
  ClientDataSet1.FieldByName('Id').Visible := False;
  ClientDataSet1.FieldByName('Script').Visible := False;
  ClientDataSet1.FieldByName('Review').ReadOnly := True;
  ClientDataSet1.FieldByName('Review').DisplayLabel := 'Assignment review';
  ClientDataSet1.FieldByName('VersionId').DisplayLabel := 'Minimum Delphi ID';
  for var LFieldName in ['Name', 'Group', 'Menu', 'Extensions', 'Image',
    'VersionId', 'Review'] do
    ClientDataSet1.FieldByName(LFieldName).DisplayWidth := 24;
  ClientDataSet1.OnNewRecord := NewCommand;
  var LReviewLabel := TLabel.Create(Self);
  LReviewLabel.Parent := PanelCustomTools;
  LReviewLabel.Align := alTop;
  LReviewLabel.WordWrap := True;
  LReviewLabel.Caption := 'Commands with an assignment review are disabled. ' +
    'Select their minimum Delphi version, then Apply.';
  LReviewLabel.Visible := False;
  ClientDataSet1.First;
  while not ClientDataSet1.Eof do
  begin
    if ClientDataSet1.FieldByName('Review').AsString <> '' then
      LReviewLabel.Visible := True;
    ClientDataSet1.Next;
  end;
  ClientDataSet1.First;

  ClientDataSet1.Open;
  ClientDataSet1.LogChanges := False;
  MigrateCustomToolIconAssignments;

  DBComboBoxImage.Items.Clear;
  for var LDescriptor in GetProjectIconDescriptors do
    DBComboBoxImage.Items.Add(LDescriptor.Key);
  DBComboBoxImage.ItemIndex := DBComboBoxImage.Items.IndexOf(
    ClientDataSet1.FieldByName('Image').AsString);

  LoadMacros;
  ConfigureCustomToolsPage;
  ActiveControl := nil;
  Log('Settings FormCreate end');
end;

procedure TFrmSettings.FormDestroy(Sender: TObject);
begin
  FSettings.Free;
end;

procedure TFrmSettings.LoadMacros;
var
  LocalFolder: TFileName;
  FileName: TFileName;
  XmlDoc: olevariant;
  Nodes: olevariant;
  lNodes, i: Integer;
  LItem: TListItem;
begin
  LocalFolder := GetDelphiDevShellToolsFolder;
  if LocalFolder <> '' then
  begin
    FileName := IncludeTrailingPathDelimiter(LocalFolder)+'macros.xml';
    if not FileExists(FileName) then Exit;
    begin
      XmlDoc := CreateOleObject('Msxml2.DOMDocument.6.0');
      try
        XmlDoc.Async := False;
        XmlDoc.Load(FileName);
        XmlDoc.SetProperty('SelectionLanguage', 'XPath');

        if (XmlDoc.parseError.errorCode <> 0) then
          raise Exception.CreateFmt('Error in Xml Data %s', [XmlDoc.parseError]);

        Nodes := XmlDoc.selectNodes('//Macros/Macro');
        lNodes:= Nodes.Length;
        for i:= 0 to lNodes-1 do
        begin
          LItem:=ListViewMacros.Items.Add;
          LItem.Caption:=Nodes.Item(i).getAttribute('name');
          LItem.SubItems.Add(Nodes.Item(i).getAttribute('description'));
        end;

      finally
        XmlDoc := Unassigned;
      end;
    end;
  end;
end;

procedure TFrmSettings.LoadSettings;
begin
  ReadSettings(FSettings);
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

end;

initialization
  RegisterClasses([TFlatPageControl, TFlatDBGrid, TDevShellLookupComboBox,
    TDevShellDBComboBox]);
  TCustomStyleEngine.RegisterStyleHook(TDevShellLookupComboBox,
    TDevShellLookupComboBoxStyleHook);

finalization
  TCustomStyleEngine.UnRegisterStyleHook(TDevShellLookupComboBox,
    TDevShellLookupComboBoxStyleHook);
  UnRegisterClass(TDevShellDBComboBox);
  UnRegisterClass(TDevShellLookupComboBox);
  UnRegisterClass(TFlatDBGrid);
  UnRegisterClass(TFlatPageControl);

end.
