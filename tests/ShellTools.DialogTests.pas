//**************************************************************************************************
//
// Unit ShellTools.DialogTests
// Tests the palette-aware extension and checksum dialog construction.
// https://github.com/RRUZ/delphi-dev-shell-tools
//
// The contents of this file are subject to the Mozilla Public License Version 1.1 (the "License");
// you may not use this file except in compliance with the License. You may obtain a copy of the
// License at http://www.mozilla.org/MPL/
//
// Software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTY OF
// ANY KIND, either express or implied. See the License for the specific language governing rights.
//
// The Original Code is ShellTools.DialogTests.pas.
//
// The Initial Developer of the Original Code is Rodrigo Ruz V.
// Portions created by Rodrigo Ruz V. are Copyright (C) 2013-2026 Rodrigo Ruz V.
// All Rights Reserved.
//
//**************************************************************************************************
unit ShellTools.DialogTests;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TDialogTests = class
  public
    [Test] procedure ExtensionDialogUsesTheSharedPalette;
    [Test] procedure ChecksumDialogUsesTheSharedPalette;
  end;

implementation

uses
  Winapi.Windows,
  System.IOUtils,
  System.SysUtils,
  System.UITypes,
  Vcl.Forms,
  Vcl.Controls,
  Vcl.Graphics,
  Vcl.StdCtrls,
  Vcl.Themes,
  DelphiDevShellTools.UI,
  DelphiDevShellTools.Logging,
  DelphiDevShellTools.GUI.ExtensionDialog,
  DelphiDevShellTools.GUI.CheckSum;

procedure TDialogTests.ExtensionDialogUsesTheSharedPalette;
begin
  SetDevShellThemeOverride(dstDark);
  try
    var LDialog := TFrmExtensionDialog.Create(nil);
    try
      var LTheme := TDevShellTheme.ActiveTheme;
      Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.BackgroundColor),
        ColorToRGB(LDialog.Color));
      Assert.IsFalse(seBorder in LDialog.StyleElements);
      Assert.IsFalse(seClient in LDialog.StyleElements);
      Assert.IsTrue(LDialog.CustomTitleBar.Enabled);
      Assert.IsFalse(LDialog.CustomTitleBar.SystemColors);
      Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.BackgroundColor),
        ColorToRGB(LDialog.CustomTitleBar.BackgroundColor));
      var LEdit := LDialog.FindComponent('ExtensionEdit') as TEdit;
      Assert.IsNotNull(LEdit);
      Assert.AreEqual<Cardinal>(ColorToRGB(BlendColor(LTheme.BackgroundColor,
        LTheme.TextColor, 0.08)), ColorToRGB(LEdit.Color));
      Assert.IsTrue(LEdit.StyleElements = []);
      Assert.AreEqual(Ord(bsNone), Ord(LEdit.BorderStyle));
      var LOkButton := LDialog.FindComponent('OkButton') as TSimpleUIButton;
      Assert.IsNotNull(LOkButton);
      Assert.AreEqual(mrOk, LOkButton.ModalResult);
      var LCancelButton := LDialog.FindComponent('CancelButton') as TSimpleUIButton;
      Assert.IsNotNull(LCancelButton);
      Assert.AreEqual(mrCancel, LCancelButton.ModalResult);
      Assert.AreEqual(32, LEdit.MaxLength);
      var LCaptureFolder := GetEnvironmentVariable('DDS_TEST_CAPTURE_DIR');
      if LCaptureFolder <> '' then
      begin
        LDialog.Show;
        LDialog.Update;
        Application.ProcessMessages;
        Assert.IsTrue(CaptureWindowScreenshot(LDialog.Handle,
          TPath.Combine(LCaptureFolder, 'extension-dialog.png')));
        LDialog.Hide;
      end;
    finally
      LDialog.Free;
    end;
  finally
    ClearDevShellThemeOverride;
  end;
end;

procedure TDialogTests.ChecksumDialogUsesTheSharedPalette;
begin
  SetDevShellThemeOverride(dstDark);
  try
    var LDialog := TFrmCheckSum.Create(nil);
    try
      var LTheme := TDevShellTheme.ActiveTheme;
      Assert.AreEqual<Cardinal>(ColorToRGB(LTheme.BackgroundColor),
        ColorToRGB(LDialog.Color));
      Assert.IsFalse(seBorder in LDialog.StyleElements);
      Assert.IsFalse(seClient in LDialog.StyleElements);
      Assert.IsTrue(LDialog.CustomTitleBar.Enabled);
      Assert.IsFalse(LDialog.CustomTitleBar.SystemColors);
      Assert.IsTrue(LDialog.EditFileName.ReadOnly);
      Assert.IsTrue(LDialog.EditCheckSum.ReadOnly);
      Assert.IsFalse(LDialog.EditCheckSum.WordWrap);
      Assert.IsTrue(LDialog.EditFileName.StyleElements = []);
      Assert.IsTrue(LDialog.EditCheckSum.StyleElements = []);
      Assert.AreEqual(Ord(bsNone), Ord(LDialog.EditFileName.BorderStyle));
      Assert.AreEqual(Ord(bsNone), Ord(LDialog.EditCheckSum.BorderStyle));
      Assert.AreEqual('Upper case', LDialog.RbUpCase.Caption);
      Assert.AreEqual('Lower case', LDialog.RbLowCase.Caption);
      Assert.AreEqual<Cardinal>(ColorToRGB(BlendColor(LTheme.BackgroundColor,
        LTheme.TextColor, 0.08)), ColorToRGB(LDialog.EditCheckSum.Color));
      var LFileName := TPath.Combine(TPath.GetTempPath,
        TPath.GetRandomFileName);
      TFile.WriteAllText(LFileName, 'abc', TEncoding.ASCII);
      try
        LDialog.FileName := LFileName;
        LDialog.CheckSumAlgo := 'CRC32';
        LDialog.FormShow(nil);
        Assert.AreEqual('CRC32 checksum', LDialog.Caption);
        Assert.AreEqual('CRC32 digest', LDialog.Label1.Caption);
        Assert.AreEqual('352441C2', LDialog.EditCheckSum.Text);
        var LCaptureFolder := GetEnvironmentVariable('DDS_TEST_CAPTURE_DIR');
        if LCaptureFolder <> '' then
        begin
          LDialog.Show;
          LDialog.Update;
          Application.ProcessMessages;
          Assert.IsTrue(CaptureWindowScreenshot(LDialog.Handle,
            TPath.Combine(LCaptureFolder, 'checksum-dialog.png')));
          LDialog.Hide;
        end;
      finally
        TFile.Delete(LFileName);
      end;
    finally
      LDialog.Free;
    end;
  finally
    ClearDevShellThemeOverride;
  end;
end;

end.
