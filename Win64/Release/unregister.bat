@echo off
call "%~dp0..\..\Build.bat" unregister Win64 Release
exit /b %errorlevel%
