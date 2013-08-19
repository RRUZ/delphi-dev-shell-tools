library DelphiDevShellTools;

uses
  {$IFDEF EL}
  EMemLeaks,
  EResLeaks,
  EDialogWinAPIMSClassic,
  EDialogWinAPIEurekaLogDetailed,
  EDialogWinAPIStepsToReproduce,
  EDebugExports,
  ExceptionLog7,
  {$ENDIF}
  ComServ,
  DelphiDevShellTools_TLB in 'DelphiDevShellTools_TLB.pas',
  DelphiDevShellToolsImpl in 'DelphiDevShellToolsImpl.pas',
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
{$R VersionInfo.res}

{
TODO :
  detect delphi version.     DONE
  enumerate builds and plattform from msbuild file dproj   DONE

  Auto Update  done
  settings app
  Map dpr to dproj >=Delphi2007    done
  Add open RadStudio Command Prompt Here  %comspec%  /K "C:\Program Files (x86)\Embarcadero\RAD Studio\11.0\bin\rsvars.bat"  DONE
  Add Format code (formatter)  done
  Add support for touch.exe  done

  Add support for convert.exe (convert forms)
  Add support for tdump.exe, tdump64.exe
  deploy in OSX , IOS, Android
  view and open vcl and firemonkey styles
  Add options to register external tools

  add tasks for packages (.dpk)  done


  open with delphi N...   DONE
  compile
  compile and run
  msbuild  DONE
  msbuild and run (use bat)

  //EurekaLog
  //http://www.eurekalog.com/help/eurekalog/index.php?profiles.php


  build
  opt
    ms build release x86
    ms build debug x86
    ms build release x64
    ms build debug  x86

  common
   crc, sha1 calculation
   copy path to clipboard   DONE
   copy full filename (Path + FileName) to clipboard     DONE
   open in notepad      DONE
   open cmd here       DONE
}


//Debugging with the Shell
//http://msdn.microsoft.com/en-us/library/windows/desktop/cc144064%28v=vs.85%29.aspx
//The Complete Idiot's Guide to Writing Shell Extensions
//http://www.codeproject.com/Articles/441/The-Complete-Idiot-s-Guide-to-Writing-Shell-Extens

begin
end.
