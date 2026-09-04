program ShellTools.Tests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}

uses
  ShellTools.SettingsTests in 'ShellTools.SettingsTests.pas',
  DelphiDevShellTools.SettingsStore in '..\units\DelphiDevShellTools.SettingsStore.pas',
  ShellTools.ExecutionTests in 'ShellTools.ExecutionTests.pas',
  System.SysUtils,
  System.Win.ComObj,
  Winapi.ActiveX,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.Xml.NUnit,
  ShellTools.BasicTests in 'ShellTools.BasicTests.pas',
  ShellTools.RegistrationTests in 'ShellTools.RegistrationTests.pas',
  ShellTools.TestSupport in 'ShellTools.TestSupport.pas';

var
  Runner: ITestRunner;
  Results: IRunResults;
begin
  if (ParamCount >= 2) and SameText(ParamStr(1), '--argument-probe') then
  begin
    WriteArgumentProbe;
    Exit;
  end;
  try
    OleCheck(CoInitialize(nil));
    try
      TDUnitX.CheckCommandLine;
      TDUnitX.RegisterTestFixture(TBasicTests);
      TDUnitX.RegisterTestFixture(TExecutionTests);
      TDUnitX.RegisterTestFixture(TSettingsTests);
      if GetEnvironmentVariable('DDS_TEST_UNC_ROOT') <> '' then
        TDUnitX.RegisterTestFixture(TUNCExecutionTests);
      // This class intentionally has no TestFixture attribute: opt-in only.
      if GetEnvironmentVariable('DDS_TEST_REGISTRATION') = '1' then
        TDUnitX.RegisterTestFixture(TRegistrationTests);
      Runner := TDUnitX.CreateRunner;
      Runner.UseRTTI := True;
      Runner.FailsOnNoAsserts := True;
      Runner.AddLogger(TDUnitXConsoleLogger.Create(True));
      Runner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile));
      Results := Runner.Execute;
      if not Results.AllPassed then
        ExitCode := 1;
      Results := nil;
      Runner := nil;
    finally
      CoUninitialize;
    end;
  except
    on E: Exception do
    begin
      Writeln(E.ClassName, ': ', E.Message);
      ExitCode := 1;
    end;
  end;
end.
