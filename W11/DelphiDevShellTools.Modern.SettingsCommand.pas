// Mozilla Public License 1.1; https://www.mozilla.org/MPL/1.1/
// Copyright (C) 2026 Rodrigo Ruz V.
unit DelphiDevShellTools.Modern.SettingsCommand;

interface

uses
  Winapi.Windows, Winapi.ActiveX, Winapi.ShlObj, System.Win.ComObj;

const
  // Independent of the classic IContextMenu CLSID. Also used in AppxManifest.xml.
  CLSID_ModernSettings: TGUID = '{E91A76D4-28C2-4E6D-A52A-6A39F28320C7}';

type
  TModernSettingsCommand = class(TComObject, IExplorerCommand)
  protected
    function GetTitle(const Items: IShellItemArray; var Title: LPWSTR): HRESULT; stdcall;
    function GetIcon(const Items: IShellItemArray; var Icon: LPWSTR): HRESULT; stdcall;
    function GetToolTip(const Items: IShellItemArray; var ToolTip: LPWSTR): HRESULT; stdcall;
    function GetCanonicalName(var CommandName: TGUID): HRESULT; stdcall;
    function GetState(const Items: IShellItemArray; SlowAllowed: BOOL;
      var State: TExpCmdState): HRESULT; stdcall;
    function Invoke(const Items: IShellItemArray; const BindContext: IBindCtx): HRESULT; stdcall;
    function GetFlags(var Flags: TExpCmdFlags): HRESULT; stdcall;
    function EnumSubCommands(out Commands: IEnumExplorerCommand): HRESULT; stdcall;
  end;

implementation

uses
  System.SysUtils, System.StrUtils, System.Win.ComServ,
  DelphiDevShellTools.Commands, DelphiDevShellTools.Execution;

function Win32Failure(Code: Cardinal): HRESULT;
begin
  if Code = 0 then Result := E_FAIL
  else Result := HRESULT($80070000 or (Code and $FFFF));
end;

function ExceptionResult: HRESULT;
begin
  // A Delphi exception must never cross a COM ABI boundary.
  if ExceptObject is EOutOfMemory then Result := E_OUTOFMEMORY
  else if ExceptObject is EOSError then
    Result := Win32Failure(EOSError(ExceptObject).ErrorCode)
  else if ExceptObject is EFileNotFoundException then
    Result := Win32Failure(ERROR_FILE_NOT_FOUND)
  else Result := E_FAIL;
end;

function CopyCOMString(const Value: string; var Output: LPWSTR): HRESULT;
var Bytes: NativeUInt;
begin
  Output := nil;
  Bytes := (Length(Value) + 1) * SizeOf(WideChar);
  Output := CoTaskMemAlloc(Bytes);
  if Output = nil then Exit(E_OUTOFMEMORY);
  Move(PWideChar(Value)^, Output^, Bytes);
  Result := S_OK;
end;

function ModulePath: string;
var Buffer: array[0..32767] of WideChar; Count: DWORD;
begin
  Count := GetModuleFileNameW(HInstance, Buffer, Length(Buffer));
  if Count = 0 then RaiseLastOSError;
  if Count >= DWORD(Length(Buffer)) then
    raise EOSError.Create('Modern command module path is too long.');
  SetString(Result, Buffer, Count);
end;

function SupportedSelection(const Items: IShellItemArray): Boolean;
var Count: DWORD; Item: IShellItem; Name: PWideChar;
begin
  Result := False;
  if (Items = nil) or Failed(Items.GetCount(Count)) or (Count <> 1) then Exit;
  if Failed(Items.GetItemAt(0, Item)) then Exit;
  Name := nil;
  if Failed(Item.GetDisplayName(SIGDN_FILESYSPATH, Name)) then Exit;
  try
    // M1 intentionally matches only the four manifest associations. No discovery,
    // project parsing, settings migration or filesystem probes on the menu path.
    Result := MatchText(ExtractFileExt(string(Name)), ['.pas', '.dpr', '.dproj', '.groupproj']);
  finally
    CoTaskMemFree(Name);
  end;
end;

function TModernSettingsCommand.GetTitle(const Items: IShellItemArray;
  var Title: LPWSTR): HRESULT;
begin
  Title := nil;
  try
    Result := CopyCOMString('Delphi Dev Shell Tools settings', Title);
  except Result := ExceptionResult; end;
end;

function TModernSettingsCommand.GetIcon(const Items: IShellItemArray;
  var Icon: LPWSTR): HRESULT;
begin
  Icon := nil;
  try
    Result := CopyCOMString(ModulePath + ',-101', Icon);
  except Result := ExceptionResult; end;
end;

function TModernSettingsCommand.GetToolTip(const Items: IShellItemArray;
  var ToolTip: LPWSTR): HRESULT;
begin
  ToolTip := nil;
  Result := E_NOTIMPL;
end;

function TModernSettingsCommand.GetCanonicalName(var CommandName: TGUID): HRESULT;
begin
  CommandName := CLSID_ModernSettings;
  Result := S_OK;
end;

function TModernSettingsCommand.GetState(const Items: IShellItemArray;
  SlowAllowed: BOOL; var State: TExpCmdState): HRESULT;
begin
  State := ECS_HIDDEN;
  try
    if SupportedSelection(Items) then State := ECS_ENABLED;
    Result := S_OK;
  except Result := ExceptionResult; end;
end;

function TModernSettingsCommand.Invoke(const Items: IShellItemArray;
  const BindContext: IBindCtx): HRESULT;
var Request: TCommandRequest; Directory: string;
begin
  try
    if not SupportedSelection(Items) then Exit(E_INVALIDARG);
    Directory := ExtractFilePath(ModulePath);
    Request := TCommandRequest.Create(ckProgram);
    Request.Executable := Directory + 'GUIDelphiDevShell.exe';
    Request.WorkingDirectory := Directory;
    Request.Arguments := TArray<string>.Create('-settings');
    // Same dispatcher, JSON request and GUI as the classic Settings action.
    DispatchCommand(Request);
    Result := S_OK;
  except Result := ExceptionResult; end;
end;

function TModernSettingsCommand.GetFlags(var Flags: TExpCmdFlags): HRESULT;
begin
  Flags := ECF_DEFAULT;
  Result := S_OK;
end;

function TModernSettingsCommand.EnumSubCommands(out Commands: IEnumExplorerCommand): HRESULT;
begin
  Commands := nil;
  Result := E_NOTIMPL;
end;

initialization
  TComObjectFactory.Create(ComServer, TModernSettingsCommand, CLSID_ModernSettings,
    '', 'Delphi Dev Shell Tools modern Settings command', ciMultiInstance, tmApartment);
end.
