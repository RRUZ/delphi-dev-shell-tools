program ShellTools.Tests;

{$APPTYPE CONSOLE}
{$STRONGLINKTYPES ON}
{$R '..\GUI\GUIResources.res'}

uses
  ShellTools.SettingsFormTests in 'ShellTools.SettingsFormTests.pas',
  ShellTools.DialogTests in 'ShellTools.DialogTests.pas',
  DelphiDevShellTools.GUI.PaletteDialog in '..\GUI\DelphiDevShellTools.GUI.PaletteDialog.pas',
  DelphiDevShellTools.GUI.ExtensionDialog in '..\GUI\DelphiDevShellTools.GUI.ExtensionDialog.pas',
  DelphiDevShellTools.GUI.CheckSum in '..\GUI\DelphiDevShellTools.GUI.CheckSum.pas',
  DelphiDevShellTools.GUI.Settings in '..\GUI\DelphiDevShellTools.GUI.Settings.pas',
  DelphiDevShellTools.GUI.MiscGUI in '..\GUI\DelphiDevShellTools.GUI.MiscGUI.pas',
  ShellTools.SettingsModelTests in 'ShellTools.SettingsModelTests.pas',
  DelphiDevShellTools.GUI.SettingsModel in '..\GUI\DelphiDevShellTools.GUI.SettingsModel.pas',
  ShellTools.CheckBoxTests in 'ShellTools.CheckBoxTests.pas',
  ShellTools.ScrollBarTests in 'ShellTools.ScrollBarTests.pas',
  ShellTools.ComboBoxTests in 'ShellTools.ComboBoxTests.pas',
  ShellTools.LoggingTests in 'ShellTools.LoggingTests.pas',
  DelphiDevShellTools.Logging in '..\units\DelphiDevShellTools.Logging.pas',
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
  ShellTools.IconTests in 'ShellTools.IconTests.pas',
  DelphiDevShellTools.Misc in '..\units\DelphiDevShellTools.Misc.pas',
  DelphiDevShellTools.UI in '..\units\DelphiDevShellTools.UI.pas',
  DelphiDevShellTools.Phosphor.Font in '..\units\DelphiDevShellTools.Phosphor.Font.pas',
  DelphiDevShellTools.Phosphor.Names in '..\units\DelphiDevShellTools.Phosphor.Names.pas',
  DelphiDevShellTools.Icons in '..\units\DelphiDevShellTools.Icons.pas',
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
      TDUnitX.RegisterTestFixture(TComboBoxTests);
      TDUnitX.RegisterTestFixture(TCheckBoxTests);
      TDUnitX.RegisterTestFixture(TScrollBarTests);
      TDUnitX.RegisterTestFixture(TBasicTests);
      TDUnitX.RegisterTestFixture(TIconTests);
      TDUnitX.RegisterTestFixture(TLoggingTests);
      TDUnitX.RegisterTestFixture(TExecutionTests);
      TDUnitX.RegisterTestFixture(TSettingsTests);
      TDUnitX.RegisterTestFixture(TSettingsModelTests);
      TDUnitX.RegisterTestFixture(TSettingsFormTests);
      TDUnitX.RegisterTestFixture(TDialogTests);
      if GetEnvironmentVariable('DDS_TEST_UNC_ROOT') <> '' then
        TDUnitX.RegisterTestFixture(TUNCExecutionTests);
      // This class intentionally has no TestFixture attribute: opt-in only.
      if GetEnvironmentVariable('DDS_TEST_REGISTRATION') = '1' then
        TDUnitX.RegisterTestFixture(TRegistrationTests);
      Runner := TDUnitX.CreateRunner;
      Runner.UseRTTI := True;
      Runner.FailsOnNoAsserts := True;
      Runner.AddLogger(TDUnitXConsoleLogger.Create(GetEnvironmentVariable('DDS_TEST_VERBOSE') <> '1'));
      Runner.AddLogger(TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile));
      RunWithIsolatedSettings(
        procedure
        begin
          Results := Runner.Execute;
        end);
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
