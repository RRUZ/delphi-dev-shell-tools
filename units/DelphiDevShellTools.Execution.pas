//**************************************************************************************************
//
// Unit DelphiDevShellTools.Execution
// Dispatches command requests and runs processes with isolated scripts and build environments.
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
// The Original Code is DelphiDevShellTools.Execution.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.Execution;

interface

uses Winapi.ShellAPI, System.SysUtils, System.Classes, DelphiDevShellTools.Commands,
  DelphiDevShellTools.Installations;

type TCommandLauncher = reference to function(var Info: TShellExecuteInfo): Boolean;

function NewRequestDirectory: string;
procedure RemoveRequestDirectory(const Directory: string);
procedure DispatchCommand(const Request: TCommandRequest; const Launcher: TCommandLauncher = nil);
procedure ResolveIDECommand(var Request: TCommandRequest; const Installation: TIDEInstallation;
  Variant: TIDEVariant);
function ExecuteCommand(const Request: TCommandRequest; const Directory, LogFile: string;
  const OnWait: TProc = nil): Cardinal;
function CommandProcessor: string;
function ScriptWithMacros(const Script: string): string;

implementation

uses Winapi.Windows, System.IOUtils;

function RequestRoot: string;
begin
  Result := IncludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA')) +
    'DelphiDevShellTools\Requests';
end;

function NewRequestDirectory: string;
begin
  Result := RequestRoot + '\' + TGUID.NewGuid.ToString;
  if not ForceDirectories(Result) then RaiseLastOSError;
end;

procedure RemoveRequestDirectory(const Directory: string);
var Name: string;
begin
  if not SameText(ExtractFileDir(ExcludeTrailingPathDelimiter(ExpandFileName(Directory))), RequestRoot) then
    raise EArgumentException.Create('Invalid request directory.');
  // Only files owned by this invocation; never recursively delete a caller's path.
  for Name in ['request.json', 'command.cmd', 'environment.txt'] do
    if FileExists(Directory + '\' + Name) then TFile.Delete(Directory + '\' + Name);
  RemoveDir(Directory);
end;

function CommandProcessor: string;
var Buffer: array[0..32767] of Char;
begin
  if GetSystemDirectory(Buffer, Length(Buffer)) = 0 then RaiseLastOSError;
  Result := IncludeTrailingPathDelimiter(Buffer) + 'cmd.exe';
end;

procedure DispatchCommand(const Request: TCommandRequest; const Launcher: TCommandLauncher);
var Directory, FileName, Helper, Params: string; Info: TShellExecuteInfo;
  Buffer: array[0..32767] of Char;
begin
  if GetModuleFileName(HInstance, Buffer, Length(Buffer)) = 0 then RaiseLastOSError;
  Helper := ExtractFilePath(Buffer) + 'GUIDelphiDevShell.exe';
  if not Assigned(Launcher) and not FileExists(Helper) then raise EFileNotFoundException.Create('Command runner is missing: ' + Helper);
  Directory := NewRequestDirectory;
  try
    FileName := Directory + '\request.json';
    TFile.WriteAllText(FileName, Request.ToJSON, TEncoding.UTF8);
    Params := '--execute ' + QuoteArgument(FileName);
    ZeroMemory(@Info, SizeOf(Info));
    Info.cbSize := SizeOf(Info);
    Info.fMask := SEE_MASK_NOCLOSEPROCESS or SEE_MASK_FLAG_NO_UI;
    Info.lpVerb := 'open';
    if Request.Elevate then Info.lpVerb := 'runas';
    Info.lpFile := PChar(Helper);
    Info.lpParameters := PChar(Params);
    Info.lpDirectory := PChar(ExtractFileDir(Helper));
    Info.nShow := SW_SHOWNORMAL;
    if Assigned(Launcher) then
    begin
      if not Launcher(Info) then RaiseLastOSError;
    end
    else if not ShellExecuteEx(@Info) then RaiseLastOSError;
    if Info.hProcess <> 0 then CloseHandle(Info.hProcess);
  except
    RemoveRequestDirectory(Directory);
    raise;
  end;
end;

procedure ResolveIDECommand(var Request: TCommandRequest; const Installation: TIDEInstallation;
  Variant: TIDEVariant);
begin
  Request.ProfileId := Installation.Id;
  Request.Variant := Variant;
  if Request.Kind = ckOpenIDE then
  begin
    Request.EnvironmentScript := '';
    Request.Executable := Installation.Executable(Variant);
    if Request.Executable = '' then raise EFileNotFoundException.Create('The selected IDE variant is unavailable.');
    Request.Arguments := TArray<string>.Create('-pDelphi', Request.FileName);
  end
  else if Request.Kind in [ckBuild, ckTerminal] then
  begin
    if Installation.EnvironmentScript = '' then raise EFileNotFoundException.Create('The selected installation has no rsvars.bat.');
    if (Request.Kind = ckBuild) and (Request.Platform <> '') and
       not Installation.SupportsPlatform(Request.Platform) then
      raise EArgumentException.Create('The selected installation does not support ' + Request.Platform + '.');
    Request.EnvironmentScript := Installation.EnvironmentScript;
  end;
end;

function CurrentEnvironment: TStringList;
var Block, Cursor: PChar; Item: string;
begin
  Result := TStringList.Create;
  Result.CaseSensitive := False;
  Block := GetEnvironmentStrings;
  try
    Cursor := Block;
    while Cursor^ <> #0 do
    begin
      Item := Cursor;
      if Pos('=', Item) > 1 then Result.Add(Item);
      Inc(Cursor, Length(Item) + 1);
    end;
  finally
    FreeEnvironmentStrings(Block);
  end;
end;

function EnvironmentBlock(Variables: TStrings): string;
var Sorted: TStringList; Item: string;
begin
  Result := '';
  Sorted := TStringList.Create;
  try
    Sorted.Assign(Variables);
    Sorted.CaseSensitive := False;
    Sorted.Sort;
    for Item in Sorted do Result := Result + Item + #0;
    Result := Result + #0;
  finally
    Sorted.Free;
  end;
end;

function RunProcess(const Executable, Parameters, WorkingDirectory: string; Variables: TStrings;
  Wait, Console: Boolean; const CaptureFile: string; const OnWait: TProc): Cardinal;
var Startup: TStartupInfo; Process: TProcessInformation; Security: TSecurityAttributes;
  Output, Input: THandle; Cmd, Env: string; EnvPointer: Pointer; Flags, WaitResult: Cardinal;
begin
  if not FileExists(Executable) then raise EFileNotFoundException.Create('Executable is missing: ' + Executable);
  if not DirectoryExists(WorkingDirectory) then raise EDirectoryNotFoundException.Create('Working directory is missing: ' + WorkingDirectory);
  if Pos(#0, Parameters) <> 0 then raise EArgumentException.Create('Invalid command argument.');
  Cmd := QuoteArgument(Executable) + ' ' + Parameters;
  UniqueString(Cmd);
  EnvPointer := nil;
  if Variables <> nil then
  begin
    Env := EnvironmentBlock(Variables);
    EnvPointer := PChar(Env);
  end;
  ZeroMemory(@Startup, SizeOf(Startup));
  Startup.cb := SizeOf(Startup);
  ZeroMemory(@Process, SizeOf(Process));
  Output := INVALID_HANDLE_VALUE;
  Input := INVALID_HANDLE_VALUE;
  Flags := CREATE_UNICODE_ENVIRONMENT;
  if Console then Flags := Flags or CREATE_NEW_CONSOLE;
  try
    if CaptureFile <> '' then
    begin
      Security.nLength := SizeOf(Security);
      Security.lpSecurityDescriptor := nil;
      Security.bInheritHandle := True;
      Output := CreateFile(PChar(CaptureFile), GENERIC_WRITE, FILE_SHARE_READ, @Security, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0);
      if Output = INVALID_HANDLE_VALUE then RaiseLastOSError;
      Input := CreateFile('NUL', GENERIC_READ, FILE_SHARE_READ or FILE_SHARE_WRITE, @Security, OPEN_EXISTING, 0, 0);
      if Input = INVALID_HANDLE_VALUE then RaiseLastOSError;
      Startup.dwFlags := STARTF_USESTDHANDLES;
      Startup.hStdInput := Input;
      Startup.hStdOutput := Output;
      Startup.hStdError := Output;
      Flags := CREATE_UNICODE_ENVIRONMENT or CREATE_NO_WINDOW;
    end;
    if not CreateProcess(PChar(Executable), PChar(Cmd), nil, nil, CaptureFile <> '', Flags,
      EnvPointer, PChar(WorkingDirectory), Startup, Process) then RaiseLastOSError;
    try
      Result := 0;
      if Wait then
      begin
        repeat
          WaitResult := WaitForSingleObject(Process.hProcess, 50);
          if WaitResult = WAIT_FAILED then RaiseLastOSError;
          if Assigned(OnWait) then OnWait();
        until WaitResult <> WAIT_TIMEOUT;
        if not GetExitCodeProcess(Process.hProcess, Result) then RaiseLastOSError;
      end;
    finally
      CloseHandle(Process.hThread);
      CloseHandle(Process.hProcess);
    end;
  finally
    if Output <> INVALID_HANDLE_VALUE then CloseHandle(Output);
    if Input <> INVALID_HANDLE_VALUE then CloseHandle(Input);
  end;
end;

procedure LoadBuildEnvironment(Variables: TStrings; const Script, Directory: string);
var Captured: TStringList; CaptureFile, Line: string; Code: Cardinal;
begin
  if not FileExists(Script) then raise EFileNotFoundException.Create('Build environment is missing: ' + Script);
  Variables.Values['DDS_RSVARS'] := Script;
  CaptureFile := Directory + '\environment.txt';
  Code := RunProcess(CommandProcessor, '/d /u /v:off /s /c ""%DDS_RSVARS%" >nul && set"',
    Directory, Variables, True, False, CaptureFile, nil);
  if Code <> 0 then raise EOSError.CreateFmt('rsvars.bat failed with exit code %d.', [Code]);
  Captured := TStringList.Create;
  try
    Captured.LoadFromFile(CaptureFile, TEncoding.Unicode);
    Variables.Clear;
    for Line in Captured do
      if Pos('=', Line) > 1 then Variables.Add(Line);
    if Variables.Values['BDS'] = '' then raise EOSError.Create('rsvars.bat did not supply a build environment.');
  finally
    Captured.Free;
  end;
end;

function ScriptWithMacros(const Script: string): string;
const Names: array[0..6] of string = ('FILENAME','NAME','ONLYNAME','EXT','PATH','BDSPATH','FPCPATH');
var Name: string;
begin
  Result := Script;
  for Name in Names do Result := StringReplace(Result, '$' + Name + '$', '%DDS_' + Name + '%', [rfReplaceAll]);
end;

function ExecuteCommand(const Request: TCommandRequest; const Directory, LogFile: string;
  const OnWait: TProc): Cardinal;
var Variables: TStringList; Exe, Parameters, Work, ScriptPath, Text: string;
  ScriptEncoding: TEncoding;
  Args: TArray<string>; Arg: string; Capture: string; Console, Wait: Boolean;
begin
  Variables := CurrentEnvironment;
  try
    Work := Request.WorkingDirectory;
    if Work = '' then Work := Directory;
    if (Request.FileName <> '') and not FileExists(Request.FileName) then
      raise EFileNotFoundException.Create('Selected file is missing: ' + Request.FileName);
    if Request.EnvironmentScript <> '' then LoadBuildEnvironment(Variables, Request.EnvironmentScript, Directory);
    Exe := Request.Executable;
    Args := Request.Arguments;
    Capture := '';
    Console := False;
    Wait := Request.WaitForExit;
    if Request.Kind = ckBuild then
    begin
      Exe := IncludeTrailingPathDelimiter(Variables.Values['FrameworkDir']) + 'MSBuild.exe';
      if Variables.Values['FrameworkDir'] = '' then raise EOSError.Create('No MSBuild path in the selected build environment.');
      Args := TArray<string>.Create(Request.FileName, '/nologo', '/t:Build');
      if Request.Platform <> '' then Args := Args + ['/p:Platform=' + Request.Platform];
      if Request.Configuration <> '' then Args := Args + ['/p:Config=' + Request.Configuration];
      Capture := LogFile;
      Wait := True;
    end;
    Parameters := '';
    for Arg in Args do Parameters := Parameters + ' ' + QuoteArgument(Arg);
    Variables.Values['DDS_WORK_DIR'] := Work;
    if Request.Kind = ckTerminal then
    begin
      Exe := CommandProcessor;
      Parameters := '/d /v:off /k pushd "%DDS_WORK_DIR%"';
      Work := Directory;
      Console := True;
      Wait := True;
    end;
    if Request.Kind = ckScript then
    begin
      Variables.Values['DDS_FILENAME'] := Request.FileName;
      Variables.Values['DDS_NAME'] := ExtractFileName(Request.FileName);
      Variables.Values['DDS_ONLYNAME'] := ChangeFileExt(ExtractFileName(Request.FileName), '');
      Variables.Values['DDS_EXT'] := ExtractFileExt(Request.FileName);
      Variables.Values['DDS_PATH'] := IncludeTrailingPathDelimiter(ExtractFileDir(Request.FileName));
      Variables.Values['DDS_BDSPATH'] := Request.MacroBin;
      Variables.Values['DDS_FPCPATH'] := Request.MacroFPC;
      if Request.MacroBin = '' then Variables.Values['DDS_BDSPATH'] := '$BDSPATH$';
      if Request.MacroFPC = '' then Variables.Values['DDS_FPCPATH'] := '$FPCPATH$';
      ScriptPath := Directory + '\command.cmd';
      Text := '@echo off'#13#10'setlocal DisableDelayedExpansion'#13#10'chcp 65001 >nul'#13#10 +
        'pushd "%DDS_WORK_DIR%" || exit /b 1'#13#10 + ScriptWithMacros(Request.Script) + #13#10;
      ScriptEncoding := TUTF8Encoding.Create(False);
      try
        TFile.WriteAllText(ScriptPath, Text, ScriptEncoding);
      finally
        ScriptEncoding.Free;
      end;
      Variables.Values['DDS_SCRIPT'] := ScriptPath;
      Exe := CommandProcessor;
      Parameters := '/d /v:off /s /c ""%DDS_SCRIPT%""';
      Work := Directory;
      Console := True;
      Wait := True;
    end;
    // Let Windows adapt inherited variables when a 32-bit runner launches a 64-bit program.
    if (Request.Kind in [ckProgram, ckOpenIDE]) and (Request.EnvironmentScript = '') then
      Result := RunProcess(Exe, Parameters, Work, nil, Wait, Console, Capture, OnWait)
    else
      Result := RunProcess(Exe, Parameters, Work, Variables, Wait, Console, Capture, OnWait);
  finally
    Variables.Free;
  end;
end;

end.
