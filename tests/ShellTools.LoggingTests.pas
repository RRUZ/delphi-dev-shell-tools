//**************************************************************************************************
//
// Unit ShellTools.LoggingTests
// Tests conditional diagnostic output and safe handling of unavailable log files.
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
// The Original Code is ShellTools.LoggingTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.LoggingTests;

interface

uses DUnitX.TestFramework;

type
  [TestFixture]
  TLoggingTests = class
  private
    FDirectory, FPreviousTemp, FPreviousTmp: string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure WritesOnlyWhenEnabled;
    [Test] procedure UnavailableLogDoesNotRaise;
  end;

implementation

uses Winapi.Windows, System.SysUtils, System.IOUtils, DelphiDevShellTools.Logging;

procedure TLoggingTests.Setup;
begin
  FDirectory := TPath.Combine(TPath.GetTempPath, 'ShellLogging-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FDirectory);
  FPreviousTemp := GetEnvironmentVariable('TEMP');
  FPreviousTmp := GetEnvironmentVariable('TMP');
  Winapi.Windows.SetEnvironmentVariable('TEMP', PChar(FDirectory));
  Winapi.Windows.SetEnvironmentVariable('TMP', PChar(FDirectory));
end;

procedure TLoggingTests.TearDown;
begin
  if FPreviousTemp = '' then Winapi.Windows.SetEnvironmentVariable('TEMP', nil)
  else Winapi.Windows.SetEnvironmentVariable('TEMP', PChar(FPreviousTemp));
  if FPreviousTmp = '' then Winapi.Windows.SetEnvironmentVariable('TMP', nil)
  else Winapi.Windows.SetEnvironmentVariable('TMP', PChar(FPreviousTmp));
  // Only remove the private directory created by this test.
  TDirectory.Delete(FDirectory, True);
end;

procedure TLoggingTests.WritesOnlyWhenEnabled;
const
  MessageText = 'Logging test ' + #$03A9;
var
  FileName: string;
  {$IF Defined(ENABLELOG) and Defined(DEBUG) and not Defined(RELEASE)}
  Contents: string;
  {$IFEND}
begin
  FileName := TPath.Combine(FDirectory, 'shelllog.txt');
  DelphiDevShellTools.Logging.Log(MessageText);
  {$IF Defined(ENABLELOG) and Defined(DEBUG) and not Defined(RELEASE)}
  Assert.IsTrue(TFile.Exists(FileName), 'Enabled diagnostics must create the log');
  Contents := TFile.ReadAllText(FileName);
  Assert.IsTrue(Contents.Contains(MessageText), 'Preserve Unicode messages');
  Assert.IsTrue(Contents.Contains(Format(' pid=%d tid=%d ', [GetCurrentProcessId, GetCurrentThreadId])));
  DelphiDevShellTools.Logging.Log('Second entry');
  Assert.AreEqual<NativeInt>(2, Length(TFile.ReadAllLines(FileName)), 'Append without replacing earlier entries');
  {$ELSE}
  Assert.IsFalse(TFile.Exists(FileName), 'Disabled diagnostics must not create a log');
  TFile.WriteAllText(FileName, 'Existing content');
  DelphiDevShellTools.Logging.Log(MessageText);
  Assert.AreEqual('Existing content', TFile.ReadAllText(FileName), 'Disabled diagnostics must not modify an existing log');
  {$IFEND}
end;

procedure TLoggingTests.UnavailableLogDoesNotRaise;
var FileName: string;
begin
  FileName := TPath.Combine(FDirectory, 'shelllog.txt');
  TDirectory.CreateDirectory(FileName);
  DelphiDevShellTools.Logging.Log('Cannot append to a directory');
  Assert.IsTrue(TDirectory.Exists(FileName), 'Logging must tolerate an unavailable output file');
end;

end.
