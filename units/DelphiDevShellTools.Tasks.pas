//**************************************************************************************************
//
// Unit DelphiDevShellTools.Tasks
// Adapts menu actions to clipboard operations and typed execution requests.
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
// The Original Code is DelphiDevShellTools.Tasks.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.Tasks;

interface

uses
   DelphiDevShellTools.Commands,
   DelphiDevShellTools.Misc,
   DelphiDevShellTools.DelphiVersions,
   Winapi.Windows,
   System.RTTI;

type

  TDelphiDevShellTasks=class
  private
  public
    class function ProgramCommand(const Executable, FileName: string; const Arguments: TArray<string>): TCommandRequest;
    class function IDECommand(Kind: TCommandKind; const FileName: string; Version: TDelphiVersionData): TCommandRequest;
    class procedure ExecuteRequest(Info: TMethodInfo);
    class function ParseMacros(const Data: string; DelphiVersionData: TDelphiVersionData; const  FileName: string): string;
    class procedure OpenWithDelphi(Info: TMethodInfo);
    class procedure OpenRADStudio(Info: TMethodInfo);
    class procedure MSBuildWithDelphi_Default(Info: TMethodInfo);
    class procedure MSBuildWithDelphi(Info: TMethodInfo);

    class procedure OpenWithNotepad(Info: TMethodInfo);
    class procedure OpenWithApp(Info: TMethodInfo);
    class procedure OpenCmdHere(Info: TMethodInfo);
    class procedure CopyPathClipboard(Info: TMethodInfo);
    class procedure CopyFileNameClipboard(Info: TMethodInfo);
    class procedure CopyFileNameUrlClipboard(Info: TMethodInfo);
    class procedure CopyFileNameUNCClipboard(Info: TMethodInfo);
    class procedure CopyFileNameUnixClipboard(Info: TMethodInfo);
    class procedure CopyFileContentClipboard(Info: TMethodInfo);
    class procedure OpenGUI(Info: TMethodInfo);
    class procedure OpenGUICheckSum(Info: TMethodInfo);
    class procedure OpenRADCmd(Info: TMethodInfo);

    class procedure OpenVclStyle(Info: TMethodInfo);
    class procedure PAClientTest(Info: TMethodInfo);
    class procedure RADTools(Info: TMethodInfo);
    class procedure ExternalTools(Info: TMethodInfo);

    class procedure Updater(Info: TMethodInfo);


    //Lazarus & FPC
    class procedure OpenWithLazarus(Info: TMethodInfo);
    class procedure BuildWithLazBuild(Info: TMethodInfo);
    class procedure FPCTools(Info: TMethodInfo);
    //-------------------

  end;

implementation

uses
  DelphiDevShellTools.Logging,
  DelphiDevShellTools.Execution,
  DelphiDevShellTools.LazarusVersions,
  Vcl.Clipbrd,
  System.IOUtils,
  System.Classes,
  System.SysUtils,
  WinAPi.ShellAPi;

{ TDelphiDevShellTasks }


class function TDelphiDevShellTasks.ProgramCommand(const Executable, FileName: string;
  const Arguments: TArray<string>): TCommandRequest;
begin
  Result := TCommandRequest.Create(ckProgram, FileName);
  Result.Executable := Executable;
  if Result.WorkingDirectory = '' then Result.WorkingDirectory := ExtractFileDir(Executable);
  Result.Arguments := Arguments;
end;

class function TDelphiDevShellTasks.IDECommand(Kind: TCommandKind; const FileName: string;
  Version: TDelphiVersionData): TCommandRequest;
begin
  Result := TCommandRequest.Create(Kind, FileName);
  if SameText(ExtractFileExt(FileName), '.dpr') and FileExists(ChangeFileExt(FileName, '.dproj')) then
    Result.FileName := ChangeFileExt(FileName, '.dproj');
  if Version <> nil then
  begin
    Result.ProfileId := Version.Installation.Id;
    if Kind in [ckBuild, ckTerminal] then
      Result.EnvironmentScript := Version.Installation.EnvironmentScript;
    Result.Executable := Version.Path;
    if (Kind = ckOpenIDE) and (Result.ProfileId = '') then
    begin
      Result.Kind := ckProgram;
      Result.Arguments := [Result.FileName];
      if Version.Version >= Delphi2005 then Result.Arguments := ['-pDelphi', Result.FileName];
    end;
  end;
end;

class procedure TDelphiDevShellTasks.ExecuteRequest(Info: TMethodInfo);
begin
  DispatchCommand(Info.Request);
end;

procedure SendScript(Info: TMethodInfo);
var Request: TCommandRequest; Version: TDelphiVersionData;
begin
  Request := TCommandRequest.Create(ckScript, Info.Value3.AsString);
  Request.Script := Info.Value1.AsString;
  Request.Elevate := Info.Value2.AsBoolean;
  if not Info.Value4.IsEmpty then
  begin
    Version := TDelphiVersionData(Info.Value4.AsObject);
    Request.MacroBin := ExtractFilePath(Version.Path);
    if Version.Installation.RootDirectory <> '' then
      Request.MacroBin := IncludeTrailingPathDelimiter(Version.Installation.RootDirectory) + 'bin\';
  end;
  if IsLazarusInstalled then Request.MacroFPC := GetFPCPath;
  DispatchCommand(Request);
end;

class procedure TDelphiDevShellTasks.BuildWithLazBuild(Info: TMethodInfo);
var Request: TCommandRequest;
begin
  Request := ProgramCommand(IncludeTrailingPathDelimiter(Info.Value1.AsString) + 'lazbuild.exe',
    Info.Value2.AsString, [Info.Value2.AsString]);
  Request.WaitForExit := True;
  DispatchCommand(Request);
end;


class procedure TDelphiDevShellTasks.CopyFileContentClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := TFile.ReadAllText(Info.Value1.AsString);
 except
   on  E: Exception do
   log(Format('TDelphiDevShellTasks.CopyFileContentClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.CopyFileNameClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := Info.Value1.AsString;
 except
   on  E: Exception do
   log(Format('TDelphiDevShellTasks.CopyFileNameClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;


class procedure TDelphiDevShellTasks.CopyFileNameUNCClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := GetUNCNameEx(Info.Value1.AsString);
 except
   on  E: Exception do
   log(Format('TDelphiDevShellTasks.CopyFileNameUNCClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.CopyFileNameUnixClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := StringReplace(Info.Value1.AsString, '\','/', [rfReplaceAll]);
 except
   on  E: Exception do
   log(Format('TDelphiDevShellTasks.CopyFileNameUnixClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.CopyFileNameUrlClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := LocalPathToFileURL(Info.Value1.AsString);
 except
   on  E: Exception do
   log(Format('TDelphiDevShellTasks.CopyFileNameUrlClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;
class procedure TDelphiDevShellTasks.CopyPathClipboard(Info: TMethodInfo);
var
  FilePath: string;
begin
 try
  FilePath:=ExtractFilePath(Info.Value1.AsString);
  Clipboard.AsText := FilePath;
 except
   on  E: Exception do
   log(Format('TDelphiDevShellTasks.CopyPathClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.ExternalTools(Info: TMethodInfo);
begin
  SendScript(Info);
end;


class function TDelphiDevShellTasks.ParseMacros(const Data: string; DelphiVersionData: TDelphiVersionData;const FileName: string): string;
begin
  Result:=Data;
  if Pos('$', Result)>0 then
  begin
    Result:=StringReplace(Result, '$FILENAME$', FileName, [rfReplaceAll]);
    Result:=StringReplace(Result, '$NAME$', ExtractFileName(FileName), [rfReplaceAll]);
    Result:=StringReplace(Result, '$ONLYNAME$', ChangeFileExt(ExtractFileName(FileName),''), [rfReplaceAll]);
    Result:=StringReplace(Result, '$EXT$', ExtractFileExt(FileName), [rfReplaceAll]);
    Result:=StringReplace(Result, '$PATH$', ExtractFilePath(FileName), [rfReplaceAll]);
    if IsLazarusInstalled then
     Result:=StringReplace(Result, '$FPCPATH$', GetFPCPath, [rfReplaceAll]);
    if (DelphiVersionData<>nil) {and (InstalledDelphiVersions.Count>0)} then
     Result:=StringReplace(Result, '$BDSPATH$', ExtractFilePath(DelphiVersionData.Path), [rfReplaceAll]);
  end;
end;


class procedure TDelphiDevShellTasks.FPCTools(Info: TMethodInfo);
begin
  SendScript(Info);
end;


class procedure TDelphiDevShellTasks.MSBuildWithDelphi(Info: TMethodInfo);
var Request: TCommandRequest;
begin
  Request := IDECommand(ckBuild, Info.Value4.AsString, TDelphiVersionData(Info.Value1.AsObject));
  Request.Platform := Info.Value2.AsString;
  Request.Configuration := Info.Value3.AsString;
  DispatchCommand(Request);
end;


class procedure TDelphiDevShellTasks.MSBuildWithDelphi_Default(Info: TMethodInfo);
begin
  DispatchCommand(IDECommand(ckBuild, Info.Value2.AsString, TDelphiVersionData(Info.Value1.AsObject)));
end;


class procedure TDelphiDevShellTasks.OpenCmdHere(Info: TMethodInfo);
var Request: TCommandRequest;
begin
  Request := TCommandRequest.Create(ckTerminal, Info.Value2.AsString);
  Request.Elevate := Info.Value1.AsBoolean;
  DispatchCommand(Request);
end;


class procedure TDelphiDevShellTasks.OpenGUI(Info: TMethodInfo);
begin
  DispatchCommand(ProgramCommand(ExtractFilePath(DelphiDevShellTools.Misc.GetModuleName) + 'GUIDelphiDevShell.exe', '', [Info.Value1.AsString]));
end;


class procedure TDelphiDevShellTasks.OpenGUICheckSum(Info: TMethodInfo);
begin
  DispatchCommand(ProgramCommand(ExtractFilePath(DelphiDevShellTools.Misc.GetModuleName) + 'GUIDelphiDevShell.exe', Info.Value2.AsString,
    [Info.Value1.AsString, Info.Value2.AsString]));
end;


class procedure TDelphiDevShellTasks.OpenRADCmd(Info: TMethodInfo);
begin
  DispatchCommand(IDECommand(ckTerminal, Info.Value2.AsString, TDelphiVersionData(Info.Value1.AsObject)));
end;


class procedure TDelphiDevShellTasks.OpenRADStudio(Info: TMethodInfo);
begin
  DispatchCommand(IDECommand(ckOpenIDE, Info.Value2.AsString, TDelphiVersionData(Info.Value1.AsObject)));
end;


class procedure TDelphiDevShellTasks.OpenVclStyle(Info: TMethodInfo);
var Version: TDelphiVersionData; Executable: string;
begin
  Version := TDelphiVersionData(Info.Value1.AsObject);
  Executable := IncludeTrailingPathDelimiter(Version.Installation.RootDirectory) + 'bin\';
  if Version.Version = DelphiXE2 then Executable := Executable + 'VCLStyleTest.exe'
  else Executable := Executable + 'VCLStyleViewer.exe';
  DispatchCommand(ProgramCommand(Executable, Info.Value2.AsString, [Info.Value2.AsString]));
end;


class procedure TDelphiDevShellTasks.OpenWithApp(Info: TMethodInfo);
begin
  DispatchCommand(ProgramCommand(Info.Value1.AsString, Info.Value2.AsString, [Info.Value2.AsString]));
end;


class procedure TDelphiDevShellTasks.OpenWithDelphi(Info: TMethodInfo);
begin
  DispatchCommand(IDECommand(ckOpenIDE, Info.Value2.AsString, TDelphiVersionData(Info.Value1.AsObject)));
end;


class procedure TDelphiDevShellTasks.OpenWithLazarus(Info: TMethodInfo);
begin
  DispatchCommand(ProgramCommand(Info.Value1.AsString, Info.Value2.AsString, [Info.Value2.AsString]));
end;


class procedure TDelphiDevShellTasks.OpenWithNotepad(Info: TMethodInfo);
begin
  DispatchCommand(ProgramCommand(ExtractFilePath(CommandProcessor) + 'notepad.exe', Info.Value1.AsString, [Info.Value1.AsString]));
end;


class procedure TDelphiDevShellTasks.PAClientTest(Info: TMethodInfo);
var Version: TDelphiVersionData; Request: TCommandRequest;
begin
  Version := TDelphiVersionData(Info.Value1.AsObject);
  Request := ProgramCommand(IncludeTrailingPathDelimiter(Version.Installation.RootDirectory) + 'bin\PAClient.exe',
    '', [Info.Value2.AsString]);
  Request.WaitForExit := True;
  DispatchCommand(Request);
end;


class procedure TDelphiDevShellTasks.RADTools(Info: TMethodInfo);
begin
  SendScript(Info);
end;


class procedure TDelphiDevShellTasks.Updater(Info: TMethodInfo);
begin
  CheckUpdates(False);
end;

end.
