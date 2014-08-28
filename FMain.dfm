object Main: TMain
  Left = 0
  Top = 0
  Caption = 'Google OAuth2 authentication for IMAP sample'
  ClientHeight = 289
  ClientWidth = 554
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 13
  object lbMailboxes: TListBox
    Left = 8
    Top = 16
    Width = 217
    Height = 233
    ItemHeight = 13
    TabOrder = 0
  end
  object btnListMailboxes: TButton
    Left = 8
    Top = 255
    Width = 217
    Height = 25
    Caption = 'List Mailboxes'
    TabOrder = 1
    OnClick = btnListMailboxesClick
  end
  object edClientID: TLabeledEdit
    Left = 231
    Top = 32
    Width = 250
    Height = 21
    EditLabel.Width = 42
    EditLabel.Height = 13
    EditLabel.Caption = 'ClientID:'
    TabOrder = 2
  end
  object edClientSecret: TLabeledEdit
    Left = 231
    Top = 72
    Width = 250
    Height = 21
    EditLabel.Width = 62
    EditLabel.Height = 13
    EditLabel.Caption = 'ClientSecret:'
    TabOrder = 3
  end
  object edEmail: TLabeledEdit
    Left = 231
    Top = 112
    Width = 250
    Height = 21
    EditLabel.Width = 28
    EditLabel.Height = 13
    EditLabel.Caption = 'Email:'
    TabOrder = 4
  end
  object chkUseSSL: TCheckBox
    Left = 231
    Top = 139
    Width = 97
    Height = 17
    Caption = 'Use SSL'
    Checked = True
    State = cbChecked
    TabOrder = 5
  end
  object btnResetAuth: TButton
    Left = 406
    Top = 139
    Width = 75
    Height = 25
    Caption = 'Reset auth'
    TabOrder = 6
    OnClick = btnResetAuthClick
  end
  object imap: TIdIMAP4
    SASLMechanisms = <>
    MilliSecsToWaitToClearBuffer = 10
    Left = 32
    Top = 40
  end
  object sslio: TIdSSLIOHandlerSocketOpenSSL
    Destination = ':143'
    MaxLineAction = maException
    Port = 143
    DefaultPort = 0
    SSLOptions.Mode = sslmClient
    SSLOptions.VerifyMode = []
    SSLOptions.VerifyDepth = 0
    OnVerifyPeer = sslioVerifyPeer
    Left = 96
    Top = 40
  end
end
