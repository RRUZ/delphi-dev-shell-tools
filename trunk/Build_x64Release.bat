call "C:\Program Files (x86)\Embarcadero\RAD Studio\11.0\bin\rsvars.bat"
msbuild.exe "DelphiDevShellTools.dproj" /target:build /p:Platform=Win64 /p:config=release
pause