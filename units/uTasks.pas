//**************************************************************************************************
//
// Unit uTasks
// unit for the Delphi Dev Shell Tools
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
// The Original Code is uTasks.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2016 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************

unit uTasks;

interface

uses
   uMisc,
   uDelphiVersions,
   Winapi.Windows,
   System.RTTI;

type

  TDelphiDevShellTasks=class
  private
  public
    class function ParseMacros(const Data: string; DelphiVersionData  : TDelphiVersionData; const  FileName : string): string;
    class procedure OpenWithDelphi(Info : TMethodInfo);
    class procedure OpenRADStudio(Info : TMethodInfo);
    class procedure MSBuildWithDelphi_Default(Info : TMethodInfo);
    class procedure MSBuildWithDelphi(Info : TMethodInfo);

    class procedure OpenWithNotepad(Info : TMethodInfo);
    class procedure OpenWithApp(Info : TMethodInfo);
    class procedure OpenCmdHere(Info : TMethodInfo);
    class procedure CopyPathClipboard(Info : TMethodInfo);
    class procedure CopyFileNameClipboard(Info : TMethodInfo);
    class procedure CopyFileNameUrlClipboard(Info : TMethodInfo);
    class procedure CopyFileNameUNCClipboard(Info : TMethodInfo);
    class procedure CopyFileNameUnixClipboard(Info : TMethodInfo);
    class procedure CopyFileContentClipboard(Info : TMethodInfo);
    class procedure OpenGUI(Info : TMethodInfo);
    class procedure OpenGUICheckSum(Info : TMethodInfo);
    class procedure OpenRADCmd(Info : TMethodInfo);

    class procedure OpenVclStyle(Info : TMethodInfo);
    class procedure PAClientTest(Info : TMethodInfo);
    class procedure RADTools(Info : TMethodInfo);
    class procedure ExternalTools(Info : TMethodInfo);

    class procedure Updater(Info : TMethodInfo);


    //Lazarus & FPC
    class procedure OpenWithLazarus(Info : TMethodInfo);
    class procedure BuildWithLazBuild(Info : TMethodInfo);
    class procedure FPCTools(Info : TMethodInfo);
    //-------------------

  end;

implementation

uses
  uLazarusVersions,
  Vcl.Clipbrd,
  System.IOUtils,
  System.Classes,
  System.SysUtils,
  WinAPi.ShellAPi;

{ TDelphiDevShellTasks }


//procedure TDelphiDevShellTasks.BuildWithDelphi(Info : TMethodInfo);//incomplete
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

class procedure TDelphiDevShellTasks.BuildWithLazBuild(Info: TMethodInfo);
var
  LazBuild, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    LazBuild:=IncludeTrailingPathDelimiter(Info.Value1.AsString)+'lazbuild.exe';
    //log('BuildWithLazBuild '+LazBuild+' '+Format(' "%s"',[FFileName]));
    BatchFile:=TStringList.Create;
    try
      BatchFile.Add(Format('"%s" "%s"',[LazBuild, Info.Value2.AsString]));
      BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
      BatchFile.SaveToFile(BatchFileName);
      Params:='/K "'+BatchFileName+'"';
      ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.BuildWithLazBuild Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

class procedure TDelphiDevShellTasks.CopyFileContentClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := TFile.ReadAllText(Info.Value1.AsString);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.CopyFileContentClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.CopyFileNameClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := Info.Value1.AsString;
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.CopyFileNameClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;


class procedure TDelphiDevShellTasks.CopyFileNameUNCClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := GetUNCNameEx(Info.Value1.AsString);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.CopyFileNameUNCClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.CopyFileNameUnixClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := StringReplace(Info.Value1.AsString, '\','/', [rfReplaceAll]);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.CopyFileNameUnixClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.CopyFileNameUrlClipboard(Info: TMethodInfo);
begin
 try
  Clipboard.AsText := LocalPathToFileURL(Info.Value1.AsString);
 except
   on  E : Exception do
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
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.CopyPathClipboard Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.ExternalTools(Info: TMethodInfo);
var
  BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    //log('ExternalTools');
    BatchFile:=TStringList.Create;
    try
      BatchFile.Text:=Info.Value1.AsString;
      BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
      BatchFile.SaveToFile(BatchFileName);
      Params:='/C "'+BatchFileName+'"';
      if Info.Value2.AsBoolean then
        ShellExecute(Info.hwnd, 'runas', PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL)
      else
        ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.FPCTools Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;


class function TDelphiDevShellTasks.ParseMacros(const Data: string; DelphiVersionData  : TDelphiVersionData;const FileName : string): string;
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
var
  BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    //log('FPCTools');
    BatchFile:=TStringList.Create;
    try
      BatchFile.Text:=Info.Value1.AsString;
      BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
      BatchFile.SaveToFile(BatchFileName);
      Params:='/C "'+BatchFileName+'"';
      if Info.Value2.AsBoolean then
        ShellExecute(Info.hwnd, 'runas', PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL)
      else
        ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.FPCTools Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

class procedure TDelphiDevShellTasks.MSBuildWithDelphi(Info: TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  LFileName, RsvarsPath, Params, BatchFileName, sPlatform, sConfig : string;
  BatchFile : TStrings;
begin
 try
  //log('MSBuildWithDelphi');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  sPlatform:=Info.Value2.AsString;
  sConfig:=Info.Value3.AsString;
  LFileName:=Info.Value4.AsString;

  RsvarsPath  :=ExtractFilePath(LDelphiVersion.Path)+'rsvars.bat';
  BatchFile:=TStringList.Create;
  try
    BatchFile.Add(Format('call "%s"',[RsvarsPath]));
    BatchFile.Add(Format('msbuild.exe "%s" /target:build /p:Platform="%s" /p:config="%s"', [LFileName, sPlatform, sConfig]));
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
   log(Format('TDelphiDevShellTasks.MSBuildWithDelphi Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.MSBuildWithDelphi_Default(Info: TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  LFileName, RsvarsPath, CompilerPath, Params, BatchFileName : string;
  BatchFile : TStrings;
begin
 try
  //log('MSBuildWithDelphi_Default');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);

  LFileName:=Info.Value2.AsString;

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
   log(Format('TDelphiDevShellTasks.MSBuildWithDelphi_Default Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

class procedure TDelphiDevShellTasks.OpenCmdHere(Info: TMethodInfo);
var
  FilePath, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
 try
    //log('OpenCmdHere');
    FilePath:=ExtractFilePath(Info.Value2.AsString);
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
   log(Format('TDelphiDevShellTasks.OpenCmdHere Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;


class procedure TDelphiDevShellTasks.OpenGUI(Info: TMethodInfo);
begin
 try
  ShellExecute(Info.hwnd, 'open', PChar(IncludeTrailingPathDelimiter(ExtractFilePath(uMisc.GetModuleName))+'GUIDelphiDevShell.exe'), PChar(Info.Value1.AsString) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.OpenGUI Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.OpenGUICheckSum(Info: TMethodInfo);
begin
 try
  ShellExecute(Info.hwnd, 'open', PChar(IncludeTrailingPathDelimiter(ExtractFilePath(uMisc.GetModuleName))+'GUIDelphiDevShell.exe'), PChar(Info.Value1.AsString+' "'+Info.Value2.AsString+'"'), nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.OpenGUI Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.OpenRADCmd(Info: TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  RsvarsPath, FilePath, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
 try
  //log('OpenRADCmd');
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  FilePath:=ExtractFilePath(Info.Value2.AsString);
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
   log(Format('TDelphiDevShellTasks.OpenRADCmd Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

class procedure TDelphiDevShellTasks.OpenRADStudio(Info: TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  LFileName       : string;
begin
 try
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  LFileName:=Info.Value2.AsString;
  //log('OpenRADStudio '+LDelphiVersion.Path+' '+Format(' "%s" "%s"',[LFileName, Info.Value3.AsString]));
  ShellExecute(Info.hwnd, 'open', PChar(LDelphiVersion.Path), PChar(Format('"%s" "%s"',[LFileName, Info.Value3.AsString])) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.OpenRADStudio Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

class procedure TDelphiDevShellTasks.OpenVclStyle(Info: TMethodInfo);
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

  //log('OpenVclStyle '+LVclStyleEditor+' '+Format(' "%s"',[FFileName]));
  ShellExecute(Info.hwnd, 'open', PChar(LVclStyleEditor), PChar(Format('"%s"',[Info.Value2.AsString])) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.OpenVclStyle Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.OpenWithApp(Info: TMethodInfo);
begin
 try
   ShellExecute(Info.hwnd, 'open', PChar(Info.Value1.AsString), PChar(Info.Value2.AsString) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.OpenWithApp Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.OpenWithDelphi(Info: TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
begin
 try
  LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
  //log('OpenWithDelphi '+LDelphiVersion.Path+' '+Format('-pDelphi "%s"',[FFileName]));
  ShellExecute(Info.hwnd, 'open', PChar(LDelphiVersion.Path), PChar(Format('-pDelphi "%s"',[Info.Value1.AsString])) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.OpenWithDelphi Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;


class procedure TDelphiDevShellTasks.OpenWithLazarus(Info: TMethodInfo);
var
  LazarusIDE      : string;
begin
 try
  LazarusIDE:=Info.Value1.AsString;
  //log('OpenWithLazarus '+LazarusIDE+' '+Format(' "%s"',[FFileName]));
  ShellExecute(Info.hwnd, 'open', PChar(LazarusIDE), PChar(Format('"%s"',[Info.Value2.AsString])) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.OpenWithLazarus Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;

end;

class procedure TDelphiDevShellTasks.OpenWithNotepad(Info: TMethodInfo);
begin
 try
  ShellExecute(Info.hwnd, 'open', 'C:\Windows\notepad.exe', PChar(Info.Value1.AsString) , nil , SW_SHOWNORMAL);
 except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.OpenWithNotepad Message %s  Trace %s',[E.Message, e.StackTrace]));
 end;
end;

class procedure TDelphiDevShellTasks.PAClientTest(Info: TMethodInfo);
var
  LDelphiVersion  : TDelphiVersionData;
  LPAClientApp, BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    LDelphiVersion:=TDelphiVersionData(Info.Value1.AsObject);
    LPAClientApp:=IncludeTrailingPathDelimiter(ExtractFilePath(LDelphiVersion.Path))+'PAClient.exe';
    //log('PAClientTest '+LPAClientApp+' '+Format(' "%s"',[Info.Value2.AsString]));
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
   log(Format('TDelphiDevShellTasks.PAClientTest Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

class procedure TDelphiDevShellTasks.RADTools(Info: TMethodInfo);
var
  BatchFileName, Params : string;
  BatchFile : TStrings;
begin
  try
    //log('RADTools');
    BatchFile:=TStringList.Create;
    try
      BatchFile.Text:=Info.Value1.AsString;
      BatchFileName:=IncludeTrailingPathDelimiter(GetTempDirectory)+'ShellExec.bat';
      BatchFile.SaveToFile(BatchFileName);
      Params:='/C "'+BatchFileName+'"';
      if Info.Value2.AsBoolean then
        ShellExecute(Info.hwnd, 'runas', PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL)
      else
        ShellExecute(Info.hwnd, nil, PChar('cmd.exe'), PChar(Params) , nil , SW_SHOWNORMAL);
    finally
      BatchFile.Free;
    end;
  except
   on  E : Exception do
   log(Format('TDelphiDevShellTasks.RADTools Message %s  Trace %s',[E.Message, e.StackTrace]));
  end;
end;

class procedure TDelphiDevShellTasks.Updater(Info: TMethodInfo);
begin
  CheckUpdates(False);
end;

end.
