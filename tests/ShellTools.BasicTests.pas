unit ShellTools.BasicTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TBasicTests = class
  private
    FDirectory: string;
    function WriteProject(const Version: string): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure ExpandsFileMacros;
    [Test] procedure PreservesUnknownMacros;
    [Test] procedure DetectsRioProjectVersion;
    [Test] procedure ReadsProjectBuildOptions;
    [Test] procedure ReadsGroupProjectRelativePaths;
    [Test] procedure UnknownProjectVersionIsNotMisidentified;
    [Test] procedure MalformedProjectIsRejected;
    [Test] procedure DllExportsRequiredEntryPoints;
    [Test] procedure DllEmbedsShellManifest;
    [Test] procedure DllMenuCallbacksAllowNullResult;
    [Test] procedure PanelReadsUnmappedProjectMetadata;
    [TestCase('96 DPI', '96')]
    [TestCase('144 DPI', '144')]
    [TestCase('192 DPI', '192')]
    procedure PanelPaintPreservesHostDCAndBounds(Dpi: Integer);
    [Test] procedure DllCreatesShellInterfacesAndRejectsEmptySelection;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Classes, Xml.XMLDoc, Xml.XMLIntf,
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  Winapi.ShlObj, Vcl.Graphics, System.Types, DelphiDevShellTools.ProjectInfoPanel,
  uTasks, uDelphiVersions, ShellTools.TestSupport;

procedure TBasicTests.Setup;
begin
  FDirectory := TPath.Combine(TPath.GetTempPath, 'ShellToolsTests-' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FDirectory);
end;

procedure TBasicTests.TearDown;
begin
  // Only the unique directory created by this fixture is removed.
  if TDirectory.Exists(FDirectory) then TDirectory.Delete(FDirectory, True);
end;

function TBasicTests.WriteProject(const Version: string): string;
begin
  Result := TPath.Combine(FDirectory, 'Example.dproj');
  TFile.WriteAllText(Result,
    '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">' +
    '<PropertyGroup><ProjectVersion>' + Version + '</ProjectVersion>' +
    '<Config>Release</Config><Platform>Win64</Platform><FrameworkType>VCL</FrameworkType>' +
    '<ProjectGuid>{12345678-1234-1234-1234-123456789012}</ProjectGuid><AppType>Application</AppType></PropertyGroup>' +
    '<ItemGroup><BuildConfiguration Include="Base"/><BuildConfiguration Include="Debug"/>' +
    '<BuildConfiguration Include="Release"/></ItemGroup>' +
    '<ProjectExtensions><BorlandProject><Platforms><Platform value="Win32">True</Platform>' +
    '<Platform value="Win64">True</Platform></Platforms></BorlandProject></ProjectExtensions></Project>');
end;

procedure TBasicTests.ExpandsFileMacros;
begin
  Assert.AreEqual('C:\Work Space\Demo.pas|Demo.pas|Demo|.pas|C:\Work Space\',
    TDelphiDevShellTasks.ParseMacros('$FILENAME$|$NAME$|$ONLYNAME$|$EXT$|$PATH$', nil, 'C:\Work Space\Demo.pas'));
end;

procedure TBasicTests.PreservesUnknownMacros;
begin
  Assert.AreEqual('$UNKNOWN$', TDelphiDevShellTasks.ParseMacros('$UNKNOWN$', nil, 'Demo.pas'));
end;

procedure TBasicTests.DetectsRioProjectVersion;
var
  Versions: SetDelphiVersions;
begin
  Versions := GetDelphiVersions(WriteProject('18.6'));
  Assert.AreEqual<NativeInt>(1, Length(Versions));
  Assert.AreEqual<NativeInt>(Ord(Delphi10Rio), Ord(Versions[0]));
end;

procedure TBasicTests.ReadsProjectBuildOptions;
var
  Project: TMSBuildDProj;
begin
  Project := TMSBuildDProj.Create(WriteProject('18.6'));
  try
    Assert.IsTrue(Project.ValidData);
    Assert.AreEqual('VCL', Project.FrameworkType);
    Assert.AreEqual('Win64', Project.DefaultPlatForm);
    Assert.AreEqual('Release', Project.DefaultConfiguration);
    Assert.AreEqual<NativeInt>(2, Project.TargetPlatforms.Count);
    Assert.IsTrue(Project.TargetPlatforms.IndexOf('Win32') >= 0);
    Assert.IsTrue(Project.TargetPlatforms.IndexOf('Win64') >= 0);
    Assert.AreEqual<NativeInt>(2, Project.BuildConfigurations.Count);
    Assert.IsTrue(Project.BuildConfigurations.IndexOf('Debug') >= 0);
    Assert.IsTrue(Project.BuildConfigurations.IndexOf('Release') >= 0);
  finally
    Project.Free;
  end;
end;

procedure TBasicTests.ReadsGroupProjectRelativePaths;
var
  Group: TMSBuildGroupProj;
  FileName: string;
begin
  WriteProject('18.6');
  FileName := TPath.Combine(FDirectory, 'Example.groupproj');
  TFile.WriteAllText(FileName, '<Project xmlns="http://schemas.microsoft.com/developer/msbuild/2003">' +
    '<ItemGroup><Projects Include="Example.dproj"/></ItemGroup></Project>');
  Group := TMSBuildGroupProj.Create(FileName);
  try
    Assert.IsTrue(Group.ValidData);
    Assert.AreEqual<NativeInt>(1, Group.Projects.Count);
    Assert.IsTrue(Group.Projects[0].ValidData);
    Assert.AreEqual(TPath.Combine(FDirectory, 'Example.dproj'), Group.Projects[0].ProjectFile);
  finally
    Group.Free;
  end;
end;

procedure TBasicTests.UnknownProjectVersionIsNotMisidentified;
begin
  Assert.AreEqual<NativeInt>(0, Length(GetDelphiVersions(WriteProject('999.0'))));
end;

procedure TBasicTests.MalformedProjectIsRejected;
var
  Project: TMSBuildDProj;
  FileName: string;
begin
  FileName := TPath.Combine(FDirectory, 'Broken.dproj');
  TFile.WriteAllText(FileName, '<Project><broken');
  Project := TMSBuildDProj.Create(FileName);
  try
    Assert.IsFalse(Project.ValidData);
  finally
    Project.Free;
  end;
end;

procedure TBasicTests.DllExportsRequiredEntryPoints;
var
  Module: HMODULE;
  Name: AnsiString;
begin
  Module := LoadTestDll;
  try
    for Name in ['DllGetClassObject', 'DllCanUnloadNow', 'DllRegisterServer', 'DllUnregisterServer', 'DllInstall'] do
      Assert.IsTrue(GetProcAddress(Module, PAnsiChar(Name)) <> nil, string(Name));
  finally
    FreeLibrary(Module);
  end;
end;

procedure TBasicTests.DllCreatesShellInterfacesAndRejectsEmptySelection;
var
  Module: HMODULE;
  GetClassObject: TDllGetClassObject;
  Factory: IClassFactory;
  Menu: IContextMenu;
  Menu2: IContextMenu2;
  Menu3: IContextMenu3;
  Init: IShellExtInit;
  MessageResult: LRESULT;
begin
  Module := LoadTestDll;
  try
    GetClassObject := GetProcAddress(Module, 'DllGetClassObject');
    Assert.IsTrue(Assigned(GetClassObject));
    CheckHR(GetClassObject(ShellClassId, IClassFactory, Factory), 'DllGetClassObject');
    CheckHR(Factory.CreateInstance(nil, IContextMenu, Menu), 'IClassFactory.CreateInstance');
    Assert.IsTrue(Supports(Menu, IContextMenu2, Menu2));
    Assert.IsTrue(Supports(Menu, IContextMenu3, Menu3));
    Assert.IsTrue(Supports(Menu, IShellExtInit, Init));
    Assert.IsTrue(Failed(Init.Initialize(nil, nil, 0)), 'Empty selection must be rejected');
    MessageResult := 123;
    Assert.IsTrue(Failed(Menu3.HandleMenuMsg2(WM_INITMENUPOPUP, 0, 0, MessageResult)),
      'Unprocessed menu messages must be passed back to Explorer');
    Assert.AreEqual<NativeInt>(0, MessageResult);
  finally
    Init := nil;
    Menu3 := nil;
    Menu2 := nil;
    Menu := nil;
    Factory := nil;
    FreeLibrary(Module);
  end;
end;

procedure TBasicTests.DllEmbedsShellManifest;
var
  Module: HMODULE;
  Resource: TResourceStream;
  Bytes: UTF8String;
  Document: IXMLDocument;
  Node: IXMLNode;
  Context: TActCtx;
  ContextHandle: THandle;
  DllPath: string;
begin
  DllPath := TestDllPath;
  Module := LoadLibraryEx(PChar(DllPath), 0, LOAD_LIBRARY_AS_DATAFILE);
  Assert.IsTrue(Module <> 0);
  try
    Assert.IsTrue(FindResource(Module, MAKEINTRESOURCE(1), RT_MANIFEST) = 0,
      'A DLL must not also embed the default executable manifest');
    Resource := TResourceStream.CreateFromID(Module, 2, RT_MANIFEST);
    try
      SetString(Bytes, PAnsiChar(Resource.Memory), Resource.Size);
      Document := LoadXMLData(UTF8ToString(Bytes));
    finally
      Resource.Free;
    end;
    Node := Document.DocumentElement.ChildNodes.FindNode('application', 'urn:schemas-microsoft-com:asm.v3');
    Assert.IsNotNull(Node);
    Node := Node.ChildNodes.FindNode('windowsSettings', 'urn:schemas-microsoft-com:asm.v3');
    Assert.IsNotNull(Node);
    Assert.AreEqual('PerMonitorV2, PerMonitor',
      Node.ChildNodes.FindNode('dpiAwareness', 'http://schemas.microsoft.com/SMI/2016/WindowsSettings').Text);
    Assert.AreEqual('true/pm',
      Node.ChildNodes.FindNode('dpiAware', 'http://schemas.microsoft.com/SMI/2005/WindowsSettings').Text);
    Node := Document.DocumentElement.ChildNodes.FindNode('compatibility', 'urn:schemas-microsoft-com:compatibility.v1')
      .ChildNodes.FindNode('application', 'urn:schemas-microsoft-com:compatibility.v1')
      .ChildNodes.FindNode('supportedOS', 'urn:schemas-microsoft-com:compatibility.v1');
    Assert.AreEqual('{8e0f7a12-bfb3-4fe8-b9a5-48fd50a15a9a}', string(Node.Attributes['Id']));
    Node := Document.DocumentElement.ChildNodes.FindNode('dependency', 'urn:schemas-microsoft-com:asm.v1')
      .ChildNodes.FindNode('dependentAssembly', 'urn:schemas-microsoft-com:asm.v1')
      .ChildNodes.FindNode('assemblyIdentity', 'urn:schemas-microsoft-com:asm.v1');
    Assert.AreEqual('Microsoft.Windows.Common-Controls', string(Node.Attributes['name']));
    Assert.AreEqual('6.0.0.0', string(Node.Attributes['version']));
    Assert.AreEqual('*', string(Node.Attributes['processorArchitecture']));
  finally
    FreeLibrary(Module);
  end;
  // Ask Windows to validate the compiled DLL's manifest and resolve v6 controls.
  ZeroMemory(@Context, SizeOf(Context));
  Context.cbSize := SizeOf(Context);
  Context.dwFlags := ACTCTX_FLAG_RESOURCE_NAME_VALID;
  Context.lpSource := PChar(DllPath);
  Context.lpResourceName := MAKEINTRESOURCE(2);
  ContextHandle := CreateActCtx(Context);
  Assert.IsTrue(ContextHandle <> INVALID_HANDLE_VALUE,
    'Windows must accept the embedded manifest: ' + SysErrorMessage(GetLastError));
  if ContextHandle <> INVALID_HANDLE_VALUE then ReleaseActCtx(ContextHandle);
end;
procedure TBasicTests.DllMenuCallbacksAllowNullResult;
var
  Module: HMODULE;
  GetClassObject: TDllGetClassObject;
  Factory: IClassFactory;
  Menu: IContextMenu3;
  OptionalResult: ^LRESULT;
  MessageId: UINT;
begin
  Module := LoadTestDll;
  try
    GetClassObject := GetProcAddress(Module, 'DllGetClassObject');
    CheckHR(GetClassObject(ShellClassId, IClassFactory, Factory), 'DllGetClassObject');
    CheckHR(Factory.CreateInstance(nil, IContextMenu3, Menu), 'Create menu callback');
    OptionalResult := nil;
    for MessageId in [WM_INITMENUPOPUP, WM_DRAWITEM, WM_MEASUREITEM, WM_MENUCHAR] do
      // Delphi declares a var parameter, but the native COM ABI permits NULL.
      // This calls the real DLL through COM with an omitted result pointer.
      Assert.IsTrue(Menu.HandleMenuMsg2(MessageId, 0, 0, OptionalResult^) = E_NOTIMPL,
        'An unhandled menu callback with NULL result must return safely');
  finally
    Menu := nil;
    Factory := nil;
    FreeLibrary(Module);
  end;
end;
procedure TBasicTests.PanelReadsUnmappedProjectMetadata;
var
  Panel: TProjectInfoPanel;
  Row: TProjectInfoRow;
  HasConfiguration, HasPlatforms: Boolean;
begin
  Panel := TProjectInfoPanel.Create(WriteProject('20.4'), 96);
  try
    Assert.IsTrue(Panel.IsValid, 'Metadata must not depend on an IDE-version mapping');
    Assert.AreEqual('Not mapped (project format 20.4)', Panel.Rows[0].Value);
    HasConfiguration := False;
    HasPlatforms := False;
    for Row in Panel.Rows do
    begin
      if Row.Caption = 'Build configuration' then HasConfiguration := Row.Value = 'Release';
      if Row.Caption = 'Available platforms' then HasPlatforms := Row.Value = 'Win32, Win64';
    end;
    Assert.IsTrue(HasConfiguration);
    Assert.IsTrue(HasPlatforms);
  finally
    Panel.Free;
  end;
end;

procedure TBasicTests.PanelPaintPreservesHostDCAndBounds(Dpi: Integer);
var
  Panel, Standard: TProjectInfoPanel;
  Bitmap: TBitmap;
  DC: HDC;
  FontBefore: HGDIOBJ;
  Background, Foreground: COLORREF;
  Bounds: TRect;
  Dark, HasIconPixels: Boolean;
  Module: HMODULE;
  Row: TProjectInfoRow;
  IconInfo: TIconInfo;
  IconBitmap: Winapi.Windows.TBitmap;
  IconCount, X, Y, Padding, IconSize: Integer;
begin
  Module := LoadLibraryEx(PChar(TestDllPath), 0, LOAD_LIBRARY_AS_DATAFILE);
  Assert.IsTrue(Module <> 0, 'Load actual DLL icon resources');
  Panel := nil;
  Standard := nil;
  Bitmap := nil;
  try
    Panel := TProjectInfoPanel.Create(WriteProject('20.4'), Dpi, Module);
    Standard := TProjectInfoPanel.Create(WriteProject('20.4'), 96, Module);
    Padding := MulDiv(10, Dpi, 96);
    IconSize := MulDiv(16, Dpi, 96);
    IconCount := 0;
    for Row in Panel.Rows do
      if Row.Icon <> 0 then
      begin
        Inc(IconCount);
        Assert.IsTrue(GetIconInfo(Row.Icon, IconInfo));
        try
          Assert.IsTrue(GetObject(IconInfo.hbmColor, SizeOf(IconBitmap), @IconBitmap) <> 0);
          Assert.AreEqual(IconSize, IconBitmap.bmWidth, 'Icon width follows menu DPI');
          Assert.AreEqual(IconSize, IconBitmap.bmHeight, 'Icon height follows menu DPI');
        finally
          if IconInfo.hbmColor <> 0 then DeleteObject(IconInfo.hbmColor);
          if IconInfo.hbmMask <> 0 then DeleteObject(IconInfo.hbmMask);
        end;
      end;
    Assert.AreEqual(5, IconCount, 'Version, framework, configuration and platform icons');
    Assert.IsTrue(Panel.Width >= Standard.Width);
    Assert.IsTrue(Panel.Height >= Standard.Height);
    if Dpi > 96 then Assert.IsTrue(Panel.Height > Standard.Height);
    Bitmap := TBitmap.Create;
    Bitmap.PixelFormat := pf32bit;
    Bitmap.SetSize(Panel.Width + 8, Panel.Height + 8);
    Bounds := Rect(4, 4, Panel.Width + 4, Panel.Height + 4);
    for Dark in [False, True] do
    begin
      Bitmap.Canvas.Brush.Color := clFuchsia;
      Bitmap.Canvas.FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
      DC := Bitmap.Canvas.Handle;
      SetTextColor(DC, RGB(12, 34, 56));
      SetBkColor(DC, RGB(78, 90, 12));
      SetBkMode(DC, OPAQUE);
      FontBefore := GetCurrentObject(DC, OBJ_FONT);
      if Dark then
      begin
        Background := RGB(43, 43, 43);
        Foreground := RGB(245, 245, 245);
      end
      else
      begin
        Background := RGB(250, 250, 250);
        Foreground := RGB(20, 20, 20);
      end;
      Panel.Paint(DC, Bounds, Background, Foreground);
      Assert.AreEqual<Cardinal>(RGB(12, 34, 56), GetTextColor(DC));
      Assert.AreEqual<Cardinal>(RGB(78, 90, 12), GetBkColor(DC));
      Assert.AreEqual(OPAQUE, GetBkMode(DC));
      Assert.IsTrue(FontBefore = GetCurrentObject(DC, OBJ_FONT));
      Assert.AreEqual<Cardinal>(Background, GetPixel(DC, Bounds.Left, Bounds.Top));
      Assert.AreEqual<Cardinal>(RGB(255, 0, 255), GetPixel(DC, Bounds.Left, Bounds.Bottom));
      Assert.AreEqual<Cardinal>(RGB(255, 0, 255), GetPixel(DC, Bounds.Right, Bounds.Top));
      Assert.AreEqual<Cardinal>(RGB(255, 0, 255), GetPixel(DC, 0, 0));
      // Text starts beyond this gutter; colored pixels must come from icons.
      HasIconPixels := False;
      for Y := Bounds.Top + Padding to Bounds.Bottom - Padding - 1 do
        for X := Bounds.Left + Padding to Bounds.Left + Padding + IconSize - 1 do
          if GetPixel(DC, X, Y) <> Background then HasIconPixels := True;
      Assert.IsTrue(HasIconPixels, 'Icons must be painted on both light and dark backgrounds');
      // Save only when an explicit local rendering check requests artifacts.
      if GetEnvironmentVariable('DDS_PANEL_PREVIEW') <> '' then
        Bitmap.SaveToFile(TPath.Combine(GetEnvironmentVariable('DDS_PANEL_PREVIEW'),
          Format('panel-%d-%s.bmp', [Dpi, BoolToStr(Dark, True)])));
    end;
  finally
    Bitmap.Free;
    Standard.Free;
    Panel.Free;
    FreeLibrary(Module);
  end;
end;
end.
