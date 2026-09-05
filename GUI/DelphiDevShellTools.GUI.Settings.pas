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
  Datasnap.DBClient, Vcl.Grids, Vcl.DBGrids;

type
  TFrmSettings = class(TForm)
    CheckBoxSubMenuOpenCmdRAD: TCheckBox;
    Panel2: TPanel;
    ButtonApply: TButton;
    ButtonCancel: TButton;
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
    BtnInsertMacro: TButton;
    DBComboBoxGroup: TDBComboBox;
    LabelDelphi: TLabel;
    DBLookupComboBoxDelphi: TDBLookupComboBox;
    ClientDataSet2: TClientDataSet;
    DataSource2: TDataSource;
    DBGrid1: TDBGrid;
    DBComboBoxImage: TDBComboBox;
    Label14: TLabel;
    DBCheckBoxRunAs: TDBCheckBox;
    Image5: TImage;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonApplyClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnInsertMacroClick(Sender: TObject);
    procedure DBComboBoxImageDrawItem(Control: TWinControl; Index: Integer;
      Rect: TRect; State: TOwnerDrawState);
    procedure ClientDataSet1AfterScroll(DataSet: TDataSet);
  private
    FSettings: TSettings;
    procedure ApplyProjectIcons;
    procedure ApplyProjectIcon(AImage: TImage; const AKey: string;
      ALogicalSize: Integer; const ATheme: TDevShellTheme);
    procedure NewCommand(Data: TDataSet);
    procedure LoadMacros;
  protected
    procedure ChangeScale(AM, AD: Integer; AIsDpiChange: Boolean); override;
  public
    property Settings: TSettings Read FSettings Write FSettings;
    procedure LoadSettings;
  end;

var
  FrmSettings: TFrmSettings;

implementation

Uses
  DelphiDevShellTools.SettingsStore,
  DelphiDevShellTools.Icons,
  DelphiDevShellTools.GUI.MiscGUI,
  StrUtils,
  System.Types,
  System.UITypes,
  ComObj,
  IOUtils,
  MidasLib;

{$R *.dfm}

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

procedure TFrmSettings.ChangeScale(AM, AD: Integer; AIsDpiChange: Boolean);
begin
  inherited ChangeScale(AM, AD, AIsDpiChange);
  if not (csLoading in ComponentState) then
  begin
    DBComboBoxImage.ItemHeight := ImagePixelsForDpi(MenuImageLogicalSize,
      CurrentPPI) + 6;
    ApplyProjectIcons;
  end;
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
  if not StartsText('Delphi', ClientDataSet1.FieldByName('Group').AsString) and
     (ClientDataSet1.FieldByName('Review').AsString = '') then
  begin
    DBLookupComboBoxDelphi.Visible:=False;
    LabelDelphi.Visible:=False;
    DBComboBoxGroup.Width:=DBEditMenu.Width;
  end
  else
  begin
    DBLookupComboBoxDelphi.Visible:=True;
    LabelDelphi.Visible:=True;
    DBComboBoxGroup.Width:=110;
  end;
end;

procedure TFrmSettings.NewCommand(Data: TDataSet);
begin
  Data.FieldByName('Id').AsString := 'command:' + TGUID.NewGuid.ToString;
  Data.FieldByName('VersionId').AsString := '*';
  Data.FieldByName('RunAs').AsBoolean := False;
end;

procedure TFrmSettings.DBComboBoxImageDrawItem(Control: TWinControl;
  Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  BulletColor: TColor;
  IconHandle: HICON;
  IconFile: string;
  ImageRect: TRect;
  TargetSize: Integer;
begin
  TargetSize := ImagePixelsForDpi(MenuImageLogicalSize, CurrentPPI);
  var LTheme := TDevShellTheme.ActiveTheme;
  with TDBComboBox(Control).Canvas do
  begin
    FillRect(Rect);
    TextRect(Rect, Rect.Left + TargetSize + 6, Rect.Top + 1,
      ChangeFileExt(TDBComboBox(Control).Items[Index], ''));
    ImageRect := System.Types.Rect(Rect.Left + 3,
      Rect.Top + (Rect.Height - TargetSize) div 2, Rect.Left + 3 + TargetSize,
      Rect.Top + (Rect.Height - TargetSize) div 2 + TargetSize);
    if TryGetBulletColor(TDBComboBox(Control).Items[Index], LTheme,
      BulletColor) then
      DrawAntialiasedSphere(TDBComboBox(Control).Canvas, ImageRect,
        BulletColor, LTheme)
    else
    begin
      IconFile := GetDevShellToolsImagesFolder + TDBComboBox(Control).Items[Index];
      IconHandle := LoadIconFileAtSize(IconFile, TargetSize);
      if IconHandle <> 0 then
      try
        DrawIconEx(TDBComboBox(Control).Canvas.Handle, ImageRect.Left,
          ImageRect.Top, IconHandle, TargetSize, TargetSize, 0, 0, DI_NORMAL);
      finally
        DestroyIcon(IconHandle);
      end;
    end;
  end;
end;

procedure TFrmSettings.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 // Only Apply writes the settings snapshot; Cancel and closing discard edits.
end;

procedure TFrmSettings.FormCreate(Sender: TObject);
var
 s: string;
 ReviewLabel: TLabel;
begin
  DBComboBoxImage.ItemHeight := ImagePixelsForDpi(MenuImageLogicalSize, CurrentPPI) + 6;
  ApplyProjectIcons;
  DBComboBoxGroup.DataField:='Group';
  DBEditName.DataField:='Name';
  DBEditMenu.DataField:='Menu';
  DBEditExtensions.DataField:='Extensions';
  DBMemoScript.DataField:='Script';
  DBComboBoxImage.DataField:='Image';
  DBCheckBoxRunAs.DataField:='RunAs';
  DBLookupComboBoxDelphi.DataField:='VersionId';
  DBLookupComboBoxDelphi.ListField:='Name';
  DBLookupComboBoxDelphi.KeyField:='VersionId';
  LabelDelphi.Caption := 'Minimum Delphi';

  FSettings := TSettings.Create;
  LoadSettings;
  LoadTools(ClientDataSet1, FSettings.Document);
  LoadVersionChoices(ClientDataSet2);
  ClientDataSet1.FieldByName('Id').Visible := False;
  ClientDataSet1.FieldByName('Script').Visible := False;
  ClientDataSet1.FieldByName('Review').ReadOnly := True;
  ClientDataSet1.FieldByName('Review').DisplayLabel := 'Assignment review';
  ClientDataSet1.FieldByName('VersionId').DisplayLabel := 'Minimum Delphi ID';
  for s in ['Name', 'Group', 'Menu', 'Extensions', 'Image', 'VersionId', 'Review'] do
    ClientDataSet1.FieldByName(s).DisplayWidth := 24;
  ClientDataSet1.OnNewRecord := NewCommand;
  ReviewLabel := TLabel.Create(Self);
  ReviewLabel.Parent := TabSheet3;
  ReviewLabel.Align := alTop;
  ReviewLabel.WordWrap := True;
  ReviewLabel.Caption := 'Commands with an assignment review are disabled. Select their minimum Delphi version, then Apply.';
  ReviewLabel.Visible := False;
  ClientDataSet1.First;
  while not ClientDataSet1.Eof do
  begin
    if ClientDataSet1.FieldByName('Review').AsString <> '' then ReviewLabel.Visible := True;
    ClientDataSet1.Next;
  end;
  ClientDataSet1.First;

  ClientDataSet1.Open;
  ClientDataSet1.LogChanges:=False;

  for s in TDirectory.GetFiles(GetDevShellToolsImagesFolder,'*.ico') do
    DBComboBoxImage.Items.Add(ExtractFileName(s));
  AddBuiltInBulletIconNames(DBComboBoxImage.Items);


  LoadMacros;

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


end.
