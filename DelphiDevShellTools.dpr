library DelphiDevShellTools;

uses
  madLinkDisAsm,
  madListHardware,
  madListProcesses,
  madListModules,
  {$IFDEF DEBUG}
  madExcept,
  {$ENDIF }
  System.Win.ComServ,
  DelphiDevShellTools_TLB in 'DelphiDevShellTools_TLB.pas',
  DelphiDevShellToolsImpl in 'DelphiDevShellToolsImpl.pas',
  uDelphiVersions in 'units\uDelphiVersions.pas',
  uMisc in 'units\uMisc.pas',
  uRegistry in 'units\uRegistry.pas',
  uSupportedIDEs in 'units\uSupportedIDEs.pas',
  uLazarusVersions in 'units\uLazarusVersions.pas',
  uTasks in 'units\uTasks.pas';

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
TODO
  Add Property sheet handler for Delphi projects
  Add Property sheet handler for Lazarus projects

  FPC
  ------------------------------------------------------------------------------
  Tools that come with Free Pascal - http://www.freepascal.org/tools/tools.var

    done - h2pas is a small command-line utility that can be used to translate C header files to pascal units. The Free Pascal team uses it to make import units for important C libraries such as GTK or MySQL.
      //h2pas -e -m -s PortableDeviceTypes.h Winapi.Portabledevicetypes.pas
    fpcmake is a tool that allows you to make complex makefiles to compile programs and units with FPC. The Free Pascal team uses it to create all it's makefiles.
    done - ppdep is a small utility that scans a program or unit and creates a depend file that can be used for inclusion by make. It understands conditional symbols and interdependency of units.
    delp is a small utility that scans a directory for files left over by the Free Pascal compiler, and deletes them.
    done - ppudump dumps the contents of a unit in human-readable format. It understands older versions of units and gracefully handles unknown (future) versions.
    ppufiles lists the object files that you need to link in when using a unit file. It lists all libraries and units that are needed.
    ppumove combines several units into one; as such it can be used to create static and dynamic libraries.
    done - ptop is a configurable source formatter. It pretty-prints your pascal code, much like indent does for C code.
    rstconv is a small utility that converts .rst files (files that contain resource strings, as created by the compiler to some other format. (GNU gettext at the moment)
    TP Lex and Yacc, written by Albert Graef. It can be used to create pascal units from a Lex vocabulary and Yacc grammar.
  ------------------------------------------------------------------------------

  add project to RAD Studio favorites

  add binary files tasks
   done - Add support for tdump.exe, tdump64.exe

  add register extensions by task      done
  Add options to register external tools  done
  use Sqlite to store data

  Add paclient.exe options
    deploy
    test profile connection  done


  detect delphi version.     DONE
  enumerate builds and plattform from msbuild file dproj   DONE
  Add extra info to default msbuild conf (platform, type (dll, app), framweork) use owner draw?  DONE

  Auto Update  done
  settings app       done
  Map dpr to dproj >=Delphi2007    done
  Add open RadStudio Command Prompt Here  %comspec%  /K "C:\Program Files (x86)\Embarcadero\RAD Studio\11.0\bin\rsvars.bat"  DONE
  Add Format code (formatter)  done
  Add support for touch.exe  done

  Add support for convert.exe (convert forms)
  deploy in OSX , IOS, Android
  view and open vcl and firemonkey styles done
  add tasks for packages (.dpk)  done


  open with delphi N...   DONE
  compile
  compile and run
  msbuild  DONE
  msbuild and run (use bat)

  //EurekaLog
  //http://www.eurekalog.com/help/eurekalog/index.php?profiles.php


  common
   crc, sha1 calculation done
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
