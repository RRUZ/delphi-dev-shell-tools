//**************************************************************************************************
//
// Unit DelphiDevShellTools.GUI.PaletteDialog
// Palette-owned VCL CustomTitleBar configuration for small dialogs.
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
//**************************************************************************************************
unit DelphiDevShellTools.GUI.PaletteDialog;

interface

uses
  System.Classes,
  System.Types,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Graphics,
  Vcl.TitleBarCtrls,
  DelphiDevShellTools.UI;

type
  TPaletteDialog = class(TForm)
  private
    procedure TitleBarPaint(Sender: TObject; Canvas: TCanvas; var ARect: TRect);
  public
    constructor Create(AOwner: TComponent); override;
    procedure ApplyPaletteChrome;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Themes;

const
  cTitleBarHeight = 34;

constructor TPaletteDialog.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  BorderStyle := bsSingle;
  BorderIcons := [biSystemMenu];
  DoubleBuffered := True;
  StyleElements := [];
  ApplyPaletteChrome;
end;

procedure TPaletteDialog.ApplyPaletteChrome;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  Color := LTheme.BackgroundColor;
  Font.Name := TDevShellTheme.cFontName;
  Font.Size := TDevShellTheme.cFontSize;
  Font.Color := LTheme.TextColor;

  CustomTitleBar.SystemHeight := False;
  CustomTitleBar.Height := ScaleValue(cTitleBarHeight);
  CustomTitleBar.SystemColors := False;
  CustomTitleBar.StyleColors := False;
  CustomTitleBar.SystemButtons := False;
  CustomTitleBar.ShowIcon := False;
  CustomTitleBar.Enabled := True;
  CustomTitleBar.BackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ForegroundColor := LTheme.TextColor;
  CustomTitleBar.InactiveBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.InactiveForegroundColor := LTheme.MutedColor;
  CustomTitleBar.ButtonBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ButtonForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonHoverBackgroundColor := BlendColor(LTheme.AccentColor,
    LTheme.BackgroundColor, 0.82);
  CustomTitleBar.ButtonHoverForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonPressedBackgroundColor := LTheme.AccentColor;
  CustomTitleBar.ButtonPressedForegroundColor := LTheme.TextColor;
  CustomTitleBar.ButtonInactiveBackgroundColor := LTheme.BackgroundColor;
  CustomTitleBar.ButtonInactiveForegroundColor := LTheme.MutedColor;
  if Assigned(CustomTitleBar.Control) then
  begin
    CustomTitleBar.Control.Height := ScaleValue(cTitleBarHeight);
    if CustomTitleBar.Control is TTitleBarPanel then
      TTitleBarPanel(CustomTitleBar.Control).OnPaint := TitleBarPaint;
    CustomTitleBar.Control.Invalidate;
  end;
end;

procedure TPaletteDialog.TitleBarPaint(Sender: TObject; Canvas: TCanvas;
  var ARect: TRect);
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  Canvas.Brush.Color := LTheme.BackgroundColor;
  Canvas.FillRect(ARect);
  Canvas.Font.Name := TDevShellTheme.cFontName;
  Canvas.Font.Size := TDevShellTheme.cFontSize;
  Canvas.Font.Color := LTheme.TextColor;
  Canvas.Brush.Style := bsClear;
  var LCaptionRect := ARect;
  LCaptionRect.Left := ScaleValue(14);
  LCaptionRect.Right := LCaptionRect.Right - ScaleValue(44);
  DrawText(Canvas.Handle, PChar(Caption), Length(Caption),
    LCaptionRect, DT_LEFT or DT_SINGLELINE or DT_VCENTER or DT_END_ELLIPSIS);
end;

end.
