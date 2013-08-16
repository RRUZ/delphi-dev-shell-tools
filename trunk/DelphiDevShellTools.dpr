library DelphiDevShellTools;

uses
  EMemLeaks,
  EResLeaks,
  EDialogWinAPIMSClassic,
  EDialogWinAPIEurekaLogDetailed,
  EDialogWinAPIStepsToReproduce,
  EDebugExports,
  ExceptionLog7,
  ComServ,
  DelphiDevShellTools_TLB in 'DelphiDevShellTools_TLB.pas',
  DelphiDevShellToolsImpl in 'DelphiDevShellToolsImpl.pas' {CloudUploadImpl: CoClass},
  uDelphiVersions in 'units\uDelphiVersions.pas',
  uMisc in 'units\uMisc.pas',
  uRegistry in 'units\uRegistry.pas',
  uSupportedIDEs in 'units\uSupportedIDEs.pas';

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer,
  DllInstall;

{$R *.TLB}

{$R *.RES}
{
TODO :
  detect delphi version.     DONE


  settings app


  open with delphi N...   DONE
  compile
  compile and run
  msbuild  DONE
  msbuild and run (use bat)

  build
  opt
    ms build release x86
    ms build debug x86
    ms build release x64
    ms build debug  x86


  common
   crc, sha1 calculation
   copy path to clipboard
   copy full filename (Path + FileName) to clipboard
   open in notepad
   open cmd here
}


//Debugging with the Shell
//http://msdn.microsoft.com/en-us/library/windows/desktop/cc144064%28v=vs.85%29.aspx
//The Complete Idiot's Guide to Writing Shell Extensions
//http://www.codeproject.com/Articles/441/The-Complete-Idiot-s-Guide-to-Writing-Shell-Extens

begin
end.
