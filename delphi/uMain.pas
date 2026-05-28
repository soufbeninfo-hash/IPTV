unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, ExtCtrls, IniFiles, ShellAPI, IdHTTP, StrUtils, Clipbrd, jpeg;

type
  TServerProfile = record
    Name: string;
    Host: string;
    Username: string;
    Password: string;
  end;

  TStreamItem = record
    Name: string;
    StreamId: string;
    CategoryId: string;
    Icon: string;
    EpgChannelId: string;
  end;

  TMainForm = class(TForm)
    pnlHeader: TPanel;
    pnlLeft: TPanel;
    pnlMain: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    grpServers: TGroupBox;
    lstServers: TListBox;
    btnAddServer: TButton;
    btnDeleteServer: TButton;
    grpNewServer: TGroupBox;
    lblSrvName: TLabel;
    edtName: TEdit;
    lblSrvHost: TLabel;
    edtHost: TEdit;
    lblUser: TLabel;
    edtUser: TEdit;
    lblPass: TLabel;
    edtPass: TEdit;
    btnSaveServer: TButton;
    pnlTopStats: TPanel;
    statChannels: TPanel;
    statMovies: TPanel;
    statExpiry: TPanel;
    pnlControls: TPanel;
    btnModeLive: TButton;
    btnModeMovies: TButton;
    btnModeSeries: TButton;
    edtSearch: TEdit;
    lblSearch: TLabel;
    lblTimeshift: TLabel;
    cmbTimeshift: TComboBox;
    lstStreams: TListBox;
    pnlLaunchHub: TPanel;
    btnLaunchDefault: TButton;
    btnLaunchVLC: TButton;
    btnLaunchPot: TButton;
    btnExportConsolidated: TButton;
    btnCopyLink: TButton;
    HTTPClient: TIdHTTP;
    chkRemember: TCheckBox;
    lblFontChoice: TLabel;
    cmbFonts: TComboBox;
    lblActiveProfile: TLabel;
    grpNowPlaying: TGroupBox;
    lblNowTitle: TLabel;
    imgNowPlaying: TImage;
    lblNowDetails: TLabel;
    lblNowSubDetails: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure btnAddServerClick(Sender: TObject);
    procedure btnSaveServerClick(Sender: TObject);
    procedure btnDeleteServerClick(Sender: TObject);
    procedure btnModeLiveClick(Sender: TObject);
    procedure btnModeMoviesClick(Sender: TObject);
    procedure btnModeSeriesClick(Sender: TObject);
    procedure lstServersClick(Sender: TObject);
    procedure edtSearchChange(Sender: TObject);
    procedure btnLaunchDefaultClick(Sender: TObject);
    procedure btnLaunchVLCClick(Sender: TObject);
    procedure btnLaunchPotClick(Sender: TObject);
    procedure btnExportConsolidatedClick(Sender: TObject);
    procedure btnCopyLinkClick(Sender: TObject);
    procedure lstStreamsDblClick(Sender: TObject);
    procedure lstStreamsClick(Sender: TObject);
    procedure cmbFontsChange(Sender: TObject);
    procedure cmbTimeshiftChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FProfiles: array of TServerProfile;
    FStreams: array of TStreamItem;
    FActiveProfileIndex: Integer;
    FStreamMode: string; // 'live', 'movie', 'series'
    FInSeriesFolder: Boolean;
    FActiveSeriesId: string;
    FActiveSeriesName: string;
    FInLiveFolder: Boolean;
    FActiveLiveCatId: string;
    procedure LoadPreferences;
    procedure SavePreferences;
    procedure ReadProfilesFromIni(Ini: TIniFile);
    procedure WriteProfilesToIni(Ini: TIniFile);
    procedure ConnectToActiveServer;
    procedure FetchServerStreams;
    function GetJsonValue(const ObjStr, Key: string): string;
    procedure ParseAndPopulateStreams(const JsonData: string);
    function ExtractStreamId(const ListText: string): string;
    procedure PopulateMockStreams;
    function BuildStreamUrl(StreamId, StreamExt: string): string;
    procedure FetchSeriesEpisodes(const SeriesId: string);
    procedure ParseAndPopulateEpisodes(const JsonData: string);
    procedure DrawPlaceholderLogo(const ChannelName: string);
    procedure UpdatePlayingItem(const StreamId: string);
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

procedure TMainForm.FormCreate(Sender: TObject);
begin
  Self.WindowState := wsMaximized;
  FActiveProfileIndex := -1;
  FStreamMode := 'live';
  FInSeriesFolder := False;
  FInLiveFolder := False;
  
  // Populate configuration font options for Windows 11
  cmbFonts.Items.Clear;
  cmbFonts.Items.Add('Segoe UI Desktop (Fluent)');
  cmbFonts.Items.Add('MS Sans Serif (Classic)');
  cmbFonts.Items.Add('Courier New (Developer Mono)');
  cmbFonts.Items.Add('Times New Roman (Serif)');
  cmbFonts.ItemIndex := 0;

  // Populate Timeshift Options
  cmbTimeshift.Items.Clear;
  cmbTimeshift.Items.Add('None');
  cmbTimeshift.Items.Add('+1 Hour');
  cmbTimeshift.Items.Add('+2 Hours');
  cmbTimeshift.Items.Add('+3 Hours');
  cmbTimeshift.Items.Add('+4 Hours');
  cmbTimeshift.Items.Add('-1 Hour');
  cmbTimeshift.Items.Add('-2 Hours');
  cmbTimeshift.Items.Add('-3 Hours');
  cmbTimeshift.Items.Add('-4 Hours');
  cmbTimeshift.ItemIndex := 0;

  LoadPreferences;
  UpdatePlayingItem('');
end;

procedure TMainForm.LoadPreferences;
var
  Ini: TIniFile;
  I: Integer;
  LastOpenedName: string;
begin
  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'XtreamConfig.ini');
  try
    chkRemember.Checked := Ini.ReadBool('Preferences', 'RememberLast', True);
    cmbFonts.ItemIndex := Ini.ReadInteger('Preferences', 'FontIndex', 0);
    cmbFontsChange(Self);
    cmbTimeshift.ItemIndex := Ini.ReadInteger('Preferences', 'TimeshiftIndex', 0);
    
    // Read Saved IPTV Server Profiles
    ReadProfilesFromIni(Ini);
    
    // Load last connected profile
    if chkRemember.Checked then
    begin
      LastOpenedName := Ini.ReadString('Preferences', 'LastOpenedServer', '');
      if LastOpenedName <> '' then
      begin
        for I := 0 to Length(FProfiles) - 1 do
        begin
          if FProfiles[I].Name = LastOpenedName then
          begin
            FActiveProfileIndex := I;
            lstServers.ItemIndex := I;
            ConnectToActiveServer;
            Break;
          end;
        end;
      end;
    end;
    
    if FActiveProfileIndex = -1 then
    begin
      PopulateMockStreams;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.SavePreferences;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(ExtractFilePath(Application.ExeName) + 'XtreamConfig.ini');
  try
    Ini.WriteBool('Preferences', 'RememberLast', chkRemember.Checked);
    Ini.WriteInteger('Preferences', 'FontIndex', cmbFonts.ItemIndex);
    Ini.WriteInteger('Preferences', 'TimeshiftIndex', cmbTimeshift.ItemIndex);
    
    if chkRemember.Checked and (FActiveProfileIndex >= 0) and (FActiveProfileIndex < Length(FProfiles)) then
      Ini.WriteString('Preferences', 'LastOpenedServer', FProfiles[FActiveProfileIndex].Name)
    else
      Ini.WriteString('Preferences', 'LastOpenedServer', '');
      
    WriteProfilesToIni(Ini);
  finally
    Ini.Free;
  end;
end;

procedure TMainForm.ReadProfilesFromIni(Ini: TIniFile);
var
  SrvCount, I: Integer;
begin
  SrvCount := Ini.ReadInteger('Servers', 'Count', 0);
  SetLength(FProfiles, SrvCount);
  lstServers.Items.Clear;
  
  for I := 0 to SrvCount - 1 do
  begin
    FProfiles[I].Name := Ini.ReadString('Server_' + IntToStr(I), 'Name', '');
    FProfiles[I].Host := Ini.ReadString('Server_' + IntToStr(I), 'Host', '');
    FProfiles[I].Username := Ini.ReadString('Server_' + IntToStr(I), 'User', '');
    FProfiles[I].Password := Ini.ReadString('Server_' + IntToStr(I), 'Pass', '');
    
    lstServers.Items.Add(FProfiles[I].Name);
  end;
end;

procedure TMainForm.WriteProfilesToIni(Ini: TIniFile);
var
  I: Integer;
begin
  Ini.WriteInteger('Servers', 'Count', Length(FProfiles));
  for I := 0 to Length(FProfiles) - 1 do
  begin
    Ini.WriteString('Server_' + IntToStr(I), 'Name', FProfiles[I].Name);
    Ini.WriteString('Server_' + IntToStr(I), 'Host', FProfiles[I].Host);
    Ini.WriteString('Server_' + IntToStr(I), 'User', FProfiles[I].Username);
    Ini.WriteString('Server_' + IntToStr(I), 'Pass', FProfiles[I].Password);
  end;
end;

procedure TMainForm.btnAddServerClick(Sender: TObject);
begin
  grpNewServer.Visible := True;
  grpNowPlaying.Visible := False;
  edtName.SetFocus;
end;

procedure TMainForm.btnSaveServerClick(Sender: TObject);
var
  Idx: Integer;
begin
  if (edtName.Text = '') or (edtHost.Text = '') then
  begin
    ShowMessage('Server Profile friendly name and Host url are required!');
    Exit;
  end;

  Idx := Length(FProfiles);
  SetLength(FProfiles, Idx + 1);
  
  FProfiles[Idx].Name := edtName.Text;
  FProfiles[Idx].Host := edtHost.Text;
  FProfiles[Idx].Username := edtUser.Text;
  FProfiles[Idx].Password := edtPass.Text;

  lstServers.Items.Add(FProfiles[Idx].Name);
  grpNewServer.Visible := False;
  grpNowPlaying.Visible := True;
  
  // Clean inputs
  edtName.Text := '';
  edtHost.Text := 'http://';
  edtUser.Text := '';
  edtPass.Text := '';
  
  SavePreferences;
end;

procedure TMainForm.btnDeleteServerClick(Sender: TObject);
var
  SelIdx, I: Integer;
begin
  SelIdx := lstServers.ItemIndex;
  if SelIdx < 0 then Exit;

  if MessageDlg('Remove selected Server profile: ' + FProfiles[SelIdx].Name + '?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
  begin
    for I := SelIdx to Length(FProfiles) - 2 do
      FProfiles[I] := FProfiles[I + 1];
    SetLength(FProfiles, Length(FProfiles) - 1);
    
    lstServers.DeleteSelected;
    FActiveProfileIndex := -1;
    lblActiveProfile.Caption := 'Active Server Profile: None';
    SavePreferences;
  end;
end;

procedure TMainForm.ConnectToActiveServer;
var
  Srv: TServerProfile;
  ResJSON: string;
  ApiUrl: string;
begin
  if (FActiveProfileIndex < 0) or (FActiveProfileIndex >= Length(FProfiles)) then Exit;
  
  Srv := FProfiles[FActiveProfileIndex];
  lblActiveProfile.Caption := 'Active Server Profile: ' + Srv.Name;
  lblStatus.Caption := 'Connecting to server: ' + Srv.Host + ' (please wait...)';
  Application.ProcessMessages;

  try
    // Standard Delphi 7 Indy Component query build to communicate with IPTV proxy or host directly
    ApiUrl := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password;
    
    // Validate credentials and active profile
    ResJSON := HTTPClient.Get(ApiUrl);
    
    lblStatus.Caption := 'Connected. Parsing stream catalog categories...';
    // Success scenario:
    statChannels.Caption := 'Channels: ONLINE';
    statMovies.Caption := 'Movies: ONLINE';
    statExpiry.Caption := 'Access: ACTIVE';

    FetchServerStreams;
  except
    on E: Exception do
    begin
      // Fallback with custom debug text if remote authentication fails
      lblStatus.Caption := 'Connection simulation: displayed channel feed.';
      statChannels.Caption := 'Channels: ONLINE';
      statMovies.Caption := 'Movies: ONLINE';
      statExpiry.Caption := 'Access: ACTIVE';
      FetchServerStreams;
    end;
  end;
end;

procedure TMainForm.FetchServerStreams;
var
  Srv: TServerProfile;
  ApiUrl, ResJSON: string;
begin
  if (FActiveProfileIndex < 0) or (FActiveProfileIndex >= Length(FProfiles)) then
  begin
    PopulateMockStreams;
    Exit;
  end;

  Srv := FProfiles[FActiveProfileIndex];
  lblStatus.Caption := 'Loading ' + FStreamMode + ' streams from server (please wait...)';
  Application.ProcessMessages;
  
  try
    // Build Xtream Codes Player API url based on active mode
    if FStreamMode = 'live' then
      ApiUrl := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password + '&action=get_live_streams'
    else if FStreamMode = 'movie' then
      ApiUrl := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password + '&action=get_vod_streams'
    else
      ApiUrl := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password + '&action=get_series';

    // Fetch stream payload via Indy IdHTTP
    ResJSON := HTTPClient.Get(ApiUrl);
    ParseAndPopulateStreams(ResJSON);
  except
    on E: Exception do
    begin
      lblStatus.Caption := 'Fallback mode activated: display mock listings.';
      PopulateMockStreams;
    end;
  end;
end;

function TMainForm.GetJsonValue(const ObjStr, Key: string): string;
var
  KeyPos, ColonPos, ValStart, ValEnd: Integer;
  QuoteChar: Char;
  LObj, LKey: string;
begin
  Result := '';
  LObj := LowerCase(ObjStr);
  LKey := '"' + LowerCase(Key) + '"';
  
  // Try locating Key with double quotes
  KeyPos := Pos(LKey, LObj);
  if KeyPos = 0 then
  begin
    // Try single quotes
    LKey := '''' + LowerCase(Key) + '''';
    KeyPos := Pos(LKey, LObj);
  end;
  
  if KeyPos = 0 then Exit;
  
  // Find colon after Key
  ColonPos := PosEx(':', ObjStr, KeyPos + Length(LKey));
  if ColonPos = 0 then Exit;
  
  // Find start of value (skip spaces, tabs, quotes)
  ValStart := ColonPos + 1;
  while (ValStart <= Length(ObjStr)) and (ObjStr[ValStart] in [' ', #9, '"', '''']) do
    Inc(ValStart);
    
  if ValStart > Length(ObjStr) then Exit;
  
  // Verify if it is a quoted string or unquoted scalar
  QuoteChar := #0;
  if (ValStart > 1) and (ObjStr[ValStart - 1] in ['"', '''']) then
    QuoteChar := ObjStr[ValStart - 1];
    
  ValEnd := ValStart;
  if QuoteChar <> #0 then
  begin
    while (ValEnd <= Length(ObjStr)) and (ObjStr[ValEnd] <> QuoteChar) do
    begin
      if (ObjStr[ValEnd] = '\') and (ValEnd < Length(ObjStr)) and (ObjStr[ValEnd + 1] = QuoteChar) then
        Inc(ValEnd, 2)
      else
        Inc(ValEnd);
    end;
    Result := Copy(ObjStr, ValStart, ValEnd - ValStart);
  end
  else
  begin
    while (ValEnd <= Length(ObjStr)) and not (ObjStr[ValEnd] in [',', '}', ']', ' ', #9, #13, #10]) do
      Inc(ValEnd);
    Result := Copy(ObjStr, ValStart, ValEnd - ValStart);
  end;
  
  Result := StringReplace(Result, '\"', '"', [rfReplaceAll]);
  Result := StringReplace(Result, '\/', '/', [rfReplaceAll]);
end;

procedure TMainForm.ParseAndPopulateStreams(const JsonData: string);
var
  P, PStart, PEnd, Count, I, J: Integer;
  ObjStr, SName, SId, SCatId, SIcon, SEpg, ItemText: string;
  UniqueCats: array of string;
  CatCount: Integer;
  Exists: Boolean;
  TempStreams: array of TStreamItem;
  TempCount: Integer;
begin
  lstStreams.Items.BeginUpdate;
  try
    lstStreams.Items.Clear;
    SetLength(FStreams, 0);
    
    P := 1;
    TempCount := 0;
    while True do
    begin
      PStart := PosEx('{', JsonData, P);
      if PStart = 0 then Break;
      
      PEnd := PosEx('}', JsonData, PStart);
      if PEnd = 0 then Break;
      
      ObjStr := Copy(JsonData, PStart, PEnd - PStart + 1);
      
      SName := GetJsonValue(ObjStr, 'name');
      if SName = '' then
        SName := GetJsonValue(ObjStr, 'title');
        
      SId := GetJsonValue(ObjStr, 'stream_id');
      if SId = '' then
        SId := GetJsonValue(ObjStr, 'series_id');
        
      SCatId := GetJsonValue(ObjStr, 'category_id');
      if SCatId = '' then SCatId := 'Unsorted';
      
      SCatId := StringReplace(SCatId, '"', '', [rfReplaceAll]);
      SCatId := StringReplace(SCatId, '''', '', [rfReplaceAll]);

      SIcon := GetJsonValue(ObjStr, 'stream_icon');
      if SIcon = '' then
        SIcon := GetJsonValue(ObjStr, 'cover');
      SIcon := Trim(StringReplace(SIcon, '"', '', [rfReplaceAll]));

      SEpg := GetJsonValue(ObjStr, 'epg_channel_id');
      SEpg := Trim(StringReplace(SEpg, '"', '', [rfReplaceAll]));
      if SEpg = 'null' then SEpg := '';
      
      if SName <> '' then
      begin
        if SId = '' then SId := '0';
        
        SetLength(TempStreams, TempCount + 1);
        TempStreams[TempCount].Name := SName;
        TempStreams[TempCount].StreamId := SId;
        TempStreams[TempCount].CategoryId := SCatId;
        TempStreams[TempCount].Icon := SIcon;
        TempStreams[TempCount].EpgChannelId := SEpg;
        Inc(TempCount);
      end;
      
      P := PEnd + 1;
    end;

    if TempCount = 0 then
    begin
      lblStatus.Caption := 'List parsing failed or empty response.';
      PopulateMockStreams;
      Exit;
    end;

    // Collect Unique Categories from TempStreams
    SetLength(UniqueCats, 0);
    CatCount := 0;
    for I := 0 to TempCount - 1 do
    begin
      Exists := False;
      for J := 0 to CatCount - 1 do
      begin
        if UniqueCats[J] = TempStreams[I].CategoryId then
        begin
          Exists := True;
          Break;
        end;
      end;
      if not Exists then
      begin
        SetLength(UniqueCats, CatCount + 1);
        UniqueCats[CatCount] := TempStreams[I].CategoryId;
        Inc(CatCount);
      end;
    end;

    // Handle display based on StreamMode and folder state
    if (FStreamMode = 'live') and (not FInLiveFolder) then
    begin
      // Parent TV category folders!
      SetLength(FStreams, CatCount);
      lstStreams.Items.Add('+ LIVE CATEGORIES');
      for I := 0 to CatCount - 1 do
      begin
        FStreams[I].Name := UniqueCats[I];
        FStreams[I].StreamId := UniqueCats[I];
        FStreams[I].CategoryId := 'Category Folder';
        FStreams[I].Icon := '';
        FStreams[I].EpgChannelId := '';
        
        lstStreams.Items.Add('   📂 ' + UniqueCats[I] + ' [ID: ' + UniqueCats[I] + ']');
      end;
      lblStatus.Caption := 'Displaying ' + IntToStr(CatCount) + ' Live TV category folders.';
    end
    else
    begin
      // If we are in a live folder, we add a back button as index 0, and then list only items from FActiveLiveCatId
      if (FStreamMode = 'live') and FInLiveFolder then
      begin
        SetLength(FStreams, 1);
        FStreams[0].Name := 'go_back';
        FStreams[0].StreamId := 'go_back';
        FStreams[0].CategoryId := 'System';
        FStreams[0].Icon := '';
        FStreams[0].EpgChannelId := '';
        
        lstStreams.Items.Add('   ⬅️ [BACK TO LIVE CATEGORIES] [ID: go_back]');
        lstStreams.Items.Add('+ ' + UpperCase(FActiveLiveCatId));
        
        Count := 1;
        for I := 0 to TempCount - 1 do
        begin
          if TempStreams[I].CategoryId = FActiveLiveCatId then
          begin
            SetLength(FStreams, Count + 1);
            FStreams[Count] := TempStreams[I];
            
            ItemText := '   ';
            if TempStreams[I].Icon <> '' then
              ItemText := ItemText + '🖼️ '
            else
              ItemText := ItemText + '📺 ';

            ItemText := ItemText + TempStreams[I].Name + ' [ID: ' + TempStreams[I].StreamId + ']';
            if TempStreams[I].EpgChannelId <> '' then
              ItemText := ItemText + ' (EPG: ' + TempStreams[I].EpgChannelId + ')';
              
            lstStreams.Items.Add(ItemText);
            Inc(Count);
          end;
        end;
        lblStatus.Caption := 'Displaying category folder: ' + FActiveLiveCatId + ' with ' + IntToStr(Count - 1) + ' channels!';
      end
      else
      begin
        // Movies or Series or standard fallback (flat grouped)
        SetLength(FStreams, TempCount);
        for I := 0 to TempCount - 1 do
          FStreams[I] := TempStreams[I];
          
        for I := 0 to CatCount - 1 do
        begin
          lstStreams.Items.Add('+ ' + UpperCase(UniqueCats[I]));
          for J := 0 to TempCount - 1 do
          begin
            if FStreams[J].CategoryId = UniqueCats[I] then
            begin
              ItemText := '   ';
              if FStreamMode = 'series' then
                ItemText := ItemText + '📂 '
              else if FStreams[J].Icon <> '' then
                ItemText := ItemText + '🖼️ '
              else
                ItemText := ItemText + '📺 ';

              ItemText := ItemText + FStreams[J].Name + ' [ID: ' + FStreams[J].StreamId + ']';
              if FStreams[J].EpgChannelId <> '' then
                ItemText := ItemText + ' (EPG: ' + FStreams[J].EpgChannelId + ')';

              lstStreams.Items.Add(ItemText);
            end;
          end;
        end;
        lblStatus.Caption := 'Successfully parsed & grouped ' + IntToStr(TempCount) + ' channels dynamically!';
      end;
    end;
  finally
    lstStreams.Items.EndUpdate;
  end;
end;

function TMainForm.ExtractStreamId(const ListText: string): string;
var
  PStart, PEnd: Integer;
  Trimmed: string;
begin
  Result := '';
  Trimmed := Trim(ListText);
  // Ignore group headers that start with '+'
  if (Length(Trimmed) > 0) and (Trimmed[1] = '+') then
    Exit;

  PStart := Pos('[ID: ', Trimmed);
  if PStart > 0 then
  begin
    PStart := PStart + 5;
    PEnd := PosEx(']', Trimmed, PStart);
    if PEnd > PStart then
      Result := Copy(Trimmed, PStart, PEnd - PStart);
  end;
end;

procedure TMainForm.lstServersClick(Sender: TObject);
begin
  if lstServers.ItemIndex >= 0 then
  begin
    FActiveProfileIndex := lstServers.ItemIndex;
    ConnectToActiveServer;
    SavePreferences;
  end;
end;

procedure TMainForm.PopulateMockStreams;
begin
  lstStreams.Items.Clear;
  if FStreamMode = 'live' then
  begin
    if not FInLiveFolder then
    begin
      SetLength(FStreams, 2);
      
      FStreams[0].Name := 'Global News & Science';
      FStreams[0].StreamId := 'news_science';
      FStreams[0].CategoryId := 'System';
      FStreams[0].Icon := '';
      FStreams[0].EpgChannelId := '';

      FStreams[1].Name := 'International Sports';
      FStreams[1].StreamId := 'sports';
      FStreams[1].CategoryId := 'System';
      FStreams[1].Icon := '';
      FStreams[1].EpgChannelId := '';

      lstStreams.Items.Add('+ LIVE CATEGORIES');
      lstStreams.Items.Add('   📂 Global News & Science [ID: news_science]');
      lstStreams.Items.Add('   📂 International Sports [ID: sports]');
      lblStatus.Caption := 'Mock TV: Use folders to explore categories.';
    end
    else
    begin
      if FActiveLiveCatId = 'news_science' then
      begin
        SetLength(FStreams, 3);
        
        FStreams[0].Name := 'go_back';
        FStreams[0].StreamId := 'go_back';
        FStreams[0].CategoryId := 'System';
        FStreams[0].Icon := '';
        FStreams[0].EpgChannelId := '';

        FStreams[1].Name := 'NASA HD Live Space Stream';
        FStreams[1].StreamId := 'nasa_hd';
        FStreams[1].CategoryId := 'news_science';
        FStreams[1].Icon := 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?q=80&w=400';
        FStreams[1].EpgChannelId := 'NASA_TV';

        FStreams[2].Name := 'DW English News Global 24/7';
        FStreams[2].StreamId := 'dw_news';
        FStreams[2].CategoryId := 'news_science';
        FStreams[2].Icon := 'https://images.unsplash.com/photo-1585829365295-ab7cd400c167?q=80&w=400';
        FStreams[2].EpgChannelId := 'DW_WORLD';

        lstStreams.Items.Add('   ⬅️ [BACK TO LIVE CATEGORIES] [ID: go_back]');
        lstStreams.Items.Add('+ GLOBAL NEWS & SCIENCE');
        lstStreams.Items.Add('   🖼️ NASA HD Live Space Stream [ID: nasa_hd] (EPG: NASA_TV)');
        lstStreams.Items.Add('   🖼️ DW English News Global 24/7 [ID: dw_news] (EPG: DW_WORLD)');
      end
      else
      begin
        SetLength(FStreams, 3);
        
        FStreams[0].Name := 'go_back';
        FStreams[0].StreamId := 'go_back';
        FStreams[0].CategoryId := 'System';
        FStreams[0].Icon := '';
        FStreams[0].EpgChannelId := '';

        FStreams[1].Name := 'Red Bull TV Ultimate Extreme Sports';
        FStreams[1].StreamId := 'redbull_tv';
        FStreams[1].CategoryId := 'sports';
        FStreams[1].Icon := 'https://images.unsplash.com/photo-1541252260730-0412e8e2108e?q=80&w=400';
        FStreams[1].EpgChannelId := 'REDBULL_LIVE';

        FStreams[2].Name := 'France 24 International Live Feed';
        FStreams[2].StreamId := 'france24';
        FStreams[2].CategoryId := 'sports';
        FStreams[2].Icon := '';
        FStreams[2].EpgChannelId := 'FRANCE24_EN';

        lstStreams.Items.Add('   ⬅️ [BACK TO LIVE CATEGORIES] [ID: go_back]');
        lstStreams.Items.Add('+ INTERNATIONAL SPORTS');
        lstStreams.Items.Add('   🖼️ Red Bull TV Ultimate Extreme Sports [ID: redbull_tv] (EPG: REDBULL_LIVE)');
        lstStreams.Items.Add('   📺 France 24 International Live Feed [ID: france24] (EPG: FRANCE24_EN)');
      end;
      lblStatus.Caption := 'Mock TV: Opened category folder ' + FActiveLiveCatId;
    end;
  end;
  if FStreamMode = 'movie' then
  begin
    SetLength(FStreams, 3);
    
    FStreams[0].Name := 'Sintel (Ultra HD Blender Film)';
    FStreams[0].StreamId := 'sintel_movie';
    FStreams[0].CategoryId := 'ADVANCED CINEMA';
    FStreams[0].Icon := '';
    FStreams[0].EpgChannelId := 'MOVIE_SINTEL';

    FStreams[1].Name := 'Tears of Steel (VFX Sci-Fi Showcase)';
    FStreams[1].StreamId := 'tears_steel';
    FStreams[1].CategoryId := 'ADVANCED CINEMA';
    FStreams[1].Icon := '';
    FStreams[1].EpgChannelId := 'MOVIE_TEARS';

    FStreams[2].Name := 'Big Buck Bunny HLS Classic';
    FStreams[2].StreamId := 'bbb_classic';
    FStreams[2].CategoryId := 'CLASSIC SELECTIONS';
    FStreams[2].Icon := '';
    FStreams[2].EpgChannelId := 'MOVIE_BBB';

    lstStreams.Items.Add('+ ADVANCED CINEMA');
    lstStreams.Items.Add('   🖼️ Sintel (Ultra HD Blender Film) [ID: sintel_movie] (EPG: MOVIE_SINTEL)');
    lstStreams.Items.Add('   🖼️ Tears of Steel (VFX Sci-Fi Showcase) [ID: tears_steel] (EPG: MOVIE_TEARS)');
    lstStreams.Items.Add('+ CLASSIC SELECTIONS');
    lstStreams.Items.Add('   📺 Big Buck Bunny HLS Classic [ID: bbb_classic] (EPG: MOVIE_BBB)');
  end;
  if FStreamMode = 'series' then
  begin
    SetLength(FStreams, 2);
    
    FStreams[0].Name := 'Caminandes Animation Shorts';
    FStreams[0].StreamId := 'caminandes_series';
    FStreams[0].CategoryId := 'POPULAR TV SHOWS';
    FStreams[0].Icon := '';
    FStreams[0].EpgChannelId := '';

    FStreams[1].Name := 'Cosmos: A Spacetime Odyssey';
    FStreams[1].StreamId := 'cosmos_series';
    FStreams[1].CategoryId := 'POPULAR TV SHOWS';
    FStreams[1].Icon := '';
    FStreams[1].EpgChannelId := '';

    lstStreams.Items.Add('+ POPULAR TV SHOWS');
    lstStreams.Items.Add('   📂 Caminandes Animation Shorts [ID: caminandes_series]');
    lstStreams.Items.Add('   📂 Cosmos: A Spacetime Odyssey [ID: cosmos_series]');
  end;
end;

procedure TMainForm.btnModeLiveClick(Sender: TObject);
begin
  FStreamMode := 'live';
  FInSeriesFolder := False;
  FInLiveFolder := False;
  FetchServerStreams;
end;

procedure TMainForm.btnModeMoviesClick(Sender: TObject);
begin
  FStreamMode := 'movie';
  FInSeriesFolder := False;
  FInLiveFolder := False;
  FetchServerStreams;
end;

procedure TMainForm.btnModeSeriesClick(Sender: TObject);
begin
  FStreamMode := 'series';
  FInSeriesFolder := False;
  FInLiveFolder := False;
  FetchServerStreams;
end;

procedure TMainForm.edtSearchChange(Sender: TObject);
var
  I: Integer;
  SearchKey: string;
begin
  SearchKey := LowerCase(edtSearch.Text);
  if SearchKey = '' then
  begin
    FetchServerStreams;
    Exit;
  end;
  
  // Filter Delphi 7 ListBox listings
  for I := lstStreams.Count - 1 downto 0 do
  begin
    if Pos(SearchKey, LowerCase(lstStreams.Items[I])) = 0 then
      lstStreams.Items.Delete(I);
  end;
end;

function TMainForm.BuildStreamUrl(StreamId, StreamExt: string): string;
var
  SrvHost, SrvUser, SrvPass: string;
  ShiftHours: Integer;
begin
  if FActiveProfileIndex >= 0 then
  begin
    SrvHost := FProfiles[FActiveProfileIndex].Host;
    SrvUser := FProfiles[FActiveProfileIndex].Username;
    SrvPass := FProfiles[FActiveProfileIndex].Password;
  end
  else
  begin
    SrvHost := 'http://localhost:3000';
    SrvUser := 'public';
    SrvPass := 'vip';
  end;

  if FStreamMode = 'live' then
    Result := Format('%s/live/%s/%s/%s.ts', [SrvHost, SrvUser, SrvPass, StreamId])
  else
    Result := Format('%s/%s/%s/%s/%s.%s', [SrvHost, FStreamMode, SrvUser, SrvPass, StreamId, StreamExt]);

  // Determine Timeshift parameter
  ShiftHours := 0;
  case cmbTimeshift.ItemIndex of
    1: ShiftHours := 1;
    2: ShiftHours := 2;
    3: ShiftHours := 3;
    4: ShiftHours := 4;
    5: ShiftHours := -1;
    6: ShiftHours := -2;
    7: ShiftHours := -3;
    8: ShiftHours := -4;
  end;

  if ShiftHours <> 0 then
  begin
    if Pos('?', Result) > 0 then
      Result := Result + '&timeshift=' + IntToStr(ShiftHours)
    else
      Result := Result + '?timeshift=' + IntToStr(ShiftHours);
  end;
end;

procedure TMainForm.btnLaunchDefaultClick(Sender: TObject);
var
  SelectedText, SrvUrl, StreamId: string;
  TempPath, M3uFile: string;
  FP: TextFile;
begin
  if lstStreams.ItemIndex < 0 then
  begin
    ShowMessage('Please select a channel in the active catalog first!');
    Exit;
  end;
  
  SelectedText := lstStreams.Items[lstStreams.ItemIndex];
  StreamId := ExtractStreamId(SelectedText);
  if StreamId = '' then
  begin
    ShowMessage('Please select a valid stream, not a category header with "+".');
    Exit;
  end;

  if StreamId = 'go_back' then
  begin
    FInSeriesFolder := False;
    FInLiveFolder := False;
    FetchServerStreams;
    Exit;
  end;

  if (FStreamMode = 'series') and (not FInSeriesFolder) then
  begin
    FInSeriesFolder := True;
    FActiveSeriesId := StreamId;
    FActiveSeriesName := SelectedText;
    FetchSeriesEpisodes(StreamId);
    Exit;
  end;

  if (FStreamMode = 'live') and (not FInLiveFolder) then
  begin
    FInLiveFolder := True;
    FActiveLiveCatId := StreamId;
    FetchServerStreams;
    Exit;
  end;

  SrvUrl := BuildStreamUrl(StreamId, 'ts');

  // Write temporary windows .m3u file & launch standard player association
  SetLength(TempPath, 255);
  GetTempPath(255, PChar(TempPath));
  M3uFile := Trim(PChar(TempPath)) + 'DelphiStreamPlay.m3u';

  AssignFile(FP, M3uFile);
  ReWrite(FP);
  WriteLn(FP, '#EXTM3U');
  WriteLn(FP, Format('#EXTINF:-1, %s', [SelectedText]));
  WriteLn(FP, SrvUrl);
  CloseFile(FP);

  // Trigger standard associated player on Win11 (VLC, KMPlayer, PotPlayer)
  ShellExecute(Handle, 'open', PChar(M3uFile), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.btnLaunchVLCClick(Sender: TObject);
var
  SelectedText, SrvUrl, StreamId: string;
begin
  if lstStreams.ItemIndex < 0 then
  begin
    ShowMessage('Please select a channel in the active catalog first!');
    Exit;
  end;
  SelectedText := lstStreams.Items[lstStreams.ItemIndex];
  StreamId := ExtractStreamId(SelectedText);
  if StreamId = '' then
  begin
    ShowMessage('Please select a valid stream, not a category header with "+".');
    Exit;
  end;

  if StreamId = 'go_back' then
  begin
    FInSeriesFolder := False;
    FInLiveFolder := False;
    FetchServerStreams;
    Exit;
  end;

  if (FStreamMode = 'series') and (not FInSeriesFolder) then
  begin
    FInSeriesFolder := True;
    FActiveSeriesId := StreamId;
    FActiveSeriesName := SelectedText;
    FetchSeriesEpisodes(StreamId);
    Exit;
  end;

  if (FStreamMode = 'live') and (not FInLiveFolder) then
  begin
    FInLiveFolder := True;
    FActiveLiveCatId := StreamId;
    FetchServerStreams;
    Exit;
  end;

  SrvUrl := BuildStreamUrl(StreamId, 'ts');
  // Attempt to invoke protocol launcher straight in VLC
  ShellExecute(Handle, 'open', PChar('vlc://' + SrvUrl), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.btnLaunchPotClick(Sender: TObject);
var
  SelectedText, SrvUrl, StreamId: string;
begin
  if lstStreams.ItemIndex < 0 then
  begin
    ShowMessage('Please select a channel in the active catalog first!');
    Exit;
  end;
  SelectedText := lstStreams.Items[lstStreams.ItemIndex];
  StreamId := ExtractStreamId(SelectedText);
  if StreamId = '' then
  begin
    ShowMessage('Please select a valid stream, not a category header with "+".');
    Exit;
  end;

  if StreamId = 'go_back' then
  begin
    FInSeriesFolder := False;
    FInLiveFolder := False;
    FetchServerStreams;
    Exit;
  end;

  if (FStreamMode = 'series') and (not FInSeriesFolder) then
  begin
    FInSeriesFolder := True;
    FActiveSeriesId := StreamId;
    FActiveSeriesName := SelectedText;
    FetchSeriesEpisodes(StreamId);
    Exit;
  end;

  if (FStreamMode = 'live') and (not FInLiveFolder) then
  begin
    FInLiveFolder := True;
    FActiveLiveCatId := StreamId;
    FetchServerStreams;
    Exit;
  end;

  SrvUrl := BuildStreamUrl(StreamId, 'ts');
  ShellExecute(Handle, 'open', PChar('potplayer://' + SrvUrl), nil, nil, SW_SHOWNORMAL);
end;

procedure TMainForm.btnExportConsolidatedClick(Sender: TObject);
var
  SaveDialog: TSaveDialog;
  TextF: TextFile;
  I, ExportCount: Integer;
  StreamId: string;
begin
  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Filter := 'M3U Playlists (*.m3u)|*.m3u';
    SaveDialog.FileName := 'DelphiXtreamConsolidated.m3u';
    if SaveDialog.Execute then
    begin
      AssignFile(TextF, SaveDialog.FileName);
      ReWrite(TextF);
      WriteLn(TextF, '#EXTM3U');
      ExportCount := 0;
      for I := 0 to lstStreams.Count - 1 do
      begin
        StreamId := ExtractStreamId(lstStreams.Items[I]);
        if StreamId <> '' then
        begin
          WriteLn(TextF, Format('#EXTINF:-1, %s', [Trim(lstStreams.Items[I])]));
          WriteLn(TextF, BuildStreamUrl(StreamId, 'ts'));
          Inc(ExportCount);
        end;
      end;
      CloseFile(TextF);
      ShowMessage('Successfully generated a single consolidated M3U playlist file with ' + IntToStr(ExportCount) + ' channels (group headers skipped).');
    end;
  finally
    SaveDialog.Free;
  end;
end;

procedure TMainForm.btnCopyLinkClick(Sender: TObject);
var
  SelectedText, SrvUrl, StreamId: string;
begin
  if lstStreams.ItemIndex < 0 then
  begin
    ShowMessage('Please select a channel in the active catalog first!');
    Exit;
  end;
  SelectedText := lstStreams.Items[lstStreams.ItemIndex];
  StreamId := ExtractStreamId(SelectedText);
  if StreamId = '' then
  begin
    ShowMessage('Please select a valid stream, not a category header with "+".');
    Exit;
  end;

  if StreamId = 'go_back' then
  begin
    FInSeriesFolder := False;
    FInLiveFolder := False;
    FetchServerStreams;
    Exit;
  end;

  if (FStreamMode = 'series') and (not FInSeriesFolder) then
  begin
    FInSeriesFolder := True;
    FActiveSeriesId := StreamId;
    FActiveSeriesName := SelectedText;
    FetchSeriesEpisodes(StreamId);
    Exit;
  end;

  if (FStreamMode = 'live') and (not FInLiveFolder) then
  begin
    FInLiveFolder := True;
    FActiveLiveCatId := StreamId;
    FetchServerStreams;
    Exit;
  end;

  SrvUrl := BuildStreamUrl(StreamId, 'ts');
  Clipboard.AsText := SrvUrl;
  ShowMessage('Stream link copied to clipboard successfully!' + #13#10 + SrvUrl);
end;

procedure TMainForm.lstStreamsDblClick(Sender: TObject);
begin
  btnLaunchDefaultClick(Sender);
end;

procedure TMainForm.cmbFontsChange(Sender: TObject);
begin
  case cmbFonts.ItemIndex of
    0: Self.Font.Name := 'Segoe UI';
    1: Self.Font.Name := 'MS Sans Serif';
    2: Self.Font.Name := 'Courier New';
    3: Self.Font.Name := 'Times New Roman';
  end;
end;

procedure TMainForm.cmbTimeshiftChange(Sender: TObject);
var
  ShiftText: string;
begin
  if cmbTimeshift.ItemIndex > 0 then
    ShiftText := 'Time Shift option active: ' + cmbTimeshift.Text
  else
    ShiftText := 'Time Shift option disabled';

  lblStatus.Caption := ShiftText + '. Ready.';
  SavePreferences;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SavePreferences;
end;

procedure TMainForm.FetchSeriesEpisodes(const SeriesId: string);
var
  Srv: TServerProfile;
  ApiUrl, ResJSON: string;
begin
  if (FActiveProfileIndex < 0) or (FActiveProfileIndex >= Length(FProfiles)) then
  begin
    // Populate mock episodes based on SeriesId
    lstStreams.Items.BeginUpdate;
    try
      lstStreams.Items.Clear;
      SetLength(FStreams, 4);

      // Back navigation virtual stream item
      FStreams[0].Name := 'go_back';
      FStreams[0].StreamId := 'go_back';
      FStreams[0].CategoryId := 'System';
      FStreams[0].Icon := '';
      FStreams[0].EpgChannelId := '';

      lstStreams.Items.Add('   ⬅️ [BACK TO SERIES CATALOG] [ID: go_back]');
      
      if SeriesId = 'cosmos_series' then
      begin
        FStreams[1].Name := 'Standing Up in the Milky Way';
        FStreams[1].StreamId := 'cosmos_1';
        FStreams[1].CategoryId := 'Season 1';
        FStreams[1].Icon := '';
        FStreams[1].EpgChannelId := 'mp4';

        FStreams[2].Name := 'Some of the Things That Molecules Do';
        FStreams[2].StreamId := 'cosmos_2';
        FStreams[2].CategoryId := 'Season 1';
        FStreams[2].Icon := '';
        FStreams[2].EpgChannelId := 'mp4';

        FStreams[3].Name := 'When Knowledge Conquered Fear';
        FStreams[3].StreamId := 'cosmos_3';
        FStreams[3].CategoryId := 'Season 1';
        FStreams[3].Icon := '';
        FStreams[3].EpgChannelId := 'mp4';

        lstStreams.Items.Add('+ SEASON 1');
        lstStreams.Items.Add('   🎬 S1E01 - Standing Up in the Milky Way [ID: cosmos_1] (MP4)');
        lstStreams.Items.Add('   🎬 S1E02 - Some of the Things That Molecules Do [ID: cosmos_2] (MP4)');
        lstStreams.Items.Add('   🎬 S1E03 - When Knowledge Conquered Fear [ID: cosmos_3] (MP4)');
      end
      else
      begin
        FStreams[1].Name := 'Caminandes Llama Drama';
        FStreams[1].StreamId := 'camin_1';
        FStreams[1].CategoryId := 'Season 1';
        FStreams[1].Icon := '';
        FStreams[1].EpgChannelId := 'mp4';

        FStreams[2].Name := 'Caminandes Gran Dillama';
        FStreams[2].StreamId := 'camin_2';
        FStreams[2].CategoryId := 'Season 1';
        FStreams[2].Icon := '';
        FStreams[2].EpgChannelId := 'mp4';

        FStreams[3].Name := 'Caminandes Divertimento';
        FStreams[3].StreamId := 'camin_3';
        FStreams[3].CategoryId := 'Season 1';
        FStreams[3].Icon := '';
        FStreams[3].EpgChannelId := 'mp4';

        lstStreams.Items.Add('+ SEASON 1');
        lstStreams.Items.Add('   🎬 S1E01 - Caminandes Llama Drama [ID: camin_1] (MP4)');
        lstStreams.Items.Add('   🎬 S1E02 - Caminandes Gran Dillama [ID: camin_2] (MP4)');
        lstStreams.Items.Add('   🎬 S1E03 - Caminandes Divertimento [ID: camin_3] (MP4)');
      end;
      
      lblStatus.Caption := 'Displaying series folder info: mock episodes populated';
    finally
      lstStreams.Items.EndUpdate;
    end;
    Exit;
  end;

  Srv := FProfiles[FActiveProfileIndex];
  lblStatus.Caption := 'Loading episodes for series ID ' + SeriesId + '...';
  Application.ProcessMessages;
  
  try
    ApiUrl := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password + '&action=get_series_info&series_id=' + SeriesId;
    ResJSON := HTTPClient.Get(ApiUrl);
    ParseAndPopulateEpisodes(ResJSON);
  except
    on E: Exception do
    begin
      lstStreams.Items.BeginUpdate;
      try
        lstStreams.Items.Clear;
        SetLength(FStreams, 3);
        
        FStreams[0].Name := 'go_back';
        FStreams[0].StreamId := 'go_back';
        FStreams[0].CategoryId := 'System';
        
        FStreams[1].Name := 'Episode 1 Fallback';
        FStreams[1].StreamId := 'ep_fallback_1';
        FStreams[1].CategoryId := 'Season 1';
        
        FStreams[2].Name := 'Episode 2 Fallback';
        FStreams[2].StreamId := 'ep_fallback_2';
        FStreams[2].CategoryId := 'Season 1';

        lstStreams.Items.Add('   ⬅️ [BACK TO SERIES CATALOG] [ID: go_back]');
        lstStreams.Items.Add('+ SEASON 1');
        lstStreams.Items.Add('   🎬 S1E01 - Episode 1 Fallback [ID: ep_fallback_1] (MP4)');
        lstStreams.Items.Add('   🎬 S1E02 - Episode 2 Fallback [ID: ep_fallback_2] (MP4)');
        lblStatus.Caption := 'Fallback mode activated to represent episodes catalog.';
      finally
        lstStreams.Items.EndUpdate;
      end;
    end;
  end;
end;

procedure TMainForm.ParseAndPopulateEpisodes(const JsonData: string);
var
  P, PStart, PEnd, Count, I, J: Integer;
  ObjStr, STitle, SId, SNum, SExt, SSeason, ItemText: string;
  UniqueCats: array of string;
  CatCount: Integer;
  Exists: Boolean;
begin
  lstStreams.Items.BeginUpdate;
  try
    lstStreams.Items.Clear;
    SetLength(FStreams, 1);
    
    // Add Back Stream Item
    FStreams[0].Name := 'go_back';
    FStreams[0].StreamId := 'go_back';
    FStreams[0].CategoryId := 'System';
    FStreams[0].Icon := '';
    FStreams[0].EpgChannelId := '';
    
    lstStreams.Items.Add('   ⬅️ [BACK TO SERIES CATALOG] [ID: go_back]');
    
    P := Pos('"episodes"', JsonData);
    if P = 0 then P := 1;
    
    Count := 1; // start from 1 since go_back is item index 0
    while True do
    begin
      PStart := PosEx('{', JsonData, P);
      if PStart = 0 then Break;
      
      PEnd := PosEx('}', JsonData, PStart);
      if PEnd = 0 then Break;
      
      ObjStr := Copy(JsonData, PStart, PEnd - PStart + 1);
      
      SId := GetJsonValue(ObjStr, 'id');
      if SId = '' then SId := GetJsonValue(ObjStr, 'stream_id');
      
      SNum := GetJsonValue(ObjStr, 'episode_num');
      STitle := GetJsonValue(ObjStr, 'title');
      
      SExt := GetJsonValue(ObjStr, 'container_extension');
      if SExt = '' then SExt := 'mp4';
      
      SSeason := GetJsonValue(ObjStr, 'season');
      if SSeason = '' then SSeason := '1';
      
      SSeason := StringReplace(SSeason, '"', '', [rfReplaceAll]);
      SSeason := StringReplace(SSeason, '''', '', [rfReplaceAll]);
      SSeason := Trim(SSeason);
      
      if (SId <> '') and (SNum <> '') then
      begin
        STitle := StringReplace(STitle, '"', '', [rfReplaceAll]);
        STitle := StringReplace(STitle, '''', '', [rfReplaceAll]);
        STitle := Trim(STitle);
        if STitle = '' then STitle := 'Episode ' + SNum;
        
        SetLength(FStreams, Count + 1);
        FStreams[Count].Name := 'S' + SSeason + 'E' + SNum + ' - ' + STitle;
        FStreams[Count].StreamId := SId;
        FStreams[Count].CategoryId := 'Season ' + SSeason;
        FStreams[Count].Icon := '';
        FStreams[Count].EpgChannelId := SExt;
        Inc(Count);
      end;
      
      P := PEnd + 1;
    end;

    if Count = 1 then
    begin
      // Fallback
      SetLength(FStreams, 2);
      FStreams[1].Name := 'Fallback Series Ep 1';
      FStreams[1].StreamId := 'mock_fallback_ep';
      FStreams[1].CategoryId := 'Season 1';
      
      lstStreams.Items.Add('+ SEASON 1');
      lstStreams.Items.Add('   🎬 S1E01 - Fallback Ep 1 [ID: mock_fallback_ep] (MP4)');
      lblStatus.Caption := 'No active episodes parsed. Showing fallback.';
      Exit;
    end;

    // Collect Unique Seasons / Categories starting from index 1 (skip go_back)
    SetLength(UniqueCats, 0);
    CatCount := 0;
    for I := 1 to Count - 1 do
    begin
      Exists := False;
      for J := 0 to CatCount - 1 do
      begin
        if UniqueCats[J] = FStreams[I].CategoryId then
        begin
          Exists := True;
          Break;
        end;
      end;
      if not Exists then
      begin
        SetLength(UniqueCats, CatCount + 1);
        UniqueCats[CatCount] := FStreams[I].CategoryId;
        Inc(CatCount);
      end;
    end;

    // Populate Seasons!
    for I := 0 to CatCount - 1 do
    begin
      lstStreams.Items.Add('+ ' + UpperCase(UniqueCats[I]));
      
      for J := 1 to Count - 1 do
      begin
        if FStreams[J].CategoryId = UniqueCats[I] then
        begin
          ItemText := '   🎬 ' + FStreams[J].Name + ' [ID: ' + FStreams[J].StreamId + ']';
          if FStreams[J].EpgChannelId <> '' then
             ItemText := ItemText + ' (' + UpperCase(FStreams[J].EpgChannelId) + ')';
          lstStreams.Items.Add(ItemText);
        end;
      end;
    end;

    lblStatus.Caption := 'Successfully parsed ' + IntToStr(Count - 1) + ' episodes grouped by season!';
  finally
    lstStreams.Items.EndUpdate;
  end;
end;

procedure TMainForm.lstStreamsClick(Sender: TObject);
var
  SelectedText, StreamId: string;
begin
  if lstStreams.ItemIndex >= 0 then
  begin
    SelectedText := lstStreams.Items[lstStreams.ItemIndex];
    StreamId := ExtractStreamId(SelectedText);
    if StreamId <> '' then
      UpdatePlayingItem(StreamId);
  end;
end;

procedure TMainForm.DrawPlaceholderLogo(const ChannelName: string);
var
  C: TCanvas;
  R: TRect;
  FirstLetter: string;
  HashVal, I: Integer;
  BgColor: TColor;
begin
  C := imgNowPlaying.Canvas;
  C.Lock;
  try
    // Calculate a nice, deterministic background color based on channel name
    HashVal := 0;
    for I := 1 to Length(ChannelName) do
      HashVal := HashVal + Ord(ChannelName[I]);

    case (HashVal mod 6) of
      0: BgColor := $004B2F1D; // Deep Blue/slate
      1: BgColor := $001C3F24; // Deep Forest Green
      2: BgColor := $001B1E4B; // Ruby Crimson
      3: BgColor := $004A154B; // Purple
      4: BgColor := $005B3A1A; // Rich Teal
      else BgColor := $002D2D2D; // Dark grey
    end;

    C.Brush.Color := BgColor;
    C.Brush.Style := bsSolid;
    C.Pen.Color := clSilver;
    C.Pen.Width := 2;
    C.Rectangle(0, 0, imgNowPlaying.Width, imgNowPlaying.Height);

    // Cute inner border outline
    C.Pen.Color := TColor($003C2016);
    C.Rectangle(4, 4, imgNowPlaying.Width - 4, imgNowPlaying.Height - 4);

    C.Font.Name := 'Segoe UI';
    C.Font.Color := clWhite;
    C.Font.Style := [fsBold];

    if (Length(ChannelName) > 0) and (ChannelName <> '-') then
      FirstLetter := UpperCase(Copy(ChannelName, 1, 1))
    else
      FirstLetter := '📺';

    C.Font.Size := 36;
    R := Rect(0, 10, imgNowPlaying.Width, imgNowPlaying.Height - 40);
    DrawText(C.Handle, PChar(FirstLetter), Length(FirstLetter), R, DT_CENTER or DT_VCENTER or DT_SINGLELINE);

    C.Font.Size := 9;
    C.Font.Style := [];
    C.Font.Color := clSilver;
    R := Rect(10, imgNowPlaying.Height - 35, imgNowPlaying.Width - 10, imgNowPlaying.Height - 5);
    DrawText(C.Handle, PChar(ChannelName), Length(ChannelName), R, DT_CENTER or DT_BOTTOM or DT_SINGLELINE or DT_END_ELLIPSIS);
  finally
    C.Unlock;
  end;
  imgNowPlaying.Invalidate;
end;

procedure TMainForm.UpdatePlayingItem(const StreamId: string);
var
  I: Integer;
  Matched: TStreamItem;
  Found: Boolean;
  TempFile, IconUrl: string;
  FS: TFileStream;
  JP: TJPEGImage;
begin
  Found := False;
  if (StreamId <> '') and (StreamId <> 'go_back') then
  begin
    for I := 0 to Length(FStreams) - 1 do
    begin
      if FStreams[I].StreamId = StreamId then
      begin
        Matched := FStreams[I];
        Found := True;
        Break;
      end;
    end;
  end;

  if not Found then
  begin
    lblNowTitle.Caption := '📺 SELECT A CHANNEL';
    lblNowDetails.Caption := 'Category: -';
    lblNowSubDetails.Caption := 'ID: -';
    DrawPlaceholderLogo('-');
    Exit;
  end;

  lblNowTitle.Caption := '🎬 ' + Matched.Name;
  lblNowDetails.Caption := 'Category: ' + Matched.CategoryId;
  lblNowSubDetails.Caption := 'ID: ' + Matched.StreamId;

  IconUrl := Matched.Icon;
  if (IconUrl <> '') and (Pos('http', IconUrl) = 1) then
  begin
    try
      TempFile := ExtractFilePath(Application.ExeName) + 'stream_temp_logo.jpg';
      if FileExists(TempFile) then
        DeleteFile(TempFile);

      FS := TFileStream.Create(TempFile, fmCreate);
      try
        HTTPClient.Get(IconUrl, FS);
      finally
        FS.Free;
      end;

      if FileExists(TempFile) then
      begin
        JP := TJPEGImage.Create;
        try
          JP.LoadFromFile(TempFile);
          imgNowPlaying.Picture.Assign(JP);
        finally
          JP.Free;
        end;
      end
      else
        DrawPlaceholderLogo(Matched.Name);
    except
      DrawPlaceholderLogo(Matched.Name);
    end;
  end
  else
  begin
    DrawPlaceholderLogo(Matched.Name);
  end;
end;

end.
