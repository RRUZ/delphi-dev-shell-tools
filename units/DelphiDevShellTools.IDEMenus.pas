//**************************************************************************************************
//
// Unit DelphiDevShellTools.IDEMenus
// Delphi IDE, build, terminal and tool menu construction
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
// The Original Code is DelphiDevShellTools.IDEMenus.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.IDEMenus;

interface

uses Winapi.Windows, DelphiDevShellTools.ShellMenu;

procedure AddOpenRADCmdTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
procedure AddMSBuildRAD_SpecificTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
procedure AddMSBuildPAClientTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
procedure AddMSBuildRAD_AllTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
procedure AddOpenVclStyleTask(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
procedure AddPreferredTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT);
procedure AddOpenWithDelphi(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
procedure AddOpenWithDelphi_GroupProject(Context: TShellMenu;
  hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
procedure AddRADStudioToolsTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);

implementation

uses
  DelphiDevShellTools.Logging,
  System.SysUtils,
  System.Classes,
  System.Types,
  System.StrUtils,
  System.Math,
  Datasnap.DBClient,
  DelphiDevShellTools.Misc,
  DelphiDevShellTools.Tasks,
  DelphiDevShellTools.SettingsStore,
  System.IOUtils,
  DelphiDevShellTools.DelphiVersions,
  DelphiDevShellTools.Commands;

procedure AddOpenRADCmdTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
var
  Found: Boolean;
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  LCurrentDelphiVersionData: TDelphiVersionData;
  sSubMenuCaption: string;
  LMethodInfo: TMethodInfo;
begin
 try
    if not MatchText(Context.FileExt, SupportedExts) then exit;

    //Open RAD Studio Command Prompt Here
    Found:=False;
    for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.Values do
     if LCurrentDelphiVersionData.Version>=Delphi2007 then
     begin
      Found:=True;
      Break;
     end;


    if Found then
    begin
      if Context.Settings.SubMenuOpenCmdRAD then
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['radcmd'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['radcmd'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['radcmd'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        if not IsVistaOrLater then
          Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'radcmd_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
        LSubMenuIndex := MenuIndex;
        LSubMenu      := hMenu;
      end;

      for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.ValuesSorted do
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
        Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' Command Prompt'), PWideChar(LCurrentDelphiVersionData.Name));
        if not Context.IconsDictExternal.ContainsKey(uIDNewItem) then
          Context.IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);
        //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=TDelphiDevShellTasks.OpenRADCmd;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        LMethodInfo.Value2:=Context.FileName;
        Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;

      if not Context.Settings.SubMenuOpenCmdRAD then
       MenuIndex:=LSubMenuIndex;
    end;
 except
   on  E: Exception do
   log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

procedure AddMSBuildRAD_SpecificTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
var
  Found: Boolean;
  LSubMenu: Winapi.Windows.HMENU;
  LSubMenuIndex: Integer;
  LMenuItem: TMenuItemInfo;
  LCurrentDelphiVersionData: TDelphiVersionData;
  LCurrentDelphiVersion: TDelphiVersions;
  LFileName, sPlatform, sSubMenuCaption, sBuildConfiguration: string;
  LMethodInfo: TMethodInfo;
begin
  try
     if not MatchText(Context.FileExt, SupportedExts) then exit;

     if (Length(Context.DProjectVersion)=0) or (Context.InstalledDelphiVersions.Count=0) then exit;


     LCurrentDelphiVersion:=Context.DProjectVersion[0];
     LCurrentDelphiVersionData:=Context.InstalledDelphiVersions.Values.ToArray[0];
     Found:=Context.InstalledDelphiVersions.ContainsKey(LCurrentDelphiVersion);
     if Found then
       LCurrentDelphiVersionData:=Context.InstalledDelphiVersions[LCurrentDelphiVersion];

//     for LCurrentDelphiVersionData in InstalledDelphiVersions do
//      if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
//      begin
//       Found:=True;
//       Break;
//      end;

     if Found and (Context.InstalledDelphiVersions.Count>0) and (Length(Context.DProjectVersion)>0) then
       begin

        if Context.Settings.SubMenuMSBuild then
        begin
          LSubMenuIndex :=0;
          LSubMenu   := CreatePopupMenu;
          sSubMenuCaption:='Run MSBuild '+DelphiVersionsNames[Context.DProjectVersion[0]];

          ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
          LMenuItem.cbSize   := SizeOf(TMenuItemInfo);
          LMenuItem.fMask    := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or MIIM_BITMAP;
          LMenuItem.fType    := MFT_STRING;
          LMenuItem.wID      := uIDNewItem;
          LMenuItem.hSubMenu := LSubMenu;
          LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
          LMenuItem.cch := Length(sSubMenuCaption);
          LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
          LMenuItem.hbmpChecked   := Context.BitmapsDict['delphi'].Handle;
          LMenuItem.hbmpUnchecked := Context.BitmapsDict['delphi'].Handle;
          InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

          if not IsVistaOrLater then
            Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');

          Inc(uIDNewItem);
          Inc(MenuIndex);
        end
        else
        begin
          LSubMenu:=hMenu;
          LSubMenuIndex:=MenuIndex;
        end;

          LFileName:=ChangeFileExt(Context.FileName,'.dproj');

         if  (Context.MSBuildDProj<>nil) and (Context.MSBuildDProj.ValidData) then
         for LCurrentDelphiVersion in Context.DProjectVersion do
         for sPlatform in Context.MSBuildDProj.TargetPlatforms do
         begin
           if not LCurrentDelphiVersionData.Installation.SupportsPlatform(sPlatform) then Continue;


           for sBuildConfiguration in Context.MSBuildDProj.BuildConfigurations do
           begin
             Found:=False;
             if SameText(sPlatform, Context.MSBuildDProj.DefaultPlatForm) and (SameText(sBuildConfiguration, Context.MSBuildDProj.DefaultConfiguration)) then
             begin
               sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - '+sBuildConfiguration+') - Default Configuration';
               Found:=True;
             end
             else
               sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - '+sBuildConfiguration+')';


             if StartsText('Win', sPlatform) then
              Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'win')
             else
             if StartsText('OSX', sPlatform) then
              Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'osx')
             else
             if StartsText('IOS', sPlatform) then
              Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'ios')
             else
             if StartsText('Android', sPlatform) then
              Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'android');



             if not IsVistaOrLater then
             begin
               if StartsText('Win', sPlatform) then
                 Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'win_ico')
               else
               if StartsText('OSX', sPlatform) then
                 Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'osx_ico')
               else
               if StartsText('IOS', sPlatform) then
                 Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'ios_ico')
               else
               if StartsText('android', sPlatform) then
                 Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'android_ico');
             end;

             if Found then
             SetMenuDefaultItem(LSubMenu, LSubMenuIndex, 1);


             LMethodInfo:=TMethodInfo.Create;
             LMethodInfo.Method:=TDelphiDevShellTasks.MSBuildWithDelphi;
             LMethodInfo.Value1:=LCurrentDelphiVersionData;
             LMethodInfo.Value2:=sPlatform;
             LMethodInfo.Value3:=sBuildConfiguration;
             LMethodInfo.Value4:=LFileName;

             Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
             Inc(uIDNewItem);
             Inc(LSubMenuIndex);
           end;
         end;

        if not Context.Settings.SubMenuMSBuild then
          MenuIndex:=LSubMenuIndex;

       end;
  except
   on  E: Exception do
   log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddMSBuildPAClientTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  Found: Boolean;
  LSubMenu: Winapi.Windows.HMENU;
  i, LSubMenuIndex: Integer;
  LMenuItem: TMenuItemInfo;
  LCurrentDelphiVersionData: TDelphiVersionData;
  LFileName, sSubMenuCaption: string;
  LMethodInfo: TMethodInfo;
  LPAClientProfile: TPAClientProfile;
begin
  try
     if not MatchText(Context.FileExt, SupportedExts) then exit;

     Found:=False;

     for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.Values do
      if (LCurrentDelphiVersionData.Version>=DelphiXE2) and not Found then
       for i:= 0 to Context.PAClientProfiles.Profiles.Count-1 do
        if Context.PAClientProfiles.Profiles[i].RADStudioVersion=LCurrentDelphiVersionData.Version then
        begin
         Found:=True;
         Break;
        end;

     if Found and (Context.InstalledDelphiVersions.Count>0)  then
       begin

//        if {Settings.SubMenuMSBuild}1=1 then
//        begin
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
          LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
          LMenuItem.hbmpChecked   := Context.BitmapsDict['delphi'].Handle;
          LMenuItem.hbmpUnchecked := Context.BitmapsDict['delphi'].Handle;
          InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

          if not IsVistaOrLater then
            Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');

          Inc(uIDNewItem);
          Inc(MenuIndex);
//        end
//        else
//        begin
//          LSubMenu:=hMenu;
//          LSubMenuIndex:=MenuIndex;
//        end;

          LFileName:=Context.FileName;

        for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.ValuesSorted do
          if (LCurrentDelphiVersionData.Version>=DelphiXE2) then
            for i:= 0 to Context.PAClientProfiles.Profiles.Count-1 do
             if Context.PAClientProfiles.Profiles[i].RADStudioVersion=LCurrentDelphiVersionData.Version then
             begin
               LPAClientProfile:=Context.PAClientProfiles.Profiles[i];
               sSubMenuCaption:='Test Profile '+LPAClientProfile.Name+Format(' (Platform: %s - Host: %s - Port: %d)',[LPAClientProfile.Platform, LPAClientProfile.Host, LPAClientProfile.Port]);

                 if StartsText('Win', LPAClientProfile.Platform) then
                   Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'win')
                 else
                 if StartsText('OSX', LPAClientProfile.Platform) then
                   Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'osx')
                 else
                 if StartsText('IOS', LPAClientProfile.Platform) then
                   Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'ios')
                 else
                 if StartsText('Android', LPAClientProfile.Platform) then
                   Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), 'android');

                 //log(Format('%s %d',[sSubMenuCaption, LSubMenuIndex]));

                 if not IsVistaOrLater then
                 begin
                   if StartsText('Win', LPAClientProfile.Platform) then
                     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'win_ico')
                   else
                   if StartsText('OSX', LPAClientProfile.Platform) then
                     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'osx_ico')
                   else
                   if StartsText('IOS', LPAClientProfile.Platform) then
                     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'ios_ico')
                   else
                   if StartsText('Android', LPAClientProfile.Platform) then
                     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'android_ico');
                 end;

                 LMethodInfo:=TMethodInfo.Create;
                 LMethodInfo.Method:=TDelphiDevShellTasks.PAClientTest;
                 LMethodInfo.Value1:=LCurrentDelphiVersionData;
                 LMethodInfo.Value2:=LPAClientProfile.Name;

                 Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                 Inc(uIDNewItem);
                 Inc(LSubMenuIndex);
             end;

        if not Context.Settings.SubMenuMSBuild then
          MenuIndex:=LSubMenuIndex;

       end;
  except
   on  E: Exception do
   log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddMSBuildRAD_AllTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
var
  Found: Boolean;
  LSubMenuIndex: Integer;
  LCurrentDelphiVersionData: TDelphiVersionData;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption, sValue: string;
  LMethodInfo: TMethodInfo;
begin
  try
    if not MatchText(Context.FileExt, SupportedExts) then exit;


    Found:=False;
    for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.Values do
    if (LCurrentDelphiVersionData.Version>=Delphi2007) and (  ((Context.MSBuildDProj <>nil) and (LCurrentDelphiVersionData.Version<>Context.MSBuildDProj.DelphiVersion)) or MatchText(Context.FileExt,['.groupproj','.proj'])) then
    begin
      Found:=True;
      Break;
    end;

    if Found then
    begin
      if Context.Settings.SubMenuMSBuildAnother then
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['msbuild'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['msbuild'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['msbuild'].Handle;
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'msbuild_ico');

        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
        LSubMenuIndex:=MenuIndex;
        LSubMenu:=hMenu;
      end;

      for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.ValuesSorted do
       if (LCurrentDelphiVersionData.Version>=Delphi2007) and (((Context.MSBuildDProj <>nil) and (LCurrentDelphiVersionData.Version<>Context.MSBuildDProj.DelphiVersion)) or MatchText(Context.FileExt,['.groupproj','.proj'])) then
       begin
        Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('MSBuild with '+LCurrentDelphiVersionData.Name), PWideChar(LCurrentDelphiVersionData.Name));

        if not IsVistaOrLater then
        if not Context.IconsDictExternal.ContainsKey(uIDNewItem) then
          Context.IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);

        //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=TDelphiDevShellTasks.MSBuildWithDelphi_Default;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        LMethodInfo.Value2:=Context.FileName;

        if SameText(Context.FileExt, '.dpr') then
        begin
         sValue:=ChangeFileExt(Context.FileName,'.dproj');
         if TFile.Exists(sValue) then
           LMethodInfo.Value2:=sValue;
        end;

        Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;

      if not Context.Settings.SubMenuMSBuildAnother then
        MenuIndex:=LSubMenuIndex;

    end;
  except
   on  E: Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddOpenVclStyleTask(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
var
  Found: Boolean;
  LSubMenuIndex: Integer;
  LCurrentDelphiVersionData: TDelphiVersionData;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption: string;
  LMethodInfo: TMethodInfo;
begin
  try
    if not MatchText(Context.FileExt, SupportedExts) then exit;

    Found:=False;
    for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.Values do
    if LCurrentDelphiVersionData.Version>=DelphiXE2 then
    begin
      Found:=True;
      Break;
    end;

    if Found then
    begin
      if Context.Settings.SubMenuOpenVclStyle then
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['vcl'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['vcl'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['vcl'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        if not IsVistaOrLater then
         Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'vcl_ico');

        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
        LSubMenu:=hMenu;
        LSubMenuIndex:=MenuIndex;
      end;

      for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.ValuesSorted do
       if LCurrentDelphiVersionData.Version>=DelphiXE2 then
       begin
        Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Use Viewer of '+LCurrentDelphiVersionData.Name), PWideChar(LCurrentDelphiVersionData.Name));

        if not IsVistaOrLater then
        if not Context.IconsDictExternal.ContainsKey(uIDNewItem) then
          Context.IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);

        //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=TDelphiDevShellTasks.OpenVclStyle;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        LMethodInfo.Value2:=Context.FileName;
        Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;

      if not Context.Settings.SubMenuOpenVclStyle then
       MenuIndex:=LSubMenuIndex;
    end;
  except
    on  E: Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddPreferredTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT);
var Kind: TCommandKind; Choose: Boolean; Caption: string; Info: TMethodInfo;
begin
  if not MatchText(Context.FileExt, SplitString(Context.Settings.OpenDelphiExt, ',')) then Exit;
  for Kind in [ckOpenIDE, ckBuild] do
  begin
    if (Kind = ckBuild) and not MatchText(Context.FileExt, ['.dpr','.dproj','.groupproj','.proj']) then Continue;
    for Choose := False to True do
    begin
      if Kind = ckOpenIDE then
      begin
        Caption := 'Open with preferred Delphi';
        if Choose then Caption := 'Choose Delphi...';
      end
      else
      begin
        Caption := 'Build with preferred Delphi';
        if Choose then Caption := 'Build with options...';
      end;
      Context.InsertMenuDevShell(hMenu, MenuIndex, uIDNewItem, PChar(Caption), 'delphi');
      Info := TMethodInfo.Create;
      Info.Method := TDelphiDevShellTasks.ExecuteRequest;
      Info.Request := TDelphiDevShellTasks.IDECommand(Kind, Context.FileName, nil);
      Info.Request.ChooseIDE := Choose;
      Context.MethodsDict.Add(uIDNewItem - idCmdFirst, Info);
      Inc(uIDNewItem);
      Inc(MenuIndex);
    end;
  end;
end;

procedure AddOpenWithDelphi(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
var
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  Found: Boolean;
  LCurrentDelphiVersionData: TDelphiVersionData;
  LCurrentDelphiVersion: TDelphiVersions;
  sValue, sSubMenuCaption: string;
  LMethodInfo: TMethodInfo;
begin
  try
     if (Context.InstalledDelphiVersions.Count=0) or (not MatchText(Context.FileExt, SupportedExts)) then exit;

     if Context.Settings.SubMenuOpenDelphi then
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
      LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
      LMenuItem.hbmpChecked   := Context.BitmapsDict['delphi'].Handle;
      LMenuItem.hbmpUnchecked := Context.BitmapsDict['delphi'].Handle;
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      if not IsVistaOrLater then
      Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');
      Inc(uIDNewItem);
      Inc(MenuIndex);
     end
     else
     begin
      LSubMenuIndex:=MenuIndex;
      LSubMenu:=hMenu;
     end;


     if  MatchText(Context.FileExt, ['.dproj', '.dpr']) then
     begin

       for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.ValuesSorted do
       //if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
         Found:=False;
         if LCurrentDelphiVersionData.Version>=Delphi2007 then
         for LCurrentDelphiVersion in Context.DProjectVersion do
         if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name+' (Detected)';
           Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));
           SetMenuDefaultItem(LSubMenu, LSubMenuIndex, 1);
           Found:=True;
           Break;
         end;

         if not Found then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
           Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));
         end;

        if not IsVistaOrLater then
        if not Context.IconsDictExternal.ContainsKey(uIDNewItem) then
          Context.IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);
         //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=TDelphiDevShellTasks.OpenRADStudio;
         LMethodInfo.Value1:=LCurrentDelphiVersionData;
         LMethodInfo.Value2:=Context.FileName;
         LMethodInfo.Value3:=EmptyStr;
         if LCurrentDelphiVersionData.Version>=Delphi2007 then
         LMethodInfo.Value3:='-pDelphi';

         if SameText(Context.FileExt, '.dpr') then
         begin
          sValue:=ChangeFileExt(Context.FileName,'.dproj');
          if TFile.Exists(sValue) then
            LMethodInfo.Value2:=sValue;
         end;

         Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
         Inc(uIDNewItem);
         Inc(LSubMenuIndex);
       end
     end
     else
     //if  MatchText(Context.FileExt, ['.pas','.inc','.pp','.dpk'])  then
     for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.ValuesSorted do
     begin
       sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
       Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));

        if not IsVistaOrLater then
        if not Context.IconsDictExternal.ContainsKey(uIDNewItem) then
          Context.IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);

       //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
       LMethodInfo:=TMethodInfo.Create;
       LMethodInfo.Method:=TDelphiDevShellTasks.OpenWithDelphi;
       LMethodInfo.Value1:=LCurrentDelphiVersionData;
       LMethodInfo.Value2:=Context.FileName;
       LMethodInfo.Value3:=EmptyStr;
       if LCurrentDelphiVersionData.Version>=Delphi2005 then
        LMethodInfo.Value3:='-pDelphi';

       Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
       Inc(uIDNewItem);
       Inc(LSubMenuIndex);
     end;

     if not Context.Settings.SubMenuOpenDelphi then
      MenuIndex:=LSubMenuIndex;
  except
    on  E: Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddOpenWithDelphi_GroupProject(Context: TShellMenu;
  hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  Found: Boolean;
  LCurrentDelphiVersionData: TDelphiVersionData;
  LCurrentDelphiVersion: TDelphiVersions;
  sSubMenuCaption: string;
  LMethodInfo: TMethodInfo;
begin
  try
     if (Context.InstalledDelphiVersions.Count=0) or (not MatchText(Context.FileExt, SupportedExts)) then exit;


     if Context.Settings.SubMenuOpenDelphi then
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
      LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
      LMenuItem.hbmpChecked   := Context.BitmapsDict['delphi'].Handle;
      LMenuItem.hbmpUnchecked := Context.BitmapsDict['delphi'].Handle;
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      if not IsVistaOrLater then
      Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');
      Inc(uIDNewItem);
      Inc(MenuIndex);
     end
     else
     begin
      LSubMenuIndex:=MenuIndex;
      LSubMenu:=hMenu;
     end;


     if  MatchText(Context.FileExt, ['.groupproj']) then
     begin
       for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.ValuesSorted do
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
         Found:=False;
         for LCurrentDelphiVersion in Context.DProjectVersion do
         if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name+' (Detected)';
           Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));
           SetMenuDefaultItem(LSubMenu, LSubMenuIndex, 1);
           Found:=True;
           Break;
         end;

         if not Found then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
           Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(sSubMenuCaption), PWideChar(LCurrentDelphiVersionData.Name));
         end;

        if not IsVistaOrLater then
        if not Context.IconsDictExternal.ContainsKey(uIDNewItem) then
          Context.IconsDictExternal.Add(uIDNewItem, LCurrentDelphiVersionData.Icon);
         //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=TDelphiDevShellTasks.OpenRADStudio;
         LMethodInfo.Value1:=LCurrentDelphiVersionData;
         LMethodInfo.Value2:=Context.FileName;
         LMethodInfo.Value3:=EmptyStr;
         if LCurrentDelphiVersionData.Version>=Delphi2007 then
         LMethodInfo.Value3:='-pDelphi';

         Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
         Inc(uIDNewItem);
         Inc(LSubMenuIndex);
       end
     end;

     if not Context.Settings.SubMenuOpenDelphi then
      MenuIndex:=LSubMenuIndex;
  except
    on  E: Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddRADStudioToolsTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LCurrentDelphiVersionData: TDelphiVersionData;
  LClientDataSet: TClientDataSet;
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  s, sSubMenuCaption: string;
  LMethodInfo: TMethodInfo;
  LArray: TStringDynArray;
begin
  try
    if (Context.InstalledDelphiVersions.Count=0) or (not MatchText(Context.FileExt, SupportedExts)) then exit;


//      if (1=1) then
//      begin
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['delphi'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['delphi'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['delphi'].Handle;
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'delphi_ico');

        Inc(uIDNewItem);
        Inc(MenuIndex);
//      end
//      else
//      begin
//         LSubMenuIndex:=MenuIndex;
//         LSubMenu:=hMenu;
//      end;


       LClientDataSet:= TClientDataSet.Create(nil);
       try
           LClientDataSet.ReadOnly:=True;
           LoadTools(LClientDataSet, Context.Settings.Document);
           LClientDataSet.Open;
           LClientDataSet.Filter:='Group = '+QuotedStr('Delphi Tools')+' AND Review = '+QuotedStr('');
           LClientDataSet.Filtered:=True;

           for LCurrentDelphiVersionData in Context.InstalledDelphiVersions.ValuesSorted do
           begin
            LClientDataSet.First;

            while not LClientDataSet.eof do
            begin
             if CommandAllowsVersion(LClientDataSet, LCurrentDelphiVersionData.Version) then
             begin
               LArray:= SplitString(LClientDataSet.FieldByName('Extensions').AsString, ',');
               if MatchText(Context.FileExt, LArray) then
               begin
                if (LClientDataSet.FieldByName('Image').IsNull) or (not FileExists(GetDevShellToolsImagesFolder+LClientDataSet.FieldByName('Image').AsString)) then
                  Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' - '+TDelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, LCurrentDelphiVersionData, Context.FileName)), nil)
                else
                begin
                  s:=LClientDataSet.FieldByName('Image').AsString;

                  Context.RegisterBitmap32(s);
                  Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' - '+TDelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, LCurrentDelphiVersionData, Context.FileName)), PWideChar(s));
                  if not IsVistaOrLater then
                    Context.RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, s);
                end;

                LMethodInfo:=TMethodInfo.Create;
                LMethodInfo.Method:=TDelphiDevShellTasks.RADTools;
                LMethodInfo.Value1:=LClientDataSet.FieldByName('Script').AsString;
                LMethodInfo.Value3:=Context.FileName;
                LMethodInfo.Value4:=LCurrentDelphiVersionData;
                LMethodInfo.Value2:=False;
                if (not LClientDataSet.FieldByName('RunAs').IsNull) then
                 LMethodInfo.Value2:=LClientDataSet.FieldByName('RunAs').AsBoolean;

                Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                Inc(uIDNewItem);
                Inc(LSubMenuIndex);
               end;
             end;
             LClientDataSet.Next;
            end;

            Context.AddMenuSeparatorEx(LSubMenu, LSubMenuIndex);
           end;

       finally
         LClientDataSet.Free;
       end;
  except
    on  E: Exception do
    log(Format('IDEMenus.AddRADStudioToolsTasks Message %s Trace %s',[E.Message, e.StackTrace]));
  end;
end;

end.
