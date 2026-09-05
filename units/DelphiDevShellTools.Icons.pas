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
  Vcl.Graphics;

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
    piiExternalTools);

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
procedure ResolveProjectIconPalette(ARole: TProjectIconPaletteRole;
  ABackgroundColor, AForegroundColor: TColor; AHighContrast: Boolean;
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
  ABackgroundColor, AForegroundColor: TColor; AHighContrast,
  ADisabled: Boolean; AResourceModule: HMODULE;
  out ASource: TProjectIconSource): Boolean;
function TryDrawProjectIcon(ADC: HDC; const AKey: string;
  const ADestRect: TRect; ABackgroundColor, AForegroundColor: TColor;
  AHighContrast, ADisabled: Boolean; AResourceModule: HMODULE;
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
  cProjectIcons: array[0..33] of TProjectIconDescriptor = (
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
      FallbackBitmapResource: 'wrench'; FallbackIconResource: 'wrench_ico')
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
  ABackgroundColor, AForegroundColor: TColor; AHighContrast: Boolean;
  out APrimaryColor, ASecondaryColor: TColor);
const
  cDarkBackgroundThreshold = 384;
begin
  if AHighContrast then
  begin
    APrimaryColor := AForegroundColor;
    ASecondaryColor := AForegroundColor;
    Exit;
  end;
  var LBackground := ColorToRGB(ABackgroundColor);
  var LDark := (GetRValue(LBackground) + GetGValue(LBackground) +
    GetBValue(LBackground)) < cDarkBackgroundThreshold;
  if LDark then
    case ARole of
      pipNeutral: APrimaryColor := RGB(174, 184, 194);
      pipCopy: APrimaryColor := RGB(85, 178, 239);
      pipLink: APrimaryColor := RGB(65, 192, 181);
      pipEdit: APrimaryColor := RGB(116, 196, 111);
      pipPlatform: APrimaryColor := RGB(168, 181, 191);
      pipFramework: APrimaryColor := RGB(185, 135, 244);
      pipBuild: APrimaryColor := RGB(245, 136, 79);
      pipChecksum: APrimaryColor := RGB(194, 139, 242);
      pipWarning: APrimaryColor := RGB(255, 180, 74);
      pipPrivileged: APrimaryColor := RGB(232, 179, 53);
    end
  else
    case ARole of
      pipNeutral: APrimaryColor := RGB(73, 84, 96);
      pipCopy: APrimaryColor := RGB(0, 105, 180);
      pipLink: APrimaryColor := RGB(0, 128, 120);
      pipEdit: APrimaryColor := RGB(31, 124, 55);
      pipPlatform: APrimaryColor := RGB(69, 87, 102);
      pipFramework: APrimaryColor := RGB(118, 64, 174);
      pipBuild: APrimaryColor := RGB(190, 72, 25);
      pipChecksum: APrimaryColor := RGB(120, 62, 165);
      pipWarning: APrimaryColor := RGB(184, 91, 0);
      pipPrivileged: APrimaryColor := RGB(145, 94, 0);
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
  ABackgroundColor, AForegroundColor: TColor; AHighContrast,
  ADisabled: Boolean; AResourceModule: HMODULE;
  out ASource: TProjectIconSource): Boolean;
var
  LDescriptor: TProjectIconDescriptor;
  LPrimaryColor: TColor;
  LSecondaryColor: TColor;
begin
  ASource := pisNone;
  if not TryGetProjectIcon(AKey, LDescriptor) then
    Exit(False);
  ResolveProjectIconPalette(LDescriptor.PaletteRole, ABackgroundColor,
    AForegroundColor, AHighContrast, LPrimaryColor, LSecondaryColor);
  Result := TryRenderProjectIcon(ABitmap, LDescriptor.Key, APixelSize,
    LPrimaryColor, LSecondaryColor, AHighContrast, ADisabled,
    AResourceModule, ASource);
end;

function TryDrawProjectIcon(ADC: HDC; const AKey: string;
  const ADestRect: TRect; ABackgroundColor, AForegroundColor: TColor;
  AHighContrast, ADisabled: Boolean; AResourceModule: HMODULE;
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
      ADestRect.Width, ABackgroundColor, AForegroundColor, AHighContrast,
      ADisabled, AResourceModule, ASource);
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
