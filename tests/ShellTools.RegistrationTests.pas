unit ShellTools.RegistrationTests;

interface

uses
  DUnitX.TestFramework;

type
  // No TestFixture attribute: the runner registers this only with explicit opt-in.
  TRegistrationTests = class
  public
    [Test] procedure RegisterActivateUnregisterAndRestore;
  end;

implementation

uses
  System.SysUtils, Winapi.Windows, Winapi.ActiveX, Winapi.ShlObj,
  ShellTools.TestSupport;

procedure TRegistrationTests.RegisterActivateUnregisterAndRestore;
var
  Module, PreviousModule: HMODULE;
  RegisterDll, UnregisterDll, RestoreDll: TDllRegistration;
  PreviousPath, PreviousHandler, PreviousApproved, OtherPath: string;
  OtherView: REGSAM;
  Menu: IContextMenu;
begin
  Assert.IsTrue(IsElevated, 'Run Build.bat test-registration for elevated registration tests.');
  Assert.AreEqual('', ReadRegistryString(HKEY_CURRENT_USER, ShellClassKey),
    'A per-user COM override would invalidate this machine-registration test.');
  PreviousPath := ReadRegistryString(HKEY_LOCAL_MACHINE, ShellClassKey);
  PreviousHandler := ReadRegistryString(HKEY_LOCAL_MACHINE, ShellHandlerKey);
  PreviousApproved := ReadRegistryString(HKEY_LOCAL_MACHINE, ShellApprovedKey, GUIDToString(ShellClassId));
  {$IFDEF WIN64}
  OtherView := KEY_WOW64_32KEY;
  {$ELSE}
  OtherView := KEY_WOW64_64KEY;
  {$ENDIF}
  OtherPath := ReadRegistryString(HKEY_LOCAL_MACHINE, ShellClassKey, '', OtherView);
  PreviousModule := 0;
  RestoreDll := nil;
  Module := LoadTestDll;
  try
    RegisterDll := GetProcAddress(Module, 'DllRegisterServer');
    UnregisterDll := GetProcAddress(Module, 'DllUnregisterServer');
    Assert.IsTrue(Assigned(RegisterDll));
    Assert.IsTrue(Assigned(UnregisterDll));
    if PreviousPath <> '' then
    begin
      Assert.IsTrue(FileExists(PreviousPath), 'Cannot restore a registration whose DLL is missing.');
      PreviousModule := LoadLibrary(PChar(PreviousPath));
      Assert.IsTrue(PreviousModule <> 0, 'Cannot load the previously registered DLL for restoration.');
      RestoreDll := GetProcAddress(PreviousModule, 'DllRegisterServer');
      Assert.IsTrue(Assigned(RestoreDll));
    end
    else if OtherPath = '' then
    begin
      Assert.AreEqual('', PreviousHandler, 'Partial pre-existing registration requires repair first.');
      Assert.AreEqual('', PreviousApproved, 'Partial pre-existing registration requires repair first.');
    end;
    try
      CheckHR(RegisterDll(), 'DllRegisterServer');
      CheckHR(RegisterDll(), 'Repeated DllRegisterServer');
      Assert.AreEqual(TestDllPath, ReadRegistryString(HKEY_LOCAL_MACHINE, ShellClassKey));
      Assert.AreEqual(GUIDToString(ShellClassId), ReadRegistryString(HKEY_LOCAL_MACHINE, ShellHandlerKey));
      Assert.IsTrue(ReadRegistryString(HKEY_LOCAL_MACHINE, ShellApprovedKey, GUIDToString(ShellClassId)) <> '');
      CheckHR(CoCreateInstance(ShellClassId, nil, CLSCTX_INPROC_SERVER, IContextMenu, Menu), 'COM activation');
      CheckFileContextMenu(Menu, False);
      Menu := nil;
      CheckHR(CoCreateInstance(ShellClassId, nil, CLSCTX_INPROC_SERVER, IContextMenu, Menu), 'Project menu activation');
      CheckFileContextMenu(Menu, True);
      Menu := nil;
      CoFreeUnusedLibraries;
      CheckHR(UnregisterDll(), 'DllUnregisterServer');
      CheckHR(UnregisterDll(), 'Repeated DllUnregisterServer');
      Assert.AreEqual('', ReadRegistryString(HKEY_LOCAL_MACHINE, ShellClassKey));
      Assert.AreEqual(OtherPath, ReadRegistryString(HKEY_LOCAL_MACHINE, ShellClassKey, '', OtherView),
        'Unregistering one architecture must preserve the other COM server.');
      if OtherPath = '' then
      begin
        Assert.AreEqual('', ReadRegistryString(HKEY_LOCAL_MACHINE, ShellHandlerKey));
        Assert.AreEqual('', ReadRegistryString(HKEY_LOCAL_MACHINE, ShellApprovedKey, GUIDToString(ShellClassId)));
      end
      else
      begin
        Assert.AreEqual(GUIDToString(ShellClassId), ReadRegistryString(HKEY_LOCAL_MACHINE, ShellHandlerKey));
        Assert.AreEqual('', ReadRegistryString(HKEY_LOCAL_MACHINE, ShellApprovedKey, GUIDToString(ShellClassId)));
      end;
    finally
      Menu := nil;
      CoFreeUnusedLibraries;
      if Assigned(RestoreDll) then CheckHR(RestoreDll(), 'Restore previous registration')
      else CheckHR(UnregisterDll(), 'Restore unregistered state');
      Assert.AreEqual(PreviousPath, ReadRegistryString(HKEY_LOCAL_MACHINE, ShellClassKey));
      Assert.AreEqual(PreviousHandler, ReadRegistryString(HKEY_LOCAL_MACHINE, ShellHandlerKey));
      Assert.AreEqual(PreviousApproved, ReadRegistryString(HKEY_LOCAL_MACHINE, ShellApprovedKey, GUIDToString(ShellClassId)));
    end;
  finally
    if PreviousModule <> 0 then FreeLibrary(PreviousModule);
    FreeLibrary(Module);
  end;
end;

end.
