//**************************************************************************************************
//
// Unit ShellTools.ExecutionTests
// Shared unit for the Delphi Dev Shell Tools
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
// The Original Code is ShellTools.ExecutionTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.ExecutionTests;

interface

uses DUnitX.TestFramework;

type
  [TestFixture]
  TExecutionTests = class
  public
    [Test] procedure CancelledElevationCleansRequest;
    [Test] procedure MissingInputAndDirectoryFail;
    [Test] procedure ProcessExitCodeIsReported;
    [Test] procedure NativeChildInheritsNativeEnvironment;
    [Test] procedure RequestRoundTrip;
    [Test] procedure InvalidRequestRejected;
    [Test] procedure DirectArgumentsAndWorkingDirectory;
    [Test] procedure ConcurrentScripts;
    [Test] procedure DiscoveryDeduplicatesAndValidates;
    [Test] procedure IDEBitnessIsIndependentOfBuildTarget;
    [Test] procedure SelectedEnvironmentDoesNotChangeParent;
    [Test] procedure MissingExecutableFails;
    [Test] procedure SelectionRequiresExplicitChoiceForUnknownProjects;
  end;

  TUNCExecutionTests = class
  public
    [Test] procedure UNCWorkingDirectoryAndScript;
  end;

procedure WriteArgumentProbe;

implementation

uses Winapi.Windows, Winapi.ShellAPI, System.Generics.Collections, System.SysUtils, System.Classes, System.IOUtils, System.JSON, System.Threading,
  DelphiDevShellTools.Commands, DelphiDevShellTools.Execution, DelphiDevShellTools.Installations;

procedure WriteArgumentProbe;
var Obj: TJSONObject; Args: TJSONArray; I, Count: Integer; Argv, Cursor: PPWideChar;
begin
  Obj := TJSONObject.Create;
  try
    Args := TJSONArray.Create;
    Obj.AddPair('arguments', Args);
    Argv := CommandLineToArgvW(GetCommandLine, Count);
    if Argv = nil then RaiseLastOSError;
    try
      Cursor := Argv;
      Inc(Cursor, 3);
      for I := 3 to Count - 1 do begin Args.Add(Cursor^); Inc(Cursor); end;
    finally
      LocalFree(HLOCAL(Argv));
    end;
    Obj.AddPair('directory', GetCurrentDir);
    Obj.AddPair('BDS', GetEnvironmentVariable('BDS'));
    Obj.AddPair('architecture', GetEnvironmentVariable('PROCESSOR_ARCHITECTURE'));
    TFile.WriteAllText(ParamStr(2), Obj.ToJSON, TEncoding.UTF8);
  finally
    Obj.Free;
  end;
end;

procedure TExecutionTests.RequestRoundTrip;
var A, B: TCommandRequest;
begin
  A := TCommandRequest.Create(ckBuild, 'C:\a & b\' + #$65E5#$672C + ' %PATH%!^.dproj');
  A.ProfileId := 'bds:37.0:c:\delphi';
  A.Arguments := ['', 'a"b', 'C:\ending\'];
  A.Variant := ivWin64;
  A.Configuration := 'Release';
  A.Platform := 'Win32';
  B := TCommandRequest.FromJSON(A.ToJSON);
  Assert.AreEqual(A.FileName, B.FileName);
  Assert.AreEqual(A.ProfileId, B.ProfileId);
  Assert.AreEqual(Ord(A.Variant), Ord(B.Variant));
  Assert.AreEqual(A.Arguments[1], B.Arguments[1]);
  Assert.AreEqual(A.Platform, B.Platform);
  Assert.IsFalse(B.Elevate, 'Normal execution is the default.');
end;

procedure TExecutionTests.InvalidRequestRejected;
begin
  Assert.WillRaise(procedure begin TCommandRequest.FromJSON('{"version":999}'); end, EArgumentException);
  Assert.WillRaise(procedure begin TCommandRequest.FromJSON('{"version":1,"kind":99,"variant":0}'); end, EArgumentException);
end;

procedure TExecutionTests.DirectArgumentsAndWorkingDirectory;
var Directory, Output: string; Request: TCommandRequest; Value: TJSONValue;
  Args: TJSONArray; I: Integer; Expected: TArray<string>;
begin
  Directory := NewRequestDirectory;
  Output := Directory + '\probe.json';
  try
    Expected := ['', 'space value', 'a"b', 'C:\ending\', '%PATH%!&^()', #$65E5#$672C, '\\server\share\file.pas'];
    Request := TCommandRequest.Create(ckProgram);
    Request.Executable := ParamStr(0);
    Request.WorkingDirectory := Directory;
    Request.Arguments := TArray<string>.Create('--argument-probe', Output) + Expected;
    Request.WaitForExit := True;
    Assert.AreEqual(Cardinal(0), ExecuteCommand(Request, Directory, ''));
    Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(Output, TEncoding.UTF8));
    try
      Args := TJSONObject(Value).GetValue<TJSONArray>('arguments');
      Assert.AreEqual<Integer>(Length(Expected), Args.Count);
      for I := 0 to High(Expected) do Assert.AreEqual(Expected[I], Args.Items[I].Value);
      Assert.IsTrue(SameText(Directory, TJSONObject(Value).GetValue<string>('directory')));
    finally
      Value.Free;
    end;
  finally
    if FileExists(Output) then TFile.Delete(Output);
    RemoveRequestDirectory(Directory);
  end;
end;

procedure RunScriptProbe(const Directory, Expected: string);
  var Request: TCommandRequest; FileName: string;
  begin
    FileName := Directory + '\' + #$65E5#$672C + ' & %PATH% ! ^ (sample).pas';
    TFile.WriteAllText(FileName, Expected, TEncoding.UTF8);
    try
      Request := TCommandRequest.Create(ckScript, FileName);
      Request.Script := 'copy /y "$FILENAME$" "copy.txt" >nul'#13#10'exit /b %errorlevel%';
      Assert.AreEqual(Cardinal(0), ExecuteCommand(Request, Directory, ''));
      Assert.AreEqual(Expected, TFile.ReadAllText(Directory + '\copy.txt', TEncoding.UTF8));
    finally
      if FileExists(FileName) then TFile.Delete(FileName);
      if FileExists(Directory + '\copy.txt') then TFile.Delete(Directory + '\copy.txt');
    end;
  end;

procedure TExecutionTests.ConcurrentScripts;
var A, B: string; First, Second: ITask; FirstProc, SecondProc: TProc;
begin
  A := NewRequestDirectory;
  B := NewRequestDirectory;
  try
    FirstProc := procedure begin RunScriptProbe(A, 'first'); end;
    First := TTask.Run(FirstProc);
    SecondProc := procedure begin RunScriptProbe(B, 'second'); end;
    Second := TTask.Run(SecondProc);
    TTask.WaitForAll([First, Second]);
    Assert.IsTrue(FileExists(A + '\command.cmd'));
    Assert.IsTrue(FileExists(B + '\command.cmd'));
    Assert.AreNotEqual(A, B);
  finally
    RemoveRequestDirectory(A);
    RemoveRequestDirectory(B);
  end;
end;

procedure TExecutionTests.DiscoveryDeduplicatesAndValidates;
var Candidates: TArray<TInstallationCandidate>; Items: TArray<TIDEInstallation>;
begin
  SetLength(Candidates, 3);
  Candidates[0].RegistryVersion := '37.0';
  Candidates[0].RootDirectory := 'C:\Delphi';
  Candidates[0].App32 := 'C:\Delphi\bin\bds.exe';
  Candidates[1] := Candidates[0];
  Candidates[1].RootDirectory := 'c:\delphi\';
  Candidates[1].App64 := 'C:\Delphi\bin64\bds.exe';
  Candidates[2].RegistryVersion := '23.0';
  Candidates[2].RootDirectory := 'C:\Missing';
  Items := NormalizeInstallations(Candidates,
    function(const Path: string): Boolean
    begin
      Result := SameText(Copy(Path, 1, 10), 'C:\Delphi\');
    end);
  Assert.AreEqual<Integer>(1, Length(Items));
  Assert.IsTrue(Items[0].IDE32 <> '');
  Assert.IsTrue(Items[0].IDE64 <> '');
  Assert.AreEqual('37.0', Items[0].RegistryVersion);
  Assert.AreEqual('bds:37.0:c:\delphi', Items[0].Id);
end;

procedure TExecutionTests.IDEBitnessIsIndependentOfBuildTarget;
var Item: TIDEInstallation; Request: TCommandRequest;
begin
  Item := Default(TIDEInstallation);
  Item.IDE64 := 'C:\Delphi\bin64\bds.exe';
  Item.Compiler32 := 'C:\Delphi\bin\dcc32.exe';
  Item.EnvironmentScript := 'C:\Delphi\bin\rsvars.bat';
  Request := TCommandRequest.Create(ckOpenIDE, 'C:\sample.pas');
  ResolveIDECommand(Request, Item, ivWin64);
  Assert.AreEqual(Item.IDE64, Request.Executable);
  Assert.AreEqual('C:\sample.pas', Request.Arguments[1]);
  Request := TCommandRequest.Create(ckBuild, 'C:\sample.dproj');
  Request.Platform := 'Win32';
  ResolveIDECommand(Request, Item, ivWin64);
  Assert.AreEqual(Item.EnvironmentScript, Request.EnvironmentScript);
  Request.Platform := 'Win64';
  try
    ResolveIDECommand(Request, Item, ivWin64);
    Assert.Fail('Unsupported build target was accepted.');
  except
    on E: EArgumentException do Assert.IsTrue(True);
  end;
end;

procedure TExecutionTests.SelectedEnvironmentDoesNotChangeParent;
var Items: TArray<TIDEInstallation>; Item: TIDEInstallation; Found: Boolean;
  Directory, Output, ParentBDS: string; Request: TCommandRequest; Value: TJSONValue;
begin
  Items := DiscoverInstallations;
  Found := False;
  for Item in Items do if Item.RegistryVersion = '37.0' then begin Found := True; Break; end;
  Assert.IsTrue(Found, 'Delphi 13 must be discoverable on the configured build host.');
  ParentBDS := GetEnvironmentVariable('BDS');
  Directory := NewRequestDirectory;
  Output := Directory + '\probe.json';
  try
    Request := TCommandRequest.Create(ckProgram);
    Request.Executable := ParamStr(0);
    Request.Arguments := ['--argument-probe', Output];
    Request.WorkingDirectory := Directory;
    Request.EnvironmentScript := Item.EnvironmentScript;
    Request.WaitForExit := True;
    Assert.AreEqual(Cardinal(0), ExecuteCommand(Request, Directory, ''));
    Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(Output, TEncoding.UTF8));
    try
      Assert.IsTrue(SameText(Item.RootDirectory, ExcludeTrailingPathDelimiter(TJSONObject(Value).GetValue<string>('BDS'))));
    finally
      Value.Free;
    end;
    Assert.AreEqual(ParentBDS, GetEnvironmentVariable('BDS'));
  finally
    if FileExists(Output) then TFile.Delete(Output);
    RemoveRequestDirectory(Directory);
  end;
end;

procedure TExecutionTests.MissingExecutableFails;
var Request: TCommandRequest; Directory: string;
begin
  Directory := NewRequestDirectory;
  try
    Request := TCommandRequest.Create(ckProgram);
    Request.WorkingDirectory := Directory;
    Request.Executable := Directory + '\missing.exe';
    try
      ExecuteCommand(Request, Directory, '');
      Assert.Fail('Missing executable was accepted.');
    except
      on E: EFileNotFoundException do Assert.IsTrue(True);
    end;
  finally
    RemoveRequestDirectory(Directory);
  end;
end;

procedure TExecutionTests.SelectionRequiresExplicitChoiceForUnknownProjects;
var Items: TArray<TIDEInstallation>; Request: TCommandRequest; Variant: TIDEVariant;
begin
  SetLength(Items, 2);
  Items[0].Id := 'delphi12';
  Items[0].RegistryVersion := '23.0';
  Items[0].IDE32 := 'C:\Delphi12\bin\bds.exe';
  Items[1].Id := 'delphi13';
  Items[1].RegistryVersion := '37.0';
  Items[1].IDE64 := 'C:\Delphi13\bin64\bds.exe';
  Request := TCommandRequest.Create(ckOpenIDE, 'C:\unknown.dproj');
  Assert.AreEqual(-1, SelectInstallation(Items, Request, 'delphi13', '', ivWin64, True, Variant));
  Assert.AreEqual(1, SelectInstallation(Items, Request, 'delphi13', '23.0', ivWin64, True, Variant));
  Assert.AreEqual(Ord(ivWin64), Ord(Variant));
  Request.ProfileId := 'delphi12';
  Assert.AreEqual(0, SelectInstallation(Items, Request, 'delphi13', '', ivWin64, True, Variant));
  Request.ProfileId := 'removed';
  Assert.AreEqual(-1, SelectInstallation(Items, Request, 'delphi13', '37.0', ivWin64, True, Variant));
end;

procedure TExecutionTests.CancelledElevationCleansRequest;
var Request: TCommandRequest; FileName: string; Launcher: TCommandLauncher;
begin
  Request := TCommandRequest.Create(ckTerminal);
  Request.Elevate := True;
  FileName := '';
  Launcher := function(var Info: TShellExecuteInfo): Boolean
    begin
      Assert.AreEqual('runas', string(Info.lpVerb));
      FileName := string(Info.lpParameters).Substring(10).Trim(['"']);
      Assert.IsTrue(FileExists(FileName));
      SetLastError(ERROR_CANCELLED);
      Result := False;
    end;
  // Tests are below tests\Platform\Config; use the real staged helper path.
  Assert.WillRaise(procedure begin DispatchCommand(Request, Launcher); end, EOSError);
  Assert.IsTrue(FileName <> '', 'Elevation boundary was reached.');
  Assert.IsFalse(DirectoryExists(ExtractFileDir(FileName)));
end;

procedure TExecutionTests.MissingInputAndDirectoryFail;
var Request: TCommandRequest; Directory: string;
begin
  Directory := NewRequestDirectory;
  try
    Request := TCommandRequest.Create(ckProgram, Directory + '\missing.pas');
    Request.Executable := ParamStr(0);
    Assert.WillRaise(procedure begin ExecuteCommand(Request, Directory, ''); end, EFileNotFoundException);
    Request.FileName := '';
    Request.WorkingDirectory := Directory + '\missing';
    Assert.WillRaise(procedure begin ExecuteCommand(Request, Directory, ''); end, EDirectoryNotFoundException);
  finally
    RemoveRequestDirectory(Directory);
  end;
end;

procedure TExecutionTests.ProcessExitCodeIsReported;
var Request: TCommandRequest; Directory: string;
begin
  Directory := NewRequestDirectory;
  try
    Request := TCommandRequest.Create(ckScript);
    Request.WorkingDirectory := Directory;
    Request.Script := 'exit /b 7';
    Request.WaitForExit := True;
    Assert.AreEqual(Cardinal(7), ExecuteCommand(Request, Directory, ''));
  finally
    RemoveRequestDirectory(Directory);
  end;
end;

procedure TUNCExecutionTests.UNCWorkingDirectoryAndScript;
var Share, Folder, Directory, Source, Output: string; Request: TCommandRequest; Value: TJSONValue;
begin
  Share := GetEnvironmentVariable('DDS_TEST_UNC_ROOT');
  Assert.IsTrue(Share <> '', 'DDS_TEST_UNC_ROOT must name a writable test share.');
  Assert.IsTrue(Copy(Share, 1, 2) = '\\');
  Folder := IncludeTrailingPathDelimiter(Share) + 'DDS-' + TGUID.NewGuid.ToString;
  ForceDirectories(Folder);
  Directory := NewRequestDirectory;
  Source := Folder + '\' + #$65E5#$672C + ' %PATH%! & ^ (file).pas';
  Output := Directory + '\probe.json';
  try
    TFile.WriteAllText(Source, 'UNC ' + #$65E5#$672C, TEncoding.UTF8);
    Request := TCommandRequest.Create(ckProgram, Source);
    Request.Executable := ParamStr(0);
    Request.Arguments := ['--argument-probe', Output, Source];
    Request.WaitForExit := True;
    Assert.AreEqual(Cardinal(0), ExecuteCommand(Request, Directory, ''));
    Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(Output, TEncoding.UTF8));
    try
      Assert.IsTrue(SameText(Folder, TJSONObject(Value).GetValue<string>('directory')));
    finally
      Value.Free;
    end;
    Request := TCommandRequest.Create(ckScript, Source);
    Request.Script := 'copy /y "$FILENAME$" "copy.txt" >nul'#13#10'exit /b %errorlevel%';
    Assert.AreEqual(Cardinal(0), ExecuteCommand(Request, Directory, ''));
    Assert.AreEqual('UNC ' + #$65E5#$672C, TFile.ReadAllText(Folder + '\copy.txt', TEncoding.UTF8));
  finally
    if FileExists(Output) then TFile.Delete(Output);
    RemoveRequestDirectory(Directory);
    TDirectory.Delete(Folder, True);
  end;
end;

procedure TExecutionTests.NativeChildInheritsNativeEnvironment;
var Directory, Output, NativeExe, Expected: string; Request: TCommandRequest; Value: TJSONValue;
begin
  NativeExe := ParamStr(0);
  Expected := 'AMD64';
  {$IFNDEF WIN64}
  NativeExe := StringReplace(NativeExe, '\Win32\', '\Win64\', [rfIgnoreCase]);
  if not FileExists(NativeExe) then begin NativeExe := ParamStr(0); Expected := 'x86'; end;
  {$ENDIF}
  Directory := NewRequestDirectory;
  Output := Directory + '\probe.json';
  try
    Request := TCommandRequest.Create(ckProgram);
    Request.Executable := NativeExe;
    Request.WorkingDirectory := Directory;
    Request.Arguments := ['--argument-probe', Output];
    Request.WaitForExit := True;
    Assert.AreEqual(Cardinal(0), ExecuteCommand(Request, Directory, ''));
    Value := TJSONObject.ParseJSONValue(TFile.ReadAllText(Output, TEncoding.UTF8));
    try
      Assert.AreEqual(Expected, TJSONObject(Value).GetValue<string>('architecture'));
    finally
      Value.Free;
    end;
  finally
    if FileExists(Output) then TFile.Delete(Output);
    RemoveRequestDirectory(Directory);
  end;
end;

end.
