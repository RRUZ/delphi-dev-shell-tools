@echo off
set dll=%CD%\Win64\Release\DelphiDevShellTools.dll
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
msbuild.exe "DelphiDevShellTools.dproj" /target:clean;build /p:Platform=Win64 /p:config=release
pause