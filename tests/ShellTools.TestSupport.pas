unit ShellTools.TestSupport;

interface

uses
  System.SysUtils, Winapi.Windows;

const
  ShellClassId: TGUID = '{45DCA61E-3762-45B1-939D-2446C0DCAC25}';
  ShellClassKey = 'Software\Classes\CLSID\{45DCA61E-3762-45B1-939D-2446C0DCAC25}\InprocServer32';
  ShellHandlerKey = 'Software\Classes\*\shellex\ContextMenuHandlers\DelphiDevShellToolsContextMenu';
  ShellApprovedKey = 'Software\Microsoft\Windows\CurrentVersion\Shell Extensions\Approved';

type
  TDllRegistration = function: HResult; stdcall;
  TDllGetClassObject = function(const ClassId, IID: TGUID; out Obj): HResult; stdcall;

function TestDllPath: string;
function LoadTestDll: HMODULE;
function ReadRegistryString(Root: HKEY; const Key: string; const Name: string = ''): string;
function IsElevated: Boolean;
procedure CheckHR(Value: HResult; const Operation: string);

implementation

uses
  System.Win.Registry, DUnitX.TestFramework;

function TestDllPath: string;
begin
  Result := GetEnvironmentVariable('DDS_TEST_DLL');
  if Result = '' then
    raise Exception.Create('DDS_TEST_DLL is missing. Run these tests with Build.bat test.');
end;

function LoadTestDll: HMODULE;
begin
  Result := LoadLibrary(PChar(TestDllPath));
  if Result = 0 then
    RaiseLastOSError;
end;

function ReadRegistryString(Root: HKEY; const Key, Name: string): string;
var
  Registry: TRegistry;
begin
  Result := '';
  {$IFDEF WIN64}
  Registry := TRegistry.Create(KEY_READ or KEY_WOW64_64KEY);
  {$ELSE}
  Registry := TRegistry.Create(KEY_READ or KEY_WOW64_32KEY);
  {$ENDIF}
  try
    Registry.RootKey := Root;
    if Registry.OpenKeyReadOnly(Key) and Registry.ValueExists(Name) then
      Result := Registry.ReadString(Name);
  finally
    Registry.Free;
  end;
end;

function IsElevated: Boolean;
var
  Token: THandle;
  Elevation: TTokenElevation;
  Size: DWORD;
begin
  Result := False;
  if not OpenProcessToken(GetCurrentProcess, TOKEN_QUERY, Token) then Exit;
  try
    if GetTokenInformation(Token, TokenElevation, @Elevation, SizeOf(Elevation), Size) then
      Result := Elevation.TokenIsElevated <> 0;
  finally
    CloseHandle(Token);
  end;
end;

procedure CheckHR(Value: HResult; const Operation: string);
begin
  Assert.IsTrue(Succeeded(Value), Format('%s failed: HRESULT %.8x', [Operation, Cardinal(Value)]));
end;

end.
