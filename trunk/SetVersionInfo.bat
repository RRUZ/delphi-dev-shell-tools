@ECHO OFF
SETLOCAL
setLocal EnableDelayedExpansion

SET _myVar=0
FOR /F %%G in (.svn\entries.) DO (
IF !_myVar! LSS 3 SET /A _myVar+=1 & SET _svn_dir_rev=%%G
)

ECHO 1 VERSIONINFO > VersionInfo.rc
ECHO. FILEVERSION %1,%2,%3,%_svn_dir_rev%   >> VersionInfo.rc
ECHO. PRODUCTVERSION 1   >> VersionInfo.rc
ECHO. FILEOS VOS__WINDOWS32   >> VersionInfo.rc
ECHO. FILETYPE VFT_APP   >> VersionInfo.rc
ECHO. BEGIN   >> VersionInfo.rc
ECHO.   BLOCK "StringFileInfo"   >> VersionInfo.rc
ECHO.   BEGIN   >> VersionInfo.rc
ECHO.     BLOCK "080904b0"   >> VersionInfo.rc
ECHO.     BEGIN   >> VersionInfo.rc
ECHO.       VALUE "CompanyName","COMPANY\000"   >> VersionInfo.rc
ECHO.       VALUE "FileDescription","APP\000"   >> VersionInfo.rc
ECHO.       VALUE "FileVersion","%1.%2.%3.%_svn_dir_rev%\000"   >> VersionInfo.rc
ECHO.       VALUE "InternalName","APP\000"   >> VersionInfo.rc
ECHO.       VALUE "LegalCopyright","Copyright APP\000"   >> VersionInfo.rc
ECHO.       VALUE "LegalTrademarks","APP\000"   >> VersionInfo.rc
ECHO.       VALUE "OriginalFilename","APP.exe\000"   >> VersionInfo.rc
ECHO.       VALUE "ProductName","APP\000"   >> VersionInfo.rc
ECHO.       VALUE "ProductVersion,"1\000"   >> VersionInfo.rc
ECHO.       VALUE "Comments","Compiled on %date% by %username%\000"   >> VersionInfo.rc
ECHO.     END   >> VersionInfo.rc
ECHO.   END   >> VersionInfo.rc
ECHO.   BLOCK "VarFileInfo"   >> VersionInfo.rc
ECHO.   BEGIN   >> VersionInfo.rc
ECHO.     VALUE "Translation", 0x0809 1200   >> VersionInfo.rc
ECHO.   END   >> VersionInfo.rc
ECHO. END   >> VersionInfo.rc
ENDLOCAL