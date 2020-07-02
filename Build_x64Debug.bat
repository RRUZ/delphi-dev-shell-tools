BRCC32 VersionInfo.rc
call "C:\Program Files (x86)\Embarcadero\Studio\20.0\bin\rsvars.bat"
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