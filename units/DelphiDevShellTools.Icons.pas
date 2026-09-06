//**************************************************************************************************
//
// Unit DelphiDevShellTools.Icons
// Semantic project-icon catalogue and Phosphor rendering provider.
// https://github.com/RRUZ/delphi-dev-shell-tools
//
// The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy of the
// License at http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
// ANY KIND, either express or implied. See the License for the specific language governing rights
// and limitations under the License.
//
// The Original Code is DelphiDevShellTools.Icons.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.Icons;

interface

uses
  Winapi.Windows,
  System.SysUtils,
  Vcl.Graphics,
  DelphiDevShellTools.UI;

type
  TProjectIconId = (
    piiNotepad,
    piiCommandPrompt,
    piiCopy,
    piiMacOS,
    piiIOS,
    piiWindows,
    piiAndroid,
    piiDelphi,
    piiDelphiUnavailable,
    piiRadStudioCommandPrompt,
    piiMSBuild,
    piiFireMonkey,
    piiVCL,
    piiLazarus,
    piiLazBuild,
    piiBuildConfiguration,
    piiPlatforms,
    piiSettings,
    piiCommonTasks,
    piiChecksum,
    piiChecksumCRC32,
    piiChecksumMD4,
    piiChecksumMD5,
    piiChecksumSHA1,
    piiChecksumSHA256,
    piiChecksumSHA384,
    piiChecksumSHA512,
    piiCopyUNC,
    piiCopyURL,
    piiCopyContent,
    piiCopyPath,
    piiAdministrator,
    piiFPCTools,
    piiExternalTools,
    piiCustomFormatter,
    piiCustomPackage,
    piiCustomDependency,
    piiCustomHeader,
    piiCustomTerminal,
    piiCustomTouch,
    piiCustomResource,
    piiCustomMetrics,
    piiCustomAudits,
    piiCustomStyle,
    piiCustomDump32,
    piiCustomDump64,
    piiCustomRegister,
    piiCustomUnregister);

  TProjectIconPaletteRole = (
    pipNeutral,
    pipCopy,
    pipLink,
    pipEdit,
    pipPlatform,
    pipFramework,
    pipBuild,
    pipChecksum,
    pipWarning,
    pipPrivileged);

  TProjectIconSource = (pisNone, pisPhosphor, pisFallbackResource);

  TProjectIconDescriptor = record
    Id: TProjectIconId;
    Key: string;
    PhosphorName: string;
    Code: Word;
    PaletteRole: TProjectIconPaletteRole;
    SecondaryOpacity: Byte;
    FallbackBitmapResource: string;
    FallbackIconResource: string;
  end;

function GetProjectIconDescriptors: TArray<TProjectIconDescriptor>;
function ProjectIconDisplayName(const AKey: string): string;
function DefaultCustomToolIconKey(const AToolName: string): string;
procedure ResolveProjectIconPalette(ARole: TProjectIconPaletteRole;
  const ATheme: TDevShellTheme;
  out APrimaryColor, ASecondaryColor: TColor);
function BeginProjectIconRenderBatch: Boolean;
procedure EndProjectIconRenderBatch;
function ProjectIconCacheKey(const AKey: string; APixelSize: Integer;
  APrimaryColor, ASecondaryColor: TColor; AHighContrast,
  ADisabled: Boolean): string;
function TryGetProjectIcon(const AKey: string;
  out ADescriptor: TProjectIconDescriptor): Boolean;
function TryRenderProjectIcon(ABitmap: TBitmap; const AKey: string;
  APixelSize: Integer; APrimaryColor, ASecondaryColor: TColor;
  AHighContrast, ADisabled: Boolean; AResourceModule: HMODULE;
  out ASource: TProjectIconSource): Boolean;
function TryRenderProjectIconForSurface(ABitmap: TBitmap;
  const AKey: string; APixelSize: Integer;
  const ATheme: TDevShellTheme; ADisabled: Boolean;
  AResourceModule: HMODULE;
  out ASource: TProjectIconSource): Boolean;
function TryDrawProjectIcon(ADC: HDC; const AKey: string;
  const ADestRect: TRect; const ATheme: TDevShellTheme;
  ADisabled: Boolean; AResourceModule: HMODULE;
  out ASource: TProjectIconSource): Boolean;
function ValidateProjectIconCatalog(out AError: string): Boolean;

implementation

uses
  System.Classes,
  System.Math,
  System.Types,
  Vcl.Imaging.pngimage,
  DelphiDevShellTools.Logging,
  DelphiDevShellTools.Misc,
  DelphiDevShellTools.Phosphor.Font,
  DelphiDevShellTools.Phosphor.Names;

type
  TProjectIconAlias = record
    AliasKey: string;
    CanonicalKey: string;
  end;

  TProjectIconOverlay = record
    Id: TProjectIconId;
    PhosphorName: string;
    Code: Word;
    ScalePercent: Byte;
    CenterXPercent: Byte;
    CenterYPercent: Byte;
  end;

const
  cDefaultSecondaryOpacity = 76;
  cProjectIcons: array[0..47] of TProjectIconDescriptor = (
    (Id: piiNotepad; Key: 'notepad'; PhosphorName: 'notepad';
      Code: cPhNotepad; PaletteRole: pipEdit;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'notepad'; FallbackIconResource: 'notepad_ico'),
    (Id: piiCommandPrompt; Key: 'cmd'; PhosphorName: 'terminal';
      Code: cPhTerminal; PaletteRole: pipNeutral;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'cmd'; FallbackIconResource: 'cmd_ico'),
    (Id: piiCopy; Key: 'copy'; PhosphorName: 'copy';
      Code: cPhCopy; PaletteRole: pipCopy;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'copy'; FallbackIconResource: 'copy_ico'),
    (Id: piiMacOS; Key: 'osx'; PhosphorName: 'apple-logo';
      Code: cPhAppleLogo; PaletteRole: pipPlatform;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'osx'; FallbackIconResource: 'osx_ico'),
    (Id: piiIOS; Key: 'ios'; PhosphorName: 'device-mobile';
      Code: cPhDeviceMobile; PaletteRole: pipPlatform;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'ios'; FallbackIconResource: 'ios_ico'),
    (Id: piiWindows; Key: 'win'; PhosphorName: 'windows-logo';
      Code: cPhWindowsLogo; PaletteRole: pipPlatform;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'win'; FallbackIconResource: 'win_ico'),
    (Id: piiAndroid; Key: 'android'; PhosphorName: 'android-logo';
      Code: cPhAndroidLogo; PaletteRole: pipPlatform;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'android'; FallbackIconResource: 'android_ico'),
    (Id: piiDelphi; Key: 'delphi'; PhosphorName: 'code';
      Code: cPhCode; PaletteRole: pipFramework;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'delphi'; FallbackIconResource: 'delphi_ico'),
    (Id: piiDelphiUnavailable; Key: 'delphig'; PhosphorName: 'code';
      Code: cPhCode; PaletteRole: pipWarning;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'delphig'; FallbackIconResource: 'delphig_ico'),
    (Id: piiRadStudioCommandPrompt; Key: 'radcmd';
      PhosphorName: 'terminal-window'; Code: cPhTerminalWindow;
      PaletteRole: pipNeutral; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'radcmd'; FallbackIconResource: 'radcmd_ico'),
    (Id: piiMSBuild; Key: 'msbuild'; PhosphorName: 'hammer';
      Code: cPhHammer; PaletteRole: pipBuild;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'msbuild'; FallbackIconResource: 'msbuild_ico'),
    (Id: piiFireMonkey; Key: 'firemonkey'; PhosphorName: 'flame';
      Code: cPhFlame; PaletteRole: pipFramework;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'firemonkey';
      FallbackIconResource: 'firemonkey_ico'),
    (Id: piiVCL; Key: 'vcl'; PhosphorName: 'app-window';
      Code: cPhAppWindow; PaletteRole: pipFramework;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'vcl'; FallbackIconResource: 'vcl_ico'),
    (Id: piiLazarus; Key: 'lazarusmenu'; PhosphorName: 'code-block';
      Code: cPhCodeBlock; PaletteRole: pipFramework;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'lazarusmenu';
      FallbackIconResource: 'lazarusmenu_ico'),
    (Id: piiLazBuild; Key: 'lazbuild'; PhosphorName: 'hammer';
      Code: cPhHammer; PaletteRole: pipBuild;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'lazbuild';
      FallbackIconResource: 'lazbuild_ico'),
    (Id: piiBuildConfiguration; Key: 'buildconf';
      PhosphorName: 'sliders-horizontal'; Code: cPhSlidersHorizontal;
      PaletteRole: pipBuild; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'buildconf';
      FallbackIconResource: 'buildconf_ico'),
    (Id: piiPlatforms; Key: 'platforms'; PhosphorName: 'devices';
      Code: cPhDevices; PaletteRole: pipPlatform;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'platforms';
      FallbackIconResource: 'platforms_ico'),
    (Id: piiSettings; Key: 'settings'; PhosphorName: 'gear';
      Code: cPhGear; PaletteRole: pipNeutral;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'settings';
      FallbackIconResource: 'settings_ico'),
    (Id: piiCommonTasks; Key: 'common'; PhosphorName: 'list-checks';
      Code: cPhListChecks; PaletteRole: pipNeutral;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'common'; FallbackIconResource: 'common_ico'),
    (Id: piiChecksum; Key: 'checksum'; PhosphorName: 'fingerprint';
      Code: cPhFingerprint; PaletteRole: pipChecksum;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'checksum';
      FallbackIconResource: 'checksum_ico'),
    (Id: piiChecksumCRC32; Key: 'checksum_crc32';
      PhosphorName: 'arrows-clockwise'; Code: cPhArrowsClockwise;
      PaletteRole: pipChecksum; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'checksum';
      FallbackIconResource: 'checksum_ico'),
    (Id: piiChecksumMD4; Key: 'checksum_md4';
      PhosphorName: 'fingerprint'; Code: cPhFingerprint;
      PaletteRole: pipChecksum; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'checksum';
      FallbackIconResource: 'checksum_ico'),
    (Id: piiChecksumMD5; Key: 'checksum_md5';
      PhosphorName: 'hash'; Code: cPhHash;
      PaletteRole: pipChecksum; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'checksum';
      FallbackIconResource: 'checksum_ico'),
    (Id: piiChecksumSHA1; Key: 'checksum_sha1';
      PhosphorName: 'shield-check'; Code: cPhShieldCheck;
      PaletteRole: pipChecksum; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'checksum';
      FallbackIconResource: 'checksum_ico'),
    (Id: piiChecksumSHA256; Key: 'checksum_sha256';
      PhosphorName: 'shield-check'; Code: cPhShieldCheck;
      PaletteRole: pipChecksum; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'checksum';
      FallbackIconResource: 'checksum_ico'),
    (Id: piiChecksumSHA384; Key: 'checksum_sha384';
      PhosphorName: 'shield-check'; Code: cPhShieldCheck;
      PaletteRole: pipChecksum; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'checksum';
      FallbackIconResource: 'checksum_ico'),
    (Id: piiChecksumSHA512; Key: 'checksum_sha512';
      PhosphorName: 'shield-check'; Code: cPhShieldCheck;
      PaletteRole: pipChecksum; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'checksum';
      FallbackIconResource: 'checksum_ico'),
    (Id: piiCopyUNC; Key: 'copy_unc'; PhosphorName: 'path';
      Code: cPhPath; PaletteRole: pipLink;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'copy_unc';
      FallbackIconResource: 'copy_unc_ico'),
    (Id: piiCopyURL; Key: 'copy_url'; PhosphorName: 'link';
      Code: cPhLink; PaletteRole: pipLink;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'copy_url';
      FallbackIconResource: 'copy_url_ico'),
    (Id: piiCopyContent; Key: 'copy_content'; PhosphorName: 'clipboard-text';
      Code: cPhClipboardText; PaletteRole: pipCopy;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'copy_content';
      FallbackIconResource: 'copy_content_ico'),
    (Id: piiCopyPath; Key: 'copy_path'; PhosphorName: 'folder-open';
      Code: cPhFolderOpen; PaletteRole: pipCopy;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'copy_path';
      FallbackIconResource: 'copy_path_ico'),
    (Id: piiAdministrator; Key: 'shield'; PhosphorName: 'shield-check';
      Code: cPhShieldCheck; PaletteRole: pipPrivileged;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'shield'; FallbackIconResource: 'shield_ico'),
    (Id: piiFPCTools; Key: 'fpc_tools'; PhosphorName: 'toolbox';
      Code: cPhToolbox; PaletteRole: pipBuild;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'fpc_tools';
      FallbackIconResource: 'fpc_tools_ico'),
    (Id: piiExternalTools; Key: 'wrench'; PhosphorName: 'wrench';
      Code: cPhWrench; PaletteRole: pipNeutral;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: 'wrench'; FallbackIconResource: 'wrench_ico'),
    (Id: piiCustomFormatter; Key: 'tool_formatter'; PhosphorName: 'code';
      Code: cPhCode; PaletteRole: pipFramework;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomPackage; Key: 'tool_package'; PhosphorName: 'cube';
      Code: cPhCube; PaletteRole: pipBuild;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomDependency; Key: 'tool_dependency';
      PhosphorName: 'magnifying-glass'; Code: cPhMagnifyingGlass;
      PaletteRole: pipCopy; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomHeader; Key: 'tool_header'; PhosphorName: 'file-text';
      Code: cPhFileText; PaletteRole: pipCopy;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomTerminal; Key: 'tool_terminal'; PhosphorName: 'terminal';
      Code: cPhTerminal; PaletteRole: pipEdit;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomTouch; Key: 'tool_touch'; PhosphorName: 'hand-tap';
      Code: cPhHandTap; PaletteRole: pipWarning;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomResource; Key: 'tool_resource'; PhosphorName: 'cpu';
      Code: cPhCpu; PaletteRole: pipBuild;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomMetrics; Key: 'tool_metrics'; PhosphorName: 'chart-bar';
      Code: cPhChartBar; PaletteRole: pipCopy;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomAudits; Key: 'tool_audits'; PhosphorName: 'list-checks';
      Code: cPhListChecks; PaletteRole: pipCopy;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomStyle; Key: 'tool_style'; PhosphorName: 'palette';
      Code: cPhPalette; PaletteRole: pipFramework;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomDump32; Key: 'tool_dump32'; PhosphorName: 'app-window';
      Code: cPhAppWindow; PaletteRole: pipCopy;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomDump64; Key: 'tool_dump64'; PhosphorName: 'app-window';
      Code: cPhAppWindow; PaletteRole: pipCopy;
      SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomRegister; Key: 'tool_register';
      PhosphorName: 'shield-check'; Code: cPhShieldCheck;
      PaletteRole: pipEdit; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: ''),
    (Id: piiCustomUnregister; Key: 'tool_unregister';
      PhosphorName: 'shield-slash'; Code: cPhShieldSlash;
      PaletteRole: pipWarning; SecondaryOpacity: cDefaultSecondaryOpacity;
      FallbackBitmapResource: ''; FallbackIconResource: '')
  );

  cProjectIconOverlays: array[0..11] of TProjectIconOverlay = (
    (Id: piiDelphiUnavailable; PhosphorName: 'warning';
      Code: cPhWarning; ScalePercent: 55; CenterXPercent: 72; CenterYPercent: 72),
    (Id: piiCopyUNC; PhosphorName: 'copy';
      Code: cPhCopy; ScalePercent: 48; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiCopyURL; PhosphorName: 'copy';
      Code: cPhCopy; ScalePercent: 48; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiCopyContent; PhosphorName: 'copy';
      Code: cPhCopy; ScalePercent: 48; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiCopyPath; PhosphorName: 'copy';
      Code: cPhCopy; ScalePercent: 48; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiChecksumCRC32; PhosphorName: 'binary';
      Code: cPhBinary; ScalePercent: 68; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiChecksumMD4; PhosphorName: 'cube';
      Code: cPhCube; ScalePercent: 68; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiChecksumMD5; PhosphorName: 'database';
      Code: cPhDatabase; ScalePercent: 68; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiChecksumSHA1; PhosphorName: 'number-circle-one';
      Code: cPhNumberCircleOne; ScalePercent: 68; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiChecksumSHA256; PhosphorName: 'binary';
      Code: cPhBinary; ScalePercent: 68; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiChecksumSHA384; PhosphorName: 'stack';
      Code: cPhStack; ScalePercent: 68; CenterXPercent: 76; CenterYPercent: 76),
    (Id: piiChecksumSHA512; PhosphorName: 'files';
      Code: cPhFiles; ScalePercent: 68; CenterXPercent: 76; CenterYPercent: 76)
  );

  cProjectIconAliases: array[0..4] of TProjectIconAlias = (
    (AliasKey: 'delphi2'; CanonicalKey: 'delphi'),
    (AliasKey: 'firemonkey2'; CanonicalKey: 'firemonkey'),
    (AliasKey: 'vcl2'; CanonicalKey: 'vcl'),
    (AliasKey: 'buildconf2'; CanonicalKey: 'buildconf'),
    (AliasKey: 'platforms2'; CanonicalKey: 'platforms')
  );

function CanonicalProjectIconKey(const AKey: string): string;
begin
  Result := LowerCase(Trim(AKey));
  for var LAlias in cProjectIconAliases do
    if SameText(Result, LAlias.AliasKey) then
      Exit(LAlias.CanonicalKey);
  if Result.EndsWith('_ico', True) then
    Delete(Result, Length(Result) - 3, 4);
  for var LAlias in cProjectIconAliases do
    if SameText(Result, LAlias.AliasKey) then
      Exit(LAlias.CanonicalKey);
end;


function GetProjectIconDescriptors: TArray<TProjectIconDescriptor>;
begin
  SetLength(Result, Length(cProjectIcons));
  for var LIndex := Low(cProjectIcons) to High(cProjectIcons) do
    Result[LIndex] := cProjectIcons[LIndex];
end;

function ProjectIconDisplayName(const AKey: string): string;
var
  LDescriptor: TProjectIconDescriptor;
begin
  if not TryGetProjectIcon(AKey, LDescriptor) then
    Exit(ChangeFileExt(ExtractFileName(AKey), ''));

  case LDescriptor.Id of
    piiCommandPrompt: Result := 'Command prompt';
    piiMacOS: Result := 'macOS';
    piiIOS: Result := 'iOS';
    piiWindows: Result := 'Windows';
    piiDelphiUnavailable: Result := 'Delphi unavailable';
    piiRadStudioCommandPrompt: Result := 'RAD Studio command prompt';
    piiMSBuild: Result := 'MSBuild';
    piiFireMonkey: Result := 'FireMonkey';
    piiVCL: Result := 'VCL';
    piiLazarus: Result := 'Lazarus';
    piiLazBuild: Result := 'Lazarus build';
    piiBuildConfiguration: Result := 'Build configuration';
    piiCommonTasks: Result := 'Common tasks';
    piiChecksumCRC32: Result := 'Checksum CRC32';
    piiChecksumMD4: Result := 'Checksum MD4';
    piiChecksumMD5: Result := 'Checksum MD5';
    piiChecksumSHA1: Result := 'Checksum SHA-1';
    piiChecksumSHA256: Result := 'Checksum SHA-256';
    piiChecksumSHA384: Result := 'Checksum SHA-384';
    piiChecksumSHA512: Result := 'Checksum SHA-512';
    piiCopyUNC: Result := 'Copy UNC path';
    piiCopyURL: Result := 'Copy URL';
    piiCopyContent: Result := 'Copy content';
    piiCopyPath: Result := 'Copy path';
    piiFPCTools: Result := 'FPC tools';
    piiExternalTools: Result := 'External tools';
    piiCustomFormatter: Result := 'Formatter';
    piiCustomPackage: Result := 'Package';
    piiCustomDependency: Result := 'Dependency';
    piiCustomHeader: Result := 'Header';
    piiCustomTerminal: Result := 'Terminal';
    piiCustomTouch: Result := 'Touch file';
    piiCustomResource: Result := 'Resource';
    piiCustomMetrics: Result := 'Metrics';
    piiCustomAudits: Result := 'Audits';
    piiCustomStyle: Result := 'Styles';
    piiCustomDump32: Result := 'TDump 32';
    piiCustomDump64: Result := 'TDump 64';
    piiCustomRegister: Result := 'Register';
    piiCustomUnregister: Result := 'Unregister';
  else
    Result := StringReplace(LDescriptor.Key, '_', ' ', [rfReplaceAll]);
    if Result <> '' then
      Result[1] := UpCase(Result[1]);
  end;
end;

function DefaultCustomToolIconKey(const AToolName: string): string;
begin
  if SameText(AToolName, 'Formatter Delphi') then
    Result := 'tool_formatter'
  else if SameText(AToolName, 'ppudump') then
    Result := 'tool_package'
  else if SameText(AToolName, 'ppdep') then
    Result := 'tool_dependency'
  else if SameText(AToolName, 'h2pas') then
    Result := 'tool_header'
  else if SameText(AToolName, 'ptop') then
    Result := 'tool_terminal'
  else if SameText(AToolName, 'Touch') then
    Result := 'tool_touch'
  else if SameText(AToolName, 'BRCC32') then
    Result := 'tool_resource'
  else if SameText(AToolName, 'AuditsCLI Metrics') then
    Result := 'tool_metrics'
  else if SameText(AToolName, 'AuditsCLI Audits') then
    Result := 'tool_audits'
  else if SameText(AToolName, 'OpenFMXStyle') then
    Result := 'tool_style'
  else if SameText(AToolName, 'TDump 32') then
    Result := 'tool_dump32'
  else if SameText(AToolName, 'TDump 64') then
    Result := 'tool_dump64'
  else if SameText(AToolName, 'RegSvr32 Install') then
    Result := 'tool_register'
  else if SameText(AToolName, 'RegSvr32 Uninstall') then
    Result := 'tool_unregister'
  else
    Result := 'wrench';
end;

function BeginProjectIconRenderBatch: Boolean;
var
  LFont: TPhosphorFont;
begin
  Result := TryGetPhosphorFont(LFont);
  if Result then
    LFont.BeginRenderSession;
end;

procedure EndProjectIconRenderBatch;
var
  LFont: TPhosphorFont;
begin
  if TryGetPhosphorFont(LFont) then
    LFont.EndRenderSession;
end;

procedure ResolveProjectIconPalette(ARole: TProjectIconPaletteRole;
  const ATheme: TDevShellTheme;
  out APrimaryColor, ASecondaryColor: TColor);
begin
  if ATheme.HighContrast then
  begin
    APrimaryColor := ATheme.TextColor;
    ASecondaryColor := ATheme.TextColor;
    Exit;
  end;
  case ARole of
    pipNeutral,
    pipPlatform: APrimaryColor := ATheme.MutedColor;
    pipCopy: APrimaryColor := ATheme.PrimaryColor;
    pipLink: APrimaryColor := ATheme.SecondaryColor;
    pipEdit: APrimaryColor := ATheme.SuccessColor;
    pipFramework,
    pipChecksum: APrimaryColor := ATheme.PrimaryColor;
    pipBuild,
    pipWarning,
    pipPrivileged: APrimaryColor := ATheme.WarningColor;
  end;
  ASecondaryColor := APrimaryColor;
end;

function ProjectIconCacheKey(const AKey: string; APixelSize: Integer;
  APrimaryColor, ASecondaryColor: TColor; AHighContrast,
  ADisabled: Boolean): string;
begin
  Result := Format('phosphor|%s|%d|%.8x|%.8x|%d|%d',
    [CanonicalProjectIconKey(AKey), APixelSize, ColorToRGB(APrimaryColor),
     ColorToRGB(ASecondaryColor), Ord(AHighContrast), Ord(ADisabled)]);
end;

function TryGetProjectIcon(const AKey: string;
  out ADescriptor: TProjectIconDescriptor): Boolean;
begin
  ADescriptor := Default(TProjectIconDescriptor);
  var LKey := CanonicalProjectIconKey(AKey);
  for var LDescriptor in cProjectIcons do
    if SameText(LKey, LDescriptor.Key) then
    begin
      ADescriptor := LDescriptor;
      Exit(True);
    end;
  Result := False;
end;

function TryLoadFallbackBitmap(ABitmap: TBitmap;
  const ADescriptor: TProjectIconDescriptor; APixelSize: Integer;
  AResourceModule: HMODULE): Boolean;
begin
  Result := False;
  if (ABitmap = nil) or (APixelSize <= 0) or
     (ADescriptor.FallbackBitmapResource = '') then
    Exit;
  if AResourceModule = 0 then
    AResourceModule := HInstance;
  try
    var LPng := TPngImage.Create;
    try
      LPng.LoadFromResourceName(AResourceModule,
        ADescriptor.FallbackBitmapResource);
      var LSourceBitmap := TBitmap.Create;
      try
        LSourceBitmap.Assign(LPng);
        if (LSourceBitmap.Width = APixelSize) and
           (LSourceBitmap.Height = APixelSize) then
          ABitmap.Assign(LSourceBitmap)
        else
          ScaleImage32(LSourceBitmap, ABitmap,
            APixelSize / LSourceBitmap.Width);
        Result := True;
      finally
        LSourceBitmap.Free;
      end;
    finally
      LPng.Free;
    end;
  except
    ABitmap.SetSize(0, 0);
    Result := False;
  end;
end;

function TryRenderProjectIcon(ABitmap: TBitmap; const AKey: string;
  APixelSize: Integer; APrimaryColor, ASecondaryColor: TColor;
  AHighContrast, ADisabled: Boolean; AResourceModule: HMODULE;
  out ASource: TProjectIconSource): Boolean;
var
  LBlend: TBlendFunction;
  LDescriptor: TProjectIconDescriptor;
  LFont: TPhosphorFont;
  LOverlay: TProjectIconOverlay;
begin
  ASource := pisNone;
  Result := False;
  if (ABitmap = nil) or (APixelSize <= 0) or
     not TryGetProjectIcon(AKey, LDescriptor) then
    Exit;
  if TryGetPhosphorFont(LFont) then
  begin
    LFont.BeginRenderSession;
    try
      try
        if AHighContrast then
          LFont.RenderIconBitmap(ABitmap, LDescriptor.Code, APixelSize,
            APrimaryColor, pfwBold)
        else
          LFont.RenderDuotoneBitmap(ABitmap, LDescriptor.Code, APixelSize,
            APrimaryColor, ASecondaryColor, LDescriptor.SecondaryOpacity);
        for LOverlay in cProjectIconOverlays do
          if LOverlay.Id = LDescriptor.Id then
          begin
            var LOverlaySize := Max(8,
              MulDiv(APixelSize, LOverlay.ScalePercent, 100));
            var LOverlayColor := ASecondaryColor;
            if AHighContrast or ADisabled then
              LOverlayColor := APrimaryColor;
            var LOverlayLeft := MulDiv(APixelSize,
              LOverlay.CenterXPercent, 100) - LOverlaySize div 2;
            LOverlayLeft := Max(0,
              Min(APixelSize - LOverlaySize, LOverlayLeft));
            var LOverlayTop := MulDiv(APixelSize,
              LOverlay.CenterYPercent, 100) - LOverlaySize div 2;
            LOverlayTop := Max(0,
              Min(APixelSize - LOverlaySize, LOverlayTop));
            var LOverlayBitmap := TBitmap.Create;
            try
              LFont.RenderIconBitmap(LOverlayBitmap, LOverlay.Code,
                LOverlaySize, LOverlayColor, pfwBold);
              ZeroMemory(@LBlend, SizeOf(LBlend));
              LBlend.BlendOp := AC_SRC_OVER;
              LBlend.SourceConstantAlpha := 255;
              LBlend.AlphaFormat := AC_SRC_ALPHA;
              if not Winapi.Windows.AlphaBlend(ABitmap.Canvas.Handle,
                LOverlayLeft, LOverlayTop,
                LOverlaySize, LOverlaySize, LOverlayBitmap.Canvas.Handle,
                0, 0, LOverlaySize, LOverlaySize, LBlend) then
                RaiseLastOSError;
              if not GdiFlush then
                RaiseLastOSError;
            finally
              LOverlayBitmap.Free;
            end;
            ABitmap.AlphaFormat := afPremultiplied;
          end;
        ASource := pisPhosphor;
        Exit(True);
      except
        on E: Exception do
        begin
          Log(Format('Phosphor render failed for %s: %s',
            [AKey, E.Message]));
          ABitmap.SetSize(0, 0);
        end;
      end;
    finally
      LFont.EndRenderSession;
    end;
  end;
  Result := TryLoadFallbackBitmap(ABitmap, LDescriptor, APixelSize,
    AResourceModule);
  if Result then
    ASource := pisFallbackResource;
end;

function TryRenderProjectIconForSurface(ABitmap: TBitmap;
  const AKey: string; APixelSize: Integer;
  const ATheme: TDevShellTheme; ADisabled: Boolean;
  AResourceModule: HMODULE;
  out ASource: TProjectIconSource): Boolean;
var
  LDescriptor: TProjectIconDescriptor;
  LPrimaryColor: TColor;
  LSecondaryColor: TColor;
begin
  ASource := pisNone;
  if not TryGetProjectIcon(AKey, LDescriptor) then
    Exit(False);
  ResolveProjectIconPalette(LDescriptor.PaletteRole, ATheme, LPrimaryColor,
    LSecondaryColor);
  Result := TryRenderProjectIcon(ABitmap, LDescriptor.Key, APixelSize,
    LPrimaryColor, LSecondaryColor, ATheme.HighContrast, ADisabled,
    AResourceModule, ASource);
end;

function TryDrawProjectIcon(ADC: HDC; const AKey: string;
  const ADestRect: TRect; const ATheme: TDevShellTheme;
  ADisabled: Boolean; AResourceModule: HMODULE;
  out ASource: TProjectIconSource): Boolean;
var
  LBlend: TBlendFunction;
begin
  ASource := pisNone;
  if (ADC = 0) or (ADestRect.Width <= 0) or (ADestRect.Height <= 0) or
     (ADestRect.Width <> ADestRect.Height) then
    Exit(False);
  var LBitmap := TBitmap.Create;
  try
    Result := TryRenderProjectIconForSurface(LBitmap, AKey,
      ADestRect.Width, ATheme, ADisabled, AResourceModule, ASource);
    if not Result then
      Exit;
    ZeroMemory(@LBlend, SizeOf(LBlend));
    LBlend.BlendOp := AC_SRC_OVER;
    LBlend.SourceConstantAlpha := 255;
    LBlend.AlphaFormat := AC_SRC_ALPHA;
    Result := Winapi.Windows.AlphaBlend(ADC, ADestRect.Left,
      ADestRect.Top, ADestRect.Width, ADestRect.Height,
      LBitmap.Canvas.Handle, 0, 0, LBitmap.Width, LBitmap.Height, LBlend);
    if Result then
      Result := GdiFlush;
    if not Result then
      ASource := pisNone;
  finally
    LBitmap.Free;
  end;
end;

function ValidateProjectIconCatalog(out AError: string): Boolean;
var
  LDescriptor: TProjectIconDescriptor;
  LFont: TPhosphorFont;
begin
  AError := '';
  for var LIndex := Low(cProjectIcons) to High(cProjectIcons) do
  begin
    LDescriptor := cProjectIcons[LIndex];
    if LDescriptor.Key = '' then
    begin
      AError := Format('Icon %d has no stable key', [Ord(LDescriptor.Id)]);
      Exit(False);
    end;
    if not SameText(GetPhosphorIconName(LDescriptor.Code),
      LDescriptor.PhosphorName) then
    begin
      AError := Format('%s maps code %.4x to %s instead of %s',
        [LDescriptor.Key, LDescriptor.Code,
         GetPhosphorIconName(LDescriptor.Code), LDescriptor.PhosphorName]);
      Exit(False);
    end;
    for var LPriorIndex := Low(cProjectIcons) to LIndex - 1 do
      if SameText(LDescriptor.Key, cProjectIcons[LPriorIndex].Key) then
      begin
        AError := Format('Duplicate project icon key %s', [LDescriptor.Key]);
        Exit(False);
      end;
  end;
  for var LOverlay in cProjectIconOverlays do
  begin
    if not SameText(GetPhosphorIconName(LOverlay.Code),
      LOverlay.PhosphorName) then
    begin
      AError := Format('Overlay maps code %.4x to %s instead of %s',
        [LOverlay.Code, GetPhosphorIconName(LOverlay.Code),
         LOverlay.PhosphorName]);
      Exit(False);
    end;
    if (LOverlay.ScalePercent < 25) or (LOverlay.ScalePercent > 75) then
    begin
      AError := Format('Overlay %s has invalid scale %d',
        [LOverlay.PhosphorName, LOverlay.ScalePercent]);
      Exit(False);
    end;
    if (LOverlay.CenterXPercent > 100) or
       (LOverlay.CenterYPercent > 100) then
    begin
      AError := Format('Overlay %s has an invalid anchor',
        [LOverlay.PhosphorName]);
      Exit(False);
    end;
  end;
  for var LAlias in cProjectIconAliases do
    if not TryGetProjectIcon(LAlias.CanonicalKey, LDescriptor) then
    begin
      AError := Format('Alias %s has unknown target %s',
        [LAlias.AliasKey, LAlias.CanonicalKey]);
      Exit(False);
    end;
  if not TryGetPhosphorFont(LFont) then
  begin
    AError := 'Phosphor font provider could not be created';
    Exit(False);
  end;
  try
    for var LOverlay in cProjectIconOverlays do
    begin
      if not LFont.HasGlyph(LOverlay.Code, pfwRegular) then
      begin
        AError := Format('Overlay %s code %.4x is missing from Regular',
          [LOverlay.PhosphorName, LOverlay.Code]);
        Exit(False);
      end;
      if not LFont.HasGlyph(LOverlay.Code, pfwDuotone) then
      begin
        AError := Format('Overlay %s code %.4x is missing from Duotone',
          [LOverlay.PhosphorName, LOverlay.Code]);
        Exit(False);
      end;
    end;
    for LDescriptor in cProjectIcons do
    begin
      if Odd(LDescriptor.Code) then
      begin
        AError := Format('%s code %.4x is not a Duotone base code',
          [LDescriptor.Key, LDescriptor.Code]);
        Exit(False);
      end;
      if not LFont.HasGlyph(LDescriptor.Code, pfwRegular) then
      begin
        AError := Format('%s code %.4x is missing from Regular',
          [LDescriptor.Key, LDescriptor.Code]);
        Exit(False);
      end;
      if not LFont.HasGlyph(LDescriptor.Code, pfwDuotone) then
      begin
        AError := Format('%s code %.4x is missing from Duotone',
          [LDescriptor.Key, LDescriptor.Code]);
        Exit(False);
      end;
      if not LFont.HasGlyph(LDescriptor.Code + 1, pfwDuotone) then
      begin
        AError := Format('%s primary code %.4x is missing from Duotone',
          [LDescriptor.Key, LDescriptor.Code + 1]);
        Exit(False);
      end;
      if not LFont.HasGlyph(LDescriptor.Code, pfwBold) then
      begin
        AError := Format('%s code %.4x is missing from Bold',
          [LDescriptor.Key, LDescriptor.Code]);
        Exit(False);
      end;
    end;
  except
    on E: Exception do
    begin
      AError := E.Message;
      Exit(False);
    end;
  end;
  Result := True;
end;

end.
