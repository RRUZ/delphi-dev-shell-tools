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
  System.SysUtils, System.IOUtils, System.Types, Vcl.Graphics,
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX, Winapi.ShlObj,
  ShellTools.TestSupport;

// Exercise a real file selection and the command-ID contract used by Explorer.
procedure CheckFileContextMenu(const Menu: IContextMenu; ProjectFile: Boolean);
const
  FirstCommand = 1000;
  LastCommand = 32767;
var
  FileName: string;
  Item: IShellItem;
  Data: IDataObject;
  Init: IShellExtInit;
  Popup: HMENU;
  ResultCode: HResult;
  ReservedCount: UINT;

  procedure CheckMenuIds(Handle: HMENU);
  var
    Position: Integer;
    Info: TMenuItemInfo;
    Measure: TMeasureItemStruct;
    Draw: TDrawItemStruct;
    Bitmap: Vcl.Graphics.TBitmap;
    Menu3: IContextMenu3;
    OmittedResult: ^LRESULT;
  begin
    for Position := 0 to GetMenuItemCount(Handle) - 1 do
    begin
      ZeroMemory(@Info, SizeOf(Info));
      Info.cbSize := SizeOf(Info);
      Info.fMask := MIIM_ID or MIIM_FTYPE or MIIM_SUBMENU or MIIM_DATA;
      Assert.IsTrue(GetMenuItemInfo(Handle, Position, True, Info));
      if not ProjectFile then
        Assert.IsTrue((Info.fType and MFT_OWNERDRAW) = 0,
          'Ordinary Pascal-file actions must stay native');
      if (Info.fType and MFT_OWNERDRAW) <> 0 then
      begin
        Assert.IsTrue(ProjectFile, 'Only project information may be owner-drawn');
        Assert.IsTrue(Supports(Menu, IContextMenu3, Menu3));
        OmittedResult := nil;
        ZeroMemory(@Measure, SizeOf(Measure));
        Measure.CtlType := ODT_MENU;
        Measure.itemID := Info.wID;
        Measure.itemData := Info.dwItemData;
        CheckHR(Menu3.HandleMenuMsg2(WM_MEASUREITEM, 0, LPARAM(@Measure), OmittedResult^), 'Measure panel');
        Assert.IsTrue((Measure.itemWidth > 0) and (Measure.itemHeight > 0));
        Bitmap := Vcl.Graphics.TBitmap.Create;
        try
          Bitmap.SetSize(Measure.itemWidth, Measure.itemHeight);
          ZeroMemory(@Draw, SizeOf(Draw));
          Draw.CtlType := ODT_MENU;
          Draw.itemID := Info.wID;
          Draw.itemData := Info.dwItemData;
          Draw.hDC := Bitmap.Canvas.Handle;
          Draw.rcItem := Rect(0, 0, Bitmap.Width, Bitmap.Height);
          CheckHR(Menu3.HandleMenuMsg2(WM_DRAWITEM, 0, LPARAM(@Draw), OmittedResult^), 'Draw panel');
        finally
          Bitmap.Free;
        end;
        Menu3 := nil;
      end;
      if (Info.fType and MFT_SEPARATOR) = 0 then
        Assert.IsTrue((Info.wID >= FirstCommand) and
          (Info.wID < FirstCommand + ReservedCount) and (Info.wID <= LastCommand),
          Format('Menu ID %d is outside the reported range %d..%d',
            [Info.wID, FirstCommand, FirstCommand + ReservedCount - 1]));
      if Info.hSubMenu <> 0 then CheckMenuIds(Info.hSubMenu);
    end;
  end;

begin
  FileName := TPath.Combine(TPath.GetTempPath, 'ShellMenu-' + TGUID.NewGuid.ToString + '.pas');
  if ProjectFile then
  begin
    FileName := ChangeFileExt(FileName, '.dproj');
    TFile.WriteAllText(FileName,
      '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">' +
      '<PropertyGroup><ProjectVersion>18.6</ProjectVersion><Config>Release</Config>' +
      '<Platform>Win64</Platform><FrameworkType>VCL</FrameworkType><AppType>Library</AppType>' +
      '<ProjectGuid>{12345678-1234-1234-1234-123456789012}</ProjectGuid></PropertyGroup>' +
      '<ProjectExtensions><BorlandProject><Platforms><Platform value="Win32">True</Platform>' +
      '<Platform value="Win64">True</Platform></Platforms></BorlandProject></ProjectExtensions></Project>');
  end
  else
    TFile.WriteAllText(FileName, 'unit Example; interface implementation end.');
  Popup := 0;
  try
    CheckHR(SHCreateItemFromParsingName(PChar(FileName), nil, IShellItem, Item), 'Create selected file');
    CheckHR(Item.BindToHandler(nil, BHID_DataObject, IDataObject, Data), 'Create file data object');
    Assert.IsTrue(Supports(Menu, IShellExtInit, Init));
    CheckHR(Init.Initialize(nil, Data, 0), 'Initialize Pascal file selection');
    Popup := CreatePopupMenu;
    Assert.IsTrue(Popup <> 0);
    ResultCode := Menu.QueryContextMenu(Popup, 0, FirstCommand, LastCommand, CMF_NORMAL);
    CheckHR(ResultCode, 'QueryContextMenu');
    ReservedCount := Cardinal(ResultCode) and $FFFF;
    Assert.IsTrue(GetMenuItemCount(Popup) > 0, 'Pascal selection must create a menu');
    CheckMenuIds(Popup);
  finally
    if Popup <> 0 then DestroyMenu(Popup);
    Init := nil;
    Data := nil;
    Item := nil;
    TFile.Delete(FileName);
  end;
end;
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
