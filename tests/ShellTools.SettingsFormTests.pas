//**************************************************************************************************
//
// Unit ShellTools.SettingsFormTests
// Exercises Settings form events using isolated copied database snapshots.
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
// The Original Code is ShellTools.SettingsFormTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.SettingsFormTests;

interface

uses
  DUnitX.TestFramework, System.JSON, DelphiDevShellTools.GUI.Settings;

type
  [TestFixture]
  TSettingsFormTests = class
  private
    FRoot: string;
    FDocument: TJSONObject;
    FForm: TFrmSettings;
    procedure CreateEditor;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure ToolListSelectionLoadsEveryCopiedRecord;
    [Test] procedure EditorEventsApplyToSnapshotWithoutTouchingDatabase;
    [Test] procedure ResolvingVersionRefreshesEnabledCheckBox;
    [Test] procedure RemovingLastToolClearsDependentControls;
    [Test] procedure CancelDiscardsEditorChanges;
    [Test] procedure CopiedMacrosAndExtensionChipsAreLoaded;
    [Test] procedure ConstructorUsesSuppliedSnapshotInsteadOfDiskConfiguration;
    [Test] procedure SettingsNavigationAndChipLayoutFollowDpiScale;
    [Test] procedure SettingsLayoutKeepsFlowContentAndFooterInsideBoundsAtAllDpi;
    [Test] procedure CommandMemoUsesUnwrappedHorizontalViewport;
    [Test] procedure IdentityCardPreservesLabelToEditorSpacingAtAllDpi;
    [Test] procedure AvailabilityCardTracksCurrentChipRows;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils, System.UITypes, System.Generics.Collections, Data.DB, Vcl.Forms,
  Vcl.Controls, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Themes,
  DelphiDevShellTools.SettingsStore, DelphiDevShellTools.Logging;

procedure TSettingsFormTests.Setup;
begin
  FRoot := TPath.Combine(TPath.GetTempPath, 'DDS-Form-' + TGUID.NewGuid.ToString);
  ForceDirectories(FRoot + '\legacy');
  var LFixture := TPath.GetFullPath(ExtractFilePath(ParamStr(0)) +
    '..\..\fixtures\CustomTools');
  for var LName in ['Tools.db', 'DelphiVersions.db', 'Settings.ini', 'macros.xml'] do
    TFile.Copy(TPath.Combine(LFixture, LName), FRoot + '\legacy\' + LName);
  FDocument := LoadConfiguration(FRoot + '\config', FRoot + '\legacy');
end;

procedure TSettingsFormTests.TearDown;
begin
  FForm.Free;
  FForm := nil;
  FDocument.Free;
  FDocument := nil;
  TStyleManager.SetStyle(TStyleManager.SystemStyle);
  if DirectoryExists(FRoot) then TDirectory.Delete(FRoot, True);
end;

procedure TSettingsFormTests.CreateEditor;
begin
  ActivateSettingsVclStyle;
  FForm := TFrmSettings.CreateForDocument(nil, FDocument, FRoot + '\legacy');
  FForm.SideBar.ItemIndex := 2;
end;

procedure TSettingsFormTests.ToolListSelectionLoadsEveryCopiedRecord;
begin
  CreateEditor;
  var LCommands := FDocument.GetValue<TJSONArray>('commands');
  for var LPass := 1 to 3 do
    for var LIndex := 0 to LCommands.Count - 1 do
    begin
      FForm.DBGrid1.ItemIndex := LIndex;
      var LCommand := LCommands.Items[LIndex] as TJSONObject;
      Assert.AreEqual(LCommand.GetValue<string>('name'), FForm.DBEditName.Text);
      Assert.AreEqual(TrimRight(StringReplace(LCommand.GetValue<string>('script'), #13, '', [rfReplaceAll])),
        TrimRight(StringReplace(FForm.DBMemoScript.Text, #13, '', [rfReplaceAll])));
      Assert.AreEqual(LIndex, FForm.ClientDataSet1.RecNo - 1);
    end;
  FForm.DBGrid1.ItemIndex := 2;
  Assert.AreEqual('ppdep', FForm.DBEditName.Text);
  var LCaptureFolder := GetEnvironmentVariable('DDS_TEST_CAPTURE_DIR');
  if LCaptureFolder <> '' then
  begin
    FForm.Show;
    FForm.Update;
    Application.ProcessMessages;
    Assert.IsTrue(CaptureWindowScreenshot(FForm.Handle,
      TPath.Combine(LCaptureFolder, 'tool-selection-fixed.png')));
  end;
end;

procedure TSettingsFormTests.EditorEventsApplyToSnapshotWithoutTouchingDatabase;
begin
  var LOriginalJSON := TFile.ReadAllText(FRoot + '\config\settings.json');
  var LOriginalDB := TFile.ReadAllText(FRoot + '\legacy\Tools.db');
  CreateEditor;
  FForm.DBGrid1.ItemIndex := 2;
  FForm.DBEditName.Text := 'Edited ppdep';
  FForm.DBMemoScript.Text := 'echo isolated test'#13#10'pause';
  FForm.DBCheckBoxRunAs.Checked := True;
  FForm.CheckBoxShowInfoDProj.Checked := False;
  FForm.DBGrid1.ItemIndex := 0;
  FForm.DBGrid1.ItemIndex := 2;
  Assert.AreEqual('Edited ppdep', FForm.DBEditName.Text);
  Assert.IsTrue(FForm.DBCheckBoxRunAs.Checked);
  FForm.ApplyChangesToSnapshot;
  var LCommand := FForm.Settings.Document.GetValue<TJSONArray>('commands').Items[2] as TJSONObject;
  Assert.AreEqual('Edited ppdep', LCommand.GetValue<string>('name'));
  Assert.AreEqual('echo isolated test'#13#10'pause', LCommand.GetValue<string>('script'));
  Assert.IsTrue(LCommand.GetValue<Boolean>('runAs'));
  Assert.AreEqual('0', FForm.Settings.Document.GetValue<TJSONObject>('settings').GetValue<string>('ShowInfoDProj'));
  Assert.AreEqual(2, FForm.DBGrid1.ItemIndex);
  Assert.AreEqual(LOriginalJSON, TFile.ReadAllText(FRoot + '\config\settings.json'));
  Assert.AreEqual(LOriginalDB, TFile.ReadAllText(FRoot + '\legacy\Tools.db'));
end;

procedure TSettingsFormTests.ResolvingVersionRefreshesEnabledCheckBox;
begin
  var LCommand := FDocument.GetValue<TJSONArray>('commands').Items[0] as TJSONObject;
  LCommand.RemovePair('versionId').Free;
  LCommand.AddPair('versionId', '');
  LCommand.RemovePair('review').Free;
  LCommand.AddPair('review', 'Resolve the legacy version');
  CreateEditor;
  FForm.DBLookupComboBoxDelphi.ItemIndex := 0;
  FForm.CustomToolControlChanged(FForm.DBLookupComboBoxDelphi);
  Assert.AreEqual('', FForm.ClientDataSet1.FieldByName('Review').AsString);
  var LFound := False;
  for var LComponent in FForm do
    if (LComponent is TCheckBox) and (TCheckBox(LComponent).Caption = 'Enabled') then
    begin
      LFound := True;
      Assert.IsTrue(TCheckBox(LComponent).Checked);
    end;
  Assert.IsTrue(LFound);
end;

procedure TSettingsFormTests.RemovingLastToolClearsDependentControls;
begin
  CreateEditor;
  while not FForm.ClientDataSet1.IsEmpty do FForm.ClientDataSet1.Delete;
  Assert.AreEqual(0, FForm.DBGrid1.ItemCount);
  Assert.AreEqual('', FForm.DBEditName.Text);
  Assert.AreEqual('', FForm.DBMemoScript.Text);
  Assert.IsFalse(FForm.DBMemoScript.Enabled);
  Assert.AreEqual(-1, FForm.DBComboBoxImage.ItemIndex);
  Assert.AreEqual(-1, FForm.DBLookupComboBoxDelphi.ItemIndex);
  for var LComponent in FForm do
    if (LComponent is TFlowPanel) and
       (TFlowPanel(LComponent).Parent = FForm.PanelCustomTools) then
      Assert.AreEqual(0, TFlowPanel(LComponent).ControlCount, 'No stale extension chips');
end;

procedure TSettingsFormTests.CancelDiscardsEditorChanges;
begin
  var LBefore := FDocument.ToJSON;
  var LOriginalJSON := TFile.ReadAllText(FRoot + '\config\settings.json');
  CreateEditor;
  FForm.DBEditName.Text := 'Discard this name';
  FForm.ButtonCancelClick(nil);
  Assert.AreEqual(LBefore, FDocument.ToJSON);
  Assert.AreEqual(LOriginalJSON, TFile.ReadAllText(FRoot + '\config\settings.json'));
end;

procedure TSettingsFormTests.CopiedMacrosAndExtensionChipsAreLoaded;
begin
  CreateEditor;
  Assert.IsTrue(FForm.ListViewMacros.Items.Count > 5);
  for var LComponent in FForm do
    if (LComponent is TFlowPanel) and
       (TFlowPanel(LComponent).Parent = FForm.PanelCustomTools) then
    begin
      Assert.AreEqual(6, TFlowPanel(LComponent).ControlCount);
      Assert.IsFalse(seClient in TFlowPanel(LComponent).StyleElements);
      FForm.DBEditExtensions.Text := '.h';
      Assert.AreEqual(2, TFlowPanel(LComponent).ControlCount);
    end;
end;

procedure TSettingsFormTests.ConstructorUsesSuppliedSnapshotInsteadOfDiskConfiguration;
begin
  // The review host supplies an in-memory JSON fixture.  Its FormCreate event
  // must consume that snapshot, never reload the similarly named file on disk.
  var LSettings := FDocument.GetValue<TJSONObject>('settings');
  LSettings.RemovePair('CommonTaskExt').Free;
  LSettings.AddPair('CommonTaskExt', '.snapshot');
  var LCommand := FDocument.GetValue<TJSONArray>('commands').Items[0]
    as TJSONObject;
  LCommand.RemovePair('name').Free;
  LCommand.AddPair('name', 'Snapshot-only command');

  CreateEditor;

  Assert.AreEqual('.snapshot', FForm.EditCommonTaskExt.Text);
  Assert.AreEqual('Snapshot-only command', FForm.DBEditName.Text);
  Assert.IsFalse(TFile.ReadAllText(FRoot + '\config\settings.json').Contains(
    '.snapshot'));
end;

procedure TSettingsFormTests.SettingsNavigationAndChipLayoutFollowDpiScale;
begin
  CreateEditor;
  Assert.AreEqual(MulDiv(880, FForm.CurrentPPI, 96), FForm.ClientWidth);
  Assert.AreEqual(MulDiv(552, FForm.CurrentPPI, 96), FForm.ClientHeight);
  Assert.AreEqual(4, FForm.SideBar.ItemCount);
  Assert.AreEqual(MulDiv(62, FForm.CurrentPPI, 96), FForm.SideBar.ItemHeight);

  var LChipPanelCount := 0;
  for var LComponent in FForm do
    if (LComponent is TFlowPanel) and
       (TFlowPanel(LComponent).Parent = FForm.PanelGeneral) then
    begin
      Inc(LChipPanelCount);
      Assert.IsTrue(TFlowPanel(LComponent).ControlCount > 0,
        'Every General row has chips and an add action');
    end;
  Assert.AreEqual(4, LChipPanelCount);
  Assert.IsFalse(FForm.EditCommonTaskExt.Visible);
  Assert.IsFalse(FForm.EditOpenDelphiExt.Visible);
  Assert.IsFalse(FForm.EditOpenLazarusExt.Visible);
  Assert.IsFalse(FForm.EditCheckSumExt.Visible);

  FForm.SideBar.ItemIndex := 1;
  Assert.IsTrue(FForm.CheckBoxSubMenuCompileRC.BoundsRect.Bottom <=
    FForm.PanelMenu.ClientHeight,
    'The Common tasks rows must stay inside the Menu page at normal creation PPI');
  Assert.IsTrue(FForm.CheckBoxSubMenuRunTouch.BoundsRect.Bottom <=
    FForm.PanelMenu.ClientHeight,
    'The Delphi tools rows must stay inside the Menu page at normal creation PPI');
  Assert.IsTrue(FForm.CheckBoxSubMenuLazarus.BoundsRect.Bottom <=
    FForm.PanelMenu.ClientHeight,
    'The last Lazarus row must stay above the footer at the protected size');
end;

procedure TSettingsFormTests.SettingsLayoutKeepsFlowContentAndFooterInsideBoundsAtAllDpi;
  procedure AssertFlowPanelsFit(AParent: TWinControl; const AContext: string);
  begin
    for var LComponent in FForm do
      if (LComponent is TFlowPanel) and
         (TFlowPanel(LComponent).Parent = AParent) then
      begin
        var LPanel := TFlowPanel(LComponent);
        Assert.IsTrue(LPanel.Left >= 0, AContext + ': flow panel starts before its parent');
        Assert.IsTrue(LPanel.Top >= 0, AContext + ': flow panel starts above its parent');
        Assert.IsTrue(LPanel.BoundsRect.Right <= AParent.ClientWidth,
          AContext + ': flow panel exceeds its parent width');
        Assert.IsTrue(LPanel.BoundsRect.Bottom <= AParent.ClientHeight,
          AContext + ': flow panel exceeds its parent height');
        for var LControlIndex := 0 to LPanel.ControlCount - 1 do
        begin
          var LControl := LPanel.Controls[LControlIndex];
          Assert.IsTrue(LControl.BoundsRect.Right <= LPanel.ClientWidth,
            AContext + ': extension chip exceeds its flow panel width');
          Assert.IsTrue(LControl.BoundsRect.Bottom <= LPanel.ClientHeight,
            AContext + ': extension chip exceeds its flow panel height');
        end;
      end;
  end;
begin
  CreateEditor;
  for var LPPI in TArray<Integer>.Create(96, 120, 144, 192) do
  begin
    FForm.ScaleForPPI(LPPI);
    FForm.RefreshDpiLayout;
    Assert.AreEqual(MulDiv(880, LPPI, 96), FForm.ClientWidth,
      Format('%d DPI preserves the protected client width', [LPPI]));
    Assert.AreEqual(MulDiv(552, LPPI, 96), FForm.ClientHeight,
      Format('%d DPI preserves the protected client height', [LPPI]));
    Assert.IsTrue(FForm.Panel2.Parent = FForm,
      Format('%d DPI keeps the footer on the form shell', [LPPI]));
    Assert.AreEqual(0, FForm.Panel2.Left,
      Format('%d DPI aligns the footer to the window left edge', [LPPI]));
    Assert.AreEqual(FForm.ClientWidth, FForm.Panel2.Width,
      Format('%d DPI spans the footer across the full client width', [LPPI]));
    Assert.IsFalse(FForm.PanelSideBarFooter.Visible,
      Format('%d DPI keeps the obsolete sidebar footer hidden', [LPPI]));
    AssertFlowPanelsFit(FForm.PanelGeneral, Format('General at %d DPI', [LPPI]));
    AssertFlowPanelsFit(FForm.PanelCustomTools,
      Format('Custom tools at %d DPI', [LPPI]));
  end;
end;

procedure TSettingsFormTests.IdentityCardPreservesLabelToEditorSpacingAtAllDpi;
begin
  CreateEditor;
  for var LPPI in TArray<Integer>.Create(96, 120, 144, 192) do
  begin
    FForm.ScaleForPPI(LPPI);
    FForm.RefreshDpiLayout;
    Assert.IsTrue(FForm.LabelDelphi.Top - FForm.DBComboBoxGroup.BoundsRect.Bottom >=
      MulDiv(6, LPPI, 96),
      Format('%d DPI keeps Minimum Delphi clear of the Group editor', [LPPI]));
    Assert.IsTrue(FForm.Label9.Top - FForm.DBLookupComboBoxDelphi.BoundsRect.Bottom >=
      MulDiv(6, LPPI, 96),
      Format('%d DPI keeps Menu Label clear of the Minimum Delphi editor', [LPPI]));
    Assert.IsTrue(FForm.Label9.Top - FForm.DBComboBoxImage.BoundsRect.Bottom >=
      MulDiv(6, LPPI, 96),
      Format('%d DPI keeps Menu Label clear of the Image editor', [LPPI]));
  end;
end;
procedure TSettingsFormTests.AvailabilityCardTracksCurrentChipRows;
  function CustomExtensionPanel: TFlowPanel;
  begin
    Result := nil;
    for var LComponent in FForm do
      if (LComponent is TFlowPanel) and
         (TFlowPanel(LComponent).Parent = FForm.PanelCustomTools) then
        Exit(TFlowPanel(LComponent));
  end;

  procedure SelectTool(const AName: string);
  begin
    for var LIndex := 0 to FForm.DBGrid1.ItemCount - 1 do
    begin
      FForm.DBGrid1.ItemIndex := LIndex;
      if SameText(FForm.DBEditName.Text, AName) then
        Exit;
    end;
    Assert.Fail('Fixture tool was not found: ' + AName);
  end;

  procedure AssertChildrenFit(const APanel: TFlowPanel; const AContext: string);
  begin
    for var LIndex := 0 to APanel.ControlCount - 1 do
      Assert.IsTrue(APanel.Controls[LIndex].BoundsRect.Bottom <=
        APanel.ClientHeight, AContext + ': a badge is vertically clipped');
  end;

begin
  CreateEditor;
  var LPanel := CustomExtensionPanel;
  Assert.IsNotNull(LPanel);

  SelectTool('BRCC32');
  var LOneRowHeight := LPanel.ClientHeight;
  AssertChildrenFit(LPanel, 'BRCC32');

  SelectTool('Formatter Delphi');
  Assert.IsTrue(LPanel.ClientHeight > LOneRowHeight,
    'A wrapped badge set must reserve its second row rather than clipping it');
  AssertChildrenFit(LPanel, 'Formatter Delphi');
end;
procedure TSettingsFormTests.CommandMemoUsesUnwrappedHorizontalViewport;
begin
  CreateEditor;
  Assert.IsFalse(FForm.DBMemoScript.WordWrap,
    'Command lines must remain intact in the compact command viewport');
  Assert.AreEqual(ssBoth, FForm.DBMemoScript.ScrollBars,
    'Long command paths must remain horizontally reachable');
end;

end.


