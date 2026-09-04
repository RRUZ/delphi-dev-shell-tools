@echo off
call "%~dp0..\..\Build.bat" register Win64 Debug
exit /b %errorlevel%
