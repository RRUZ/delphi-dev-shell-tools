{**************************************************************************************************}
{                                                                                                  }
{ GUIDelphiDevShell                                                                                }
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
{ The Original Code is GUIDelphiDevShell.pas.                                                      }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013 Rodrigo Ruz V.                         }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}

program GUIDelphiDevShell;

uses
  Vcl.Forms,
  Vcl.Dialogs,
  SysUtils,
  StrUtils,
  Windows,
  uAbout in 'uAbout.pas' {FrmAbout},
  uCheckUpdate in 'uCheckUpdate.pas' {FrmCheckUpdate},
  uWinInet in 'uWinInet.pas',
  uUpdatesChanges in 'uUpdatesChanges.pas' {FrmUpdateChanges},
  Vcl.Styles.WebBrowser in 'Vcl.Styles.WebBrowser.pas',
  uMiscGUI in 'uMiscGUI.pas',
  Vcl.Themes,
  Vcl.Styles,
  uSettings in 'uSettings.pas' {FrmSettings},
  uMisc in '..\units\uMisc.pas';

{$R *.res}

procedure OnlyOne;
var
    hWnd, hMutex : THandle;
    lpName      : PWideChar;
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
  OnlyOne;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  TStyleManager.TrySetStyle('Amakrits');
  if ParamCount>0 then
  begin
   if SameText('-about',ParamStr(1)) then
    Application.CreateForm(TFrmAbout, FrmAbout)
   else
   if SameText('-settings',ParamStr(1)) then
    Application.CreateForm(TFrmSettings, FrmSettings)
   else
    Application.CreateForm(TFrmAbout, FrmAbout);
  end
  else
    Application.CreateForm(TFrmAbout, FrmAbout);

  Application.Run;
end.
