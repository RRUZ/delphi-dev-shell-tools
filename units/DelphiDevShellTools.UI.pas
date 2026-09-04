//**************************************************************************************************
//
// Unit DelphiDevShellTools.UI
// Shared DPI-aware drawing helpers for generated user-interface images.
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
// The Original Code is DelphiDevShellTools.UI.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.UI;

interface

uses
  Winapi.Windows,
  System.Classes,
  System.Types,
  Vcl.Graphics;

const
  cBulletIconNames: array[0..6] of string = (
    'bullet_green.ico',
    'bullet_orange.ico',
    'bullet_pink.ico',
    'bullet_purple.ico',
    'bullet_red.ico',
    'bullet_white.ico',
    'bullet_yellow.ico'
  );

function TryGetBulletColor(const AIconName: string;
  out AColor: TColor): Boolean;
procedure AddBuiltInBulletIconNames(AItems: TStrings);
procedure DrawAntialiasedSphere(const ACanvas: TCanvas; const ABounds: TRect;
  AColor: TColor);
procedure CreateBulletBitmap(ABitmap: TBitmap; AColor: TColor; ASize: Integer);
function CreateBulletIcon(AColor: TColor; ASize: Integer): HICON;

implementation

uses
  System.Math,
  System.SysUtils,
  Winapi.GDIPAPI,
  Winapi.GDIPOBJ;

function GPColor(AColor: TColor; AAlpha: Byte = 255): TGPColor;
begin
  var LRGBColor := ColorToRGB(AColor);
  Result := MakeColor(AAlpha, GetRValue(LRGBColor), GetGValue(LRGBColor),
    GetBValue(LRGBColor));
end;

function BlendColor(AColor, ATarget: TColor; AAmount: Single): TColor;
begin
  var LAmount: Single := EnsureRange(AAmount, 0.0, 1.0);
  var LColorRGB := ColorToRGB(AColor);
  var LTargetRGB := ColorToRGB(ATarget);
  Result := TColor(RGB(
    Round(GetRValue(LColorRGB) +
      (GetRValue(LTargetRGB) - GetRValue(LColorRGB)) * LAmount),
    Round(GetGValue(LColorRGB) +
      (GetGValue(LTargetRGB) - GetGValue(LColorRGB)) * LAmount),
    Round(GetBValue(LColorRGB) +
      (GetBValue(LTargetRGB) - GetBValue(LColorRGB)) * LAmount)));
end;

procedure DrawSphere(const AGraphics: TGPGraphics; const ABounds: TGPRectF;
  AColor: TColor);
begin
  if (ABounds.Width <= 0.0) or (ABounds.Height <= 0.0) then
    Exit;

  var LLightColor := BlendColor(AColor, clWhite, 0.58);
  var LDarkColor := BlendColor(AColor, clBlack, 0.42);
  var LBorderWidth: Single := Max(1.0,
    Min(ABounds.Width, ABounds.Height) / 14.0);
  var LCirclePath := TGPGraphicsPath.Create;
  try
    LCirclePath.AddEllipse(ABounds);
    var LGradient := TGPLinearGradientBrush.Create(ABounds,
      GPColor(LLightColor), GPColor(LDarkColor), LinearGradientModeVertical);
    try
      AGraphics.FillPath(LGradient, LCirclePath);
    finally
      LGradient.Free;
    end;

    var LHighlightBounds := MakeRect(ABounds.X + ABounds.Width * 0.20,
      ABounds.Y + ABounds.Height * 0.13, ABounds.Width * 0.48,
      ABounds.Height * 0.34);
    var LHighlightPath := TGPGraphicsPath.Create;
    try
      LHighlightPath.AddEllipse(LHighlightBounds);
      var LHighlight := TGPSolidBrush.Create(GPColor(clWhite, 118));
      try
        AGraphics.FillPath(LHighlight, LHighlightPath);
      finally
        LHighlight.Free;
      end;
    finally
      LHighlightPath.Free;
    end;

    var LBorderPen := TGPPen.Create(
      GPColor(BlendColor(AColor, clBlack, 0.55)), LBorderWidth);
    try
      LBorderPen.SetLineJoin(LineJoinRound);
      AGraphics.DrawPath(LBorderPen, LCirclePath);
    finally
      LBorderPen.Free;
    end;
  finally
    LCirclePath.Free;
  end;
end;

function TryGetBulletColor(const AIconName: string;
  out AColor: TColor): Boolean;
begin
  var LName := LowerCase(ExtractFileName(AIconName));
  Result := True;
  if LName = 'bullet_green.ico' then
    AColor := TColor(RGB(52, 168, 83))
  else if LName = 'bullet_orange.ico' then
    AColor := TColor(RGB(242, 153, 36))
  else if LName = 'bullet_pink.ico' then
    AColor := TColor(RGB(225, 76, 146))
  else if LName = 'bullet_purple.ico' then
    AColor := TColor(RGB(139, 92, 246))
  else if LName = 'bullet_red.ico' then
    AColor := TColor(RGB(220, 64, 64))
  else if LName = 'bullet_white.ico' then
    AColor := TColor(RGB(245, 245, 245))
  else if LName = 'bullet_yellow.ico' then
    AColor := TColor(RGB(242, 196, 48))
  else
  begin
    AColor := clNone;
    Result := False;
  end;
end;

procedure AddBuiltInBulletIconNames(AItems: TStrings);
begin
  if AItems = nil then
    Exit;
  for var LIconName in cBulletIconNames do
    if AItems.IndexOf(LIconName) < 0 then
      AItems.Add(LIconName);
end;

procedure DrawAntialiasedSphere(const ACanvas: TCanvas; const ABounds: TRect;
  AColor: TColor);
begin
  if (ACanvas = nil) or (ABounds.Width <= 0) or (ABounds.Height <= 0) then
    Exit;
  var LGraphics := TGPGraphics.Create(ACanvas.Handle);
  try
    LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
    LGraphics.SetCompositingMode(CompositingModeSourceOver);
    var LInset: Single := Max(1.0,
      Min(ABounds.Width, ABounds.Height) / 16.0);
    var LSphereBounds := MakeRect(ABounds.Left + LInset,
      ABounds.Top + LInset, ABounds.Width - LInset * 2.0,
      ABounds.Height - LInset * 2.0);
    DrawSphere(LGraphics, LSphereBounds, AColor);
  finally
    LGraphics.Free;
  end;
end;

procedure CreateBulletBitmap(ABitmap: TBitmap; AColor: TColor; ASize: Integer);
var
  LHandle: HBITMAP;
begin
  if (ABitmap = nil) or (ASize <= 0) then
    Exit;
  var LGPBitmap := TGPBitmap.Create(ASize, ASize, PixelFormat32bppPARGB);
  try
    var LGraphics := TGPGraphics.Create(LGPBitmap);
    try
      LGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
      LGraphics.SetPixelOffsetMode(PixelOffsetModeHalf);
      LGraphics.SetCompositingMode(CompositingModeSourceCopy);
      LGraphics.Clear(MakeColor(0, 0, 0, 0));
      LGraphics.SetCompositingMode(CompositingModeSourceOver);
      var LInset: Single := Max(1.0, ASize / 16.0);
      DrawSphere(LGraphics, MakeRect(LInset, LInset,
        ASize - LInset * 2.0, ASize - LInset * 2.0), AColor);
    finally
      LGraphics.Free;
    end;
    if LGPBitmap.GetHBITMAP(MakeColor(0, 0, 0, 0), LHandle) <> Ok then
      raise EInvalidGraphic.Create('Unable to create the bullet bitmap.');
    ABitmap.Handle := LHandle;
    ABitmap.PixelFormat := pf32bit;
  finally
    LGPBitmap.Free;
  end;
end;

function CreateBulletIcon(AColor: TColor; ASize: Integer): HICON;
var
  LIconInfo: TIconInfo;
  LMaskBits: TBytes;
begin
  Result := 0;
  if ASize <= 0 then
    Exit;
  var LBitmap := TBitmap.Create;
  try
    CreateBulletBitmap(LBitmap, AColor, ASize);
    var LMaskStride := ((ASize + 15) div 16) * 2;
    SetLength(LMaskBits, LMaskStride * ASize);
    FillChar(LMaskBits[0], Length(LMaskBits), 0);
    FillChar(LIconInfo, SizeOf(LIconInfo), 0);
    LIconInfo.fIcon := True;
    LIconInfo.hbmColor := LBitmap.Handle;
    LIconInfo.hbmMask := CreateBitmap(ASize, ASize, 1, 1, @LMaskBits[0]);
    if LIconInfo.hbmMask <> 0 then
    try
      Result := CreateIconIndirect(LIconInfo);
    finally
      DeleteObject(LIconInfo.hbmMask);
    end;
  finally
    LBitmap.Free;
  end;
end;

end.
