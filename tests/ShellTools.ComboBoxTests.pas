//**************************************************************************************************
// Unit ShellTools.ComboBoxTests
// Regression checks for palette combo rendering, registration and borrowed drawing state.
// https://github.com/RRUZ/delphi-dev-shell-tools
// The contents of this file are subject to the Mozilla Public License Version 1.1.
// License: http://www.mozilla.org/MPL/
// Software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY KIND.
// Copyright (C) 2026 Rodrigo Ruz V. All Rights Reserved.
//**************************************************************************************************
unit ShellTools.ComboBoxTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TComboBoxTests = class
  public
    [Test] procedure ConcreteComboUsesPaletteHook;
    [TestCase('Light', '0')]
    [TestCase('Dark', '1')]
    procedure ClosedSelectionUsesPaletteAndPreservesDC(AThemeKind: Integer);
    [Test] procedure EditableChildIsExcludedFromBorderPainting;
  end;

implementation

uses
  Winapi.Windows, System.Types, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  Vcl.Themes, DelphiDevShellTools.UI;

type
  TComboHookProbe = class(TDevShellComboBoxStyleHook)
  public
    procedure RenderBorder(ACanvas: TCanvas);
    procedure RenderSelection(ACanvas: TCanvas; const ARect: TRect);
  end;

  TStyleEngineProbe = class(TCustomStyleEngine)
  public
    class function ConcreteHook: TStyleHookClass;
  end;

procedure TComboHookProbe.RenderBorder(ACanvas: TCanvas);
begin
  PaintBorder(ACanvas);
end;

procedure TComboHookProbe.RenderSelection(ACanvas: TCanvas;
  const ARect: TRect);
begin
  DrawItem(ACanvas, 0, ARect, True);
end;

class function TStyleEngineProbe.ConcreteHook: TStyleHookClass;
begin
  Result := RegisteredStyleHooks[TComboBox].Last;
end;

procedure TComboBoxTests.ConcreteComboUsesPaletteHook;
begin
  Assert.IsTrue(TStyleEngineProbe.ConcreteHook = TDevShellComboBoxStyleHook,
    'TComboBox has its own VCL registration and must override that exact class');
end;

procedure TComboBoxTests.ClosedSelectionUsesPaletteAndPreservesDC(
  AThemeKind: Integer);
begin
  SetDevShellThemeOverride(TDevShellThemeKind(AThemeKind));
  try
    var LTheme := TDevShellTheme.ActiveTheme;
    var LForm := TForm.CreateNew(nil);
    try
      var LCombo := TComboBox.Create(LForm);
      LCombo.Parent := LForm;
      LCombo.Style := csDropDownList;
      LCombo.Items.Add('Delphi 13');
      LCombo.ItemIndex := 0;
      var LHook := TComboHookProbe.Create(LCombo);
      try
        var LBitmap := TBitmap.Create;
        try
          LBitmap.SetSize(180, 30);
          LBitmap.Canvas.Lock;
          try
            for var LIndex := 1 to 3 do
            begin
              var LDC := LBitmap.Canvas.Handle;
              SetTextColor(LDC, RGB(17, 31, 47));
              SetBkColor(LDC, RGB(23, 37, 53));
              var LFont := GetCurrentObject(LDC, OBJ_FONT);
              LHook.RenderSelection(LBitmap.Canvas, Rect(0, 0, 180, 30));
              Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.BackgroundColor),
                GetPixel(LDC, 0, 0), 'Focused closed selection keeps the input background');
              Assert.AreEqual<Cardinal>(RGB(17, 31, 47), GetTextColor(LDC));
              Assert.AreEqual<Cardinal>(RGB(23, 37, 53), GetBkColor(LDC));
              Assert.IsTrue(LFont = GetCurrentObject(LDC, OBJ_FONT));
            end;
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

procedure TComboBoxTests.EditableChildIsExcludedFromBorderPainting;
var
  LInfo: TComboBoxInfo;
begin
  var LForm := TForm.CreateNew(nil);
  try
    var LCombo := TComboBox.Create(LForm);
    LCombo.Parent := LForm;
    LCombo.Style := csDropDown;
    LCombo.Width := 180;
    LInfo := Default(TComboBoxInfo);
    LInfo.cbSize := SizeOf(LInfo);
    Assert.IsTrue(GetComboBoxInfo(LCombo.Handle, LInfo));
    var LHook := TComboHookProbe.Create(LCombo);
    try
      var LBitmap := TBitmap.Create;
      try
        LBitmap.SetSize(LCombo.Width, LCombo.Height);
        LBitmap.Canvas.Lock;
        try
        LBitmap.Canvas.Brush.Color := clFuchsia;
        LBitmap.Canvas.FillRect(Rect(0, 0, LBitmap.Width, LBitmap.Height));
        LHook.RenderBorder(LBitmap.Canvas);
        Assert.AreEqual<Cardinal>(ColorToRGB(clFuchsia),
          GetPixel(LBitmap.Canvas.Handle, LInfo.rcItem.CenterPoint.X,
            LInfo.rcItem.CenterPoint.Y), 'The native edit child owns its pixels');
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
end;

end.
