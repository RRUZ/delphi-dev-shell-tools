@echo off
call "%~dp0..\..\Build.bat" register Win32 Release
exit /b %errorlevel%
