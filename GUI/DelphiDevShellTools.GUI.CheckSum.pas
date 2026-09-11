//**************************************************************************************************
//
// Unit DelphiDevShellTools.GUI.CheckSum
// File checksum calculation and result display using Indy hash implementations.
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
// The Original Code is DelphiDevShellTools.GUI.CheckSum.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.GUI.CheckSum;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, System.Types, Vcl.Graphics,
  Vcl.Controls, Vcl.Dialogs, Vcl.Forms, Vcl.StdCtrls,
  Vcl.ExtCtrls,
  Vcl.TitleBarCtrls,
  DelphiDevShellTools.UI, DelphiDevShellTools.GUI.PaletteDialog;

type
  TFrmCheckSum = class(TPaletteDialog)
    Label1: TLabel;
    Label2: TLabel;
    EditFileName: TEdit;
    Button1: TSimpleUIButton;
    EditCheckSum: TMemo;
    RbUpCase: TSimpleUIButton;
    RbLowCase: TSimpleUIButton;
    TitleBarPanel: TTitleBarPanel;
    ShapeFileNameInput: TShape;
    ShapeChecksumInput: TShape;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RbUpCaseClick(Sender: TObject);
    procedure RbLowCaseClick(Sender: TObject);
    procedure InputFocusChanged(Sender: TObject);
  private
    FFileName: string;
    FCheckSumAlgo: string;
    FUpperCase: Boolean;
    procedure ApplyPalette;
    procedure SelectChecksumCase(AUpperCase: Boolean);
    procedure UpdateCaseButtons;
  public
    { Public declarations }
    property FileName: string read FFileName write FFileName;
    property CheckSumAlgo: string read FCheckSumAlgo write FCheckSumAlgo;
  end;


var
  FrmCheckSum: TFrmCheckSum;

implementation

{$R *.dfm}

uses
  Vcl.Themes,
  IdHashCRC,
  IdSSLOpenSSL,
  IdHashSHA,
  IdHashMessageDigest;

type
  TControlAccess = class(TControl);
  TWinControlAccess = class(TWinControl);

function SHA1FromFile(const FileName: string): string;
var
  LSHA1: TIdHashSHA1;
  LStream: TFileStream;
begin
  LStream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LSHA1 := TIdHashSHA1.Create;
    try
      Result := LSHA1.HashStreamAsHex(LStream);
    finally
      LSHA1.Free;
    end;
  finally
    LStream.Free;
  end;
end;

function SHA256FromFile(const FileName: string): string;
var
  LSHA256: TIdHashSHA256;
  LStream: TFileStream;
begin
  LStream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LSHA256 := TIdHashSHA256.Create;
    try
      Result := LSHA256.HashStreamAsHex(LStream);
    finally
      LSHA256.Free;
    end;
  finally
    LStream.Free;
  end;
end;

function SHA384FromFile(const FileName: string): string;
var
  LSHA384: TIdHashSHA384;
  LStream: TFileStream;
begin
  LStream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LSHA384 := TIdHashSHA384.Create;
    try
      Result := LSHA384.HashStreamAsHex(LStream);
    finally
      LSHA384.Free;
    end;
  finally
    LStream.Free;
  end;
end;

function SHA512FromFile(const FileName: string): string;
var
  LSHA512: TIdHashSHA512;
  LStream: TFileStream;
begin
  LStream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LSHA512 := TIdHashSHA512.Create;
    try
      Result := LSHA512.HashStreamAsHex(LStream);
    finally
      LSHA512.Free;
    end;
  finally
    LStream.Free;
  end;
end;

function MD4FromFile(const FileName: string): string;
var
  LMD4: TIdHashMessageDigest4;
  LStream: TFileStream;
begin
  LStream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LMD4 := TIdHashMessageDigest4.Create;
    try
      Result := LMD4.HashStreamAsHex(LStream);
    finally
      LMD4.Free;
    end;
  finally
    LStream.Free;
  end;
end;

function MD5FromFile(const FileName: string): string;
var
  LMD5: TIdHashMessageDigest5;
  LStream: TFileStream;
begin
  LStream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LMD5 := TIdHashMessageDigest5.Create;
    try
      Result := LMD5.HashStreamAsHex(LStream);
    finally
      LMD5.Free;
    end;
  finally
    LStream.Free;
  end;
end;

function CRC32FromFile(const FileName: string): string;
var
  LCRC32: TIdHashCRC32;
  LStream: TFileStream;
begin
  LStream:=TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    LCRC32 := TIdHashCRC32.Create;
    try
      Result := LCRC32.HashStreamAsHex(LStream);
    finally
      LCRC32.Free;
    end;
  finally
    LStream.Free;
  end;
end;

procedure TFrmCheckSum.Button1Click(Sender: TObject);
begin
 Close;
end;

procedure TFrmCheckSum.FormCreate(Sender: TObject);
begin
  FUpperCase := True;
  ApplyPalette;
  UpdateCaseButtons;
end;

procedure TFrmCheckSum.FormShow(Sender: TObject);
begin
   Caption := CheckSumAlgo + ' checksum';
   Label1.Caption := CheckSumAlgo + ' digest';
   EditFileName.Text:=FileName;
   LoadOpenSSLLibrary;

   if CheckSumAlgo='CRC32' then
    EditCheckSum.Text:=CRC32FromFile(FileName)
   else
   if CheckSumAlgo='MD4' then
    EditCheckSum.Text:=MD4FromFile(FileName)
   else
   if CheckSumAlgo='MD5' then
    EditCheckSum.Text:=MD5FromFile(FileName)
   else
   if CheckSumAlgo='SHA1' then
    EditCheckSum.Text:=SHA1FromFile(FileName)
   else
   if CheckSumAlgo='SHA-256' then
    EditCheckSum.Text:=SHA256FromFile(FileName)
   else
   if CheckSumAlgo='SHA-384' then
    EditCheckSum.Text:=SHA384FromFile(FileName)
   else
   if CheckSumAlgo='SHA-512' then
    EditCheckSum.Text:=SHA512FromFile(FileName);
   SelectChecksumCase(FUpperCase);
   InputFocusChanged(EditFileName);
end;

procedure TFrmCheckSum.RbLowCaseClick(Sender: TObject);
begin
  SelectChecksumCase(False);
end;

procedure TFrmCheckSum.RbUpCaseClick(Sender: TObject);
begin
  SelectChecksumCase(True);
end;

procedure TFrmCheckSum.SelectChecksumCase(AUpperCase: Boolean);
begin
  FUpperCase := AUpperCase;
  UpdateCaseButtons;
  if FUpperCase then
    EditCheckSum.Text := UpperCase(EditCheckSum.Text)
  else
    EditCheckSum.Text := LowerCase(EditCheckSum.Text);
end;

procedure TFrmCheckSum.UpdateCaseButtons;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  var LPalette := DevShellButtonPalette(LTheme);
  var LSelectedPalette := LPalette;
  LSelectedPalette.Background := BlendColor(LTheme.AccentColor,
    LTheme.BackgroundColor, 0.78);
  LSelectedPalette.HotBackground := BlendColor(LTheme.AccentColor,
    LTheme.BackgroundColor, 0.70);
  LSelectedPalette.Border := LTheme.AccentColor;
  LSelectedPalette.HotBorder := LTheme.AccentColor;
  LSelectedPalette.PressedBorder := LTheme.AccentColor;
  if FUpperCase then
  begin
    RbUpCase.ApplyPalette(LSelectedPalette);
    RbLowCase.ApplyPalette(LPalette);
  end
  else
  begin
    RbUpCase.ApplyPalette(LPalette);
    RbLowCase.ApplyPalette(LSelectedPalette);
  end;
  RbUpCase.Caption := 'Upper case';
  RbLowCase.Caption := 'Lower case';
end;

procedure TFrmCheckSum.ApplyPalette;
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  Color := LTheme.BackgroundColor;
  Font.Name := TDevShellTheme.cFontName;
  Font.Size := TDevShellTheme.cFontSize;
  Font.Color := LTheme.TextColor;
  for var LLabel in TArray<TLabel>.Create(Label1, Label2) do
  begin
    LLabel.Transparent := True;
    LLabel.Font.Assign(Font);
    LLabel.Font.Color := LTheme.TextColor;
  end;
  for var LInput in TArray<TControl>.Create(EditFileName, EditCheckSum) do
  begin
    LInput.StyleElements := [];
    TControlAccess(LInput).Color := BlendColor(LTheme.BackgroundColor,
      LTheme.TextColor, 0.08);
    TControlAccess(LInput).Font.Assign(Font);
    TControlAccess(LInput).Font.Color := LTheme.TextColor;
  end;
  EditFileName.BorderStyle := bsNone;
  EditCheckSum.BorderStyle := bsNone;
  for var LShape in TArray<TShape>.Create(ShapeFileNameInput,
    ShapeChecksumInput) do
  begin
    LShape.StyleElements := [];
    LShape.Shape := stRoundRect;
    LShape.Pen.Width := 1;
  end;
  ShapeFileNameInput.Brush.Color := EditFileName.Color;
  ShapeChecksumInput.Brush.Color := EditCheckSum.Color;
  RbUpCase.Font.Assign(Font);
  RbLowCase.Font.Assign(Font);
  ApplyDevShellThemeToButton(Button1, LTheme);
  Button1.Font.Assign(Font);
end;

procedure TFrmCheckSum.InputFocusChanged(Sender: TObject);
begin
  var LTheme := TDevShellTheme.ActiveTheme;
  if EditFileName.Focused then
    ShapeFileNameInput.Pen.Color := LTheme.AccentColor
  else
    ShapeFileNameInput.Pen.Color := BlendColor(LTheme.TextColor,
      LTheme.BackgroundColor, 0.72);
  if EditCheckSum.Focused then
    ShapeChecksumInput.Pen.Color := LTheme.AccentColor
  else
    ShapeChecksumInput.Pen.Color := BlendColor(LTheme.TextColor,
      LTheme.BackgroundColor, 0.72);
end;

end.
