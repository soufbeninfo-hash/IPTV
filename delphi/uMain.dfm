object MainForm: TMainForm
  Left = 240
  Top = 150
  Width = 980
  Height = 650
  Caption = 'Xtream IPTV Flow - Windows Premium Client (Delphi 7 Edition)'
  Color = ClSlateGray
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Segoe UI'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnClose = FormClose
  PixelsPerInch = 96
  TextHeight = 13
  object pnlHeader: TPanel
    Left = 0
    Top = 0
    Width = 964
    Height = 60
    Align = alTop
    Color = $001B0E09
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 14
      Width = 320
      Height = 25
      Caption = 'Xtream IPTV Flow: Delphi 7 Desktop'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -19
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblStatus: TLabel
      Left = 380
      Top = 22
      Width = 220
      Height = 13
      Caption = 'Status: Portable Windows engine ready'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = $00A5978B
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
    end
    object lblActiveProfile: TLabel
      Left = 700
      Top = 22
      Width = 240
      Height = 13
      Alignment = taRightJustify
      Caption = 'Active Server Profile: None'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSkyBlue
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
  end
  object pnlLeft: TPanel
    Left = 0
    Top = 60
    Width = 280
    Height = 551
    Align = alLeft
    Color = $00170B07
    TabOrder = 1
    object grpServers: TGroupBox
      Left = 8
      Top = 8
      Width = 264
      Height = 220
      Caption = 'Saved Connections'
      Color = $00170B07
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 0
      object lstServers: TListBox
        Left = 10
        Top = 24
        Width = 244
        Height = 150
        Color = $002C1B15
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWhite
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ItemHeight = 13
        ParentFont = False
        TabOrder = 0
        OnClick = lstServersClick
      end
      object btnAddServer: TButton
        Left = 10
        Top = 184
        Width = 115
        Height = 25
        Caption = '+ Add Connection'
        TabOrder = 1
        OnClick = btnAddServerClick
      end
      object btnDeleteServer: TButton
        Left = 139
        Top = 184
        Width = 115
        Height = 25
        Caption = 'Delete Profile'
        TabOrder = 2
        OnClick = btnDeleteServerClick
      end
    end
    object grpNewServer: TGroupBox
      Left = 8
      Top = 240
      Width = 264
      Height = 240
      Caption = 'Add IPTV Connection'
      Color = $00170B07
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 1
      Visible = False
      object lblSrvName: TLabel
        Left = 12
        Top = 22
        Width = 73
        Height = 13
        Caption = 'Friendly Name:'
        Font.Style = []
      end
      object edtName: TEdit
        Left = 12
        Top = 38
        Width = 240
        Height = 21
        Color = $002C1B15
        Font.Style = []
        TabOrder = 0
      end
      object lblSrvHost: TLabel
        Left = 12
        Top = 66
        Width = 83
        Height = 13
        Caption = 'Host / Server URL:'
        Font.Style = []
      end
      object edtHost: TEdit
        Left = 12
        Top = 82
        Width = 240
        Height = 21
        Color = $002C1B15
        Font.Style = []
        TabOrder = 1
        Text = 'http://'
      end
      object lblUser: TLabel
        Left = 12
        Top = 110
        Width = 51
        Height = 13
        Caption = 'Username:'
        Font.Style = []
      end
      object edtUser: TEdit
        Left = 12
        Top = 126
        Width = 240
        Height = 21
        Color = $002C1B15
        Font.Style = []
        TabOrder = 2
      end
      object lblPass: TLabel
        Left = 12
        Top = 154
        Width = 49
        Height = 13
        Caption = 'Password:'
        Font.Style = []
      end
      object edtPass: TEdit
        Left = 12
        Top = 170
        Width = 240
        Height = 21
        Color = $002C1B15
        Font.Style = []
        TabOrder = 3
      end
      object btnSaveServer: TButton
        Left = 12
        Top = 202
        Width = 240
        Height = 25
        Caption = 'Authenticate & Save Profile'
        TabOrder = 4
        OnClick = btnSaveServerClick
      end
    end
    object chkRemember: TCheckBox
      Left = 16
      Top = 495
      Width = 240
      Height = 17
      Caption = 'Remember active profile on launch'
      Checked = True
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clSilver
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = []
      ParentFont = False
      State = cbChecked
      TabOrder = 2
    end
    object lblFontChoice: TLabel
      Left = 16
      Top = 520
      Width = 60
      Height = 13
      Caption = 'VCL Font:'
      Color = clNone
      Font.Height = -10
      Font.Style = [fsBold]
      ParentColor = False
    end
    object cmbFonts: TComboBox
      Left = 85
      Top = 518
      Width = 180
      Height = 21
      Style = csDropDownList
      ItemHeight = 13
      TabOrder = 3
      OnChange = cmbFontsChange
    end
    object grpNowPlaying: TGroupBox
      Left = 8
      Top = 236
      Width = 264
      Height = 295
      Caption = ' Now Playing Stream'
      Color = $00170B07
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -11
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentColor = False
      ParentFont = False
      TabOrder = 4
      object lblNowTitle: TLabel
        Left = 10
        Top = 20
        Width = 244
        Height = 18
        Caption = '📺 SELECT A CHANNEL'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clSkyBlue
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object lblNowDetails: TLabel
        Left = 10
        Top = 192
        Width = 244
        Height = 15
        Caption = 'Category: -'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clSilver
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblNowSubDetails: TLabel
        Left = 10
        Top = 210
        Width = 244
        Height = 15
        Caption = 'ID: -'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clSilver
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = []
        ParentFont = False
      end
      object lblNowEpg: TLabel
        Left = 10
        Top = 228
        Width = 244
        Height = 15
        Caption = 'EPG: -'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clSkyBlue
        Font.Height = -11
        Font.Name = 'Segoe UI'
        Font.Style = [fsItalic]
        ParentFont = False
      end
      object imgNowPlaying: TImage
        Left = 10
        Top = 44
        Width = 244
        Height = 140
        Center = True
        Stretch = True
      end
      object btnLoadImgUrl: TButton
        Left = 10
        Top = 250
        Width = 244
        Height = 32
        Caption = '🌐 Load HTTPS Image...'
        TabOrder = 0
        OnClick = btnLoadImgUrlClick
      end
    end
  end
  object pnlMain: TPanel
    Left = 280
    Top = 60
    Width = 684
    Height = 551
    Align = alClient
    Color = $000D0704
    TabOrder = 2
    object pnlTopStats: TPanel
      Left = 1
      Top = 1
      Width = 682
      Height = 50
      Align = alTop
      Color = $001B0E09
      TabOrder = 0
      object statChannels: TPanel
        Left = 10
        Top = 10
        Width = 150
        Height = 30
        Caption = 'Channels: LOCAL'
        Color = $00170B07
        Font.Color = clSilver
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 0
      end
      object statMovies: TPanel
        Left = 170
        Top = 10
        Width = 150
        Height = 30
        Caption = 'Movies: LOCAL'
        Color = $00170B07
        Font.Color = clSilver
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 1
      end
      object statExpiry: TPanel
        Left = 330
        Top = 10
        Width = 150
        Height = 30
        Caption = 'Access: FREEWARE'
        Color = $00170B07
        Font.Color = clSilver
        Font.Style = [fsBold]
        ParentFont = False
        TabOrder = 2
      end
    end
    object pnlControls: TPanel
      Left = 1
      Top = 51
      Width = 682
      Height = 50
      Align = alTop
      Color = $000D0704
      TabOrder = 1
      object lblSearch: TLabel
        Left = 295
        Top = 18
        Width = 65
        Height = 13
        Caption = 'Search Filter:'
        Font.Color = clSilver
        Font.Style = [fsBold]
      end
      object lblTimeshift: TLabel
        Left = 525
        Top = 18
        Width = 55
        Height = 13
        Caption = 'Time Shift:'
        Font.Color = clSilver
        Font.Style = [fsBold]
      end
      object btnModeLive: TButton
        Left = 10
        Top = 12
        Width = 90
        Height = 25
        Caption = 'LIVE STREAM'
        TabOrder = 0
        OnClick = btnModeLiveClick
      end
      object btnModeMovies: TButton
        Left = 105
        Top = 12
        Width = 90
        Height = 25
        Caption = 'VOD MOVIES'
        TabOrder = 1
        OnClick = btnModeMoviesClick
      end
      object btnModeSeries: TButton
        Left = 200
        Top = 12
        Width = 90
        Height = 25
        Caption = 'TV SERIES'
        TabOrder = 2
        OnClick = btnModeSeriesClick
      end
      object edtSearch: TEdit
        Left = 365
        Top = 14
        Width = 150
        Height = 21
        Color = $00170B07
        Font.Color = clWhite
        TabOrder = 3
        OnChange = edtSearchChange
      end
      object cmbTimeshift: TComboBox
        Left = 585
        Top = 14
        Width = 85
        Height = 21
        Style = csDropDownList
        ItemHeight = 13
        TabOrder = 4
        OnChange = cmbTimeshiftChange
      end
    end
    object lstStreams: TListBox
      Left = 1
      Top = 101
      Width = 682
      Height = 360
      Align = alClient
      Color = $00170B07
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWhite
      Font.Height = -12
      Font.Name = 'Segoe UI'
      Font.Style = []
      ItemHeight = 15
      ParentFont = False
      TabOrder = 2
      OnClick = lstStreamsClick
      OnDblClick = lstStreamsDblClick
    end
    object pnlLaunchHub: TPanel
      Left = 1
      Top = 461
      Width = 682
      Height = 89
      Align = alBottom
      Color = $001B0E09
      TabOrder = 3
      object btnLaunchDefault: TButton
        Left = 10
        Top = 12
        Width = 215
        Height = 30
        Caption = '💾 Instant Play (VLC/Default)'
        Font.Style = [fsBold]
        TabOrder = 0
        OnClick = btnLaunchDefaultClick
      end
      object btnLaunchVLC: TButton
        Left = 232
        Top = 12
        Width = 215
        Height = 30
        Caption = '🍊 Launch in VLC Direct'
        TabOrder = 1
        OnClick = btnLaunchVLCClick
      end
      object btnLaunchPot: TButton
        Left = 455
        Top = 12
        Width = 215
        Height = 30
        Caption = '🚀 Launch in PotPlayer'
        TabOrder = 2
        OnClick = btnLaunchPotClick
      end
      object btnExportConsolidated: TButton
        Left = 10
        Top = 48
        Width = 325
        Height = 30
        Caption = '📁 Export All Listed Channels to M3U'
        Font.Color = clGreen
        Font.Style = [fsBold]
        TabOrder = 3
        OnClick = btnExportConsolidatedClick
      end
      object btnCopyLink: TButton
        Left = 345
        Top = 48
        Width = 325
        Height = 30
        Caption = '🔗 Copy Active Channel Stream Link'
        Font.Style = [fsBold]
        TabOrder = 4
        OnClick = btnCopyLinkClick
      end
    end
  end
  object HTTPClient: TIdHTTP
    MaxLineAction = maException
    ReadTimeout = 5000
    AllowCookies = True
    ProxyParams.ProxyPort = 0
    Request.ContentLength = -1
    Request.ContentRangeEnd = -1
    Request.ContentRangeStart = -1
    Request.ContentType = 'application/x-www-form-urlencoded'
    Request.Accept = 'text/html, */*'
    Request.BasicAuthentication = False
    Request.UserAgent = 'Mozilla/3.0 (compatible; Indy Library)'
    HTTPOptions = [hoForceEncodeParams]
    Left = 700
    Top = 13
  end
end
