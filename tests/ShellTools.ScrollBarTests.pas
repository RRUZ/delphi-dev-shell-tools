//**************************************************************************************************
//
// Unit ShellTools.ScrollBarTests
// Palette scrollbar registration, native scrolling and drawing-state regression tests.
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
// The Original Code is ShellTools.ScrollBarTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.ScrollBarTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TScrollBarTests = class
  public
    [Test] procedure ConcreteControlsUsePaletteHooks;
    [TestCase('LightVertical', '0,1')]
    [TestCase('DarkVertical', '1,1')]
    [TestCase('LightHorizontal', '0,0')]
    [TestCase('DarkHorizontal', '1,0')]
    procedure PalettePaintingPreservesClipAndDC(AThemeKind, AVertical: Integer);
    [Test] procedure MemoScrollMessagesStillMoveContent;
  end;

implementation

uses
  Winapi.Windows, Winapi.Messages, System.Types, System.SysUtils,
  Vcl.Forms, Vcl.Controls, Vcl.Graphics, Vcl.StdCtrls, Vcl.ComCtrls,
  Vcl.ControlList, Vcl.Themes, DelphiDevShellTools.UI;

type
  TMemoHookProbe = class(TDevShellMemoStyleHook)
  public
    function BarRect(AVertical: Boolean): TRect;
    function ThumbRect(AVertical: Boolean): TRect;
    procedure Render(ADC: HDC; AVertical, APressed: Boolean);
  end;

  TStyleEngineProbe = class(TCustomStyleEngine)
  public
    class function HookFor(AControlClass: TClass): TStyleHookClass;
  end;

class function TStyleEngineProbe.HookFor(AControlClass: TClass): TStyleHookClass;
begin
  Result := RegisteredStyleHooks[AControlClass].Last;
end;

function TMemoHookProbe.BarRect(AVertical: Boolean): TRect;
begin
  if AVertical then Result := VertScrollRect else Result := HorzScrollRect;
end;

function TMemoHookProbe.ThumbRect(AVertical: Boolean): TRect;
begin
  if AVertical then Result := VertSliderRect else Result := HorzSliderRect;
end;

procedure TMemoHookProbe.Render(ADC: HDC; AVertical, APressed: Boolean);
begin
  if APressed then
  begin
    VertSliderState := tsThumbBtnVertPressed;
    HorzSliderState := tsThumbBtnHorzPressed;
  end;
  if AVertical then DrawVertScroll(ADC) else DrawHorzScroll(ADC);
end;

procedure PopulateMemo(AMemo: TMemo; AParent: TWinControl);
begin
  AMemo.Parent := AParent;
  AMemo.SetBounds(0, 0, 260, 150);
  AMemo.ScrollBars := ssBoth;
  AMemo.WordWrap := False;
  AMemo.BorderStyle := bsNone;
  for var LIndex := 1 to 80 do
    AMemo.Lines.Add(IntToStr(LIndex) + StringOfChar('W', 120));
  AMemo.SelStart := 0;
end;

procedure TScrollBarTests.ConcreteControlsUsePaletteHooks;
begin
  Assert.IsTrue(TStyleEngineProbe.HookFor(TMemo) = TDevShellMemoStyleHook);
  Assert.IsTrue(TStyleEngineProbe.HookFor(TCustomMemo) = TDevShellMemoStyleHook);
  Assert.IsTrue(TStyleEngineProbe.HookFor(TControlList) = TDevShellControlListStyleHook);
  Assert.IsTrue(TStyleEngineProbe.HookFor(TCustomControlList) = TDevShellControlListStyleHook);
  Assert.IsTrue(TStyleEngineProbe.HookFor(TListView) = TDevShellListViewStyleHook);
  Assert.IsTrue(TStyleEngineProbe.HookFor(TCustomListView) = TDevShellListViewStyleHook);
end;

procedure TScrollBarTests.PalettePaintingPreservesClipAndDC(
  AThemeKind, AVertical: Integer);
var
  LClipBefore, LClipAfter: TRect;
begin
  SetDevShellThemeOverride(TDevShellThemeKind(AThemeKind));
  try
    var LForm := TForm.CreateNew(nil);
    try
      var LMemo := TMemo.Create(LForm);
      PopulateMemo(LMemo, LForm);
      var LHook := TMemoHookProbe.Create(LMemo);
      try
        var LBar := LHook.BarRect(AVertical <> 0);
        var LThumb := LHook.ThumbRect(AVertical <> 0);
        Assert.IsFalse(LBar.IsEmpty, 'The native memo exposes the scrollbar');
        Assert.IsFalse(LThumb.IsEmpty, 'Long text exposes an enabled thumb');
        var LBitmap := TBitmap.Create;
        try
          LBitmap.SetSize(300, 200);
          LBitmap.Canvas.Lock;
          try
            LBitmap.Canvas.Brush.Color := clFuchsia;
            LBitmap.Canvas.FillRect(Rect(0, 0, 300, 200));
            var LDC := LBitmap.Canvas.Handle;
            SetTextColor(LDC, RGB(17, 31, 47));
            SetBkColor(LDC, RGB(23, 37, 53));
            IntersectClipRect(LDC, 0, 0, 290, 190);
            GetClipBox(LDC, LClipBefore);
            var LFont := GetCurrentObject(LDC, OBJ_FONT);
            LHook.Render(LDC, AVertical <> 0, True);
            var LTheme := TDevShellTheme.ActiveTheme;
            Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.BackgroundColor),
              GetPixel(LDC, LBar.Left, LBar.Top), 'Track uses the palette background');
            Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.AccentColor),
              GetPixel(LDC, LThumb.CenterPoint.X, LThumb.CenterPoint.Y),
              'Pressed thumb uses the palette accent');
            Assert.AreEqual<Cardinal>(ColorToRGB(clFuchsia),
              GetPixel(LDC, 2, 2), 'Painting must not enter the memo client');
            Assert.AreEqual<Cardinal>(RGB(17, 31, 47), GetTextColor(LDC));
            Assert.AreEqual<Cardinal>(RGB(23, 37, 53), GetBkColor(LDC));
            Assert.IsTrue(LFont = GetCurrentObject(LDC, OBJ_FONT));
            GetClipBox(LDC, LClipAfter);
            Assert.IsTrue(EqualRect(LClipBefore, LClipAfter), 'Preserve caller clipping');
          finally
            LBitmap.Canvas.Unlock;
          end;
        finally
          LBitmap.Free;
        end;
      finally
        LHook.Free;
      end;
    finally
      LForm.Free;
    end;
  finally
    ClearDevShellThemeOverride;
  end;
end;

procedure TScrollBarTests.MemoScrollMessagesStillMoveContent;
begin
  var LForm := TForm.CreateNew(nil);
  try
    var LMemo := TMemo.Create(LForm);
    PopulateMemo(LMemo, LForm);
    var LHook := TMemoHookProbe.Create(LMemo);
    try
      var LFirstLine := LMemo.Perform(EM_GETFIRSTVISIBLELINE, 0, 0);
      LMemo.Perform(WM_VSCROLL, SB_PAGEDOWN, 0);
      Assert.IsTrue(LMemo.Perform(EM_GETFIRSTVISIBLELINE, 0, 0) > LFirstLine,
        'Inherited VCL scrolling still moves the native memo');
      LMemo.Perform(WM_HSCROLL, SB_LINERIGHT, 0);
      Assert.IsTrue(GetScrollPos(LMemo.Handle, SB_HORZ) > 0,
        'Horizontal scrolling still moves the native memo');
      LMemo.Perform(WM_VSCROLL, SB_TOP, 0);
      Assert.AreEqual<NativeInt>(LFirstLine, LMemo.Perform(EM_GETFIRSTVISIBLELINE, 0, 0));
    finally
      LHook.Free;
    end;
  finally
    LForm.Free;
  end;
end;

end.
