#define MyAppName 'Delphi Dev. Shell Tools'
#define MyAppVersion GetFileVersion('Win64\Debug\DelphiDevShellTools.dll')
[Types]
Name: Debug; Description: Install Shell Extension with debug info (MadExcept)
Name: Release; Description: Install Shell Extension

[Components]
Name: program; Description: GUI for Shell Extension; Types: Debug Release; Flags: fixed
Name: Debug; Description: Shell Extension with Debug info (MadExcept); Types: Debug; Flags: exclusive
Name: Release; Description: Shell Extension; Types: Release; Flags: exclusive
[Files]
Source: Win64\Debug\DelphiDevShellTools.dll; DestDir: {app}; Check: Is64BitInstallMode; Flags: regserver restartreplace; Components: Debug
Source: Win32\Debug\DelphiDevShellTools.dll; DestDir: {app}; Check: not Is64BitInstallMode; Flags: regserver restartreplace; Components: Debug
Source: Win64\Release\DelphiDevShellTools.dll; DestDir: {app}; Check: Is64BitInstallMode; Flags: regserver restartreplace; Components: Release
Source: Win32\Release\DelphiDevShellTools.dll; DestDir: {app}; Check: not Is64BitInstallMode; Flags: regserver restartreplace; Components: Release
Source: Updater\Updater.exe; DestDir: {app}; Components: program
Source: Updater\DownloadInfo.xml; DestDir: {app}; Components: program
Source: GUI\GUIDelphiDevShell.exe; DestDir: {app}; Components: program
;Source: OpenSSL\openssl-1.0.1g-i386-win32\ssleay32.dll; DestDir: {app}; Check: not Is64BitInstallMode; Components: program
;Source: OpenSSL\openssl-1.0.1g-i386-win32\libeay32.dll; DestDir: {app}; Check: not Is64BitInstallMode; Components: program
;Source: OpenSSL\openssl-1.0.1g-x64_86-win64\ssleay32.dll; DestDir: {app}; Check: Is64BitInstallMode; Components: program
;Source: OpenSSL\openssl-1.0.1g-x64_86-win64\libeay32.dll; DestDir: {app}; Check: Is64BitInstallMode; Components: program
Source: OpenSSL\openssl-1.0.1g-i386-win32\OpenSSL License.txt; DestDir: {app}; Components: program
Source: OpenSSL\openssl-1.0.1g-i386-win32\ssleay32.dll; DestDir: {app}; Components: program
Source: OpenSSL\openssl-1.0.1g-i386-win32\libeay32.dll; DestDir: {app}; Components: program
Source: Settings.ini; DestDir: {commonappdata}\DelphiDevShellTools
Source: Tools.db; DestDir: {commonappdata}\DelphiDevShellTools
Source: macros.xml; DestDir: {commonappdata}\DelphiDevShellTools
Source: DelphiVersions.db; DestDir: {commonappdata}\DelphiDevShellTools
Source: ico\application_osx_terminal.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\application_xp_terminal.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\audits.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\bullet_green.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\bullet_orange.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\bullet_pink.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\bullet_purple.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\bullet_red.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\bullet_white.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\bullet_yellow.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\check_boxes.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\check_boxes_series.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\check_box_list.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\cog.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\compile.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\compile_error.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\compile_warning.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\delphi.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\document_properties.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\edit_chain.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\edit_diff.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\firemonkey.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\fpc_tools.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\ftp.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\ftp_accounts.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\ftp_session_control.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\gear_in.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\google_webmaster_tools.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\installer_box.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\interface_preferences.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\investment_menu_quality.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\ios.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\ip.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\ipad.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\iphone.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\lazarus.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\lazbuild.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\legend.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\light_circle_green.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\linechart.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\menu.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\menu_item.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\metrics.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\network_cloud.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\network_clouds.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\network_ethernet.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\network_folder.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\network_hub.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\network_ip.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\network_tools.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\network_wireless.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\osx.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\platforms.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\source_code.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\synchronize_ftp_password.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\system_monitor.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\touch.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\vcl.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: ico\win.ico; DestDir: {commonappdata}\DelphiDevShellTools\Ico\
Source: Installer\VclStylesInno.dll; DestDir: {app}; Flags: dontcopy
Source: Installer\Glossy.vsf; DestDir: {app}; Flags: dontcopy
Source: Installer\background.bmp; Flags: dontcopy

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
AppPublisherURL=https://github.com/RRUZ/delphi-dev-shell-tools
AppSupportURL=https://github.com/RRUZ/delphi-dev-shell-tools
AppUpdatesURL=https://github.com/RRUZ/delphi-dev-shell-tools
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
WizardSmallImageFile=Installer\WizModernSmallImage-IS.bmp
WizardImageFile=Installer\WizModernImage-IS.bmp
AppContact=theroadtodelphi@gmail.com
DisableProgramGroupPage=false
AppID=DelphiDevShellTools
SetupIconFile=Icons\Logo.ico
DefaultGroupName=Delphi Dev Shell Tools

[Languages]
Name: english; MessagesFile: compiler:Default.isl
;Name: basque; MessagesFile: compiler:Languages\Basque.isl
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
;Name: slovak; MessagesFile: compiler:Languages\Slovak.isl
Name: slovenian; MessagesFile: compiler:Languages\Slovenian.isl
Name: spanish; MessagesFile: compiler:Languages\Spanish.isl
[Dirs]
Name: {commonappdata}\DelphiDevShellTools; Permissions: everyone-full
Name: {commonappdata}\DelphiDevShellTools\ico; Permissions: everyone-full

[Code]
// Import the LoadVCLStyle function from VclStylesInno.DLL
procedure LoadVCLStyle(VClStyleFile: String); external 'LoadVCLStyleW@files:VclStylesInno.dll stdcall';
// Import the UnLoadVCLStyles function from VclStylesInno.DLL
procedure UnLoadVCLStyles; external 'UnLoadVCLStyles@files:VclStylesInno.dll stdcall';


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


procedure BitmapImageOnClick(Sender: TObject);
var
  ErrorCode : Integer;
begin
  ShellExec('open', 'http://code.google.com/p/delphi-dev-shell-tools/', '', '', SW_SHOWNORMAL, ewNoWait, ErrorCode);
end;

procedure CreateWizardPages;
var
  Page: TWizardPage;
  BitmapImage: TBitmapImage;
  BitmapFileName: String;
begin
  BitmapFileName := ExpandConstant('{tmp}\background.bmp');
  ExtractTemporaryFile(ExtractFileName(BitmapFileName));

  { TBitmapImage }
  Page := CreateCustomPage(wpInstalling, 'Contributions',
  'If you want show your appreciation for this project. Go to the code google page, login with you google account and star the project.');

  BitmapImage := TBitmapImage.Create(Page);
  BitmapImage.AutoSize := True;
  BitmapImage.Left := 0;
  BitmapImage.Top  := 0;
  BitmapImage.Bitmap.LoadFromFile(BitmapFileName);
  BitmapImage.Cursor := crHand;
  BitmapImage.OnClick := @BitmapImageOnClick;
  BitmapImage.Parent := Page.Surface;
  BitmapImage.Align:=alCLient;
  BitmapImage.Stretch:=True;
end;

procedure InitializeWizard();
begin
  //CreateWizardPages;
end;

function InitializeSetup(): Boolean;
begin
   ExtractTemporaryFile('Glossy.vsf');
   LoadVCLStyle(ExpandConstant('{tmp}\Glossy.vsf'));
   Result:=True;
end;

procedure DeinitializeSetup();
begin
	UnLoadVCLStyles;
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
