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
  uDelphiVersions,
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
    FFileName, FFileExt: string;
    DProjectVersion : SetDelphiVersions;

    FMenuItemIndex: UINT;
    FMethodsDict : TObjectDictionary<Integer, TMethodInfo>;
    procedure OpenWithDelphi(Info : TMethodInfo);
    procedure OpenRADStudio(Info : TMethodInfo);
    //procedure BuildWithDelphi(Info : TMethodInfo);
    procedure MSBuildWithDelphi_Default(Info : TMethodInfo);
    procedure MSBuildWithDelphi(Info : TMethodInfo);
    procedure OpenWithNotepad(Info : TMethodInfo);
    procedure OpenWithApp(Info : TMethodInfo);
    procedure OpenCmdHere(Info : TMethodInfo);
    procedure CopyPathClipboard(Info : TMethodInfo);
    procedure CopyFileNameClipboard(Info : TMethodInfo);
    procedure OpenGUI(Info : TMethodInfo);
    procedure OpenRADCmd(Info : TMethodInfo);
    procedure FormatSourceRAD(Info : TMethodInfo);
    procedure TouchRAD(Info : TMethodInfo);

    procedure AddCommonTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddOpenRADCmdTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddFormatCodeRADTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddTouchRADTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddMSBuildRAD_SpecificTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddMSBuildRAD_AllTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
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
  Vcl.GraphUtil,
  System.Classes,
  System.IOUtils,
  System.StrUtils,
  System.Win.ComServ,
  System.SysUtils,
  System.Win.Registry;

{$R images.res}

var
  InstalledDelphiVersions : TObjectList<TDelphiVersionData>;
  BitmapsDict    : TObjectDictionary<string, TBitmap>;
  ExeNameTxt, FriendlyAppNameTxt : string;

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

procedure TDelphiDevShellToolsContextMenu.OpenWithApp(Info : TMethodInfo);
begin
  ShellExecute(Info.hwnd, 'open', PChar(Info.Value1.AsString), PChar(FFileName) , nil , SW_SHOWNORMAL);
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

procedure TDelphiDevShellToolsContextMenu.OpenRADCmd(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  RsvarsPath, FilePath, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  log('OpenRADCmd');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  FilePath:=ExtractFilePath(FFileName);
  RsvarsPath  :=ExtractFilePath(LDelphiVersion.Path)+'rsvars.bat';
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('%s',[FilePath[1]+':']));
    BatchFile.Add(Format('cd "%s"',[FilePath]));
    BatchFile.Add('cls');
    BatchFile.Add(Format('call "%s"',[RsvarsPath]));
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

procedure TDelphiDevShellToolsContextMenu.FormatSourceRAD(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  FormatterPath, Params, BatchFileName : string;
  BatchFile : TStrings;
begin
  log('FormatSourceRAD');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  FormatterPath:=ExtractFilePath(LDelphiVersion.Path)+'formatter.exe';
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('"%s" -b -delphi "%s"', [FormatterPath, FFileName]));
    BatchFile.Add('Pause');
    BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
    BatchFile.SaveToFile(BatchFileName);
    Params:='/C "'+BatchFileName+'"';
    ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
  finally
    BatchFile.Free;
  end;
end;

procedure TDelphiDevShellToolsContextMenu.TouchRAD(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  TouchPath, Params, BatchFileName : string;
  BatchFile : TStrings;
begin
  log('TouchRAD');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  TouchPath:=ExtractFilePath(LDelphiVersion.Path)+'touch.exe';
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('"%s" "%s"', [TouchPath, FFileName]));
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

procedure TDelphiDevShellToolsContextMenu.AddCommonTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  LMethodInfo : TMethodInfo;
begin
   if not MatchText(FFileExt, SupportedExts) then exit;

     InsertMenu(hMenu, MenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy file path to clipboard'));
     SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyPathClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(MenuIndex);

     InsertMenu(hMenu, MenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy full filename (Path + FileName) to clipboard'));
     SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyFileNameClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(MenuIndex);

     InsertMenu(hMenu, MenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open In Notepad'));
     SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['notepad'].Handle, BitmapsDict.Items['notepad'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenWithNotepad;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(MenuIndex);

     try
       if (ExeNameTxt<>'') and (not SameText('notepad.exe', ExtractFileName(ExeNameTxt))) then
       begin
           log(ExtractFileName(ExeNameTxt));
           InsertMenu(hMenu, MenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open In '+FriendlyAppNameTxt));
           if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
            SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['txt13'].Handle, BitmapsDict.Items['txt13'].Handle)
           else
            SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['txt'].Handle, BitmapsDict.Items['txt'].Handle);
           LMethodInfo:=TMethodInfo.Create;
           LMethodInfo.Method:=OpenWithApp;
           LMethodInfo.Value1:=ExeNameTxt;
           FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
           Inc(uIDNewItem);
           Inc(MenuIndex);
       end;

     except
       on  E : Exception do
       log('GetAssocAppByExt '+E.Message);
     end;

     InsertMenu(hMenu, MenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open cmd here'));
     SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['cmd'].Handle, BitmapsDict.Items['cmd'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenCmdHere;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(MenuIndex);

     InsertMenu(hMenu, MenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
     inc(MenuIndex);
     Inc(uIDNewItem);

end;

procedure TDelphiDevShellToolsContextMenu.AddOpenRADCmdTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenuIndex : Integer;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
  if not MatchText(FFileExt, SupportedExts) then exit;

    //Open RadStudio Command Prompt Here
    Found:=false;
    for LCurrentDelphiVersionData in InstalledDelphiVersions do
     if LCurrentDelphiVersionData.Version>=Delphi2007 then
     begin
      Found:=True;
      Break;
     end;

    if Found then
    begin
      LSubMenuIndex :=0;
      LSubMenu   := CreatePopupMenu;
      sSubMenuCaption:='Open RAD Studio Command Prompt Here';

      ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
      LMenuItem.cbSize := SizeOf(TMenuItemInfo);
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := FMenuItemIndex;
      LMenuItem.hSubMenu := LSubMenu;
      LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
      LMenuItem.cch := Length(sSubMenuCaption);
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['radcmd'].Handle, BitmapsDict.Items['radcmd'].Handle);
      Inc(uIDNewItem);
      Inc(MenuIndex);

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
        InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' Command Prompt'));
        if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap13.Handle, LCurrentDelphiVersionData.Bitmap13.Handle)
        else
         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=OpenRADCmd;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;
    end;

end;

procedure TDelphiDevShellToolsContextMenu.AddFormatCodeRADTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenuIndex : Integer;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
  if not MatchText(FFileExt, SupportedExts) then exit;

    //FormatCode
    Found:=False;
    for LCurrentDelphiVersionData in InstalledDelphiVersions do
    if LCurrentDelphiVersionData.Version>=Delphi2010 then
    begin
      Found:=True;
      Break;
    end;

    if Found then
    begin
      LSubMenuIndex :=0;
      LSubMenu   := CreatePopupMenu;
      sSubMenuCaption:='Format Sorce Code';

      ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
      LMenuItem.cbSize := SizeOf(TMenuItemInfo);
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := FMenuItemIndex;
      LMenuItem.hSubMenu := LSubMenu;
      LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
      LMenuItem.cch := Length(sSubMenuCaption);
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['format'].Handle, BitmapsDict.Items['format'].Handle);

      Inc(uIDNewItem);
      Inc(MenuIndex);

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=Delphi2010 then
       begin
        InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' - Formatter.exe'));
        if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap13.Handle, LCurrentDelphiVersionData.Bitmap13.Handle)
        else
         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);

        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=FormatSourceRAD;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;
    end;
end;

procedure TDelphiDevShellToolsContextMenu.AddTouchRADTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenuIndex : Integer;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
  if not MatchText(FFileExt, SupportedExts) then exit;

    //Touch
    Found:=False;
    for LCurrentDelphiVersionData in InstalledDelphiVersions do
    if LCurrentDelphiVersionData.Version>=Delphi2007 then
    begin
      Found:=True;
      Break;
    end;

    if Found then
    begin
      LSubMenuIndex :=0;
      LSubMenu   := CreatePopupMenu;
      sSubMenuCaption:='Run Touch';

      ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
      LMenuItem.cbSize := SizeOf(TMenuItemInfo);
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := FMenuItemIndex;
      LMenuItem.hSubMenu := LSubMenu;
      LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
      LMenuItem.cch := Length(sSubMenuCaption);
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['touch'].Handle, BitmapsDict.Items['touch'].Handle);

      Inc(uIDNewItem);
      Inc(MenuIndex);

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
        InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' - Touch.exe'));
        if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap13.Handle, LCurrentDelphiVersionData.Bitmap13.Handle)
        else
         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);

        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=TouchRAD;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;
    end;

end;

procedure TDelphiDevShellToolsContextMenu.AddMSBuildRAD_SpecificTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LCurrentDelphiVersion      : TDelphiVersions;
  sPlatform, sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
  LMSBuildDProj : TMSBuildDProj;
begin
  if not MatchText(FFileExt, SupportedExts) then exit;

     if (InstalledDelphiVersions.Count>0) then
     begin
       if Length(DProjectVersion)>0 then
       begin
         LMSBuildDProj:=TMSBuildDProj.Create(FFileName);
         try

             for LCurrentDelphiVersion in DProjectVersion do
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
                 InsertMenu(hMenu, MenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
                 log(Format('%s %d',[sSubMenuCaption, MenuIndex]));

                 if StartsText('Win', sPlatform) then
                   SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['win'].Handle, BitmapsDict.Items['win'].Handle)
                 else
                 if StartsText('OSX', sPlatform) then
                   SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['osx'].Handle, BitmapsDict.Items['osx'].Handle)
                 else
                 if StartsText('IOS', sPlatform) then
                   SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['ios'].Handle, BitmapsDict.Items['ios'].Handle);

                 LMethodInfo:=TMethodInfo.Create;
                 LMethodInfo.Method:=MSBuildWithDelphi;
                 LMethodInfo.Value1:=LCurrentDelphiVersionData;
                 LMethodInfo.Value2:=sPlatform;
                 LMethodInfo.Value3:='release';
                 FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                 Inc(uIDNewItem);
                 Inc(MenuIndex);

                 sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - Debug)';
                 InsertMenu(hMenu, MenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
                 log(Format('%s %d',[sSubMenuCaption, MenuIndex]));

                 if StartsText('Win', sPlatform) then
                   SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['win'].Handle, BitmapsDict.Items['win'].Handle)
                 else
                 if StartsText('OSX', sPlatform) then
                   SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['osx'].Handle, BitmapsDict.Items['osx'].Handle)
                 else
                 if StartsText('IOS', sPlatform) then
                   SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['ios'].Handle, BitmapsDict.Items['ios'].Handle);

                 LMethodInfo:=TMethodInfo.Create;
                 LMethodInfo.Method:=MSBuildWithDelphi;
                 LMethodInfo.Value1:=LCurrentDelphiVersionData;
                 LMethodInfo.Value2:=sPlatform;
                 LMethodInfo.Value3:='debug';
                 FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                 Inc(uIDNewItem);
                 Inc(MenuIndex);

                 //ContainsItems:=True;
               end;
             end;

         finally
           LMSBuildDProj.Free;
         end;
       end;
     end;

end;

procedure TDelphiDevShellToolsContextMenu.AddMSBuildRAD_AllTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
var
  Found : Boolean;
  LSubMenuIndex : Integer;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LSubMenu: Winapi.Windows.HMENU;
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption : string;
  LMethodInfo : TMethodInfo;
begin
  if not MatchText(FFileExt, SupportedExts) then exit;

    Found:=False;
    for LCurrentDelphiVersionData in InstalledDelphiVersions do
    if LCurrentDelphiVersionData.Version>=Delphi2007 then
    begin
      Found:=True;
      Break;
    end;

    if Found then
    begin
      LSubMenuIndex :=0;
      LSubMenu   := CreatePopupMenu;
      sSubMenuCaption:='Run MSBUILD';

      ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
      LMenuItem.cbSize := SizeOf(TMenuItemInfo);
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := FMenuItemIndex;
      LMenuItem.hSubMenu := LSubMenu;
      LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
      LMenuItem.cch := Length(sSubMenuCaption);
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['msbuild'].Handle, BitmapsDict.Items['msbuild'].Handle);

      Inc(uIDNewItem);
      Inc(MenuIndex);

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
        InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('MSBuild with '+LCurrentDelphiVersionData.Name));
        if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap13.Handle, LCurrentDelphiVersionData.Bitmap13.Handle)
        else
         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);

        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=MSBuildWithDelphi_Default;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
        Inc(uIDNewItem);
        Inc(LSubMenuIndex);
       end;
    end;


end;

function TDelphiDevShellToolsContextMenu.QueryContextMenu(Menu: HMENU;
  indexMenu, idCmdFirst, idCmdLast, uFlags: UINT): HResult;
var
  LMenuItem: TMenuItemInfo;
  sSubMenuCaption, LMenuCaption : String;
  hSubMenu : HMENU;
  uIDNewItem: UINT;
  LCurrentDelphiVersionData  : TDelphiVersionData;
  LCurrentDelphiVersion      : TDelphiVersions;
  hSubMenuIndex  : Integer;
  {ContainsItems,} Found : Boolean;
  LMethodInfo : TMethodInfo;
                {
  uId_menuitem : Cardinal;
  LMenuInfo    : TMenuItemInfo;
  Buffer       : array [0..79] of char;}
begin
  FMenuItemIndex := indexMenu;

  if (uFlags and CMF_DEFAULTONLY)<> 0 then
    Exit(MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, 0))
  else
    LMenuCaption := 'Delphi Dev Shell Tools';

  if FMethodsDict=nil then
    FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues]);


  if not MatchText(FFileExt,['.pas','.dpr','.inc','.pp','.dproj', '.bdsproj','.dpk','.groupproj']) then
   Exit(MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, 0));

   if  MatchText(FFileExt ,['.dproj', '.bdsproj']) then
     DProjectVersion:=GetDelphiVersions(FFileName)
   else
     SetLength(DProjectVersion, 0);


    hSubMenu   := CreatePopupMenu;
    uIDNewItem := idCmdFirst;
    hSubMenuIndex := 0;
    AddCommonTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj', '.bdsproj','.dpk','.groupproj']);
    AddOpenRADCmdTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj', '.bdsproj','.dpk','.groupproj']);
    AddFormatCodeRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp']);
    AddTouchRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj', '.bdsproj','.dpk','.groupproj']);


     if  MatchText(FFileExt, ['.pas','.dpr','.inc','.pp','.dpk'])  then
     for LCurrentDelphiVersionData in InstalledDelphiVersions do
     begin
       sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
       InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
       log(Format('%s %d',[sSubMenuCaption, hSubMenuIndex]));
       if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
        SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap13.Handle, LCurrentDelphiVersionData.Bitmap13.Handle)
       else
        SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
       LMethodInfo:=TMethodInfo.Create;
       LMethodInfo.Method:=OpenWithDelphi;
       LMethodInfo.Value1:=LCurrentDelphiVersionData;
       FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
       Inc(uIDNewItem);
       Inc(hSubMenuIndex);
       //ContainsItems:=True;
     end
     else
     if  MatchText(FFileExt, ['.dproj', '.bdsproj']) then
     for LCurrentDelphiVersionData in InstalledDelphiVersions do
     begin

       Found:=False;
       for LCurrentDelphiVersion in DProjectVersion do
       if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
       begin
         sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name+' (Detected)';
         InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
         log(Format('%s %d',[sSubMenuCaption, hSubMenuIndex]));
         Found:=True;
         Break;
       end;

       if not Found then
       begin
         sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
         InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
         log(Format('%s %d',[sSubMenuCaption, hSubMenuIndex]));
       end;

       if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
        SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap13.Handle, LCurrentDelphiVersionData.Bitmap13.Handle)
       else
       SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
       LMethodInfo:=TMethodInfo.Create;
       LMethodInfo.Method:=OpenRADStudio;
       LMethodInfo.Value1:=LCurrentDelphiVersionData;
       FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
       Inc(uIDNewItem);
       Inc(hSubMenuIndex);
       //ContainsItems:=True;
     end;


     InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
     inc(hSubMenuIndex);

     if  MatchText(ExtractFileExt(FFileName),['.dproj']) then
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
             InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION or MF_GRAYED, uIDNewItem, PWideChar(sSubMenuCaption));
             if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
               SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphig13'].Handle, BitmapsDict.Items['delphig13'].Handle)
             else
               SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphig'].Handle, BitmapsDict.Items['delphig'].Handle);
             log(Format('%s %d',[sSubMenuCaption, hSubMenuIndex]));
             Inc(uIDNewItem);
             Inc(hSubMenuIndex);
         end
         else
         for LCurrentDelphiVersionData in InstalledDelphiVersions do
         begin

           for LCurrentDelphiVersion in DProjectVersion do
           if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
           begin
             sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' (Use default settings)';
             InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
             log(Format('%s %d',[sSubMenuCaption, hSubMenuIndex]));
             if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
              SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap13.Handle, LCurrentDelphiVersionData.Bitmap13.Handle)
             else
             SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
             LMethodInfo:=TMethodInfo.Create;
             LMethodInfo.Method:=MSBuildWithDelphi_Default;
             LMethodInfo.Value1:=LCurrentDelphiVersionData;
             FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
             Inc(uIDNewItem);
             Inc(hSubMenuIndex);
             //ContainsItems:=True;

             InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION or MF_SEPARATOR, 0, nil);
             inc(hSubMenuIndex);
             Break;
           end;

         end;
       end;
     end;

     AddMSBuildRAD_SpecificTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj']);
     AddMSBuildRAD_AllTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj', '.groupproj']);


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


     InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('About'));
     SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['logo'].Handle, BitmapsDict.Items['logo'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUI;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(hSubMenuIndex);

      ZeroMemory(@LMenuItem, SizeOf(TMenuItemInfo));
      LMenuItem.cbSize := SizeOf(TMenuItemInfo);
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := FMenuItemIndex;
      LMenuItem.hSubMenu := hSubMenu;
      LMenuItem.dwTypeData := PWideChar(LMenuCaption);
      LMenuItem.cch := Length(LMenuCaption);
      InsertMenuItem(Menu, indexMenu, True, LMenuItem);
      SetMenuItemBitmaps(Menu, indexMenu, MF_BYPOSITION, BitmapsDict.Items['logo'].Handle, BitmapsDict.Items['logo'].Handle);

      log('uIDNewItem-idCmdFirst '+IntToStr(uIDNewItem-idCmdFirst));
      Result := MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, uIDNewItem-idCmdFirst);
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
    Result := NOERROR;
  end
  else
  begin
    FFileName := EmptyStr;
    FFileExt  := EmptyStr;
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

procedure RegisterBitmap(const Name, Name13 : string);
begin
  BitmapsDict.Add(Name,TBitmap.Create);
  if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
   BitmapsDict.Items[Name].LoadFromResourceName(HInstance,Name13)
  else
   BitmapsDict.Items[Name].LoadFromResourceName(HInstance,Name);
  MakeBitmapMenuTransparent(BitmapsDict.Items[Name]);
end;

initialization
  log('initialization');
  TDelphiDevShellObjectFactory.Create(ComServer, TDelphiDevShellToolsContextMenu, CLASS_DelphiDevShellToolsContextMenu, ciMultiInstance, tmApartment);
  InstalledDelphiVersions:=TObjectList<TDelphiVersionData>.Create;
  FillListDelphiVersions(InstalledDelphiVersions);

  BitmapsDict:=TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);

  RegisterBitmap('logo', 'logo13');
  RegisterBitmap('notepad', 'notepad13');
  RegisterBitmap('cmd', 'cmd13');
  RegisterBitmap('copy', 'copy13');
  RegisterBitmap('osx', 'osx13');
  RegisterBitmap('ios', 'ios13');
  RegisterBitmap('win', 'win');
  RegisterBitmap('delphi', 'delphi13');
  RegisterBitmap('delphig', 'delphig13');
  RegisterBitmap('radcmd', 'radcmd13');
  RegisterBitmap('format', 'format13');
  RegisterBitmap('touch', 'touch13');
  RegisterBitmap('msbuild', 'msbuild13');

     try

       BitmapsDict.Add('txt',TBitmap.Create);
       BitmapsDict.Add('txt13',TBitmap.Create);
       GetAssocAppByExt('foo.txt', ExeNameTxt, FriendlyAppNameTxt);
       if (ExeNameTxt<>'') and TFile.Exists(ExeNameTxt)  then
       begin
         ExtractBitmapFile(BitmapsDict.Items['txt'], ExeNameTxt, SHGFI_SMALLICON);
         MakeBitmapMenuTransparent(BitmapsDict.Items['txt']);
         ScaleImage( BitmapsDict.Items['txt'], BitmapsDict.Items['txt13'], 0.81);
       end;
     except
       on  E : Exception do
       log('GetAssocAppByExt '+E.Message);
     end;

finalization
  BitmapsDict.Free;
  InstalledDelphiVersions.Free;
  log('finalization');
end.