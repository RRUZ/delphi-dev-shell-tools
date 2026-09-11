//**************************************************************************************************
//
// Unit DelphiDevShellTools.GUI.SettingsModel
// Synchronizes the Settings custom-tools editor with its in-memory datasets.
// https://github.com/RRUZ/delphi-dev-shell-tools
//
// The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy of the
// License at http://www.mozilla.org/MPL/
//
//**************************************************************************************************
unit DelphiDevShellTools.GUI.SettingsModel;

interface

uses
  System.Classes,
  System.JSON,
  Datasnap.DBClient;

type
  TCustomToolData = record
    Id: string;
    Name: string;
    GroupName: string;
    MenuLabel: string;
    Extensions: string;
    Script: string;
    ImageKey: string;
    VersionId: string;
    Review: string;
    RunAsAdministrator: Boolean;
    Enabled: Boolean;
  end;

  TSettingsToolsModel = class
  private
    FTools: TClientDataSet;
    FVersions: TClientDataSet;
    FView: TClientDataSet;
    function GetCount: Integer;
    function GetSelectedIndex: Integer;
    procedure ConfigureDataSets;
    procedure MigrateIconAssignments;
  public
    constructor Create(ATools, AVersions: TClientDataSet;
      ADocument: TJSONObject);
    destructor Destroy; override;
    function Current: TCustomToolData;
    function ItemAt(AIndex: Integer): TCustomToolData;
    procedure UpdateCurrent(const AValue: TCustomToolData);
    procedure SelectIndex(AIndex: Integer);
    procedure Append;
    procedure DeleteCurrent;
    procedure FillVersionItems(ANames, AIds: TStrings);
    procedure FillIconItems(AItems: TStrings);
    procedure LoadMacroDefinitions(ANames, ADescriptions: TStrings;
      const ADirectory: string = '');
    procedure Save(ADocument: TJSONObject);
    function HasReviews: Boolean;
    class function SplitExtensions(const AValue: string): TArray<string>; static;
    class function JoinExtensions(const AValues: TArray<string>): string; static;
    class function Validate(const AValue: TCustomToolData): string; static;
    property Count: Integer read GetCount;
    property SelectedIndex: Integer read GetSelectedIndex;
  end;

implementation

uses
  System.Math,
  System.SysUtils,
  System.Win.ComObj,
  Data.DB,
  DelphiDevShellTools.Icons,
  DelphiDevShellTools.DelphiVersions,
  DelphiDevShellTools.Misc,
  DelphiDevShellTools.SettingsStore;

procedure TSettingsToolsModel.ConfigureDataSets;
begin
  FTools.FieldByName('Id').Visible := False;
  FTools.FieldByName('Script').Visible := False;
  FTools.FieldByName('Review').ReadOnly := True;
  FTools.FieldByName('Review').DisplayLabel := 'Assignment review';
  FTools.FieldByName('VersionId').DisplayLabel := 'Minimum Delphi ID';
  for var LFieldName in ['Name', 'Group', 'Menu', 'Extensions', 'Image',
    'VersionId', 'Review'] do
    FTools.FieldByName(LFieldName).DisplayWidth := 24;
end;

procedure TSettingsToolsModel.MigrateIconAssignments;
var
  LDescriptor: TProjectIconDescriptor;
begin
  FTools.DisableControls;
  try
    FTools.First;
    while not FTools.Eof do
    begin
      var LIconKey := FTools.FieldByName('Image').AsString;
      if not TryGetProjectIcon(LIconKey, LDescriptor) then
      begin
        LIconKey := DefaultCustomToolIconKey(
          FTools.FieldByName('Name').AsString);
        FTools.Edit;
        FTools.FieldByName('Image').AsString := LIconKey;
        FTools.Post;
      end;
      FTools.Next;
    end;
    FTools.First;
  finally
    FTools.EnableControls;
  end;
end;
constructor TSettingsToolsModel.Create(ATools, AVersions: TClientDataSet;
  ADocument: TJSONObject);
begin
  inherited Create;
  FTools := ATools;
  FVersions := AVersions;
  LoadTools(FTools, ADocument);
  LoadVersionChoices(FVersions);
  ConfigureDataSets;
  MigrateIconAssignments;
  FTools.LogChanges := False;
  FView := TClientDataSet.Create(nil);
  FView.CloneCursor(FTools, True, True);
  FView.ReadOnly := True;
end;

destructor TSettingsToolsModel.Destroy;
begin
  FView.Free;
  inherited;
end;

function TSettingsToolsModel.GetCount: Integer;
begin
  if Assigned(FTools) and FTools.Active then
    Result := FTools.RecordCount
  else
    Result := 0;
end;

function TSettingsToolsModel.GetSelectedIndex: Integer;
begin
  if (Count = 0) or FTools.IsEmpty then
    Exit(-1);
  Result := FTools.RecNo - 1;
end;

function TSettingsToolsModel.Current: TCustomToolData;
begin
  Result := Default(TCustomToolData);
  if (Count = 0) or FTools.IsEmpty then
    Exit;
  Result.Id := FTools.FieldByName('Id').AsString;
  Result.Name := FTools.FieldByName('Name').AsString;
  Result.GroupName := FTools.FieldByName('Group').AsString;
  Result.MenuLabel := FTools.FieldByName('Menu').AsString;
  Result.Extensions := FTools.FieldByName('Extensions').AsString;
  Result.Script := FTools.FieldByName('Script').AsString;
  Result.ImageKey := FTools.FieldByName('Image').AsString;
  Result.VersionId := FTools.FieldByName('VersionId').AsString;
  Result.Review := FTools.FieldByName('Review').AsString;
  Result.RunAsAdministrator := FTools.FieldByName('RunAs').AsBoolean;
  Result.Enabled := Result.Review = '';
end;

function TSettingsToolsModel.ItemAt(AIndex: Integer): TCustomToolData;
begin
  Result := Default(TCustomToolData);
  if (AIndex < 0) or (AIndex >= Count) then
    Exit;
  FView.First;
  FView.MoveBy(AIndex);
  Result.Id := FView.FieldByName('Id').AsString;
  Result.Name := FView.FieldByName('Name').AsString;
  Result.GroupName := FView.FieldByName('Group').AsString;
  Result.MenuLabel := FView.FieldByName('Menu').AsString;
  Result.Extensions := FView.FieldByName('Extensions').AsString;
  Result.Script := FView.FieldByName('Script').AsString;
  Result.ImageKey := FView.FieldByName('Image').AsString;
  Result.VersionId := FView.FieldByName('VersionId').AsString;
  Result.Review := FView.FieldByName('Review').AsString;
  Result.RunAsAdministrator := FView.FieldByName('RunAs').AsBoolean;
  Result.Enabled := Result.Review = '';
end;
procedure TSettingsToolsModel.UpdateCurrent(const AValue: TCustomToolData);
var
  LVersion: TDelphiVersions;
begin
  if (Count = 0) or FTools.IsEmpty then
    Exit;
  var LCurrent := Current;
  if AValue.Id <> LCurrent.Id then
    raise EDatabaseError.Create('The selected custom tool has changed. Select it again before editing.');
  var LReview := LCurrent.Review;
  if (LReview <> '') and not SameText(LReview, cDisabledCommandReview) then
  begin
    // A migration review is not a user-disabled flag. Retain its explanation
    // until a valid assignment is explicitly selected or enabled.
    if ((AValue.VersionId <> LCurrent.VersionId) or AValue.Enabled) and
      ((AValue.VersionId = '*') or TryDelphiVersionID(AValue.VersionId, LVersion)) then
      LReview := '';
  end
  else if AValue.Enabled then
    LReview := ''
  else
    LReview := cDisabledCommandReview;

  FTools.Edit;
  try
    FTools.FieldByName('Name').AsString := AValue.Name;
    FTools.FieldByName('Group').AsString := AValue.GroupName;
    FTools.FieldByName('Menu').AsString := AValue.MenuLabel;
    FTools.FieldByName('Extensions').AsString := AValue.Extensions;
    FTools.FieldByName('Script').AsString := AValue.Script;
    FTools.FieldByName('Image').AsString := AValue.ImageKey;
    FTools.FieldByName('VersionId').AsString := AValue.VersionId;
    var LReviewField := FTools.FieldByName('Review');
    if LReviewField.AsString <> LReview then
    begin
      // Only the model may change this diagnostic field, not data-bound editors.
      var LReadOnly := LReviewField.ReadOnly;
      LReviewField.ReadOnly := False;
      try
        LReviewField.AsString := LReview;
      finally
        LReviewField.ReadOnly := LReadOnly;
      end;
    end;
    FTools.FieldByName('RunAs').AsBoolean := AValue.RunAsAdministrator;
    FTools.Post;
  except
    FTools.Cancel;
    raise;
  end;
end;

procedure TSettingsToolsModel.SelectIndex(AIndex: Integer);
begin
  if Count = 0 then
    Exit;
  FTools.RecNo := EnsureRange(AIndex, 0, Count - 1) + 1;
end;

procedure TSettingsToolsModel.Append;
begin
  FTools.Append;
  FTools.FieldByName('Id').AsString := 'command:' +
    TGUID.NewGuid.ToString;
  FTools.FieldByName('VersionId').AsString := '*';
  FTools.FieldByName('RunAs').AsBoolean := False;
  FTools.FieldByName('Image').AsString := 'wrench';
  FTools.Post;
end;

procedure TSettingsToolsModel.DeleteCurrent;
begin
  if (Count > 0) and not FTools.IsEmpty then
    FTools.Delete;
end;

procedure TSettingsToolsModel.FillVersionItems(ANames, AIds: TStrings);
begin
  ANames.BeginUpdate;
  AIds.BeginUpdate;
  try
    ANames.Clear;
    AIds.Clear;
    if not Assigned(FVersions) or not FVersions.Active then
      Exit;
    FVersions.DisableControls;
    try
      FVersions.First;
      while not FVersions.Eof do
      begin
        ANames.Add(FVersions.FieldByName('Name').AsString);
        AIds.Add(FVersions.FieldByName('VersionId').AsString);
        FVersions.Next;
      end;
      FVersions.First;
    finally
      FVersions.EnableControls;
    end;
  finally
    AIds.EndUpdate;
    ANames.EndUpdate;
  end;
end;

procedure TSettingsToolsModel.FillIconItems(AItems: TStrings);
begin
  AItems.BeginUpdate;
  try
    AItems.Clear;
    for var LDescriptor in GetProjectIconDescriptors do
      AItems.Add(LDescriptor.Key);
  finally
    AItems.EndUpdate;
  end;
end;

procedure TSettingsToolsModel.LoadMacroDefinitions(ANames,
  ADescriptions: TStrings; const ADirectory: string);
var
  LXmlDocument: OleVariant;
  LNodes: OleVariant;
  LNodeCount: Integer;
  LIndex: Integer;
begin
  ANames.Clear;
  ADescriptions.Clear;
  var LFolder := ADirectory;
  if LFolder = '' then
    LFolder := GetDelphiDevShellToolsFolder;
  if LFolder = '' then
    Exit;
  var LFileName := IncludeTrailingPathDelimiter(LFolder) + 'macros.xml';
  if not FileExists(LFileName) then
    Exit;

  LXmlDocument := CreateOleObject('Msxml2.DOMDocument.6.0');
  LXmlDocument.Async := False;
  LXmlDocument.Load(LFileName);
  LXmlDocument.SetProperty('SelectionLanguage', 'XPath');
  if LXmlDocument.parseError.errorCode <> 0 then
    raise Exception.CreateFmt('Error in XML data: %s',
      [string(LXmlDocument.parseError.reason)]);
  LNodes := LXmlDocument.selectNodes('//Macros/Macro');
  LNodeCount := Integer(LNodes.Length);
  for LIndex := 0 to LNodeCount - 1 do
  begin
    ANames.Add(string(LNodes.Item(LIndex).getAttribute('name')));
    ADescriptions.Add(string(
      LNodes.Item(LIndex).getAttribute('description')));
  end;
end;
procedure TSettingsToolsModel.Save(ADocument: TJSONObject);
begin
  FTools.CheckBrowseMode;
  StoreTools(FView, ADocument);
end;

function TSettingsToolsModel.HasReviews: Boolean;
begin
  Result := False;
  FView.First;
  while not FView.Eof do
  begin
    if FView.FieldByName('Review').AsString <> '' then
      Exit(True);
    FView.Next;
  end;
end;
class function TSettingsToolsModel.SplitExtensions(
  const AValue: string): TArray<string>;
begin
  Result := AValue.Split([',', ';', ' '], TStringSplitOptions.ExcludeEmpty);
  for var LIndex := 0 to High(Result) do
  begin
    Result[LIndex] := Trim(Result[LIndex]);
    if (Result[LIndex] <> '') and not Result[LIndex].StartsWith('.') then
      Result[LIndex] := '.' + Result[LIndex];
  end;
end;

class function TSettingsToolsModel.JoinExtensions(
  const AValues: TArray<string>): string;
begin
  Result := string.Join(',', AValues);
end;

class function TSettingsToolsModel.Validate(
  const AValue: TCustomToolData): string;
var
  LVersion: TDelphiVersions;
begin
  if Trim(AValue.Name) = '' then
    Exit('Enter a command name');
  if Trim(AValue.MenuLabel) = '' then
    Exit('Enter a menu label');
  if Trim(AValue.Script) = '' then
    Exit('Enter a command script');
  if (AValue.VersionId <> '*') and
    not TryDelphiVersionID(AValue.VersionId, LVersion) then
    Exit('Choose a minimum Delphi version');
  if AValue.Review <> '' then
    Exit(AValue.Review);
  Result := '';
end;

end.
