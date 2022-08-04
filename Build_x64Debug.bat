@echo off
set dll=%CD%\Win64\Debug\DelphiDevShellTools.dll
if exist %dll% (
	echo Unregistering
	powershell -Command "start-process cmd \"/c regsvr32 %dll% /u \" -Verb RunAs"
	del %dll%
	pause
)
if exist %dll% (
	echo DLL was locked by explorer so restarting explorer.
	taskkill /F /IM explorer.exe
	del %dll%
	start explorer.exe
)
BRCC32 VersionInfo.rc
call "C:\Program Files (x86)\Embarcadero\Studio\22.0\bin\rsvars.bat"
msbuild.exe "DelphiDevShellTools.dproj" /target:Clean;Build /p:Platform=Win64 /p:config=debug
set BUILD_STATUS=%ERRORLEVEL%
if %BUILD_STATUS%==0 GOTO Updater
pause
EXIT

:Updater
msbuild.exe Updater\Updater.dproj /target:Clean;Build /p:Platform=Win32 /p:config=release
set BUILD_STATUS=%ERRORLEVEL%
if %BUILD_STATUS%==0 GOTO GUI

:GUI
msbuild.exe GUI\GUIDelphiDevShell.dproj /target:Clean;Build /p:Platform=Win32 /p:config=release
copy GUI\GUIDelphiDevShell.exe Win64\Debug\GUIDelphiDevShell.exe

pause