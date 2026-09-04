@echo off
call "%~dp0..\..\Build.bat" unregister Win32 Release
exit /b %errorlevel%
