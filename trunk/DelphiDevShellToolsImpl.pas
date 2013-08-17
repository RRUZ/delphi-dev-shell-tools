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
{$DEFINE ENABLELOG}

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
    procedure BuildWithDelphi(Info : TMethodInfo);
    procedure MSBuildWithDelphi_Default(Info : TMethodInfo);
    procedure MSBuildWithDelphi(Info : TMethodInfo);
    procedure OpenWithNotepad(Info : TMethodInfo);
    procedure OpenCmdHere(Info : TMethodInfo);
    procedure CopyPathClipboard(Info : TMethodInfo);
    procedure CopyFileNameClipboard(Info : TMethodInfo);
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

procedure TDelphiDevShellToolsContextMenu.BuildWithDelphi(Info : TMethodInfo);//incomplete
var
  LDelphiVersion  : TDelphiVersionData;
  CompilerPath, Params, BatchFileName : string;
  BatchFile : TStrings;
begin
  log('BuildWithDelphi');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  CompilerPath:=ExtractFilePath(LDelphiVersion.Path)+'DCC32.exe';
  //Params:=Format('/K "%s" -B -NSsystem;vcl;Winapi;System.Win "%s"',[CompilerPath, FFileName]);
  //log('BuildWithDelphi cmd.exe '+Params);
  //ShellExecute(Info.hwnd, 'open', PChar('"'+CompilerPath+'"'), PChar(Format('-B -NSsystem;vcl;Winapi;System.Win "%s"',[FFileName])) , nil , SW_SHOWNORMAL);
  //ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('"%s" -B -NSsystem;vcl;Winapi;System.Win "%s"',[CompilerPath, FFileName]));
    BatchFile.Add('Pause');
    BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
    BatchFile.SaveToFile(BatchFileName);
    Params:='/C "'+BatchFileName+'"';
    ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
  finally
    BatchFile.Free;
  end;
end;

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


function TDelphiDevShellToolsContextMenu.GetCommandString(idCmd: UINT_PTR; uFlags: UINT;
  pwReserved: PUINT; pszName: LPSTR; cchMax: UINT): HResult;
begin
  Result := E_INVALIDARG;
end;

function TDelphiDevShellToolsContextMenu.InvokeCommand(var lpici: TCMInvokeCommandInfo): HResult;
var
  LItemMenuIndex: Word;
begin
  Result := E_FAIL;
  log('InvokeCommand lpVerb '+IntToStr(Integer(lpici.lpVerb)));
  if HiWord(Integer(lpici.lpVerb)) <> 0 then
    Exit;

  LItemMenuIndex := LoWord(Integer(lpici.lpVerb));
  log('InvokeCommand '+IntToStr(LItemMenuIndex));
  if FMethodsDict.ContainsKey(LItemMenuIndex) then
  begin
    log('InvokeCommand Exec');
    FMethodsDict.Items[LItemMenuIndex].hwnd:=lpici.hwnd;
    FMethodsDict.Items[LItemMenuIndex].Method(FMethodsDict.Items[LItemMenuIndex]);
    Result:=NOERROR;
  end;
end;


function TDelphiDevShellToolsContextMenu.QueryContextMenu(Menu: HMENU;
  indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult;
var
  LMenuItem: TMenuItemInfo;
  LMenuCaption, sPlatform: String;
  LSubMenu: HMENU;
  uIDNewItem: UINT;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LCurrentDelphiVersion      : TDelphiVersions;
  LIndex : Integer;
  ContainsItems, Found : Boolean;
  LMethodInfo : TMethodInfo;
  sdv : SetDelphiVersions;
  LMSBuildDProj : TMSBuildDProj;
begin
  ContainsItems:=False;
  FMenuItemIndex := indexMenu;

  if (uFlags = CMF_NORMAL) or ((uFlags and CMF_EXPLORE) = CMF_EXPLORE) then
    LMenuCaption := 'Delphi Dev Shell Tools'
  else
    Result := E_FAIL;

  if FMethodsDict=nil then
    FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues]);

  if Result <> E_FAIL then
  begin
    LSubMenu := CreatePopupMenu;
    uIDNewItem := idCmdFirst;
    LIndex:=0;

     InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy file path to clipboard'));
     SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyPathClipboard;
     FMethodsDict.Add(LIndex, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LIndex);

     InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy full filename (Path + FileName) to clipboard'));
     SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyFileNameClipboard;
     FMethodsDict.Add(LIndex, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LIndex);

     InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open In Notepad'));
     SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['notepad'].Handle, BitmapsDict.Items['notepad'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenWithNotepad;
     FMethodsDict.Add(LIndex, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LIndex);

     InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open cmd here'));
     SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['cmd'].Handle, BitmapsDict.Items['cmd'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenCmdHere;
     FMethodsDict.Add(LIndex, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LIndex);
      {
     InsertMenu(LSubMenu, LIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
     inc(LIndex);
                 }
       if  MatchText(ExtractFileExt(FFileName),['.pas','.dpr','.inc','.pp'])  then
       for LCurrentDelphiVersionData in InstalledDelphiVersions do
       begin
         InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open with '+LCurrentDelphiVersionData.Name));
         SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=OpenWithDelphi;
         LMethodInfo.Value1:=LCurrentDelphiVersionData;
         FMethodsDict.Add(LIndex, LMethodInfo);
         Inc(uIDNewItem);
         Inc(LIndex);
         ContainsItems:=True;
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
             InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open with '+LCurrentDelphiVersionData.Name+' (Detected)'));
             Found:=True;
             Break;
           end;

         if not Found then
           InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open with '+LCurrentDelphiVersionData.Name));

         SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=OpenRADStudio;
         LMethodInfo.Value1:=LCurrentDelphiVersionData;
         FMethodsDict.Add(LIndex, LMethodInfo);
         Inc(uIDNewItem);
         Inc(LIndex);
         ContainsItems:=True;
       end;

              {
     if ContainsItems then
     begin
      InsertMenu(LSubMenu, LIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
      inc(LIndex);
     end;
          }
     if  MatchText(ExtractFileExt(FFileName),['.dproj']) then
     begin
       sdv:=GetDelphiVersions(FFileName);
       for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=TDelphiVersions.Delphi2007 then
       begin

         for LCurrentDelphiVersion in sdv do
         if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
         begin

           InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Run MSBuild with '+LCurrentDelphiVersionData.Name+' (Use default settings)'));
           SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
           LMethodInfo:=TMethodInfo.Create;
           LMethodInfo.Method:=MSBuildWithDelphi_Default;
           LMethodInfo.Value1:=LCurrentDelphiVersionData;
           FMethodsDict.Add(LIndex, LMethodInfo);
           Inc(uIDNewItem);
           Inc(LIndex);
           ContainsItems:=True;
                  {
           InsertMenu(LSubMenu, LIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
           inc(LIndex);  }
           Break;
         end;
                {
         if not Found then
           InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('MSBuild with '+LDelphiVersionData.Name));

         SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, LDelphiVersionData.Bitmap.Handle, LDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=MSBuildWithDelphi;
         LMethodInfo.Value1:=LDelphiVersionData;
         FMethodsDict.Add(LIndex, LMethodInfo);
         Inc(uIDNewItem);
         Inc(LIndex);
         ContainsItems:=True;

                 }

       end;
     end;

     if  MatchText(ExtractFileExt(FFileName),['.dproj']) then
     begin
       sdv:=GetDelphiVersions(FFileName);
       LMSBuildDProj:=TMSBuildDProj.Create(FFileName);
       try
           for LCurrentDelphiVersion in sdv do
           for sPlatform in LMSBuildDProj.Platforms do
           begin

             for LCurrentDelphiVersionData in InstalledDelphiVersions do
              if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
               Break;

             InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - Release)'));

             if StartsText('Win', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['win'].Handle, BitmapsDict.Items['win'].Handle)
             else
             if StartsText('OSX', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['osx'].Handle, BitmapsDict.Items['osx'].Handle)
             else
             if StartsText('IOS', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['ios'].Handle, BitmapsDict.Items['ios'].Handle);

             LMethodInfo:=TMethodInfo.Create;
             LMethodInfo.Method:=MSBuildWithDelphi;
             LMethodInfo.Value1:=LCurrentDelphiVersionData;
             LMethodInfo.Value2:=sPlatform;
             LMethodInfo.Value3:='release';
             FMethodsDict.Add(LIndex, LMethodInfo);
             Inc(uIDNewItem);
             Inc(LIndex);


             InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - Debug)'));

             if StartsText('Win', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['win'].Handle, BitmapsDict.Items['win'].Handle)
             else
             if StartsText('OSX', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['osx'].Handle, BitmapsDict.Items['osx'].Handle)
             else
             if StartsText('IOS', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, BitmapsDict.Items['ios'].Handle, BitmapsDict.Items['ios'].Handle);

             LMethodInfo:=TMethodInfo.Create;
             LMethodInfo.Method:=MSBuildWithDelphi;
             LMethodInfo.Value1:=LCurrentDelphiVersionData;
             LMethodInfo.Value2:=sPlatform;
             LMethodInfo.Value3:='debug';
             FMethodsDict.Add(LIndex, LMethodInfo);
             Inc(uIDNewItem);
             Inc(LIndex);

             ContainsItems:=True;
           end;

       finally
         LMSBuildDProj.Free;
       end;
     end;


      if ContainsItems then
      begin
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
      end
      else
      Result:=E_FAIL;

      log('uIDNewItem-idCmdFirst '+IntToStr(uIDNewItem-idCmdFirst));
      Result := MakeResult(SEVERITY_SUCCESS, 0, uIDNewItem-idCmdFirst);
  end;
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
  BitmapsDict.Items['logo'].LoadFromResourceName(HInstance,'logo');
  MakeBitmapMenuTransparent(BitmapsDict.Items['logo']);

  BitmapsDict.Add('notepad',TBitmap.Create);
  BitmapsDict.Items['notepad'].LoadFromResourceName(HInstance,'notepad');
  MakeBitmapMenuTransparent(BitmapsDict.Items['notepad']);

  BitmapsDict.Add('cmd',TBitmap.Create);
  BitmapsDict.Items['cmd'].LoadFromResourceName(HInstance,'cmd');
  MakeBitmapMenuTransparent(BitmapsDict.Items['cmd']);

  BitmapsDict.Add('copy',TBitmap.Create);
  BitmapsDict.Items['copy'].LoadFromResourceName(HInstance,'copy');
  MakeBitmapMenuTransparent(BitmapsDict.Items['copy']);

  BitmapsDict.Add('osx',TBitmap.Create);
  BitmapsDict.Items['osx'].LoadFromResourceName(HInstance,'osx');
  MakeBitmapMenuTransparent(BitmapsDict.Items['osx']);

  BitmapsDict.Add('ios',TBitmap.Create);
  BitmapsDict.Items['ios'].LoadFromResourceName(HInstance,'ios');
  MakeBitmapMenuTransparent(BitmapsDict.Items['ios']);

  BitmapsDict.Add('win',TBitmap.Create);
  BitmapsDict.Items['win'].LoadFromResourceName(HInstance,'win');
  MakeBitmapMenuTransparent(BitmapsDict.Items['win']);

finalization
  BitmapsDict.Free;
  InstalledDelphiVersions.Free;

end.
