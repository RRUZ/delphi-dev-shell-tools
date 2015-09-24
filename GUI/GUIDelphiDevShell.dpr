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
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2015 Rodrigo Ruz V.                    }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}

program GUIDelphiDevShell;

uses
  {$IFDEF DEBUG}
  {$ENDIF }
  Vcl.Forms,
  Vcl.Dialogs,
  SysUtils,
  StrUtils,
  Windows,
  uAbout in 'uAbout.pas' {FrmAbout},
  uMiscGUI in 'uMiscGUI.pas',
  Vcl.Themes,
  Vcl.Styles,
  uSettings in 'uSettings.pas' {FrmSettings},
  uMisc in '..\units\uMisc.pas',
  uCheckSum in 'uCheckSum.pas' {FrmCheckSum},
  Vcl.Styles.Utils.Menus in 'Vcl.Styles.Utils.Menus.pas';

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
  if (ParamCount>0) and MatchText(ParamStr(1),['-settings','-about']) then
  OnlyOne;

  Application.Initialize;
  Application.MainFormOnTaskbar := True;
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
