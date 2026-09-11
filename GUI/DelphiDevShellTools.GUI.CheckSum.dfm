object FrmCheckSum: TFrmCheckSum
  Left = 0
  Top = 0
  ActiveControl = Button1
  BorderStyle = bsNone
  Caption = 'Checksum'
  ClientHeight = 298
  ClientWidth = 560
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
  TextHeight = 13
  object Label1: TLabel
    Left = 20
    Top = 146
    Width = 34
    Height = 15
    Caption = 'Digest'
  end
  object Label2: TLabel
    Left = 20
    Top = 52
    Width = 52
    Height = 15
    Caption = 'File name'
  end
  object ShapeFileNameInput: TShape
    Left = 20
    Top = 76
    Width = 520
    Height = 28
    Shape = stRoundRect
  end
  object EditFileName: TEdit
    Left = 22
    Top = 81
    Width = 516
    Height = 18
    AutoSize = False
    BorderStyle = bsNone
    ReadOnly = True
    TabOrder = 0
    OnEnter = InputFocusChanged
    OnExit = InputFocusChanged
  end
  object Button1: TSimpleUIButton
    Left = 432
    Top = 248
    Width = 108
    Height = 30
    Caption = 'Close'
    TabOrder = 4
    OnClick = Button1Click
  end
  object ShapeChecksumInput: TShape
    Left = 20
    Top = 170
    Width = 520
    Height = 60
    Shape = stRoundRect
  end
  object EditCheckSum: TMemo
    Left = 22
    Top = 172
    Width = 516
    Height = 56
    BorderStyle = bsNone
    ReadOnly = True
    ScrollBars = ssHorizontal
    TabOrder = 3
    WordWrap = False
    OnEnter = InputFocusChanged
    OnExit = InputFocusChanged
  end
  object RbUpCase: TSimpleUIButton
    Left = 20
    Top = 112
    Width = 106
    Height = 28
    Caption = 'Upper case'
    TabOrder = 1
    OnClick = RbUpCaseClick
  end
  object RbLowCase: TSimpleUIButton
    Left = 136
    Top = 112
    Width = 106
    Height = 28
    Caption = 'Lower case'
    TabOrder = 2
    OnClick = RbLowCaseClick
  end
  object TitleBarPanel: TTitleBarPanel
    Left = 0
    Top = 0
    Width = 560
    Height = 34
    CustomButtons = <>
  end
end
