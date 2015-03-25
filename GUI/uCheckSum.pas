//**************************************************************************************************
//
// Unit uCheckSum
// unit for the Delphi Dev Shell Tools
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
// The Original Code is uCheckSum.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2015 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit uCheckSum;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TFrmCheckSum = class(TForm)
    Label1: TLabel;
    Label2: TLabel;
    EditFileName: TEdit;
    Button1: TButton;
    EditCheckSum: TMemo;
    RbUpCase: TRadioButton;
    RbLowCase: TRadioButton;
    procedure FormShow(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure RbUpCaseClick(Sender: TObject);
    procedure RbLowCaseClick(Sender: TObject);
  private
    FFileName: string;
    FCheckSumAlgo: string;
    { Private declarations }
  public
    { Public declarations }
    property FileName : string read FFileName write FFileName;
    property CheckSumAlgo : string read FCheckSumAlgo write FCheckSumAlgo;
  end;


var
  FrmCheckSum : TFrmCheckSum;

implementation

{$R *.dfm}

uses
  IdHashCRC,
  IdSSLOpenSSL,
  IdHashSHA,
  IdHashMessageDigest;

function SHA1FromFile(const FileName: string): string;
var
  LSHA1: TIdHashSHA1;
  LStream : TFileStream;
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
  LStream : TFileStream;
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
  LStream : TFileStream;
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
  LStream : TFileStream;
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
  LStream : TFileStream;
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
  LStream : TFileStream;
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
  LStream : TFileStream;
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
  LoadOpenSSLLibrary;
end;

procedure TFrmCheckSum.FormShow(Sender: TObject);
begin
   Caption:=CheckSumAlgo;
   EditFileName.Text:=FileName;

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
end;

procedure TFrmCheckSum.RbLowCaseClick(Sender: TObject);
begin
  EditCheckSum.Text:=LowerCase(EditCheckSum.Text);
end;

procedure TFrmCheckSum.RbUpCaseClick(Sender: TObject);
begin
  EditCheckSum.Text:=UpperCase(EditCheckSum.Text);
end;

end.
