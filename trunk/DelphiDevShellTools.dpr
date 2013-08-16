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


  open with delphi N...
  compile
  compile and run
  msbuild
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


{



    if a .dproj file exists -> read \project\PropertyGroup\ProjectVersion
        empty -> Delphi 2007
        12.0 -> Delphi 2009 or 2010
        12.2 or 12.3 -> Delphi XE1 (according to Uwe Schuster)
        13.4 -> Delphi XE2
        14.3 -> XE3
        14.6 -> XE4

    if a .bdsproj file exists -> Delphi 2005 or 2006
    if a .dof file exists -> read [FileVersion]\version
        empty -> Delphi 5 (or possibly older)
        6.0 -> Delphi 6
        7.0 -> Delphi 7


}


//Debugging with the Shell
//http://msdn.microsoft.com/en-us/library/windows/desktop/cc144064%28v=vs.85%29.aspx
//The Complete Idiot's Guide to Writing Shell Extensions
//http://www.codeproject.com/Articles/441/The-Complete-Idiot-s-Guide-to-Writing-Shell-Extens

begin
end.
