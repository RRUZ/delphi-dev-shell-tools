{**************************************************************************************************}
{                                                                                                  }
{ DelphiDevShellTools.GUI.SettingsHost                                                             }
{ Standalone development host for DelphiDevShellTools.GUI.Settings.                                }
{ https://github.com/RRUZ/delphi-dev-shell-tools                                                   }
{                                                                                                  }
{ The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License"); }
{ you may not use this file except in compliance with the License. You may obtain a copy of the    }
{ License at http://www.mozilla.org/MPL/                                                           }
{                                                                                                  }
{ Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF   }
{ ANY KIND, either express or implied. See the License for the specific language governing rights  }
{ and limitations under the License.                                                               }
{                                                                                                  }
{ The Original Code is DelphiDevShellTools.GUI.SettingsHost.dpr.                                   }
{                                                                                                  }
{ The Initial Developer of the Original Code is Rodrigo Ruz V.                                     }
{ Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.                    }
{ All Rights Reserved.                                                                             }
{                                                                                                  }
{**************************************************************************************************}

program DelphiDevShellToolsGUISettingsHost;

uses
  Winapi.Windows,
  System.JSON,
  System.IOUtils,
  System.SysUtils,
  Vcl.Forms,
  Vcl.StdCtrls,
  Vcl.Themes,
  Vcl.Styles,
  DelphiDevShellTools.Logging in '..\units\DelphiDevShellTools.Logging.pas',
  DelphiDevShellTools.UI in '..\units\DelphiDevShellTools.UI.pas',
  DelphiDevShellTools.GUI.Settings in 'DelphiDevShellTools.GUI.Settings.pas' {FrmSettings};

{$R 'GUIResources.res' 'GUIResources.rc'}
{$R 'GUIManifest.res' 'GUIManifest.rc'}

function WindowsStyleRequested: Boolean;
var
  LIndex: Integer;
begin
  Result := False;
  for LIndex := 1 to ParamCount do
    if SameText(ParamStr(LIndex), '--windows-style') then
      Exit(True);
end;

function RequestedPPI: Integer;
begin
  Result := 0;
  for var LIndex := 1 to ParamCount - 1 do
    if SameText(ParamStr(LIndex), '--dpi') then
    begin
      var LPPI: Integer;
      if TryStrToInt(ParamStr(LIndex + 1), LPPI) and (LPPI > 0) then
        Exit(LPPI);
    end;
end;

function FixtureRootRequested: string;
begin
  Result := '';
  for var LIndex := 1 to ParamCount - 1 do
    if SameText(ParamStr(LIndex), '--fixture-root') then
      Exit(ParamStr(LIndex + 1));
end;

function CaptureRequested: Boolean;
begin
  Result := (ParamCount >= 1) and (SameText(ParamStr(1), '--capture') or
    SameText(ParamStr(1), '--capture-sequence'));
end;

procedure SelectSettingsView(const AViewName: string);
begin
  if SameText(AViewName, 'general') then
    FrmSettings.SideBar.ItemIndex := 0
  else if SameText(AViewName, 'menu') then
    FrmSettings.SideBar.ItemIndex := 1
  else if SameText(AViewName, 'custom-tools') then
    FrmSettings.SideBar.ItemIndex := 2
  else if SameText(AViewName, 'about') then
    FrmSettings.SideBar.ItemIndex := 3;
end;

procedure SelectCustomTool(const AToolName: string);
begin
  if (AToolName <> '') and FrmSettings.ClientDataSet1.Active then
    FrmSettings.ClientDataSet1.Locate('Name', AToolName, []);
end;

begin
  var LFixtureRoot := FixtureRootRequested;
  if (LFixtureRoot <> '') and not CaptureRequested then
  begin
    Log('SettingsHost fixture root requires --capture');
    Halt(3);
  end;
  Log('SettingsHost initialize');
  Application.Initialize;
  if WindowsStyleRequested then
  begin
    SetDevShellThemeOverride(dstLight);
    TStyleManager.SetStyle(TStyleManager.SystemStyle);
  end
  else
    ActivateSettingsVclStyle;
  for var LIndex := 1 to ParamCount do
    if SameText(ParamStr(LIndex), '--light-palette') then
      SetDevShellThemeOverride(dstLight);
  Application.MainFormOnTaskbar := True;
  Application.Title := 'Delphi Dev. Shell Tools Settings Host';
  Log('SettingsHost create form');
  var LFixtureDocument: TJSONObject := nil;
  if LFixtureRoot <> '' then
  begin
    var LFixtureFileName := IncludeTrailingPathDelimiter(LFixtureRoot) +
      'settings.json';
    if not TFile.Exists(LFixtureFileName) then
      raise EFileNotFoundException.CreateFmt(
        'Settings capture fixture is missing %s', [LFixtureFileName]);
    LFixtureDocument := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(LFixtureFileName, TEncoding.UTF8)) as TJSONObject;
    if not Assigned(LFixtureDocument) then
      raise EConvertError.CreateFmt('Settings capture fixture is not a JSON object: %s',
        [LFixtureFileName]);
    Log('SettingsHost fixture root=' + LFixtureRoot + ' common=' +
      LFixtureDocument.GetValue<TJSONObject>('settings').GetValue<string>(
        'CommonTaskExt', ''));
    FrmSettings := TFrmSettings.CreateForDocument(Application, LFixtureDocument,
      ExcludeTrailingPathDelimiter(LFixtureRoot));
  end
  else
    Application.CreateForm(TFrmSettings, FrmSettings);
  Log('SettingsHost form created');
  if LFixtureRoot <> '' then
    Log('SettingsHost fixture loaded common=' + FrmSettings.Settings.CommonTaskExt);
  var LRequestedPPI := RequestedPPI;
  if LRequestedPPI <> 0 then
  begin
    FrmSettings.ScaleForPPI(LRequestedPPI);
    FrmSettings.RefreshDpiLayout;
  end;
  if CaptureRequested then
  begin
    Log('SettingsHost configure capture view');
    var LSequenceCapture := SameText(ParamStr(1), '--capture-sequence');
    if (not LSequenceCapture) and (ParamCount >= 3) then
      SelectSettingsView(ParamStr(3));
    if (ParamCount >= 4) and SameText(ParamStr(3), 'custom-tools') then
      SelectCustomTool(ParamStr(4));
    Log('SettingsHost show capture form');
    FrmSettings.Show;
    ShowWindow(FrmSettings.Handle, SW_SHOWNORMAL);
    SetForegroundWindow(FrmSettings.Handle);
    Log('SettingsHost form shown');
    Application.ProcessMessages;
    Log('SettingsHost messages processed');
    var LOpenCombo: TComboBox := nil;
    if (ParamCount >= 5) and SameText(ParamStr(3), 'custom-tools') then
    begin
      if SameText(ParamStr(5), 'open-icons') then
        LOpenCombo := FrmSettings.DBComboBoxImage
      else if SameText(ParamStr(5), 'open-group') then
        LOpenCombo := FrmSettings.DBComboBoxGroup
      else if SameText(ParamStr(5), 'open-versions') then
        LOpenCombo := FrmSettings.DBLookupComboBoxDelphi;
      if Assigned(LOpenCombo) then
      begin
        LOpenCombo.SetFocus;
        LOpenCombo.DroppedDown := True;
        Application.ProcessMessages;
      end;
    end;
    // The custom VCL title panel is a separately buffered paint owner. Refresh
    // it explicitly after show so capture and normal navigation share chrome.
    RedrawWindow(FrmSettings.TitleBarPanel1.Handle, nil, 0,
      RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_UPDATENOW);
    FrmSettings.Update;
    Log('SettingsHost form updated');
    Sleep(100);
    Application.ProcessMessages;
    Log('SettingsHost capture window');
    if LSequenceCapture then
    begin
      ForceDirectories(ParamStr(2));
      var LViews := TArray<string>.Create('general', 'menu', 'custom-tools', 'menu');
      for var LIndex := 0 to High(LViews) do
      begin
        SelectSettingsView(LViews[LIndex]);
        Application.ProcessMessages;
        FrmSettings.Update;
        RedrawWindow(FrmSettings.TitleBarPanel1.Handle, nil, 0,
          RDW_INVALIDATE or RDW_ERASE or RDW_ALLCHILDREN or RDW_UPDATENOW);
        RedrawWindow(FrmSettings.Handle, nil, 0,
          RDW_INVALIDATE or RDW_ERASE or RDW_FRAME or RDW_ALLCHILDREN or RDW_UPDATENOW);
        Sleep(50);
        if not CaptureWindowScreenshot(FrmSettings.Handle,
          TPath.Combine(ParamStr(2), Format('%d-%s.png', [LIndex + 1, LViews[LIndex]]))) then
          Halt(1);
      end;
    end
    else if not CaptureWindowScreenshot(FrmSettings.Handle, ParamStr(2)) then
      Halt(1);
    if Assigned(LOpenCombo) then
    begin
      var LInfo := Default(TComboBoxInfo);
      LInfo.cbSize := SizeOf(LInfo);
      if GetComboBoxInfo(LOpenCombo.Handle, LInfo) then
        if not CaptureWindowScreenshot(LInfo.hwndList,
          ChangeFileExt(ParamStr(2), '.popup.png')) then
          Halt(2);
      LOpenCombo.DroppedDown := False;
    end;
    Log('SettingsHost capture saved');
    FrmSettings.Close;
    Log('SettingsHost form closed');
    FrmSettings.Free;
    FrmSettings := nil;
    LFixtureDocument.Free;
    // A capture is a finite harness action. Do not enter Application.Run with
    // a closed form, otherwise each artifact leaves a headless host process.
    Exit;
  end
  else
  begin
    if (ParamCount >= 2) and SameText(ParamStr(1), '--view') then
      SelectSettingsView(ParamStr(2));
    if (ParamCount >= 3) and SameText(ParamStr(2), 'custom-tools') then
      SelectCustomTool(ParamStr(3));
    Application.Run;
  end;
end.

