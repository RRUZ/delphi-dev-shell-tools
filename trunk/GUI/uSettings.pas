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
  Vcl.Imaging.pngimage, Vcl.ComCtrls;

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
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ButtonCancelClick(Sender: TObject);
    procedure ButtonApplyClick(Sender: TObject);
  private
    FSettings: TSettings;
  public
    property Settings: TSettings Read FSettings Write FSettings;
    procedure LoadSettings;
  end;

var
  FrmSettings: TFrmSettings;

implementation

Uses
  uMiscGUI,
  System.UITypes;

{$R *.dfm}

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

procedure TFrmSettings.FormCreate(Sender: TObject);
begin
  FSettings:=TSettings.Create;
  LoadSettings;
end;

procedure TFrmSettings.FormDestroy(Sender: TObject);
begin
  FSettings.Free;
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
