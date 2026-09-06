//**************************************************************************************************
//
// Unit DelphiDevShellTools.Logging
// Conditional file diagnostics with timestamps and process/thread identifiers.
// ENABLELOG enables Debug logging; Release builds always disable it.
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
// The Original Code is DelphiDevShellTools.Logging.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.Logging;

// Release takes precedence even if DEBUG and ENABLELOG are inherited together.
{$IF Defined(RELEASE) or not Defined(DEBUG)}
  {$UNDEF ENABLELOG}
{$IFEND}

interface

uses
  Winapi.Windows;

procedure Log(const Msg: string); {$IFNDEF ENABLELOG}inline;{$ENDIF}
function CaptureWindowScreenshot(AWindow: HWND;
  const AFileName: string): Boolean; {$IFNDEF ENABLELOG}inline;{$ENDIF}

implementation

{$IFDEF ENABLELOG}
uses
  System.SysUtils,
  System.IOUtils,
  Vcl.Graphics,
  Vcl.Imaging.pngimage;
{$ENDIF}

procedure Log(const Msg: string);
begin
  {$IFDEF ENABLELOG}
  try
    TFile.AppendAllText(TPath.Combine(TPath.GetTempPath, 'shelllog.txt'),
      FormatDateTime('yyyy-mm-dd hh:nn:ss.zzz', Now) +
      Format(' pid=%d tid=%d ', [GetCurrentProcessId, GetCurrentThreadId]) + Msg + sLineBreak);
  except
    // Diagnostics must never interrupt Explorer if the file is unavailable.
  end;
  {$ENDIF}
end;

function CaptureWindowScreenshot(AWindow: HWND;
  const AFileName: string): Boolean;
{$IFDEF ENABLELOG}
var
  LWindowRect: TRect;
{$ENDIF}
begin
  Result := False;
  {$IFDEF ENABLELOG}
  try
    if (AWindow = 0) or not GetWindowRect(AWindow, LWindowRect) then
      Exit;
    var LWidth := LWindowRect.Right - LWindowRect.Left;
    var LHeight := LWindowRect.Bottom - LWindowRect.Top;
    if (LWidth <= 0) or (LHeight <= 0) then
      Exit;

    var LBitmap := TBitmap.Create;
    try
      LBitmap.PixelFormat := pf32bit;
      LBitmap.SetSize(LWidth, LHeight);
      var LWindowDC := GetWindowDC(AWindow);
      if LWindowDC = 0 then
        Exit;
      try
        if not BitBlt(LBitmap.Canvas.Handle, 0, 0, LWidth, LHeight,
          LWindowDC, 0, 0, SRCCOPY) then
          Exit;
      finally
        ReleaseDC(AWindow, LWindowDC);
      end;

      var LDirectory := ExtractFileDir(AFileName);
      if LDirectory <> '' then
        TDirectory.CreateDirectory(LDirectory);
      var LPng := TPngImage.Create;
      try
        LPng.Assign(LBitmap);
        LPng.SaveToFile(AFileName);
      finally
        LPng.Free;
      end;
      Result := True;
    finally
      LBitmap.Free;
    end;
  except
    on LException: Exception do
      Log('CaptureWindowScreenshot failed: ' + LException.Message);
  end;
  {$ENDIF}
end;

end.
