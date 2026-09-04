@echo off
call "%~dp0..\..\Build.bat" register Win32 Debug
exit /b %errorlevel%
