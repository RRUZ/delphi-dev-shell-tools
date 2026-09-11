object FrmExtensionDialog: TFrmExtensionDialog
  Left = 0
  Top = 0
  ActiveControl = ExtensionEdit
  BorderStyle = bsNone
  Caption = 'File extension'
  ClientHeight = 168
  ClientWidth = 400
  Color = clBtnFace
  CustomTitleBar.Control = TitleBarPanel
  CustomTitleBar.Enabled = True
  CustomTitleBar.Height = 34
  CustomTitleBar.SystemHeight = False
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 15
  object ExtensionLabel: TLabel
    Left = 18
    Top = 52
    Width = 56
    Height = 15
    Caption = 'Extension'
  end
  object ShapeExtensionInput: TShape
    Left = 18
    Top = 76
    Width = 364
    Height = 28
    Shape = stRoundRect
  end
  object ExtensionEdit: TEdit
    Left = 20
    Top = 81
    Width = 360
    Height = 18
    AutoSize = False
    BorderStyle = bsNone
    MaxLength = 32
    TabOrder = 0
    OnEnter = InputFocusChanged
    OnExit = InputFocusChanged
  end
  object OkButton: TSimpleUIButton
    Left = 180
    Top = 122
    Width = 92
    Height = 30
    Caption = 'OK'
    Default = True
    ModalResult = 1
    TabOrder = 1
  end
  object CancelButton: TSimpleUIButton
    Left = 290
    Top = 122
    Width = 92
    Height = 30
    Cancel = True
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 2
  end
  object TitleBarPanel: TTitleBarPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 34
    CustomButtons = <>
  end
end
