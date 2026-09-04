@echo off
setlocal
if "%~1"=="" goto help
if /i "%~1"=="help" goto help
if /i "%~1"=="register" goto run
if /i "%~1"=="unregister" goto run
if /i "%~1"=="status" goto run
echo ERROR: Expected register, unregister, status, or help.
exit /b 2

:run
call "%~dp0..\Build.bat" %*
exit /b %errorlevel%

:help
echo ShellExtension.bat register [Win64^|Win32] [Release^|Debug]
echo ShellExtension.bat unregister [Win64^|Win32^|All]
echo ShellExtension.bat status [Win64^|Win32^|All]
echo.
echo Defaults: Win64 Release. Registration changes request UAC when needed.
echo Unregister uses the currently registered DLL; runtime data is preserved.
exit /b 0
