//**************************************************************************************************
//
// Unit DelphiDevShellTools.Commands
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
// The Original Code is DelphiDevShellTools.Commands.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.Commands;

interface

uses System.SysUtils, System.JSON, System.Generics.Collections;

type
  TCommandKind = (ckProgram, ckOpenIDE, ckBuild, ckTerminal, ckScript);
  TIDEVariant = (ivAutomatic, ivWin32, ivWin64);
  TCommandRequest = record
    Kind: TCommandKind;
    FileName, Executable, WorkingDirectory, ProfileId: string;
    Arguments: TArray<string>;
    Variant: TIDEVariant;
    Configuration, Platform, EnvironmentScript, Script, MacroBin, MacroFPC: string;
    Elevate, ChooseIDE, WaitForExit: Boolean;
    class function Create(AKind: TCommandKind; const AFileName: string = ''): TCommandRequest; static;
    function ToJSON: string;
    class function FromJSON(const Text: string): TCommandRequest; static;
  end;

function QuoteArgument(const Value: string): string;
function CommandLine(const Executable: string; const Arguments: TArray<string>): string;

implementation

function QuoteArgument(const Value: string): string;
var C: Char; Slashes: Integer;
begin
  Result := '"';
  Slashes := 0;
  for C in Value do
    if C = '\' then Inc(Slashes)
    else
    begin
      if C = '"' then Result := Result + StringOfChar('\', Slashes * 2 + 1)
      else Result := Result + StringOfChar('\', Slashes);
      Result := Result + C;
      Slashes := 0;
    end;
  Result := Result + StringOfChar('\', Slashes * 2) + '"';
end;

function CommandLine(const Executable: string; const Arguments: TArray<string>): string;
var Argument: string;
begin
  Result := QuoteArgument(Executable);
  for Argument in Arguments do Result := Result + ' ' + QuoteArgument(Argument);
end;

class function TCommandRequest.Create(AKind: TCommandKind; const AFileName: string): TCommandRequest;
begin
  Result := Default(TCommandRequest);
  Result.Kind := AKind;
  Result.FileName := AFileName;
  Result.WorkingDirectory := ExtractFileDir(AFileName);
end;

function TCommandRequest.ToJSON: string;
var Obj: TJSONObject; Args: TJSONArray; Arg: string;
begin
  Obj := TJSONObject.Create;
  try
    Obj.AddPair('version', TJSONNumber.Create(1));
    Obj.AddPair('kind', TJSONNumber.Create(Ord(Kind)));
    Obj.AddPair('variant', TJSONNumber.Create(Ord(Variant)));
    Obj.AddPair('file', FileName);
    Obj.AddPair('executable', Executable);
    Obj.AddPair('directory', WorkingDirectory);
    Obj.AddPair('profile', ProfileId);
    Obj.AddPair('configuration', Configuration);
    Obj.AddPair('platform', Platform);
    Obj.AddPair('environment', EnvironmentScript);
    Obj.AddPair('script', Script);
    Obj.AddPair('macroBin', MacroBin);
    Obj.AddPair('macroFPC', MacroFPC);
    Obj.AddPair('elevate', TJSONBool.Create(Elevate));
    Obj.AddPair('choose', TJSONBool.Create(ChooseIDE));
    Obj.AddPair('wait', TJSONBool.Create(WaitForExit));
    Args := TJSONArray.Create;
    Obj.AddPair('arguments', Args);
    for Arg in Arguments do Args.Add(Arg);
    Result := Obj.ToJSON;
  finally
    Obj.Free;
  end;
end;

class function TCommandRequest.FromJSON(const Text: string): TCommandRequest;
var Value: TJSONValue; Obj: TJSONObject; Args: TJSONArray; I, K, V: Integer;
begin
  Result := Default(TCommandRequest);
  if Length(Text) > 1024 * 1024 then raise EArgumentException.Create('Command request is too large.');
  Value := TJSONObject.ParseJSONValue(Text);
  try
    if not (Value is TJSONObject) then raise EArgumentException.Create('Invalid command request.');
    Obj := TJSONObject(Value);
    if Obj.GetValue<Integer>('version', 0) <> 1 then raise EArgumentException.Create('Unsupported command version.');
    K := Obj.GetValue<Integer>('kind', -1);
    V := Obj.GetValue<Integer>('variant', -1);
    if (K < Ord(Low(TCommandKind))) or (K > Ord(High(TCommandKind))) or
       (V < Ord(Low(TIDEVariant))) or (V > Ord(High(TIDEVariant))) then
      raise EArgumentException.Create('Invalid command kind or IDE variant.');
    Result.Kind := TCommandKind(K);
    Result.Variant := TIDEVariant(V);
    Result.FileName := Obj.GetValue<string>('file', '');
    Result.Executable := Obj.GetValue<string>('executable', '');
    Result.WorkingDirectory := Obj.GetValue<string>('directory', '');
    Result.ProfileId := Obj.GetValue<string>('profile', '');
    Result.Configuration := Obj.GetValue<string>('configuration', '');
    Result.Platform := Obj.GetValue<string>('platform', '');
    Result.EnvironmentScript := Obj.GetValue<string>('environment', '');
    Result.Script := Obj.GetValue<string>('script', '');
    Result.MacroBin := Obj.GetValue<string>('macroBin', '');
    Result.MacroFPC := Obj.GetValue<string>('macroFPC', '');
    Result.Elevate := Obj.GetValue<Boolean>('elevate', False);
    Result.ChooseIDE := Obj.GetValue<Boolean>('choose', False);
    Result.WaitForExit := Obj.GetValue<Boolean>('wait', False);
    Args := Obj.GetValue<TJSONArray>('arguments');
    if (Args = nil) or (Args.Count > 256) then raise EArgumentException.Create('Invalid command arguments.');
    SetLength(Result.Arguments, Args.Count);
    for I := 0 to Args.Count - 1 do
    begin
      if not (Args.Items[I] is TJSONString) then raise EArgumentException.Create('Arguments must be strings.');
      Result.Arguments[I] := Args.Items[I].Value;
    end;
  finally
    Value.Free;
  end;
end;

end.
