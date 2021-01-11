//**************************************************************************************************
//
// Unit uMiscGUI
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
// The Original Code is uMiscGUI.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2021 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************


unit uMiscGUI;

interface

  procedure MsgWarning(const Msg: string);
  procedure MsgInformation(const Msg: string);
  function  MsgQuestion(const Msg: string):Boolean;

implementation

Uses
 System.UITypes,
 Vcl.Dialogs;


procedure MsgWarning(const Msg: string);
begin
  MessageDlg(Msg, mtWarning ,[mbOK], 0);
end;

procedure MsgInformation(const Msg: string);
begin
  MessageDlg(Msg,  mtInformation ,[mbOK], 0);
end;

function  MsgQuestion(const Msg: string):Boolean;
begin
  Result:= MessageDlg(Msg, mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;



end.
