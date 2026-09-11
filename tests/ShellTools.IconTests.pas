//**************************************************************************************************
//
// Unit ShellTools.IconTests
// Tests the semantic Phosphor catalogue and DPI-ready duotone rendering provider.
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
// The Original Code is ShellTools.IconTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.IconTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TIconTests = class
  private
    FRenderBatchActive: Boolean;
  public
    [SetupFixture] procedure BeginRenderBatch;
    [TearDownFixture] procedure EndRenderBatch;
    [Test] procedure CatalogMapsEveryGlyphAndExclusion;
    [TestCase('16 px', '16')]
    [TestCase('24 px', '24')]
    [TestCase('32 px', '32')]
    procedure EveryCatalogIconRendersAtMenuSize(APixelSize: Integer);
    [Test] procedure AliasesAndCacheIdentityAreStable;
    [TestCase('16 px', '16')]
    [TestCase('20 px', '20')]
    [TestCase('24 px', '24')]
    [TestCase('32 px', '32')]
    procedure DuotoneBitmapMatchesRequestedSize(APixelSize: Integer);
    [Test] procedure BitmapRendererHonorsPrimaryWeight;
    [Test] procedure CrispDuotoneCompositionIncludesBothVisualLayers;
    [TestCase('Copy', 'copy')]
    [TestCase('Open in Delphi', 'delphi')]
    [TestCase('Build', 'msbuild')]
    [TestCase('Copy path', 'copy_path')]
    [TestCase('RAD command prompt', 'radcmd')]
    procedure MenuGlyphOccupiesTheAvailableCanvas(const AKey: string);
    [Test] procedure CompositeIconAddsItsSemanticBadge;
    [Test] procedure AlgorithmAndCopyVariantsRenderDistinctCompositions;
    [Test] procedure DirectDrawingPreservesHostDCStateAndClip;
    [Test] procedure HighContrastUsesTheBoldGlyph;
    [Test] procedure ChecksumUsesTheFingerprintGlyph;
    [Test] procedure PaletteRolesUseTheActiveShellTheme;
    [Test] procedure RepeatedRenderingReleasesGdiObjects;
  end;

implementation

uses
  Winapi.Windows,
  System.Math,
  System.SysUtils,
  System.Types,
  Vcl.Graphics,
  DelphiDevShellTools.UI,
  DelphiDevShellTools.Icons,
  DelphiDevShellTools.Phosphor.Font;

function AlphaAt(const ABitmap: TBitmap; AX, AY: Integer): Byte;
begin
  var LPixel := PByte(ABitmap.ScanLine[AY]);
  Inc(LPixel, AX * 4 + 3);
  Result := LPixel^;
end;

function BitmapsMatch(const ALeft, ARight: TBitmap): Boolean;
begin
  Result := (ALeft.Width = ARight.Width) and
    (ALeft.Height = ARight.Height);
  if not Result then
    Exit;
  var LRowBytes := ALeft.Width * 4;
  for var LY := 0 to ALeft.Height - 1 do
    if not CompareMem(ALeft.ScanLine[LY], ARight.ScanLine[LY], LRowBytes) then
      Exit(False);
end;

function VisiblePixelCount(const ABitmap: TBitmap): Integer;
begin
  Result := 0;
  for var LY := 0 to ABitmap.Height - 1 do
    for var LX := 0 to ABitmap.Width - 1 do
      if AlphaAt(ABitmap, LX, LY) <> 0 then
        Inc(Result);
end;

function TryGetVisibleBounds(const ABitmap: TBitmap;
  out ABounds: TRect): Boolean;
begin
  Result := False;
  ABounds := Rect(ABitmap.Width, ABitmap.Height, 0, 0);
  for var LY := 0 to ABitmap.Height - 1 do
    for var LX := 0 to ABitmap.Width - 1 do
      if AlphaAt(ABitmap, LX, LY) <> 0 then
      begin
        ABounds.Left := Min(ABounds.Left, LX);
        ABounds.Top := Min(ABounds.Top, LY);
        ABounds.Right := Max(ABounds.Right, LX + 1);
        ABounds.Bottom := Max(ABounds.Bottom, LY + 1);
        Result := True;
      end;
end;

procedure TIconTests.AliasesAndCacheIdentityAreStable;
var
  LCanonical: TProjectIconDescriptor;
  LAlias: TProjectIconDescriptor;
begin
  Assert.IsTrue(TryGetProjectIcon('delphi', LCanonical));
  Assert.IsTrue(TryGetProjectIcon('delphi2', LAlias));
  Assert.AreEqual(LCanonical.Code, LAlias.Code);
  Assert.IsTrue(TryGetProjectIcon('delphi_ico', LAlias));
  Assert.AreEqual(LCanonical.Code, LAlias.Code);
  Assert.AreEqual(
    ProjectIconCacheKey('delphi', 16, clBlack, clGray, False, False),
    ProjectIconCacheKey('delphi2', 16, clBlack, clGray, False, False));
  Assert.AreNotEqual(
    ProjectIconCacheKey('delphi', 16, clBlack, clGray, False, False),
    ProjectIconCacheKey('delphi', 20, clBlack, clGray, False, False));
  Assert.AreNotEqual(
    ProjectIconCacheKey('delphi', 16, clBlack, clGray, False, False),
    ProjectIconCacheKey('delphi', 16, clBlack, clGray, True, False));
  Assert.AreNotEqual(
    ProjectIconCacheKey('delphi', 16, clBlack, clGray, False, False),
    ProjectIconCacheKey('delphi', 16, clBlack, clGray, False, True));
end;


procedure TIconTests.BeginRenderBatch;
begin
  FRenderBatchActive := BeginProjectIconRenderBatch;
  Assert.IsTrue(FRenderBatchActive,
    'Phosphor render batch could not be initialized');
end;

procedure TIconTests.EndRenderBatch;
begin
  if FRenderBatchActive then
    EndProjectIconRenderBatch;
end;

procedure TIconTests.BitmapRendererHonorsPrimaryWeight;
var
  LFont: TPhosphorFont;
begin
  Assert.IsTrue(TryGetPhosphorFont(LFont));
  var LRegular := TBitmap.Create;
  try
    var LBold := TBitmap.Create;
    try
      LFont.RenderIconBitmap(LRegular, cPhGear, 16, RGB(85, 178, 239),
        pfwRegular);
      LFont.RenderIconBitmap(LBold, cPhGear, 16, RGB(85, 178, 239),
        pfwBold);
      Assert.IsFalse(BitmapsMatch(LRegular, LBold),
        'Regular and Bold must produce different rasterized pixels');
      Assert.IsTrue(VisiblePixelCount(LBold) > 0,
        'Bold menu-size rendering must remain visible');
    finally
      LBold.Free;
    end;
  finally
    LRegular.Free;
  end;
end;

procedure TIconTests.EveryCatalogIconRendersAtMenuSize(APixelSize: Integer);
var
  LSource: TProjectIconSource;
begin
  var LBitmap := TBitmap.Create;
  try
    for var LDescriptor in GetProjectIconDescriptors do
    begin
      Assert.IsTrue(TryRenderProjectIcon(LBitmap, LDescriptor.Key, APixelSize,
        RGB(85, 178, 239), RGB(50, 140, 220), False, False, HInstance, LSource),
        LDescriptor.Key);
      Assert.AreEqual(Ord(pisPhosphor), Ord(LSource), LDescriptor.Key);
      Assert.IsTrue(VisiblePixelCount(LBitmap) > 0, LDescriptor.Key);
      Assert.AreEqual(APixelSize, LBitmap.Width, LDescriptor.Key);
      Assert.AreEqual(APixelSize, LBitmap.Height, LDescriptor.Key);
    end;
  finally
    LBitmap.Free;
  end;
end;


procedure TIconTests.CatalogMapsEveryGlyphAndExclusion;
const
  cExpectedKeys: array[0..47] of string = (
    'notepad', 'cmd', 'copy', 'osx',
    'ios', 'win', 'android', 'delphi',
    'delphig', 'radcmd', 'msbuild', 'firemonkey',
    'vcl', 'lazarusmenu', 'lazbuild', 'buildconf',
    'platforms', 'settings', 'common', 'checksum',
    'checksum_crc32', 'checksum_md4', 'checksum_md5', 'checksum_sha1',
    'checksum_sha256', 'checksum_sha384', 'checksum_sha512', 'copy_unc',
    'copy_url', 'copy_content', 'copy_path', 'shield',
    'fpc_tools', 'wrench', 'tool_formatter', 'tool_package',
    'tool_dependency', 'tool_header', 'tool_terminal', 'tool_touch',
    'tool_resource', 'tool_metrics', 'tool_audits', 'tool_style',
    'tool_dump32', 'tool_dump64', 'tool_register', 'tool_unregister');
var
  LDescriptor: TProjectIconDescriptor;
  LError: string;
begin
  Assert.AreEqual<Integer>(Length(cExpectedKeys), Length(GetProjectIconDescriptors));
  for var LKey in cExpectedKeys do
    Assert.IsTrue(TryGetProjectIcon(LKey, LDescriptor), LKey);
  Assert.IsTrue(ValidateProjectIconCatalog(LError), LError);
  Assert.IsFalse(TryGetProjectIcon('logo', LDescriptor));
  Assert.IsFalse(TryGetProjectIcon('logo_ico', LDescriptor));
  Assert.IsFalse(TryGetProjectIcon('bullet_green.ico', LDescriptor));
end;

procedure TIconTests.DuotoneBitmapMatchesRequestedSize(APixelSize: Integer);
var
  LSource: TProjectIconSource;
begin
  var LBitmap := TBitmap.Create;
  try
    Assert.IsTrue(TryRenderProjectIcon(LBitmap, 'settings', APixelSize,
      RGB(24, 70, 120), RGB(50, 140, 220), False, False, HInstance,
      LSource));
    Assert.AreEqual(Ord(pisPhosphor), Ord(LSource));
    Assert.AreEqual(APixelSize, LBitmap.Width);
    Assert.AreEqual(APixelSize, LBitmap.Height);
    Assert.AreEqual(Ord(pf32bit), Ord(LBitmap.PixelFormat));
    Assert.AreEqual(Ord(afPremultiplied), Ord(LBitmap.AlphaFormat));
    var LVisiblePixels := 0;
    for var LY := 0 to LBitmap.Height - 1 do
      for var LX := 0 to LBitmap.Width - 1 do
        if AlphaAt(LBitmap, LX, LY) <> 0 then
          Inc(LVisiblePixels);
    Assert.IsTrue(LVisiblePixels > 0, 'Rendered glyph must contain pixels');
  finally
    LBitmap.Free;
  end;
end;

procedure TIconTests.AlgorithmAndCopyVariantsRenderDistinctCompositions;
const
  cVariantKeys: array[0..10] of string = (
    'checksum_crc32', 'checksum_md4', 'checksum_md5', 'checksum_sha1',
    'checksum_sha256', 'checksum_sha384', 'checksum_sha512', 'copy_unc',
    'copy_url', 'copy_content', 'copy_path');
var
  LDescriptor: TProjectIconDescriptor;
  LFont: TPhosphorFont;
  LSource: TProjectIconSource;
begin
  Assert.IsTrue(TryGetPhosphorFont(LFont));
  for var LKey in cVariantKeys do
  begin
    var LBitmap := TBitmap.Create;
    try
      Assert.IsTrue(TryRenderProjectIcon(LBitmap, LKey, 32,
        RGB(31, 58, 95), RGB(225, 112, 24), False, False, HInstance,
        LSource), LKey);
      Assert.AreEqual(Ord(pisPhosphor), Ord(LSource), LKey);
      Assert.AreEqual(32, LBitmap.Width, LKey);
      Assert.AreEqual(32, LBitmap.Height, LKey);
    finally
      LBitmap.Free;
    end;
  end;

  Assert.IsTrue(TryGetProjectIcon('copy_url', LDescriptor));
  var LComposite := TBitmap.Create;
  try
    var LBase := TBitmap.Create;
    try
      Assert.IsTrue(TryRenderProjectIcon(LComposite, 'copy_url', 32,
        RGB(31, 58, 95), RGB(225, 112, 24), False, False, HInstance,
        LSource));
      LFont.RenderDuotoneBitmap(LBase, LDescriptor.Code, 32,
        RGB(31, 58, 95), RGB(225, 112, 24),
        LDescriptor.SecondaryOpacity);
      Assert.IsFalse(BitmapsMatch(LComposite, LBase),
        'Copy URL must add its copy-action badge');
    finally
      LBase.Free;
    end;
  finally
    LComposite.Free;
  end;
end;
procedure TIconTests.CompositeIconAddsItsSemanticBadge;
var
  LDescriptor: TProjectIconDescriptor;
  LFont: TPhosphorFont;
  LSource: TProjectIconSource;
begin
  Assert.IsTrue(TryGetProjectIcon('delphig', LDescriptor));
  Assert.IsTrue(TryGetPhosphorFont(LFont));
  var LComposite := TBitmap.Create;
  try
    var LBase := TBitmap.Create;
    try
      Assert.IsTrue(TryRenderProjectIcon(LComposite, 'delphig', 32,
        RGB(72, 80, 92), RGB(225, 112, 24), False, False, HInstance,
        LSource));
      Assert.AreEqual(Ord(pisPhosphor), Ord(LSource));
      LFont.RenderDuotoneBitmap(LBase, LDescriptor.Code, 32,
        RGB(72, 80, 92), RGB(225, 112, 24),
        LDescriptor.SecondaryOpacity);
      Assert.IsFalse(BitmapsMatch(LComposite, LBase),
        'The unavailable-state warning badge must change the base code glyph');
      var LAddedPixelFound := False;
      for var LY := 0 to LComposite.Height - 1 do
        for var LX := 0 to LComposite.Width - 1 do
          if AlphaAt(LComposite, LX, LY) > AlphaAt(LBase, LX, LY) then
            LAddedPixelFound := True;
      Assert.IsTrue(LAddedPixelFound,
        'The warning badge must add visible pixels to the base glyph');
    finally
      LBase.Free;
    end;
  finally
    LComposite.Free;
  end;
end;
procedure TIconTests.CrispDuotoneCompositionIncludesBothVisualLayers;
var
  LDescriptor: TProjectIconDescriptor;
  LFont: TPhosphorFont;
begin
  Assert.IsTrue(TryGetProjectIcon('settings', LDescriptor));
  Assert.IsTrue(TryGetPhosphorFont(LFont));
  var LDuotone := TBitmap.Create;
  try
    var LSecondary := TBitmap.Create;
    try
      var LPrimary := TBitmap.Create;
      try
        var LBold := TBitmap.Create;
        try
          LFont.RenderDuotoneBitmap(LDuotone, LDescriptor.Code, 32,
            RGB(12, 45, 90), RGB(80, 170, 240),
            LDescriptor.SecondaryOpacity);
          LFont.RenderIconBitmap(LSecondary, LDescriptor.Code, 32,
            RGB(80, 170, 240), pfwDuotone);
          LFont.RenderIconBitmap(LPrimary, LDescriptor.Code + 1, 32,
            RGB(12, 45, 90), pfwDuotone);
          LFont.RenderIconBitmap(LBold, LDescriptor.Code, 32,
            RGB(12, 45, 90), pfwBold);
          var LSecondaryPixelFound := False;
          var LPrimaryPixelFound := False;
          var LBoldCoveragePreserved := True;
          var LBoldDominantPixelFound := False;
          for var LY := 0 to LDuotone.Height - 1 do
            for var LX := 0 to LDuotone.Width - 1 do
            begin
              if (AlphaAt(LSecondary, LX, LY) > 0) and
                 (AlphaAt(LPrimary, LX, LY) = 0) and
                 (AlphaAt(LDuotone, LX, LY) > 0) then
                LSecondaryPixelFound := True;
              if (AlphaAt(LPrimary, LX, LY) > 0) and
                 (AlphaAt(LDuotone, LX, LY) > 0) then
                LPrimaryPixelFound := True;
              if AlphaAt(LDuotone, LX, LY) < AlphaAt(LBold, LX, LY) then
                LBoldCoveragePreserved := False;
              if AlphaAt(LBold, LX, LY) > AlphaAt(LPrimary, LX, LY) then
                LBoldDominantPixelFound := True;
            end;
          Assert.IsTrue(LSecondaryPixelFound,
            'Duotone must retain pixels from its translucent even-code layer');
          Assert.IsTrue(LPrimaryPixelFound,
            'Duotone must include its opaque odd-code primary layer');
          Assert.IsTrue(LBoldDominantPixelFound,
            'Bold must provide coverage beyond the thin Duotone primary');
          Assert.IsTrue(LBoldCoveragePreserved,
            'The final icon must preserve every pixel of the Bold clarity layer');
        finally
          LBold.Free;
        end;
      finally
        LPrimary.Free;
      end;
    finally
      LSecondary.Free;
    end;
  finally
    LDuotone.Free;
  end;
end;

procedure TIconTests.MenuGlyphOccupiesTheAvailableCanvas(const AKey: string);
var
  LBounds: TRect;
  LSource: TProjectIconSource;
begin
  var LBitmap := TBitmap.Create;
  try
    Assert.IsTrue(TryRenderProjectIcon(LBitmap, AKey, 16,
      RGB(85, 178, 239), RGB(85, 178, 239), False, False, HInstance,
      LSource), AKey);
    Assert.AreEqual(Ord(pisPhosphor), Ord(LSource), AKey);
    Assert.IsTrue(TryGetVisibleBounds(LBitmap, LBounds), AKey);
    Assert.IsTrue(LBounds.Width >= 10,
      Format('%s rendered only %d pixels wide', [AKey, LBounds.Width]));
    Assert.IsTrue(LBounds.Height >= 10,
      Format('%s rendered only %d pixels high', [AKey, LBounds.Height]));
  finally
    LBitmap.Free;
  end;
end;

procedure TIconTests.DirectDrawingPreservesHostDCStateAndClip;
var
  LAfterClip: TRect;
  LBeforeClip: TRect;
  LFont: TPhosphorFont;
begin
  Assert.IsTrue(TryGetPhosphorFont(LFont));
  var LBitmap := TBitmap.Create;
  try
    LBitmap.PixelFormat := pf32bit;
    LBitmap.SetSize(40, 40);
    var LDC := LBitmap.Canvas.Handle;
    var LSavedDC := SaveDC(LDC);
    Assert.IsTrue(LSavedDC <> 0);
    try
      var LRegion := CreateRectRgn(4, 5, 34, 35);
      Assert.IsTrue(LRegion <> 0);
      try
        Assert.AreNotEqual(ERROR, SelectClipRgn(LDC, LRegion));
      finally
        DeleteObject(LRegion);
      end;
      SetTextColor(LDC, RGB(12, 34, 56));
      SetBkColor(LDC, RGB(78, 90, 12));
      SetBkMode(LDC, OPAQUE);
      var LFontBefore := GetCurrentObject(LDC, OBJ_FONT);
      Assert.AreNotEqual(ERROR, GetClipBox(LDC, LBeforeClip));
      LFont.DrawDuotoneIcon(LDC, cPhGear, Rect(0, 0, 40, 40),
        RGB(20, 60, 100), RGB(80, 170, 240));
      LFont.DrawDuotoneIcon(LDC, cPhGear, Rect(0, 0, 0, 0),
        RGB(20, 60, 100), RGB(80, 170, 240));
      Assert.AreEqual<Cardinal>(RGB(12, 34, 56), GetTextColor(LDC));
      Assert.AreEqual<Cardinal>(RGB(78, 90, 12), GetBkColor(LDC));
      Assert.AreEqual(OPAQUE, GetBkMode(LDC));
      Assert.IsTrue(LFontBefore = GetCurrentObject(LDC, OBJ_FONT));
      Assert.AreNotEqual(ERROR, GetClipBox(LDC, LAfterClip));
      Assert.AreEqual(LBeforeClip.Left, LAfterClip.Left);
      Assert.AreEqual(LBeforeClip.Top, LAfterClip.Top);
      Assert.AreEqual(LBeforeClip.Right, LAfterClip.Right);
      Assert.AreEqual(LBeforeClip.Bottom, LAfterClip.Bottom);
    finally
      RestoreDC(LDC, LSavedDC);
    end;
  finally
    LBitmap.Free;
  end;
end;
procedure TIconTests.HighContrastUsesTheBoldGlyph;
var
  LSource: TProjectIconSource;
begin
  var LActual := TBitmap.Create;
  try
    Assert.IsTrue(TryRenderProjectIcon(LActual, 'checksum', 24,
      clWindowText, clHighlight, True, False, HInstance, LSource));
    Assert.AreEqual(Ord(pisPhosphor), Ord(LSource));
    Assert.IsTrue(VisiblePixelCount(LActual) > 0,
      'High-contrast Bold glyph must contain visible pixels');
  finally
    LActual.Free;
  end;
end;

procedure TIconTests.ChecksumUsesTheFingerprintGlyph;
var
  LDescriptor: TProjectIconDescriptor;
begin
  Assert.IsTrue(TryGetProjectIcon('checksum', LDescriptor));
  Assert.AreEqual('fingerprint', LDescriptor.PhosphorName);
  Assert.AreEqual(cPhFingerprint, LDescriptor.Code);
  Assert.AreEqual(Ord(pipChecksum), Ord(LDescriptor.PaletteRole));
end;

procedure TIconTests.PaletteRolesUseTheActiveShellTheme;
var
  LActiveTheme: TDevShellTheme;
  LAliasPrimary, LAliasSecondary: TColor;
  LDarkTheme: TDevShellTheme;
  LDarkPrimary, LDarkSecondary: TColor;
  LHighContrastTheme: TDevShellTheme;
  LHighContrastPrimary, LHighContrastSecondary: TColor;
  LLightTheme: TDevShellTheme;
  LLightPrimary, LLightSecondary: TColor;
begin
  LLightTheme := TDevShellTheme.LightTheme;
  LDarkTheme := TDevShellTheme.DarkTheme;
  LHighContrastTheme := LLightTheme;
  LHighContrastTheme.HighContrast := True;
  LHighContrastTheme.TextColor := clWebBlack;
  ResolveProjectIconPalette(pipCopy, LLightTheme, LLightPrimary,
    LLightSecondary);
  ResolveProjectIconPalette(pipCopy, LDarkTheme, LDarkPrimary,
    LDarkSecondary);
  ResolveProjectIconPalette(pipWarning, LHighContrastTheme,
    LHighContrastPrimary, LHighContrastSecondary);
  Assert.AreEqual<Cardinal>(ColorToRGB(clWebSteelBlue),
    ColorToRGB(LLightPrimary));
  Assert.AreEqual<Cardinal>(ColorToRGB(RGB($21, $96, $FF)),
    ColorToRGB(LDarkPrimary));
  Assert.AreEqual<Cardinal>(ColorToRGB(LLightPrimary),
    ColorToRGB(LLightSecondary));
  Assert.AreEqual<Cardinal>(ColorToRGB(LDarkPrimary),
    ColorToRGB(LDarkSecondary));
  Assert.AreEqual<Cardinal>(ColorToRGB(clWebBlack),
    ColorToRGB(LHighContrastPrimary));
  Assert.AreEqual<Cardinal>(ColorToRGB(LHighContrastPrimary),
    ColorToRGB(LHighContrastSecondary));
  ResolveProjectIconPalette(pipPlatform, LLightTheme, LAliasPrimary,
    LAliasSecondary);
  Assert.AreEqual<Cardinal>(ColorToRGB(LLightTheme.MutedColor),
    ColorToRGB(LAliasPrimary));
  ResolveProjectIconPalette(pipFramework, LLightTheme, LAliasPrimary,
    LAliasSecondary);
  Assert.AreEqual<Cardinal>(ColorToRGB(LLightTheme.PrimaryColor),
    ColorToRGB(LAliasPrimary));
  ResolveProjectIconPalette(pipChecksum, LLightTheme, LAliasPrimary,
    LAliasSecondary);
  Assert.AreEqual<Cardinal>(ColorToRGB(LLightTheme.PrimaryColor),
    ColorToRGB(LAliasPrimary));
  ResolveProjectIconPalette(pipPrivileged, LLightTheme, LAliasPrimary,
    LAliasSecondary);
  Assert.AreEqual<Cardinal>(ColorToRGB(LLightTheme.WarningColor),
    ColorToRGB(LAliasPrimary));
  Assert.AreEqual<Cardinal>(ColorToRGB(LAliasPrimary),
    ColorToRGB(LAliasSecondary));
  Assert.AreEqual('Segoe UI', TDevShellTheme.cFontName);
  Assert.AreEqual(9, TDevShellTheme.cFontSize);
  LActiveTheme := TDevShellTheme.ActiveTheme;
  if IsWindowsLightTheme then
    Assert.AreEqual(Ord(dstLight), Ord(LActiveTheme.Kind))
  else
    Assert.AreEqual(Ord(dstDark), Ord(LActiveTheme.Kind));
end;

procedure TIconTests.RepeatedRenderingReleasesGdiObjects;
var
  LSource: TProjectIconSource;
begin
  var LWarmup := TBitmap.Create;
  try
    Assert.IsTrue(TryRenderProjectIcon(LWarmup, 'copy_path', 24,
      clWindowText, clHighlight, False, False, HInstance, LSource));
  finally
    LWarmup.Free;
  end;
  var LBefore := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
  for var LIndex := 1 to 100 do
  begin
    var LBitmap := TBitmap.Create;
    try
      Assert.IsTrue(TryRenderProjectIcon(LBitmap, 'copy_path', 24,
        clWindowText, clHighlight, False, False, HInstance, LSource));
    finally
      LBitmap.Free;
    end;
  end;
  var LAfter := GetGuiResources(GetCurrentProcess, GR_GDIOBJECTS);
  Assert.IsTrue(LAfter <= LBefore + 2,
    Format('GDI objects grew from %d to %d', [LBefore, LAfter]));
end;

end.
