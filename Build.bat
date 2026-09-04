@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "DDS_RELOAD="
set "DDS_RELOAD_STAGE="
set "DDS_ACTION=build"
set "DDS_PLATFORM=Win64"
set "DDS_CONFIG=Release"
if not "%~1"=="" set "DDS_ACTION=%~1"
if not "%~2"=="" set "DDS_PLATFORM=%~2"
if not "%~3"=="" set "DDS_CONFIG=%~3"
if not "%~5"=="" goto usage_error
if /i "%~4"=="--reload" set "DDS_RELOAD=1"
if not "%~4"=="" if not defined DDS_RELOAD goto usage_error
if /i "%DDS_ACTION%"=="help" goto help
set "DDS_VALID="
for %%A in (build rebuild clean test test-registration register unregister status) do if /i "%DDS_ACTION%"=="%%A" set "DDS_VALID=1"
if not defined DDS_VALID goto usage_error
set "DDS_PLATFORMS="
for %%A in (Win32 Win64) do if /i "%DDS_PLATFORM%"=="%%A" set "DDS_PLATFORMS=%%A"
if /i "%DDS_PLATFORM%"=="All" set "DDS_PLATFORMS=Win32 Win64"
if not defined DDS_PLATFORMS goto usage_error
set "DDS_CONFIGS="
for %%C in (Debug Release) do if /i "%DDS_CONFIG%"=="%%C" set "DDS_CONFIGS=%%C"
if /i "%DDS_CONFIG%"=="All" set "DDS_CONFIGS=Debug Release"
if not defined DDS_CONFIGS goto usage_error
if /i "%DDS_ACTION%"=="register" if /i "%DDS_PLATFORM%"=="All" goto usage_error
if /i "%DDS_ACTION%"=="register" if /i "%DDS_CONFIG%"=="All" goto usage_error
if defined DDS_RELOAD (
    if /i not "%DDS_ACTION%"=="build" if /i not "%DDS_ACTION%"=="rebuild" goto usage_error
    if /i "%DDS_PLATFORM%"=="All" goto usage_error
    if /i "%DDS_CONFIG%"=="All" goto usage_error
)
set "DDS_64BIT="
if /i "%PROCESSOR_ARCHITECTURE%"=="AMD64" set "DDS_64BIT=1"
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "DDS_64BIT=1"
if defined PROCESSOR_ARCHITEW6432 set "DDS_64BIT=1"
if not defined DDS_64BIT if /i not "%DDS_PLATFORM%"=="Win32" (
    echo ERROR: Win64 requires a 64-bit Windows host. Use Win32.
    exit /b 1
)
for %%R in ("%~dp0.") do set "DDS_ROOT=%%~fR"
set "DDS_SYSTEM=%SystemRoot%\System32"
if exist "%SystemRoot%\Sysnative\reg.exe" set "DDS_SYSTEM=%SystemRoot%\Sysnative"
set "DDS_CLASS={45DCA61E-3762-45B1-939D-2446C0DCAC25}"
set "DDS_CLASSKEY=Software\Classes\CLSID\%DDS_CLASS%\InprocServer32"
set "DDS_HANDLERKEY=Software\Classes\*\shellex\ContextMenuHandlers\DelphiDevShellToolsContextMenu"
pushd "%DDS_ROOT%"
if errorlevel 1 exit /b 1
if /i "%DDS_ACTION%"=="status" goto status
if /i "%DDS_ACTION%"=="register" goto registration
if /i "%DDS_ACTION%"=="unregister" goto registration
if /i "%DDS_ACTION%"=="test-registration" goto registration_tests
if defined DDS_RELOAD (
    call :require_admin
    if errorlevel 1 goto failed
)
if not defined DUNITX_ROOT set "DUNITX_ROOT=C:\dev\DUnitX-0.4.1"
if /i "%DDS_ACTION%"=="test" if not exist "%DUNITX_ROOT%\Source\DUnitX.TestFramework.pas" (
    echo ERROR: DUnitX source is missing. Set DUNITX_ROOT.
    goto failed
)
call :initialize_compiler
if errorlevel 1 goto failed
call :logs
if errorlevel 1 goto failed
set "DDS_TARGET=Build"
if /i "%DDS_ACTION%"=="rebuild" set "DDS_TARGET=Clean;Build"
if /i "%DDS_ACTION%"=="clean" set "DDS_TARGET=Clean"
set "DDS_OPENSSL=%DDS_ROOT%\OpenSSL\openssl-1.0.1g-i386-win32"
if /i "%DDS_ACTION%"=="clean" goto build_configs
for %%F in (libeay32.dll ssleay32.dll) do if not exist "%DDS_OPENSSL%\%%F" (
    echo ERROR: Missing "%DDS_OPENSSL%\%%F". Restore it from Git.
    goto failed
)
for %%R in (VersionInfo.rc ShellExtensionManifest.rc Icons\images.RC GUI\GUIManifest.rc GUI\GUIResources.rc GUI\AwesomeFont.rc) do (
    call :compile_resource "%%R"
    if errorlevel 1 goto failed
)
if defined DDS_RELOAD goto reload_build
:build_configs
for %%C in (%DDS_CONFIGS%) do (
    call :build_config %%C
    if errorlevel 1 goto failed
)
if /i "%DDS_ACTION%"=="test" goto tests
goto success

:build_config
set "DDS_CURRENT_CONFIG=%~1"
set "DDS_PROJECT=GUI\GUIDelphiDevShell.dproj"
set "DDS_ARCH=Win32"
set "DDS_OUTPUT=%DDS_ROOT%\GUI\Win32\%~1"
if defined DDS_RELOAD_STAGE set "DDS_OUTPUT=%DDS_RELOAD_STAGE%\GUI\Win32\%~1"
set "DDS_GUI_OUTPUT=%DDS_OUTPUT%"
call :project_build
if errorlevel 1 exit /b 1
for %%A in (%DDS_PLATFORMS%) do (
    call :build_shell %%A
    if errorlevel 1 exit /b 1
)
exit /b 0

:build_shell
set "DDS_ARCH=%~1"
set "DDS_PROJECT=DelphiDevShellTools.dproj"
set "DDS_OUTPUT=%DDS_ROOT%\%DDS_ARCH%\%DDS_CURRENT_CONFIG%"
if defined DDS_RELOAD_STAGE set "DDS_OUTPUT=%DDS_RELOAD_STAGE%\%DDS_ARCH%\%DDS_CURRENT_CONFIG%"
call :project_build
if errorlevel 1 exit /b 1
if /i "%DDS_ACTION%"=="clean" goto clean_staged
set "DDS_DLL=%DDS_OUTPUT%\DelphiDevShellTools.dll"
call :check_dll
if errorlevel 1 exit /b 1
copy /y "%DDS_GUI_OUTPUT%\GUIDelphiDevShell.exe" "%DDS_OUTPUT%\GUIDelphiDevShell.exe" >nul
if errorlevel 1 exit /b 1
for %%F in (libeay32.dll ssleay32.dll) do (
    copy /y "%DDS_OPENSSL%\%%F" "%DDS_OUTPUT%\%%F" >nul
    if errorlevel 1 exit /b 1
)
echo Ready: "%DDS_DLL%"
if /i not "%DDS_ACTION%"=="test" exit /b 0
set "DDS_PROJECT=tests\ShellTools.Tests.dproj"
set "DDS_OUTPUT=%DDS_ROOT%\tests\%DDS_ARCH%\%DDS_CURRENT_CONFIG%"
call :project_build
exit /b %errorlevel%

:clean_staged
rem Delete only staged files beneath the validated platform/configuration output.
for %%F in (GUIDelphiDevShell.exe libeay32.dll ssleay32.dll) do (
    if exist "%DDS_OUTPUT%\%%F" del /q "%DDS_OUTPUT%\%%F"
    if exist "%DDS_OUTPUT%\%%F" exit /b 1
)
exit /b 0

:compile_resource
rem Resolve asset paths relative to each RC source, never the caller's directory.
for %%R in ("%DDS_ROOT%\%~1") do (
    pushd "%%~dpR"
    if errorlevel 1 exit /b 1
    "%DDS_DELPHI%\bin\brcc32.exe" "%%~nxR"
)
set "DDS_RESOURCE_RESULT=%errorlevel%"
popd
exit /b %DDS_RESOURCE_RESULT%

:project_build
for %%F in ("%DDS_PROJECT%") do set "DDS_PROJECT_NAME=%%~nF"
set "DDS_LOG=%DDS_ROOT%\build\logs\%DDS_PROJECT_NAME%-%DDS_ARCH%-%DDS_CURRENT_CONFIG%.log"
echo %DDS_TARGET% %DDS_PROJECT_NAME% / %DDS_ARCH% / %DDS_CURRENT_CONFIG%
"%DDS_MSBUILD%" "%DDS_ROOT%\%DDS_PROJECT%" /nologo /v:minimal "/t:%DDS_TARGET%" "/p:Platform=%DDS_ARCH%" "/p:Config=%DDS_CURRENT_CONFIG%" /p:VerInfo_AutoIncVersion=false "/p:DCC_ExeOutput=%DDS_OUTPUT%" "/p:DCC_DcuOutput=%DDS_OUTPUT%" "/p:DUnitXRoot=%DUNITX_ROOT%" "/flp:LogFile=%DDS_LOG%;Verbosity=normal"
if not errorlevel 1 exit /b 0
echo ERROR: Build failed. Log: "%DDS_LOG%".
if /i "%DDS_PROJECT_NAME%"=="DelphiDevShellTools" echo If Explorer holds the DLL, use Build.bat build %DDS_ARCH% %DDS_CURRENT_CONFIG% --reload from an Administrator Command Prompt.
exit /b 1

:reload_build
rem Compile before touching live registration or stopping Explorer.
set "DDS_PLATFORM=%DDS_PLATFORMS%"
set "DDS_CONFIG=%DDS_CONFIGS%"
set "DDS_RELOAD_COPYING="
set "DDS_RELOAD_ACTION=%DDS_ACTION%"
set "DDS_RELOAD_STAGE=%DDS_ROOT%\build\reload"
set "DDS_RELOAD_LIVE=%DDS_ROOT%\%DDS_PLATFORM%\%DDS_CONFIG%"
set "DDS_RELOAD_NEW=%DDS_RELOAD_STAGE%\%DDS_PLATFORM%\%DDS_CONFIG%"
set "DDS_RELOAD_BACKUP=%DDS_RELOAD_NEW%\previous"
set "DDS_RELOAD_FILES=GUIDelphiDevShell.exe libeay32.dll ssleay32.dll DelphiDevShellTools.dll"
set "DDS_ARCH=%DDS_PLATFORM%"
call :registry_view
call :read_registered
set "DDS_RELOAD_OLD_DLL=%DDS_REGISTERED%"
if defined DDS_RELOAD_OLD_DLL if not exist "%DDS_RELOAD_OLD_DLL%" (
    echo ERROR: The registered DLL is missing. Repair registration before reloading.
    goto failed
)
set "DDS_OVERRIDE="
for /f "tokens=2,*" %%A in ('reg query "HKCU\%DDS_CLASSKEY%" /ve /reg:%DDS_VIEW% 2^>nul') do if /i "%%A"=="REG_SZ" set "DDS_OVERRIDE=%%B"
if defined DDS_OVERRIDE (
    echo ERROR: A per-user COM registration overrides this class: "%DDS_OVERRIDE%".
    goto failed
)
set "DDS_RELOAD_SESSION="
"%DDS_SYSTEM%\query.exe" session >"%DDS_ROOT%\build\logs\reload-sessions.log" 2>nul
findstr /b /c:">" "%DDS_ROOT%\build\logs\reload-sessions.log" >"%DDS_ROOT%\build\logs\reload-active-session.log"
for /f "usebackq tokens=3" %%S in ("%DDS_ROOT%\build\logs\reload-active-session.log") do set "DDS_RELOAD_SESSION=%%S"
for /f "delims=0123456789" %%S in ("%DDS_RELOAD_SESSION%") do set "DDS_RELOAD_SESSION="
if not defined DDS_RELOAD_SESSION (
    echo ERROR: Cannot identify the interactive session. Run --reload in a local Administrator Command Prompt.
    goto failed
)
"%DDS_SYSTEM%\query.exe" session %DDS_RELOAD_SESSION% >"%DDS_ROOT%\build\logs\reload-verified-session.log" 2>nul
findstr /b /c:">" "%DDS_ROOT%\build\logs\reload-verified-session.log" >nul
if errorlevel 1 (
    echo ERROR: Session identity could not be verified; registration was not changed.
    goto failed
)
call :build_config %DDS_CONFIG%
if errorlevel 1 goto failed
if not exist "%DDS_RELOAD_BACKUP%\" mkdir "%DDS_RELOAD_BACKUP%"
if not exist "%DDS_RELOAD_BACKUP%\" goto failed
for %%F in (%DDS_RELOAD_FILES%) do (
    call :reload_backup_file %%F
    if errorlevel 1 goto failed
)
set "DDS_RELOAD_EXPLORER="
set "DDS_RELOAD_BLOCKED="
"%DDS_SYSTEM%\tasklist.exe" /m DelphiDevShellTools.dll /fo csv /nh >"%DDS_RELOAD_NEW%\holders.csv"
if errorlevel 1 goto failed
for /f "usebackq tokens=1,2 delims=," %%A in ("%DDS_RELOAD_NEW%\holders.csv") do call :reload_check_holder "%%~A" "%%~B"
if defined DDS_RELOAD_BLOCKED goto failed
set "DDS_ACTION=unregister"
call :register_one %DDS_PLATFORM%
if errorlevel 1 goto reload_recover
if defined DDS_RELOAD_EXPLORER (
    echo Restarting Explorer in session %DDS_RELOAD_SESSION%; its folder windows will close.
    "%DDS_SYSTEM%\taskkill.exe" /f /fi "SESSION eq %DDS_RELOAD_SESSION%" /fi "USERNAME eq %USERDOMAIN%\%USERNAME%" /im explorer.exe
    if errorlevel 1 goto reload_recover
)
if not exist "%DDS_RELOAD_LIVE%\" mkdir "%DDS_RELOAD_LIVE%"
if not exist "%DDS_RELOAD_LIVE%\" goto reload_recover
set "DDS_RELOAD_COPYING=1"
for %%F in (%DDS_RELOAD_FILES%) do (
    copy /y "%DDS_RELOAD_NEW%\%%F" "%DDS_RELOAD_LIVE%\%%F" >nul
    if errorlevel 1 goto reload_recover
)
set "DDS_ACTION=register"
call :register_one %DDS_PLATFORM%
if errorlevel 1 goto reload_recover
call :reload_start_explorer
if errorlevel 1 (
    echo ERROR: Could not start Explorer. Run explorer.exe manually.
    goto failed
)
set "DDS_ACTION=%DDS_RELOAD_ACTION%"
echo Reload complete: "%DDS_RELOAD_LIVE%\DelphiDevShellTools.dll"
goto success

:reload_backup_file
rem Both paths are fixed beneath the validated repository/platform/configuration.
if exist "%DDS_RELOAD_BACKUP%\%~1" del /q "%DDS_RELOAD_BACKUP%\%~1"
if exist "%DDS_RELOAD_BACKUP%\%~1" exit /b 1
if not exist "%DDS_RELOAD_LIVE%\%~1" exit /b 0
copy /y "%DDS_RELOAD_LIVE%\%~1" "%DDS_RELOAD_BACKUP%\%~1" >nul
exit /b %errorlevel%

:reload_check_holder
for %%F in ("%~1") do if /i not "%%~xF"==".exe" exit /b 0
if /i not "%~1"=="explorer.exe" goto reload_foreign_holder
"%DDS_SYSTEM%\tasklist.exe" /fi "PID eq %~2" /fi "SESSION eq %DDS_RELOAD_SESSION%" /fi "USERNAME eq %USERDOMAIN%\%USERNAME%" /fo csv /nh >"%DDS_RELOAD_NEW%\session-holder.csv"
if errorlevel 1 goto reload_foreign_holder
findstr /i /c:"explorer.exe" "%DDS_RELOAD_NEW%\session-holder.csv" >nul
if errorlevel 1 goto reload_foreign_holder
set "DDS_RELOAD_EXPLORER=1"
exit /b 0
:reload_foreign_holder
echo ERROR: %~1 PID %~2 holds a shell DLL outside this session's Explorer. Close it and retry --reload.
set "DDS_RELOAD_BLOCKED=1"
exit /b 0

:reload_recover
echo ERROR: Reload failed; restoring the previous files and registration.
set "DDS_RELOAD_RECOVERY_FAILED="
if defined DDS_RELOAD_COPYING (
    set "DDS_ACTION=unregister"
    call :register_one %DDS_PLATFORM%
    if errorlevel 1 set "DDS_RELOAD_RECOVERY_FAILED=1"
    for %%F in (%DDS_RELOAD_FILES%) do (
        call :reload_restore_file %%F
        if errorlevel 1 set "DDS_RELOAD_RECOVERY_FAILED=1"
    )
)
if defined DDS_RELOAD_OLD_DLL (
    set "DDS_ACTION=register"
    set "DDS_DLL=%DDS_RELOAD_OLD_DLL%"
    set "DDS_REG_OPTIONS=/s"
    call :run_regsvr
    if errorlevel 1 set "DDS_RELOAD_RECOVERY_FAILED=1"
)
call :reload_start_explorer
if defined DDS_RELOAD_RECOVERY_FAILED echo ERROR: Recovery needs attention. Previous files: "%DDS_RELOAD_BACKUP%".
set "DDS_ACTION=%DDS_RELOAD_ACTION%"
goto failed

:reload_restore_file
if not exist "%DDS_RELOAD_BACKUP%\%~1" goto reload_remove_new_file
fc /b "%DDS_RELOAD_BACKUP%\%~1" "%DDS_RELOAD_LIVE%\%~1" >nul 2>&1
if not errorlevel 1 exit /b 0
copy /y "%DDS_RELOAD_BACKUP%\%~1" "%DDS_RELOAD_LIVE%\%~1" >nul
exit /b %errorlevel%
:reload_remove_new_file
if exist "%DDS_RELOAD_LIVE%\%~1" del /q "%DDS_RELOAD_LIVE%\%~1"
if exist "%DDS_RELOAD_LIVE%\%~1" exit /b 1
exit /b 0

:reload_start_explorer
if not defined DDS_RELOAD_EXPLORER exit /b 0
"%DDS_SYSTEM%\tasklist.exe" /fi "IMAGENAME eq explorer.exe" /fi "SESSION eq %DDS_RELOAD_SESSION%" /fi "USERNAME eq %USERDOMAIN%\%USERNAME%" /fo csv /nh >"%DDS_RELOAD_NEW%\explorer.csv"
findstr /i /c:"explorer.exe" "%DDS_RELOAD_NEW%\explorer.csv" >nul
if not errorlevel 1 exit /b 0
ver >nul
start "" "%SystemRoot%\explorer.exe"
exit /b %errorlevel%

:find_delphi
set "DDS_DELPHI=%DELPHI_ROOT%"
if defined DDS_DELPHI goto delphi_found
for %%H in (HKCU HKLM) do for %%V in (32 64) do (
    call :find_delphi_registry %%H %%V
)
if not defined DDS_DELPHI set "DDS_DELPHI=%ProgramFiles(x86)%\Embarcadero\Studio\37.0"
:delphi_found
for %%D in ("%DDS_DELPHI%\.") do set "DDS_DELPHI=%%~fD"
if exist "%DDS_DELPHI%\bin\rsvars.bat" exit /b 0
echo ERROR: Delphi 13 is missing. Set DELPHI_ROOT to its installation folder.
exit /b 1

:find_delphi_registry
if defined DDS_DELPHI exit /b 0
for /f "tokens=2,*" %%A in ('reg query "%~1\Software\Embarcadero\BDS\37.0" /v RootDir /reg:%~2 2^>nul') do if /i "%%A"=="REG_SZ" if exist "%%B\bin\rsvars.bat" set "DDS_DELPHI=%%B"
exit /b 0

:initialize_compiler
call :find_delphi
if errorlevel 1 exit /b 1
call "%DDS_DELPHI%\bin\rsvars.bat"
if errorlevel 1 exit /b 1
set "DDS_MSBUILD=%FrameworkDir%\MSBuild.exe"
if not exist "%DDS_MSBUILD%" (
    echo ERROR: MSBuild is missing: "%DDS_MSBUILD%".
    exit /b 1
)
if not exist "%DDS_DELPHI%\bin\brcc32.exe" exit /b 1
echo Compiler: "%DDS_DELPHI%"
exit /b 0

:check_dll
if not exist "%DDS_DLL%" (
    echo ERROR: Missing DLL: "%DDS_DLL%".
    exit /b 1
)
if not exist "%DDS_DELPHI%\bin\tdump.exe" (
    echo ERROR: Delphi tdump.exe is required to verify DLL architecture.
    exit /b 1
)
set "DDS_CPU=80386"
if /i "%DDS_ARCH%"=="Win64" set "DDS_CPU=AMD64"
"%DDS_DELPHI%\bin\tdump.exe" -ns -q -eiHDR "%DDS_DLL%" >"%DDS_ROOT%\build\logs\architecture-%DDS_ARCH%.log" 2>&1
if errorlevel 1 exit /b 1
findstr /r /c:"^CPU type  *%DDS_CPU%$" "%DDS_ROOT%\build\logs\architecture-%DDS_ARCH%.log" >nul
if not errorlevel 1 exit /b 0
echo ERROR: DLL architecture does not match %DDS_ARCH%: "%DDS_DLL%".
exit /b 1

:registration_tests
call :require_admin
if errorlevel 1 goto failed
call :logs
if errorlevel 1 goto failed
:tests
set "DDS_TEST_REGISTRATION=0"
if /i "%DDS_ACTION%"=="test-registration" set "DDS_TEST_REGISTRATION=1"
for %%C in (%DDS_CONFIGS%) do for %%A in (%DDS_PLATFORMS%) do (
    call :run_tests %%A %%C
    if errorlevel 1 goto failed
)
goto success

:run_tests
set "DDS_TEST_DLL=%DDS_ROOT%\%~1\%~2\DelphiDevShellTools.dll"
set "DDS_TEST_EXE=%DDS_ROOT%\tests\%~1\%~2\ShellTools.Tests.exe"
if not exist "%DDS_TEST_DLL%" goto tests_missing
if not exist "%DDS_TEST_EXE%" goto tests_missing
echo Running %DDS_ACTION% / %~1 / %~2
"%DDS_TEST_EXE%" "--xml:%DDS_ROOT%\build\logs\%DDS_ACTION%-%~1-%~2.xml"
if not errorlevel 1 exit /b 0
echo ERROR: Tests failed. Report: "build\logs\%DDS_ACTION%-%~1-%~2.xml".
exit /b 1
:tests_missing
echo ERROR: Tests or DLL missing. Run Build.bat test %~1 %~2 first.
exit /b 1

:require_admin
"%DDS_SYSTEM%\fltmc.exe" >nul 2>&1
if not errorlevel 1 exit /b 0
echo ERROR: Run this command from an Administrator Command Prompt.
exit /b 1

:status
for %%A in (%DDS_PLATFORMS%) do call :show_status %%A
goto success
:show_status
set "DDS_ARCH=%~1"
call :registry_view
call :read_registered
if defined DDS_REGISTERED (echo %~1 registered: "%DDS_REGISTERED%") else echo %~1 not registered.
exit /b 0

:registry_view
set "DDS_VIEW=32"
if /i "%DDS_ARCH%"=="Win64" set "DDS_VIEW=64"
exit /b 0
:read_registered
set "DDS_REGISTERED="
for /f "tokens=2,*" %%A in ('reg query "HKLM\%DDS_CLASSKEY%" /ve /reg:%DDS_VIEW% 2^>nul') do if /i "%%A"=="REG_SZ" set "DDS_REGISTERED=%%B"
exit /b 0
:read_other_registered
set "DDS_OTHER_VIEW=64"
if "%DDS_VIEW%"=="64" set "DDS_OTHER_VIEW=32"
set "DDS_OTHER_REGISTERED="
for /f "tokens=2,*" %%A in ('reg query "HKLM\%DDS_CLASSKEY%" /ve /reg:%DDS_OTHER_VIEW% 2^>nul') do if /i "%%A"=="REG_SZ" set "DDS_OTHER_REGISTERED=%%B"
exit /b 0

:read_handler
set "DDS_HANDLER="
for /f "tokens=2,*" %%A in ('reg query "HKLM\%DDS_HANDLERKEY%" /ve /reg:%DDS_VIEW% 2^>nul') do if /i "%%A"=="REG_SZ" set "DDS_HANDLER=%%B"
exit /b 0

:registration
call :require_admin
if errorlevel 1 goto failed
call :find_delphi
if errorlevel 1 goto failed
call :logs
if errorlevel 1 goto failed
for %%A in (%DDS_PLATFORMS%) do (
    call :register_one %%A
    if errorlevel 1 goto failed
)
goto success

:register_one
set "DDS_ARCH=%~1"
call :registry_view
call :read_registered
set "DDS_DLL=%DDS_REGISTERED%"
if /i "%DDS_ACTION%"=="unregister" goto unregister_one
set "DDS_OUTPUT=%DDS_ROOT%\%DDS_ARCH%\%DDS_CONFIG%"
set "DDS_DLL=%DDS_OUTPUT%\DelphiDevShellTools.dll"
for %%F in (DelphiDevShellTools.dll GUIDelphiDevShell.exe libeay32.dll ssleay32.dll) do if not exist "%DDS_OUTPUT%\%%F" (
    echo ERROR: Missing "%DDS_OUTPUT%\%%F". Run Build.bat build %DDS_ARCH% %DDS_CONFIG% first.
    exit /b 1
)
set "DDS_OVERRIDE="
for /f "tokens=2,*" %%A in ('reg query "HKCU\%DDS_CLASSKEY%" /ve /reg:%DDS_VIEW% 2^>nul') do if /i "%%A"=="REG_SZ" set "DDS_OVERRIDE=%%B"
if defined DDS_OVERRIDE (
    echo ERROR: A per-user COM registration overrides this class: "%DDS_OVERRIDE%".
    exit /b 1
)
call :check_dll
if errorlevel 1 exit /b 1
call :initialize_defaults
if errorlevel 1 exit /b 1
set "DDS_REG_OPTIONS=/s"
goto run_regsvr
:unregister_one
if defined DDS_DLL goto unregister_dll
call :read_handler
call :read_other_registered
if not defined DDS_OTHER_REGISTERED if defined DDS_HANDLER (
    echo ERROR: Context-menu registration exists without a COM server. Repair registration first.
    exit /b 1
)
echo %DDS_ARCH% is already unregistered.
exit /b 0
:unregister_dll
call :check_dll
if errorlevel 1 exit /b 1
set "DDS_REG_OPTIONS=/s /u"
:run_regsvr
set "DDS_REGSVR=%DDS_SYSTEM%\regsvr32.exe"
if defined DDS_64BIT if /i "%DDS_ARCH%"=="Win32" set "DDS_REGSVR=%SystemRoot%\SysWOW64\regsvr32.exe"
start "" /wait "%DDS_REGSVR%" %DDS_REG_OPTIONS% "%DDS_DLL%"
if errorlevel 1 (
    echo ERROR: regsvr32 failed for "%DDS_DLL%".
    exit /b 1
)
call :read_registered
call :read_handler
if /i "%DDS_ACTION%"=="unregister" goto verify_unregistered
if /i not "%DDS_REGISTERED%"=="%DDS_DLL%" goto registration_failed
if /i not "%DDS_HANDLER%"=="%DDS_CLASS%" goto registration_failed
echo Registered %DDS_ARCH%: "%DDS_REGISTERED%"
exit /b 0
:verify_unregistered
if defined DDS_REGISTERED goto registration_failed
call :read_other_registered
if defined DDS_OTHER_REGISTERED (
    if /i not "%DDS_HANDLER%"=="%DDS_CLASS%" goto registration_failed
) else if defined DDS_HANDLER goto registration_failed
echo Unregistered %DDS_ARCH%.
exit /b 0
:registration_failed
echo ERROR: COM server or context-menu registration verification failed.
exit /b 1

:initialize_defaults
set "DDS_DATA=%ProgramData%\DelphiDevShellTools"
if exist "%DDS_DATA%\" goto copy_defaults
mkdir "%DDS_DATA%"
if errorlevel 1 exit /b 1
set "DDS_SID="
for /f "tokens=2 delims=," %%S in ('whoami /user /fo csv /nh') do set "DDS_SID=%%~S"
if not defined DDS_SID exit /b 1
icacls "%DDS_DATA%" /grant "*%DDS_SID%:(OI)(CI)M" >nul
if errorlevel 1 exit /b 1
:copy_defaults
if exist "%DDS_DATA%\Settings.ini" goto copy_catalogs
copy /y "%DDS_ROOT%\Settings.ini" "%DDS_DATA%\Settings.ini" >nul
if errorlevel 1 exit /b 1
:copy_catalogs
for %%F in (Tools.db DelphiVersions.db macros.xml) do if not exist "%DDS_DATA%\%%F" (
    copy "%DDS_ROOT%\%%F" "%DDS_DATA%\%%F" >nul
    if errorlevel 1 exit /b 1
)
if not exist "%DDS_DATA%\ico\" mkdir "%DDS_DATA%\ico"
if not exist "%DDS_DATA%\ico\" exit /b 1
for %%F in ("%DDS_ROOT%\ico\*.ico") do if not exist "%DDS_DATA%\ico\%%~nxF" (
    copy "%%~fF" "%DDS_DATA%\ico\%%~nxF" >nul
    if errorlevel 1 exit /b 1
)
exit /b 0

:logs
if not exist "%DDS_ROOT%\build\logs\" mkdir "%DDS_ROOT%\build\logs"
if not exist "%DDS_ROOT%\build\logs\" exit /b 1
exit /b 0
:success
popd
exit /b 0
:failed
echo ERROR: %DDS_ACTION% failed.
popd
exit /b 1
:usage_error
echo ERROR: Invalid arguments. Run Build.bat help.
exit /b 2
:help
echo Build.bat [build^|rebuild^|clean^|test^|test-registration] [Win64^|Win32^|All] [Release^|Debug^|All]
echo Build.bat [build^|rebuild] [Win64^|Win32] [Release^|Debug] --reload
echo Build.bat register [Win64^|Win32] [Release^|Debug]
echo Build.bat [unregister^|status] [Win64^|Win32^|All]
echo Defaults: build Win64 Release. Overrides: DELPHI_ROOT, DUNITX_ROOT.
echo DUnitX default: C:\dev\DUnitX-0.4.1. Logs: build\logs.
echo Register/unregister/test-registration/--reload require an Administrator Command Prompt.
echo --reload stages the build, registers it and restarts this session's Explorer if loaded.
echo Run test before test-registration; registration tests restore prior state.
exit /b 0
