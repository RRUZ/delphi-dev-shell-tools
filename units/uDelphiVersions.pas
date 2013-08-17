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
  public
    property Version : TDelphiVersions read FVersion;
    property Path    : string read FPath write FPath;
    property Name    : string read FName write FName;
    property Icon    : TIcon read FIcon write FIcon;
    property IDEType : TSupportedIDEs read FIDEType write FIDEType;
    property Bitmap  : TBitmap read FBitmap write FBitmap;
    constructor Create;
    Destructor  Destroy; override;
  end;

type
  TMSBuildDProj=class
  private
    FFrameworkType: string;
    FProjectFile : string;
    FPlatforms: TStrings;
    procedure LoadInfo;
  public
    property FrameworkType : string read FFrameworkType write FFrameworkType;
    property Platforms : TStrings read FPlatforms write FPlatforms;
    constructor Create(const ProjectFile : string);
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
  CommCtrl,
  Typinfo,
  ShellAPI,
  uRegistry,
  Registry;

constructor TMSBuildDProj.Create(const ProjectFile : string);
begin
 inherited Create;
 FProjectFile:=ProjectFile;
 FPlatforms:=TStringList.Create;
 LoadInfo;
end;

destructor TMSBuildDProj.Destroy;
begin
  FPlatforms.Free;
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
    FFrameworkType := 'VCL';
    FPlatforms.Add('Win32');
    Break;
  end
  else
  begin
    CoInitialize(nil);
    try
      XmlDoc := CreateOleObject('Msxml2.DOMDocument.6.0');
      try
        XmlDoc.Async := False;
        XmlDoc.Load(FProjectFile);
        XmlDoc.SetProperty('SelectionLanguage', 'XPath');
         ns := Format('xmlns:a=%s',[QuotedStr('http://schemas.microsoft.com/developer/msbuild/2003')]);
         XmlDoc.setProperty('SelectionNamespaces', ns);

        if (XmlDoc.parseError.errorCode <> 0) then
          raise Exception.CreateFmt('Error in Xml Data %s', [XmlDoc.parseError]);

        Node := XmlDoc.selectSingleNode('/a:Project/a:PropertyGroup/a:FrameworkType');
        if not VarIsClear(Node) then
          FFrameworkType := Node.Text;

        Nodes := XmlDoc.selectNodes('//a:Project/a:ProjectExtensions/a:BorlandProject/a:Platforms/a:Platform');
        lNodes:= Nodes.Length;
        for i:= 0 to lNodes-1 do
           FPlatforms.Add(Nodes.Item(i).getAttribute('value'));

      finally
        XmlDoc := Unassigned;
      end;
    finally
      CoUninitialize;
    end;
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
            raise Exception.CreateFmt('Error in Xml Data %s', [XmlDoc.parseError]);

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
  VersionData : TDelphiVersionData;
  DelphiComp  : TDelphiVersions;
  FileName    : string;
  Found       : boolean;
  ColorLeftCorner, ColorBackMenu: TColor;
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

      VersionData.FBitmap := Graphics.TBitmap.Create;
      VersionData.FBitmap.PixelFormat:=pf24bit;
      VersionData.FBitmap.Width := VersionData.FIcon.Width;
      VersionData.FBitmap.Height := VersionData.FIcon.Height;
      VersionData.FBitmap.Canvas.Draw(0, 0, VersionData.FIcon);

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
   FIcon:=nil;
end;

destructor TDelphiVersionData.Destroy;
begin
  if FBitmap<>nil then
    FBitmap.Free;

  if FIcon<>nil then
    FIcon.Free;

  inherited;
end;

end.
