{**************************************************************************************************}
{                                                                                                  }
{ GUIDelphiDevShell                                                                                }
{ unit for the Delphi Dev Shell Tools                                                              }
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
{ The Original Code is GUIDelphiDevShell.pas.                                                      }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2021 Rodrigo Ruz V.                    }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}

program GUIDelphiDevShell;

uses
  DelphiDevShellTools.Logging in '..\units\DelphiDevShellTools.Logging.pas',
  DelphiDevShellTools.SettingsStore in '..\units\DelphiDevShellTools.SettingsStore.pas',
  {$IFDEF DEBUG}
  {$ENDIF }
  DelphiDevShellTools.Commands in '..\units\DelphiDevShellTools.Commands.pas',
  DelphiDevShellTools.Installations in '..\units\DelphiDevShellTools.Installations.pas',
  DelphiDevShellTools.Execution in '..\units\DelphiDevShellTools.Execution.pas',
  DelphiDevShellTools.DelphiVersions in '..\units\DelphiDevShellTools.DelphiVersions.pas',
  DelphiDevShellTools.GUI.Execution in 'DelphiDevShellTools.GUI.Execution.pas',
  Vcl.Forms,
  Vcl.Dialogs,
  SysUtils,
  StrUtils,
  Windows,
  DelphiDevShellTools.GUI.About in 'DelphiDevShellTools.GUI.About.pas' {FrmAbout},
  DelphiDevShellTools.GUI.MiscGUI in 'DelphiDevShellTools.GUI.MiscGUI.pas',
  Vcl.Themes,
  Vcl.Styles,
  DelphiDevShellTools.GUI.Settings in 'DelphiDevShellTools.GUI.Settings.pas' {FrmSettings},
  DelphiDevShellTools.Misc in '..\units\DelphiDevShellTools.Misc.pas',
  DelphiDevShellTools.UI in '..\units\DelphiDevShellTools.UI.pas',
  DelphiDevShellTools.Phosphor.Font in '..\units\DelphiDevShellTools.Phosphor.Font.pas',
  DelphiDevShellTools.Phosphor.Names in '..\units\DelphiDevShellTools.Phosphor.Names.pas',
  DelphiDevShellTools.Icons in '..\units\DelphiDevShellTools.Icons.pas',
  DelphiDevShellTools.GUI.CheckSum in 'DelphiDevShellTools.GUI.CheckSum.pas' {FrmCheckSum};

{$R 'GUIResources.res' 'GUIResources.rc'}
{$R 'GUIManifest.res' 'GUIManifest.rc'}

procedure OnlyOne;
var
    hWnd, hMutex: THandle;
    lpName: PWideChar;
begin
  lpName := PWideChar(Application.Title);
  hMutex := CreateMutex (nil, FALSE, lpName );
  if WaitForSingleObject (hMutex, 0) = wait_TimeOut then
  begin
     SetWindowText(Application.Handle,'');
     hWnd := FindWindow(nil,lpName);
     if hWnd<>0 then
     begin
        if IsIconic(hWnd) then ShowWindow(hWnd, SW_RESTORE);
        BringWindowToTop(hWnd);
        SetForegroundWindow(hWnd);
     end;
     Application.ShowMainForm := False;
     Application.Terminate;
     Halt(0);
  end;
end;


begin
  if (ParamCount>0) and MatchText(ParamStr(1),['-settings','-about']) then
  OnlyOne;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  if (ParamCount = 2) and SameText(ParamStr(1), '--execute') then
  begin
    ExitCode := RunCommandRequest(ParamStr(2));
    Exit;
  end;
  //TStyleManager.TrySetStyle('Jet');
  if ParamCount>0 then
  begin
   if SameText('-about',ParamStr(1)) then
    Application.CreateForm(TFrmAbout, FrmAbout)
   else
   if MatchText(ParamStr(1),['CRC32', 'SHA1', 'MD4', 'MD5', 'SHA-256', 'SHA-384', 'SHA-512']) then
   begin
    Application.CreateForm(TFrmCheckSum, FrmCheckSum);
    FrmCheckSum.CheckSumAlgo:=ParamStr(1);
    FrmCheckSum.FileName:=ParamStr(2);
   end
   else
   if SameText('-settings', ParamStr(1)) then
    Application.CreateForm(TFrmSettings, FrmSettings)
   else
    Application.CreateForm(TFrmAbout, FrmAbout);
  end
  else
    Application.CreateForm(TFrmAbout, FrmAbout);

  Application.Run;
end.
