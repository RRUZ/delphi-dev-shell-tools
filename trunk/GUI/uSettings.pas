{**************************************************************************************************}
{                                                                                                  }
{ Unit uSettings                                                                                   }
{ unit for the Delphi Dev Shell Tools                                                              }
{ http://code.google.com/p/delphi-dev-shell-tools/                                                 }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is uSettings.pas.                                                              }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013 Rodrigo Ruz V.                         }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}
unit uSettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls, uMisc,
  Vcl.Imaging.pngimage, Vcl.ComCtrls, Vcl.DBCtrls, Vcl.Mask, Data.DB,
  Datasnap.DBClient;

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
    RadioButtonCheckUpdates: TRadioButton;
    RadioButtonNoCheckUpdates: TRadioButton;
    Label1: TLabel;
    Label2: TLabel;
    EditCommonTaskExt: TEdit;
    EditOpenDelphiExt: TEdit;
    Label3: TLabel;
    Label4: TLabel;
    EditOpenLazarusExt: TEdit;
    Label5: TLabel;
    EditFormatPascalExt: TEdit;
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
    Label13: TLabel;
    DBLookupComboBoxDelphi: TDBLookupComboBox;
    ClientDataSet2: TClientDataSet;
    DataSource2: TDataSource;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonApplyClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure BtnInsertMacroClick(Sender: TObject);
    procedure DBComboBoxGroupChange(Sender: TObject);
  private
    FSettings: TSettings;
    procedure CreateStructure;
    procedure LoadMacros;
  public
    property Settings: TSettings Read FSettings Write FSettings;
    procedure LoadSettings;
  end;

var
  FrmSettings: TFrmSettings;

implementation

Uses
  uMiscGUI,
  StrUtils,
  ComObj,
  IOUtils,
  MidasLib,
  System.UITypes;

{$R *.dfm}

procedure TFrmSettings.BtnInsertMacroClick(Sender: TObject);
var
 sValue : string;
 iSelPos, iSelLen : Integer;
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
    FSettings.CheckForUpdates            := RadioButtonCheckUpdates.Checked;
    FSettings.CommonTaskExt              := EditCommonTaskExt.Text;
    FSettings.FormatPascalExt            := EditFormatPascalExt.Text;
    FSettings.OpenDelphiExt              := EditOpenDelphiExt.Text;
    FSettings.OpenLazarusExt             := EditOpenLazarusExt.Text;
    FSettings.CheckSumExt                := EditCheckSumExt.Text;

    WriteSettings(FSettings);
    Close();
    //LoadVCLStyle(ComboBoxVCLStyle.Text);

  end;
end;
procedure TFrmSettings.ButtonCancelClick(Sender: TObject);
begin
 Close();
end;

procedure TFrmSettings.CreateStructure;
begin
  if ClientDataSet1.Active then ClientDataSet1.Close;
  ClientDataSet1.FieldDefs.Clear;
  ClientDataSet1.FieldDefs.Add('Name', ftString, 40, True);
  ClientDataSet1.FieldDefs.Add('Group', ftString, 40, True);
  ClientDataSet1.FieldDefs.Add('Menu', ftString, 100, True);
  ClientDataSet1.FieldDefs.Add('Extensions', ftString, 512, True);
  ClientDataSet1.FieldDefs.Add('Script', ftString, 4096, True);

  ClientDataSet1.IndexDefs.Add('Name','Name',[ixPrimary, ixUnique, ixCaseInsensitive]);
  ClientDataSet1.IndexName:='Name';
  ClientDataSet1.CreateDataSet;
end;

procedure TFrmSettings.DBComboBoxGroupChange(Sender: TObject);
begin
{
 if ClientDataSet1.Active then
  if not StartsText('Delphi', ClientDataSet1.FieldByName('Group').AsString) then
    DBLookupComboBoxDelphi.Enabled:=False
  else
    DBLookupComboBoxDelphi.Enabled:=True;
}
end;

function GetDevShellToolsDbName : String;
begin
 Result:=GetDelphiDevShellToolsFolder + 'Tools.db';
end;

function GetDevShellToolsDbDelphi : String;
begin
 Result:=GetDelphiDevShellToolsFolder + 'DelphiVersions.db';
end;

function ExistevShellToolsDb : Boolean;
begin
  Result:=TFile.Exists(GetDevShellToolsDbName);
end;

procedure TFrmSettings.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 ClientDataSet1.SaveToFile(GetDevShellToolsDbName, dfXML);

end;

procedure TFrmSettings.FormCreate(Sender: TObject);
begin
  DBComboBoxGroup.DataField:='Group';
  DBEditName.DataField:='Name';
  DBEditMenu.DataField:='Menu';
  DBEditExtensions.DataField:='Extensions';
  DBMemoScript.DataField:='Script';

  DBLookupComboBoxDelphi.DataField:='DelphiVersion';
  DBLookupComboBoxDelphi.ListField:='Name';
  DBLookupComboBoxDelphi.KeyField:='Version';

  if not ExistevShellToolsDb then
    CreateStructure
  else
  begin
    ClientDataSet1.LoadFromFile(GetDevShellToolsDbName);
    ClientDataSet1.IndexDefs.Add('Name','Name',[ixPrimary, ixUnique, ixCaseInsensitive]);
    ClientDataSet1.IndexName:='Name';
  end;

  ClientDataSet2.LoadFromFile(GetDevShellToolsDbDelphi);
  ClientDataSet2.Open;

  ClientDataSet1.Open;
  ClientDataSet1.LogChanges:=False;
   {
  ClientDataSet1.DisableControls;
  try
    while not ClientDataSet1.eof do
    begin
     DBComboBoxGroup.Items.Add(ClientDataSet1.FieldByName('Group').AsString);
     ClientDataSet1.Next;
    end;
    ClientDataSet1.First;
  finally
    ClientDataSet1.EnableControls;
  end;
      }


  LoadMacros;
  FSettings:=TSettings.Create;
  LoadSettings;
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
  lNodes, i : Integer;
  LItem : TListItem;
begin
  LocalFolder := GetDelphiDevShellToolsFolder;
  if LocalFolder <> '' then
  begin
    FileName := IncludeTrailingPathDelimiter(LocalFolder)+'macros.xml';
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
  RadioButtonCheckUpdates.Checked := FSettings.CheckForUpdates;
  EditCommonTaskExt.Text          := FSettings.CommonTaskExt;
  EditFormatPascalExt.Text        := FSettings.FormatPascalExt;
  EditOpenDelphiExt.Text          := FSettings.OpenDelphiExt;
  EditOpenLazarusExt.Text         := FSettings.OpenLazarusExt;
  EditCheckSumExt.Text            := FSettings.CheckSumExt;

  if not FSettings.CheckForUpdates then
   RadioButtonNoCheckUpdates.Checked:=True;

end;



end.
