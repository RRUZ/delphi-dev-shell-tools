#define MyAppName 'Delphi Dev. Shell Tools'
#define MyAppVersion GetFileVersion('Win64\Debug\DelphiDevShellTools.dll')
[Types]
Name: Debug; Description: Install Shell Extension with debug info (EurekaLog)
Name: Release; Description: Install Shell Extension

[Components]
Name: program; Description: GUI for Shell Extension; Types: Debug Release; Flags: fixed
Name: Debug; Description: Shell Extension with Debug info (EurekaLog); Types: Debug; Flags: exclusive
Name: Release; Description: Shell Extension; Types: Release; Flags: exclusive
[Files]
Source: Win64\Debug\DelphiDevShellTools.dll; DestDir: {app}; Check: Is64BitInstallMode; Flags: regserver restartreplace regtypelib; Components: Debug
Source: Win32\Debug\DelphiDevShellTools.dll; DestDir: {app}; Check: not Is64BitInstallMode; Flags: regserver restartreplace regtypelib; Components: Debug
Source: Win64\Release\DelphiDevShellTools.dll; DestDir: {app}; Check: Is64BitInstallMode; Flags: regserver restartreplace regtypelib; Components: Release
Source: Win32\Release\DelphiDevShellTools.dll; DestDir: {app}; Check: not Is64BitInstallMode; Flags: regserver restartreplace regtypelib; Components: Release
Source: GUI\GUIDelphiDevShell.exe; DestDir: {app}; Components: program
Source: OpenSSL\openssl-1.0.1e-i386-win32\ssleay32.dll; DestDir: {app}; Check: not Is64BitInstallMode; Components: program
Source: OpenSSL\openssl-1.0.1e-i386-win32\libeay32.dll; DestDir: {app}; Check: not Is64BitInstallMode; Components: program
Source: OpenSSL\openssl-1.0.1e-x64_86-win64\ssleay32.dll; DestDir: {app}; Check: Is64BitInstallMode; Components: program
Source: OpenSSL\openssl-1.0.1e-x64_86-win64\libeay32.dll; DestDir: {app}; Check: Is64BitInstallMode; Components: program
Source: Settings.ini; DestDir: {userappdata}\DelphiDevShellTools
Source: OpenSSL\openssl-1.0.1e-i386-win32\OpenSSL License.txt; DestDir: {app}; Components: program
Source: Tools.db; DestDir: {userappdata}\DelphiDevShellTools
Source: macros.xml; DestDir: {userappdata}\DelphiDevShellTools
Source: DelphiVersions.db; DestDir: {userappdata}\DelphiDevShellTools
[Run]
Filename: regsvr32.exe; Parameters: "/s ""{app}\DelphiDevShellTools.dll"""; StatusMsg: Registering plugin
[UninstallRun]
Filename: regsvr32.exe; Parameters: "/s /u ""{app}\DelphiDevShellTools.dll"""; StatusMsg: UnRegistering plugin
[Setup]
UsePreviousLanguage=no
AppName={#MyAppName}
AppPublisher=The Road To Delphi
AppVerName={#MyAppName} {#MyAppVersion}
VersionInfoVersion={#MyAppVersion}
AppPublisherURL=http://theroadtodelphi.wordpress.com/
AppSupportURL=http://theroadtodelphi.wordpress.com/
AppUpdatesURL=http://theroadtodelphi.wordpress.com/
DefaultDirName={pf}\The Road To Delphi\Delphi Dev. Shell Tools
OutputBaseFileName=Setup
DisableDirPage=true
Compression=lzma
SolidCompression=true
UsePreviousAppDir=false
AppendDefaultDirName=true
PrivilegesRequired=admin
WindowVisible=false
ArchitecturesInstallIn64BitMode=x64
;WizardSmallImageFile=compiler:WizModernSmallImage-IS.bmp
;WizardSmallImageFile=Extras\SmallImage-IS.bmp
;WizardImageFile=Extras\LeftBackground.bmp
AppContact=theroadtodelphi@gmail.com
DisableProgramGroupPage=false
AppID=DelphiDevShellTools
SetupIconFile=Icons\Logo.ico
DefaultGroupName=Delphi Dev Shell Tools
;MinVersion=
[Languages]
Name: english; MessagesFile: compiler:Default.isl
Name: basque; MessagesFile: compiler:Languages\Basque.isl
Name: brazilianportuguese; MessagesFile: compiler:Languages\BrazilianPortuguese.isl
Name: catalan; MessagesFile: compiler:Languages\Catalan.isl
Name: czech; MessagesFile: compiler:Languages\Czech.isl
Name: danish; MessagesFile: compiler:Languages\Danish.isl
Name: dutch; MessagesFile: compiler:Languages\Dutch.isl
Name: finnish; MessagesFile: compiler:Languages\Finnish.isl
Name: french; MessagesFile: compiler:Languages\French.isl
Name: german; MessagesFile: compiler:Languages\German.isl
Name: hebrew; MessagesFile: compiler:Languages\Hebrew.isl
Name: hungarian; MessagesFile: compiler:Languages\Hungarian.isl
Name: italian; MessagesFile: compiler:Languages\Italian.isl
Name: japanese; MessagesFile: compiler:Languages\Japanese.isl
Name: norwegian; MessagesFile: compiler:Languages\Norwegian.isl
Name: polish; MessagesFile: compiler:Languages\Polish.isl
Name: portuguese; MessagesFile: compiler:Languages\Portuguese.isl
Name: russian; MessagesFile: compiler:Languages\Russian.isl
Name: slovak; MessagesFile: compiler:Languages\Slovak.isl
Name: slovenian; MessagesFile: compiler:Languages\Slovenian.isl
Name: spanish; MessagesFile: compiler:Languages\Spanish.isl

[Code]

function GetUninstallString(): String;
var
  sUnInstPath: String;
  sUnInstallString: String;
begin
  sUnInstPath := ExpandConstant('Software\Microsoft\Windows\CurrentVersion\Uninstall\{#emit SetupSetting("AppId")}_is1');
  sUnInstallString := '';
  if not RegQueryStringValue(HKLM, sUnInstPath, 'UninstallString', sUnInstallString) then
    RegQueryStringValue(HKCU, sUnInstPath, 'UninstallString', sUnInstallString);
  Result := sUnInstallString;
end;

function IsUpgrade(): Boolean;
begin
  Result := (GetUninstallString() <> '');
end;

function UnInstallOldVersion(): Integer;
var
  sUnInstallString: String;
  iResultCode: Integer;
begin

  Result := 0;
  sUnInstallString := GetUninstallString();
  if sUnInstallString <> '' then begin
    sUnInstallString := RemoveQuotes(sUnInstallString);
    if Exec(sUnInstallString, '/SILENT /NORESTART /SUPPRESSMSGBOXES','', SW_HIDE, ewWaitUntilTerminated, iResultCode) then
      Result := 3
    else
      Result := 2;
  end else
    Result := 1;
end;


function InitializeSetup(): Boolean;
begin
   Result:=True;
end;

procedure DeinitializeSetup();
begin
 //ShowWindow(StrToInt(ExpandConstant('{wizardhwnd}')), 0);
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if (CurStep=ssInstall) then
  begin
    if (IsUpgrade()) then
    begin
      UnInstallOldVersion();
    end;
  end;
end;
