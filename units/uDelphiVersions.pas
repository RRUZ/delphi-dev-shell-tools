{**************************************************************************************************}
{                                                                                                  }
{ Unit uDelphiVersions                                                                             }
{ unit for the Delphi Dev Shell Tools                                                              }
{ http://code.google.com/p/delphi-dev-shell-tools/                                                 }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is uDelphiVersions.pas.                                                        }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013 Rodrigo Ruz V.                         }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}


unit uDelphiVersions;

interface

uses
  Generics.Defaults,
  Generics.Collections,
  uSupportedIDEs,
  Windows,
  Graphics,
  SysUtils,
  Classes;

{$DEFINE DELPHI_OLDER_VERSIONS_SUPPORT}

type
  TDelphiVersions =
    (
  {$IFDEF DELPHI_OLDER_VERSIONS_SUPPORT}
    Delphi5,
    Delphi6,
  {$ENDIF}
    Delphi7,
    Delphi8,
    Delphi2005,
    Delphi2006,
    Delphi2007,
    Delphi2009,
    Delphi2010,
    DelphiXE,
    DelphiXE2,
    DelphiXE3,
    DelphiXE4
);

  SetDelphiVersions= TArray<TDelphiVersions>;

  TDelphiVersionData=Class
  private
    FVersion: TDelphiVersions;
    FName: string;
    FPath: string;
    FIcon: TIcon;
    FIDEType: TSupportedIDEs;
    FBitmap: TBitmap;
    //FBitmap13: TBitmap;
  public
    property Version : TDelphiVersions read FVersion;
    property Path    : string read FPath write FPath;
    property Name    : string read FName write FName;
    property Icon    : TIcon read FIcon write FIcon;
    property IDEType : TSupportedIDEs read FIDEType write FIDEType;
    property Bitmap  : TBitmap read FBitmap write FBitmap;
    //property Bitmap13: TBitmap read FBitmap13 write FBitmap13;
    constructor Create;

    Destructor  Destroy; override;
  end;

type
  TMSBuildDProj=class
  private
    FFrameworkType: string;
    FProjectFile : string;
    FTargetPlatforms: TStrings;
    FGUID: string;
    FAppType : string;
    FDelphiVersion : TDelphiVersions;
    FDefaultConfiguration : string;
    FDefaultPlatForm : string;
    FValidData : Boolean;
    FBuildConfigurations: TStrings;
    procedure LoadInfo;
  public
    property FrameworkType : string read FFrameworkType;
    property TargetPlatforms : TStrings read FTargetPlatforms write FTargetPlatforms;
    property BuildConfigurations : TStrings read FBuildConfigurations write FBuildConfigurations;
    property GUID : string read FGUID;
    property AppType : string read FAppType;
    property DelphiVersion : TDelphiVersions read FDelphiVersion;
    property DefaultConfiguration : string read  FDefaultConfiguration; //Release, Debug
    property DefaultPlatForm : string read  FDefaultPlatForm; //Win32, OSX
    property ValidData : Boolean read FValidData;
    constructor Create(const ProjectFile : string);
    Destructor  Destroy; override;
  end;

  TPAClientProfile=class
  private
    FPlatform: string;
    FHost: string;
    FPort: Integer;
    FName: string;
    FFileName: string;
    FRADStudioVersion: TDelphiVersions;
  public
    property Platform : string read FPlatform;
    property Host : string read FHost;
    property Port : Integer read FPort;
    property Name : string read FName;
    property FileName : string read FFileName;
    property RADStudioVersion : TDelphiVersions read FRADStudioVersion;
  end;

  TPAClientProfileList=class
  private
    FProfiles: TObjectList<TPAClientProfile>;
    FListDelphiVersions:TList<TDelphiVersionData>;
    procedure LoadData;
  public
    property    Profiles : TObjectList<TPAClientProfile> read FProfiles;
    constructor Create(ListDelphiVersions:TList<TDelphiVersionData>);
    Destructor  Destroy; override;
  end;

const
  {$IFDEF DELPHI_OLDER_VERSIONS_SUPPORT}
  DelphiOldVersions = 2;
  DelphiOldVersionNumbers: array[0..DelphiOldVersions-1] of TDelphiVersions =(Delphi5,Delphi6);
  {$ENDIF}

  DelphiVersionsNames: array[TDelphiVersions] of string = (
  {$IFDEF DELPHI_OLDER_VERSIONS_SUPPORT}
    'Delphi 5',
    'Delphi 6',
  {$ENDIF}
    'Delphi 7',
    'Delphi 8',
    'BDS 2005',
    'BDS 2006',
    'RAD Studio 2007',
    'RAD Studio 2009',
    'RAD Studio 2010',
    'RAD Studio XE',
    'RAD Studio XE2',
    'RAD Studio XE3',
    'RAD Studio XE4'
    );

  DelphiVersionNumbers: array[TDelphiVersions] of double =
    (
  {$IFDEF DELPHI_OLDER_VERSIONS_SUPPORT}
    13,      // 'Delphi 5',
    14,      // 'Delphi 6',
  {$ENDIF}
    15,      // 'Delphi 7',
    16,      // 'Delphi 8',
    17,      // 'BDS 2005',
    18,      // 'BDS 2006',
    18.5,    // 'RAD Studio 2007',
    20,      // 'RAD Studio 2009',
    21,      // 'RAD Studio 2010',
    22,      // 'RAD Studio XE'
    23,      // 'RAD Studio XE2'
    24,      // 'RAD Studio XE3'
    25       // 'RAD Studio XE4'
    );



  DelphiRegPaths: array[TDelphiVersions] of string = (
  {$IFDEF DELPHI_OLDER_VERSIONS_SUPPORT}
    '\Software\Borland\Delphi\5.0',
    '\Software\Borland\Delphi\6.0',
  {$ENDIF}
    '\Software\Borland\Delphi\7.0',
    '\Software\Borland\BDS\2.0',
    '\Software\Borland\BDS\3.0',
    '\Software\Borland\BDS\4.0',
    '\Software\Borland\BDS\5.0',
    '\Software\CodeGear\BDS\6.0',
    '\Software\CodeGear\BDS\7.0',
    '\Software\Embarcadero\BDS\8.0',
    '\Software\Embarcadero\BDS\9.0',
    '\Software\Embarcadero\BDS\10.0',
    '\Software\Embarcadero\BDS\11.0'
    );

 PAClientProfilesPaths: array[TDelphiVersions] of string = (
  {$IFDEF DELPHI_OLDER_VERSIONS_SUPPORT}
    '',
    '',
  {$ENDIF}
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '',
    '\Embarcadero\BDS\9.0',
    '\Embarcadero\BDS\10.0',
    '\Embarcadero\BDS\11.0'
    );

  procedure FillListDelphiVersions(AList:TList<TDelphiVersionData>);
  {$IFDEF DELPHI_OLDER_VERSIONS_SUPPORT}
  function DelphiIsOldVersion(DelphiVersion:TDelphiVersions) : Boolean;
  {$ENDIF}
  procedure ReplaceColor(ABitmap: TBitmap; SourceColor, TargetColor: TColor);
  procedure MakeBitmapMenuTransparent(ABitmap: TBitmap);
  function GetDelphiVersions(const ProjectFile: string) : SetDelphiVersions;

implementation

uses
  uMisc,
  Winapi.PsAPI,
  Controls,
  System.Variants,
  ComObj,
  ActiveX,
  System.StrUtils,
  ImgList,
  GraphUtil,
  CommCtrl,
  Typinfo,
  ShellAPI,
  Winapi.ShlObj,
  IOUtils,
  uRegistry,
  System.Types,
  Registry;

constructor TMSBuildDProj.Create(const ProjectFile : string);
begin
 inherited Create;
 FProjectFile:=ProjectFile;
 FTargetPlatforms  :=TStringList.Create;
 FBuildConfigurations :=TStringList.Create;
 FValidData  := False;
 if FileExists(ProjectFile) then
   LoadInfo;
end;

destructor TMSBuildDProj.Destroy;
begin
  FTargetPlatforms.Free;
  FBuildConfigurations.Free;
  inherited;
end;



procedure TMSBuildDProj.LoadInfo;
var
  ns: string;
  XmlDoc: OleVariant;
  Nodes, Node: OleVariant;
  i, lNodes : Integer;
  sdv : SetDelphiVersions;
  LDelphiVersion      : TDelphiVersions;
begin

  sdv:=GetDelphiVersions(FProjectFile);
  for LDelphiVersion in sdv do
  if  LDelphiVersion<=TDelphiVersions.DelphiXE then
  begin
    FDelphiVersion:=LDelphiVersion;
    FFrameworkType := 'VCL';
    FTargetPlatforms.Add('Win32');

    CoInitialize(nil);
    try
      XmlDoc := CreateOleObject('Msxml2.DOMDocument.6.0');
      try
        XmlDoc.Async := False;
        XmlDoc.Load(FProjectFile);

        if (XmlDoc.parseError.errorCode <> 0) then
        begin
          FValidData:=False;
          Exit;
        end
        else
          FValidData:=True;

        XmlDoc.SetProperty('SelectionLanguage', 'XPath');
         ns := Format('xmlns:a=%s',[QuotedStr('http://schemas.microsoft.com/developer/msbuild/2003')]);
         XmlDoc.setProperty('SelectionNamespaces', ns);

        FDefaultPlatForm:='Win32';


        if LDelphiVersion=Delphi2007 then
        begin
          Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:Configuration');
          if not VarIsClear(Node) then
            FDefaultConfiguration := Node.Text;
        end
        else
        begin
          Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:Config');
          if not VarIsClear(Node) then
            FDefaultConfiguration := Node.Text;
        end;

        Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:ProjectGuid');
        if not VarIsClear(Node) then
          FGUID := Node.Text;

        Node := XmlDoc.selectSingleNode('/a:Project/a:ProjectExtensions/a:Borland.ProjectType');
        if not VarIsClear(Node) then
          FAppType := Node.Text;

        FBuildConfigurations.Add('Debug');
        FBuildConfigurations.Add('Release');
      finally
        XmlDoc := Unassigned;
      end;
    finally
      CoUninitialize;
    end;

    break;
  end
  else
  begin
    FDelphiVersion:=LDelphiVersion;
    CoInitialize(nil);
    try
      XmlDoc := CreateOleObject('Msxml2.DOMDocument.6.0');
      try
        XmlDoc.Async := False;
        XmlDoc.Load(FProjectFile);

        if (XmlDoc.parseError.errorCode <> 0) then
        begin
          FValidData:=False;
          Exit;
        end
        else
          FValidData:=True;

        XmlDoc.SetProperty('SelectionLanguage', 'XPath');
         ns := Format('xmlns:a=%s',[QuotedStr('http://schemas.microsoft.com/developer/msbuild/2003')]);
         XmlDoc.setProperty('SelectionNamespaces', ns);

        Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:Config');
        if not VarIsClear(Node) then
          FDefaultConfiguration := Node.Text;

        Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:FrameworkType');
        if not VarIsClear(Node) then
          FFrameworkType := Node.Text;

        Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:ProjectGuid');
        if not VarIsClear(Node) then
          FGUID := Node.Text;

        Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:AppType');
        if not VarIsClear(Node) then
          FAppType := Node.Text;

        Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:Platform');
        if not VarIsClear(Node) then
          FDefaultPlatForm := Node.Text;

        Nodes := XmlDoc.selectNodes('//a:Project/a:ProjectExtensions/a:BorlandProject/a:Platforms/a:Platform');
        lNodes:= Nodes.Length;
        for i:= 0 to lNodes-1 do
         if SameText(Nodes.Item(i).Text,'True') then
           FTargetPlatforms.Add(Nodes.Item(i).getAttribute('value'));


        Nodes := XmlDoc.selectNodes('//a:Project/a:ItemGroup/a:BuildConfiguration');
        lNodes:= Nodes.Length;
        for i:= 0 to lNodes-1 do
         if not SameText(Nodes.Item(i).getAttribute('Include'),'Base') then
           FBuildConfigurations.Add(Nodes.Item(i).getAttribute('Include'));


      finally
        XmlDoc := Unassigned;
      end;
    finally
      CoUninitialize;
    end;
    Break;
  end;
end;


function GetDelphiVersions(const ProjectFile: string) : SetDelphiVersions;
var
  sVersion, ns, ProjectExt, ProjectPath : string;
  XmlDoc: OleVariant;
  Node: OleVariant;
begin
  SetLength(Result, 0);
  CoInitialize(nil);
  try
    ProjectExt  :=ExtractFileExt(ProjectFile);
    ProjectPath :=ExtractFilePath(ProjectFile);
    if SameText(ProjectExt, '.dproj') then
    begin
        XmlDoc := CreateOleObject('Msxml2.DOMDocument.6.0');
        try
          XmlDoc.Async := False;
          XmlDoc.Load(ProjectFile);
          XmlDoc.SetProperty('SelectionLanguage', 'XPath');
           ns := Format('xmlns:a=%s',[QuotedStr('http://schemas.microsoft.com/developer/msbuild/2003')]);
           XmlDoc.setProperty('SelectionNamespaces', ns);

          if (XmlDoc.parseError.errorCode <> 0) then
            exit;  //raise Exception.CreateFmt('Error in Xml Data %s', [XmlDoc.parseError]);

          Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:ProjectVersion');
          if not VarIsClear(Node) then
          begin
            sVersion := Node.Text;
            if sVersion='14.6' then
             Exit(TArray<TDelphiVersions>.Create(DelphiXE4))
            else
            if sVersion='14.3' then
             Exit(TArray<TDelphiVersions>.Create(DelphiXE3))
            else
            if sVersion='13.4' then
             Exit(TArray<TDelphiVersions>.Create(DelphiXE2))
            else
            if MatchText(sVersion,['12.2','12.3']) then
             Exit(TArray<TDelphiVersions>.Create(DelphiXE))
            else
            if MatchText(sVersion,['12.0']) then
             Exit(TArray<TDelphiVersions>.Create(Delphi2009, Delphi2010));
          end
          else
          begin
            Exit(TArray<TDelphiVersions>.Create(Delphi2007))
          end;
        finally
          XmlDoc := Unassigned;
        end;
    end
    else
    if SameText(ProjectExt, '.bdsproj') then
      Exit(TArray<TDelphiVersions>.Create(Delphi2005, Delphi2006))
  finally
    CoUninitialize;
  end;
end;

{$IFDEF DELPHI_OLDER_VERSIONS_SUPPORT}
function DelphiIsOldVersion(DelphiVersion:TDelphiVersions) : Boolean;
var
 i  : integer;
begin
 Result:=False;
  for i:=0  to DelphiOldVersions-1 do
    if DelphiVersion=DelphiOldVersionNumbers[i] then
    begin
       Result:=True;
       exit;
    end;
end;

{$ENDIF}

procedure ReplaceColor(ABitmap: TBitmap; SourceColor, TargetColor: TColor);
type
  TRGBBytes = array[0..2] of Byte;
var
  I: Integer;
  X: Integer;
  Y: Integer;
  Size: Integer;
  Pixels: PByteArray;
  LSourceColor: TRGBBytes;
  LTargetColor: TRGBBytes;
const
  TripleSize = SizeOf(TRGBBytes);
begin
  case ABitmap.PixelFormat of
    pf24bit: Size := SizeOf(TRGBTriple);
    pf32bit: Size := SizeOf(TRGBQuad);
  else
    exit;
  end;

  for I := 0 to TripleSize - 1 do
  begin
    LSourceColor[I] := Byte(SourceColor shr (16 - (I * 8)));
    LTargetColor[I] := Byte(TargetColor shr (16 - (I * 8)));
  end;

  for Y := 0 to ABitmap.Height - 1 do
  begin
    Pixels := ABitmap.ScanLine[Y];
    for X := 0 to ABitmap.Width - 1 do
      if CompareMem(@Pixels[(X * Size)], @LSourceColor, TripleSize) then
        Move(LTargetColor, Pixels[(X * Size)], TripleSize);
  end;
end;

procedure MakeBitmapMenuTransparent(ABitmap: TBitmap);
var
  ColorLeftCorner, ColorBackMenu: TColor;
begin
 ColorBackMenu := GetSysColor(COLOR_MENU);
 ColorLeftCorner := ABitmap.Canvas.Pixels[0, 0];
 ReplaceColor(ABitmap, ColorLeftCorner, ColorBackMenu);
end;

procedure FillListDelphiVersions(AList:TList<TDelphiVersionData>);
Var
  Factor : Double;
  VersionData : TDelphiVersionData;
  DelphiComp  : TDelphiVersions;
  FileName    : string;
  Found       : boolean;
  ColorLeftCorner, ColorBackMenu: TColor;
  TempBitmap  : TBitmap;
  CX : Integer;
begin
  for DelphiComp := Low(TDelphiVersions) to High(TDelphiVersions) do
  begin
    Found := RegKeyExists(DelphiRegPaths[DelphiComp], HKEY_CURRENT_USER);
    if Found then
      Found := RegReadStr(DelphiRegPaths[DelphiComp], 'App', FileName, HKEY_CURRENT_USER) and FileExists(FileName);

    if not Found then
    begin
      Found := RegKeyExists(DelphiRegPaths[DelphiComp], HKEY_LOCAL_MACHINE);
      if Found then
        Found := RegReadStr(DelphiRegPaths[DelphiComp], 'App', FileName, HKEY_LOCAL_MACHINE) and FileExists(FileName);
    end;


    ColorBackMenu := GetSysColor(COLOR_MENU);
    if Found then
    begin
      VersionData:=TDelphiVersionData.Create;
      VersionData.FPath:=Filename;
      VersionData.FVersion:=DelphiComp;
      VersionData.FName   :=DelphiVersionsNames[DelphiComp];
      VersionData.FIDEType:=TSupportedIDEs.DelphiIDE;
      VersionData.Icon    :=TIcon.Create;



      ExtractIconFile(VersionData.FIcon, Filename, SHGFI_SMALLICON);
      {
      VersionData.FBitmap := Graphics.TBitmap.Create;
      VersionData.FBitmap.PixelFormat:=pf24bit;
      VersionData.FBitmap.Width := VersionData.FIcon.Width;
      VersionData.FBitmap.Height := VersionData.FIcon.Height;
      VersionData.FBitmap.Canvas.Draw(0, 0, VersionData.FIcon);
      VersionData.FBitmap13:=TBitmap.Create;
      ScaleImage( VersionData.FBitmap, VersionData.FBitmap13, 0.81);
                                            }

      CX:=GetSystemMetrics(SM_CXMENUCHECK);
      if CX>=16 then
      begin
        VersionData.FBitmap := Graphics.TBitmap.Create;
        ExtractBitmapFile(VersionData.FBitmap, Filename, SHGFI_SMALLICON);
      end
      else
      begin
        TempBitmap:=TBitmap.Create;
        try
          VersionData.FBitmap := Graphics.TBitmap.Create;
          ExtractBitmapFile(TempBitmap, Filename, SHGFI_SMALLICON);
          Factor:= CX/16;
          ScaleImage(TempBitmap, VersionData.FBitmap, Factor);
        finally
          TempBitmap.Free;
        end;

      end;

      ColorLeftCorner := VersionData.FBitmap.Canvas.Pixels[0, 0];
      ReplaceColor(VersionData.FBitmap, ColorLeftCorner, ColorBackMenu);
      AList.Add(VersionData);
    end;
  end;

end;



{ TDelphiVersionData }

constructor TDelphiVersionData.Create;
begin
   inherited;
   FBitmap:=nil;
   //FBitmap13:=nil;
   FIcon:=nil;
end;

destructor TDelphiVersionData.Destroy;
begin
  if FBitmap<>nil then
    FBitmap.Free;

  if FIcon<>nil then
    FIcon.Free;
  {
  if FBitmap13<>nil then
    FBitmap13.Free;
  }
  inherited;
end;

{ TPAClientProfileList }

constructor TPAClientProfileList.Create(ListDelphiVersions:TList<TDelphiVersionData>);
begin
  inherited Create;
  FListDelphiVersions:=ListDelphiVersions;
  FProfiles:=TObjectList<TPAClientProfile>.Create(True);
  LoadData;
end;

destructor TPAClientProfileList.Destroy;
begin
  FProfiles.Free;
  inherited;
end;

procedure TPAClientProfileList.LoadData;
var
  LDelphiVersionData  : TDelphiVersionData;
  ns, sProfile, sProfilePath : string;
  XmlDoc: OleVariant;
  Node: OleVariant;
begin
  CoInitialize(nil);
  try
    for LDelphiVersionData in FListDelphiVersions do
    if LDelphiVersionData.Version>=DelphiXE2  then
    begin
      sProfilePath:=IncludeTrailingPathDelimiter(GetSpecialFolder(CSIDL_APPDATA))+PAClientProfilesPaths[LDelphiVersionData.Version];
      for sProfile in TDirectory.GetFiles(sProfilePath,'*.profile') do
      begin
        FProfiles.Add(TPAClientProfile.Create);
        FProfiles[FProfiles.Count-1].FName:=ChangeFileExt(ExtractFileName(sProfile),'');
        FProfiles[FProfiles.Count-1].FFileName:=ExtractFileName(sProfile);
        FProfiles[FProfiles.Count-1].FRADStudioVersion:=LDelphiVersionData.Version;

        XmlDoc := CreateOleObject('Msxml2.DOMDocument.6.0');
        try
          XmlDoc.Async := False;
          XmlDoc.Load(sProfile);
          XmlDoc.SetProperty('SelectionLanguage', 'XPath');
           ns := Format('xmlns:a=%s',[QuotedStr('http://schemas.microsoft.com/developer/msbuild/2003')]);
           XmlDoc.setProperty('SelectionNamespaces', ns);

          if (XmlDoc.parseError.errorCode <> 0) then
            Exit;//raise Exception.CreateFmt('Error in Xml Data %s', [XmlDoc.parseError]);

          Node := XmlDoc.selectSingleNode('/a:Project//a:PropertyGroup/a:Profile_platform');
          if not VarIsClear(Node) then
           FProfiles[FProfiles.Count-1].FPlatform:=Node.text;

          Node := XmlDoc.selectSingleNode('/a:Project//a:PropertyGroup/a:Profile_host');
          if not VarIsClear(Node) then
           FProfiles[FProfiles.Count-1].FHost:=Node.text;

          Node := XmlDoc.selectSingleNode('/a:Project//a:PropertyGroup/a:Profile_port');
          if not VarIsClear(Node) then
           TryStrToInt(Node.text, FProfiles[FProfiles.Count-1].FPort);

        finally
          XmlDoc := Unassigned;
        end;

      end;
    end;
  finally
    CoUninitialize;
  end;

end;

end.
