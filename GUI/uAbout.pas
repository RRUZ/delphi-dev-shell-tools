//**************************************************************************************************
//
// Unit uAbout
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
// The Original Code is uAbout.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2015 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************

unit uAbout;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, pngimage;

type
  TFrmAbout = class(TForm)
    Panel1:    TPanel;
    Button1:   TButton;
    Label1:    TLabel;
    LabelVersion: TLabel;
    Button2:   TButton;
    MemoCopyRights: TMemo;
    Button3: TButton;
    Image2: TImage;
    btnCheckUpdates: TButton;
    Image1: TImage;
    LabelWindowsVersion: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure btnCheckUpdatesClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Image3Click(Sender: TObject);
  private
    { Private declarations }

    protected
  procedure CreateParams(var Params: TCreateParams); override;

  end;

var
  FrmAbout : TFrmAbout;

implementation

uses
  uCheckUpdate,
  ShellApi,
  uMisc;

{$R *.dfm}

procedure TFrmAbout.btnCheckUpdatesClick(Sender: TObject);
var
  Frm: TFrmCheckUpdate;
begin
  Frm := GetUpdaterInstance;
  try
    Frm.ShowModal();
  finally
    Frm.Free;
  end;
end;

procedure TFrmAbout.Button1Click(Sender: TObject);
begin
  Close();
end;

procedure TFrmAbout.Button2Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', PChar('http://code.google.com/p/delphi-dev-shell-tools/'), nil,
    nil, SW_SHOW);
end;

procedure TFrmAbout.Button3Click(Sender: TObject);
begin
   ShellExecute(Handle, 'open', PChar('http://theroadtodelphi.wordpress.com/contributions/'), nil, nil, SW_SHOW);
end;

procedure TFrmAbout.CreateParams(var Params: TCreateParams);
const
  CS_DROPSHADOW = $00020000;
begin
  inherited CreateParams(Params);
  with Params do
    WindowClass.Style := WindowClass.Style or CS_DROPSHADOW;
end;

procedure TFrmAbout.FormClose(Sender: TObject; var Action: TCloseAction);
begin
 Action:=caFree;
end;

procedure TFrmAbout.FormCreate(Sender: TObject);
begin
  if FileExists(IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)))+'DelphiDevShellTools.dll') then
  LabelVersion.Caption    := Format('Version %s', [
  uMisc.GetFileVersion(ExtractFilePath(ParamStr(0))+'DelphiDevShellTools.dll')]);

  LabelWindowsVersion.Caption    := Format('%s', [TOSVersion.ToString]);
  MemoCopyRights.Lines.Add('Shell Extension for Delphi Developers ');
  MemoCopyRights.Lines.Add('Author Rodrigo Ruz rodrigo.ruz.v@gmail.com - © 2013-2014 all rights reserved.');
  MemoCopyRights.Lines.Add('http://code.google.com/p/delphi-dev-shell-tools/');
  MemoCopyRights.Lines.Add('');
  MemoCopyRights.Lines.Add('This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit (http://www.openssl.org/)');
  MemoCopyRights.Lines.Add('');
  MemoCopyRights.Lines.Add('Go Delphi Go');
end;


procedure TFrmAbout.Image3Click(Sender: TObject);
begin
  ShellExecute(Handle, 'open', 'http://tp.embarcadero.com/ctprefer?partner_id=1445&product_id=0',nil,nil, SW_SHOWNORMAL) ;
end;

end.
