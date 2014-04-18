//**************************************************************************************************
//
// Unit DelphiDevShellToolsImpl
// unit for the Delphi Dev Shell Tools
// http://code.google.com/p/delphi-dev-shell-tools/
//
// The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy of the
// License at http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
// ANY KIND, either express or implied. See the License for the specific language governing rights
// and limitations under the License.
//
// The Original Code is DelphiDevShellToolsImpl.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2014 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellToolsImpl;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  uMisc,
  uTasks,
  Generics.Defaults,
  Generics.Collections,
  System.Win.ComObj,
  uDelphiVersions,
  Winapi.ActiveX,
  DelphiDevShellTools_TLB,
  System.Rtti,
  Winapi.ShlObj,
  Winapi.Windows,
  Winapi.ShellAPI;

type

  TDelphiDevShellToolsContextMenu = class(TAutoObject, IDelphiDevShellToolsContextMenu,
  IShellExtInit, IContextMenu, IContextMenu2, IContextMenu3)
  private
    FFileName, FFileExt: string;
    DProjectVersion : SetDelphiVersions;
    FMSBuildDProj : TMSBuildDProj;
    FMSBuildGroupDProj : TMSBuildGroupProj;
    FMethodsDict : TObjectDictionary<Integer, TMethodInfo>;
    FOwnerDrawId : UINT;
    DelphiDevShellTasks : TDelphiDevShellTasks;

    procedure AddCommonTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddOpenRADCmdTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddMSBuildRAD_SpecificTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddMSBuildRAD_AllTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddOpenWithDelphi(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddOpenWithDelphi_GroupProject(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);

    procedure AddMSBuildPAClientTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddOpenVclStyleTask(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddCheckSumTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddRADStudioToolsTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    //Lazarus & FPC
    procedure AddLazarusTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddFPCToolsTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    //-------------------
    procedure AddExternalToolsTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    //Menu helper functions
    function  InsertMenuDevShell(hMenu: HMENU; uPosition: UINT; uIDNewItem: UINT_PTR; lpNewItem, IconName: LPCWSTR): BOOL;
    procedure RegisterMenuItemBitmapDevShell(hMenu: HMENU; uPosition, wID: UINT; const IconName : String);
    procedure RegisterMenuItemBitmapExternal(hMenu: HMENU; uPosition, wID: UINT; const IconName : String);
    procedure AddMenuSeparatorEx(hMenu : HMENU; var MenuIndex : Integer);

  protected
    function IShellExtInit.Initialize = ShellExtInitialize;
    function ShellExtInitialize(pidlFolder: PItemIDList; lpdobj: IDataObject; hKeyProgID: HKEY): HResult; stdcall;
    function QueryContextMenu(Menu: HMENU; indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult; stdcall;
    function InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult; stdcall;
    function GetCommandString(idCmd: UINT_PTR; uFlags: UINT; pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult; stdcall;
    //IContextMenu2
    function HandleMenuMsg(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HResult; stdcall;
    //IContextMenu3
    function HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
    function MenuMessageHandler(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
  public
    constructor Create;
    destructor Destroy; override;
  end;

  TDelphiDevShellObjectFactory = class(TAutoObjectFactory)
  protected
    function GetProgID: string; override;
  public
    procedure UpdateRegistry(Register: Boolean); override;
  end;



implementation

uses
  uLazarusVersions,
//  Vcl.Styles,
//  Vcl.Themes,
  Vcl.Graphics,
  Vcl.GraphUtil,
  Math,
  PngImage,
  Winapi.Messages,
  Datasnap.DBClient,
  System.Types,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.Win.ComServ,
  System.SysUtils,
  System.Win.Registry;

{$R images.res}

var
  InstalledDelphiVersions : TObjectList<TDelphiVersionData>;
  PAClientProfiles        : TPAClientProfileList;
  BitmapsDict        : TObjectDictionary<string, TBitmap>;
  IconsExternals     : TObjectDictionary<string, TIcon>;//TIcon is a instance
  IconsDictExternal  : TDictionary<Integer, TIcon>;//TIcon is only a refernce
  IconsDictResources : TDictionary<Integer, string>;

  ExeNameTxt, FriendlyAppNameTxt : string;
  LazarusInstalled : Boolean;
  Settings         : TSettings;
  DelphiToolsExts, ExternalToolsExts, FPCToolsExts     : TStringDynArray;

  procedure RegisterBitmap32(const ResourceName: string); forward;


constructor TDelphiDevShellToolsContextMenu.Create;
begin
  inherited;
  DelphiDevShellTasks:=TDelphiDevShellTasks.Create;
  FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues]);
end;

destructor TDelphiDevShellToolsContextMenu.Destroy;
begin
  DelphiDevShellTasks.Free;
  if FMethodsDict<>nil then
    FMethodsDict.Free;
  inherited;
end;


function TDelphiDevShellToolsContextMenu.GetCommandString(idCmd: UINT_PTR; uFlags: UINT;
  pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult;
begin
  Result := E_INVALIDARG;
end;

function TDelphiDevShellToolsContextMenu.InsertMenuDevShell(hMenu: HMENU; uPosition: UINT; uIDNewItem: UINT_PTR; lpNewItem, IconName: LPCWSTR) : BOOL;
var
  LMenuItem : TMenuItemInfo;
begin
  try
    ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
    LMenuItem.cbSize := SizeOf(TMenuItemInfo);
    LMenuItem.fMask  := MIIM_FTYPE or MIIM_ID or MIIM_BITMAP or MIIM_STRING;
    LMenuItem.fType  := MFT_STRING;
    LMenuItem.wID    := uIDNewItem;
    LMenuItem.dwTypeData := lpNewItem;
    if (IconName<>nil) and (IsVistaOrLater and BitmapsDict.ContainsKey(IconName)) then
      LMenuItem.hbmpItem   := BitmapsDict[IconName].Handle
    else
    if (IconName<>nil) and not IsVistaOrLater then
      LMenuItem.hbmpItem   :=HBMMENU_CALLBACK;

     //LMenuItem.hbmpItem   := IfThen(IsVistaOrLater, BitmapsDict[IconName].Handle ,HBMMENU_CALLBACK);
    //log('InsertMenuEx HBMMENU_CALLBACK '+IntToStr(uIDNewItem));
    Result:=InsertMenuItem(hMenu, uPosition, True, LMenuItem);

    if not Result then
     log(SysErrorMessage(GetLastError));
  except
   on  E : Exception do
   begin
     Result:=False;
     log(Format('TDelphiDevShellToolsContextMenu.InsertMenuDevShell Message %s  Trace %s',[E.Message, e.StackTrace]));
   end;
  end;
end;


procedure TDelphiDevShellToolsContextMenu.RegisterMenuItemBitmapDevShell(hMenu: HMENU;
  uPosition, wID: UINT; const IconName : String);
//var
//  LMenuInfo    : TMenuItemInfo;
//  Buffer       : array [0..79] of char;
begin
  if IsVistaOrLater then exit;
  log('RegisterMenuItemBitmapDevShell '+IconName+' init');
  try
    if not IconsDictResources.ContainsKey(wID) then
    begin
     IconsDictResources.Add(wID, IconName);
     log('RegisterMenuItemBitmapDevShell '+IconName+' ok wID '+IntToStr(wID));
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.RegisterMenuItemBitmapDevShell Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;

//  //log('SetMenuItemBitmapsEx GetMenuItemInfo '+IconName);
//  LMenuInfo.cbSize := sizeof(LMenuInfo);
//  LMenuInfo.fMask  := MIIM_ID;
//  LMenuInfo.dwTypeData := Buffer;
//  LMenuInfo.cch := SizeOf(Buffer);
//  if GetMenuItemInfo(hMenu, uPosition, True, LMenuInfo) then
//  begin
//    //log('SetMenuItemBitmapsEx GetMenuItemInfo wID '+IntToStr(LMenuInfo.wID));
//    //if LMenuInfo.wID=0 then  LMenuInfo.wID:=uFlags;
//
//    if not IconsDictResources.ContainsKey(LMenuInfo.wID) then
//    begin
//     IconsDictResources.Add(LMenuInfo.wID, IconName);
//     log('RegisterMenuItemBitmapDevShell '+IconName+' ok wID '+IntToStr(LMenuInfo.wID));
//    end;
//  end
//  else
//    log(SysErrorMessage(GetLastError));
end;

procedure  TDelphiDevShellToolsContextMenu.RegisterMenuItemBitmapExternal(hMenu: HMENU; uPosition, wID: UINT; const IconName : String);
{
var
  LMenuInfo    : TMenuItemInfo;
  Buffer       : array [0..79] of char;
}
begin
  if IsVistaOrLater then exit;

  try
    if not IconsDictExternal.ContainsKey(wID) then
     IconsDictExternal.Add(wID, IconsExternals[IconName]);
  except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.RegisterMenuItemBitmapDevShell Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;

{
  try
    LMenuInfo.cbSize := sizeof(LMenuInfo);
    LMenuInfo.fMask  := MIIM_ID;
    LMenuInfo.dwTypeData := Buffer;
    LMenuInfo.cch := SizeOf(Buffer);
    if GetMenuItemInfo(hMenu, uPosition, True, LMenuInfo) then
    begin
      if not IconsDictExternal.ContainsKey(LMenuInfo.wID) then
       IconsDictExternal.Add(LMenuInfo.wID, IconsExternals[IconName]);
    end
    else
      log(SysErrorMessage(GetLastError));
  except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.RegisterMenuItemBitmapExternal Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
}
end;


procedure TDelphiDevShellToolsContextMenu.AddMenuSeparatorEx(hMenu : HMENU; var MenuIndex : Integer);
var
  LMenuInfo    : TMenuItemInfo;
  Buffer       : array [0..79] of char;
begin
  try
    LMenuInfo.cbSize := sizeof(LMenuInfo);
    LMenuInfo.fMask  := MIIM_TYPE;
    LMenuInfo.dwTypeData := Buffer;
    LMenuInfo.cch := SizeOf(Buffer);
    if GetMenuItemInfo(hMenu, MenuIndex-1, True, LMenuInfo) then
    begin
      log('GetMenuItemInfo ok '+IntToStr(LMenuInfo.fType));
      if (LMenuInfo.fType and MFT_SEPARATOR) = MFT_SEPARATOR then
      else
      begin
        log('adding separator');
        InsertMenu(hMenu, MenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
        inc(MenuIndex);
      end;
    end
    else
      log(SysErrorMessage(GetLastError));
  except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.AddMenuSeparatorEx Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

function TDelphiDevShellToolsContextMenu.InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult;
var
  LVerb: Word;
begin
  try
    if FMSBuildDProj<>nil then
    begin
      FMSBuildDProj.Free;
      FMSBuildDProj:=nil;
    end;

    if FMSBuildGroupDProj<>nil then
    begin
      FMSBuildGroupDProj.Free;
      FMSBuildGroupDProj:=nil;
    end;


    Result := E_FAIL;
    log('InvokeCommand lpVerb '+IntToStr(Integer(lpici.lpVerb)));
    if HiWord(Integer(lpici.lpVerb)) <> 0 then
      Exit;

    LVerb := LoWord(Integer(lpici.lpVerb));
    log('InvokeCommand '+IntToStr(LVerb));
    if FMethodsDict.ContainsKey(LVerb) then
    begin
      log('InvokeCommand Exec');
      FMethodsDict.Items[LVerb].hwnd:=lpici.hwnd;
      FMethodsDict.Items[LVerb].Method(FMethodsDict.Items[LVerb]);
      Result:=NOERROR;
    end;
  except on  E : Exception do
    begin
     log(Format('TDelphiDevShellToolsContextMenu.InvokeCommand Message %s  Trace %s',[E.Message, e.StackTrace]));
     Result := E_FAIL;
    end;
  end;
end;


function TDelphiDevShellToolsContextMenu.MenuMessageHandler(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
const
  Dx = 20;
  Dy = 5;
  MinHeight = 16;
var
  i, Lx,Ly :Integer;
  LCanvas: TCanvas;
  SaveIndex: Integer;
  LIcon : TIcon;
  LCurrentDelphiVersionData : TDelphiVersionData;
  Found : Boolean;
begin
  try
    case uMsg of

      WM_MEASUREITEM:
      begin
        if PMeasureItemStruct(lParam)=nil then Exit(S_OK);
        if PMeasureItemStruct(lParam)^.itemID<>FOwnerDrawId then
        begin
            PMeasureItemStruct(lParam)^.itemWidth := PMeasureItemStruct(lParam)^.itemWidth+2;
            if (PMeasureItemStruct(lParam)^.itemHeight < MinHeight) then
               PMeasureItemStruct(lParam)^.itemHeight := MinHeight;
        end
        else
        if PMeasureItemStruct(lParam)^.itemID=FOwnerDrawId then
        begin
          with PMeasureItemStruct(lParam)^ do
          begin
            itemWidth :=380;
            itemHeight:=120;
              if (FMSBuildDProj<>nil) and (FMSBuildDProj.TargetPlatforms.Count>1) then
                itemHeight:= itemHeight+((18+Dy)*UINT(FMSBuildDProj.TargetPlatforms.Count));
          end;
        end;
      end;

      WM_DRAWITEM:
      begin

          if PDrawItemStruct(lParam)^.itemID<>FOwnerDrawId then
          with PDrawItemStruct(lParam)^ do
          begin
              if IconsDictResources.ContainsKey(PDrawItemStruct(lParam)^.itemID) then
              begin
                LIcon:=TIcon.Create;
                try
                 LIcon.LoadFromResourceName(HInstance,IconsDictResources[PDrawItemStruct(lParam)^.itemID]);
                 DrawIconEx(hDC,rcItem.Left-16, rcItem.Top + (rcItem.Bottom - rcItem.Top - 16) div 2,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                finally
                 LIcon.Free;
                end;
              end
              else
              if IconsDictExternal.ContainsKey(PDrawItemStruct(lParam)^.itemID) then
                 DrawIconEx(hDC,rcItem.Left-16, rcItem.Top + (rcItem.Bottom - rcItem.Top - 16) div 2,  IconsDictExternal[PDrawItemStruct(lParam)^.itemID].Handle, 16, 16,  0, 0, DI_NORMAL);
          end
          else
          if (PDrawItemStruct(lParam)^.itemID=FOwnerDrawId)  then
          begin
            with PDrawItemStruct(lParam)^ do
            begin

              LCanvas := TCanvas.Create;
              try
                SaveIndex := SaveDC(hDC);
                try
                  LCanvas.Handle := hDC;

//                  if itemState = ODS_SELECTED then
//                  begin
//                    LCanvas.Brush.Color := clHighlight;
//                    LCanvas.Font.Color := clHighlightText;
//                  end
//                  else
//                  begin
//                    LCanvas.Brush.Color := clMenu;
//                    LCanvas.Font.Color := clMenuText;
//                  end;

                  LCanvas.Brush.Color := clMenu;
                  LCanvas.Font.Color  := clMenuText;
                  LCanvas.FillRect(rcItem);

                  Ly:=rcItem.Top  + Dy;
                  Lx:=rcItem.Left + Dx;

                  LCanvas.TextOut(Lx, Ly, 'Delphi Version (Detected)');
                  LIcon:=TIcon.Create;
                  try
                    Found:=False;
                    for LCurrentDelphiVersionData in InstalledDelphiVersions do
                     if LCurrentDelphiVersionData.Version=FMSBuildDProj.DelphiVersion then
                     begin
                        LIcon.Assign(LCurrentDelphiVersionData.Icon);
                        Found:=True;
                        break;
                     end;
                     {
                     if Found then
                     begin
                       DrawIconEx(hDC, Lx+140, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                       LCanvas.TextOut(Lx+140+LIcon.Width+3, Ly, DelphiVersionsNames[FMSBuildDProj.DelphiVersion]);
                     end
                     else
                       LCanvas.TextOut(Lx+140, Ly, DelphiVersionsNames[FMSBuildDProj.DelphiVersion]);
                     }
                     LCanvas.TextOut(Lx+140, Ly, DelphiVersionsNames[FMSBuildDProj.DelphiVersion]);
                     if Found then
                       DrawIconEx(hDC, Lx+140+LCanvas.TextWidth(DelphiVersionsNames[FMSBuildDProj.DelphiVersion])+3, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                  finally
                   LIcon.Free;
                  end;

                  LIcon:=TIcon.Create;
                  try
                   LIcon.LoadFromResourceName(HInstance,'delphi_ico');
                   DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                  finally
                   LIcon.Free;
                  end;


                  Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
                  LCanvas.TextOut(Lx, Ly, 'Project Type');
                  LCanvas.TextOut(Lx+140, Ly, FMSBuildDProj.AppType);

                  Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
                  LCanvas.TextOut(Lx, Ly, 'Framework Type');
                  LCanvas.TextOut(Lx+140, Ly, FMSBuildDProj.FrameworkType);
                  if SameText(FMSBuildDProj.FrameworkType,'FMX') then
                  begin
                    LIcon:=TIcon.Create;
                    try
                     LIcon.LoadFromResourceName(HInstance,'firemonkey_ico');
                     DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                    finally
                     LIcon.Free;
                    end;
                  end
                  else
                  begin
                    LIcon:=TIcon.Create;
                    try
                     LIcon.LoadFromResourceName(HInstance,'vcl_ico');
                     DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                    finally
                     LIcon.Free;
                    end;
                  end;


                  Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
                  LCanvas.TextOut(Lx, Ly, 'GUID');
                  LCanvas.TextOut(Lx+140, Ly, FMSBuildDProj.GUID);

                  Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
                  LCanvas.TextOut(Lx, Ly, 'Current Build Configuration');
                  LCanvas.TextOut(Lx+140, Ly, FMSBuildDProj.DefaultConfiguration);
                    LIcon:=TIcon.Create;
                    try
                     LIcon.LoadFromResourceName(HInstance,'buildconf_ico');
                     DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                    finally
                     LIcon.Free;
                    end;

                  Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
                  LCanvas.TextOut(Lx, Ly, 'Current Target Platform');
                  LCanvas.TextOut(Lx+140, Ly, FMSBuildDProj.DefaultPlatForm);

                 if StartsText('Win', FMSBuildDProj.DefaultPlatForm) then
                  begin
                    LIcon:=TIcon.Create;
                    try
                     LIcon.LoadFromResourceName(HInstance,'win_ico');
                     DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                    finally
                     LIcon.Free;
                    end;
                  end
                 else
                 if StartsText('OSX', FMSBuildDProj.DefaultPlatForm) then
                  begin
                    LIcon:=TIcon.Create;
                    try
                     LIcon.LoadFromResourceName(HInstance,'osx_ico');
                     DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                    finally
                     LIcon.Free;
                    end;
                  end
                 else
                 if StartsText('IOS', FMSBuildDProj.DefaultPlatForm) then
                  begin
                    LIcon:=TIcon.Create;
                    try
                     LIcon.LoadFromResourceName(HInstance,'ios_ico');
                     DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                    finally
                     LIcon.Free;
                    end;
                  end
                 else
                 if StartsText('Android', FMSBuildDProj.DefaultPlatForm) then
                  begin
                    LIcon:=TIcon.Create;
                    try
                     LIcon.LoadFromResourceName(HInstance,'android_ico');
                     DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                    finally
                     LIcon.Free;
                    end;
                  end;

                  if (FMSBuildDProj<>nil) and (FMSBuildDProj.TargetPlatforms.Count>1) then
                  begin
                    Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
                    LCanvas.TextOut(Lx, Ly, 'Target Platforms');

                    LIcon:=TIcon.Create;
                    try
                     LIcon.LoadFromResourceName(HInstance,'platforms_ico');
                     DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                    finally
                     LIcon.Free;
                    end;

                     for i := 0 to FMSBuildDProj.TargetPlatforms.Count-1 do
                     begin
                        Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
                        LCanvas.TextOut(Lx+25, Ly, FMSBuildDProj.TargetPlatforms[i]);
                        if StartsText('Win', FMSBuildDProj.TargetPlatforms[i]) then
                        begin
                          LIcon:=TIcon.Create;
                          try
                           LIcon.LoadFromResourceName(HInstance,'win_ico');
                           DrawIconEx(hDC,Lx+5, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                          finally
                           LIcon.Free;
                          end;
                        end
                        else
                        if StartsText('OSX', FMSBuildDProj.TargetPlatforms[i]) then
                        begin
                          LIcon:=TIcon.Create;
                          try
                           LIcon.LoadFromResourceName(HInstance,'osx_ico');
                           DrawIconEx(hDC,Lx+5, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                          finally
                           LIcon.Free;
                          end;
                        end
                        else
                        if StartsText('IOS', FMSBuildDProj.TargetPlatforms[i]) then
                        begin
                          LIcon:=TIcon.Create;
                          try
                           LIcon.LoadFromResourceName(HInstance,'ios_ico');
                           DrawIconEx(hDC,Lx+5, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                          finally
                           LIcon.Free;
                          end;
                        end
                        else
                        if StartsText('Android', FMSBuildDProj.TargetPlatforms[i]) then
                        begin
                          LIcon:=TIcon.Create;
                          try
                           LIcon.LoadFromResourceName(HInstance,'android_ico');
                           DrawIconEx(hDC,Lx+5, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                          finally
                           LIcon.Free;
                          end;
                        end;
                     end;
                  end;

                finally
                  LCanvas.Handle := 0;
                  RestoreDC(hDC, SaveIndex);
                end;
              finally
                LCanvas.Free;
              end;

            end;
          end;
      end;

    end;
    Result:=S_OK;

  except on  E : Exception do
    begin
     log(Format('TDelphiDevShellToolsContextMenu.MenuMessageHandler Message %s  Trace %s',[E.Message, e.StackTrace]));
     Result := E_FAIL;
    end;
  end;
end;

//IContextMenu2
function TDelphiDevShellToolsContextMenu.HandleMenuMsg(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HResult; stdcall;
var
 res : Winapi.Windows.LPARAM;
begin
 //log('HandleMenuMsg');
 Result:=MenuMessageHandler ( uMsg, wParam, lParam, res);
end;

//IContextMenu3
function TDelphiDevShellToolsContextMenu.HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
begin
  //log('HandleMenuMsg2');
  Result:= MenuMessageHandler( uMsg, wParam, lParam, lpResult);
end;


procedure TDelphiDevShellToolsContextMenu.AddCheckSumTasks(hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LMethodInfo : TMethodInfo;
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption : string;
begin
  try
   if not MatchText(FFileExt, SupportedExts) then exit;

      if (1=1){Settings.SubMenuCommonTasks} then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='Calculate Checksum';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize := SizeOf(TMenuItemInfo);
        LMenuItem.fMask  := MIIM_SUBMENU or MIIM_FTYPE or  MIIM_ID or MIIM_BITMAP or MIIM_STRING;
        LMenuItem.fType  := MFT_STRING;
        LMenuItem.wID    := uIDNewItem;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['checksum'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['checksum'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['checksum'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'checksum_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;



     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate CRC32'), nil);
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='CRC32';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate MD4'), nil);
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='MD4';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate MD5'), nil);
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='MD5';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate SHA1'), nil);
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='SHA1';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate SHA-256'), nil);
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='SHA-256';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate SHA-384'), nil);
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='SHA-384';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate SHA-512'), nil);
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='SHA-512';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     {
      if not Settings.SubMenuCommonTasks then
       MenuIndex:=LSubMenuIndex;
     }
  except
    on  E : Exception do
     log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;
procedure TDelphiDevShellToolsContextMenu.AddCommonTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  LMethodInfo : TMethodInfo;
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption : string;
begin
  try
   if not MatchText(FFileExt, SupportedExts) then exit;

      if Settings.SubMenuCommonTasks then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='Common Tasks';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize   := SizeOf(TMenuItemInfo);
        LMenuItem.fMask    := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
        LMenuItem.fType    := MFT_STRING;
        LMenuItem.wID      := uIDNewItem;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['common'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['common'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['common'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        if not IsVistaOrLater then
          RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'common_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;


     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Copy File Path to clipboard'), 'copy_path');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'copy_path_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.CopyPathClipboard;
     LMethodInfo.Value1:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Copy full FileName (Path + FileName) to clipboard'),'copy');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'copy_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.CopyFileNameClipboard;
     LMethodInfo.Value1:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Copy FileName using URL format (file://...) to clipboard'),'copy_url');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'copy_url_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.CopyFileNameUrlClipboard;
     LMethodInfo.Value1:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Copy FileName using UNC format (\\server-name\Shared...) to clipboard'),'copy_unc');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'copy_unc_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.CopyFileNameUNCClipboard;
     LMethodInfo.Value1:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Copy FileName using Unix format (Drive:/Path/Filaname) to clipboard'),'copy_unc');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'copy_unc_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.CopyFileNameUnixClipboard;
     LMethodInfo.Value1:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Copy File content to the clipboard'), 'copy_content');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'copy_content_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.CopyFileContentClipboard;
     LMethodInfo.Value1:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);


     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open In Notepad'), 'notepad');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'notepad_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenWithNotepad;
     LMethodInfo.Value1:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     try
       if (ExeNameTxt<>'') and (not SameText('notepad.exe', ExtractFileName(ExeNameTxt))) then
       begin
           log(ExtractFileName(ExeNameTxt));
           InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open In '+FriendlyAppNameTxt), 'txt');
           RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, 'txt');
           LMethodInfo:=TMethodInfo.Create;
           LMethodInfo.Method:=DelphiDevShellTasks.OpenWithApp;
           LMethodInfo.Value1:=ExeNameTxt;
           LMethodInfo.Value2:=FFileName;
           FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
           Inc(uIDNewItem);
           Inc(LSubMenuIndex);
       end;

     except
       on  E : Exception do
       log('GetAssocAppByExt '+E.Message);
     end;

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open Command Line here'), 'cmd');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'cmd_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenCmdHere;
     LMethodInfo.Value1:=False;
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open Command Line here as Administrator'), 'shield');
     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'shield_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=DelphiDevShellTasks.OpenCmdHere;
     LMethodInfo.Value1:=True;
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

      if not Settings.SubMenuCommonTasks then
       MenuIndex:=LSubMenuIndex;

  except
    on  E : Exception do
     log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure TDelphiDevShellToolsContextMenu.AddOpenRADCmdTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
 try
  if not MatchText(FFileExt, SupportedExts) then exit;

    //Open RAD Studio Command Prompt Here
    Found:=false;
    for LCurrentDelphiVersionData in InstalledDelphiVersions do
     if LCurrentDelphiVersionData.Version>=Delphi2007 then
     begin
      Found:=True;
      Break;
     end;

    if Found then
    begin
      if Settings.SubMenuOpenCmdRAD then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='Open RAD Studio Command Prompt Here';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize := SizeOf(TMenuItemInfo);
        LMenuItem.fMask  := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
        LMenuItem.fType  := MFT_STRING;
        LMenuItem.wID        := uIDNewItem;
        LMenuItem.hSubMenu   := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['radcmd'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['radcmd'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['radcmd'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        if not IsVistaOrLater then
          RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'radcmd_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
        LSubMenuIndex := MenuIndex;
        LSubMenu      := hMenu;
      end;

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
        InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' Command Prompt'), PWideChar(LCurrentDelphiVersionData.Name));
        if not IconsDictExternal.ContainsKey(uIDNewItem) then
          IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);
        //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=DelphiDevShellTasks.OpenRADCmd;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        LMethodInfo.Value2:=FFileName;
        FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;

      if not Settings.SubMenuOpenCmdRAD then
       MenuIndex:=LSubMenuIndex;
    end;
 except
   on  E : Exception do
   log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

procedure TDelphiDevShellToolsContextMenu.AddExternalToolsTasks(hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LClientDataSet : TClientDataSet;
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  s, sSubMenuCaption : string;

  LMethodInfo : TMethodInfo;
  LArray : TStringDynArray;
begin
  try
    if not MatchText(FFileExt, SupportedExts) then exit;


      if (1=1){Settings.SubMenuLazarus} then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='External Tools';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize     := SizeOf(TMenuItemInfo);
        LMenuItem.fMask      := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
        LMenuItem.fType      := MFT_STRING;
        LMenuItem.wID        := uIDNewItem;
        LMenuItem.hSubMenu   := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['wrench'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['wrench'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['wrench'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'wrench_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;

       LClientDataSet:= TClientDataSet.Create(nil);
       try
           LClientDataSet.ReadOnly:=True;
           LClientDataSet.LoadFromFile(GetDelphiDevShellToolsFolder+'tools.db');
           LClientDataSet.Open;
           LClientDataSet.Filter:='Group = '+QuotedStr('External Tools');
           LClientDataSet.Filtered:=True;

            while not LClientDataSet.eof do
            begin
             LArray:= SplitString(LClientDataSet.FieldByName('Extensions').AsString, ',');
             if MatchText(FFileExt, LArray) then
             begin

              if (LClientDataSet.FieldByName('Image').IsNull) or (not FileExists(GetDevShellToolsImagesFolder+LClientDataSet.FieldByName('Image').AsString)) then
               InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil, FFileName)), nil)
              else
              begin
                s:=LClientDataSet.FieldByName('Image').AsString;

                RegisterBitmap32(s);
                InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil, FFileName)), PWideChar(s));
                if not IsVistaOrLater then
                  RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, s);
              end;

              LMethodInfo:=TMethodInfo.Create;
              LMethodInfo.Method:=DelphiDevShellTasks.ExternalTools;
              LMethodInfo.Value1:=DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Script').AsString, nil, FFileName);
              LMethodInfo.Value2:=False;
              if (not LClientDataSet.FieldByName('RunAs').IsNull) then
               LMethodInfo.Value2:=LClientDataSet.FieldByName('RunAs').AsBoolean;

              FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
              Inc(uIDNewItem);
              Inc(LSubMenuIndex);
             end;
             LClientDataSet.Next;
            end;

       finally
         LClientDataSet.Free;
       end;

               {
      if not Settings.SubMenuLazarus then
       MenuIndex:=LSubMenuIndex;
               }
  except
    on  E : Exception do
    log(Format('TDelphiDevShellToolsContextMenu.AddFPCToolsTasks Message %s Trace %s',[E.Message, e.StackTrace]));
  end;
end;



procedure TDelphiDevShellToolsContextMenu.AddFPCToolsTasks(hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LClientDataSet : TClientDataSet;
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  s, sSubMenuCaption : string;

  LMethodInfo : TMethodInfo;
  LArray : TStringDynArray;
begin
  try
    if not MatchText(FFileExt, SupportedExts) then exit;


      if (1=1){Settings.SubMenuLazarus} then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='Free Pascal Tools';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize   := SizeOf(TMenuItemInfo);
        LMenuItem.fMask    := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
        LMenuItem.fType    := MFT_STRING;
        LMenuItem.wID      := uIDNewItem;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['fpc_tools'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['fpc_tools'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['fpc_tools'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'fpc_tools_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;

       LClientDataSet:= TClientDataSet.Create(nil);
       try
           LClientDataSet.ReadOnly:=True;
           LClientDataSet.LoadFromFile(GetDelphiDevShellToolsFolder+'tools.db');
           LClientDataSet.Open;
           LClientDataSet.Filter:='Group = '+QuotedStr('FPC Tools');
           LClientDataSet.Filtered:=True;

            while not LClientDataSet.eof do
            begin
             LArray:= SplitString(LClientDataSet.FieldByName('Extensions').AsString, ',');
             if MatchText(FFileExt, LArray) then
             begin

              if (LClientDataSet.FieldByName('Image').IsNull) or (not FileExists(GetDevShellToolsImagesFolder+LClientDataSet.FieldByName('Image').AsString)) then
               InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil, FFileName)), nil)
              else
              begin
                s:=LClientDataSet.FieldByName('Image').AsString;

                RegisterBitmap32(s);
                InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil, FFileName)), PWideChar(s));
                if not IsVistaOrLater then
                  RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, s);
              end;

              LMethodInfo:=TMethodInfo.Create;
              LMethodInfo.Method:=DelphiDevShellTasks.FPCTools;
              LMethodInfo.Value1:=DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Script').AsString, nil, FFileName);
              LMethodInfo.Value2:=False;
              if (not LClientDataSet.FieldByName('RunAs').IsNull) then
               LMethodInfo.Value2:=LClientDataSet.FieldByName('RunAs').AsBoolean;

              FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
              Inc(uIDNewItem);
              Inc(LSubMenuIndex);
             end;
             LClientDataSet.Next;
            end;

       finally
         LClientDataSet.Free;
       end;

               {
      if not Settings.SubMenuLazarus then
       MenuIndex:=LSubMenuIndex;
               }
  except
    on  E : Exception do
    log(Format('TDelphiDevShellToolsContextMenu.AddFPCToolsTasks Message %s Trace %s',[E.Message, e.StackTrace]));
  end;
end;


procedure TDelphiDevShellToolsContextMenu.AddMSBuildRAD_SpecificTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenu: Winapi.Windows.HMENU;
  LSubMenuIndex : Integer;
  LMenuItem: TMenuItemInfo;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LCurrentDelphiVersion      : TDelphiVersions;
  LFileName, sPlatform, sSubMenuCaption, sBuildConfiguration : string;
  LMethodInfo : TMethodInfo;
begin
  try
     if not MatchText(FFileExt, SupportedExts) then exit;

     if (Length(DProjectVersion)=0) then exit;

     Found:=False;

     LCurrentDelphiVersion:=DProjectVersion[0];

     LCurrentDelphiVersionData:=InstalledDelphiVersions[0];
     for LCurrentDelphiVersionData in InstalledDelphiVersions do
      if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
      begin
       Found:=True;
       Break;
      end;

     if Found and (InstalledDelphiVersions.Count>0) and (Length(DProjectVersion)>0) then
       begin

        if Settings.SubMenuMSBuild then
        begin
          LSubMenuIndex :=0;
          LSubMenu   := CreatePopupMenu;
          sSubMenuCaption:='Run MSBuild '+DelphiVersionsNames[DProjectVersion[0]];

          ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
          LMenuItem.cbSize   := SizeOf(TMenuItemInfo);
          LMenuItem.fMask    := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
          LMenuItem.fType    := MFT_STRING;
          LMenuItem.wID      := uIDNewItem;
          LMenuItem.hSubMenu := LSubMenu;
          LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
          LMenuItem.cch := Length(sSubMenuCaption);
          LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
          LMenuItem.hbmpChecked   := BitmapsDict['delphi'].Handle;
          LMenuItem.hbmpUnchecked := BitmapsDict['delphi'].Handle;
          InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

          if not IsVistaOrLater then
            RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');

          Inc(uIDNewItem);
          Inc(MenuIndex);
        end
        else
        begin
          LSubMenu:=hMenu;
          LSubMenuIndex:=MenuIndex;
        end;

          LFileName:=ChangeFileExt(FFileName,'.dproj');

         if  (FMSBuildDProj<>nil) and (FMSBuildDProj.ValidData) then
         for LCurrentDelphiVersion in DProjectVersion do
         for sPlatform in FMSBuildDProj.TargetPlatforms do
         begin


           for sBuildConfiguration in FMSBuildDProj.BuildConfigurations do
           begin
             Found:=False;
             if SameText(sPlatform, FMSBuildDProj.DefaultPlatForm) and (SameText(sBuildConfiguration, FMSBuildDProj.DefaultConfiguration)) then
             begin
               sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - '+sBuildConfiguration+') - Default Configuration';
               Found:=True;
             end
             else
               sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - '+sBuildConfiguration+')';


             if StartsText('Win', sPlatform) then
              InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'win')
             else
             if StartsText('OSX', sPlatform) then
              InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'osx')
             else
             if StartsText('IOS', sPlatform) then
              InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'ios')
             else
             if StartsText('Android', sPlatform) then
              InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'android');



             if not IsVistaOrLater then
             begin
               if StartsText('Win', sPlatform) then
                 RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'win_ico')
               else
               if StartsText('OSX', sPlatform) then
                 RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'osx_ico')
               else
               if StartsText('IOS', sPlatform) then
                 RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'ios_ico')
               else
               if StartsText('android', sPlatform) then
                 RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'android_ico');
             end;

             if Found then
             SetMenuDefaultItem(LSubMenu, LSubMenuIndex, 1);


             LMethodInfo:=TMethodInfo.Create;
             LMethodInfo.Method:=DelphiDevShellTasks.MSBuildWithDelphi;
             LMethodInfo.Value1:=LCurrentDelphiVersionData;
             LMethodInfo.Value2:=sPlatform;
             LMethodInfo.Value3:=sBuildConfiguration;
             LMethodInfo.Value4:=LFileName;

             FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
             Inc(uIDNewItem);
             Inc(LSubMenuIndex);
           end;
         end;

        if not Settings.SubMenuMSBuild then
          MenuIndex:=LSubMenuIndex;

       end;
  except
   on  E : Exception do
   log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure TDelphiDevShellToolsContextMenu.AddMSBuildPAClientTasks(hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenu: Winapi.Windows.HMENU;
  i, LSubMenuIndex : Integer;
  LMenuItem: TMenuItemInfo;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LFileName, sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
  LPAClientProfile : TPAClientProfile;
begin
  try
     if not MatchText(FFileExt, SupportedExts) then exit;

     Found:=False;

     for LCurrentDelphiVersionData in InstalledDelphiVersions do
      if (LCurrentDelphiVersionData.Version>=DelphiXE2) and  not Found then
       for i:= 0 to PAClientProfiles.Profiles.Count-1 do
        if PAClientProfiles.Profiles[i].RADStudioVersion=LCurrentDelphiVersionData.Version then
        begin
         Found:=True;
         Break;
        end;

     if Found and (InstalledDelphiVersions.Count>0)  then
       begin

        if {Settings.SubMenuMSBuild}1=1 then
        begin
          LSubMenuIndex :=0;
          LSubMenu   := CreatePopupMenu;
          sSubMenuCaption:='PAClient';

          ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
          LMenuItem.cbSize   := SizeOf(TMenuItemInfo);
          LMenuItem.fMask    := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
          LMenuItem.fType    := MFT_STRING;
          LMenuItem.wID      := uIDNewItem;
          LMenuItem.hSubMenu := LSubMenu;
          LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
          LMenuItem.cch := Length(sSubMenuCaption);
          LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
          LMenuItem.hbmpChecked   := BitmapsDict['delphi'].Handle;
          LMenuItem.hbmpUnchecked := BitmapsDict['delphi'].Handle;
          InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

          if not IsVistaOrLater then
            RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');

          Inc(uIDNewItem);
          Inc(MenuIndex);
        end
        else
        begin
          LSubMenu:=hMenu;
          LSubMenuIndex:=MenuIndex;
        end;

          LFileName:=FFileName;

        for LCurrentDelphiVersionData in InstalledDelphiVersions do
          if (LCurrentDelphiVersionData.Version>=DelphiXE2) then
            for i:= 0 to PAClientProfiles.Profiles.Count-1 do
             if PAClientProfiles.Profiles[i].RADStudioVersion=LCurrentDelphiVersionData.Version then
             begin
               LPAClientProfile:=PAClientProfiles.Profiles[i];
               sSubMenuCaption:='Test Profile '+LPAClientProfile.Name+Format(' (Platform : %s - Host : %s - Port : %d)',[LPAClientProfile.Platform, LPAClientProfile.Host, LPAClientProfile.Port]);

                 if StartsText('Win', LPAClientProfile.Platform) then
                   InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'win')
                 else
                 if StartsText('OSX', LPAClientProfile.Platform) then
                   InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'osx')
                 else
                 if StartsText('IOS', LPAClientProfile.Platform) then
                   InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'ios')
                 else
                 if StartsText('Android', LPAClientProfile.Platform) then
                   InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'android');

                 //log(Format('%s %d',[sSubMenuCaption, LSubMenuIndex]));

                 if not IsVistaOrLater then
                 begin
                   if StartsText('Win', LPAClientProfile.Platform) then
                     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'win_ico')
                   else
                   if StartsText('OSX', LPAClientProfile.Platform) then
                     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'osx_ico')
                   else
                   if StartsText('IOS', LPAClientProfile.Platform) then
                     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'ios_ico')
                   else
                   if StartsText('Android', LPAClientProfile.Platform) then
                     RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'android_ico');
                 end;

                 LMethodInfo:=TMethodInfo.Create;
                 LMethodInfo.Method:=DelphiDevShellTasks.PAClientTest;
                 LMethodInfo.Value1:=LCurrentDelphiVersionData;
                 LMethodInfo.Value2:=LPAClientProfile.Name;

                 FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                 Inc(uIDNewItem);
                 Inc(LSubMenuIndex);
             end;

        if not Settings.SubMenuMSBuild then
          MenuIndex:=LSubMenuIndex;

       end;
  except
   on  E : Exception do
   log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;


procedure TDelphiDevShellToolsContextMenu.AddMSBuildRAD_AllTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenuIndex : Integer;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption, sValue : string;
  LMethodInfo : TMethodInfo;
begin
  try
    if not MatchText(FFileExt, SupportedExts) then exit;


    Found:=False;
    for LCurrentDelphiVersionData in InstalledDelphiVersions do
    if (LCurrentDelphiVersionData.Version>=Delphi2007) and (  ((FMSBuildDProj <>nil) and (LCurrentDelphiVersionData.Version<>FMSBuildDProj.DelphiVersion)) or MatchText(FFileExt,['.groupproj','.proj'])) then
    begin
      Found:=True;
      Break;
    end;

    if Found then
    begin
      if Settings.SubMenuMSBuildAnother then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='Run MSBUILD with another Delphi version';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize     := SizeOf(TMenuItemInfo);
        LMenuItem.fMask      := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
        LMenuItem.fType      := MFT_STRING;
        LMenuItem.wID        := uIDNewItem;
        LMenuItem.hSubMenu   := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['msbuild'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['msbuild'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['msbuild'].Handle;
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'msbuild_ico');

        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
        LSubMenuIndex:=MenuIndex;
        LSubMenu:=hMenu;
      end;

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if (LCurrentDelphiVersionData.Version>=Delphi2007) and (((FMSBuildDProj <>nil) and (LCurrentDelphiVersionData.Version<>FMSBuildDProj.DelphiVersion)) or MatchText(FFileExt,['.groupproj','.proj'])) then
       begin
        InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('MSBuild with '+LCurrentDelphiVersionData.Name), PWideChar(LCurrentDelphiVersionData.Name));

        if not IsVistaOrLater then
        if not IconsDictExternal.ContainsKey(uIDNewItem) then
          IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);

        //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=DelphiDevShellTasks.MSBuildWithDelphi_Default;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        LMethodInfo.Value2:=FFileName;

        if SameText(FFileExt, '.dpr') then
        begin
         sValue:=ChangeFileExt(FFileName,'.dproj');
         if TFile.Exists(sValue) then
           LMethodInfo.Value2:=sValue;
        end;

        FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;

      if not Settings.SubMenuMSBuildAnother then
        MenuIndex:=LSubMenuIndex;

    end;
  except
   on  E : Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure TDelphiDevShellToolsContextMenu.AddOpenVclStyleTask(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenuIndex : Integer;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
  try
    if not MatchText(FFileExt, SupportedExts) then exit;

    Found:=False;
    for LCurrentDelphiVersionData in InstalledDelphiVersions do
    if LCurrentDelphiVersionData.Version>=DelphiXE2 then
    begin
      Found:=True;
      Break;
    end;

    if Found then
    begin
      if Settings.SubMenuOpenVclStyle then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='View Vcl Style File';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize := SizeOf(TMenuItemInfo);
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := uIDNewItem;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['vcl'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['vcl'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['vcl'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        if not IsVistaOrLater then
         RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'vcl_ico');

        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
        LSubMenu:=hMenu;
        LSubMenuIndex:=MenuIndex;
      end;

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=DelphiXE2 then
       begin
        InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Use Viewer of '+LCurrentDelphiVersionData.Name), PWideChar(LCurrentDelphiVersionData.Name));

        if not IsVistaOrLater then
        if not IconsDictExternal.ContainsKey(uIDNewItem) then
          IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);

        //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=DelphiDevShellTasks.OpenVclStyle;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        LMethodInfo.Value2:=FFileName;
        FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;

      if not Settings.SubMenuOpenVclStyle then
       MenuIndex:=LSubMenuIndex;
    end;
  except
    on  E : Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;


procedure TDelphiDevShellToolsContextMenu.AddLazarusTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
  try
    if not MatchText(FFileExt, SupportedExts) then exit;

      if Settings.SubMenuLazarus then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='Lazarus';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize := SizeOf(TMenuItemInfo);
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := uIDNewItem;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['lazarusmenu'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['lazarusmenu'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['lazarusmenu'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'lazarusmenu_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;

      InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open with Lazarus IDE'), 'lazarus');
      if not IsVistaOrLater then
        RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, 'lazarus');

      LMethodInfo:=TMethodInfo.Create;
      LMethodInfo.Method:=DelphiDevShellTasks.OpenWithLazarus;
      LMethodInfo.Value1:=GetLazarusIDEFileName;
      LMethodInfo.Value2:=FFileName;
      FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
      Inc(uIDNewItem);
      Inc(LSubMenuIndex);


      if MatchText(FFileExt, ['.lpi', '.lpk']) then
      begin
        InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Build with lazbuild'), 'lazbuild');
        if not IsVistaOrLater then
          RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'lazbuild_ico');
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=DelphiDevShellTasks.BuildWithLazBuild;
        LMethodInfo.Value1:=GetLazarusIDEFolder;
        LMethodInfo.Value2:=FFileName;
        FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
      end;


      if not Settings.SubMenuLazarus then
       MenuIndex:=LSubMenuIndex;

  except
    on  E : Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure TDelphiDevShellToolsContextMenu.AddOpenWithDelphi(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  Found : Boolean;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LCurrentDelphiVersion      : TDelphiVersions;
  sValue, sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
  try
     if (InstalledDelphiVersions.Count=0) or (not MatchText(FFileExt, SupportedExts)) then exit;

     if Settings.SubMenuOpenDelphi then
     begin
      LSubMenuIndex :=0;
      LSubMenu   := CreatePopupMenu;
      sSubMenuCaption:='Open with Delphi';

      ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
      LMenuItem.cbSize := SizeOf(TMenuItemInfo);
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := uIDNewItem;
      LMenuItem.hSubMenu := LSubMenu;
      LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
      LMenuItem.cch := Length(sSubMenuCaption);
      LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
      LMenuItem.hbmpChecked   := BitmapsDict['delphi'].Handle;
      LMenuItem.hbmpUnchecked := BitmapsDict['delphi'].Handle;
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      if not IsVistaOrLater then
      RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');
      Inc(uIDNewItem);
      Inc(MenuIndex);
     end
     else
     begin
      LSubMenuIndex:=MenuIndex;
      LSubMenu:=hMenu;
     end;


     if  MatchText(FFileExt, ['.dproj', '.dpr']) then
     begin
       for LCurrentDelphiVersionData in InstalledDelphiVersions do
       //if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
         Found:=False;
         if LCurrentDelphiVersionData.Version>=Delphi2007 then
         for LCurrentDelphiVersion in DProjectVersion do
         if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name+' (Detected)';
           InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));
           SetMenuDefaultItem(LSubMenu, LSubMenuIndex, 1);
           Found:=True;
           Break;
         end;

         if not Found then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
           InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));
         end;

        if not IsVistaOrLater then
        if not IconsDictExternal.ContainsKey(uIDNewItem) then
          IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);
         //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=DelphiDevShellTasks.OpenRADStudio;
         LMethodInfo.Value1:=LCurrentDelphiVersionData;
         LMethodInfo.Value2:=FFileName;
         LMethodInfo.Value3:=EmptyStr;
         if LCurrentDelphiVersionData.Version>=Delphi2007 then
         LMethodInfo.Value3:='-pDelphi';

         if SameText(FFileExt, '.dpr') then
         begin
          sValue:=ChangeFileExt(FFileName,'.dproj');
          if TFile.Exists(sValue) then
            LMethodInfo.Value2:=sValue;
         end;

         FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
         Inc(uIDNewItem);
         Inc(LSubMenuIndex);
       end
     end
     else
     //if  MatchText(FFileExt, ['.pas','.inc','.pp','.dpk'])  then
     for LCurrentDelphiVersionData in InstalledDelphiVersions do
     begin
       sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
       InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));

        if not IsVistaOrLater then
        if not IconsDictExternal.ContainsKey(uIDNewItem) then
          IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);

       //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
       LMethodInfo:=TMethodInfo.Create;
       LMethodInfo.Method:=DelphiDevShellTasks.OpenWithDelphi;
       LMethodInfo.Value1:=LCurrentDelphiVersionData;
       LMethodInfo.Value2:=FFileName;
       LMethodInfo.Value3:=EmptyStr;
       if LCurrentDelphiVersionData.Version>=Delphi2005 then
        LMethodInfo.Value3:='-pDelphi';

       FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
       Inc(uIDNewItem);
       Inc(LSubMenuIndex);
     end;

     if not Settings.SubMenuOpenDelphi then
      MenuIndex:=LSubMenuIndex;
  except
    on  E : Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure TDelphiDevShellToolsContextMenu.AddOpenWithDelphi_GroupProject(
  hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  Found : Boolean;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LCurrentDelphiVersion      : TDelphiVersions;
  sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
  try
     if (InstalledDelphiVersions.Count=0) or (not MatchText(FFileExt, SupportedExts)) then exit;


     if Settings.SubMenuOpenDelphi then
     begin
      LSubMenuIndex :=0;
      LSubMenu   := CreatePopupMenu;
      sSubMenuCaption:='Open Project Group with Delphi';

      ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
      LMenuItem.cbSize := SizeOf(TMenuItemInfo);
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := uIDNewItem;
      LMenuItem.hSubMenu := LSubMenu;
      LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
      LMenuItem.cch := Length(sSubMenuCaption);
      LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
      LMenuItem.hbmpChecked   := BitmapsDict['delphi'].Handle;
      LMenuItem.hbmpUnchecked := BitmapsDict['delphi'].Handle;
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      if not IsVistaOrLater then
      RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');
      Inc(uIDNewItem);
      Inc(MenuIndex);
     end
     else
     begin
      LSubMenuIndex:=MenuIndex;
      LSubMenu:=hMenu;
     end;


     if  MatchText(FFileExt, ['.groupproj']) then
     begin
       for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
         Found:=False;
         for LCurrentDelphiVersion in DProjectVersion do
         if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name+' (Detected)';
           InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));
           SetMenuDefaultItem(LSubMenu, LSubMenuIndex, 1);
           Found:=True;
           Break;
         end;

         if not Found then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
           InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));
         end;

        if not IsVistaOrLater then
        if not IconsDictExternal.ContainsKey(uIDNewItem) then
          IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);
         //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=DelphiDevShellTasks.OpenRADStudio;
         LMethodInfo.Value1:=LCurrentDelphiVersionData;
         LMethodInfo.Value2:=FFileName;
         LMethodInfo.Value3:=EmptyStr;
         if LCurrentDelphiVersionData.Version>=Delphi2007 then
         LMethodInfo.Value3:='-pDelphi';

         FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
         Inc(uIDNewItem);
         Inc(LSubMenuIndex);
       end
     end;

     if not Settings.SubMenuOpenDelphi then
      MenuIndex:=LSubMenuIndex;
  except
    on  E : Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure TDelphiDevShellToolsContextMenu.AddRADStudioToolsTasks(hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LClientDataSet : TClientDataSet;
  LSubMenuIndex : Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  s, sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
  LArray : TStringDynArray;
begin
  try
    if (InstalledDelphiVersions.Count=0) or (not MatchText(FFileExt, SupportedExts)) then exit;


      if (1=1) then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='Delphi && RAD Studio Tools';

        ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
        LMenuItem.cbSize := SizeOf(TMenuItemInfo);
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := uIDNewItem;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := BitmapsDict['delphi'].Handle;
        LMenuItem.hbmpUnchecked := BitmapsDict['delphi'].Handle;
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');

        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;


       LClientDataSet:= TClientDataSet.Create(nil);
       try
           LClientDataSet.ReadOnly:=True;
           LClientDataSet.LoadFromFile(GetDelphiDevShellToolsFolder+'tools.db');
           LClientDataSet.Open;
           LClientDataSet.Filter:='Group = '+QuotedStr('Delphi Tools');
           LClientDataSet.Filtered:=True;

           for LCurrentDelphiVersionData in InstalledDelphiVersions do
           begin
            LClientDataSet.First;

            while not LClientDataSet.eof do
            begin
             if (LClientDataSet.FieldByName('DelphiVersion').IsNull) or (LCurrentDelphiVersionData.Version>=TDelphiVersions(LClientDataSet.FieldByName('DelphiVersion').AsInteger)) then
             begin
               LArray:= SplitString(LClientDataSet.FieldByName('Extensions').AsString, ',');
               if MatchText(FFileExt, LArray) then
               begin
                if (LClientDataSet.FieldByName('Image').IsNull) or (not FileExists(GetDevShellToolsImagesFolder+LClientDataSet.FieldByName('Image').AsString)) then
                  InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' - '+DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, LCurrentDelphiVersionData, FFileName)), nil)
                else
                begin
                  s:=LClientDataSet.FieldByName('Image').AsString;

                  RegisterBitmap32(s);
                  InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' - '+DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, LCurrentDelphiVersionData, FFileName)), PWideChar(s));
                  if not IsVistaOrLater then
                    RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, s);
                end;

                LMethodInfo:=TMethodInfo.Create;
                LMethodInfo.Method:=DelphiDevShellTasks.RADTools;
                LMethodInfo.Value1:=DelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Script').AsString, LCurrentDelphiVersionData, FFileName);
                LMethodInfo.Value2:=False;
                if (not LClientDataSet.FieldByName('RunAs').IsNull) then
                 LMethodInfo.Value2:=LClientDataSet.FieldByName('RunAs').AsBoolean;

                FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                Inc(uIDNewItem);
                Inc(LSubMenuIndex);
               end;
             end;
             LClientDataSet.Next;
            end;

            AddMenuSeparatorEx(LSubMenu, LSubMenuIndex);
           end;

       finally
         LClientDataSet.Free;
       end;
  except
    on  E : Exception do
    log(Format('TDelphiDevShellToolsContextMenu.AddFPCToolsTasks Message %s Trace %s',[E.Message, e.StackTrace]));
  end;
end;



function TDelphiDevShellToolsContextMenu.QueryContextMenu(Menu: HMENU;
  indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult;
var
  LMenuItem: TMenuItemInfo;
  sValue, sSubMenuCaption, LMenuCaption : String;
  hSubMenu : HMENU;
  uIDNewItem: UINT;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LCurrentDelphiVersion      : TDelphiVersions;
  hSubMenuIndex  : Integer;
  Found : Boolean;
  LMethodInfo : TMethodInfo;
  LMenuInfo    : TMenuInfo;
begin
 try
  ReadSettings(Settings);

  if (uFlags and CMF_DEFAULTONLY)<> 0 then
    Exit(MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, 0))
  else
    LMenuCaption := 'Delphi Dev Shell Tools';

  if FMethodsDict=nil then
    FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues]);


  if (not MatchText(FFileExt,[
     '.pas','.dpr','.inc','.pp','.proj','.dproj', '.bdsproj','.dpk','.groupproj','.rc','.dfm',
     '.lfm','.fmx','.vsf','.style','.lpi','.lpr','.lpk','.h','.ppu']))
     and (not MatchText(FFileExt, ExternalToolsExts))
     and (not MatchText(FFileExt, FPCToolsExts))
     and (not MatchText(FFileExt, DelphiToolsExts))
     and (not MatchText(FFileExt, SplitString(Settings.CommonTaskExt,',')))
     and (not MatchText(FFileExt, SplitString(Settings.OpenDelphiExt,',')))
     and (not MatchText(FFileExt, SplitString(Settings.OpenLazarusExt,',')))
     and (not MatchText(FFileExt, SplitString(Settings.CheckSumExt,',')))

  then
   Exit(MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, 0));

   if  MatchText(FFileExt ,['.dproj', '.bdsproj','.dpr']) then
   begin
     if SameText(FFileExt, '.dpr') then
     begin
      sValue:=ChangeFileExt(FFileName,'.dproj');
      if TFile.Exists(sValue) then
         DProjectVersion:=GetDelphiVersions(sValue);
     end
     else
     DProjectVersion:=GetDelphiVersions(FFileName)
   end
   else
   if MatchText(FFileExt ,['.groupproj']) then
   begin
     if (FMSBuildGroupDProj<>nil) and (FMSBuildGroupDProj.ValidData) and (FMSBuildGroupDProj.Projects.Count>0) and (FMSBuildGroupDProj.Projects[0].ValidData) then
       DProjectVersion:=GetDelphiVersions(FMSBuildGroupDProj.Projects[0].ProjectFile)
     else
       SetLength(DProjectVersion, 0);
   end
   else
     SetLength(DProjectVersion, 0);

    hSubMenu   := CreatePopupMenu;
    uIDNewItem := idCmdFirst;
    hSubMenuIndex := 0;

     if Settings.ShowInfoDProj and  MatchText(FFileExt,['.dproj','.dpr']) and (FMSBuildDProj<>nil) and (FMSBuildDProj.ValidData) then
     begin
       ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
       LMenuItem.cbSize := SizeOf(TMenuItemInfo);
       LMenuItem.fMask := MIIM_TYPE or MIIM_ID;
       LMenuItem.fType := MFT_OWNERDRAW;
       LMenuItem.wID := uIDNewItem;
       FOwnerDrawId  := uIDNewItem;
       log('MFT_OWNERDRAW '+IntToStr(uIDNewItem));
       if not InsertMenuItem(hSubMenu, hSubMenuIndex, True, LMenuItem) then
        log(SysErrorMessage(GetLastError));
       Inc(uIDNewItem);
       Inc(hSubMenuIndex);
       AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
     end;


    //AddCommonTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj','.bdsproj','.dpk','.groupproj','.rc','.lfm','.dfm','.fmx','.lpi','.lpr','.lpk']);
    AddCommonTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.CommonTaskExt,','));
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    AddCheckSumTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.CheckSumExt,','));
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    AddExternalToolsTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ExternalToolsExts);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    AddOpenRADCmdTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj','.bdsproj','.dpk','.groupproj','.rc','.dfm','.fmx','.vsf','.style']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    //AddFormatCodeRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp']);
    //AddFormatCodeRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.FormatPascalExt,','));
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);
    //AddCompileRCTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.rc']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);
    AddOpenVclStyleTask(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.vsf']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    //AddOpenFmxStyleTask(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.style']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);


     if  MatchText(ExtractFileExt(FFileName),['.dproj','.dpr']) then
     begin

       if Length(DProjectVersion)>0 then
       begin
         LCurrentDelphiVersion:=DProjectVersion[0];

         Found:=False;
         for LCurrentDelphiVersion in DProjectVersion do
           for LCurrentDelphiVersionData in InstalledDelphiVersions do
            if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
            begin
             Found:=True;
             Break;
            end;

         if not Found then
         begin
             sSubMenuCaption:='Project Type '+DelphiVersionsNames[LCurrentDelphiVersion]+' Detected but not installed';
             InsertMenuDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption),'delphig');
             if not IsVistaOrLater then
               RegisterMenuItemBitmapExternal(hSubMenu, hSubMenuIndex, uIDNewItem, 'delphig_ico');
             Inc(uIDNewItem);
             Inc(hSubMenuIndex);
         end;
       end;
     end;

    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    AddMSBuildRAD_SpecificTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    //AddAuditsCLITasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);


    AddMSBuildRAD_AllTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.groupproj','.dpr','.proj']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    AddMSBuildPAClientTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    //AddOpenWithDelphi(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj', '.groupproj','.dpr','.pas','.inc','.pp','.dpk']);
    AddOpenWithDelphi(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.OpenDelphiExt,','));
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    AddOpenWithDelphi_GroupProject(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.groupproj']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    AddRADStudioToolsTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, DelphiToolsExts);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    if Settings.ActivateLazarus and LazarusInstalled then
    begin
      //AddLazarusTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.lpi','.pp','.inc','.pas','.lpk']);
      AddLazarusTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.OpenLazarusExt,','));
      AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

      AddFPCToolsTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, FPCToolsExts);
      AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    end;

    //AddTouchRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj', '.bdsproj','.dpk','.groupproj']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);


    InsertMenuDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, PWideChar('Settings'), 'settings');
    if not IsVistaOrLater then
    RegisterMenuItemBitmapDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, 'settings_ico');
    LMethodInfo:=TMethodInfo.Create;
    LMethodInfo.Method:=DelphiDevShellTasks.OpenGUI;
    LMethodInfo.Value1:='-settings';
    FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
    Inc(uIDNewItem);
    Inc(hSubMenuIndex);


    //InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Check for updates'));
    InsertMenuDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, PWideChar('Check for updates'), 'updates');
    //SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['updates'].Handle, BitmapsDict.Items['updates'].Handle);
    //log('Check for updates uIDNewItem '+IntToStr(uIDNewItem));
    if not IsVistaOrLater then
    RegisterMenuItemBitmapDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, 'updates_ico');
    LMethodInfo:=TMethodInfo.Create;
    LMethodInfo.Method:=DelphiDevShellTasks.OpenGUI;
    LMethodInfo.Value1:='-update';
    FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
    Inc(uIDNewItem);
    Inc(hSubMenuIndex);


    InsertMenuDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, PWideChar('About'), 'logo');
    if not IsVistaOrLater then
    RegisterMenuItemBitmapDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, 'logo_ico');
    LMethodInfo:=TMethodInfo.Create;
    LMethodInfo.Method:=DelphiDevShellTasks.OpenGUI;
    LMethodInfo.Value1:='-about';
    FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
    Inc(uIDNewItem);
    Inc(hSubMenuIndex);

    ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
    LMenuItem.cbSize := SizeOf(TMenuItemInfo);
    LMenuItem.fMask  := MIIM_FTYPE or MIIM_ID or MIIM_SUBMENU or MIIM_DATA or MIIM_BITMAP or  MIIM_STRING;
    LMenuItem.fType  := MFT_STRING;
    LMenuItem.wID    := uIDNewItem;
    log('Main Logo uIDNewItem '+IntToStr(uIDNewItem));
    LMenuItem.hSubMenu := hSubMenu;
    LMenuItem.dwTypeData := PWideChar(LMenuCaption);
    LMenuItem.cch := Length(LMenuCaption);
    //LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['logo'].Handle, HBMMENU_CALLBACK);
    LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, BitmapsDict['logo'].Handle, BitmapsDict['logo24'].Handle);
    LMenuItem.hbmpChecked   := 0;
    LMenuItem.hbmpUnchecked := 0;
    if IsVistaOrLater then
    begin
      LMenuItem.hbmpChecked   := BitmapsDict['logo'].Handle;
      LMenuItem.hbmpUnchecked := BitmapsDict['logo'].Handle;
    end;
    InsertMenuItem(Menu, indexMenu, True, LMenuItem);

    if not IsVistaOrLater then
      RegisterMenuItemBitmapDevShell(Menu, indexMenu, uIDNewItem, 'logo_ico');

    if IsVistaOrLater then
    begin
      ZeroMemory(@LMenuInfo, SizeOf(LMenuInfo));
      LMenuInfo.cbSize  := sizeof(LMenuInfo);
      LMenuInfo.fMask   := MIM_STYLE or MIM_APPLYTOSUBMENUS;
      LMenuInfo.dwStyle := MNS_CHECKORBMP;
      SetMenuInfo(Menu, LMenuInfo);
    end;

    //log('uIDNewItem-idCmdFirst '+IntToStr(uIDNewItem-idCmdFirst));
    Result := MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, uIDNewItem-idCmdFirst);
 except on  E : Exception do
    begin
     log(Format('TDelphiDevShellToolsContextMenu.QueryContextMenu Message %s  Trace %s',[E.Message, E.StackTrace]));
     Result := E_FAIL;
    end;
 end;
end;


function TDelphiDevShellToolsContextMenu.ShellExtInitialize(pidlFolder: PItemIDList;
  lpdobj: IDataObject; hKeyProgID: HKEY): HResult;
var
  formatetcIn : TFormatEtc;
  medium      : TStgMedium;
  LFileName   : Array [0 .. MAX_PATH] of Char;
  LProjName   : string;
begin
  Result := E_FAIL;
 try
    if lpdobj = nil then
      Exit;

    formatetcIn.cfFormat := CF_HDROP;
    formatetcIn.dwAspect := DVASPECT_CONTENT;
    formatetcIn.tymed := TYMED_HGLOBAL;
    formatetcIn.ptd := nil;
    formatetcIn.lindex := -1;

    if lpdobj.GetData(formatetcIn, medium) <> S_OK then
      Exit;

    if DragQueryFile(medium.hGlobal, $FFFFFFFF, nil, 0) = 1 then
    begin
      SetLength(FFileName, MAX_PATH);
      DragQueryFile(medium.hGlobal, 0, @LFileName, SizeOf(LFileName));
      FFileName := LFileName;
      FFileExt:=ExtractFileExt(FFileName);

      if FMSBuildDProj<>nil then
      begin
        FMSBuildDProj.Free;
        FMSBuildDProj:=nil;
      end;

      if FMSBuildGroupDProj<>nil then
      begin
        FMSBuildGroupDProj.Free;
        FMSBuildGroupDProj:=nil;
      end;


      LProjName:=FFileName;
      if SameText(FFileExt, '.dpr') then
      begin
       LProjName:=ChangeFileExt(FFileName,'.dproj');
       if not TFile.Exists(LFileName) then
        LProjName:=FFileName;
      end;

      if MatchText(FFileExt,['.dproj','.dpr']) and TFile.Exists(LProjName) then
        FMSBuildDProj:=TMSBuildDProj.Create(LProjName);

      if MatchText(FFileExt,['.groupproj']) and TFile.Exists(FFileName) then
        FMSBuildGroupDProj:=TMSBuildGroupProj.Create(FFileName);

      Result := NOERROR;
    end
    else
    begin

      if FMSBuildDProj<>nil then
      begin
        FMSBuildDProj.Free;
        FMSBuildDProj:=nil;
      end;

      if FMSBuildGroupDProj<>nil then
      begin
        FMSBuildGroupDProj.Free;
        FMSBuildGroupDProj:=nil;
      end;

      FFileName := EmptyStr;
      FFileExt  := EmptyStr;
      Result := E_FAIL;
    end;
    ReleaseStgMedium(medium);
 except on  E : Exception do
    begin
     log(Format('TDelphiDevShellToolsContextMenu.ShellExtInitialize Message %s  Trace %s',[E.Message, e.StackTrace]));
     Result := E_FAIL;
    end;
 end;
end;

{ TDelphiDevShellObjectFactory }
function TDelphiDevShellObjectFactory.GetProgID: string;
begin
  Exit(EmptyStr);
end;

procedure TDelphiDevShellObjectFactory.UpdateRegistry(Register: Boolean);
var
  LRegistry: TRegistry;
begin
  inherited UpdateRegistry(Register);
  LRegistry := TRegistry.Create;
  try
    LRegistry.RootKey := HKEY_LOCAL_MACHINE;
    if not LRegistry.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved', True) then
      Exit;

    if &Register then
      LRegistry.WriteString(GUIDToString(ClassID), Description)
    else
      LRegistry.DeleteValue(GUIDToString(ClassID));
  finally
    LRegistry.Free;
  end;

  if Register then
    CreateRegKey(Format('*\shellex\ContextMenuHandlers\%s', [ClassName]), '', GUIDToString(ClassID), HKEY_CLASSES_ROOT)
  else
    DeleteRegKey(Format('*\shellex\ContextMenuHandlers\%s', [ClassName]));

end;

    procedure RegisterBitmap(const ResourceName: string;const DictName:string='');
    var
      Factor : Double;
      CX     : Integer;
      TempBitmap : TBitmap;
      LDictName : string;
      LPng : TPngImage;
    begin
     try
        LDictName:=ResourceName;
        if DictName<>'' then
          LDictName:=DictName;

        CX:=GetSystemMetrics(SM_CXMENUCHECK);
        if CX>=16 then
        begin
          BitmapsDict.Add(LDictName,TBitmap.Create);
          LPng:=TPngImage.Create;
          try
            LPng.LoadFromResourceName(HInstance, ResourceName);
            BitmapsDict.Items[LDictName].Assign(LPng);
          finally
            LPng.Free;
          end;
        end
        else
        begin
          Factor:= CX/16;
          TempBitmap:=TBitmap.Create;
          try
            BitmapsDict.Add(LDictName,TBitmap.Create);
            LPng:=TPngImage.Create;
            try
              LPng.LoadFromResourceName(HInstance, ResourceName);
              TempBitmap.Assign(LPng);
            finally
              LPng.Free;
            end;

            ScaleImage32(TempBitmap, BitmapsDict.Items[LDictName], Factor);
          finally
            TempBitmap.Free;
          end;
        end;
     except
       on  E : Exception do
         log(Format('RegisterBitmap Message %s  Trace %s',[E.Message, e.StackTrace]));
     end;

    end;

    procedure RegisterBitmap32(const ResourceName: string);
    var
      TempBitmap : TBitmap;
      CX     : Integer;
      LPicture : TPicture;
      s : string;
      Factor : Double;
    begin
     try
        CX:=GetSystemMetrics(SM_CXMENUCHECK);
        s:=GetDevShellToolsImagesFolder+ResourceName;
        if IsVistaOrLater then
        begin
            if (not BitmapsDict.ContainsKey(ResourceName)) and FileExists(s) then
            begin
              LPicture := TPicture.Create;
              try
                 LPicture.LoadFromFile(s);

                 if CX>=16 then
                 begin
                  BitmapsDict.Add(ResourceName, TBitmap.Create);
                  BitmapsDict.Items[ResourceName].Assign(LPicture.Graphic);
                 end
                 else
                 begin
                    Factor:= CX/16;
                    TempBitmap:=TBitmap.Create;
                    try
                      BitmapsDict.Add(ResourceName,TBitmap.Create);
                      BitmapsDict.Items[ResourceName].PixelFormat:=pf32bit;
                      TempBitmap.Assign(LPicture.Graphic);
                      ScaleImage32(TempBitmap, BitmapsDict.Items[ResourceName], Factor);
                    finally
                      TempBitmap.Free;
                    end;
                 end;
              finally
                LPicture.Free;
              end;
            end;
        end
        else
        if (not IconsExternals.ContainsKey(ResourceName)) and FileExists(s) then
        begin
            IconsExternals.Add(ResourceName, TIcon.Create);
            IconsExternals.Items[ResourceName].LoadFromFile(s);
        end;
     except
       on  E : Exception do
       log(Format('RegisterBitmap32 Message %s  Trace %s',[E.Message, e.StackTrace]));
     end;
    end;

var
 CX     : Integer;
 Factor : Double;
 LCurrentDelphiVersionData  : TDelphiVersionData;
 TempBitmap : TBitmap;
initialization
//  TStyleManager.LoadFromFile('C:\Delphi\google-code\dev-shell-tools\Styles\Amakrits.vsf');
//  TStyleManager.SetStyle('Amakrits');
  CX:=GetSystemMetrics(SM_CXMENUCHECK);
  log('initialization');
  TDelphiDevShellObjectFactory.Create(ComServer, TDelphiDevShellToolsContextMenu, CLASS_DelphiDevShellToolsContextMenu, ciMultiInstance, tmApartment);
  Settings:=TSettings.Create;
  InstalledDelphiVersions:=TObjectList<TDelphiVersionData>.Create;
  FillListDelphiVersions(InstalledDelphiVersions);
  PAClientProfiles:=TPAClientProfileList.Create(InstalledDelphiVersions);

  BitmapsDict        :=TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
  IconsExternals     :=TObjectDictionary<string, TIcon>.Create([doOwnsValues]);
  IconsDictExternal  :=TDictionary<Integer, TIcon>.Create;
  IconsDictResources := TDictionary<Integer, string>.Create;

  RegisterBitmap('logo');
  RegisterBitmap('notepad');
  RegisterBitmap('cmd');
  RegisterBitmap('copy');
  RegisterBitmap('osx');
  RegisterBitmap('ios');
  RegisterBitmap('win');
  RegisterBitmap('android');
  {
  RegisterBitmap('osx', 'osx2');
  RegisterBitmap('ios', 'ios2');
  RegisterBitmap('win', 'win2');
  }
  RegisterBitmap('delphi');
  RegisterBitmap('delphi', 'delphi2');
  RegisterBitmap('delphig');
  RegisterBitmap('radcmd');
  RegisterBitmap('msbuild');
  RegisterBitmap('firemonkey');
  RegisterBitmap('firemonkey', 'firemonkey2');
  RegisterBitmap('vcl', 'vcl2');
  RegisterBitmap('lazarusmenu');
  RegisterBitmap('lazbuild');
  RegisterBitmap('buildconf');
  RegisterBitmap('platforms');
  RegisterBitmap('buildconf', 'buildconf2');
  RegisterBitmap('platforms', 'platforms2');
  RegisterBitmap('settings');
  RegisterBitmap('common');
  RegisterBitmap('updates');
  RegisterBitmap('checksum');
  RegisterBitmap('copy_unc');
  RegisterBitmap('copy_url');
  RegisterBitmap('copy_content');
  RegisterBitmap('copy_path');
  RegisterBitmap('shield');
  RegisterBitmap('fpc_tools');
  RegisterBitmap('wrench');

   if CX>=16 then
   begin
     BitmapsDict.Add('logo24',TBitmap.Create);
     BitmapsDict.Items['logo24'].LoadFromResourceName(HInstance,'logo24');
   end
   else
   begin
      Factor:= CX/16;
      TempBitmap:=TBitmap.Create;
      try
        BitmapsDict.Add('logo24',TBitmap.Create);
        TempBitmap.LoadFromResourceName(HInstance,'logo24');
        ScaleImage(TempBitmap, BitmapsDict.Items['logo24'], Factor);
      finally
        TempBitmap.Free;
      end;
   end;
  MakeBitmapMenuTransparent(BitmapsDict.Items['logo24']);

  for LCurrentDelphiVersionData in InstalledDelphiVersions do
     if not BitmapsDict.ContainsKey(LCurrentDelphiVersionData.Name) then
     begin
       BitmapsDict.Add(LCurrentDelphiVersionData.Name, TBitmap.Create);
       BitmapsDict.Items[LCurrentDelphiVersionData.Name].Assign(LCurrentDelphiVersionData.Bitmap);
     end;

   try
     BitmapsDict.Add('txt',TBitmap.Create);
     GetAssocAppByExt('foo.txt', ExeNameTxt, FriendlyAppNameTxt);
     if (ExeNameTxt<>'') and TFile.Exists(ExeNameTxt)  then
     begin
       if IsVistaOrLater then
       begin
         if CX<16 then
         begin
           BitmapsDict.Add('txt2',TBitmap.Create);
           ExtractBitmapFile32(BitmapsDict.Items['txt2'], ExeNameTxt, SHGFI_SMALLICON);
           Factor:= CX/16;
           ScaleImage32( BitmapsDict.Items['txt2'], BitmapsDict.Items['txt'], Factor);
         end
         else
           ExtractBitmapFile32(BitmapsDict.Items['txt'], GetLazarusIDEFileName, SHGFI_SMALLICON);
       end
       else
       begin
         IconsExternals.Add('txt', TIcon.Create);
         ExtractIconFile( IconsExternals['txt'] , ExeNameTxt, SHGFI_SMALLICON);
       end;
     end;
   except
     on  E : Exception do
     log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
   end;

   try
     DelphiToolsExts:=GetGroupToolsExtensions('Delphi Tools');
   except
     on  E : Exception do
     log(Format('GetGroupToolsExtensions Message %s  Trace %s',[E.Message, e.StackTrace]));
   end;

   try
     ExternalToolsExts:=GetGroupToolsExtensions('External Tools');
   except
     on  E : Exception do
     log(Format('GetGroupToolsExtensions Message %s  Trace %s',[E.Message, e.StackTrace]));
   end;

   LazarusInstalled:=IsLazarusInstalled and TFile.Exists(GetLazarusIDEFileName);

   if LazarusInstalled then
   begin
     try
       FPCToolsExts:=GetGroupToolsExtensions('FPC Tools');
       BitmapsDict.Add('lazarus',TBitmap.Create);
       if IsVistaOrLater then
       begin
         if CX<16 then
         begin
           BitmapsDict.Add('lazarus2',TBitmap.Create);
           ExtractBitmapFile32(BitmapsDict.Items['lazarus2'], GetLazarusIDEFileName, SHGFI_SMALLICON);
           Factor:= CX/16;
           ScaleImage32( BitmapsDict.Items['lazarus2'], BitmapsDict.Items['lazarus'], Factor);
         end
         else
           ExtractBitmapFile32(BitmapsDict.Items['lazarus'], GetLazarusIDEFileName, SHGFI_SMALLICON);
       end
       else
       begin
         IconsExternals.Add('lazarus', TIcon.Create);
         ExtractIconFile(IconsExternals['lazarus'], GetLazarusIDEFileName, SHGFI_SMALLICON);
       end;
     except
       on  E : Exception do
       log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
     end;
   end;

   ReadSettings(Settings);
   if Settings.CheckForUpdates then
     CheckUpdates;

finalization
  Settings.Free;
  BitmapsDict.Free;
  InstalledDelphiVersions.Free;
  PAClientProfiles.Free;
  IconsDictResources.Free;
  IconsDictExternal.Free;
  log('finalization');
end.

