//**************************************************************************************************
//
// Unit DelphiDevShellTools.GUI.Execution
// GUI command runner with IDE/target selection, progress reporting and execution results.
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
// The Original Code is DelphiDevShellTools.GUI.Execution.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit DelphiDevShellTools.GUI.Execution;

interface

function RunCommandRequest(const RequestFile: string): Integer;

implementation

uses DelphiDevShellTools.SettingsStore, System.JSON, System.SysUtils, System.UITypes, System.Classes, System.IOUtils, System.Win.Registry,
  Winapi.Windows, Vcl.Forms, Vcl.StdCtrls, Vcl.Controls, Vcl.Dialogs,
  DelphiDevShellTools.Commands, DelphiDevShellTools.Execution,
  DelphiDevShellTools.Installations, DelphiDevShellTools.DelphiVersions;

procedure Preferences(var Profile: string; var Variant: TIDEVariant; Save: Boolean);
var Document, Execution: TJSONObject; Name: string;
begin
  Document := LoadUserConfiguration;
  try
    Execution := Document.GetValue<TJSONObject>('execution');
    if Save then
    begin
      Name := 'automatic';
      case Variant of ivWin32: Name := 'win32'; ivWin64: Name := 'win64'; end;
      PutJSON(Execution, 'preferredInstallation', TJSONString.Create(Profile));
      PutJSON(Execution, 'preferredVariant', TJSONString.Create(Name));
      SaveConfiguration(UserSettingsDirectory, Document);
    end
    else
    begin
      Profile := Execution.GetValue<string>('preferredInstallation', '');
      Name := Execution.GetValue<string>('preferredVariant', 'automatic');
      Variant := ivAutomatic;
      if Name = 'win32' then Variant := ivWin32;
      if Name = 'win64' then Variant := ivWin64;
    end;
  finally
    Document.Free;
  end;
end;

function ChooseInstallation(var Request: TCommandRequest; const Items: TArray<TIDEInstallation>;
  var Index: Integer; var Variant: TIDEVariant): Boolean;
var Form: TForm; List: TListBox; Remember: TCheckBox; OK, Cancel: TButton;
  Config, Platform: TComboBox; LabelControl: TLabel; I, Choice: Integer;
  Indices: TArray<Integer>; Variants: TArray<TIDEVariant>;
  Item: TIDEInstallation; V: TIDEVariant; Project: TMSBuildDProj; Value, Profile: string;
begin
  Result := False;
  Form := TForm.CreateNew(nil);
  try
    Form.Caption := 'Choose Delphi';
    Form.Position := poScreenCenter;
    Form.BorderStyle := bsDialog;
    Form.ClientWidth := 590;
    Form.ClientHeight := 370;
    LabelControl := TLabel.Create(Form);
    LabelControl.Parent := Form;
    LabelControl.SetBounds(16, 12, 558, 35);
    LabelControl.Caption := ExtractFileName(Request.FileName);
    List := TListBox.Create(Form);
    List.Parent := Form;
    List.SetBounds(16, 40, 558, 172);
    for I := 0 to High(Items) do
    begin
      Item := Items[I];
      if (Request.Kind = ckBuild) and (Item.EnvironmentScript = '') then Continue;
      for V := ivWin32 to ivWin64 do
        if Item.Executable(V) <> '' then
        begin
          Value := '32-bit IDE';
          if V = ivWin64 then Value := '64-bit IDE';
          Choice := List.Items.Add(Item.Name + ' - ' + Value + ' (' + Item.RootDirectory + ')');
          Indices := Indices + [I];
          Variants := Variants + [V];
          if (I = Index) and ((V = Variant) or
            ((Variant = ivAutomatic) and (Item.Executable(ivAutomatic) = Item.Executable(V)))) then
            List.ItemIndex := Choice;
        end;
    end;
    if (List.ItemIndex < 0) and (List.Count > 0) then List.ItemIndex := 0;
    Config := TComboBox.Create(Form);
    Config.Parent := Form;
    Config.SetBounds(16, 228, 270, 28);
    Config.Style := csDropDownList;
    Config.Items.Add('Project default configuration');
    Platform := TComboBox.Create(Form);
    Platform.Parent := Form;
    Platform.SetBounds(304, 228, 270, 28);
    Platform.Style := csDropDownList;
    Platform.Items.Add('Project default platform');
    if SameText(ExtractFileExt(Request.FileName), '.dproj') then
    begin
      Project := TMSBuildDProj.Create(Request.FileName);
      try
        Config.Items.AddStrings(Project.BuildConfigurations);
        for Value in Project.TargetPlatforms do
          if SameText(Value, 'Win32') or SameText(Value, 'Win64') then Platform.Items.Add(Value);
      finally
        Project.Free;
      end;
    end;
    if Config.Items.Count = 1 then Config.Items.AddStrings(['Debug', 'Release']);
    if Platform.Items.Count = 1 then Platform.Items.AddStrings(['Win32', 'Win64']);
    Config.ItemIndex := Config.Items.IndexOf(Request.Configuration);
    if Config.ItemIndex < 0 then Config.ItemIndex := 0;
    Platform.ItemIndex := Platform.Items.IndexOf(Request.Platform);
    if Platform.ItemIndex < 0 then Platform.ItemIndex := 0;
    Config.Visible := Request.Kind = ckBuild;
    Platform.Visible := Request.Kind = ckBuild;
    Remember := TCheckBox.Create(Form);
    Remember.Parent := Form;
    Remember.SetBounds(16, 275, 558, 24);
    Remember.Caption := 'Use this installation and IDE variant as my preference';
    OK := TButton.Create(Form);
    OK.Parent := Form;
    OK.SetBounds(380, 324, 92, 30);
    OK.Caption := 'Open';
    if Request.Kind = ckBuild then OK.Caption := 'Build';
    OK.Default := True;
    OK.ModalResult := mrOk;
    OK.Enabled := List.Count > 0;
    Cancel := TButton.Create(Form);
    Cancel.Parent := Form;
    Cancel.SetBounds(482, 324, 92, 30);
    Cancel.Caption := 'Cancel';
    Cancel.Cancel := True;
    Cancel.ModalResult := mrCancel;
    if Form.ShowModal <> mrOk then Exit;
    if List.ItemIndex < 0 then Exit;
    Index := Indices[List.ItemIndex];
    Variant := Variants[List.ItemIndex];
    if Request.Kind = ckBuild then
    begin
      Request.Configuration := '';
      Request.Platform := '';
      if Config.ItemIndex > 0 then Request.Configuration := Config.Text;
      if Platform.ItemIndex > 0 then Request.Platform := Platform.Text;
    end;
    if Remember.Checked then
    begin
      Profile := Items[Index].Id;
      Preferences(Profile, Variant, True);
    end;
    Result := True;
  finally
    Form.Free;
  end;
end;

function ResolveSelection(var Request: TCommandRequest): Boolean;
var Items: TArray<TIDEInstallation>; Index: Integer; Variant, PreferredVariant: TIDEVariant;
  Preferred, Detected: string; Versions: SetDelphiVersions; Project: TMSBuildDProj;
begin
  Result := False;
  Items := DiscoverInstallations;
  if Length(Items) = 0 then raise EFileNotFoundException.Create('No installed Delphi IDE was found.');
  Preferred := '';
  PreferredVariant := ivAutomatic;
  Preferences(Preferred, PreferredVariant, False);
  Detected := '';
  Versions := GetDelphiVersions(Request.FileName);
  if Length(Versions) > 0 then Detected := ExtractFileName(DelphiRegPaths[Versions[0]]);
  Index := SelectInstallation(Items, Request, Preferred, Detected, PreferredVariant,
    SameText(ExtractFileExt(Request.FileName), '.dproj') or
    SameText(ExtractFileExt(Request.FileName), '.groupproj'), Variant);
  if Request.ChooseIDE or (Index < 0) then
    if not ChooseInstallation(Request, Items, Index, Variant) then Exit;
  if (Request.Kind = ckBuild) and SameText(ExtractFileExt(Request.FileName), '.dproj') then
  begin
    Project := TMSBuildDProj.Create(Request.FileName);
    try
      if Request.Configuration = '' then Request.Configuration := Project.DefaultConfiguration;
      if Request.Platform = '' then Request.Platform := Project.DefaultPlatForm;
    finally
      Project.Free;
    end;
  end;
  ResolveIDECommand(Request, Items[Index], Variant);
  Result := True;
end;

function RunCommandRequest(const RequestFile: string): Integer;
var Request: TCommandRequest; Directory, LogFile: string; Progress: TForm;
  LabelControl: TLabel; CloseButton: TButton; Output: TMemo;
begin
  Result := 1;
  Directory := ExtractFileDir(ExpandFileName(RequestFile));
  Progress := nil;
  Output := nil;
  LabelControl := nil;
  try
    try
      if not SameText(ExtractFileDir(Directory), IncludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA')) + 'DelphiDevShellTools\Requests') then
        raise EArgumentException.Create('Invalid request directory.');
      if (ExtractFileName(RequestFile) <> 'request.json') or
         (TFile.GetSize(RequestFile) > 1024 * 1024) then raise EArgumentException.Create('Invalid request file.');
      Request := TCommandRequest.FromJSON(TFile.ReadAllText(RequestFile, TEncoding.UTF8));
      if (Request.Kind in [ckOpenIDE, ckBuild]) or
         ((Request.Kind = ckTerminal) and (Request.ProfileId <> '')) then
        if not ResolveSelection(Request) then Exit(0);
      LogFile := IncludeTrailingPathDelimiter(GetEnvironmentVariable('LOCALAPPDATA')) + 'DelphiDevShellTools\Logs';
      ForceDirectories(LogFile);
      LogFile := LogFile + '\' + ExtractFileName(Directory) + '.log';
      if Request.Kind = ckBuild then
      begin
        Progress := TForm.CreateNew(nil);
        Progress.Caption := 'Delphi build';
        Progress.Position := poScreenCenter;
        Progress.ClientWidth := 720;
        Progress.ClientHeight := 440;
        Progress.BorderIcons := [];
        LabelControl := TLabel.Create(Progress);
        LabelControl.Parent := Progress;
        LabelControl.SetBounds(12, 12, 696, 30);
        LabelControl.Caption := 'Building ' + ExtractFileName(Request.FileName) + '...';
        Output := TMemo.Create(Progress);
        Output.Parent := Progress;
        Output.SetBounds(12, 48, 696, 340);
        Output.ReadOnly := True;
        Output.ScrollBars := ssBoth;
        Output.WordWrap := False;
        Progress.Show;
        Progress.Update;
      end;
      Result := ExecuteCommand(Request, Directory, LogFile,
        procedure
        begin
          Application.ProcessMessages;
        end);
      if Progress <> nil then
      begin
        LabelControl.Caption := Format('Build finished with exit code %d. Log: %s', [Result, LogFile]);
        if FileExists(LogFile) then Output.Lines.LoadFromFile(LogFile);
        Progress.Hide;
        Progress.BorderIcons := [biSystemMenu];
        CloseButton := TButton.Create(Progress);
        CloseButton.Parent := Progress;
        CloseButton.SetBounds(616, 400, 92, 28);
        CloseButton.Caption := 'Close';
        CloseButton.ModalResult := mrOk;
        CloseButton.Cancel := True;
        Progress.ShowModal;
      end
      else if Result <> 0 then raise EOSError.CreateFmt('Command exited with code %d.', [Result]);
    except
      on E: Exception do
      begin
        Result := 1;
        MessageDlg(E.Message, mtError, [mbOK], 0);
      end;
    end;
  finally
    Progress.Free;
    RemoveRequestDirectory(Directory);
  end;
end;

end.
