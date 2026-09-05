//**************************************************************************************************
//
// Unit ShellTools.BasicTests
// Tests project metadata, shell interfaces, menu construction, manifests and panel rendering.
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
// The Original Code is ShellTools.BasicTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
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
    [TestCase('Delphi11 VCL provisional', '11,VCL,Win32')]
    [TestCase('Delphi11 FMX provisional', '11,FMX,Win32')]
    [TestCase('Delphi12 VCL', '12,VCL,Win64')]
    [TestCase('Delphi12 FMX', '12,FMX,Win32')]
    [TestCase('Delphi13 VCL', '13,VCL,Win32')]
    [TestCase('Delphi13 FMX', '13,FMX,Win32')]
    procedure ReadsModernProjectFixture(IDE: Integer; const Framework, Platform: string);
    [TestCase('Delphi11 provisional', '11')]
    [TestCase('Delphi12', '12')]
    [TestCase('Delphi13', '13')]
    procedure ReadsModernGroupFixture(IDE: Integer);
    [Test] procedure ProvisionalDelphi11SchemaGap;
    [Test] procedure DelphiVersionIdsRemainStable;
    [Test] procedure DetectsRioProjectVersion;
    [Test] procedure ReadsProjectBuildOptions;
    [Test] procedure ReadsGroupProjectRelativePaths;
    [Test] procedure UnknownProjectVersionIsNotMisidentified;
    [Test] procedure MalformedProjectIsRejected;
    [Test] procedure DllExportsRequiredEntryPoints;
    [Test] procedure DllEmbedsShellManifest;
    [Test] procedure GuiEmbedsDpiManifest;
    [Test] procedure ResourceMappingsAndGuiIconMetadataAreStable;
    [Test] procedure HighResolutionLogoFramesAreEmbedded;
    [TestCase('96 DPI', '96,16')]
    [TestCase('120 DPI', '120,20')]
    [TestCase('144 DPI', '144,24')]
    [TestCase('192 DPI', '192,32')]
    procedure MenuImageDpiContract(Dpi, ExpectedPixels: Integer);
    [Test] procedure ImageCacheIdentityAndIcoSelectionFollowDpi;
    [Test] procedure BulletIconNamesAndColorsAreStable;
    [Test] procedure BadgeLabelUsesCompactThemePalette;
    [TestCase('16 px', '16')]
    [TestCase('20 px', '20')]
    [TestCase('24 px', '24')]
    [TestCase('32 px', '32')]
    procedure GeneratedBulletImagesMatchRequestedSize(Size: Integer);
    [Test] procedure AssociatedEditorProviderHasNoLazarusFallback;
    [Test] procedure PanelDpiResourcesAreReleased;
    [Test] procedure DllMenuCallbacksAllowNullResult;
    [Test] procedure PanelReadsUnmappedProjectMetadata;
    [TestCase('96 DPI', '96')]
    [TestCase('120 DPI', '120')]
    [TestCase('144 DPI', '144')]
    [TestCase('192 DPI', '192')]
    procedure PanelPaintPreservesHostDCAndBounds(Dpi: Integer);
    [Test] procedure DllCreatesShellInterfacesAndRejectsEmptySelection;
    [Test] procedure DllFactoryInitializesMenuState;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Classes, Xml.XMLDoc, Xml.XMLIntf,
  Winapi.Windows, Winapi.Messages, Winapi.ActiveX,
  Winapi.ShlObj, Vcl.Graphics, System.Types, DelphiDevShellTools.ProjectInfoPanel,
  DelphiDevShellTools.Tasks, DelphiDevShellTools.DelphiVersions, DelphiDevShellTools.Misc,
  DelphiDevShellTools.UI, DelphiDevShellTools.Icons,
  ShellTools.TestSupport;

function RepositoryFile(const RelativeName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)),
    '..\..\..\' + RelativeName));
end;

function CountText(const Needle, Haystack: string): Integer;
var
  Offset: Integer;
begin
  Result := 0;
  Offset := Pos(Needle, Haystack);
  while Offset > 0 do
  begin
    Inc(Result);
    Offset := Pos(Needle, Haystack, Offset + Length(Needle));
  end;
end;

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

function ModernFixturePath(IDE: Integer; const Name: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)),
    Format('..\..\fixtures\Delphi%d\%s', [IDE, Name])));
end;

function FixtureIDE(IDE: Integer): TDelphiVersions;
begin
  case IDE of
    11: Result := Delphi11Alexandria;
    12: Result := Delphi12Athens;
    13: Result := Delphi13Florence;
  else
    raise Exception.Create('Unsupported fixture IDE');
  end;
end;

procedure TBasicTests.ReadsModernProjectFixture(IDE: Integer; const Framework, Platform: string);
var
  FileName, Name: string;
  Project: TMSBuildDProj;
  Versions: SetDelphiVersions;
  Panel: TProjectInfoPanel;
begin
  Name := Format('Project%s.Delphi%d.dproj', [Framework, IDE]);
  if (Framework = 'FMX') and (IDE >= 12) then
    Name := Format('ProjectFMXDelphi%d.dproj', [IDE]);
  FileName := ModernFixturePath(IDE, Name);
  Assert.IsTrue(FileExists(FileName), FileName);
  Versions := GetDelphiVersions(FileName);
  Assert.AreEqual<NativeInt>(1, Length(Versions));
  Assert.AreEqual(Ord(FixtureIDE(IDE)), Ord(Versions[0]));
  Project := TMSBuildDProj.Create(FileName);
  try
    Assert.IsTrue(Project.ValidData);
    Assert.AreEqual(Ord(FixtureIDE(IDE)), Ord(Project.DelphiVersion));
    Assert.AreEqual(Framework, Project.FrameworkType);
    Assert.AreEqual('Application', Project.AppType);
    Assert.AreEqual('Debug', Project.DefaultConfiguration);
    Assert.AreEqual(Platform, Project.DefaultPlatForm);
    Assert.IsTrue(Project.GUID <> '');
    Assert.IsTrue(Project.BuildConfigurations.IndexOf('Debug') >= 0);
    Assert.IsTrue(Project.BuildConfigurations.IndexOf('Release') >= 0);
    Assert.IsTrue(Project.TargetPlatforms.IndexOf('Win32') >= 0);
    Assert.IsTrue(Project.TargetPlatforms.IndexOf('Win64') >= 0);
    Assert.IsTrue(Project.TargetPlatforms.IndexOf('Android') < 0);
    if IDE = 13 then
      Assert.IsTrue(Project.TargetPlatforms.IndexOf('WinARM64EC') >= 0,
        'Preserve the enabled target supplied by the real Delphi 13 fixture');
  finally
    Project.Free;
  end;
  Panel := TProjectInfoPanel.Create(FileName, 96);
  try
    Assert.IsTrue(Panel.IsValid);
    Assert.AreEqual(DelphiVersionsNames[FixtureIDE(IDE)], Panel.Rows[0].Value);
  finally
    Panel.Free;
  end;
end;

procedure TBasicTests.ReadsModernGroupFixture(IDE: Integer);
var
  Group: TMSBuildGroupProj;
  Project: TMSBuildDProj;
begin
  Group := TMSBuildGroupProj.Create(ModernFixturePath(IDE,
    Format('ProjectGroupDelphi%d.groupproj', [IDE])));
  try
    Assert.IsTrue(Group.ValidData);
    Assert.AreEqual<NativeInt>(2, Group.Projects.Count);
    Assert.AreEqual(Ord(FixtureIDE(IDE)), Ord(Group.DelphiVersion));
    for Project in Group.Projects do
    begin
      Assert.IsTrue(FileExists(Project.ProjectFile), 'Resolve group members relative to the group');
      Assert.IsTrue(Project.ValidData);
      Assert.AreEqual(Ord(FixtureIDE(IDE)), Ord(Project.DelphiVersion));
    end;
    Assert.AreEqual('VCL', Group.Projects[0].FrameworkType);
    Assert.AreEqual('FMX', Group.Projects[1].FrameworkType);
  finally
    Group.Free;
  end;
end;

procedure TBasicTests.ProvisionalDelphi11SchemaGap;
var
  Versions: SetDelphiVersions;
begin
  // TODO: replace this inferred intermediate schema with an IDE-saved fixture.
  Versions := GetDelphiVersions(WriteProject('19.4'));
  Assert.AreEqual<NativeInt>(1, Length(Versions));
  Assert.AreEqual(Ord(Delphi11Alexandria), Ord(Versions[0]));
end;

procedure TBasicTests.DelphiVersionIdsRemainStable;
begin
  // Saved commands store these ordinals. New IDE support must not renumber them.
  Assert.AreEqual(14, Ord(Appmethod113));
  Assert.AreEqual(15, Ord(DelphiXE6));
  Assert.AreEqual(21, Ord(Delphi10Rio));
  Assert.AreEqual(22, Ord(Delphi10Sydney));
  Assert.AreEqual(25, Ord(Delphi13Florence));
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

procedure TBasicTests.DllFactoryInitializesMenuState;
var
  Module: HMODULE;
  GetClassObject: TDllGetClassObject;
  Factory: IClassFactory;
  Menu: IContextMenu;
  ProjectFile: Boolean;
begin
  Module := LoadTestDll;
  try
    GetClassObject := GetProcAddress(Module, 'DllGetClassObject');
    Assert.IsTrue(Assigned(GetClassObject));
    CheckHR(GetClassObject(ShellClassId, IClassFactory, Factory), 'DllGetClassObject');
    for ProjectFile in [False, True] do
    begin
      // Exercise factory initialization and per-instance state without registration.
      CheckHR(Factory.CreateInstance(nil, IContextMenu, Menu), 'Create file menu');
      CheckFileContextMenu(Menu, ProjectFile);
      Menu := nil;
    end;
  finally
    Menu := nil;
    Factory := nil;
    FreeLibrary(Module);
  end;
end;

procedure CheckEmbeddedDpiManifest(const BinaryPath: string; ManifestId: Integer);
var
  Module: HMODULE;
  Resource: TResourceStream;
  Bytes: UTF8String;
  Document: IXMLDocument;
  Node: IXMLNode;
  Context: TActCtx;
  ContextHandle: THandle;
begin
  Module := LoadLibraryEx(PChar(BinaryPath), 0, LOAD_LIBRARY_AS_DATAFILE);
  Assert.IsTrue(Module <> 0);
  try
    Assert.IsTrue(FindResource(Module, MAKEINTRESOURCE(3 - ManifestId), RT_MANIFEST) = 0,
      'Only the appropriate executable or DLL manifest may be embedded');
    Resource := TResourceStream.CreateFromID(Module, ManifestId, RT_MANIFEST);
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
    if ManifestId = 1 then
    begin
      Node := Document.DocumentElement.ChildNodes.FindNode('trustInfo', 'urn:schemas-microsoft-com:asm.v3')
        .ChildNodes.FindNode('security', 'urn:schemas-microsoft-com:asm.v3')
        .ChildNodes.FindNode('requestedPrivileges', 'urn:schemas-microsoft-com:asm.v3')
        .ChildNodes.FindNode('requestedExecutionLevel', 'urn:schemas-microsoft-com:asm.v3');
      Assert.AreEqual('asInvoker', string(Node.Attributes['level']));
    end;
  finally
    FreeLibrary(Module);
  end;
  // Ask Windows to validate the compiled binary's manifest and resolve v6 controls.
  ZeroMemory(@Context, SizeOf(Context));
  Context.cbSize := SizeOf(Context);
  Context.dwFlags := ACTCTX_FLAG_RESOURCE_NAME_VALID;
  Context.lpSource := PChar(BinaryPath);
  Context.lpResourceName := MAKEINTRESOURCE(ManifestId);
  ContextHandle := CreateActCtx(Context);
  Assert.IsTrue(ContextHandle <> INVALID_HANDLE_VALUE,
    'Windows must accept the embedded manifest: ' + SysErrorMessage(GetLastError));
  if ContextHandle <> INVALID_HANDLE_VALUE then ReleaseActCtx(ContextHandle);
end;

procedure TBasicTests.DllEmbedsShellManifest;
begin
  CheckEmbeddedDpiManifest(TestDllPath, 2);
end;

procedure TBasicTests.ResourceMappingsAndGuiIconMetadataAreStable;
var
  LProjectText, LResourceText: string;
begin
  LProjectText := TFile.ReadAllText(RepositoryFile('Build.bat'));
  Assert.IsTrue(Pos('if /i "%~1"=="Icons\images.RC"', LProjectText) > 0);
  Assert.IsTrue(Pos('bin64\llvm-rc.exe" /no-preprocess', LProjectText) > 0,
    'Modern high-resolution ICO frames require LLVM-RC');
  Assert.IsFalse(Pos('AwesomeFont', LProjectText) > 0);
  LProjectText := TFile.ReadAllText(RepositoryFile('DelphiDevShellTools.dproj'));
  Assert.IsFalse(Pos('<RcCompile Include="Icons\images.RC"/>', LProjectText) > 0,
    'MSBuild must not send the high-resolution icon bundle to BRCC32');
  Assert.IsTrue(Pos('<Target Name="CompileHighResolutionImages"', LProjectText) > 0);
  Assert.IsTrue(Pos('<None Include="Icons\images.RC"/>', LProjectText) > 0);
  LResourceText := TFile.ReadAllText(RepositoryFile('Icons\images.RC'));
  Assert.IsTrue(Pos('settings_ico  ICON "settings.ico"', LResourceText) > 0);
  Assert.IsTrue(Pos('platforms_ico ICON "platforms.ico"', LResourceText) > 0);
  Assert.IsFalse(Pos('settings_ico  ICON "platforms.ico"', LResourceText) > 0);
  LResourceText := TFile.ReadAllText(RepositoryFile('GUI\GUIResources.rc'));
  Assert.IsTrue(Pos('MAINICON ICON "GUIDelphiDevShell_Icon.ico"', LResourceText) > 0);
  LProjectText := TFile.ReadAllText(RepositoryFile('GUI\GUIDelphiDevShell.dproj'));
  Assert.AreEqual(1, CountText('<Icon_MainIcon>', LProjectText));
  Assert.IsTrue(Pos('<Icon_MainIcon>GUIDelphiDevShell_Icon.ico</Icon_MainIcon>', LProjectText) > 0);
  Assert.IsFalse(Pos('AwesomeFont', LProjectText) > 0);
  Assert.IsFalse(TFile.Exists(RepositoryFile('GUI\AwesomeFont.rc')));
  Assert.IsFalse(TFile.Exists(RepositoryFile('GUI\fontawesome.ttf')));
end;

procedure TBasicTests.HighResolutionLogoFramesAreEmbedded;
var
  LBitmap: Winapi.Windows.TBitmap;
  LIcon: HICON;
  LIconInfo: TIconInfo;
  LModule: HMODULE;
  LSize: Integer;
begin
  LModule := LoadLibraryEx(PChar(TestDllPath), 0, LOAD_LIBRARY_AS_DATAFILE);
  Assert.IsTrue(LModule <> 0);
  try
    for LSize in [16, 24, 32, 48, 128, 256] do
    begin
      LIcon := LoadImage(LModule, 'logo_ico', IMAGE_ICON, LSize, LSize,
        LR_DEFAULTCOLOR);
      Assert.IsTrue(LIcon <> 0, Format('Missing %d-pixel logo frame', [LSize]));
      try
        Assert.IsTrue(GetIconInfo(LIcon, LIconInfo));
        try
          try
            Assert.IsTrue(LIconInfo.hbmColor <> 0);
            Assert.IsTrue(LIconInfo.hbmMask <> 0);
            Assert.IsTrue(GetObject(LIconInfo.hbmColor, SizeOf(LBitmap),
              @LBitmap) <> 0);
            Assert.AreEqual(LSize, LBitmap.bmWidth);
            Assert.AreEqual(LSize, LBitmap.bmHeight);
          finally
            if LIconInfo.hbmMask <> 0 then
              DeleteObject(LIconInfo.hbmMask);
          end;
        finally
          if LIconInfo.hbmColor <> 0 then
            DeleteObject(LIconInfo.hbmColor);
        end;
      finally
        DestroyIcon(LIcon);
      end;
    end;
  finally
    FreeLibrary(LModule);
  end;
end;

procedure TBasicTests.MenuImageDpiContract(Dpi, ExpectedPixels: Integer);
begin
  Assert.AreEqual(ExpectedPixels, ImagePixelsForDpi(MenuImageLogicalSize, Dpi));
end;

procedure TBasicTests.ImageCacheIdentityAndIcoSelectionFollowDpi;
var
  Dpi, Expected, KeyIndex: Integer;
  Icon: HICON;
  Info: TIconInfo;
  Bitmap: Winapi.Windows.TBitmap;
  Keys: array[0..3] of string;
begin
  KeyIndex := 0;
  for Dpi in [96, 120, 144, 192] do
  begin
    Expected := ImagePixelsForDpi(MenuImageLogicalSize, Dpi);
    Keys[KeyIndex] := ImageCacheKey('menu', MenuImageLogicalSize, Dpi);
    Icon := LoadIconFileAtSize(RepositoryFile('GUI\GUIDelphiDevShell_Icon.ico'), Expected);
    Assert.IsTrue(Icon <> 0);
    try
      Assert.IsTrue(GetIconInfo(Icon, Info));
      try
        Assert.IsTrue(GetObject(Info.hbmColor, SizeOf(Bitmap), @Bitmap) <> 0);
        Assert.AreEqual(Expected, Bitmap.bmWidth);
        Assert.AreEqual(Expected, Bitmap.bmHeight);
      finally
        if Info.hbmColor <> 0 then DeleteObject(Info.hbmColor);
        if Info.hbmMask <> 0 then DeleteObject(Info.hbmMask);
      end;
    finally
      DestroyIcon(Icon);
    end;
    Inc(KeyIndex);
  end;
  Assert.AreNotEqual(Keys[0], Keys[1]);
  Assert.AreNotEqual(Keys[1], Keys[2]);
  Assert.AreNotEqual(Keys[2], Keys[3]);
end;

procedure TBasicTests.BulletIconNamesAndColorsAreStable;
var
  BulletColor: TColor;
  IconName: string;
  LTheme: TDevShellTheme;
  Names: TStringList;
begin
  LTheme := TDevShellTheme.LightTheme;
  Names := TStringList.Create;
  try
    AddBuiltInBulletIconNames(Names);
    Assert.AreEqual(Length(cBulletIconNames), Names.Count);
    AddBuiltInBulletIconNames(Names);
    Assert.AreEqual(Length(cBulletIconNames), Names.Count);
    for IconName in cBulletIconNames do
      Assert.IsTrue(TryGetBulletColor(IconName, LTheme, BulletColor),
        IconName);
    Assert.IsTrue(TryGetBulletColor('C:\temp\BULLET_RED.ICO', LTheme,
      BulletColor));
    Assert.AreEqual(TColor(LTheme.DangerColor), BulletColor);
    Assert.IsTrue(TryGetBulletColor('bullet_green.ico', LTheme,
      BulletColor));
    Assert.AreEqual(TColor(LTheme.SuccessColor), BulletColor);
    Assert.IsTrue(TryGetBulletColor('bullet_orange.ico', LTheme,
      BulletColor));
    Assert.AreEqual(TColor(LTheme.WarningColor), BulletColor);
    Assert.IsTrue(TryGetBulletColor('bullet_pink.ico', LTheme,
      BulletColor));
    Assert.AreEqual(TColor(LTheme.DangerColor), BulletColor);
    Assert.IsTrue(TryGetBulletColor('bullet_purple.ico', LTheme,
      BulletColor));
    Assert.AreEqual(TColor(LTheme.PrimaryColor), BulletColor);
    Assert.IsTrue(TryGetBulletColor('bullet_white.ico', LTheme,
      BulletColor));
    Assert.AreEqual(TColor(LTheme.TextColor), BulletColor);
    Assert.IsTrue(TryGetBulletColor('bullet_yellow.ico', LTheme,
      BulletColor));
    Assert.AreEqual(TColor(LTheme.WarningColor), BulletColor);
    Assert.IsFalse(TryGetBulletColor('compile.ico', LTheme, BulletColor));
  finally
    Names.Free;
  end;
end;

procedure TBasicTests.BadgeLabelUsesCompactThemePalette;
begin
  var LTheme := TDevShellTheme.LightTheme;
  var LBadge := TDevShellBadgeLabel.Create(nil);
  try
    LBadge.Caption := 'Win64';
    LBadge.ApplyTheme(LTheme);
    Assert.AreEqual(TDevShellTheme.cBadgeFontSize, LBadge.Font.Size);
    Assert.AreEqual(TDevShellTheme.cFontSize - 1, LBadge.Font.Size);
    LBadge.BadgeRole := dsbrSuccess;
    Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.SuccessColor),
      ColorToRGB(LBadge.Font.Color));
    Assert.IsTrue(LBadge.NaturalWidth > 16);
    LBadge.BadgeRole := dsbrWarning;
    Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.WarningColor),
      ColorToRGB(LBadge.Font.Color));
  finally
    LBadge.Free;
  end;
end;

procedure TBasicTests.GeneratedBulletImagesMatchRequestedSize(Size: Integer);
type
  TRGBQuadArray = array[0..1023] of TRGBQuad;
  PRGBQuadArray = ^TRGBQuadArray;
var
  Bitmap: Vcl.Graphics.TBitmap;
  BulletColor: TColor;
  CenterRow, CornerRow: PRGBQuadArray;
  Icon: HICON;
  IconBitmap: Winapi.Windows.TBitmap;
  IconInfo: TIconInfo;
  LTheme: TDevShellTheme;
begin
  LTheme := TDevShellTheme.LightTheme;
  Assert.IsTrue(TryGetBulletColor('bullet_green.ico', LTheme, BulletColor));
  Bitmap := Vcl.Graphics.TBitmap.Create;
  try
    CreateBulletBitmap(Bitmap, BulletColor, Size, LTheme);
    Assert.AreEqual(Size, Bitmap.Width);
    Assert.AreEqual(Size, Bitmap.Height);
    Assert.AreNotEqual(Bitmap.Canvas.Pixels[0, 0],
      Bitmap.Canvas.Pixels[Size div 2, Size div 2]);
    CornerRow := Bitmap.ScanLine[Size - 1];
    CenterRow := Bitmap.ScanLine[Size - 1 - Size div 2];
    Assert.AreEqual(0, Integer(CornerRow[0].rgbReserved));
    Assert.IsTrue(CenterRow[Size div 2].rgbReserved > 0,
      'Sphere center must carry alpha.');
  finally
    Bitmap.Free;
  end;

  Icon := CreateBulletIcon(BulletColor, Size, LTheme);
  Assert.IsTrue(Icon <> 0);
  try
    Assert.IsTrue(GetIconInfo(Icon, IconInfo));
    try
      Assert.IsTrue(GetObject(IconInfo.hbmColor, SizeOf(IconBitmap),
        @IconBitmap) <> 0);
      Assert.AreEqual(Size, IconBitmap.bmWidth);
      Assert.AreEqual(Size, IconBitmap.bmHeight);
    finally
      if IconInfo.hbmColor <> 0 then DeleteObject(IconInfo.hbmColor);
      if IconInfo.hbmMask <> 0 then DeleteObject(IconInfo.hbmMask);
    end;
  finally
    DestroyIcon(Icon);
  end;
end;

procedure TBasicTests.AssociatedEditorProviderHasNoLazarusFallback;
var
  EditorFile: string;
begin
  EditorFile := TPath.Combine(FDirectory, 'associated-editor.exe');
  TFile.WriteAllBytes(EditorFile, TBytes.Create($4D, $5A));
  Assert.AreEqual(EditorFile, ResolveAssociatedEditorIcon(EditorFile));
  Assert.AreEqual('', ResolveAssociatedEditorIcon(TPath.Combine(FDirectory, 'missing.exe')));
end;

procedure TBasicTests.PanelDpiResourcesAreReleased;
var
  BeforeGdi, BeforeUser, AfterGdi, AfterUser: DWORD;
  Dpi, Iteration: Integer;
  Module: HMODULE;
  Panel: TProjectInfoPanel;
begin
  Module := LoadLibraryEx(PChar(TestDllPath), 0, LOAD_LIBRARY_AS_DATAFILE);
  Assert.IsTrue(Module <> 0);
  try
    BeforeGdi := GetGuiResources(GetCurrentProcess, 0);
    BeforeUser := GetGuiResources(GetCurrentProcess, 1);
    for Iteration := 1 to 10 do
      for Dpi in [96, 120, 144, 192] do
      begin
        Panel := TProjectInfoPanel.Create(WriteProject('999.0'), Dpi, Module);
        Panel.Free;
      end;
    AfterGdi := GetGuiResources(GetCurrentProcess, 0);
    AfterUser := GetGuiResources(GetCurrentProcess, 1);
    Assert.IsTrue(AfterGdi <= BeforeGdi + 1, 'GDI objects must be released');
    Assert.IsTrue(AfterUser <= BeforeUser + 1, 'Icon handles must be released');
  finally
    FreeLibrary(Module);
  end;
end;

procedure TBasicTests.GuiEmbedsDpiManifest;
begin
  CheckEmbeddedDpiManifest(ExtractFilePath(TestDllPath) + 'GUIDelphiDevShell.exe', 1);
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
  HasConfiguration, HasFramework, HasPlatforms, HasTarget: Boolean;
begin
  Panel := TProjectInfoPanel.Create(WriteProject('999.0'), 96);
  try
    Assert.IsTrue(Panel.IsValid, 'Metadata must not depend on an IDE-version mapping');
    Assert.AreEqual('Not mapped (project format 999.0)', Panel.Rows[0].Value);
    HasConfiguration := False;
    HasFramework := False;
    HasPlatforms := False;
    HasTarget := False;
    for Row in Panel.Rows do
    begin
      if Row.Caption = 'Framework' then
      begin
        HasFramework := Row.Value = 'VCL';
        Assert.AreEqual(Ord(pivkBadge), Ord(Row.ValueKind));
        Assert.AreEqual(Ord(dsbrPrimary), Ord(Row.BadgeRole));
      end;
      if Row.Caption = 'Build configuration' then
      begin
        HasConfiguration := Row.Value = 'Release';
        Assert.AreEqual(Ord(pivkBadge), Ord(Row.ValueKind));
        Assert.AreEqual(Ord(dsbrSuccess), Ord(Row.BadgeRole));
      end;
      if Row.Caption = 'Target platform' then
      begin
        HasTarget := Row.Value = 'Win64';
        Assert.AreEqual(Ord(pivkBadge), Ord(Row.ValueKind));
        Assert.AreEqual(Ord(dsbrPrimary), Ord(Row.BadgeRole));
      end;
      if Row.Caption = 'Available platforms' then
      begin
        HasPlatforms := Row.Value = 'Win32, Win64';
        Assert.AreEqual(Ord(pivkBadgeList), Ord(Row.ValueKind));
        Assert.AreEqual(Ord(dsbrMuted), Ord(Row.BadgeRole));
      end;
    end;
    Assert.IsTrue(HasConfiguration);
    Assert.IsTrue(HasFramework);
    Assert.IsTrue(HasPlatforms);
    Assert.IsTrue(HasTarget);
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
  Background: COLORREF;
  Bounds: TRect;
  HasIconPixels: Boolean;
  Palette: Integer;
  Module: HMODULE;
  Row: TProjectInfoRow;
  LDescriptor: TProjectIconDescriptor;
  LTheme: TDevShellTheme;
  IconCount, X, Y, Padding, IconSize: Integer;
begin
  Module := LoadLibraryEx(PChar(TestDllPath), 0, LOAD_LIBRARY_AS_DATAFILE);
  Assert.IsTrue(Module <> 0, 'Load actual DLL icon resources');
  Panel := nil;
  Standard := nil;
  Bitmap := nil;
  try
    Panel := TProjectInfoPanel.Create(WriteProject('999.0'), Dpi, Module);
    Standard := TProjectInfoPanel.Create(WriteProject('999.0'), 96, Module);
    Padding := MulDiv(10, Dpi, 96);
    IconSize := MulDiv(16, Dpi, 96);
    IconCount := 0;
    for Row in Panel.Rows do
      if Row.IconKey <> '' then
      begin
        Inc(IconCount);
        Assert.IsTrue(TryGetProjectIcon(Row.IconKey, LDescriptor),
          'Panel row must use a semantic project-icon key: ' + Row.IconKey);
        Assert.IsTrue(LDescriptor.Key = Row.IconKey,
          'Panel row must store the canonical key');
      end;
    Assert.AreEqual(5, IconCount, 'Version, framework, configuration and platform icons');
    Assert.IsTrue(Panel.Width >= Standard.Width);
    Assert.IsTrue(Panel.Height >= Standard.Height);
    if Dpi > 96 then Assert.IsTrue(Panel.Height > Standard.Height);
    Bitmap := TBitmap.Create;
    Bitmap.PixelFormat := pf32bit;
    Bitmap.SetSize(Panel.Width + 8, Panel.Height + 8);
    Bounds := Rect(4, 4, Panel.Width + 4, Panel.Height + 4);
    for Palette := 0 to 2 do
    begin
      Bitmap.Canvas.Brush.Color := clFuchsia;
      Bitmap.Canvas.FillRect(Rect(0, 0, Bitmap.Width, Bitmap.Height));
      DC := Bitmap.Canvas.Handle;
      SetTextColor(DC, RGB(12, 34, 56));
      SetBkColor(DC, RGB(78, 90, 12));
      SetBkMode(DC, OPAQUE);
      FontBefore := GetCurrentObject(DC, OBJ_FONT);
      case Palette of
        1:
          LTheme := TDevShellTheme.DarkTheme;
        2:
          begin
            LTheme := TDevShellTheme.LightTheme;
            LTheme.HighContrast := True;
            LTheme.BackgroundColor := TColor(GetSysColor(COLOR_HIGHLIGHT));
            LTheme.TextColor := TColor(GetSysColor(COLOR_HIGHLIGHTTEXT));
          end;
      else
        LTheme := TDevShellTheme.LightTheme;
      end;
      Background := ColorToRGB(LTheme.BackgroundColor);
      Panel.Paint(DC, Bounds, LTheme);
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
          Format('panel-%d-palette-%d.bmp', [Dpi, Palette])));
    end;
  finally
    Bitmap.Free;
    Standard.Free;
    Panel.Free;
    FreeLibrary(Module);
  end;
end;
end.
