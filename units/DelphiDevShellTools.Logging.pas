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

procedure Log(const Msg: string); {$IFNDEF ENABLELOG}inline;{$ENDIF}

implementation

{$IFDEF ENABLELOG}
uses Winapi.Windows, System.SysUtils, System.IOUtils;
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

end.
