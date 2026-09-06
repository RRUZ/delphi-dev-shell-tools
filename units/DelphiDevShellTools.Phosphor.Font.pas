//**************************************************************************************************
//
// Unit DelphiDevShellTools.Phosphor.Font
// Thread-safe Phosphor font loading and anti-aliased icon rendering.
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
// The Original Code is DelphiDevShellTools.Phosphor.Font.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.Phosphor.Font;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.SysUtils,
  System.Types,
  Vcl.Controls,
  Vcl.Graphics,
  Winapi.GDIPOBJ;

type
  TPhosphorFontWeight = (pfwThin, pfwLight, pfwRegular, pfwBold, pfwFill,
    pfwDuotone);

  TPhosphorFont = class
  private
    FFontCollections: array[TPhosphorFontWeight] of TGPPrivateFontCollection;
    FFontData: array[TPhosphorFontWeight] of TBytes;
    FFontHandles: array[TPhosphorFontWeight] of THandle;
    FFontLoaded: array[TPhosphorFontWeight] of Boolean;
    FLock: TObject;
    FGdiPlusToken: ULONG_PTR;
    FGdiPlusUsers: Integer;
    procedure ConfigureGraphics(AGraphics: TGPGraphics;
      const AClipRect: TRect);
    function GetFontCollection(
      AWeight: TPhosphorFontWeight): TGPPrivateFontCollection;
    procedure DrawIconLayer(AGraphics: TGPGraphics;
      ACollection: TGPPrivateFontCollection; ACode: Word;
      const ADestRect: TRect; AColor: TColor; AAlpha: Byte;
      AWeight: TPhosphorFontWeight);
    procedure EnsureFontLoaded(AWeight: TPhosphorFontWeight);
    procedure LoadFont(AWeight: TPhosphorFontWeight);
    function TryShutdown: Boolean;
    procedure RenderBitmap(ABitmap: TBitmap; ACode: Word; ASize: Integer;
      APrimaryColor, ASecondaryColor: TColor; ASecondaryOpacity: Byte;
      ADuotone: Boolean; APrimaryWeight: TPhosphorFontWeight;
      AReinforcePrimary: Boolean);
  public
    constructor Create;
    destructor Destroy; override;
    procedure BeginRenderSession;
    procedure EndRenderSession;
    procedure DrawIcon(ADC: HDC; ACode: Word; const ADestRect: TRect;
      AColor: TColor; AWeight: TPhosphorFontWeight = pfwRegular);
    procedure DrawDuotoneIcon(ADC: HDC; ACode: Word;
      const ADestRect: TRect; APrimaryColor, ASecondaryColor: TColor;
      ASecondaryOpacity: Byte = 76; AReinforcePrimary: Boolean = True);
    function GetIconCodes(
      AWeight: TPhosphorFontWeight = pfwRegular): TArray<Word>;
    function HasGlyph(ACode: Word;
      AWeight: TPhosphorFontWeight = pfwRegular): Boolean;
    procedure RenderIconBitmap(ABitmap: TBitmap; ACode: Word; ASize: Integer;
      AColor: TColor; AWeight: TPhosphorFontWeight = pfwRegular);
    procedure RenderDuotoneBitmap(ABitmap: TBitmap; ACode: Word;
      ASize: Integer; APrimaryColor, ASecondaryColor: TColor;
      ASecondaryOpacity: Byte = 76; AReinforcePrimary: Boolean = True);
  end;

  TPhosphorIcon = class(TCustomControl)
  private
    FIconCode: Word;
    FIconColor: TColor;
    FWeight: TPhosphorFontWeight;
    procedure SetIconCode(const AValue: Word);
    procedure SetIconColor(const AValue: TColor);
    procedure SetWeight(const AValue: TPhosphorFontWeight);
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Anchors;
    property Color;
    property IconCode: Word read FIconCode write SetIconCode default $E67C;
    property IconColor: TColor read FIconColor write SetIconColor default clHighlight;
    property Weight: TPhosphorFontWeight read FWeight write SetWeight default pfwRegular;
    property OnClick;
    property OnMouseEnter;
    property OnMouseLeave;
  end;

const
  cPhPulse = $E000;
  cPhArrowsClockwise = $E094;
  cPhAndroidLogo = $E008;
  cPhBrowser = $E0F4;
  cPhChartBar = $E150;
  cPhClipboardText = $E198;
  cPhClockCounterClockwise = $E1A0;
  cPhAppWindow = $E5DA;
  cPhCode = $E1BC;
  cPhCopy = $E1CA;
  cPhCube = $E1DA;
  cPhDatabase = $E1DE;
  cPhDeviceMobile = $E1E0;
  cPhFileMagnifyingGlass = $E238;
  cPhFileText = $E23A;
  cPhFingerprint = $E23E;
  cPhFolderOpen = $E256;
  cPhGear = $E270;
  cPhGlobe = $E288;
  cPhHash = $E2A2;
  cPhInfo = $E2CE;
  cPhLeaf = $E2DA;
  cPhLink = $E2E2;
  cPhListDashes = $E2F4;
  cPhMagnifyingGlass = $E30C;
  cPhMoon = $E330;
  cPhNumberCircleFive = $E358;
  cPhNumberCircleFour = $E35E;
  cPhNumberCircleOne = $E36A;
  cPhNumberCircleThree = $E37C;
  cPhNumberCircleTwo = $E382;
  cPhPalette = $E6C8;
  cPhPath = $E39C;
  cPhPlus = $E3D4;
  cPhShield = $E40A;
  cPhShieldCheck = $E40C;
  cPhShieldSlash = $E410;
  cPhSignIn = $E428;
  cPhSlidersHorizontal = $E434;
  cPhStack = $E466;
  cPhSun = $E472;
  cPhTable = $E476;
  cPhTerminal = $E47E;
  cPhTrash = $E4A6;
  cPhWarning = $E4E0;
  cPhUser = $E4C2;
  cPhAppleLogo = $E516;
  cPhGithubLogo = $E576;
  cPhWrench = $E5D4;
  cPhArrowSquareOut = $E5DE;
  cPhBug = $E5F4;
  cPhFlame = $E624;
  cPhNotepad = $E63E;
  cPhTreeStructure = $E67C;
  cPhWindowsLogo = $E692;
  cPhFiles = $E710;
  cPhCpu = $E610;
  cPhHammer = $E80E;
  cPhBracketsCurly = $E860;
  cPhTerminalWindow = $EAE8;
  cPhDevices = $EBA4;
  cPhToolbox = $ECA0;
  cPhListChecks = $EADC;
  cPhCodeBlock = $EAFE;
  cPhHandTap = $EC90;
  cPhNetwork = $EDDE;
  cPhBinary = $EE60;
  cPhScales = $E750;

function TryGetPhosphorFont(out AFont: TPhosphorFont): Boolean;
function TryShutdownPhosphorFont: Boolean;

implementation

uses
  Winapi.GDIPAPI;

{$R DelphiDevShellTools.Phosphor.Font.res}

const
  cResourceNames: array[TPhosphorFontWeight] of string = (
    'PHOSPHOR_THIN', 'PHOSPHOR_LIGHT', 'PHOSPHOR_REGULAR', 'PHOSPHOR_BOLD',
    'PHOSPHOR_FILL', 'PHOSPHOR_DUOTONE');
  cFontNames: array[TPhosphorFontWeight] of string = (
    'Phosphor-Thin', 'Phosphor-Light', 'Phosphor', 'Phosphor-Bold',
    'Phosphor-Fill', 'Phosphor-Duotone');

var
  GPhosphorFont: TPhosphorFont;
  GPhosphorFontLock: TObject;

procedure RaiseGdiPlusError(const AOperation: string; AStatus: TStatus);
begin
  raise EInvalidOp.CreateFmt('%s failed with GDI+ status %d',
    [AOperation, Ord(AStatus)]);
end;

function StartGdiPlus: ULONG_PTR;
var
  LInput: TGdiplusStartupInput;
  LStatus: TStatus;
begin
  Result := 0;
  ZeroMemory(@LInput, SizeOf(LInput));
  LInput.GdiplusVersion := 1;
  LStatus := GdiplusStartup(Result, @LInput, nil);
  if LStatus <> Status.Ok then
  begin
    Result := 0;
    RaiseGdiPlusError('GdiplusStartup', LStatus);
  end;
end;

procedure StopGdiPlus(AToken: ULONG_PTR);
begin
  if AToken <> 0 then
    GdiplusShutdown(AToken);
end;

function TryGetPhosphorFont(out AFont: TPhosphorFont): Boolean;
begin
  AFont := nil;
  try
    TMonitor.Enter(GPhosphorFontLock);
    try
      if GPhosphorFont = nil then
        GPhosphorFont := TPhosphorFont.Create;
      AFont := GPhosphorFont;
    finally
      TMonitor.Exit(GPhosphorFontLock);
    end;
    Result := True;
  except
    AFont := nil;
    Result := False;
  end;
end;

function TryShutdownPhosphorFont: Boolean;
begin
  Result := True;
  TMonitor.Enter(GPhosphorFontLock);
  try
    if GPhosphorFont <> nil then
      Result := GPhosphorFont.TryShutdown;
  finally
    TMonitor.Exit(GPhosphorFontLock);
  end;
end;

{ TPhosphorFont }

constructor TPhosphorFont.Create;
begin
  inherited Create;
  FLock := TObject.Create;
end;

destructor TPhosphorFont.Destroy;
begin
  if not IsLibrary then
    TryShutdown;
  for var LWeight := Low(TPhosphorFontWeight) to High(TPhosphorFontWeight) do
  begin
    FFontCollections[LWeight] := nil;
    if FFontHandles[LWeight] <> 0 then
    begin
      RemoveFontMemResourceEx(FFontHandles[LWeight]);
      FFontHandles[LWeight] := 0;
    end;
    FFontData[LWeight] := nil;
  end;
  FLock.Free;
  inherited;
end;

procedure TPhosphorFont.BeginRenderSession;
begin
  TMonitor.Enter(FLock);
  try
    if (FGdiPlusUsers = 0) and (FGdiPlusToken = 0) then
      FGdiPlusToken := StartGdiPlus;
    Inc(FGdiPlusUsers);
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TPhosphorFont.EndRenderSession;
begin
  TMonitor.Enter(FLock);
  try
    if FGdiPlusUsers <= 0 then
      raise EInvalidOp.Create('Unbalanced Phosphor render session');
    Dec(FGdiPlusUsers);
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TPhosphorFont.TryShutdown: Boolean;
begin
  TMonitor.Enter(FLock);
  try
    Result := FGdiPlusUsers = 0;
    if not Result then
      Exit;
    for var LWeight := Low(TPhosphorFontWeight) to
      High(TPhosphorFontWeight) do
    begin
      FFontCollections[LWeight].Free;
      FFontCollections[LWeight] := nil;
    end;
    StopGdiPlus(FGdiPlusToken);
    FGdiPlusToken := 0;
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TPhosphorFont.ConfigureGraphics(AGraphics: TGPGraphics;
  const AClipRect: TRect);
begin
  var LStatus := AGraphics.SetCompositingMode(CompositingModeSourceOver);
  if LStatus <> Status.Ok then
    RaiseGdiPlusError('SetCompositingMode', LStatus);
  LStatus := AGraphics.SetTextRenderingHint(TextRenderingHintAntiAliasGridFit);
  if LStatus <> Status.Ok then
    RaiseGdiPlusError('SetTextRenderingHint', LStatus);
  LStatus := AGraphics.SetClip(MakeRect(AClipRect.Left, AClipRect.Top,
    AClipRect.Width, AClipRect.Height));
  if LStatus <> Status.Ok then
    RaiseGdiPlusError('SetClip', LStatus);
end;

function TPhosphorFont.GetFontCollection(
  AWeight: TPhosphorFontWeight): TGPPrivateFontCollection;
begin
  EnsureFontLoaded(AWeight);
  TMonitor.Enter(FLock);
  try
    if FFontCollections[AWeight] = nil then
    begin
      var LCollection := TGPPrivateFontCollection.Create;
      try
        var LStatus := LCollection.AddMemoryFont(
          @FFontData[AWeight][0], Length(FFontData[AWeight]));
        if LStatus <> Status.Ok then
          RaiseGdiPlusError('AddMemoryFont', LStatus);
        if LCollection.GetFamilyCount <> 1 then
          raise EInvalidOp.CreateFmt(
            'Phosphor collection %s contains %d families',
            [cFontNames[AWeight], LCollection.GetFamilyCount]);
        FFontCollections[AWeight] := LCollection;
        LCollection := nil;
      finally
        LCollection.Free;
      end;
    end;
    Result := FFontCollections[AWeight];
  finally
    TMonitor.Exit(FLock);
  end;
end;

procedure TPhosphorFont.DrawIconLayer(AGraphics: TGPGraphics;
  ACollection: TGPPrivateFontCollection; ACode: Word;
  const ADestRect: TRect; AColor: TColor; AAlpha: Byte;
  AWeight: TPhosphorFontWeight);
var
  LFamilies: array[0..0] of TGPFontFamily;
  LFamilyCount: Integer;
begin
  LFamilies[0] := TGPFontFamily.Create;
  try
    LFamilyCount := 0;
    var LStatus := ACollection.GetFamilies(1, LFamilies, LFamilyCount);
    if LStatus <> Status.Ok then
      RaiseGdiPlusError('Get font family', LStatus);
    if LFamilyCount <> 1 then
      raise EInvalidOp.CreateFmt(
        'Phosphor collection %s returned %d families',
        [cFontNames[AWeight], LFamilyCount]);
    var LFont := TGPFont.Create(LFamilies[0], ADestRect.Height,
      FontStyleRegular, UnitPixel);
    try
      if LFont.GetLastStatus <> Status.Ok then
        RaiseGdiPlusError('Create font', LFont.GetLastStatus);
      var LColor := ColorToRGB(AColor);
      var LBrush := TGPSolidBrush.Create(MakeColor(AAlpha, GetRValue(LColor),
        GetGValue(LColor), GetBValue(LColor)));
      try
        if LBrush.GetLastStatus <> Status.Ok then
          RaiseGdiPlusError('Create brush', LBrush.GetLastStatus);
        var LStringFormat := TGPStringFormat.Create;
        try
          if LStringFormat.GetLastStatus <> Status.Ok then
            RaiseGdiPlusError('Create string format',
              LStringFormat.GetLastStatus);
          LStatus := LStringFormat.SetAlignment(StringAlignmentCenter);
          if LStatus <> Status.Ok then
            RaiseGdiPlusError('Set horizontal alignment', LStatus);
          LStatus := LStringFormat.SetLineAlignment(StringAlignmentCenter);
          if LStatus <> Status.Ok then
            RaiseGdiPlusError('Set vertical alignment', LStatus);
          var LRect := MakeRect(ADestRect.Left * 1.0, ADestRect.Top * 1.0,
            ADestRect.Width * 1.0, ADestRect.Height * 1.0);
          var LText: string := Char(ACode);
          LStatus := AGraphics.DrawString(LText, -1, LFont, LRect,
            LStringFormat, LBrush);
          if LStatus <> Status.Ok then
            RaiseGdiPlusError('DrawString', LStatus);
        finally
          LStringFormat.Free;
        end;
      finally
        LBrush.Free;
      end;
    finally
      LFont.Free;
    end;
  finally
    LFamilies[0].Free;
  end;
end;

procedure TPhosphorFont.DrawIcon(ADC: HDC; ACode: Word;
  const ADestRect: TRect; AColor: TColor; AWeight: TPhosphorFontWeight);
begin
  if (ADC = 0) or (ADestRect.Width <= 0) or (ADestRect.Height <= 0) then
    Exit;
  BeginRenderSession;
  try
    var LCollection := GetFontCollection(AWeight);
    var LSavedDC := SaveDC(ADC);
    if LSavedDC = 0 then
      RaiseLastOSError;
    try
      var LGraphics := TGPGraphics.Create(ADC);
      try
        if LGraphics.GetLastStatus <> Status.Ok then
          RaiseGdiPlusError('Create graphics',
            LGraphics.GetLastStatus);
        ConfigureGraphics(LGraphics, ADestRect);
        DrawIconLayer(LGraphics, LCollection, ACode, ADestRect,
          AColor, 255, AWeight);
      finally
        LGraphics.Free;
      end;
    finally
      RestoreDC(ADC, LSavedDC);
    end;
  finally
    EndRenderSession;
  end;
end;

procedure TPhosphorFont.DrawDuotoneIcon(ADC: HDC; ACode: Word;
  const ADestRect: TRect; APrimaryColor, ASecondaryColor: TColor;
  ASecondaryOpacity: Byte; AReinforcePrimary: Boolean);
begin
  if (ADC = 0) or (ADestRect.Width <= 0) or (ADestRect.Height <= 0) then
    Exit;
  BeginRenderSession;
  try
    var LDuotoneCollection := GetFontCollection(pfwDuotone);
    var LSavedDC := SaveDC(ADC);
    if LSavedDC = 0 then
      RaiseLastOSError;
    try
      var LGraphics := TGPGraphics.Create(ADC);
      try
        if LGraphics.GetLastStatus <> Status.Ok then
          RaiseGdiPlusError('Create graphics',
            LGraphics.GetLastStatus);
        ConfigureGraphics(LGraphics, ADestRect);
        DrawIconLayer(LGraphics, LDuotoneCollection, ACode,
          ADestRect, ASecondaryColor, ASecondaryOpacity, pfwDuotone);
        DrawIconLayer(LGraphics, LDuotoneCollection, ACode + 1,
          ADestRect, APrimaryColor, 255, pfwDuotone);
        if AReinforcePrimary then
          DrawIconLayer(LGraphics, GetFontCollection(pfwBold), ACode,
            ADestRect, APrimaryColor, 255, pfwBold);
      finally
        LGraphics.Free;
      end;
    finally
      RestoreDC(ADC, LSavedDC);
    end;
  finally
    EndRenderSession;
  end;
end;

procedure TPhosphorFont.EnsureFontLoaded(AWeight: TPhosphorFontWeight);
begin
  if FFontLoaded[AWeight] then
    Exit;
  TMonitor.Enter(FLock);
  try
    if not FFontLoaded[AWeight] then
      LoadFont(AWeight);
  finally
    TMonitor.Exit(FLock);
  end;
end;

function TPhosphorFont.GetIconCodes(
  AWeight: TPhosphorFontWeight): TArray<Word>;
const
  cPrivateUseFirst = $E000;
  cPrivateUseLast = $F8FF;
var
  LCharacters: TArray<WideChar>;
  LGlyphIndexes: TArray<Word>;
begin
  EnsureFontLoaded(AWeight);
  var LDC := GetDC(0);
  if LDC = 0 then
    RaiseLastOSError;
  try
    var LFont := CreateFont(32, 0, 0, 0, FW_NORMAL, 0, 0, 0,
      DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      ANTIALIASED_QUALITY, DEFAULT_PITCH, PChar(cFontNames[AWeight]));
    if LFont = 0 then
      RaiseLastOSError;
    try
      var LOldFont := SelectObject(LDC, LFont);
      if LOldFont = 0 then
        RaiseLastOSError;
      try
        var LCharacterCount := cPrivateUseLast - cPrivateUseFirst + 1;
        SetLength(LCharacters, LCharacterCount);
        SetLength(LGlyphIndexes, LCharacterCount);
        for var LIndex := 0 to LCharacterCount - 1 do
          LCharacters[LIndex] := WideChar(cPrivateUseFirst + LIndex);
        if GetGlyphIndicesW(LDC, PWideChar(@LCharacters[0]), LCharacterCount,
          @LGlyphIndexes[0], GGI_MARK_NONEXISTING_GLYPHS) = GDI_ERROR then
          RaiseLastOSError;
        SetLength(Result, LCharacterCount);
        var LResultIndex := 0;
        for var LIndex := 0 to LCharacterCount - 1 do
          if LGlyphIndexes[LIndex] <> $FFFF then
          begin
            Result[LResultIndex] := Word(LCharacters[LIndex]);
            Inc(LResultIndex);
          end;
        SetLength(Result, LResultIndex);
      finally
        SelectObject(LDC, LOldFont);
      end;
    finally
      DeleteObject(LFont);
    end;
  finally
    ReleaseDC(0, LDC);
  end;
end;

function TPhosphorFont.HasGlyph(ACode: Word;
  AWeight: TPhosphorFontWeight): Boolean;
var
  LGlyphIndex: Word;
begin
  EnsureFontLoaded(AWeight);
  var LDC := GetDC(0);
  if LDC = 0 then
    RaiseLastOSError;
  try
    var LFont := CreateFont(32, 0, 0, 0, FW_NORMAL, 0, 0, 0,
      DEFAULT_CHARSET, OUT_DEFAULT_PRECIS, CLIP_DEFAULT_PRECIS,
      ANTIALIASED_QUALITY, DEFAULT_PITCH, PChar(cFontNames[AWeight]));
    if LFont = 0 then
      RaiseLastOSError;
    try
      var LOldFont := SelectObject(LDC, LFont);
      if LOldFont = 0 then
        RaiseLastOSError;
      try
        var LCharacter := WideChar(ACode);
        if GetGlyphIndicesW(LDC, @LCharacter, 1, @LGlyphIndex,
          GGI_MARK_NONEXISTING_GLYPHS) = GDI_ERROR then
          RaiseLastOSError;
        Result := LGlyphIndex <> $FFFF;
      finally
        SelectObject(LDC, LOldFont);
      end;
    finally
      DeleteObject(LFont);
    end;
  finally
    ReleaseDC(0, LDC);
  end;
end;

procedure TPhosphorFont.LoadFont(AWeight: TPhosphorFontWeight);
var
  LFontCount: Cardinal;
  LFontData: TBytes;
begin
  var LStream := TResourceStream.Create(HInstance,
    cResourceNames[AWeight], RT_RCDATA);
  try
    if LStream.Size <= 0 then
      raise EInvalidOp.CreateFmt('Phosphor resource %s is empty',
        [cResourceNames[AWeight]]);
    SetLength(LFontData, LStream.Size);
    LStream.ReadBuffer(LFontData[0], LStream.Size);
    LFontCount := 0;
    var LFontHandle := AddFontMemResourceEx(@LFontData[0],
      Length(LFontData), nil, @LFontCount);
    if LFontHandle = 0 then
      RaiseLastOSError;
    try
      FFontData[AWeight] := LFontData;
      FFontHandles[AWeight] := LFontHandle;
      FFontLoaded[AWeight] := True;
      LFontHandle := 0;
    finally
      if LFontHandle <> 0 then
        RemoveFontMemResourceEx(LFontHandle);
    end;
  finally
    LStream.Free;
  end;
end;

procedure TPhosphorFont.RenderBitmap(ABitmap: TBitmap; ACode: Word;
  ASize: Integer; APrimaryColor, ASecondaryColor: TColor;
  ASecondaryOpacity: Byte; ADuotone: Boolean;
  APrimaryWeight: TPhosphorFontWeight; AReinforcePrimary: Boolean);
var
  LBitmapInfo: TBitmapInfo;
  LBits: Pointer;
begin
  if ABitmap = nil then
    raise EArgumentNilException.Create('ABitmap');
  if ASize <= 0 then
  begin
    ABitmap.SetSize(0, 0);
    Exit;
  end;

  ZeroMemory(@LBitmapInfo, SizeOf(LBitmapInfo));
  LBitmapInfo.bmiHeader.biSize := SizeOf(TBitmapInfoHeader);
  LBitmapInfo.bmiHeader.biWidth := ASize;
  LBitmapInfo.bmiHeader.biHeight := -ASize;
  LBitmapInfo.bmiHeader.biPlanes := 1;
  LBitmapInfo.bmiHeader.biBitCount := 32;
  LBitmapInfo.bmiHeader.biCompression := BI_RGB;
  LBits := nil;
  var LBitmapHandle := CreateDIBSection(0, LBitmapInfo, DIB_RGB_COLORS,
    LBits, 0, 0);
  if (LBitmapHandle = 0) or (LBits = nil) then
    RaiseLastOSError;
  try
    FillChar(LBits^, ASize * ASize * 4, 0);
    BeginRenderSession;
    try
      var LPrimaryCollection := GetFontCollection(APrimaryWeight);
      var LDuotoneCollection: TGPPrivateFontCollection := nil;
      if ADuotone then
        LDuotoneCollection := GetFontCollection(pfwDuotone);
      var LGdiBitmap := TGPBitmap.Create(ASize, ASize, ASize * 4,
        PixelFormat32bppPARGB, LBits);
      try
        if LGdiBitmap.GetLastStatus <> Status.Ok then
          RaiseGdiPlusError('Create PARGB bitmap',
            LGdiBitmap.GetLastStatus);
        var LGraphics := TGPGraphics.Create(LGdiBitmap);
        try
          if LGraphics.GetLastStatus <> Status.Ok then
            RaiseGdiPlusError('Create bitmap graphics',
              LGraphics.GetLastStatus);
          var LRect := Rect(0, 0, ASize, ASize);
          ConfigureGraphics(LGraphics, LRect);
          var LStatus := LGraphics.Clear(MakeColor(0, 0, 0, 0));
          if LStatus <> Status.Ok then
            RaiseGdiPlusError('Clear bitmap', LStatus);
          if ADuotone then
          begin
            DrawIconLayer(LGraphics, LDuotoneCollection, ACode,
              LRect, ASecondaryColor, ASecondaryOpacity, pfwDuotone);
            DrawIconLayer(LGraphics, LDuotoneCollection, ACode + 1,
              LRect, APrimaryColor, 255, pfwDuotone);
            if AReinforcePrimary then
              DrawIconLayer(LGraphics, LPrimaryCollection, ACode,
                LRect, APrimaryColor, 255, APrimaryWeight);
          end
          else
            DrawIconLayer(LGraphics, LPrimaryCollection, ACode, LRect,
              APrimaryColor, 255, APrimaryWeight);
        finally
          LGraphics.Free;
        end;
      finally
        LGdiBitmap.Free;
      end;
    finally
      EndRenderSession;
    end;
    ABitmap.Handle := LBitmapHandle;
    LBitmapHandle := 0;
    ABitmap.PixelFormat := pf32bit;
    ABitmap.AlphaFormat := afPremultiplied;
  finally
    if LBitmapHandle <> 0 then
      DeleteObject(LBitmapHandle);
  end;
end;

procedure TPhosphorFont.RenderDuotoneBitmap(ABitmap: TBitmap; ACode: Word;
  ASize: Integer; APrimaryColor, ASecondaryColor: TColor;
  ASecondaryOpacity: Byte; AReinforcePrimary: Boolean);
begin
  RenderBitmap(ABitmap, ACode, ASize, APrimaryColor, ASecondaryColor,
    ASecondaryOpacity, True, pfwBold, AReinforcePrimary);
end;

procedure TPhosphorFont.RenderIconBitmap(ABitmap: TBitmap; ACode: Word;
  ASize: Integer; AColor: TColor; AWeight: TPhosphorFontWeight);
begin
  RenderBitmap(ABitmap, ACode, ASize, AColor, AColor, 255, False,
    AWeight, False);
end;

{ TPhosphorIcon }

constructor TPhosphorIcon.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  Cursor := crHandPoint;
  FIconCode := cPhTreeStructure;
  FIconColor := clHighlight;
  FWeight := pfwRegular;
  Color := clBtnFace;
end;

procedure TPhosphorIcon.Paint;
var
  LFont: TPhosphorFont;
begin
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  if TryGetPhosphorFont(LFont) then
    try
      LFont.DrawIcon(Canvas.Handle, FIconCode, ClientRect, FIconColor,
        FWeight);
    except
      // A design-time/control paint failure must not escape into the host.
    end;
end;

procedure TPhosphorIcon.SetIconCode(const AValue: Word);
begin
  if FIconCode <> AValue then
  begin
    FIconCode := AValue;
    Invalidate;
  end;
end;

procedure TPhosphorIcon.SetIconColor(const AValue: TColor);
begin
  if FIconColor <> AValue then
  begin
    FIconColor := AValue;
    Invalidate;
  end;
end;

procedure TPhosphorIcon.SetWeight(const AValue: TPhosphorFontWeight);
begin
  if FWeight <> AValue then
  begin
    FWeight := AValue;
    Invalidate;
  end;
end;

initialization
  GPhosphorFontLock := TObject.Create;

finalization
  GPhosphorFont.Free;
  GPhosphorFontLock.Free;

end.
