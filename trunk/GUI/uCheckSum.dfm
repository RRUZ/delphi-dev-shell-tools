object FrmCheckSum: TFrmCheckSum
  Left = 0
  Top = 0
  ActiveControl = Button1
  BorderIcons = [biSystemMenu]
  BorderStyle = bsSingle
  Caption = 'CheckSum'
  ClientHeight = 207
  ClientWidth = 400
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  Position = poScreenCenter
  OnCreate = FormCreate
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 13
  object Label1: TLabel
    Left = 8
    Top = 53
    Width = 27
    Height = 13
    Caption = 'HASH'
  end
  object Label2: TLabel
    Left = 8
    Top = 7
    Width = 43
    Height = 13
    Caption = 'FileName'
  end
  object EditFileName: TEdit
    Left = 8
    Top = 26
    Width = 384
    Height = 21
    Enabled = False
    TabOrder = 0
  end
  object Button1: TButton
    Left = 8
    Top = 168
    Width = 75
    Height = 25
    Caption = 'Close'
    TabOrder = 4
    OnClick = Button1Click
  end
  object EditCheckSum: TMemo
    Left = 8
    Top = 96
    Width = 384
    Height = 57
    TabOrder = 3
  end
  object RbUpCase: TRadioButton
    Left = 8
    Top = 72
    Width = 89
    Height = 17
    Caption = 'Upper Case'
    Checked = True
    TabOrder = 1
    TabStop = True
    OnClick = RbUpCaseClick
  end
  object RbLowCase: TRadioButton
    Left = 112
    Top = 73
    Width = 81
    Height = 17
    Caption = 'Lower Case'
    TabOrder = 2
    OnClick = RbLowCaseClick
  end
end
