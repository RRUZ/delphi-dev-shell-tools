//**************************************************************************************************
//
// Unit DelphiDevShellTools.GUI.ExtensionDialog
// Palette-aware prompt for a custom tool file extension.
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
// The Original Code is DelphiDevShellTools.GUI.ExtensionDialog.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.GUI.ExtensionDialog;

interface

uses
  System.Classes,
  System.Types,
  Vcl.Controls,
  Vcl.ExtCtrls,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.TitleBarCtrls,
  DelphiDevShellTools.UI,
  DelphiDevShellTools.GUI.PaletteDialog;

type
  TFrmExtensionDialog = class(TPaletteDialog)
    ExtensionLabel: TLabel;
    ExtensionEdit: TEdit;
    OkButton: TSimpleUIButton;
    CancelButton: TSimpleUIButton;
    TitleBarPanel: TTitleBarPanel;
    ShapeExtensionInput: TShape;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure InputFocusChanged(Sender: TObject);
  private
    procedure ApplyPalette;
  public
    class function Execute(AOwner: TComponent; const AInitialValue: string;
      out AValue: string): Boolean; static;
  end;

implementation

uses
  Vcl.Themes;

type
  TControlAccess = class(TControl);

{$R *.dfm}

procedure TFrmExtensionDialog.FormCreate(Sender: TObject);
begin
  ApplyPalette;
end;

procedure TFrmExtensionDialog.FormShow(Sender: TObject);
begin
  InputFocusChanged(ExtensionEdit);
end;

procedure TFrmExtensionDialog.ApplyPalette;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  Color := LTheme.BackgroundColor;
  Font.Name := TDevShellTheme.cFontName;
  Font.Size := TDevShellTheme.cFontSize;
  Font.Color := LTheme.TextColor;
  ExtensionLabel.Transparent := True;
  ExtensionLabel.Font.Assign(Font);
  ExtensionLabel.Font.Color := LTheme.TextColor;
  TControlAccess(ExtensionEdit).StyleElements := [];
  ExtensionEdit.BorderStyle := bsNone;
  ExtensionEdit.Color := BlendColor(LTheme.BackgroundColor,
    LTheme.TextColor, 0.08);
  ExtensionEdit.Font.Assign(Font);
  ExtensionEdit.Font.Color := LTheme.TextColor;
  ShapeExtensionInput.StyleElements := [];
  ShapeExtensionInput.Shape := stRoundRect;
  ShapeExtensionInput.Brush.Color := ExtensionEdit.Color;
  ShapeExtensionInput.Pen.Width := 1;
  ApplyDevShellThemeToButton(OkButton, LTheme);
  ApplyDevShellThemeToButton(CancelButton, LTheme);
  OkButton.Font.Assign(Font);
  CancelButton.Font.Assign(Font);
end;

procedure TFrmExtensionDialog.InputFocusChanged(Sender: TObject);
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  if ExtensionEdit.Focused then
    ShapeExtensionInput.Pen.Color := LTheme.AccentColor
  else
    ShapeExtensionInput.Pen.Color := BlendColor(LTheme.TextColor,
      LTheme.BackgroundColor, 0.72);
end;

class function TFrmExtensionDialog.Execute(AOwner: TComponent;
  const AInitialValue: string; out AValue: string): Boolean;
begin
  AValue := AInitialValue;
  var LDialog := TFrmExtensionDialog.Create(AOwner);
  try
    LDialog.ExtensionEdit.Text := AInitialValue;
    LDialog.ExtensionEdit.SelectAll;
    Result := LDialog.ShowModal = mrOk;
    if Result then
      AValue := LDialog.ExtensionEdit.Text;
  finally
    LDialog.Free;
  end;
end;

end.
