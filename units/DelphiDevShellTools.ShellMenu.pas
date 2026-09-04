//**************************************************************************************************
//
// Unit DelphiDevShellTools.ShellMenu
// Shell menu state, resources, composition and command dispatch
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
// The Original Code is DelphiDevShellTools.ShellMenu.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.ShellMenu;

interface

uses
  Winapi.Windows,
  Winapi.ActiveX,
  Winapi.ShlObj,
  System.Types,
  System.Generics.Collections,
  Vcl.Graphics,
  DelphiDevShellTools.Misc,
  DelphiDevShellTools.ProjectInfoPanel,
  DelphiDevShellTools.DelphiVersions;

type
  TShellMenu = class
  private
    FFileName, FFileExt: string;
    FInfoPanel: TProjectInfoPanel;
    FInfoPanelId: UINT;
    FDProjectVersion: SetDelphiVersions;
    FMSBuildDProj: TMSBuildDProj;
    FMSBuildGroupDProj: TMSBuildGroupProj;
    FMethodsDict: TObjectDictionary<Integer, TMethodInfo>;

    FInstalledDelphiVersions: TInstalledDelphiVerions;
    FPAClientProfiles: TPAClientProfileList;
    FBitmapsDict: TObjectDictionary<string, TBitmap>;
    FMenuDpi, FMenuImageSize: Integer;
    FImageCacheKey: string;
    FIconsExternals: TObjectDictionary<string, TIcon>;//TIcon is a instance
    FIconsDictExternal: TDictionary<Integer, TIcon>;//TIcon is only a reference
    FIconsDictResources: TDictionary<Integer, string>;

    FExeNameTxt, FFriendlyAppNameTxt: string;
    FLazarusInstalled: Boolean;
    FSettings: TSettings;
    FDelphiToolsExts, FExternalToolsExts, FPCToolsExts: TStringDynArray;

    procedure InitResources;
    procedure FreeResources;
    procedure RegisterBitmap(const ResourceName: string;const DictName:string='');
    function  IsSeparator(MenuType: UINT): Boolean;
    function MenuMessageHandler(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult;
  public
    function  InsertMenuDevShell(hMenu: HMENU; uPosition: UINT; uIDNewItem: UINT_PTR; lpNewItem, IconName: LPCWSTR): BOOL;
    procedure RegisterMenuItemBitmapDevShell(hMenu: HMENU; uPosition, wID: UINT; const IconName: String);
    procedure RegisterMenuItemBitmapExternal(hMenu: HMENU; uPosition, wID: UINT; const IconName: String);
    procedure AddMenuSeparatorEx(hMenu: HMENU; var MenuIndex: Integer);

    procedure RegisterBitmap32(const ResourceName: string);

    function ShellExtInitialize(pidlFolder: PItemIDList; lpdobj: IDataObject; hKeyProgID: HKEY): HResult;
    function QueryContextMenu(Menu: HMENU; indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult;
    function InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult;
    function GetCommandString(idCmd: UINT_PTR; uFlags: UINT; pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult;
    //IContextMenu2
    function HandleMenuMsg(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HResult;
    //IContextMenu3
    function HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult;
    constructor Create;
    destructor Destroy; override;
    property FileName: string read FFileName;
    property FileExt: string read FFileExt;
    property DProjectVersion: SetDelphiVersions read FDProjectVersion;
    property MSBuildDProj: TMSBuildDProj read FMSBuildDProj;
    property MethodsDict: TObjectDictionary<Integer, TMethodInfo> read FMethodsDict;
    property InstalledDelphiVersions: TInstalledDelphiVerions read FInstalledDelphiVersions;
    property PAClientProfiles: TPAClientProfileList read FPAClientProfiles;
    property BitmapsDict: TObjectDictionary<string, TBitmap> read FBitmapsDict;
    property IconsDictExternal: TDictionary<Integer, TIcon> read FIconsDictExternal;
    property ExeNameTxt: string read FExeNameTxt;
    property FriendlyAppNameTxt: string read FFriendlyAppNameTxt;
    property Settings: TSettings read FSettings;
  end;

implementation

uses
  DelphiDevShellTools.Logging,
  Winapi.ShellAPI,
  Winapi.Messages,
  System.SysUtils,
  System.IOUtils,
  System.StrUtils,
  System.Math,
  System.Win.ComObj,
  Vcl.GraphUtil,
  Vcl.Imaging.PngImage,
  DelphiDevShellTools.UI,
  DelphiDevShellTools.Tasks,
  DelphiDevShellTools.LazarusVersions,
  DelphiDevShellTools.ToolMenus,
  DelphiDevShellTools.IDEMenus;


constructor TShellMenu.Create;
begin
  FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues]);
  log('TShellMenu.Create');
  inherited;
end;

destructor TShellMenu.Destroy;
begin
  log('TShellMenu.Destroy');
  FreeResources;
  if FMethodsDict<>nil then
    FMethodsDict.Free;
  inherited;
end;

procedure TShellMenu.FreeResources;
begin
  log('FreeResources init');
  FreeAndNil(FInfoPanel);
  FreeAndNil(FSettings);
  FreeAndNil(FBitmapsDict);
  FreeAndNil(FInstalledDelphiVersions);
  FreeAndNil(FPAClientProfiles);
  FreeAndNil(FIconsDictResources);
  FreeAndNil(FIconsDictExternal);
  FreeAndNil(FIconsExternals);
  log('FreeResources done');
end;

function TShellMenu.GetCommandString(idCmd: UINT_PTR; uFlags: UINT;
  pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult;
begin
  Result := E_INVALIDARG;
end;

procedure TShellMenu.RegisterBitmap(const ResourceName: string;const DictName:string='');
var
  LDictName: string;
  SourceBitmap: TBitmap;
  LPng: TPngImage;
begin
  try
    LDictName := ResourceName;
    if DictName <> '' then LDictName := DictName;
    SourceBitmap := TBitmap.Create;
    LPng := TPngImage.Create;
    try
      LPng.LoadFromResourceName(HInstance, ResourceName);
      SourceBitmap.Assign(LPng);
      FBitmapsDict.Add(LDictName, TBitmap.Create);
      if (SourceBitmap.Width = FMenuImageSize) and (SourceBitmap.Height = FMenuImageSize) then
        FBitmapsDict.Items[LDictName].Assign(SourceBitmap)
      else
        ScaleImage32(SourceBitmap, FBitmapsDict.Items[LDictName],
          FMenuImageSize / SourceBitmap.Width);
    finally
      LPng.Free;
      SourceBitmap.Free;
    end;
  except
    on E: Exception do
      log(Format('RegisterBitmap Message %s Trace %s', [E.Message, E.StackTrace]));
  end;
end;

procedure TShellMenu.RegisterBitmap32(const ResourceName: string);
var
  BulletColor: TColor;
  BulletHandle: HICON;
  LPicture: TPicture;
  SourceBitmap: TBitmap;
  FileName: string;
begin
  try
    if TryGetBulletColor(ResourceName, BulletColor) then
    begin
      if IsVistaOrLater then
      begin
        if not FBitmapsDict.ContainsKey(ResourceName) then
        begin
          FBitmapsDict.Add(ResourceName, TBitmap.Create);
          CreateBulletBitmap(FBitmapsDict.Items[ResourceName], BulletColor,
            FMenuImageSize);
        end;
      end
      else if not FIconsExternals.ContainsKey(ResourceName) then
      begin
        BulletHandle := CreateBulletIcon(BulletColor, FMenuImageSize);
        if BulletHandle <> 0 then
        begin
          FIconsExternals.Add(ResourceName, TIcon.Create);
          FIconsExternals.Items[ResourceName].Handle := BulletHandle;
        end;
      end;
      Exit;
    end;
    FileName := GetDevShellToolsImagesFolder + ResourceName;
    if IsVistaOrLater then
    begin
      if (not FBitmapsDict.ContainsKey(ResourceName)) and FileExists(FileName) then
      begin
        LPicture := TPicture.Create;
        SourceBitmap := TBitmap.Create;
        try
          LPicture.LoadFromFile(FileName);
          SourceBitmap.Assign(LPicture.Graphic);
          FBitmapsDict.Add(ResourceName, TBitmap.Create);
          if (SourceBitmap.Width = FMenuImageSize) and (SourceBitmap.Height = FMenuImageSize) then
            FBitmapsDict.Items[ResourceName].Assign(SourceBitmap)
          else
            ScaleImage32(SourceBitmap, FBitmapsDict.Items[ResourceName],
              FMenuImageSize / SourceBitmap.Width);
        finally
          SourceBitmap.Free;
          LPicture.Free;
        end;
      end;
    end
    else if (not FIconsExternals.ContainsKey(ResourceName)) and FileExists(FileName) then
    begin
      FIconsExternals.Add(ResourceName, TIcon.Create);
      FIconsExternals.Items[ResourceName].LoadFromFile(FileName);
    end;
  except
    on E: Exception do
      log(Format('RegisterBitmap32 Message %s Trace %s', [E.Message, E.StackTrace]));
  end;
end;

procedure TShellMenu.InitResources;
var
  LCurrentDelphiVersionData: TDelphiVersionData;
  SourceBitmap: TBitmap;
  NewDpi: Integer;
  NewCacheKey: string;
  EditorIconFile: string;
begin
  try
    NewDpi := MenuDpi;
    NewCacheKey := ImageCacheKey('shell-menu', MenuImageLogicalSize, NewDpi);
    if (FBitmapsDict <> nil) and SameText(FImageCacheKey, NewCacheKey) then Exit;
    if FBitmapsDict <> nil then FreeResources;
    FMenuDpi := NewDpi;
    FMenuImageSize := ImagePixelsForDpi(MenuImageLogicalSize, FMenuDpi);
    FImageCacheKey := NewCacheKey;
    FSettings:=TSettings.Create;
    FInstalledDelphiVersions:=GetListInstalledDelphiVersions(FMenuImageSize);
    FPAClientProfiles:=TPAClientProfileList.Create(FInstalledDelphiVersions);
    FBitmapsDict        :=TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
    FIconsExternals     :=TObjectDictionary<string, TIcon>.Create([doOwnsValues]);
    FIconsDictExternal  :=TDictionary<Integer, TIcon>.Create;
    FIconsDictResources := TDictionary<Integer, string>.Create;
    ReadSettings(FSettings);
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
    RegisterBitmap('vcl');
    RegisterBitmap('vcl', 'vcl2');
    RegisterBitmap('lazarusmenu');
    RegisterBitmap('lazbuild');
    RegisterBitmap('buildconf');
    RegisterBitmap('platforms');
    RegisterBitmap('buildconf', 'buildconf2');
    RegisterBitmap('platforms', 'platforms2');
    RegisterBitmap('settings');
    RegisterBitmap('common');
    RegisterBitmap('checksum');
    RegisterBitmap('copy_unc');
    RegisterBitmap('copy_url');
    RegisterBitmap('copy_content');
    RegisterBitmap('copy_path');
    RegisterBitmap('shield');
    RegisterBitmap('fpc_tools');
    RegisterBitmap('wrench');

    SourceBitmap := TBitmap.Create;
    try
      SourceBitmap.LoadFromResourceName(HInstance, 'logo24');
      FBitmapsDict.Add('logo24', TBitmap.Create);
      if (SourceBitmap.Width = FMenuImageSize) and (SourceBitmap.Height = FMenuImageSize) then
        FBitmapsDict.Items['logo24'].Assign(SourceBitmap)
      else
        ScaleImage32(SourceBitmap, FBitmapsDict.Items['logo24'],
          FMenuImageSize / SourceBitmap.Width);
    finally
      SourceBitmap.Free;
    end;
    MakeBitmapMenuTransparent(FBitmapsDict.Items['logo24']);

    for LCurrentDelphiVersionData in FInstalledDelphiVersions.Values do
       if not FBitmapsDict.ContainsKey(LCurrentDelphiVersionData.Name) then
       begin
         FBitmapsDict.Add(LCurrentDelphiVersionData.Name, TBitmap.Create);
         FBitmapsDict.Items[LCurrentDelphiVersionData.Name].Assign(LCurrentDelphiVersionData.Bitmap);
       end;

     try
       FBitmapsDict.Add('txt', TBitmap.Create);
       GetAssocAppByExt('foo.txt', FExeNameTxt, FFriendlyAppNameTxt);
       EditorIconFile := ResolveAssociatedEditorIcon(FExeNameTxt);
       if EditorIconFile <> '' then
       begin
         if IsVistaOrLater then
           ExtractBitmapFile32(FBitmapsDict.Items['txt'], EditorIconFile,
             SHGFI_SMALLICON, FMenuImageSize)
         else
         begin
           FIconsExternals.Add('txt', TIcon.Create);
           ExtractIconFile(FIconsExternals['txt'], EditorIconFile, SHGFI_SMALLICON);
         end;
       end;
     except
       on  E: Exception do
       log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
     end;

     try
       FDelphiToolsExts:=GetGroupToolsExtensions('Delphi Tools');
     except
       on  E: Exception do
       log(Format('GetGroupToolsExtensions Message %s  Trace %s',[E.Message, e.StackTrace]));
     end;

     try
       FExternalToolsExts:=GetGroupToolsExtensions('External Tools');
     except
       on  E: Exception do
       log(Format('GetGroupToolsExtensions Message %s  Trace %s',[E.Message, e.StackTrace]));
     end;

     FLazarusInstalled:=IsLazarusInstalled and TFile.Exists(GetLazarusIDEFileName);

     if FLazarusInstalled then
     begin
       try
         FPCToolsExts:=GetGroupToolsExtensions('FPC Tools');
         FBitmapsDict.Add('lazarus', TBitmap.Create);
         if IsVistaOrLater then
           ExtractBitmapFile32(FBitmapsDict.Items['lazarus'], GetLazarusIDEFileName,
             SHGFI_SMALLICON, FMenuImageSize)
         else
         begin
           FIconsExternals.Add('lazarus', TIcon.Create);
           ExtractIconFile(FIconsExternals['lazarus'], GetLazarusIDEFileName, SHGFI_SMALLICON);
         end;
       except
         on  E: Exception do
         log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
       end;
     end;

     ReadSettings(FSettings);
  except
   on  E: Exception do
     log(Format('TShellMenu.InitResources Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

function TShellMenu.InsertMenuDevShell(hMenu: HMENU; uPosition: UINT; uIDNewItem: UINT_PTR; lpNewItem, IconName: LPCWSTR): BOOL;
var
  LMenuItem: TMenuItemInfo;
begin
  //log('TShellMenu.InsertMenuDevShell '+lpNewItem);
  try
    ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
    LMenuItem.cbSize := SizeOf(TMenuItemInfo);
    LMenuItem.fMask  := MIIM_FTYPE or MIIM_ID or MIIM_BITMAP or MIIM_STRING;
    LMenuItem.fType  := MFT_STRING;
    LMenuItem.wID    := uIDNewItem;
    LMenuItem.dwTypeData := lpNewItem;
    if (IconName<>nil) and (IsVistaOrLater and FBitmapsDict.ContainsKey(IconName)) then
      LMenuItem.hbmpItem   := FBitmapsDict[IconName].Handle
    else
    if (IconName<>nil) and not IsVistaOrLater then
      LMenuItem.hbmpItem   :=HBMMENU_CALLBACK;

     //LMenuItem.hbmpItem   := IfThen(IsVistaOrLater, BitmapsDict[IconName].Handle ,HBMMENU_CALLBACK);
    //log('InsertMenuEx HBMMENU_CALLBACK '+IntToStr(uIDNewItem));
    Result:=InsertMenuItem(hMenu, uPosition, True, LMenuItem);

    if not Result then
     log('TShellMenu.InsertMenuDevShell SysErrorMessage ' + SysErrorMessage(GetLastError));
  except
   on  E: Exception do
   begin
     Result:=False;
     log(Format('TShellMenu.InsertMenuDevShell Message %s  Trace %s',[E.Message, e.StackTrace]));
   end;
  end;
end;

procedure TShellMenu.RegisterMenuItemBitmapDevShell(hMenu: HMENU;
  uPosition, wID: UINT; const IconName: String);
//var
//  LMenuInfo: TMenuItemInfo;
//  Buffer: array [0..79] of char;
begin
  if IsVistaOrLater then exit;
  //log('RegisterMenuItemBitmapDevShell '+IconName+' init');
  try
    if not FIconsDictResources.ContainsKey(wID) then
    begin
     FIconsDictResources.Add(wID, IconName);
     log('RegisterMenuItemBitmapDevShell '+IconName+' ok wID '+IntToStr(wID));
    end;
  except
   on  E: Exception do
   log(Format('TShellMenu.RegisterMenuItemBitmapDevShell Message %s  Trace %s',[E.Message, e.StackTrace]));
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

procedure  TShellMenu.RegisterMenuItemBitmapExternal(hMenu: HMENU; uPosition, wID: UINT; const IconName: String);
{
var
  LMenuInfo: TMenuItemInfo;
  Buffer: array [0..79] of char;
}
begin
  if IsVistaOrLater then exit;

  try
    if not FIconsDictExternal.ContainsKey(wID) then
     FIconsDictExternal.Add(wID, FIconsExternals[IconName]);
  except
   on  E: Exception do
   log(Format('TShellMenu.RegisterMenuItemBitmapDevShell Message %s  Trace %s',[E.Message, e.StackTrace]));
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
   on  E: Exception do
   log(Format('TShellMenu.RegisterMenuItemBitmapExternal Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
}
end;

procedure TShellMenu.AddMenuSeparatorEx(hMenu: HMENU; var MenuIndex: Integer);
var
  LMenuInfo: TMenuItemInfo;
  Buffer: array [0..79] of char;
begin
  try
    LMenuInfo.cbSize := sizeof(LMenuInfo);
    LMenuInfo.fMask  := MIIM_TYPE;
    LMenuInfo.dwTypeData := Buffer;
    LMenuInfo.cch := SizeOf(Buffer);
    if GetMenuItemInfo(hMenu, MenuIndex-1, True, LMenuInfo) then
    begin
      //log('GetMenuItemInfo ok '+IntToStr(LMenuInfo.fType));

      if not IsSeparator(LMenuInfo.fType)  then
      begin
        //log('adding separator');
        InsertMenu(hMenu, MenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
        inc(MenuIndex);
      end;
    end
    else
      log('TShellMenu.AddMenuSeparatorEx SysErrorMessage ' + SysErrorMessage(GetLastError));
  except
   on  E: Exception do
   log(Format('TShellMenu.AddMenuSeparatorEx Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

function TShellMenu.InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult;
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
    //log('InvokeCommand lpVerb '+IntToStr(Integer(lpici.lpVerb)));
    if HiWord(Integer(lpici.lpVerb)) <> 0 then
      Exit;

    LVerb := LoWord(Integer(lpici.lpVerb));
    //log('InvokeCommand '+IntToStr(LVerb));
    if FMethodsDict.ContainsKey(LVerb) then
    begin
      //log('InvokeCommand Exec');
      FMethodsDict.Items[LVerb].hwnd:=lpici.hwnd;
      FMethodsDict.Items[LVerb].Method(FMethodsDict.Items[LVerb]);
      Result:=NOERROR;
    end;
  except on  E: Exception do
    begin
     log(Format('TShellMenu.InvokeCommand Message %s  Trace %s',[E.Message, e.StackTrace]));
     Result := E_FAIL;
    end;
  end;
end;

function TShellMenu.IsSeparator(MenuType: UINT): Boolean;
begin
 Result := (MenuType and MFT_SEPARATOR) = MFT_SEPARATOR;
end;

function TShellMenu.MenuMessageHandler(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult;
var
  ItemId: UINT;
  LIcon: TIcon;
  Draw: PDrawItemStruct;
  Background, Foreground: COLORREF;
begin
  lpResult := 0;
  Result := E_NOTIMPL;
  // Handle only our information panel and legacy bitmap callbacks.
  // Explorer retains ownership of all ordinary menu-item drawing.
  if lParam = 0 then Exit;
  try
    case uMsg of
      WM_MEASUREITEM:
        begin
          if PMeasureItemStruct(lParam)^.CtlType <> ODT_MENU then Exit;
          ItemId := PMeasureItemStruct(lParam)^.itemID;
        end;
      WM_DRAWITEM:
        begin
          if PDrawItemStruct(lParam)^.CtlType <> ODT_MENU then Exit;
          ItemId := PDrawItemStruct(lParam)^.itemID;
        end;
    else
      Exit;
    end;
    if (FInfoPanel <> nil) and (ItemId = FInfoPanelId) then
    begin
      if uMsg = WM_MEASUREITEM then
      begin
        PMeasureItemStruct(lParam)^.itemWidth := FInfoPanel.Width;
        PMeasureItemStruct(lParam)^.itemHeight := FInfoPanel.Height;
      end
      else
      begin
        Draw := PDrawItemStruct(lParam);
        if Draw^.hDC = 0 then Exit(E_INVALIDARG);
        MenuPanelColors(Draw^.hDC, Draw^.rcItem, Background, Foreground);
        FInfoPanel.Paint(Draw^.hDC, Draw^.rcItem, Background, Foreground);
      end;
      lpResult := 1;
      Exit(S_OK);
    end;
    if IsVistaOrLater then Exit;
    if (FIconsDictResources = nil) or (FIconsDictExternal = nil) then Exit;
    if not FIconsDictResources.ContainsKey(ItemId) and
       not FIconsDictExternal.ContainsKey(ItemId) then Exit;
    if uMsg = WM_MEASUREITEM then
    begin
      Inc(PMeasureItemStruct(lParam)^.itemWidth, 2);
      if Integer(PMeasureItemStruct(lParam)^.itemHeight) < FMenuImageSize then
        PMeasureItemStruct(lParam)^.itemHeight := FMenuImageSize;
    end
    else
    begin
      Draw := PDrawItemStruct(lParam);
      LIcon := TIcon.Create;
      try
        if FIconsDictResources.ContainsKey(ItemId) then
          LIcon.LoadFromResourceName(HInstance, FIconsDictResources[ItemId])
        else
          LIcon.Assign(FIconsDictExternal[ItemId]);
        DrawIconEx(Draw^.hDC, Draw^.rcItem.Left - FMenuImageSize,
          Draw^.rcItem.Top + (Draw^.rcItem.Bottom - Draw^.rcItem.Top - FMenuImageSize) div 2,
          LIcon.Handle, FMenuImageSize, FMenuImageSize, 0, 0, DI_NORMAL);
      finally
        LIcon.Free;
      end;
    end;
    lpResult := 1;
    Result := S_OK;
  except
    on E: Exception do
    begin
      log('MenuMessageHandler: ' + E.Message);
      Result := E_FAIL;
    end;
  end;
end;
//IContextMenu2

function TShellMenu.HandleMenuMsg(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HResult;
var
 res: Winapi.Windows.LPARAM;
begin
 //log('HandleMenuMsg');
 Result:=MenuMessageHandler ( uMsg, wParam, lParam, res);
end;

//IContextMenu3

function TShellMenu.HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult;
var
  MessageResult: LRESULT;
begin
  // The native COM contract permits a NULL plResult, despite Delphi's var
  // declaration. Always give our internal handler valid storage first.
  Result := MenuMessageHandler(uMsg, wParam, lParam, MessageResult);
  if @lpResult <> nil then
    lpResult := MessageResult;
end;

function TShellMenu.QueryContextMenu(Menu: HMENU;
  indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult;
var
  LMenuItem: TMenuItemInfo;
  sValue, sSubMenuCaption, LMenuCaption: String;
  hSubMenu: HMENU;
  uIDNewItem: UINT;
  //LCurrentDelphiVersionData: TDelphiVersionData;
  LCurrentDelphiVersion: TDelphiVersions;
  hSubMenuIndex: Integer;
  Found: Boolean;
  LMethodInfo: TMethodInfo;

begin
 try
  log(Format('QueryContextMenu file=%s index=%d first=%d last=%d flags=%.8x',
    [FFileName, indexMenu, idCmdFirst, idCmdLast, uFlags]));
  InitResources;

  ReadSettings(FSettings);
  if (uFlags and CMF_DEFAULTONLY)<> 0 then
    Exit(MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, 0))
  else
    LMenuCaption := 'Delphi Dev Shell Tools';

  if FMethodsDict=nil then
    FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues])
  else
    FMethodsDict.Clear;


  if (not MatchText(FFileExt,[
     '.pas','.dpr','.inc','.pp','.proj','.dproj', '.bdsproj','.dpk','.groupproj','.rc','.dfm',
     '.lfm','.fmx','.vsf','.style','.lpi','.lpr','.lpk','.h','.ppu']))
     and (not MatchText(FFileExt, FExternalToolsExts))
     and (not MatchText(FFileExt, FPCToolsExts))
     and (not MatchText(FFileExt, FDelphiToolsExts))
     and (not MatchText(FFileExt, SplitString(FSettings.CommonTaskExt,',')))
     and (not MatchText(FFileExt, SplitString(FSettings.OpenDelphiExt,',')))
     and (not MatchText(FFileExt, SplitString(FSettings.OpenLazarusExt,',')))
     and (not MatchText(FFileExt, SplitString(FSettings.CheckSumExt,',')))

  then
   Exit(MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, 0));

   if  MatchText(FFileExt ,['.dproj', '.bdsproj','.dpr']) then
   begin
     if SameText(FFileExt, '.dpr') then
     begin
      sValue:=ChangeFileExt(FFileName,'.dproj');
      if TFile.Exists(sValue) then
         FDProjectVersion:=GetDelphiVersions(sValue);
     end
     else
     FDProjectVersion:=GetDelphiVersions(FFileName)
   end
   else
   if MatchText(FFileExt ,['.groupproj']) then
   begin
     if (FMSBuildGroupDProj<>nil) and (FMSBuildGroupDProj.ValidData) and (FMSBuildGroupDProj.Projects.Count>0) and (FMSBuildGroupDProj.Projects[0].ValidData) then
       FDProjectVersion:=GetDelphiVersions(FMSBuildGroupDProj.Projects[0].ProjectFile)
     else
       SetLength(FDProjectVersion, 0);
   end
   else
     SetLength(FDProjectVersion, 0);

    hSubMenu   := CreatePopupMenu;
    uIDNewItem := idCmdFirst;
    hSubMenuIndex := 0;

    FreeAndNil(FInfoPanel);
    if FSettings.ShowInfoDProj and MatchText(FFileExt, ['.dproj', '.dpr']) and
       FileExists(ChangeFileExt(FFileName, '.dproj')) then
    begin
      try
        FInfoPanel := TProjectInfoPanel.Create(ChangeFileExt(FFileName, '.dproj'), MenuDpi);
        if not FInfoPanel.IsValid then FreeAndNil(FInfoPanel);
      except
        on E: Exception do log('Project information: ' + E.Message);
      end;
      if FInfoPanel <> nil then
      begin
        ZeroMemory(@LMenuItem, SizeOf(LMenuItem));
        LMenuItem.cbSize := SizeOf(LMenuItem);
        LMenuItem.fMask := MIIM_FTYPE or MIIM_ID or MIIM_DATA or MIIM_STATE or MIIM_STRING;
        LMenuItem.fType := MFT_OWNERDRAW;
        LMenuItem.fState := MFS_DISABLED;
        LMenuItem.wID := uIDNewItem;
        LMenuItem.dwItemData := NativeUInt(FInfoPanel);
        LMenuItem.dwTypeData := 'Project information';
        FInfoPanelId := uIDNewItem;
        if not InsertMenuItem(hSubMenu, hSubMenuIndex, True, LMenuItem) then RaiseLastOSError;
        Inc(uIDNewItem);
        Inc(hSubMenuIndex);
        AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
        log(Format('Project panel id=%d size=%dx%d', [FInfoPanelId, FInfoPanel.Width, FInfoPanel.Height]));
      end;
    end;
    //AddCommonTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj','.bdsproj','.dpk','.groupproj','.rc','.lfm','.dfm','.fmx','.lpi','.lpr','.lpk']);
    AddCommonTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(FSettings.CommonTaskExt,','));
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    AddCheckSumTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(FSettings.CheckSumExt,','));
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    AddExternalToolsTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, FExternalToolsExts);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    AddOpenRADCmdTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj','.bdsproj','.dpk','.groupproj','.rc','.dfm','.fmx','.vsf','.style']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    //AddFormatCodeRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp']);
    //AddFormatCodeRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.FormatPascalExt,','));
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);
    //AddCompileRCTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.rc']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);
    AddOpenVclStyleTask(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.vsf']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    //AddOpenFmxStyleTask(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.style']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);


     if  MatchText(ExtractFileExt(FFileName),['.dproj','.dpr']) then
     begin

       if Length(FDProjectVersion)>0 then
       begin
         LCurrentDelphiVersion:=FDProjectVersion[0];

         Found:=FInstalledDelphiVersions.ContainsKey(LCurrentDelphiVersion);

//         for LCurrentDelphiVersion in DProjectVersion do
//           for LCurrentDelphiVersionData in InstalledDelphiVersions do
//            if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
//            begin
//             Found:=True;
//             Break;
//            end;

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

    AddPreferredTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst);
    AddMSBuildRAD_SpecificTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    //AddAuditsCLITasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);


    AddMSBuildRAD_AllTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.groupproj','.dpr','.proj']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    AddMSBuildPAClientTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    //AddOpenWithDelphi(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj', '.groupproj','.dpr','.pas','.inc','.pp','.dpk']);
    AddOpenWithDelphi(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(FSettings.OpenDelphiExt,','));
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    AddOpenWithDelphi_GroupProject(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.groupproj']);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    AddRADStudioToolsTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, FDelphiToolsExts);
    AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

    if FSettings.ActivateLazarus and FLazarusInstalled then
    begin
      //AddLazarusTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.lpi','.pp','.inc','.pas','.lpk']);
      AddLazarusTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(FSettings.OpenLazarusExt,','));
      AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);

      AddFPCToolsTasks(Self, hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, FPCToolsExts);
      AddMenuSeparatorEx(hSubMenu, hSubMenuIndex);
    end;

    //AddTouchRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj', '.bdsproj','.dpk','.groupproj']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);


    InsertMenuDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, PWideChar('Settings'), 'settings');
    if not IsVistaOrLater then
    RegisterMenuItemBitmapDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, 'settings_ico');
    LMethodInfo:=TMethodInfo.Create;
    LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUI;
    LMethodInfo.Value1:='-settings';
    FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
    Inc(uIDNewItem);
    Inc(hSubMenuIndex);


    InsertMenuDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, PWideChar('About'), 'logo');
    if not IsVistaOrLater then
    RegisterMenuItemBitmapDevShell(hSubMenu, hSubMenuIndex, uIDNewItem, 'logo_ico');
    LMethodInfo:=TMethodInfo.Create;
    LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUI;
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
    LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, FBitmapsDict['logo'].Handle, FBitmapsDict['logo24'].Handle);
    LMenuItem.hbmpChecked   := 0;
    LMenuItem.hbmpUnchecked := 0;
    if IsVistaOrLater then
    begin
      LMenuItem.hbmpChecked   := FBitmapsDict['logo'].Handle;
      LMenuItem.hbmpUnchecked := FBitmapsDict['logo'].Handle;
    end;

    if not InsertMenuItem(Menu, indexMenu, True, LMenuItem) then
         log('TShellMenu.QueryContextMenu RootMenu SysErrorMessage '+SysErrorMessage(GetLastError));

    if not IsVistaOrLater then
      RegisterMenuItemBitmapDevShell(Menu, indexMenu, uIDNewItem, 'logo_ico');

    // The root submenu also owns an ID. Return the highest offset PLUS ONE,
    // otherwise Explorer can discard it or reuse its ID for another handler.
    Inc(uIDNewItem);
    log('QueryContextMenu reserved IDs='+IntToStr(uIDNewItem-idCmdFirst));
    Result := MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, uIDNewItem-idCmdFirst);
 except on  E: Exception do
    begin
     log(Format('TShellMenu.QueryContextMenu Message %s  Trace %s',[E.Message, E.StackTrace]));
     Result := E_FAIL;
    end;
 end;
end;

function TShellMenu.ShellExtInitialize(pidlFolder: PItemIDList;
  lpdobj: IDataObject; hKeyProgID: HKEY): HResult;
var
  formatetcIn: TFormatEtc;
  medium: TStgMedium;
  FileNameLength: UINT;
  LProjName: string;
begin
  Result := E_FAIL;
 try
   log('TShellMenu.ShellExtInitialize Init');

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
      FileNameLength := DragQueryFile(medium.hGlobal, 0, nil, 0);
      SetLength(FFileName, FileNameLength + 1);
      DragQueryFile(medium.hGlobal, 0, PChar(FFileName), FileNameLength + 1);
      SetLength(FFileName, FileNameLength);
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
       if not TFile.Exists(LProjName) then
        LProjName:=FFileName;
      end;

      if SameText(ExtractFileExt(LProjName), '.dproj') and TFile.Exists(LProjName) then
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
   log('TShellMenu.ShellExtInitialize Done');
 except on  E: Exception do
    begin
     log(Format('TShellMenu.ShellExtInitialize Message %s  Trace %s',[E.Message, e.StackTrace]));
     Result := E_FAIL;
    end;
 end;
end;


end.
