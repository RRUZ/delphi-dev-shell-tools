//**************************************************************************************************
//
// Unit ShellTools.CheckBoxTests
// Palette checkbox registration, rendering and native state regression tests.
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
// The Original Code is ShellTools.CheckBoxTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.CheckBoxTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TCheckBoxTests = class
  public
    [Test] procedure ConcreteCheckBoxesUsePaletteHook;
    [TestCase('LightUnchecked', '0,0,1,0')]
    [TestCase('DarkChecked', '1,1,1,0')]
    [TestCase('LightMixed', '0,2,1,0')]
    [TestCase('DarkMixedDisabled', '1,2,0,0')]
    [TestCase('LightCheckedRight', '0,1,1,1')]
    [TestCase('DarkUncheckedRight', '1,0,1,1')]
    procedure RenderingPreservesPaletteStateAndAlignment(
      AThemeKind, AState, AEnabled, ARightAligned: Integer);
    [Test] procedure NativeClickStillTogglesCheckState;
  end;

implementation

uses
  Winapi.Windows, Winapi.Messages, System.Classes, System.Types, Vcl.Forms, Vcl.Controls,
  Vcl.Graphics, Vcl.StdCtrls, Vcl.Themes, DelphiDevShellTools.UI;

type
  TCheckBoxHookProbe = class(TDevShellCheckBoxStyleHook)
  public
    procedure Render(ACanvas: TCanvas);
  end;

  TStyleEngineProbe = class(TCustomStyleEngine)
  public
    class function HookFor(AControlClass: TClass): TStyleHookClass;
  end;

class function TStyleEngineProbe.HookFor(AControlClass: TClass): TStyleHookClass;
begin
  Result := RegisteredStyleHooks[AControlClass].Last;
end;

procedure TCheckBoxHookProbe.Render(ACanvas: TCanvas);
begin
  Paint(ACanvas);
end;

procedure TCheckBoxTests.ConcreteCheckBoxesUsePaletteHook;
begin
  Assert.IsTrue(TStyleEngineProbe.HookFor(TCheckBox) = TDevShellCheckBoxStyleHook);
  Assert.IsTrue(TStyleEngineProbe.HookFor(TCustomCheckBox) = TDevShellCheckBoxStyleHook);
end;

procedure TCheckBoxTests.RenderingPreservesPaletteStateAndAlignment(
  AThemeKind, AState, AEnabled, ARightAligned: Integer);
var
  LClipBefore, LClipAfter: TRect;
begin
  SetDevShellThemeOverride(TDevShellThemeKind(AThemeKind));
  try
    var LForm := TForm.CreateNew(nil);
    try
      var LCheckBox := TCheckBox.Create(LForm);
      LCheckBox.Parent := LForm;
      LCheckBox.SetBounds(0, 0, 120, 30);
      LCheckBox.Caption := '';
      LCheckBox.AllowGrayed := True;
      LCheckBox.State := TCheckBoxState(AState);
      LCheckBox.Enabled := AEnabled <> 0;
      if ARightAligned <> 0 then
        LCheckBox.Alignment := taLeftJustify;
      var LHook := TCheckBoxHookProbe.Create(LCheckBox);
      try
        var LBitmap := TBitmap.Create;
        try
          LBitmap.SetSize(150, 40);
          LBitmap.Canvas.Lock;
          try
            LBitmap.Canvas.Brush.Color := clFuchsia;
            LBitmap.Canvas.FillRect(Rect(0, 0, 150, 40));
            var LDC := LBitmap.Canvas.Handle;
            SetTextColor(LDC, RGB(17, 31, 47));
            SetBkColor(LDC, RGB(23, 37, 53));
            IntersectClipRect(LDC, 0, 0, 145, 38);
            GetClipBox(LDC, LClipBefore);
            LHook.Render(LBitmap.Canvas);
            var LTheme := TDevShellTheme.ActiveTheme;
            Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.BackgroundColor),
              GetPixel(LDC, 60, 15), 'No VCL style background behind the checkbox');
            Assert.AreEqual<Cardinal>(ColorToRGB(clFuchsia), GetPixel(LDC, 140, 15),
              'Clip to the control bounds');
            Assert.AreEqual<Cardinal>(RGB(17, 31, 47), GetTextColor(LDC));
            Assert.AreEqual<Cardinal>(RGB(23, 37, 53), GetBkColor(LDC));
            GetClipBox(LDC, LClipAfter);
            Assert.IsTrue(EqualRect(LClipBefore, LClipAfter));
            var LBoxLeft := 0;
            var LBoxWidth := MulDiv(14, LCheckBox.CurrentPPI, 96);
            if ARightAligned <> 0 then
              LBoxLeft := LCheckBox.Width - LBoxWidth;
            var LColoredPixels := 0;
            for var LX := LBoxLeft to LBoxLeft + LBoxWidth - 1 do
              for var LY := 0 to LCheckBox.Height - 1 do
                if GetPixel(LDC, LX, LY) <> Cardinal(ColorToRGB(LTheme.BackgroundColor)) then
                  Inc(LColoredPixels);
            Assert.IsTrue(LColoredPixels > 10, 'Paint the native-aligned glyph');
            Assert.AreEqual<Integer>(AState, Ord(LCheckBox.State),
              'Painting must not alter checked or mixed state');
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

procedure TCheckBoxTests.NativeClickStillTogglesCheckState;
begin
  var LForm := TForm.CreateNew(nil);
  try
    var LCheckBox := TCheckBox.Create(LForm);
    LCheckBox.Parent := LForm;
    var LHook := TCheckBoxHookProbe.Create(LCheckBox);
    try
      SendMessage(LCheckBox.Handle, BM_CLICK, 0, 0);
      Assert.IsTrue(LCheckBox.Checked);
      SendMessage(LCheckBox.Handle, BM_CLICK, 0, 0);
      Assert.IsFalse(LCheckBox.Checked);
    finally
      LHook.Free;
    end;
  finally
    LForm.Free;
  end;
end;

end.
