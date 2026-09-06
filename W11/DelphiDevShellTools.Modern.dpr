library DelphiDevShellToolsModern;

uses
  System.Win.ComServ,
  DelphiDevShellTools.Modern.SettingsCommand in 'DelphiDevShellTools.Modern.SettingsCommand.pas',
  DelphiDevShellTools.Commands in '..\units\DelphiDevShellTools.Commands.pas',
  DelphiDevShellTools.Execution in '..\units\DelphiDevShellTools.Execution.pas',
  DelphiDevShellTools.Installations in '..\units\DelphiDevShellTools.Installations.pas';

{$R 'ModernResources.res' 'ModernResources.rc'}

// Package COM activation only. Never register or unregister the classic handler.
exports
  DllGetClassObject,
  DllCanUnloadNow;

begin
end.
