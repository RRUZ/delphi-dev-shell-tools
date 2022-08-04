@echo off
set dll=%CD%\DelphiDevShellTools.dll
powershell -Command "start-process cmd \"/c regsvr32 /U %dll%\" -Verb RunAs"