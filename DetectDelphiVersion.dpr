program DetectDelphiVersion;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  TypInfo,
  ActiveX,
  ComObj,
  Variants,
  ShellApi,
  Classes,
  Windows,
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
 msb : TMSBuildDProj;
begin
 try
    CoInitialize(nil);
    try
      //sdv := GetDelphiVersions('C:\Users\Public\Documents\RAD Studio\11.0\Samples\FireMonkey\CPUMonitor\CPUMonitor.dproj');
      //Writeln(SetToString(TypeInfo(SetDelphiVersions), sdv));
      {
      sdv := GetDelphiVersions('C:\Users\RRUZ\Desktop\Test\ProjectXE2.dproj');
      Writeln(SetToString(TypeInfo(SetDelphiVersions), sdv));
      sdv := GetDelphiVersions('C:\Users\RRUZ\Desktop\Test\Project2007.dproj');
      Writeln(SetToString(TypeInfo(SetDelphiVersions), sdv));
      }
      //msb:=TMSBuildDProj.Create('C:\Users\RRUZ\Desktop\Test\ProjectFMOSX.dproj');
      {
      ShellExecute(0,'open',
      '"C:\Program Files (x86)\Embarcadero\RAD Studio\11.0\bin\bds.exe"',
      '"C:\Users\Public\Documents\RAD Studio\11.0\Samples\iOSCodeSnippets\iOS Accelerometer\iOS_Accelerometer.dproj"',nil, SW_SHOWNORMAL);
      }
      msb:=TMSBuildDProj.Create('C:\Dephi\google-code\dev-shell-tools\Win64\Debug\SynEdit_R2010.dproj');
      try
         Writeln(msb.ValidData);
         Writeln('FrameworkType '+msb.FrameworkType); //VCL
         Writeln('AppType       '+msb.AppType);   //Library, Package, Application
         Writeln('GUID          '+msb.GUID);
         Writeln('Def. Conf.    '+msb.DefaultConfiguration); //Debug
         Writeln('Def. Platform '+msb.DefaultPlatForm); //Win32, OSX
         Writeln(msb.Platforms.Text);
      finally
        msb.Free;
      end;
     Writeln;
           {
      msb:=TMSBuildDProj.Create('C:\Dephi\google-code\SynEdit\SynEdit\Packages\SynEdit_DXE4.dproj');
      try
         Writeln('FrameworkType '+msb.FrameworkType);
         Writeln('AppType       '+msb.AppType);
         Writeln('GUID          '+msb.GUID);
         Writeln('Def. Conf.    '+msb.DefaultConfiguration);
         Writeln('Def. Platform '+msb.DefaultPlatForm);
         Writeln(msb.Platforms.Text);
      finally
        msb.Free;
      end;
         }
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
