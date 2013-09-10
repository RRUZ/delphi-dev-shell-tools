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
  uMisc,
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
    FMenuItemIndex: UINT;
    FMethodsDict : TObjectDictionary<Integer, TMethodInfo>;
    FOwnerDrawId : UINT;

    procedure OpenWithDelphi(Info : TMethodInfo);
    procedure OpenRADStudio(Info : TMethodInfo);
    procedure MSBuildWithDelphi_Default(Info : TMethodInfo);
    procedure MSBuildWithDelphi(Info : TMethodInfo);

    procedure OpenWithNotepad(Info : TMethodInfo);
    procedure OpenWithApp(Info : TMethodInfo);
    procedure OpenCmdHere(Info : TMethodInfo);
    procedure CopyPathClipboard(Info : TMethodInfo);
    procedure CopyFileNameClipboard(Info : TMethodInfo);
    procedure CopyFileNameUrlClipboard(Info : TMethodInfo);
    procedure CopyFileNameUNCClipboard(Info : TMethodInfo);
    procedure CopyFileContentClipboard(Info : TMethodInfo);
    procedure OpenGUI(Info : TMethodInfo);
    procedure OpenGUICheckSum(Info : TMethodInfo);
    procedure OpenRADCmd(Info : TMethodInfo);


    procedure OpenVclStyle(Info : TMethodInfo);
    procedure PAClientTest(Info : TMethodInfo);
    procedure RADTools(Info : TMethodInfo);

    //Lazarus & FPC
    procedure OpenWithLazarus(Info : TMethodInfo);
    procedure BuildWithLazBuild(Info : TMethodInfo);
    procedure FPCTools(Info : TMethodInfo);
    //-------------------

    procedure AddCommonTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddOpenRADCmdTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddMSBuildRAD_SpecificTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddMSBuildRAD_AllTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddOpenWithDelphi(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddMSBuildPAClientTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddOpenVclStyleTask(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddCheckSumTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddRADStudioToolsTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    //Lazarus & FPC
    procedure AddLazarusTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    procedure AddFPCToolsTasks(hMenu : HMENU; var MenuIndex : Integer; var uIDNewItem :UINT; idCmdFirst : UINT; const SupportedExts: array of string);
    //-------------------
    procedure AddMenuSeparator(hMenu : HMENU; var MenuIndex : Integer);
    function ParseMacros(const Data : string;DelphiVersionData  : TDelphiVersionData) : string;
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
  ClipBrd,
  Vcl.Graphics,
  Vcl.GraphUtil,
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
  BitmapsDict    : TObjectDictionary<string, TBitmap>;
  Bitmaps32Dict    : TObjectDictionary<string, TBitmap>;
  ExeNameTxt, FriendlyAppNameTxt : string;
  LazarusInstalled : Boolean;
  Settings         : TSettings;
  FPCToolsExts     : TStringDynArray;
  DelphiToolsExts     : TStringDynArray;

  procedure RegisterBitmap32(const ResourceName: string); forward;


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
 try
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  log('OpenWithDelphi '+LDelphiVersion.Path+' '+Format('-pDelphi "%s"',[FFileName]));
  ShellExecute(Info.hwnd, 'open', PChar(LDelphiVersion.Path), PChar(Format('-pDelphi "%s"',[FFileName])) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenWithDelphi Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.OpenRADStudio(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  LFileName       : string;
begin
 try
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  if Info.Value2.AsString<>'' then
   LFileName:=Info.Value2.AsString
  else
   LFileName:=FFileName;

  log('OpenRADStudio '+LDelphiVersion.Path+' '+Format(' "%s" "%s"',[LFileName, Info.Value3.AsString]));
  ShellExecute(Info.hwnd, 'open', PChar(LDelphiVersion.Path), PChar(Format('"%s" "%s"',[LFileName, Info.Value3.AsString])) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenRADStudio Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

procedure TDelphiDevShellToolsContextMenu.OpenVclStyle(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  LVclStyleEditor : string;
begin
 try
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  if LDelphiVersion.Version=DelphiXE2 then
   LVclStyleEditor:=IncludeTrailingPathDelimiter(ExtractFilePath(LDelphiVersion.Path))+'VCLStyleTest.exe'
  else
   LVclStyleEditor:=IncludeTrailingPathDelimiter(ExtractFilePath(LDelphiVersion.Path))+'VCLStyleViewer.exe';

  log('OpenVclStyle '+LVclStyleEditor+' '+Format(' "%s"',[FFileName]));
  ShellExecute(Info.hwnd, 'open', PChar(LVclStyleEditor), PChar(Format('"%s"',[FFileName])) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenVclStyle Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.OpenWithLazarus(Info : TMethodInfo);
var
  LazarusIDE      : string;
begin
 try
  LazarusIDE:=Info.Value1.AsString;
  log('OpenWithLazarus '+LazarusIDE+' '+Format(' "%s"',[FFileName]));
  ShellExecute(Info.hwnd, 'open', PChar(LazarusIDE), PChar(Format('"%s"',[FFileName])) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenWithLazarus Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

procedure TDelphiDevShellToolsContextMenu.BuildWithLazBuild(Info : TMethodInfo);
var
  LazBuild, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    LazBuild:=IncludeTrailingPathDelimiter(Info.Value1.AsString)+'lazbuild.exe';
    log('BuildWithLazBuild '+LazBuild+' '+Format(' "%s"',[FFileName]));
    BatchFile:=TStringList.Create;
    try
      BatchFile.Add(Format('"%s" "%s"',[LazBuild, FFileName]));
      BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
      BatchFile.SaveToFile(BatchFileName);
      Params:='/K "'+BatchFileName+'"';
      ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.BuildWithLazBuild Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;


procedure TDelphiDevShellToolsContextMenu.OpenWithNotepad(Info : TMethodInfo);
begin
 try
  ShellExecute(Info.hwnd, 'open', 'C:\Windows\notepad.exe', PChar(FFileName) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenWithNotepad Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.PAClientTest(Info: TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  LPAClientApp, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
    LPAClientApp:=IncludeTrailingPathDelimiter(ExtractFilePath(LDelphiVersion.Path))+'PAClient.exe';
    log('PAClientTest '+LPAClientApp+' '+Format(' "%s"',[Info.Value2.AsString]));
    BatchFile:=TStringList.Create;
    try
      BatchFile.Add(Format('"%s" "%s"',[LPAClientApp, Info.Value2.AsString]));
      BatchFile.Add('Pause');
      BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
      BatchFile.SaveToFile(BatchFileName);
      Params:='/C "'+BatchFileName+'"';
      ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.PAClientTest Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;

end;
function TDelphiDevShellToolsContextMenu.ParseMacros(
  const Data: string; DelphiVersionData  : TDelphiVersionData): string;
begin
  Result:=Data;
  if Pos('$', Result)>0 then
  begin
    Result:=StringReplace(Result, '$FILENAME$', FFileName, [rfReplaceAll]);
    Result:=StringReplace(Result, '$NAME$', ExtractFileName(FFileName), [rfReplaceAll]);
    Result:=StringReplace(Result, '$ONLYNAME$', ChangeFileExt(ExtractFileName(FFileName),''), [rfReplaceAll]);
    Result:=StringReplace(Result, '$EXT$', FFileExt, [rfReplaceAll]);
    Result:=StringReplace(Result, '$PATH$', ExtractFilePath(FFileName), [rfReplaceAll]);
    if IsLazarusInstalled then
     Result:=StringReplace(Result, '$FPCPATH$', GetFPCPath, [rfReplaceAll]);
    if (DelphiVersionData<>nil) and (InstalledDelphiVersions.Count>0) then
     Result:=StringReplace(Result, '$BDSPATH$', ExtractFilePath(DelphiVersionData.Path), [rfReplaceAll]);
  end;
end;

procedure TDelphiDevShellToolsContextMenu.OpenWithApp(Info : TMethodInfo);
begin
 try
   ShellExecute(Info.hwnd, 'open', PChar(Info.Value1.AsString), PChar(FFileName) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenWithApp Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.CopyPathClipboard(Info : TMethodInfo);
var
  FilePath: string;
begin
 try
  FilePath:=ExtractFilePath(FFileName);
  Clipboard.AsText := FilePath;
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.CopyPathClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.CopyFileNameClipboard(Info : TMethodInfo);
begin
 try
  Clipboard.AsText := FFileName;
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.CopyFileNameClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;


procedure TDelphiDevShellToolsContextMenu.CopyFileNameUNCClipboard(
  Info: TMethodInfo);
begin
 try
  Clipboard.AsText := GetUNCNameEx(FFileName);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.CopyFileNameUNCClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;
procedure TDelphiDevShellToolsContextMenu.CopyFileNameUrlClipboard(
  Info: TMethodInfo);
begin
 try
  Clipboard.AsText := LocalPathToFileURL(FFileName);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.CopyFileNameUrlClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.CopyFileContentClipboard(Info : TMethodInfo);
begin
 try
  Clipboard.AsText := TFile.ReadAllText(FFileName);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.CopyFileContentClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.OpenCmdHere(Info : TMethodInfo);
var
  FilePath, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
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

      if Info.Value1.AsBoolean then
       ShellExecute(Info.hwnd, 'runas', PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL)
      else
       ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenCmdHere Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.OpenRADCmd(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  RsvarsPath, FilePath, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
 try
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
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenRADCmd Message %s  Trace %s',[E.Message, e.StackTrace]));
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
  LFileName, RsvarsPath, CompilerPath, Params, BatchFileName : string;
  BatchFile : TStrings;
begin
 try
  log('MSBuildWithDelphi_Default');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);

  if Info.Value2.AsString<>'' then
   LFileName:=Info.Value2.AsString
  else
   LFileName:=FFileName;

  RsvarsPath  :=ExtractFilePath(LDelphiVersion.Path)+'rsvars.bat';
  CompilerPath:=ExtractFilePath(LDelphiVersion.Path)+'DCC32.exe';
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('call "%s"',[RsvarsPath]));
    BatchFile.Add(Format('msbuild.exe "%s"', [LFileName]));
    BatchFile.Add('Pause');
    BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
    BatchFile.SaveToFile(BatchFileName);
    Params:='/C "'+BatchFileName+'"';
    ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
  finally
    BatchFile.Free;
  end;
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.MSBuildWithDelphi_Default Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

procedure TDelphiDevShellToolsContextMenu.MSBuildWithDelphi(Info : TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  LFileName, RsvarsPath, CompilerPath, Params, BatchFileName, sPlatform, sConfig : string;
  BatchFile : TStrings;
begin
 try
  log('MSBuildWithDelphi');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  sPlatform:=Info.Value2.AsString;
  sConfig:=Info.Value3.AsString;
  LFileName:=Info.Value4.AsString;

  RsvarsPath  :=ExtractFilePath(LDelphiVersion.Path)+'rsvars.bat';
  CompilerPath:=ExtractFilePath(LDelphiVersion.Path)+'DCC32.exe';
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('call "%s"',[RsvarsPath]));
    BatchFile.Add(Format('msbuild.exe "%s" /target:build /p:Platform=%s /p:config=%s', [LFileName, sPlatform, sConfig]));
    BatchFile.Add('Pause');
    BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
    BatchFile.SaveToFile(BatchFileName);
    Params:='/C "'+BatchFileName+'"';
    ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
  finally
    BatchFile.Free;
  end;
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.MSBuildWithDelphi Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;


  
procedure TDelphiDevShellToolsContextMenu.FPCTools(Info: TMethodInfo);
var
  BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    log('FPCTools');
    BatchFile:=TStringList.Create;
    try
      BatchFile.Text:=Info.Value1.AsString;
      BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
      BatchFile.SaveToFile(BatchFileName);
      Params:='/K "'+BatchFileName+'"';
      ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.FPCTools Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure TDelphiDevShellToolsContextMenu.RADTools(Info: TMethodInfo);
var
  BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    log('RADTools');
    BatchFile:=TStringList.Create;
    try
      BatchFile.Text:=Info.Value1.AsString;
      BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
      BatchFile.SaveToFile(BatchFileName);
      Params:='/K "'+BatchFileName+'"';
      ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.RADTools Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

procedure TDelphiDevShellToolsContextMenu.OpenGUI(Info : TMethodInfo);
begin
 try
  ShellExecute(Info.hwnd, 'open', PChar(IncludeTrailingPathDelimiter(ExtractFilePath(uMisc.GetModuleName))+'GUIDelphiDevShell.exe'), PChar(Info.Value1.AsString) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenGUI Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

procedure TDelphiDevShellToolsContextMenu.OpenGUICheckSum(Info: TMethodInfo);
begin
 try
  ShellExecute(Info.hwnd, 'open', PChar(IncludeTrailingPathDelimiter(ExtractFilePath(uMisc.GetModuleName))+'GUIDelphiDevShell.exe'), PChar(Info.Value1.AsString+' "'+Info.Value2.AsString+'"'), nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellToolsContextMenu.OpenGUI Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
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
  if FMSBuildDProj<>nil then
  begin
    FMSBuildDProj.Free;
    FMSBuildDProj:=nil;
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
end;


function TDelphiDevShellToolsContextMenu.MenuMessageHandler(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
const
  Dx = 20;
  Dy = 4;
var
  i, Lx,Ly :Integer;
  LCanvas: TCanvas;
  SaveIndex: Integer;
  LIcon : TIcon;
begin
log('MenuMessageHandler');
  case uMsg of
    WM_MEASUREITEM:
      if PMeasureItemStruct(lParam)^.itemID=FOwnerDrawId then
      begin
        with PMeasureItemStruct(lParam)^ do
        begin
          itemWidth :=250;
          itemHeight:=110;
            if (FMSBuildDProj<>nil) and (FMSBuildDProj.TargetPlatforms.Count>1) then
              itemHeight:= itemHeight+((18+Dy)*UINT(FMSBuildDProj.TargetPlatforms.Count));
        end;
        log('WM_MEASUREITEM '+IntToStr(PMeasureItemStruct(lParam)^.itemID));
      end;
    WM_DRAWITEM:
      if PDrawItemStruct(lParam)^.itemID=FOwnerDrawId then
      begin
        with PDrawItemStruct(lParam)^ do
        begin
          LCanvas := TCanvas.Create;
          try
            SaveIndex := SaveDC(hDC);
            try
              LCanvas.Handle := hDC;

              if itemState = ODS_SELECTED then
              begin
                LCanvas.Brush.Color := clHighlight;
                LCanvas.Font.Color := clHighlightText;
              end
              else
              begin
                LCanvas.Brush.Color := clMenu;
                LCanvas.Font.Color := clMenuText;
              end;

              Ly:=rcItem.Top  + Dy;
              Lx:=rcItem.Left + Dx;

              LCanvas.TextOut(Lx, Ly, 'Delphi Version (Detected)');
              LCanvas.TextOut(Lx+140, Ly, DelphiVersionsNames[FMSBuildDProj.DelphiVersion]);
              //LCanvas.Draw(rcItem.Left +1, Ly, BitmapsDict.Items['delphi2']);
              LIcon:=TIcon.Create;
              try
               LIcon.LoadFromResourceName(HInstance,'delphi_ico');
               DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
              finally
               LIcon.Free;
              end;


              //BitBlt(hDC, rcItem.Left +1, Ly, BitmapsDict.Items['delphi2'].Width, BitmapsDict.Items['delphi2'].Height, BitmapsDict.Items['delphi2'].Canvas.Handle, 0, 0, SRCCOPY);


              Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
              LCanvas.TextOut(Lx, Ly, 'Application Type');
              LCanvas.TextOut(Lx+140, Ly, FMSBuildDProj.AppType);

              Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
              LCanvas.TextOut(Lx, Ly, 'Framework Type');
              LCanvas.TextOut(Lx+140, Ly, FMSBuildDProj.FrameworkType);
              if SameText(FMSBuildDProj.FrameworkType,'FMX') then
                //LCanvas.Draw(rcItem.Left +1, Ly, BitmapsDict.Items['firemonkey'])
                //BitBlt(LCanvas.Handle, rcItem.Left +1, Ly, BitmapsDict.Items['firemonkey2'].Width, BitmapsDict.Items['firemonkey2'].Height, BitmapsDict.Items['firemonkey2'].Canvas.Handle, 0, 0, SRCCOPY)
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
                //BitBlt(LCanvas.Handle, rcItem.Left +1, Ly, BitmapsDict.Items['vcl2'].Width, BitmapsDict.Items['vcl2'].Height, BitmapsDict.Items['vcl2'].Canvas.Handle, 0, 0, SRCCOPY);
                //LCanvas.Draw(rcItem.Left +1, Ly, BitmapsDict.Items['vcl']);
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
              //LCanvas.Draw(rcItem.Left +1, Ly, BitmapsDict.Items['buildconf']);
              //BitBlt(LCanvas.Handle, rcItem.Left +1, Ly, BitmapsDict.Items['buildconf2'].Width, BitmapsDict.Items['buildconf2'].Height, BitmapsDict.Items['buildconf2'].Canvas.Handle, 0, 0, SRCCOPY);
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
               //LCanvas.Draw(rcItem.Left +1, Ly, BitmapsDict.Items['win'])
               //BitBlt(LCanvas.Handle, rcItem.Left +1, Ly, BitmapsDict.Items['win2'].Width, BitmapsDict.Items['win2'].Height, BitmapsDict.Items['win2'].Canvas.Handle, 0, 0, SRCCOPY)
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
               //LCanvas.Draw(rcItem.Left +1, Ly, BitmapsDict.Items['osx'])
               //BitBlt(LCanvas.Handle, rcItem.Left +1, Ly, BitmapsDict.Items['osx2'].Width, BitmapsDict.Items['osx2'].Height, BitmapsDict.Items['osx2'].Canvas.Handle, 0, 0, SRCCOPY)
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
               //LCanvas.Draw(rcItem.Left +1, Ly, BitmapsDict.Items['ios']);
               //BitBlt(LCanvas.Handle, rcItem.Left +1, Ly, BitmapsDict.Items['ios2'].Width, BitmapsDict.Items['ios2'].Height, BitmapsDict.Items['ios2'].Canvas.Handle, 0, 0, SRCCOPY);
              begin
                LIcon:=TIcon.Create;
                try
                 LIcon.LoadFromResourceName(HInstance,'ios_ico');
                 DrawIconEx(hDC,rcItem.Left +1, Ly,  LIcon.Handle, 16, 16,  0, 0, DI_NORMAL);
                finally
                 LIcon.Free;
                end;
              end;

              if (FMSBuildDProj<>nil) and (FMSBuildDProj.TargetPlatforms.Count>1) then
              begin
                Inc(Ly,LCanvas.TextHeight('Hg')+Dy);
                LCanvas.TextOut(Lx, Ly, 'Target Platforms');
                //LCanvas.Draw(rcItem.Left +1, Ly, BitmapsDict.Items['platforms2']);

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
                      //LCanvas.Draw(Lx+5, Ly, BitmapsDict.Items['win'])
                      //BitBlt(LCanvas.Handle, Lx+5, Ly, BitmapsDict.Items['win2'].Width, BitmapsDict.Items['win2'].Height, BitmapsDict.Items['win2'].Canvas.Handle, 0, 0, SRCCOPY)
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
                      //LCanvas.Draw(Lx+5, Ly, BitmapsDict.Items['osx'])
                      //BitBlt(LCanvas.Handle, Lx+5, Ly, BitmapsDict.Items['osx2'].Width, BitmapsDict.Items['osx2'].Height, BitmapsDict.Items['osx2'].Canvas.Handle, 0, 0, SRCCOPY)
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
                     //LCanvas.Draw(Lx+5, Ly, BitmapsDict.Items['ios']);
                     //BitBlt(LCanvas.Handle, Lx+5, Ly, BitmapsDict.Items['ios2'].Width, BitmapsDict.Items['ios2'].Height, BitmapsDict.Items['ios2'].Canvas.Handle, 0, 0, SRCCOPY);
                    begin
                      LIcon:=TIcon.Create;
                      try
                       LIcon.LoadFromResourceName(HInstance,'ios_ico');
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
        log('WM_DRAWITEM '+IntToStr(PDrawItemStruct(lParam)^.itemID));

      end;
  end;
  Result:=S_OK;
end;

//IContextMenu2
function TDelphiDevShellToolsContextMenu.HandleMenuMsg(uMsg: UINT; WParam: WPARAM; LParam: LPARAM): HResult; stdcall;
var
 res : Winapi.Windows.LPARAM;
begin
 log('HandleMenuMsg');
 Result:=MenuMessageHandler ( uMsg, wParam, lParam, res);
end;

//IContextMenu3
function TDelphiDevShellToolsContextMenu.HandleMenuMsg2(uMsg: UINT; wParam: WPARAM; lParam: LPARAM; var lpResult: LRESULT): HResult; stdcall;
begin
  log('HandleMenuMsg2');
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
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := FMenuItemIndex;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['checksum'].Handle, BitmapsDict.Items['checksum'].Handle);
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;


     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Calculate CRC32'));
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUICheckSum;
     LMethodInfo.Value1:='CRC32';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Calculate MD4'));
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUICheckSum;
     LMethodInfo.Value1:='MD4';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Calculate MD5'));
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUICheckSum;
     LMethodInfo.Value1:='MD5';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Calculate SHA1'));
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUICheckSum;
     LMethodInfo.Value1:='SHA1';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Calculate SHA-256'));
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUICheckSum;
     LMethodInfo.Value1:='SHA-256';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Calculate SHA-384'));
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUICheckSum;
     LMethodInfo.Value1:='SHA-384';
     LMethodInfo.Value2:=FFileName;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Calculate SHA-512'));
     //SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenGUICheckSum;
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
        LMenuItem.cbSize := SizeOf(TMenuItemInfo);
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := FMenuItemIndex;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['common'].Handle, BitmapsDict.Items['common'].Handle);
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;


     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy File Path to clipboard'));
     SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy_path'].Handle, BitmapsDict.Items['copy_path'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyPathClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy full FileName (Path + FileName) to clipboard'));
     SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy'].Handle, BitmapsDict.Items['copy'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyFileNameClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy FileName using URL format (file://...) to clipboard'));
     SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy_url'].Handle, BitmapsDict.Items['copy_url'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyFileNameUrlClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy FileName using UNC format (\\server-name\Shared...) to clipboard'));
     SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy_unc'].Handle, BitmapsDict.Items['copy_unc'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyFileNameUNCClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Copy File content to the clipboard'));
     SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['copy_content'].Handle, BitmapsDict.Items['copy_content'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=CopyFileContentClipboard;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);


     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open In Notepad'));
     SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['notepad'].Handle, BitmapsDict.Items['notepad'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenWithNotepad;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     try
       if (ExeNameTxt<>'') and (not SameText('notepad.exe', ExtractFileName(ExeNameTxt))) then
       begin
           log(ExtractFileName(ExeNameTxt));
           InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open In '+FriendlyAppNameTxt));
           SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['txt'].Handle, BitmapsDict.Items['txt'].Handle);
           LMethodInfo:=TMethodInfo.Create;
           LMethodInfo.Method:=OpenWithApp;
           LMethodInfo.Value1:=ExeNameTxt;
           FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
           Inc(uIDNewItem);
           Inc(LSubMenuIndex);
       end;

     except
       on  E : Exception do
       log('GetAssocAppByExt '+E.Message);
     end;

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open Command Line here'));
     SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['cmd'].Handle, BitmapsDict.Items['cmd'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenCmdHere;
     LMethodInfo.Value1:=False;
     FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
     Inc(uIDNewItem);
     Inc(LSubMenuIndex);

     InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open Command Line here as Administrator'));
     SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['shield'].Handle, BitmapsDict.Items['shield'].Handle);
     LMethodInfo:=TMethodInfo.Create;
     LMethodInfo.Method:=OpenCmdHere;
     LMethodInfo.Value1:=True;
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
      end
      else
      begin
        LSubMenuIndex := MenuIndex;
        LSubMenu      := hMenu;
      end;

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
        InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' Command Prompt'));
        SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=OpenRADCmd;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
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
        LMenuItem.cbSize := SizeOf(TMenuItemInfo);
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := FMenuItemIndex;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['fpc_tools'].Handle, BitmapsDict.Items['fpc_tools'].Handle);
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
              InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(ParseMacros(LClientDataSet.FieldByName('Menu').AsString, nil)));

              if not LClientDataSet.FieldByName('Image').IsNull then
              begin
                s:=LClientDataSet.FieldByName('Image').AsString;
                log(GetDevShellToolsImagesFolder+s);
                RegisterBitmap32(s);
                if Bitmaps32Dict.ContainsKey(s) then
                  SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, Bitmaps32Dict.Items[s].Handle, Bitmaps32Dict.Items[s].Handle);
              end;

              LMethodInfo:=TMethodInfo.Create;
              LMethodInfo.Method:=FPCTools;
              LMethodInfo.Value1:=ParseMacros(LClientDataSet.FieldByName('Script').AsString, nil);
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
          LMenuItem.cbSize := SizeOf(TMenuItemInfo);
          LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
          LMenuItem.fType := MFT_STRING;
          LMenuItem.wID := FMenuItemIndex;
          LMenuItem.hSubMenu := LSubMenu;
          LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
          LMenuItem.cch := Length(sSubMenuCaption);
          InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
          SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphi'].Handle, BitmapsDict.Items['delphi'].Handle);

          Inc(uIDNewItem);
          Inc(MenuIndex);
        end
        else
        begin
          LSubMenu:=hMenu;
          LSubMenuIndex:=MenuIndex;
        end;

          LFileName:=FFileName;

         if  (FMSBuildDProj<>nil) and (FMSBuildDProj.ValidData) then
         for LCurrentDelphiVersion in DProjectVersion do
         for sPlatform in FMSBuildDProj.TargetPlatforms do
         begin
           Found:=False;

           for sBuildConfiguration in FMSBuildDProj.BuildConfigurations do
           begin

             if SameText(sPlatform, FMSBuildDProj.DefaultPlatForm) and (SameText(sBuildConfiguration, FMSBuildDProj.DefaultConfiguration)) then
               sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - '+sBuildConfiguration+') - Default Configuration'
             else
               sSubMenuCaption:='Run MSBuild with '+LCurrentDelphiVersionData.Name+' ('+sPlatform+' - '+sBuildConfiguration+')';

             InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
             log(Format('%s %d',[sSubMenuCaption, LSubMenuIndex]));

             if StartsText('Win', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['win'].Handle, BitmapsDict.Items['win'].Handle)
             else
             if StartsText('OSX', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['osx'].Handle, BitmapsDict.Items['osx'].Handle)
             else
             if StartsText('IOS', sPlatform) then
               SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['ios'].Handle, BitmapsDict.Items['ios'].Handle);

             LMethodInfo:=TMethodInfo.Create;
             LMethodInfo.Method:=MSBuildWithDelphi;
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
          LMenuItem.cbSize := SizeOf(TMenuItemInfo);
          LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
          LMenuItem.fType := MFT_STRING;
          LMenuItem.wID := FMenuItemIndex;
          LMenuItem.hSubMenu := LSubMenu;
          LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
          LMenuItem.cch := Length(sSubMenuCaption);
          InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
          SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphi'].Handle, BitmapsDict.Items['delphi'].Handle);

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

                 InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
                 log(Format('%s %d',[sSubMenuCaption, LSubMenuIndex]));

                 if StartsText('Win', LPAClientProfile.Platform) then
                   SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['win'].Handle, BitmapsDict.Items['win'].Handle)
                 else
                 if StartsText('OSX', LPAClientProfile.Platform) then
                   SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['osx'].Handle, BitmapsDict.Items['osx'].Handle)
                 else
                 if StartsText('IOS', LPAClientProfile.Platform) then
                   SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['ios'].Handle, BitmapsDict.Items['ios'].Handle);

                 LMethodInfo:=TMethodInfo.Create;
                 LMethodInfo.Method:=PAClientTest;
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

    log('AddMSBuildRAD_AllTasks');
    Found:=False;
    for LCurrentDelphiVersionData in InstalledDelphiVersions do
    if (LCurrentDelphiVersionData.Version>=Delphi2007) and (  ((FMSBuildDProj <>nil) and (LCurrentDelphiVersionData.Version<>FMSBuildDProj.DelphiVersion)) or MatchText(FFileExt,['.groupproj','.proj'])) then
    begin
      Found:=True;
      Break;
    end;
    log('AddMSBuildRAD_AllTasks found '+BoolToStr(Found, True));

    if Found then
    begin
      if Settings.SubMenuMSBuildAnother then
      begin
        LSubMenuIndex :=0;
        LSubMenu   := CreatePopupMenu;
        sSubMenuCaption:='Run MSBUILD with another Delphi version';

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
      end
      else
      begin
        LSubMenuIndex:=MenuIndex;
        LSubMenu:=hMenu;
      end;

      for LCurrentDelphiVersionData in InstalledDelphiVersions do
       if (LCurrentDelphiVersionData.Version>=Delphi2007) and (((FMSBuildDProj <>nil) and (LCurrentDelphiVersionData.Version<>FMSBuildDProj.DelphiVersion)) or MatchText(FFileExt,['.groupproj','.proj'])) then
       begin
        InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('MSBuild with '+LCurrentDelphiVersionData.Name));
        SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=MSBuildWithDelphi_Default;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
        LMethodInfo.Value2:=EmptyStr;

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
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := FMenuItemIndex;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['vcl'].Handle, BitmapsDict.Items['vcl'].Handle);

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
        InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Use Viewer of '+LCurrentDelphiVersionData.Name));
        SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=OpenVclStyle;
        LMethodInfo.Value1:=LCurrentDelphiVersionData;
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
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := FMenuItemIndex;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['lazarusmenu'].Handle, BitmapsDict.Items['lazarusmenu'].Handle);
        Inc(uIDNewItem);
        Inc(MenuIndex);
      end
      else
      begin
         LSubMenuIndex:=MenuIndex;
         LSubMenu:=hMenu;
      end;

      InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Open with Lazarus IDE'));
      SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['lazarus'].Handle, BitmapsDict.Items['lazarus'].Handle);
      LMethodInfo:=TMethodInfo.Create;
      LMethodInfo.Method:=OpenWithLazarus;
      LMethodInfo.Value1:=GetLazarusIDEFileName;
      FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
      Inc(uIDNewItem);
      Inc(LSubMenuIndex);


      if MatchText(FFileExt, ['.lpi', '.lpk']) then
      begin
        InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Build with lazbuild'));
        SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['lazbuild'].Handle, BitmapsDict.Items['lazbuild'].Handle);
        LMethodInfo:=TMethodInfo.Create;
        LMethodInfo.Method:=BuildWithLazBuild;
        LMethodInfo.Value1:=GetLazarusIDEFolder;
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
      LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
      LMenuItem.fType := MFT_STRING;
      LMenuItem.wID := FMenuItemIndex;
      LMenuItem.hSubMenu := LSubMenu;
      LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
      LMenuItem.cch := Length(sSubMenuCaption);
      InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
      SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphi'].Handle, BitmapsDict.Items['delphi'].Handle);
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
       if LCurrentDelphiVersionData.Version>=Delphi2007 then
       begin
         Found:=False;
         for LCurrentDelphiVersion in DProjectVersion do
         if LCurrentDelphiVersionData.Version=LCurrentDelphiVersion then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name+' (Detected)';
           InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
           log(Format('%s %d',[sSubMenuCaption, LSubMenuIndex]));
           Found:=True;
           Break;
         end;

         if not Found then
         begin
           sSubMenuCaption:='Open with '+LCurrentDelphiVersionData.Name;
           InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
           log(Format('%s %d',[sSubMenuCaption, LSubMenuIndex]));
         end;

         SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
         LMethodInfo:=TMethodInfo.Create;
         LMethodInfo.Method:=OpenRADStudio;
         LMethodInfo.Value1:=LCurrentDelphiVersionData;
         LMethodInfo.Value2:=EmptyStr;
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
       InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(sSubMenuCaption));
       log(Format('%s %d',[sSubMenuCaption, LSubMenuIndex]));
       SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, LCurrentDelphiVersionData.Bitmap.Handle, LCurrentDelphiVersionData.Bitmap.Handle);
       LMethodInfo:=TMethodInfo.Create;
       LMethodInfo.Method:=OpenWithDelphi;
       LMethodInfo.Value1:=LCurrentDelphiVersionData;
       LMethodInfo.Value2:=EmptyStr;
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
        LMenuItem.fMask := MIIM_SUBMENU or MIIM_STRING or MIIM_ID;
        LMenuItem.fType := MFT_STRING;
        LMenuItem.wID := FMenuItemIndex;
        LMenuItem.hSubMenu := LSubMenu;
        LMenuItem.dwTypeData := PWideChar(sSubMenuCaption);
        LMenuItem.cch := Length(sSubMenuCaption);
        InsertMenuItem(hMenu, MenuIndex, True, LMenuItem);
        SetMenuItemBitmaps(hMenu, MenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphi'].Handle, BitmapsDict.Items['delphi'].Handle);
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
                InsertMenu(LSubMenu, LSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar(LCurrentDelphiVersionData.Name+' - '+ParseMacros(LClientDataSet.FieldByName('Menu').AsString, LCurrentDelphiVersionData)));

                  if not LClientDataSet.FieldByName('Image').IsNull then
                  begin
                    s:=LClientDataSet.FieldByName('Image').AsString;
                    log(GetDevShellToolsImagesFolder+s);
                    RegisterBitmap32(s);
                    if Bitmaps32Dict.ContainsKey(s) then
                      SetMenuItemBitmaps(LSubMenu, LSubMenuIndex, MF_BYPOSITION, Bitmaps32Dict.Items[s].Handle, Bitmaps32Dict.Items[s].Handle);
                  end;

                LMethodInfo:=TMethodInfo.Create;
                LMethodInfo.Method:=RADTools;
                LMethodInfo.Value1:=ParseMacros(LClientDataSet.FieldByName('Script').AsString, LCurrentDelphiVersionData);
                FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
                Inc(uIDNewItem);
                Inc(LSubMenuIndex);
               end;
             end;
             LClientDataSet.Next;
            end;

            AddMenuSeparator(LSubMenu, LSubMenuIndex);
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

procedure TDelphiDevShellToolsContextMenu.AddMenuSeparator(hMenu : HMENU; var MenuIndex : Integer);
var
  LMenuInfo    : TMenuItemInfo;
  Buffer       : array [0..79] of char;
begin
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
begin
 ReadSettings(Settings);
 FMenuItemIndex := indexMenu;

  if (uFlags and CMF_DEFAULTONLY)<> 0 then
    Exit(MakeResult(SEVERITY_SUCCESS, FACILITY_NULL, 0))
  else
    LMenuCaption := 'Delphi Dev Shell Tools';

  if FMethodsDict=nil then
    FMethodsDict:=TObjectDictionary<Integer, TMethodInfo>.Create([doOwnsValues]);


  if (not MatchText(FFileExt,[
     '.pas','.dpr','.inc','.pp','.proj','.dproj', '.bdsproj','.dpk','.groupproj','.rc','.dfm',
     '.lfm','.fmx','.vsf','.style','.lpi','.lpr','.lpk','.h','.ppu']))
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
       AddMenuSeparator(hSubMenu, hSubMenuIndex);
     end;


    //AddCommonTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj','.bdsproj','.dpk','.groupproj','.rc','.lfm','.dfm','.fmx','.lpi','.lpr','.lpk']);
    AddCommonTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.CommonTaskExt,','));
    AddMenuSeparator(hSubMenu, hSubMenuIndex);
    AddCheckSumTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.CheckSumExt,','));
    AddMenuSeparator(hSubMenu, hSubMenuIndex);
    AddOpenRADCmdTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj','.bdsproj','.dpk','.groupproj','.rc','.dfm','.fmx','.vsf','.style']);
    AddMenuSeparator(hSubMenu, hSubMenuIndex);
    //AddFormatCodeRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp']);
    //AddFormatCodeRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.FormatPascalExt,','));
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);
    //AddCompileRCTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.rc']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);
    AddOpenVclStyleTask(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.vsf']);
    AddMenuSeparator(hSubMenu, hSubMenuIndex);
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
             InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION or MF_GRAYED, uIDNewItem, PWideChar(sSubMenuCaption));
             if (TOSVersion.Major=5) and (TOSVersion.Minor=1) then
               SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphig13'].Handle, BitmapsDict.Items['delphig13'].Handle)
             else
               SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['delphig'].Handle, BitmapsDict.Items['delphig'].Handle);
             log(Format('%s %d',[sSubMenuCaption, hSubMenuIndex]));
             Inc(uIDNewItem);
             Inc(hSubMenuIndex);
         end;
       end;
     end;

    AddMenuSeparator(hSubMenu, hSubMenuIndex);

    AddMSBuildRAD_SpecificTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    AddMenuSeparator(hSubMenu, hSubMenuIndex);
    //AddAuditsCLITasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);


    AddMSBuildRAD_AllTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.groupproj','.dpr','.proj']);
    AddMenuSeparator(hSubMenu, hSubMenuIndex);
    AddMSBuildPAClientTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj','.dpr']);
    AddMenuSeparator(hSubMenu, hSubMenuIndex);

    //AddOpenWithDelphi(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.dproj', '.groupproj','.dpr','.pas','.inc','.pp','.dpk']);
    AddOpenWithDelphi(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.OpenDelphiExt,','));
    AddMenuSeparator(hSubMenu, hSubMenuIndex);

    AddRADStudioToolsTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, DelphiToolsExts);
    AddMenuSeparator(hSubMenu, hSubMenuIndex);

    if Settings.ActivateLazarus and LazarusInstalled then
    begin
      //AddLazarusTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.lpi','.pp','.inc','.pas','.lpk']);
      AddLazarusTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, SplitString(Settings.OpenLazarusExt,','));
      AddMenuSeparator(hSubMenu, hSubMenuIndex);

      AddFPCToolsTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, FPCToolsExts);
      AddMenuSeparator(hSubMenu, hSubMenuIndex);
    end;

    //AddTouchRADTasks(hSubMenu, hSubMenuIndex, uIDNewItem, idCmdFirst, ['.pas','.dpr','.inc','.pp','.dproj', '.bdsproj','.dpk','.groupproj']);
    //AddMenuSeparator(hSubMenu, hSubMenuIndex);


    InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Settings'));
    SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['settings'].Handle, BitmapsDict.Items['settings'].Handle);
    LMethodInfo:=TMethodInfo.Create;
    LMethodInfo.Method:=OpenGUI;
    LMethodInfo.Value1:='-settings';
    FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
    Inc(uIDNewItem);
    Inc(hSubMenuIndex);

    InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('Check for updates'));
    SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['updates'].Handle, BitmapsDict.Items['updates'].Handle);
    LMethodInfo:=TMethodInfo.Create;
    LMethodInfo.Method:=OpenGUI;
    LMethodInfo.Value1:='-update';
    FMethodsDict.Add(uIDNewItem-idCmdFirst, LMethodInfo);
    Inc(uIDNewItem);
    Inc(hSubMenuIndex);


    InsertMenu(hSubMenu, hSubMenuIndex, MF_BYPOSITION, uIDNewItem, PWideChar('About'));
    SetMenuItemBitmaps(hSubMenu, hSubMenuIndex, MF_BYPOSITION, BitmapsDict.Items['logo'].Handle, BitmapsDict.Items['logo'].Handle);
    LMethodInfo:=TMethodInfo.Create;
    LMethodInfo.Method:=OpenGUI;
    LMethodInfo.Value1:='-about';
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
  LProjName   : string;
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
    if FMSBuildDProj<>nil then
    begin
      FMSBuildDProj.Free;
      FMSBuildDProj:=nil;
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
    Result := NOERROR;
  end
  else
  begin
    if FMSBuildDProj<>nil then
    begin
      FMSBuildDProj.Free;
      FMSBuildDProj:=nil;
    end;
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
      //BitmapsDict.Items[LDictName].LoadFromResourceName(HInstance,ResourceName);
      //MakeBitmapMenuTransparent(BitmapsDict.Items[LDictName]);
    end
    else
    begin
      Factor:= CX/16;
      TempBitmap:=TBitmap.Create;
      try
        BitmapsDict.Add(LDictName,TBitmap.Create);
        //TempBitmap.LoadFromResourceName(HInstance,ResourceName);
        LPng:=TPngImage.Create;
        try
          LPng.LoadFromResourceName(HInstance, ResourceName);
          TempBitmap.Assign(LPng);
        finally
          LPng.Free;
        end;

        ScaleImage32(TempBitmap, BitmapsDict.Items[LDictName], Factor);
        //MakeBitmapMenuTransparent(BitmapsDict.Items[LDictName]);
      finally
        TempBitmap.Free;
      end;
    end;
 except
   on  E : Exception do
   log(Format('Message %s  Trace %s',[E.Message, e.StackTrace]));
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
  CX:=GetSystemMetrics(SM_CXMENUCHECK);
  s:=GetDevShellToolsImagesFolder+ResourceName;
  if (not Bitmaps32Dict.ContainsKey(ResourceName)) and FileExists(s) then
  begin
    LPicture := TPicture.Create;
    try
       LPicture.LoadFromFile(s);

       if CX>=16 then
       begin
        Bitmaps32Dict.Add(ResourceName, TBitmap.Create);
        Bitmaps32Dict.Items[ResourceName].Assign(LPicture.Graphic);
       end
       else
       begin
          Factor:= CX/16;
          TempBitmap:=TBitmap.Create;
          try
            Bitmaps32Dict.Add(ResourceName,TBitmap.Create);
            Bitmaps32Dict.Items[ResourceName].PixelFormat:=pf32bit;
            TempBitmap.Assign(LPicture.Graphic);
            ScaleImage32(TempBitmap, Bitmaps32Dict.Items[ResourceName], Factor);
          finally
            TempBitmap.Free;
          end;
       end;
    finally
      LPicture.Free;
    end;
  end;
end;

var
 CX     : Integer;
 Factor : Double;
initialization
  CX:=GetSystemMetrics(SM_CXMENUCHECK);
  log('initialization');
  TDelphiDevShellObjectFactory.Create(ComServer, TDelphiDevShellToolsContextMenu, CLASS_DelphiDevShellToolsContextMenu, ciMultiInstance, tmApartment);
  Settings:=TSettings.Create;
  InstalledDelphiVersions:=TObjectList<TDelphiVersionData>.Create;
  FillListDelphiVersions(InstalledDelphiVersions);
  PAClientProfiles:=TPAClientProfileList.Create(InstalledDelphiVersions);

  BitmapsDict:=TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);
  Bitmaps32Dict:=TObjectDictionary<string, TBitmap>.Create([doOwnsValues]);

  RegisterBitmap('logo');
  RegisterBitmap('notepad');
  RegisterBitmap('cmd');
  RegisterBitmap('copy');
  RegisterBitmap('osx');
  RegisterBitmap('ios');
  RegisterBitmap('win');
  RegisterBitmap('osx', 'osx2');
  RegisterBitmap('ios', 'ios2');
  RegisterBitmap('win', 'win2');
  RegisterBitmap('delphi');
  RegisterBitmap('delphi', 'delphi2');
  RegisterBitmap('delphig');
  RegisterBitmap('radcmd');
  //RegisterBitmap('format');
  //RegisterBitmap('touch');
  RegisterBitmap('msbuild');
  //RegisterBitmap('brcc32');
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
  //RegisterBitmap('audits');
  //RegisterBitmap('metrics');
  RegisterBitmap('fpc_tools');

   try
     BitmapsDict.Add('txt',TBitmap.Create);
     GetAssocAppByExt('foo.txt', ExeNameTxt, FriendlyAppNameTxt);
     if (ExeNameTxt<>'') and TFile.Exists(ExeNameTxt)  then
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

   LazarusInstalled:=IsLazarusInstalled and TFile.Exists(GetLazarusIDEFileName);

   if LazarusInstalled then
   begin
     try
       FPCToolsExts:=GetGroupToolsExtensions('FPC Tools');

       BitmapsDict.Add('lazarus',TBitmap.Create);
       //MakeBitmapMenuTransparent(BitmapsDict.Items['lazarus']);
       if CX<16 then
       begin
         BitmapsDict.Add('lazarus2',TBitmap.Create);
         ExtractBitmapFile32(BitmapsDict.Items['lazarus2'], GetLazarusIDEFileName, SHGFI_SMALLICON);
         Factor:= CX/16;
         ScaleImage32( BitmapsDict.Items['lazarus2'], BitmapsDict.Items['lazarus'], Factor);
       end
       else
         ExtractBitmapFile32(BitmapsDict.Items['lazarus'], GetLazarusIDEFileName, SHGFI_SMALLICON);

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
  Bitmaps32Dict.Free;
  InstalledDelphiVersions.Free;
  PAClientProfiles.Free;
  log('finalization');
end.
