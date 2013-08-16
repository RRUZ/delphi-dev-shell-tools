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
   Method : procedure(Info : TMethodInfo) of object;
  end;

  TDelphiDevShellToolsContextMenu = class(TAutoObject, IDelphiDevShellToolsContextMenu, IShellExtInit, IContextMenu)
  private
    FFileName: string;
    FMenuItemIndex: UINT;
    FMethodsDict : TObjectDictionary<Integer, TMethodInfo>;
    procedure OpenWithDelphi(Info : TMethodInfo);
    procedure BuildWithDelphi(Info : TMethodInfo);
    procedure MSBuildWithDelphi(Info : TMethodInfo);
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
  Graphics,
  Classes,
  uDelphiVersions,
  System.IOUtils,
  System.StrUtils,
  System.Win.ComServ,
  System.SysUtils,
  System.Win.Registry;

{$R images.res}

var
  DelphiVersions : TObjectList<TDelphiVersionData>;
  MainIcon       : TBitmap;

procedure log(const msg: string);
begin
   TFile.AppendAllText(IncludeTrailingPathDelimiter(GetTempDirectory)+'shelllog.txt', FormatDateTime('hh:nn:ss.zzz',Now)+' '+msg+sLineBreak);
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

procedure TDelphiDevShellToolsContextMenu.MSBuildWithDelphi(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  RsvarsPath, CompilerPath, Params, BatchFileName : string;
  BatchFile : TStrings;
begin
  log('MSBuildWithDelphi');
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
  LMenuCaption: String;
  LSubMenu: HMENU;
  uIDNewItem: UINT;
  LDelphiVersionData  : TDelphiVersionData;
  LDelphiVersion      : TDelphiVersions;
  LIndex: Integer;
  ContainsItems, Found : Boolean;
  LMethodInfo : TMethodInfo;
  sdv : SetDelphiVersions;
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

     if  MatchText(ExtractFileExt(FFileName),['.pas','.dpr','.inc','.pp']) then
     for LDelphiVersionData in DelphiVersions do
     begin
       InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open with '+LDelphiVersionData.Name));
       SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, LDelphiVersionData.Bitmap.Handle, LDelphiVersionData.Bitmap.Handle);
       LMethodInfo:=TMethodInfo.Create;
       LMethodInfo.Method:=OpenWithDelphi;
       LMethodInfo.Value1:=LDelphiVersionData;
       FMethodsDict.Add(LIndex, LMethodInfo);
       Inc(uIDNewItem);
       Inc(LIndex);
       ContainsItems:=True;
     end;

     if ContainsItems then
     begin
      InsertMenu(LSubMenu, LIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
      inc(LIndex);
     end;

     if  MatchText(ExtractFileExt(FFileName),['.dproj', '.bdsproj']) then
     begin
       sdv:=GetDelphiVersions(FFileName);
       for LDelphiVersionData in DelphiVersions do
       if LDelphiVersionData.Version>=TDelphiVersions.Delphi2007 then
       begin
         Found:=False;
         for LDelphiVersion in sdv do
         if LDelphiVersionData.Version=LDelphiVersion then
         begin
           InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('MSBuild With '+LDelphiVersionData.Name+' (Detected)'));
           Found:=True;
           Break;
         end;

         if not Found then
           InsertMenu(LSubMenu, LIndex, MF_BYPOSITION, uIDNewItem, PWideChar('MSBuild With '+LDelphiVersionData.Name));


         SetMenuItemBitmaps(LSubMenu, LIndex, MF_BYPOSITION, LDelphiVersionData.Bitmap.Handle, LDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=MSBuildWithDelphi;
         LMethodInfo.Value1:=LDelphiVersionData;
         FMethodsDict.Add(LIndex, LMethodInfo);
         Inc(uIDNewItem);
         Inc(LIndex);
         ContainsItems:=True;
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
        SetMenuItemBitmaps(Menu, indexMenu, MF_BYPOSITION, MainIcon.Handle, MainIcon.Handle);
      end
      else
      Result:=E_FAIL;

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
  DelphiVersions:=TObjectList<TDelphiVersionData>.Create;
  FillListDelphiVersions(DelphiVersions);
  MainIcon:=TBitmap.Create;
  MainIcon.LoadFromResourceName(HInstance,'logo');
  MakeBitmapMenuTransparent(MainIcon);
finalization
  MainIcon.Free;
  DelphiVersions.Free;

end.
