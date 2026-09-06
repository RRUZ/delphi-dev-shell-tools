{**************************************************************************************************}
{                                                                                                  }
{ DelphiDevShellTools.GUI.SettingsHost                                                             }
{ Standalone development host for DelphiDevShellTools.GUI.Settings.                                }
{ https://github.com/RRUZ/delphi-dev-shell-tools                                                   }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is DelphiDevShellTools.GUI.SettingsHost.dpr.                                   }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.                    }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}

program DelphiDevShellToolsGUISettingsHost;

uses
  Winapi.Windows,
  System.SysUtils,
  Vcl.Forms,
  DelphiDevShellTools.Logging in '..\units\DelphiDevShellTools.Logging.pas',
  DelphiDevShellTools.UI in '..\units\DelphiDevShellTools.UI.pas',
  DelphiDevShellTools.GUI.Settings in 'DelphiDevShellTools.GUI.Settings.pas' {FrmSettings};

{$R 'GUIResources.res' 'GUIResources.rc'}
{$R 'GUIManifest.res' 'GUIManifest.rc'}

procedure SelectSettingsView(const AViewName: string);
begin
  if SameText(AViewName, 'menu') then
    FrmSettings.SideBar.ItemIndex := 1
  else if SameText(AViewName, 'custom-tools') then
    FrmSettings.SideBar.ItemIndex := 2
  else if SameText(AViewName, 'about') then
    FrmSettings.SideBar.ItemIndex := 3;
end;

procedure SelectCustomTool(const AToolName: string);
begin
  if (AToolName <> '') and FrmSettings.ClientDataSet1.Active then
    FrmSettings.ClientDataSet1.Locate('Name', AToolName, []);
end;

begin
  Log('SettingsHost initialize');
  Application.Initialize;
  ActivateSettingsVclStyle;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Delphi Dev. Shell Tools Settings Host';
  Log('SettingsHost create form');
  Application.CreateForm(TFrmSettings, FrmSettings);
  Log('SettingsHost form created');
  if (ParamCount >= 2) and SameText(ParamStr(1), '--capture') then
  begin
    Log('SettingsHost configure capture view');
    if ParamCount >= 3 then
      SelectSettingsView(ParamStr(3));
    if (ParamCount >= 4) and SameText(ParamStr(3), 'custom-tools') then
      SelectCustomTool(ParamStr(4));
    Log('SettingsHost show capture form');
    FrmSettings.Show;
    Log('SettingsHost form shown');
    Application.ProcessMessages;
    Log('SettingsHost messages processed');
    if (ParamCount >= 5) and SameText(ParamStr(3), 'custom-tools') and
       SameText(ParamStr(5), 'open-icons') then
    begin
      FrmSettings.DBComboBoxImage.SetFocus;
      FrmSettings.DBComboBoxImage.DroppedDown := True;
      Application.ProcessMessages;
    end;
    FrmSettings.Update;
    Log('SettingsHost form updated');
    Sleep(100);
    Application.ProcessMessages;
    Log('SettingsHost capture window');
    if not CaptureWindowScreenshot(FrmSettings.Handle, ParamStr(2)) then
      Halt(1);
    Log('SettingsHost capture saved');
    FrmSettings.Close;
    Log('SettingsHost form closed');
  end
  else
  begin
    if (ParamCount >= 2) and SameText(ParamStr(1), '--view') then
      SelectSettingsView(ParamStr(2));
    if (ParamCount >= 3) and SameText(ParamStr(2), 'custom-tools') then
      SelectCustomTool(ParamStr(3));
    Application.Run;
  end;
end.
