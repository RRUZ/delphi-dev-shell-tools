@echo off
setlocal EnableExtensions DisableDelayedExpansion
set "DDS_MODERN_CONFIG=Release"
if not "%~1"=="" set "DDS_MODERN_CONFIG=%~1"
if /i not "%DDS_MODERN_CONFIG%"=="Release" if /i not "%DDS_MODERN_CONFIG%"=="Debug" exit /b 2
if not "%~2"=="" exit /b 2
if not defined DELPHI_ROOT set "DELPHI_ROOT=C:\Program Files (x86)\Embarcadero\Studio\37.0"
if not exist "%DELPHI_ROOT%\bin\rsvars.bat" (
    echo ERROR: Set DELPHI_ROOT to a Delphi 13 installation.
    exit /b 1
)
call "%DELPHI_ROOT%\bin\rsvars.bat"
if errorlevel 1 exit /b 1
if not exist "%~dp0..\build\logs" mkdir "%~dp0..\build\logs"
"%FrameworkDir%\MSBuild.exe" "%~dp0DelphiDevShellTools.Modern.dproj" /nologo /v:minimal /t:Build /p:Platform=Win64 "/p:Config=%DDS_MODERN_CONFIG%" "/flp:LogFile=%~dp0..\build\logs\modern-%DDS_MODERN_CONFIG%.log;Verbosity=normal"
exit /b %errorlevel%
