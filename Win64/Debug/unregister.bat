@echo off
call "%~dp0..\..\Build.bat" unregister Win64 Debug
exit /b %errorlevel%
