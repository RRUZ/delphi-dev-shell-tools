BRCC32 VersionInfo.rc
call "C:\Program Files (x86)\Embarcadero\RAD Studio\11.0\bin\rsvars.bat"
msbuild.exe "DelphiDevShellTools.dproj" /target:clean;build /p:Platform=Win64 /p:config=release
pause