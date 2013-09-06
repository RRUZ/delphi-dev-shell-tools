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
 Graphics,
 Rtti,
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
    FCheckSumExt, FFormatPascalExt, FOpenLazarusExt, FOpenDelphiExt, FCommonTaskExt : string;
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
    property FormatPascalExt : string read FFormatPascalExt write FFormatPascalExt;
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
  procedure ReadSettings(var Settings: TSettings);
  procedure WriteSettings(const Settings: TSettings);

  procedure CheckUpdates;


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
  Registry,
  TypInfo,
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

function CheckTokenMembership(TokenHandle: THandle; SidToCheck: PSID; var IsMember: BOOL): BOOL; stdcall; external advapi32;


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


end.
