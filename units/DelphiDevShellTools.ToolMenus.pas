//**************************************************************************************************
//
// Unit DelphiDevShellTools.ToolMenus
// Common, checksum, custom-tool and Lazarus menu construction
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
// The Original Code is DelphiDevShellTools.ToolMenus.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.ToolMenus;

interface

uses Winapi.Windows, DelphiDevShellTools.ShellMenu;

procedure AddCheckSumTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
procedure AddCommonTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
procedure AddExternalToolsTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
procedure AddFPCToolsTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
procedure AddLazarusTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);

implementation

uses
  DelphiDevShellTools.Logging,
  System.SysUtils,
  System.Types,
  System.StrUtils,
  System.Math,
  Datasnap.DBClient,
  DelphiDevShellTools.Misc,
  DelphiDevShellTools.Tasks,
  DelphiDevShellTools.SettingsStore,
  DelphiDevShellTools.LazarusVersions;

procedure AddCheckSumTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LMethodInfo: TMethodInfo;
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption: string;
begin
  try
   if not MatchText(Context.FileExt, SupportedExts) then exit;

//      if (1=1){Settings.SubMenuCommonTasks} then
//      begin
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['checksum'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['checksum'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['checksum'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'checksum_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
//      end
//      else
//      begin
//         LSubMenuIndex:=MenuIndex;
//         LSubMenu:=hMenu;
//      end;
//


     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate CRC32'), 'checksum_crc32');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex,
       uIDNewItem, 'checksum_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='CRC32';
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate MD4'), 'checksum_md4');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex,
       uIDNewItem, 'checksum_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='MD4';
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate MD5'), 'checksum_md5');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex,
       uIDNewItem, 'checksum_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='MD5';
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate SHA1'), 'checksum_sha1');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex,
       uIDNewItem, 'checksum_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='SHA1';
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate SHA-256'), 'checksum_sha256');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex,
       uIDNewItem, 'checksum_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='SHA-256';
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate SHA-384'), 'checksum_sha384');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex,
       uIDNewItem, 'checksum_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='SHA-384';
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Calculate SHA-512'), 'checksum_sha512');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex,
       uIDNewItem, 'checksum_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenGUICheckSum;
     LMethodInfo.Value1:='SHA-512';
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     //Inc(LSubMenuIndex);

     {
      if not Settings.SubMenuCommonTasks then
       MenuIndex:=LSubMenuIndex;
     }
  except
    on  E: Exception do
     log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddCommonTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
var
  LMethodInfo: TMethodInfo;
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption: string;
begin
  try
   if not MatchText(Context.FileExt, SupportedExts) then exit;

      if Context.Settings.SubMenuCommonTasks then
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['common'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['common'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['common'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        if not IsVistaOrLater then
          Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'common_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;


     var LCopySubMenuIndex := 0;
     var LCopySubMenu := CreatePopupMenu;
     if LCopySubMenu = 0 then
       RaiseLastOSError;
     var LCopyCaption := 'Copy';
     var LCopyMenuId := uIDNewItem + 6;
     var LCopyMenuItem := Default(TMenuItemInfo);
     LCopyMenuItem.cbSize := SizeOf(TMenuItemInfo);
     LCopyMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID or
       MIIM_BITMAP;
     LCopyMenuItem.fType := MFT_STRING;
     LCopyMenuItem.wID := LCopyMenuId;
     LCopyMenuItem.hSubMenu := LCopySubMenu;
     LCopyMenuItem.dwTypeData := PWideChar(LCopyCaption);
     LCopyMenuItem.cch := Length(LCopyCaption);
     LCopyMenuItem.hbmpItem := IfThen(IsVistaOrLater,
       Context.BitmapsDict['copy'].Handle, HBMMENU_CALLBACK);
     LCopyMenuItem.hbmpChecked := Context.BitmapsDict['copy'].Handle;
     LCopyMenuItem.hbmpUnchecked := Context.BitmapsDict['copy'].Handle;
     if not InsertMenuItem(LSubMenu, LSubMenuIndex, True, LCopyMenuItem) then
     begin
       DestroyMenu(LCopySubMenu);
       RaiseLastOSError;
     end;
     if not IsVistaOrLater then
       Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex,
         LCopyMenuId, 'copy_ico');
     Inc(LSubMenuIndex);

     Context.InsertMenuDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, PWideChar('Copy File Path to clipboard'), 'copy_path');
     Context.RegisterMenuItemBitmapDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, 'copy_path_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.CopyPathClipboard;
     LMethodInfo.Value1:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LCopySubMenuIndex);

     Context.InsertMenuDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, PWideChar('Copy full FileName (Path + FileName) to clipboard'),'copy');
     Context.RegisterMenuItemBitmapDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, 'copy_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.CopyFileNameClipboard;
     LMethodInfo.Value1:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LCopySubMenuIndex);

     Context.InsertMenuDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, PWideChar('Copy FileName using URL format (file://...) to clipboard'),'copy_url');
     Context.RegisterMenuItemBitmapDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, 'copy_url_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.CopyFileNameUrlClipboard;
     LMethodInfo.Value1:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LCopySubMenuIndex);

     Context.InsertMenuDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, PWideChar('Copy FileName using UNC format (\\server-name\Shared...) to clipboard'),'copy_unc');
     Context.RegisterMenuItemBitmapDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, 'copy_unc_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.CopyFileNameUNCClipboard;
     LMethodInfo.Value1:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LCopySubMenuIndex);

     Context.InsertMenuDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, PWideChar('Copy FileName using Unix format (Drive:/Path/Filaname) to clipboard'),'copy_unc');
     Context.RegisterMenuItemBitmapDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, 'copy_unc_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.CopyFileNameUnixClipboard;
     LMethodInfo.Value1:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LCopySubMenuIndex);

     Context.InsertMenuDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, PWideChar('Copy File content to the clipboard'), 'copy_content');
     Context.RegisterMenuItemBitmapDevShell(LCopySubMenu, LCopySubMenuIndex, uIDNewItem, 'copy_content_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.CopyFileContentClipboard;
     LMethodInfo.Value1:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);

     Inc(uIDNewItem);

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open In Notepad'), 'notepad');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'notepad_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenWithNotepad;
     LMethodInfo.Value1:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     try
       if (Context.ExeNameTxt<>'') and (not SameText('notepad.exe', ExtractFileName(Context.ExeNameTxt))) then
       begin
           log(ExtractFileName(Context.ExeNameTxt));
           Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open In '+Context.FriendlyAppNameTxt), 'txt');
           Context.RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, 'txt');
           LMethodInfo:=TMethodInfo.Create;
           LMethodInfo.Method:=TDelphiDevShellTasks.OpenWithApp;
           LMethodInfo.Value1:=Context.ExeNameTxt;
           LMethodInfo.Value2:=Context.FileName;
           Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
           Inc(uIDNewItem);
           Inc(LSubMenuIndex);
       end;

     except
       on  E: Exception do
       log('GetAssocAppByExt '+E.Message);
     end;

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open Command Line here'), 'cmd');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'cmd_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenCmdHere;
     LMethodInfo.Value1:=False;
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open Command Line here as Administrator'), 'shield');
     Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'shield_ico');
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=TDelphiDevShellTasks.OpenCmdHere;
     LMethodInfo.Value1:=True;
     LMethodInfo.Value2:=Context.FileName;
     Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

      if not Context.Settings.SubMenuCommonTasks then
       MenuIndex:=LSubMenuIndex;

  except
    on  E: Exception do
     log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddExternalToolsTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LClientDataSet: TClientDataSet;
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  s, sSubMenuCaption: string;

  LMethodInfo: TMethodInfo;
  LArray: TStringDynArray;
begin
  try
    if not MatchText(Context.FileExt, SupportedExts) then exit;


//      if (1=1){Settings.SubMenuLazarus} then
//      begin
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['wrench'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['wrench'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['wrench'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'wrench_ico');
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
           LClientDataSet.Filter:='Group = '+QuotedStr('External Tools')+' AND Review = '+QuotedStr('');
           LClientDataSet.Filtered:=True;

            while not LClientDataSet.eof do
            begin
             LArray:= SplitString(LClientDataSet.FieldByName('Extensions').AsString, ',');
             if MatchText(Context.FileExt, LArray) then
             begin

              if LClientDataSet.FieldByName('Image').IsNull or
                not Context.IsMenuIconAvailable(
                  LClientDataSet.FieldByName('Image').AsString) then
               Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(TDelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil, Context.FileName)), nil)
              else
              begin
                s:=LClientDataSet.FieldByName('Image').AsString;

                Context.RegisterBitmap32(s);
                Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(TDelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil, Context.FileName)), PWideChar(s));
                if not IsVistaOrLater then
                  Context.RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, s);
              end;

              LMethodInfo:=TMethodInfo.Create;
              LMethodInfo.Method:=TDelphiDevShellTasks.ExternalTools;
              LMethodInfo.Value1:=LClientDataSet.FieldByName('Script').AsString;
              LMethodInfo.Value3:=Context.FileName;
              LMethodInfo.Value2:=False;
              if (not LClientDataSet.FieldByName('RunAs').IsNull) then
               LMethodInfo.Value2:=LClientDataSet.FieldByName('RunAs').AsBoolean;

              Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
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
    on  E: Exception do
    log(Format('ToolMenus.AddFPCToolsTasks Message %s Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddFPCToolsTasks(Context: TShellMenu; hMenu: HMENU;
  var MenuIndex: Integer; var uIDNewItem: UINT; idCmdFirst: UINT;
  const SupportedExts: array of string);
var
  LClientDataSet: TClientDataSet;
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  s, sSubMenuCaption: string;

  LMethodInfo: TMethodInfo;
  LArray: TStringDynArray;
begin
  try
    if not MatchText(Context.FileExt, SupportedExts) then exit;


//      if (1=1){Settings.SubMenuLazarus} then
//      begin
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['fpc_tools'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['fpc_tools'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['fpc_tools'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'fpc_tools_ico');
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
           LClientDataSet.Filter:='Group = '+QuotedStr('FPC Tools')+' AND Review = '+QuotedStr('');
           LClientDataSet.Filtered:=True;

            while not LClientDataSet.eof do
            begin
             LArray:= SplitString(LClientDataSet.FieldByName('Extensions').AsString, ',');
             if MatchText(Context.FileExt, LArray) then
             begin

              if LClientDataSet.FieldByName('Image').IsNull or
                not Context.IsMenuIconAvailable(
                  LClientDataSet.FieldByName('Image').AsString) then
               Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(TDelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil, Context.FileName)), nil)
              else
              begin
                s:=LClientDataSet.FieldByName('Image').AsString;

                Context.RegisterBitmap32(s);
                Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar(TDelphiDevShellTasks.ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil, Context.FileName)), PWideChar(s));
                if not IsVistaOrLater then
                  Context.RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, s);
              end;

              LMethodInfo:=TMethodInfo.Create;
              LMethodInfo.Method:=TDelphiDevShellTasks.FPCTools;
              LMethodInfo.Value1:=LClientDataSet.FieldByName('Script').AsString;
              LMethodInfo.Value3:=Context.FileName;
              LMethodInfo.Value2:=False;
              if (not LClientDataSet.FieldByName('RunAs').IsNull) then
               LMethodInfo.Value2:=LClientDataSet.FieldByName('RunAs').AsBoolean;

              Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
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
    on  E: Exception do
    log(Format('ToolMenus.AddFPCToolsTasks Message %s Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure AddLazarusTasks(Context: TShellMenu; hMenu: HMENU; var MenuIndex: Integer; var uIDNewItem :UINT; idCmdFirst: UINT; const SupportedExts: array of string);
var
  LSubMenuIndex: Integer;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption: string;
  LMethodInfo: TMethodInfo;
begin
  try
    if not MatchText(Context.FileExt, SupportedExts) then exit;

      if Context.Settings.SubMenuLazarus then
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
        LMenuItem.hbmpItem      := IfThen(IsVistaOrLater, Context.BitmapsDict['lazarusmenu'].Handle, HBMMENU_CALLBACK);
        LMenuItem.hbmpChecked   := Context.BitmapsDict['lazarusmenu'].Handle;
        LMenuItem.hbmpUnchecked := Context.BitmapsDict['lazarusmenu'].Handle;

        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);

        if not IsVistaOrLater then
          Context.RegisterMenuItemBitmapDevShell(hMenu, MenuIndex, uIDNewItem, 'lazarusmenu_ico');
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;

      Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Open with Lazarus IDE'), 'lazarus');
      if not IsVistaOrLater then
        Context.RegisterMenuItemBitmapExternal(LSubMenu, LSubMenuIndex, uIDNewItem, 'lazarus');

      LMethodInfo:=TMethodInfo.Create;
      LMethodInfo.Method:=TDelphiDevShellTasks.OpenWithLazarus;
      LMethodInfo.Value1:=GetLazarusIDEFileName;
      LMethodInfo.Value2:=Context.FileName;
      Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
      Inc(uIDNewItem);
      Inc(LSubMenuIndex);


      if MatchText(Context.FileExt, ['.lpi', '.lpk']) then
      begin
        Context.InsertMenuDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, PWideChar('Build with lazbuild'), 'lazbuild');
        if not IsVistaOrLater then
          Context.RegisterMenuItemBitmapDevShell(LSubMenu, LSubMenuIndex, uIDNewItem, 'lazbuild_ico');
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=TDelphiDevShellTasks.BuildWithLazBuild;
        LMethodInfo.Value1:=GetLazarusIDEFolder;
        LMethodInfo.Value2:=Context.FileName;
        Context.MethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
      end;


      if not Context.Settings.SubMenuLazarus then
       MenuIndex:=LSubMenuIndex;

  except
    on  E: Exception do
    log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

end.
