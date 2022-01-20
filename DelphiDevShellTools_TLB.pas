//**************************************************************************************************
//
// Unit DelphiDevShellTools_TLB
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
// The Original Code is DelphiDevShellTools_TLB.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2021 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools_TLB;

// ************************************************************************ //
// WARNING
// -------
// The types declared in this file were generated from data read from a
// Type Library. If this type library is explicitly or indirectly (via
// another type library referring to this type library) re-imported, or the
// 'Refresh' command of the Type Library Editor activated while editing the
// Type Library, the contents of this file will be regenerated and all
// manual modifications will be lost.
// ************************************************************************ //

// $Rev: 52393 $
// File generated on 8/15/2013 1:09:18 PM from Type Library described below.

// ************************************************************************  //
// Type Lib: C:\Dephi\google-code\dev-shell-tools\DelphiDevShellTools (1)
// LIBID: {6BB542DD-DF25-496B-B7F4-8D530C0A747F}
// LCID: 0
// Helpfile:
// HelpString:
// DepndLst:
//   (1) v2.0 stdole, (C:\Windows\SysWOW64\stdole2.tlb)
// SYS_KIND: SYS_WIN32
// ************************************************************************ //
{$TYPEDADDRESS OFF} // Unit must be compiled without type-checked pointers.
{$WARN SYMBOL_PLATFORM OFF}
{$WRITEABLECONST ON}
{$VARPROPSETTER ON}
{$ALIGN 4}

interface

uses Winapi.Windows, System.Classes, {System.Variants, {System.Win.StdVCL,Vcl.Graphics, Vcl.OleServer,}  Winapi.ActiveX;


// *********************************************************************//
// GUIDS declared in the TypeLibrary. Following prefixes are used:
//   Type Libraries: LIBID_xxxx
//   CoClasses: CLASS_xxxx
//   DISPInterfaces: DIID_xxxx
//   Non-DISP interfaces: IID_xxxx
// *********************************************************************//
const
  // TypeLibrary Major and minor versions
  DelphiDevShellToolsMajorVersion = 1;
  DelphiDevShellToolsMinorVersion = 0;

  LIBID_DelphiDevShellTools: TGUID = '{6BB542DD-DF25-496B-B7F4-8D530C0A747F}';

  IID_IDelphiDevShellToolsContextMenu: TGUID = '{D2E2B705-011B-4D8D-B4C1-97ADD6E9EBCF}';
  CLASS_DelphiDevShellToolsContextMenu: TGUID = '{45DCA61E-3762-45B1-939D-2446C0DCAC25}';
type

// *********************************************************************//
// Forward declaration of types defined in TypeLibrary
// *********************************************************************//
  IDelphiDevShellToolsContextMenu = interface;
  IDelphiDevShellToolsContextMenuDisp = dispinterface;

// *********************************************************************//
// Declaration of CoClasses defined in Type Library
// (NOTE: Here we map each CoClass to its Default Interface)
// *********************************************************************//
  DelphiDevShellToolsContextMenu = IDelphiDevShellToolsContextMenu;


// *********************************************************************//
// Interface: IDelphiDevShellToolsContextMenu
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {D2E2B705-011B-4D8D-B4C1-97ADD6E9EBCF}
// *********************************************************************//
  IDelphiDevShellToolsContextMenu = interface(IDispatch)
    ['{D2E2B705-011B-4D8D-B4C1-97ADD6E9EBCF}']
  end;

// *********************************************************************//
// DispIntf:  IDelphiDevShellToolsContextMenuDisp
// Flags:     (4416) Dual OleAutomation Dispatchable
// GUID:      {D2E2B705-011B-4D8D-B4C1-97ADD6E9EBCF}
// *********************************************************************//
  IDelphiDevShellToolsContextMenuDisp = dispinterface
    ['{D2E2B705-011B-4D8D-B4C1-97ADD6E9EBCF}']
  end;

// *********************************************************************//
// The Class CoDelphiDevShellToolsContextMenu provides a Create and CreateRemote method to
// create instances of the default interface IDelphiDevShellToolsContextMenu exposed by
// the CoClass DelphiDevShellToolsContextMenu. The functions are intended to be used by
// clients wishing to automate the CoClass objects exposed by the
// server of this typelibrary.
// *********************************************************************//
  CoDelphiDevShellToolsContextMenu = class
    class function Create: IDelphiDevShellToolsContextMenu;
    class function CreateRemote(const MachineName: string): IDelphiDevShellToolsContextMenu;
  end;

implementation

uses System.Win.ComObj;

class function CoDelphiDevShellToolsContextMenu.Create: IDelphiDevShellToolsContextMenu;
begin
  Result := CreateComObject(CLASS_DelphiDevShellToolsContextMenu) as IDelphiDevShellToolsContextMenu;
end;

class function CoDelphiDevShellToolsContextMenu.CreateRemote(const MachineName: string): IDelphiDevShellToolsContextMenu;
begin
  Result := CreateRemoteComObject(MachineName, CLASS_DelphiDevShellToolsContextMenu) as IDelphiDevShellToolsContextMenu;
end;

end.

