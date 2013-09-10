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
Source: png\application_osx_terminal.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\application_xp_terminal.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\audits.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\bullet_green.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\bullet_orange.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\bullet_pink.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\bullet_purple.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\bullet_red.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\bullet_white.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\bullet_yellow.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\check_boxes.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\check_boxes_series.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\check_box_list.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\cog.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\compile.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\compile_error.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\compile_warning.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\delphi.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\document_properties.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\edit_chain.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\edit_diff.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\firemonkey.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\fpc_tools.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\ftp.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\ftp_accounts.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\ftp_session_control.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\gear_in.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\google_webmaster_tools.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\installer_box.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\interface_preferences.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\investment_menu_quality.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\ios.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\ip.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\ipad.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\iphone.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\lazarus.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\lazbuild.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\legend.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\light_circle_green.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\linechart.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\menu.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\menu_item.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\metrics.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\network_cloud.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\network_clouds.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\network_ethernet.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\network_folder.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\network_hub.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\network_ip.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\network_tools.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\network_wireless.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\osx.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\platforms.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\source_code.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\synchronize_ftp_password.png; DestDir: {{userappdata}\DelphiDevShellTools\png\
Source: png\system_monitor.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\touch.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\vcl.png; DestDir: {userappdata}\DelphiDevShellTools\png\
Source: png\win.png; DestDir: {userappdata}\DelphiDevShellTools\png\
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
[Dirs]
Name: {userappdata}\DelphiDevShellTools\png
