@echo off
call "%~dp0..\..\Build.bat" unregister Win32 Debug
exit /b %errorlevel%
