{**************************************************************************************************}
{                                                                                                  }
{ Unit DelphiDevShellToolsImpl                                                                     }
{ unit for the Delphi Dev Shell Tools                                                              }
{ http://code.google.com/p/delphi-dev-shell-tools/                                                 }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is DelphiDevShellToolsImpl.pas.                                                }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013 Rodrigo Ruz V.                         }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}
unit DelphiDevShellToolsImpl;

{$WARN SYMBOL_PLATFORM OFF}
{.$DEFINE ENABLELOG}

interface

uses
  Generics.Defaults,
  Generics.Collections,
  System.Win.ComObj,
  Winapi.ActiveX,
  DelphiDevShellTools_TLB,
  System.Rtti,
  Winapi.ShlObj,
  Winapi.Windows,
  Winapi.ShellAPI;

type
  TMethodInfo=class
   hwnd   : HWND;
   Value1 : TValue;
   Value2 : TValue;
   Value3 : TValue;
   Method : procedure(Info : TMethodInfo) of object;
  end;

  TDelphiDevShellToolsContextMenu = class(TAutoObject, IDelphiDevShellToolsContextMenu, IShellExtInit, IContextMenu)
  private
    FFileName: string;
    FMenuItemIndex: UINT;
    FMethodsDict : TObjectDictionary<Integer, TMethodInfo>;
    procedure OpenWithDelphi(Info : TMethodInfo);
    procedure OpenRADStudio(Info : TMethodInfo);
    //procedure BuildWithDelphi(Info : TMethodInfo);
    procedure MSBuildWithDelphi_Default(Info : TMethodInfo);
    procedure MSBuildWithDelphi(Info : TMethodInfo);
    procedure OpenWithNotepad(Info : TMethodInfo);
    procedure OpenCmdHere(Info : TMethodInfo);
    procedure CopyPathClipboard(Info : TMethodInfo);
    procedure CopyFileNameClipboard(Info : TMethodInfo);
    procedure OpenGUI(Info : TMethodInfo);
  protected
    function IShellExtInit.Initialize = ShellExtInitialize;
    function ShellExtInitialize(pidlFolder: PItemIDList; lpdobj: IDataObject; hKeyProgID: HKEY): HResult; stdcall;
    function QueryContextMenu(Menu: HMENU; indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult; stdcall;
    function InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult; stdcall;
    function GetCommandString(idCmd: UINT_PTR; uFlags: UINT; pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult; stdcall;
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
  uMisc,
  ClipBrd,
  Vcl.Graphics,
  System.Classes,
  uDelphiVersions,
  System.IOUtils,
  System.StrUtils,
  System.Win.ComServ,
  System.SysUtils,
  System.Win.Registry;

{$R images.res}

var
  InstalledDelphiVersions : TObjectList<TDelphiVersionData>;
  BitmapsDict    : TObjectDictionary<string, TBitmap>;

procedure log(const msg: string);
begin
 {$IFDEF ENABLELOG}
  TFile.AppendAllText(IncludeTrailingPathDelimiter(GetTempDirectory)+'shelllog.txt', FormatDateTime('hh:nn:ss.zzz',Now)+' '+msg+sLineBreak);
 {$ENDIF}
end;

constructor TDelphiDevShellToolsContextMenu.Create;
begin
  inherited;
  FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues]);
end;

destructor TDelphiDevShellToolsContextMenu.Destroy;
begin
  if FMethodsDict<>nil then
    FMethodsDict.Free;
  inherited;
end;

procedure TDelphiDevShellToolsContextMenu.OpenWithDelphi(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
begin
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  log('OpenWithDelphi '+LDelphiVersion.Path+' '+Format('-pDelphi "%s"',[FFileName]));
  ShellExecute(Info.hwnd, 'open', PChar(LDelphiVersion.Path), PChar(Format('-pDelphi "%s"',[FFileName])) , nil , SW_SHOWNORMAL);
end;

procedure TDelphiDevShellToolsContextMenu.OpenRADStudio(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
begin
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  log('OpenRADStudio '+LDelphiVersion.Path+' '+Format(' "%s"',[FFileName]));
  ShellExecute(Info.hwnd, 'open', PChar(LDelphiVersion.Path), PChar(Format('"%s"',[FFileName])) , nil , SW_SHOWNORMAL);
end;

procedure TDelphiDevShellToolsContextMenu.OpenWithNotepad(Info : TMethodInfo);
begin
  ShellExecute(Info.hwnd, 'open', 'C:\Windows\notepad.exe', PChar(FFileName) , nil , SW_SHOWNORMAL);
end;

procedure TDelphiDevShellToolsContextMenu.CopyPathClipboard(Info : TMethodInfo);
var
  FilePath: string;
begin
  FilePath:=ExtractFilePath(FFileName);
  Clipboard.AsText := FilePath;
end;

procedure TDelphiDevShellToolsContextMenu.CopyFileNameClipboard(Info : TMethodInfo);
begin
  Clipboard.AsText := FFileName;
end;

procedure TDelphiDevShellToolsContextMenu.OpenCmdHere(Info : TMethodInfo);
var
  FilePath, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  log('OpenCmdHere');
  FilePath:=ExtractFilePath(FFileName);
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('%s',[FilePath[1]+':']));
    BatchFile.Add(Format('cd "%s"',[FilePath]));
    BatchFile.Add('cls');
    BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
    BatchFile.SaveToFile(BatchFileName);
    Params:='/K "'+BatchFileName+'"';
    ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
  finally
    BatchFile.Free;
  end;
end;

//procedure TDelphiDevShellToolsContextMenu.BuildWithDelphi(Info : TMethodInfo);//incomplete
//var
//  LDelphiVersion  : TDelphiVersionData;
//  CompilerPath, Params, BatchFileName : string;
//  BatchFile : TStrings;
//begin
//  log('BuildWithDelphi');
//  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
//  CompilerPath:=ExtractFilePath(LDelphiVersion.Path)+'DCC32.exe';
//  //Params:=Format('/K "%s" -B -NSsystem;vcl;Winapi;System.Win "%s"',[CompilerPath, FFileName]);
//  //log('BuildWithDelphi cmd.exe '+Params);
//  //ShellExecute(Info.hwnd, 'open', PChar('"'+CompilerPath+'"'), PChar(Format('-B -NSsystem;vcl;Winapi;System.Win "%s"',[FFileName])) , nil , SW_SHOWNORMAL);
//  //ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
//  BatchFile:=TStringList.Create;
//  try
//    BatchFile.Add(Format('"%s" -B -NSsystem;vcl;Winapi;System.Win "%s"',[CompilerPath, FFileName]));
//    BatchFile.Add('Pause');
//    BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
//    BatchFile.SaveToFile(BatchFileName);
//    Params:='/C "'+BatchFileName+'"';
//    ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
//  finally
//    BatchFile.Free;
//  end;
//end;

procedure TDelphiDevShellToolsContextMenu.MSBuildWithDelphi_Default(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  RsvarsPath, CompilerPath, Params, BatchFileName : string;
  BatchFile : TStrings;
begin
  log('MSBuildWithDelphi_Default');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  RsvarsPath  :=ExtractFilePath(LDelphiVersion.Path)+'rsvars.bat';
  CompilerPath:=ExtractFilePath(LDelphiVersion.Path)+'DCC32.exe';
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('call "%s"',[RsvarsPath]));
    BatchFile.Add(Format('msbuild.exe "%s"', [FFileName]));
    BatchFile.Add('Pause');
    BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
    BatchFile.SaveToFile(BatchFileName);
    Params:='/C "'+BatchFileName+'"';
    ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
  finally
    BatchFile.Free;
  end;
end;


procedure TDelphiDevShellToolsContextMenu.MSBuildWithDelphi(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  RsvarsPath, CompilerPath, Params, BatchFileName, sPlatform, sConfig : string;
  BatchFile : TStrings;
begin
  log('MSBuildWithDelphi');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  sPlatform:=Info.Value2.AsString;
  sConfig:=Info.Value3.AsString;


  RsvarsPath  :=ExtractFilePath(LDelphiVersion.Path)+'rsvars.bat';
  CompilerPath:=ExtractFilePath(LDelphiVersion.Path)+'DCC32.exe';
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('call "%s"',[RsvarsPath]));
    BatchFile.Add(Format('msbuild.exe "%s" /target:build /p:Platform=%s /p:config=%s', [FFileName, sPlatform, sConfig]));
    BatchFile.Add('Pause');
    BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
    BatchFile.SaveToFile(BatchFileName);
    Params:='/C "'+BatchFileName+'"';
    ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
  finally
    BatchFile.Free;
  end;
end;


procedure TDelphiDevShellToolsContextMenu.OpenGUI(Info : TMethodInfo);
begin
  ShellExecute(Info.hwnd, 'open', PChar(IncludeTrailingPathDelimiter(ExtractFilePath(GetModuleName))+'GUIDelphiDevShell.exe'), PChar(FFileName) , nil , SW_SHOWNORMAL);
end;

function TDelphiDevShellToolsContextMenu.GetCommandString(idCmd: UINT_PTR; uFlags: UINT;
  pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult;
begin
  Result := E_INVALIDARG;
end;

function TDelphiDevShellToolsContextMenu.InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult;
var
  LVerb: Word;
begin
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
end;


function TDelphiDevShellToolsContextMenu.QueryContextMenu(Menu: HMENU;
  indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult;
var
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption, FileExt, LMenuCaption, sPlatform: String;
  LSubMenu: HMENU;
  uIDNewItem: UINT;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LCurrentDelphiVersion      : TDelphiVersions;
  LMenuIndex : Integer;
  {ContainsItems,} Found : Boolean;
  LMethodInfo : TMethodInfo;
  sdv : SetDelphiVersions;
  LMSBuildDProj : TMSBuildDProj;
                {
  uId_menuitem : Cardinal;
  LMenuInfo    : TMenuItemInfo;
  Buffer       : array [0..79] of char;}
begin

  //ContainsItems:=False;
  FMenuItemIndex := indexMenu;

  if (uFlags = CMF_NORMAL) or ((uFlags and CMF_EXPLORE) = CMF_EXPLORE) then
    LMenuCaption := 'Delphi Dev Shell Tools'
  else
    Exit(E_FAIL);

  if FMethodsDict=nil then
    FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues]);

  FileExt:=ExtractFileExt(FFileName);

  if not MatchText(FileExt,['.pas','.dpr','.inc','.pp','.dproj', '.bdsproj']) then
   Exit(E_FAIL);


    LSubMenu := CreatePopupMenu;
    uIDNewItem := idCmdFirst;
    LMenuIndex:=0;

     InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy file path to clipboard'));
     SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyPathClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LMenuIndex);

     InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy full filename (Path + FileName) to clipboard'));
     SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyFileNameClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LMenuIndex);

     InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open In Notepad'));
     SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['notepad'].Handle, BitmapsDict.Items['notepad'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenWithNotepad;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LMenuIndex);

     InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open cmd here'));
     SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['cmd'].Handle, BitmapsDict.Items['cmd'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenCmdHere;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LMenuIndex);

     InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
     inc(LMenuIndex);
     Inc(uIDNewItem);

     if  MatchText(FileExt,['.pas','.dpr','.inc','.pp'])  then
     for LCurrentDelphiVersionData in InstalledDelphiVersions do
     begin
       sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
       InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
       log(Format('%s %d',[sSubMenuCaption, LMenuIndex]));
       SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
       LMethodInfo:=TMethodInfo.Create;
       LMethodInfo.Method:=OpenWithDelphi;
       LMethodInfo.Value1:=LCurrentDelphiVersionData;
       FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
       Inc(uIDNewItem);
       Inc(LMenuIndex);
       //ContainsItems:=True;
     end
     else
     if  MatchText(ExtractFileExt(FFileName),['.dproj', '.bdsproj']) then
     for LCurrentDelphiVersionData in InstalledDelphiVersions do
     begin
       sdv:=GetDelphiVersions(FFileName);
       Found:=False;
       for LCurrentDelphiVersion in sdv do
       if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
       begin
         sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name+' (Detected)';
         InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
         log(Format('%s %d',[sSubMenuCaption, LMenuIndex]));
         Found:=True;
         Break;
       end;

       if not Found then
       begin
         sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
         InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
         log(Format('%s %d',[sSubMenuCaption, LMenuIndex]));
       end;

       SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
       LMethodInfo:=TMethodInfo.Create;
       LMethodInfo.Method:=OpenRADStudio;
       LMethodInfo.Value1:=LCurrentDelphiVersionData;
       FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
       Inc(uIDNewItem);
       Inc(LMenuIndex);
       //ContainsItems:=True;
     end;


     InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
     inc(LMenuIndex);


     if  MatchText(ExtractFileExt(FFileName),['.dproj']) then
     begin
       sdv:=GetDelphiVersions(FFileName);
       if Length(sdv)>0 then
       begin
         LCurrentDelphiVersion:=sdv[0];

         Found:=False;
         for LCurrentDelphiVersion in sdv do
           for LCurrentDelphiVersionData in InstalledDelphiVersions do
            if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
            begin
             Found:=True;
             Break;
            end;

         if not Found then
         begin
             sSubMenuCaption:='Project Type '+DelphiVersionsNames[LCurrentDelphiVersion]+' Detected but not installed';
             InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION or MF_GRAYED, uIDNewItem, PWideChar(sSubMenuCaption));
             SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphig'].Handle, BitmapsDict.Items['delphig'].Handle);
             log(Format('%s %d',[sSubMenuCaption, LMenuIndex]));
             Inc(uIDNewItem);
             Inc(LMenuIndex);
         end
         else
         for LCurrentDelphiVersionData in InstalledDelphiVersions do
         begin

           for LCurrentDelphiVersion in sdv do
           if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
           begin
             sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' (Use default settings)';
             InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
             log(Format('%s %d',[sSubMenuCaption, LMenuIndex]));
             SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
             LMethodInfo:=TMethodInfo.Create;
             LMethodInfo.Method:=MSBuildWithDelphi_Default;
             LMethodInfo.Value1:=LCurrentDelphiVersionData;
             FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
             Inc(uIDNewItem);
             Inc(LMenuIndex);
             //ContainsItems:=True;

             InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
             inc(LMenuIndex);
             Break;
           end;

         end;
       end;
     end;

     if  MatchText(ExtractFileExt(FFileName),['.dproj']) and (InstalledDelphiVersions.Count>0) then
     begin
       sdv:=GetDelphiVersions(FFileName);
       if Length(sdv)>0 then
       begin
         LMSBuildDProj:=TMSBuildDProj.Create(FFileName);
         try

             for LCurrentDelphiVersion in sdv do
             for sPlatform in LMSBuildDProj.Platforms do
             begin
               Found:=False;

               LCurrentDelphiVersionData:=InstalledDelphiVersions.Items[0];

               for LCurrentDelphiVersionData in InstalledDelphiVersions do
                if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
                begin
                 Found:=True;
                 Break;
                end;

               if Found then
               begin
                 sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - Release)';
                 InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
                 log(Format('%s %d',[sSubMenuCaption, LMenuIndex]));

                 if StartsText('Win', sPlatform) then
                   SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['win'].Handle, BitmapsDict.Items['win'].Handle)
                 else
                 if StartsText('OSX', sPlatform) then
                   SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['osx'].Handle, BitmapsDict.Items['osx'].Handle)
                 else
                 if StartsText('IOS', sPlatform) then
                   SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['ios'].Handle, BitmapsDict.Items['ios'].Handle);

                 LMethodInfo:=TMethodInfo.Create;
                 LMethodInfo.Method:=MSBuildWithDelphi;
                 LMethodInfo.Value1:=LCurrentDelphiVersionData;
                 LMethodInfo.Value2:=sPlatform;
                 LMethodInfo.Value3:='release';
                 FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                 Inc(uIDNewItem);
                 Inc(LMenuIndex);

                 sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - Debug)';
                 InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
                 log(Format('%s %d',[sSubMenuCaption, LMenuIndex]));

                 if StartsText('Win', sPlatform) then
                   SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['win'].Handle, BitmapsDict.Items['win'].Handle)
                 else
                 if StartsText('OSX', sPlatform) then
                   SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['osx'].Handle, BitmapsDict.Items['osx'].Handle)
                 else
                 if StartsText('IOS', sPlatform) then
                   SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['ios'].Handle, BitmapsDict.Items['ios'].Handle);

                 LMethodInfo:=TMethodInfo.Create;
                 LMethodInfo.Method:=MSBuildWithDelphi;
                 LMethodInfo.Value1:=LCurrentDelphiVersionData;
                 LMethodInfo.Value2:=sPlatform;
                 LMethodInfo.Value3:='debug';
                 FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                 Inc(uIDNewItem);
                 Inc(LMenuIndex);

                 //ContainsItems:=True;
               end;
             end;

         finally
           LMSBuildDProj.Free;
         end;
       end;
     end;

    //uId_menuitem := GetMenuItemID(LSubMenu, LMenuIndex);
                            {
    LMenuInfo.cbSize := sizeof(LMenuInfo);
    LMenuInfo.fMask  := MIIM_TYPE;
    LMenuInfo.dwTypeData := Buffer;
    LMenuInfo.cch := SizeOf(Buffer);
    if GetMenuItemInfo(Menu, LMenuIndex, True, LMenuInfo) then
    begin
      log('GetMenuItemInfo ok '+IntToStr(LMenuInfo.fType));
      if (LMenuInfo.fType and MFT_SEPARATOR) = MFT_SEPARATOR then
      else
      begin
        log('adding separator');
        InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
        inc(LMenuIndex);
      end;
    end
    else
      log(SysErrorMessage(GetLastError));
                                  }
     InsertMenu(LSubMenu, LMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('About'));
     SetMenuItemBitmaps(LSubMenu, LMenuIndex, MF_BYPOSITION, BitmapsDict.Items['logo'].Handle, BitmapsDict.Items['logo'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUI;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LMenuIndex);

      ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
      LMenuItem.cbSize := SizeOf(TMenuItemInfo);
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := FMenuItemIndex;
      LMenuItem.hSubMenu := LSubMenu;
      LMenuItem.dwTypeData := PWideChar(LMenuCaption);
      LMenuItem.cch := Length(LMenuCaption);
      InsertMenuItem(Menu, indexMenu, True, LMenuItem);
      SetMenuItemBitmaps(Menu, indexMenu, MF_BYPOSITION, BitmapsDict.Items['logo'].Handle, BitmapsDict.Items['logo'].Handle);

      log('uIDNewItem-idCmdFirst '+IntToStr(uIDNewItem-idCmdFirst));
      Result := MakeResult(SEVERITY_SUCCESS, 0, uIDNewItem-idCmdFirst);

end;

function TDelphiDevShellToolsContextMenu.ShellExtInitialize(pidlFolder: PItemIDList;
  lpdobj: IDataObject; hKeyProgID: HKEY): HResult;
var
  formatetcIn : TFormatEtc;
  medium      : TStgMedium;
  LFileName   : Array [0 .. MAX_PATH] of Char;
begin
  Result := E_FAIL;

  if lpdobj = nil then
    Exit;

  formatetcIn.cfFormat := CF_HDROP;
  formatetcIn.ptd := nil;
  formatetcIn.dwAspect := DVASPECT_CONTENT;
  formatetcIn.lindex := -1;
  formatetcIn.tymed := TYMED_HGLOBAL;

  if lpdobj.GetData(formatetcIn, medium) <> S_OK then
    Exit;

  if DragQueryFile(medium.hGlobal, $FFFFFFFF, nil, 0) = 1 then
  begin
    SetLength(FFileName, MAX_PATH);
    DragQueryFile(medium.hGlobal, 0, @LFileName, SizeOf(LFileName));
    FFileName := LFileName;
    Result := NOERROR;
  end
  else
  begin
    FFileName := EmptyStr;
    Result := E_FAIL;
  end;
  ReleaseStgMedium(medium);
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

initialization
  log('initialization');
  TDelphiDevShellObjectFactory.Create(ComServer, TDelphiDevShellToolsContextMenu, CLASS_DelphiDevShellToolsContextMenu, ciMultiInstance, tmApartment);
  InstalledDelphiVersions:=TObjectList<TDelphiVersionData>.Create;
  FillListDelphiVersions(InstalledDelphiVersions);

  BitmapsDict:=TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);

  BitmapsDict.Add('logo',TBitmap.Create);

  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['logo'].LoadFromResourceName(HInstance,'logo13')
  else
  BitmapsDict.Items['logo'].LoadFromResourceName(HInstance,'logo');
  MakeBitmapMenuTransparent(BitmapsDict.Items['logo']);

  BitmapsDict.Add('notepad',TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['notepad'].LoadFromResourceName(HInstance,'notepad13')
  else
  BitmapsDict.Items['notepad'].LoadFromResourceName(HInstance,'notepad');
  MakeBitmapMenuTransparent(BitmapsDict.Items['notepad']);

  BitmapsDict.Add('cmd',TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['cmd'].LoadFromResourceName(HInstance,'cmd13')
  else
  BitmapsDict.Items['cmd'].LoadFromResourceName(HInstance,'cmd');
  MakeBitmapMenuTransparent(BitmapsDict.Items['cmd']);

  BitmapsDict.Add('copy',TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['copy'].LoadFromResourceName(HInstance,'copy13')
  else
  BitmapsDict.Items['copy'].LoadFromResourceName(HInstance,'copy');
  MakeBitmapMenuTransparent(BitmapsDict.Items['copy']);

  BitmapsDict.Add('osx',TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['osx'].LoadFromResourceName(HInstance,'osx13')
  else
  BitmapsDict.Items['osx'].LoadFromResourceName(HInstance,'osx');
  MakeBitmapMenuTransparent(BitmapsDict.Items['osx']);

  BitmapsDict.Add('ios',TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['ios'].LoadFromResourceName(HInstance,'ios13')
  else
  BitmapsDict.Items['ios'].LoadFromResourceName(HInstance,'ios');
  MakeBitmapMenuTransparent(BitmapsDict.Items['ios']);

  BitmapsDict.Add('logo',TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['logo'].LoadFromResourceName(HInstance,'win13')
  else
  BitmapsDict.Items['win'].LoadFromResourceName(HInstance,'win');
  MakeBitmapMenuTransparent(BitmapsDict.Items['win']);

  BitmapsDict.Add('delphi',TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['delphi'].LoadFromResourceName(HInstance,'delphi13')
  else
  BitmapsDict.Items['delphi'].LoadFromResourceName(HInstance,'delphi');
  MakeBitmapMenuTransparent(BitmapsDict.Items['delphi']);

  BitmapsDict.Add('delphig',TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
  BitmapsDict.Items['delphig'].LoadFromResourceName(HInstance,'delphig13')
  else
  BitmapsDict.Items['delphig'].LoadFromResourceName(HInstance,'delphig');
  MakeBitmapMenuTransparent(BitmapsDict.Items['delphig']);
finalization
  BitmapsDict.Free;
  InstalledDelphiVersions.Free;
  log('finalization');
end.
