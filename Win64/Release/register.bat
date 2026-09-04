@echo off
call "%~dp0..\..\Build.bat" register Win64 Release
exit /b %errorlevel%
