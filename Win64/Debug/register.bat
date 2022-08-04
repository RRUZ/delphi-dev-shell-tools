@echo off
set dll=%CD%\DelphiDevShellTools.dll

if exist %dll% (
	powershell -Command "start-process cmd \"/c regsvr32 %dll%\" -Verb RunAs"
) else (
	echo "DelphiDevShellTools.dll not found. Run Build first."
	Pause
)