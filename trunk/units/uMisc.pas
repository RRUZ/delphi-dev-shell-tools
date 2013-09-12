{**************************************************************************************************}
{                                                                                                  }
{ Unit uMisc                                                                                       }
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
{ The Original Code is uMisc.pas.                                                                  }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013 Rodrigo Ruz V.                         }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}
unit uMisc;

interface

uses
 Windows,
 Vcl.Graphics,
 Rtti,
 System.Types,
 ImgList;

type

  TSettings =class
  private
    FSubMenuOpenCmdRAD: Boolean;
    FShowInfoDProj: Boolean;
    FSubMenuLazarus: Boolean;
    FActivateLazarus : Boolean;
    FSubMenuCommonTasks: Boolean;
    FSubMenuMSBuild: Boolean;
    FSubMenuMSBuildAnother: Boolean;
    FSubMenuRunTouch: Boolean;
    FSubMenuOpenDelphi: Boolean;
    FSubMenuFormat: Boolean;
    FSubMenuOpenVclStyle: Boolean;
    FSubMenuOpenFMXStyle: Boolean;
    FSubMenuCompileRC: Boolean;
    FCheckForUpdates: Boolean;
    FCheckSumExt, FOpenLazarusExt, FOpenDelphiExt, FCommonTaskExt : string;
  public
    property SubMenuOpenCmdRAD : Boolean read FSubMenuOpenCmdRAD write FSubMenuOpenCmdRAD;
    property SubMenuLazarus : Boolean read FSubMenuLazarus write FSubMenuLazarus;
    property SubMenuCommonTasks : Boolean read FSubMenuCommonTasks write FSubMenuCommonTasks;
    property ShowInfoDProj : Boolean read FShowInfoDProj write FShowInfoDProj;
    property ActivateLazarus : Boolean read FActivateLazarus write FActivateLazarus;
    property SubMenuMSBuild : Boolean read FSubMenuMSBuild write FSubMenuMSBuild;
    property SubMenuMSBuildAnother : Boolean read FSubMenuMSBuildAnother write FSubMenuMSBuildAnother;
    property SubMenuRunTouch : Boolean read FSubMenuRunTouch write FSubMenuRunTouch;
    property SubMenuOpenDelphi : Boolean read FSubMenuOpenDelphi write FSubMenuOpenDelphi;
    property SubMenuFormat : Boolean read FSubMenuFormat write FSubMenuFormat;
    property SubMenuCompileRC : Boolean read FSubMenuCompileRC  write FSubMenuCompileRC;
    property SubMenuOpenFMXStyle : Boolean read FSubMenuOpenFMXStyle write FSubMenuOpenFMXStyle;
    property SubMenuOpenVclStyle : Boolean read FSubMenuOpenVclStyle write FSubMenuOpenVclStyle;

    property CheckForUpdates     : Boolean read FCheckForUpdates write FCheckForUpdates;
    property CommonTaskExt : string read FCommonTaskExt write FCommonTaskExt;
    property OpenDelphiExt : string read FOpenDelphiExt write FOpenDelphiExt;
    property OpenLazarusExt : string read FOpenLazarusExt write FOpenLazarusExt;
    property CheckSumExt : string read FCheckSumExt write FCheckSumExt;
  end;

  TMethodInfo=class
   hwnd   : HWND;
   Value1 : TValue;
   Value2 : TValue;
   Value3 : TValue;
   Value4 : TValue;
   Method : procedure (Info : TMethodInfo) of object;
  end;

  procedure ExtractIconFileToImageList(ImageList: TCustomImageList; const Filename: string);
  procedure ExtractIconFile(Icon: TIcon; const Filename: string;IconType : Cardinal);
  procedure ExtractBitmapFile(Bmp: TBitmap; const Filename: string;IconType : Cardinal);
  procedure ExtractBitmapFile32(Bmp: TBitmap; const Filename: string;IconType : Cardinal);

  function  GetFileVersion(const FileName: string): string;
  function  IsAppRunning(const FileName: string): boolean;
  function  GetLocalAppDataFolder: string;
  function  GetTempDirectory: string;
  procedure MsgBox(const Msg: string);
  procedure CreateArrayBitmap(Width,Height:Word;Colors: Array of TColor;var bmp : TBitmap);
  function  GetSpecialFolder(const CSIDL: integer) : string;
  function  IsUACEnabled: Boolean;
  procedure RunAsAdmin(const FileName, Params: string; hWnd: HWND = 0);
  function  CurrentUserIsAdmin: Boolean;
  function  GetModuleName: string;
  procedure GetAssocAppByExt(const FileName:string; var ExeName, FriendlyAppName : string);
  function  GetDelphiDevShellToolsFolder : string;
  function  GetDevShellToolsDbName : String;
  function  GetDevShellToolsDbDelphi : String;
  function  GetDevShellToolsImagesFolder : String;

  procedure ReadSettings(var Settings: TSettings);
  procedure WriteSettings(const Settings: TSettings);

  function GetUNCNameEx(const lpLocalPath: string): string;
  function LocalPathToFileURL(const pszPath: string): string;

  procedure CheckUpdates;

  function GetGroupToolsExtensions(const GroupName : string) : TStringDynArray;

  procedure ScaleImage32(const SourceBitmap, ResizedBitmap: TBitmap; const ScaleAmount: Double);
  function IsVistaOrLater : Boolean;
  function IconToBitmapPARGB32(hIcon : HICON): HBITMAP;

implementation

uses
  ActiveX,
  ShlObj,
  PsAPI,
  tlhelp32,
  ComObj,
  CommCtrl,
  StrUtils,
  ShellAPI,
  Classes,
  Dialogs,
  ShLwApi,
  System.UITypes,
  Datasnap.DBClient,
  MidasLib,
  Db,
  Registry,
  TypInfo,
  UxTheme,
  IniFiles,
  SysUtils;

Const
 SECURITY_NT_AUTHORITY: TSIDIdentifierAuthority = (Value: (0, 0, 0, 0, 0, 5));
 SECURITY_BUILTIN_DOMAIN_RID = $00000020;
 DOMAIN_ALIAS_RID_ADMINS     = $00000220;
 DOMAIN_ALIAS_RID_USERS      = $00000221;
 DOMAIN_ALIAS_RID_GUESTS     = $00000222;
 DOMAIN_ALIAS_RID_POWER_USERS= $00000223;

type
  TAssocStr = (
  ASSOCSTR_COMMAND = 1,
  ASSOCSTR_EXECUTABLE,
  ASSOCSTR_FRIENDLYDOCNAME,
  ASSOCSTR_FRIENDLYAPPNAME,
  ASSOCSTR_NOOPEN,
  ASSOCSTR_SHELLNEWVALUE,
  ASSOCSTR_DDECOMMAND,
  ASSOCSTR_DDEIFEXEC,
  ASSOCSTR_DDEAPPLICATION,
  ASSOCSTR_DDETOPIC );

const
  AssocStrDisplaystrings : array [ASSOCSTR_COMMAND..ASSOCSTR_DDETOPIC]
  of string = (
  'ASSOCSTR_COMMAND',
  'ASSOCSTR_EXECUTABLE',
  'ASSOCSTR_FRIENDLYDOCNAME',
  'ASSOCSTR_FRIENDLYAPPNAME',
  'ASSOCSTR_NOOPEN',
  'ASSOCSTR_SHELLNEWVALUE',
  'ASSOCSTR_DDECOMMAND',
  'ASSOCSTR_DDEIFEXEC',
  'ASSOCSTR_DDEAPPLICATION',
  'ASSOCSTR_DDETOPIC' );


function IsVistaOrLater : Boolean;
begin
  Result:= (Win32MajorVersion >= 6);
end;

function GetGroupToolsExtensions(const GroupName : string) : TStringDynArray;
var
 LClientDataSet : TClientDataSet;
 List : TStrings;
 LArray  : TStringDynArray;
 s : string;
 i : integer;
begin
Result:=nil;
 LClientDataSet:= TClientDataSet.Create(nil);
 try
   List:=TStringList.Create;
   try
     LClientDataSet.ReadOnly:=True;
     LClientDataSet.LoadFromFile(GetDelphiDevShellToolsFolder+'tools.db');
     LClientDataSet.Open;
     LClientDataSet.Filter:='Group = '+QuotedStr(GroupName);
     LClientDataSet.Filtered:=True;
      while not LClientDataSet.eof do
      begin

       LArray:= SplitString(LClientDataSet.FieldByName('Extensions').AsString, ',');
       if Length(LArray)>0 then
        for s in LArray do
          if List.IndexOf(s)=-1 then
             List.Add(s);

       LClientDataSet.Next;
      end;

     if List.Count>0 then
     begin
      SetLength(Result, List.Count);
      for i:=0 to List.Count-1 do
        Result[i]:=List[i];
     end;

   finally
     List.Free;
   end;
 finally
   LClientDataSet.Free;
 end;
end;



function CheckTokenMembership(TokenHandle: THandle; SidToCheck: PSID; var IsMember: BOOL): BOOL; stdcall; external advapi32;

function GetComputerName: string;
var
  nSize: Cardinal;
begin
  nSize := MAX_COMPUTERNAME_LENGTH + 1;
  Result := StringOfChar(#0, nSize);
  Windows.GetComputerName(PChar(Result), nSize);
  SetLength(Result, nSize);
end;

function GetUNCNameEx(const lpLocalPath: string): string;
begin
  if GetDriveType(PChar(Copy(lpLocalPath,1,3)))=DRIVE_REMOTE then
   Result:=ExpandUNCFileName(lpLocalPath)
  else
    Result := '\\' + GetComputerName + '\' + StringReplace(lpLocalPath,':','$', [rfReplaceAll]);
end;

function LocalPathToFileURL(const pszPath: string): string;
var
  pszUrl: string;
  pcchUrl: DWORD;
begin
  Result := '';
  pcchUrl := Length('file:///' + pszPath + #0);
  SetLength(pszUrl, pcchUrl);

  if UrlCreateFromPath(PChar(pszPath), PChar(pszUrl), @pcchUrl, 0) = S_OK then
    Result := pszUrl;
end;

procedure CheckUpdates;
var
  LRegistry : TRegistry;
  dt : TDateTime;
begin
  LRegistry:=TRegistry.Create;
  try
    LRegistry.RootKey := HKEY_CURRENT_USER;
    if LRegistry.OpenKeyReadOnly('Software\DelphiDevShellTools\') then
    begin
      try
        LRegistry.ReadBinaryData('LastUpdateCheck', dt, SizeOf(dt));
      finally
        LRegistry.CloseKey;
      end;
    end;
  finally
    LRegistry.Free;
  end;

  if Abs(Now-dt)>=1 then
  begin
    ShellExecute(0, 'open', PChar(IncludeTrailingPathDelimiter(ExtractFilePath(GetModuleName))+'GUIDelphiDevShell.exe'), PChar('-checkupdates') , nil , SW_SHOWNORMAL);

    LRegistry:=TRegistry.Create;
    try
      LRegistry.RootKey := HKEY_CURRENT_USER;
      if LRegistry.OpenKey('Software\DelphiDevShellTools\', True) then
      begin
        try
          dt:=Now;
          LRegistry.WriteBinaryData('LastUpdateCheck', dt, SizeOf(dt));
        finally
          LRegistry.CloseKey;
        end;
      end;
    finally
      LRegistry.Free;
    end;
  end;
end;

function GetDelphiDevShellToolsFolder : string;
begin
 Result:=IncludeTrailingPathDelimiter(GetSpecialFolder(CSIDL_APPDATA))+ 'DelphiDevShellTools\';
 //C:\Users\Dexter\AppData\Roaming\DelphiDevShellTools\
 ForceDirectories(Result);
end;

function GetDevShellToolsDbName : String;
begin
 Result:=GetDelphiDevShellToolsFolder + 'Tools.db';
end;

function GetDevShellToolsDbDelphi : String;
begin
 Result:=GetDelphiDevShellToolsFolder + 'DelphiVersions.db';
end;

function GetDevShellToolsImagesFolder : String;
begin
 Result:=GetDelphiDevShellToolsFolder+'ico\';
end;



procedure ReadSettings(var Settings: TSettings);
var
  iniFile: TIniFile;
  LCtx   : TRttiContext;
  LProp  : TRttiProperty;
  BooleanValue : Boolean;
  StringValue : string;
begin
  iniFile := TIniFile.Create(GetDelphiDevShellToolsFolder + 'Settings.ini');
  try
   LCtx:=TRttiContext.Create;
   try
    for LProp in LCtx.GetType(TypeInfo(TSettings)).GetProperties do
    if LProp.PropertyType.TypeKind=tkEnumeration then
    begin
      BooleanValue:= iniFile.ReadBool('Global', LProp.Name, True);
      LProp.SetValue(Settings, BooleanValue);
    end
    else
    if (LProp.PropertyType.TypeKind=tkString) or  (LProp.PropertyType.TypeKind=tkUString) then
    begin
      StringValue:= iniFile.ReadString('Global', LProp.Name, '');
      LProp.SetValue(Settings, StringValue);
    end;
   finally
     LCtx.Free;
   end;
  finally
    iniFile.Free;
  end;
end;

procedure WriteSettings(const Settings: TSettings);
var
  iniFile: TIniFile;
  LCtx   : TRttiContext;
  LProp  : TRttiProperty;
  BooleanValue : Boolean;
  StringValue : string;
begin
  iniFile := TIniFile.Create(GetDelphiDevShellToolsFolder + 'Settings.ini');
  try
   LCtx:=TRttiContext.Create;
   try
    for LProp in LCtx.GetType(TypeInfo(TSettings)).GetProperties do
    if LProp.PropertyType.TypeKind=tkEnumeration then
    begin
       BooleanValue:= LProp.GetValue(Settings).AsBoolean;
       iniFile.WriteBool('Global', LProp.Name, BooleanValue);
    end
    else
    if (LProp.PropertyType.TypeKind=tkString) or  (LProp.PropertyType.TypeKind=tkUString) then
    begin
       StringValue:= LProp.GetValue(Settings).AsString;
       iniFile.WriteString('Global', LProp.Name, StringValue);
    end;
   finally
     LCtx.Free;
   end;
  finally
    iniFile.Free;
  end;
end;

procedure GetAssocAppByExt(const FileName:string; var ExeName, FriendlyAppName : string);
var
 pszOut: array [0..1024] of Char;
 pcchOut: DWord;
begin
  ExeName:='';
  FriendlyAppName:='';
  pcchOut := Sizeof(pszOut);
  ZeroMemory(@pszOut, SizeOf(pszOut));

  OleCheck( AssocQueryString(ASSOCF_NOTRUNCATE, ASSOCSTR(ASSOCSTR_EXECUTABLE), LPCWSTR(ExtractFileExt(FileName)), 'open', pszOut, @pcchOut));
  if pcchOut>0 then
   SetString(ExeName, PChar(@pszOut[0]), pcchOut-1);

  pcchOut := Sizeof(pszOut);
  ZeroMemory(@pszOut, SizeOf(pszOut));

  OleCheck( AssocQueryString(ASSOCF_NOTRUNCATE, ASSOCSTR(ASSOCSTR_FRIENDLYAPPNAME), LPCWSTR(ExtractFileExt(FileName)), 'open', pszOut, @pcchOut));
  if pcchOut>0 then
   SetString(FriendlyAppName, PChar(@pszOut[0]), pcchOut-1);
end;

function GetModuleName: string;
var
  lpFilename: array[0..MAX_PATH] of Char;
begin
  ZeroMemory(@lpFilename, SizeOf(lpFilename));
  GetModuleFileName(hInstance, lpFilename, MAX_PATH);
  Result := lpFilename;
end;

function IsUACEnabled: Boolean;
var
  LRegistry: TRegistry;
begin
  Result := False;
  if CheckWin32Version(6, 0) then
  begin
    LRegistry := TRegistry.Create;
    try
      LRegistry.RootKey := HKEY_LOCAL_MACHINE;
      if LRegistry.OpenKeyReadOnly('SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System') then
        Exit(LRegistry.ValueExists('EnableLUA') and LRegistry.ReadBool('EnableLUA'));
    finally
      LRegistry.Free;
    end;
  end;
end;


function  UserInGroup(Group :DWORD) : Boolean;
 var
  pIdentifierAuthority :TSIDIdentifierAuthority;
  pSid : Windows.PSID;
  IsMember    : BOOL;
 begin
  pIdentifierAuthority := SECURITY_NT_AUTHORITY;
  Result := AllocateAndInitializeSid(pIdentifierAuthority,2, SECURITY_BUILTIN_DOMAIN_RID, Group, 0, 0, 0, 0, 0, 0, pSid);
  try
    if Result then
      if not CheckTokenMembership(0, pSid, IsMember) then //passing 0 means which the function will be use the token of the calling thread.
         Result:= False
      else
         Result:=IsMember;
  finally
     FreeSid(pSid);
  end;
 end;

function  CurrentUserIsAdmin: Boolean;
begin
 Result:=UserInGroup(DOMAIN_ALIAS_RID_ADMINS);
end;

procedure RunAsAdmin(const FileName, Params: string; hWnd: HWND = 0);
var
  sei: TShellExecuteInfo;
begin
  ZeroMemory(@sei, SizeOf(sei));
  sei.cbSize := SizeOf(sei);
  sei.Wnd := hWnd;
  sei.fMask := SEE_MASK_FLAG_DDEWAIT or SEE_MASK_FLAG_NO_UI;
  sei.lpVerb := 'runas';
  sei.lpFile := PChar(FileName);
  sei.lpParameters := PChar(Params);
  sei.nShow := SW_SHOWNORMAL;
  if not ShellExecuteEx(@sei) then
    RaiseLastOSError;
end;


function GetSpecialFolder(const CSIDL: integer) : string;
var
  lpszPath : PWideChar;
begin
  lpszPath := StrAlloc(MAX_PATH);
  try
     ZeroMemory(lpszPath, MAX_PATH);
    if SHGetSpecialFolderPath(0, lpszPath, CSIDL, False)  then
      Result := lpszPath
    else
      Result := '';
  finally
    StrDispose(lpszPath);
  end;
end;

procedure MsgBox(const Msg: string);
begin
  MessageDlg(Msg, mtInformation, [mbOK], 0);
end;

function GetTempDirectory: string;
var
  lpBuffer: array[0..MAX_PATH] of Char;
begin
  GetTempPath(MAX_PATH, @lpBuffer);
  Result := StrPas(lpBuffer);
end;

function GetLocalAppDataFolder: string;
const
  CSIDL_LOCAL_APPDATA = $001C;
var
  ppMalloc: IMalloc;
  ppidl:    PItemIdList;
begin
  ppidl := nil;
  try
    if SHGetMalloc(ppMalloc) = S_OK then
    begin
      SHGetSpecialFolderLocation(0, CSIDL_LOCAL_APPDATA, ppidl);
      SetLength(Result, MAX_PATH);
      if not SHGetPathFromIDList(ppidl, PChar(Result)) then
        RaiseLastOSError;
      SetLength(Result, lStrLen(PChar(Result)));
    end;
  finally
    if ppidl <> nil then
      ppMalloc.Free(ppidl);
  end;
end;


function ProcessFileName(dwProcessId: DWORD): string;
var
  hModule: Cardinal;
begin
  Result := '';
  hModule := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, dwProcessId);
  if hModule <> 0 then
    try
      SetLength(Result, MAX_PATH);
      if GetModuleFileNameEx(hModule, 0, PChar(Result), MAX_PATH) > 0 then
        SetLength(Result, StrLen(PChar(Result)))
      else
        Result := '';
    finally
      CloseHandle(hModule);
    end;
end;

function IsAppRunning(const FileName: string): boolean;
var
  hSnapshot      : Cardinal;
  EntryParentProc: TProcessEntry32;
begin
  Result := False;
  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnapshot = INVALID_HANDLE_VALUE then
    exit;
  try
    EntryParentProc.dwSize := SizeOf(EntryParentProc);
    if Process32First(hSnapshot, EntryParentProc) then
      repeat
        if CompareText(ExtractFileName(FileName), EntryParentProc.szExeFile) = 0 then
          if CompareText(ProcessFileName(EntryParentProc.th32ProcessID),  FileName) = 0 then
          begin
            Result := True;
            break;
          end;
      until not Process32Next(hSnapshot, EntryParentProc);
  finally
    CloseHandle(hSnapshot);
  end;
end;



function GetFileVersion(const FileName: string): string;
var
  FSO  : OleVariant;
begin
  FSO    := CreateOleObject('Scripting.FileSystemObject');
  Result := FSO.GetFileVersion(FileName);
end;

procedure ExtractIconFile(Icon: TIcon; const Filename: string;IconType : Cardinal);
var
  FileInfo: TShFileInfo;
begin
  if FileExists(Filename) then
  begin
    FillChar(FileInfo, SizeOf(FileInfo), 0);
    SHGetFileInfo(PChar(Filename), 0, FileInfo, SizeOf(FileInfo),
      SHGFI_ICON or IconType);
    if FileInfo.hIcon <> 0 then
      Icon.Handle:=FileInfo.hIcon;
  end;
end;

procedure ExtractBitmapFile(Bmp: TBitmap; const Filename: string;IconType : Cardinal);
var
 Icon: TIcon;
begin
  Icon:=TIcon.Create;
  try
    ExtractIconFile(Icon, Filename, SHGFI_SMALLICON);
    Bmp.PixelFormat:=pf24bit;
    Bmp.Width := Icon.Width;
    Bmp.Height := Icon.Height;
    Bmp.Canvas.Draw(0, 0, Icon);
  finally
    Icon.Free;
  end;

end;


procedure ExtractBitmapFile32(Bmp: TBitmap; const Filename: string;IconType : Cardinal);
var
 Icon: TIcon;
begin
  Icon:=TIcon.Create;
  try
    ExtractIconFile(Icon, Filename, SHGFI_SMALLICON);
    Bmp.PixelFormat:=pf32bit;  {
    Bmp.Width := Icon.Width;
    Bmp.Height := Icon.Height;
    Bmp.Canvas.Draw(0, 0, Icon);
    }
    Bmp.Assign(Icon);
  finally
    Icon.Free;
  end;

end;
procedure ExtractIconFileToImageList(ImageList: TCustomImageList; const Filename: string);
var
  FileInfo: TShFileInfo;
begin
  if FileExists(Filename) then
  begin
    FillChar(FileInfo, SizeOf(FileInfo), 0);
    SHGetFileInfo(PChar(Filename), 0, FileInfo, SizeOf(FileInfo),
      SHGFI_ICON or SHGFI_SMALLICON);
    if FileInfo.hIcon <> 0 then
    begin
      ImageList_AddIcon(ImageList.Handle, FileInfo.hIcon);
      DestroyIcon(FileInfo.hIcon);
    end;
  end;
end;


procedure CreateArrayBitmap(Width,Height:Word;Colors: Array of TColor;var bmp : TBitmap);
Var
 i : integer;
 w : integer;
begin
  bmp.PixelFormat:=pf24bit;
  bmp.Width:=Width;
  bmp.Height:=Height;
  bmp.Canvas.Brush.Color := clBlack;
  bmp.Canvas.FillRect(Rect(0,0, Width, Height));


  w :=(Width-2) div (High(Colors)+1);
  for i:=0 to High(Colors) do
  begin
   bmp.Canvas.Brush.Color := Colors[i];
   //bmp.Canvas.FillRect(Rect((w*i),0, w*(i+1), Height));
   bmp.Canvas.FillRect(Rect((w*i)+1,1, w*(i+1)+1, Height-1))
  end;
end;

procedure ShrinkImage32(const SourceBitmap, StretchedBitmap: TBitmap;
  Scale: Double);
var
  ScanLines: array of PByteArray;
  DestLine: PByteArray;
  CurrentLine: PByteArray;
  DestX, DestY: Integer;
  DestA, DestR, DestB, DestG: Integer;
  SourceYStart, SourceXStart: Integer;
  SourceYEnd, SourceXEnd: Integer;
  AvgX, AvgY: Integer;
  ActualX: Integer;
  PixelsUsed: Integer;
  DestWidth, DestHeight: Integer;
begin
  DestWidth := StretchedBitmap.Width;
  DestHeight := StretchedBitmap.Height;
  SetLength(ScanLines, SourceBitmap.Height);
  for DestY := 0 to DestHeight - 1 do
  begin
    SourceYStart := Round(DestY / Scale);
    SourceYEnd := Round((DestY + 1) / Scale) - 1;

    if SourceYEnd >= SourceBitmap.Height then
      SourceYEnd := SourceBitmap.Height - 1;

    { Grab the destination pixels }
    DestLine := StretchedBitmap.ScanLine[DestY];
    for DestX := 0 to DestWidth - 1 do
    begin
      { Calculate the RGB value at this destination pixel }
      SourceXStart := Round(DestX / Scale);
      SourceXEnd := Round((DestX + 1) / Scale) - 1;

      DestR := 0;
      DestB := 0;
      DestG := 0;
      DestA := 0;

      PixelsUsed := 0;
      if SourceXEnd >= SourceBitmap.Width then
        SourceXEnd := SourceBitmap.Width - 1;
      for AvgY := SourceYStart to SourceYEnd do
      begin
        if ScanLines[AvgY] = nil then
          ScanLines[AvgY] := SourceBitmap.ScanLine[AvgY];
        CurrentLine := ScanLines[AvgY];
        for AvgX := SourceXStart to SourceXEnd do
        begin
          ActualX := AvgX*4; { 4 bytes per pixel }
          DestR := DestR + CurrentLine[ActualX];
          DestB := DestB + CurrentLine[ActualX+1];
          DestG := DestG + CurrentLine[ActualX+2];
          DestA := DestA + CurrentLine[ActualX+3];
          Inc(PixelsUsed);
        end;
      end;

      { pf32bit = 4 bytes per pixel }
      ActualX := DestX*4;
      DestLine[ActualX]   := Round(DestR / PixelsUsed);
      DestLine[ActualX+1] := Round(DestB / PixelsUsed);
      DestLine[ActualX+2] := Round(DestG / PixelsUsed);
      DestLine[ActualX+3] := Round(DestA / PixelsUsed);
    end;
  end;
end;


procedure EnlargeImage32(const SourceBitmap, StretchedBitmap: TBitmap;
  Scale: Double);
var
  ScanLines: array of PByteArray;
  DestLine: PByteArray;
  CurrentLine: PByteArray;
  DestX, DestY: Integer;
  DestA, DestR, DestB, DestG: Double;
  SourceYStart, SourceXStart: Integer;
  SourceYPos: Integer;
  AvgX, AvgY: Integer;
  ActualX: Integer;
  { Use a 4 pixels for enlarging }
  XWeights, YWeights: array[0..1] of Double;
  PixelWeight: Double;
  DistFromStart: Double;
  DestWidth, DestHeight: Integer;
begin
  DestWidth := StretchedBitmap.Width;
  DestHeight := StretchedBitmap.Height;
  Scale := StretchedBitmap.Width / SourceBitmap.Width;
  SetLength(ScanLines, SourceBitmap.Height);
  for DestY := 0 to DestHeight - 1 do
  begin
    DistFromStart := DestY / Scale;
    SourceYStart := Round(DistFromSTart);
    YWeights[1] := DistFromStart - SourceYStart;
    if YWeights[1] < 0 then
      YWeights[1] := 0;
    YWeights[0] := 1 - YWeights[1];

    DestLine := StretchedBitmap.ScanLine[DestY];
    for DestX := 0 to DestWidth - 1 do
    begin
      { Calculate the RGB value at this destination pixel }
      DistFromStart := DestX / Scale;
      if DistFromStart > (SourceBitmap.Width - 1) then
        DistFromStart := SourceBitmap.Width - 1;
      SourceXStart := Round(DistFromStart);
      XWeights[1] := DistFromStart - SourceXStart;
      if XWeights[1] < 0 then
        XWeights[1] := 0;
      XWeights[0] := 1 - XWeights[1];

      { Average the four nearest pixels from the source mapped point }
      DestR := 0;
      DestB := 0;
      DestG := 0;
      DestA := 0;
      for AvgY := 0 to 1 do
      begin
        SourceYPos := SourceYStart + AvgY;
        if SourceYPos >= SourceBitmap.Height then
          SourceYPos := SourceBitmap.Height - 1;
        if ScanLines[SourceYPos] = nil then
          ScanLines[SourceYPos] := SourceBitmap.ScanLine[SourceYPos];
            CurrentLine := ScanLines[SourceYPos];

        for AvgX := 0 to 1 do
        begin
          if SourceXStart + AvgX >= SourceBitmap.Width then
            SourceXStart := SourceBitmap.Width - 1;

          ActualX := (SourceXStart + AvgX) * 4; { 4 bytes per pixel }

          { Calculate how heavy this pixel is based on how far away
            it is from the mapped pixel }
          PixelWeight := XWeights[AvgX] * YWeights[AvgY];
          DestR := DestR + CurrentLine[ActualX] * PixelWeight;
          DestB := DestB + CurrentLine[ActualX+1] * PixelWeight;
          DestG := DestG + CurrentLine[ActualX+2] * PixelWeight;
          DestA := DestA + CurrentLine[ActualX+3] * PixelWeight;
        end;
      end;

      ActualX := DestX * 4; { 4 bytes per pixel }
      DestLine[ActualX] := Round(DestR);
      DestLine[ActualX+1] := Round(DestB);
      DestLine[ActualX+2] := Round(DestG);
      DestLine[ActualX+3] := Round(DestA);
    end;
  end;
end;

procedure ScaleImage32(const SourceBitmap, ResizedBitmap: TBitmap;
  const ScaleAmount: Double);
var
  DestWidth, DestHeight: Integer;
begin
  DestWidth := Round(SourceBitmap.Width * ScaleAmount);
  DestHeight := Round(SourceBitmap.Height * ScaleAmount);
  SourceBitmap.PixelFormat := pf32bit;

  ResizedBitmap.Width := DestWidth;
  ResizedBitmap.Height := DestHeight;
  //ResizedBitmap.Canvas.Brush.Color := Vcl.Graphics.clNone;
  //ResizedBitmap.Canvas.FillRect(Rect(0, 0, DestWidth, DestHeight));
  ResizedBitmap.PixelFormat := pf32bit;

  if ResizedBitmap.Width < SourceBitmap.Width then
    ShrinkImage32(SourceBitmap, ResizedBitmap, ScaleAmount)
  else
    EnlargeImage32(SourceBitmap, ResizedBitmap, ScaleAmount);
end;

function Create32BitHBITMAP(hdc : HDC; psize : TSize ; var ppvBits : Pointer; out  phBmp : HBITMAP) : HRESULT;
var
  bmi  : TBitmapInfo;
  hdcUsed : Windows.HDC;
begin
    phBmp := 0;
    ZeroMemory(@bmi, sizeof(bmi));

    bmi.bmiHeader.biSize := sizeof(BITMAPINFOHEADER);
    bmi.bmiHeader.biPlanes := 1;
    bmi.bmiHeader.biCompression := BI_RGB;

    bmi.bmiHeader.biWidth := psize.cx;
    bmi.bmiHeader.biHeight := psize.cy;
    bmi.bmiHeader.biBitCount := 32;

    if hdc<>0 then hdcUsed := hdc else hdcUsed := GetDC(0);

    if (hdcUsed<>0) then
    begin
        phBmp := CreateDIBSection(hdcUsed, bmi, DIB_RGB_COLORS, ppvBits, 0, 0);
        if (hdc <> hdcUsed) then
            ReleaseDC(0, hdcUsed);
    end;

    if phBmp=0 then
      Result:= E_OUTOFMEMORY
    else
      Result:= S_OK;
end;


function IconToBitmapPARGB32(hIcon : HICON): HBITMAP;
var
  sizIcon : TSize;
  rcIcon  : TRect;
  hbmpOld, hBmp    : HBITMAP;
  hdcBuffer, hdcDest : HDC;
  bfAlpha : TBlendFunction;
  paintParams : TBPPaintParams;
  hPaintBuffer : UxTheme.HPAINTBUFFER;
  ppvBits : Pointer;
begin
    if (hIcon=0) then Exit(0);

    sizIcon.cx := GetSystemMetrics(SM_CXSMICON);
    sizIcon.cy := GetSystemMetrics(SM_CYSMICON);

    SetRect(rcIcon, 0, 0, sizIcon.cx, sizIcon.cy);
    hBmp := 0;
    ppvBits:=nil;

    hdcDest := CreateCompatibleDC(0);
    if (hdcDest<>0) then
    begin
        if (Succeeded(Create32BitHBITMAP(hdcDest, sizIcon, ppvBits, hBmp))) then
        begin
            hbmpOld := HBITMAP(SelectObject(hdcDest, hBmp));
            if (hbmpOld<>0) then
            begin
                bfAlpha.BlendOp := AC_SRC_OVER;
                bfAlpha.BlendFlags := 0;
                bfAlpha.SourceConstantAlpha := 255;
                bfAlpha.AlphaFormat := AC_SRC_ALPHA;
                paintParams.cbSize := sizeof(paintParams);
                paintParams.dwFlags := BPPF_ERASE;
                paintParams.pBlendFunction := @bfAlpha;
                hPaintBuffer := BeginBufferedPaint(hdcDest, rcIcon, BPBF_DIB, @paintParams, hdcBuffer);
                if (hPaintBuffer<>0) then
                begin
                    if (DrawIconEx(hdcBuffer, 0, 0, hIcon, sizIcon.cx, sizIcon.cy, 0, 0, DI_NORMAL)) then
                        // If icon did not have an alpha channel we need to convert buffer to PARGB
                        // always use icons with alpha
                        //ConvertBufferToPARGB32(hPaintBuffer, hdcDest, hIcon, sizIcon);

                    // This will write the buffer contents to the destination bitmap
                    EndBufferedPaint(hPaintBuffer, TRUE);
                end;
                SelectObject(hdcDest, hbmpOld);
            end;
        end;
        DeleteDC(hdcDest);
    end;

    Exit(hBmp);
end;

//function IconToBitmap(hIcon : HICON) : HBITMAP;
//begin
//
//    RECT rect;
//
//    rect.right = ::GetSystemMetrics(SM_CXMENUCHECK);
//    rect.bottom = ::GetSystemMetrics(SM_CYMENUCHECK);
//
//    rect.left = rect.top = 0;
//
//    HWND desktop = ::GetDesktopWindow();
//    if (desktop == NULL)
//    {
//        DestroyIcon(hIcon);
//        return NULL;
//    }
//
//    HDC screen_dev = ::GetDC(desktop);
//    if (screen_dev == NULL)
//    {
//        DestroyIcon(hIcon);
//        return NULL;
//    }
//
//    // Create a compatible DC
//    HDC dst_hdc = ::CreateCompatibleDC(screen_dev);
//    if (dst_hdc == NULL)
//    {
//        DestroyIcon(hIcon);
//        ::ReleaseDC(desktop, screen_dev);
//        return NULL;
//    }
//
//    // Create a new bitmap of icon size
//    HBITMAP bmp = ::CreateCompatibleBitmap(screen_dev, rect.right, rect.bottom);
//    if (bmp == NULL)
//    {
//        DestroyIcon(hIcon);
//        ::DeleteDC(dst_hdc);
//        ::ReleaseDC(desktop, screen_dev);
//        return NULL;
//    }
//
//    // Select it into the compatible DC
//    HBITMAP old_dst_bmp = (HBITMAP)::SelectObject(dst_hdc, bmp);
//    if (old_dst_bmp == NULL)
//    {
//        DestroyIcon(hIcon);
//        ::DeleteDC(dst_hdc);
//        ::ReleaseDC(desktop, screen_dev);
//        return NULL;
//    }
//
//    // Fill the background of the compatible DC with the white color
//    // that is taken by menu routines as transparent
//    ::SetBkColor(dst_hdc, RGB(255, 255, 255));
//    ::ExtTextOut(dst_hdc, 0, 0, ETO_OPAQUE, &rect, NULL, 0, NULL);
//
//    // Draw the icon into the compatible DC
//    ::DrawIconEx(dst_hdc, 0, 0, hIcon, rect.right, rect.bottom, 0, NULL, DI_NORMAL);
//
//    // Restore settings
//    ::SelectObject(dst_hdc, old_dst_bmp);
//    ::DeleteDC(dst_hdc);
//    ::ReleaseDC(desktop, screen_dev);
//    DestroyIcon(hIcon);
//    if (bmp)
//        bitmaps.insert(bitmap_it, std::make_pair(uIcon, bmp));
//    return bmp;
//end;

end.
