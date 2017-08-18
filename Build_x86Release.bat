BRCC32 VersionInfo.rc
call "C:\Program Files (x86)\Embarcadero\Studio\18.0\bin\rsvars.bat"
msbuild.exe "DelphiDevShellTools.dproj" /target:clean;build /p:Platform=Win32 /p:config=release
pause