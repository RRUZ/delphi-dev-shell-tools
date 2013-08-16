program DetectDelphiVersion;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  TypInfo,
  ActiveX,
  ComObj,
  Variants,
  System.SysUtils,
  System.StrUtils,
  uDelphiVersions in 'units\uDelphiVersions.pas',
  uMisc in 'units\uMisc.pas',
  uSupportedIDEs in 'units\uSupportedIDEs.pas',
  uRegistry in 'units\uRegistry.pas';

function SetToString(Info: PTypeInfo; const Value): String;
var
  LTypeInfo  : PTypeInfo;
  LIntegerSet: TIntegerSet;
  I: Integer;

  function GetOrdValue : Integer;
  begin
    Result := 0;
    case GetTypeData(Info)^.OrdType of
      otSByte, otUByte: Result := Byte(Value);
      otSWord, otUWord: Result := Word(Value);
      otSLong, otULong: Result := Integer(Value);
    end;
  end;

begin
  Result := '';
  Integer(LIntegerSet) := GetOrdValue;
  LTypeInfo  := GetTypeData(Info)^.CompType{$IFNDEF FPC}^{$ENDIF};
  for I := 0 to SizeOf(Integer) * 8 - 1 do
    if I in LIntegerSet then
    begin
      if Result <> '' then Result := Result + ',';
      Result := Result + GetEnumName(LTypeInfo, I);
    end;
end;

var
 sdv : SetDelphiVersions;

begin
 try
    CoInitialize(nil);
    try
      sdv := GetDelphiVersions('C:\Users\RRUZ\Desktop\Test\ProjectXE4.dproj');
      Writeln(SetToString(TypeInfo(SetDelphiVersions), sdv));
      sdv := GetDelphiVersions('C:\Users\RRUZ\Desktop\Test\ProjectXE2.dproj');
      Writeln(SetToString(TypeInfo(SetDelphiVersions), sdv));
      sdv := GetDelphiVersions('C:\Users\RRUZ\Desktop\Test\Project2007.dproj');
      Writeln(SetToString(TypeInfo(SetDelphiVersions), sdv));
    finally
      CoUninitialize;
    end;
 except
    on E:EOleException do
        Writeln(Format('EOleException %s %x', [E.Message,E.ErrorCode]));
    on E:Exception do
        Writeln(E.Classname, ':', E.Message);
 end;
 Writeln('Press Enter to exit');
 Readln;
end.
