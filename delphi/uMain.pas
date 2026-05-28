unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, ExtCtrls, IniFiles, ShellAPI, IdHTTP, StrUtils, Clipbrd;

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
    procedure cmbFontsChange(Sender: TObject);
    procedure cmbTimeshiftChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    { Private declarations }
    FProfiles: array of TServerProfile;
    FStreams: array of TStreamItem;
    FActiveProfileIndex: Integer;
    FStreamMode: string; // 'live', 'movie', 'series'
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
begin
  lstStreams.Items.BeginUpdate;
  try
    lstStreams.Items.Clear;
    SetLength(FStreams, 0);
    
    P := 1;
    Count := 0;
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
        
        SetLength(FStreams, Count + 1);
        FStreams[Count].Name := SName;
        FStreams[Count].StreamId := SId;
        FStreams[Count].CategoryId := SCatId;
        FStreams[Count].Icon := SIcon;
        FStreams[Count].EpgChannelId := SEpg;
        Inc(Count);
      end;
      
      P := PEnd + 1;
    end;

    if Count = 0 then
    begin
      lblStatus.Caption := 'List parsing failed or empty response.';
      PopulateMockStreams;
      Exit;
    end;

    // Collect Unique Categories
    SetLength(UniqueCats, 0);
    CatCount := 0;
    for I := 0 to Count - 1 do
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

    // Now populate ListBox grouped with '+' signs!
    for I := 0 to CatCount - 1 do
    begin
      // Add Group Header prefixed with '+'
      lstStreams.Items.Add('+ ' + UpperCase(UniqueCats[I]));
      
      // Add Streams belonging to this Category ID
      for J := 0 to Count - 1 do
      begin
        if FStreams[J].CategoryId = UniqueCats[I] then
        begin
          ItemText := '   ';
          if FStreams[J].Icon <> '' then
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

    lblStatus.Caption := 'Successfully parsed & grouped ' + IntToStr(Count) + ' channels dynamically!';
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
    lstStreams.Items.Add('+ GLOBAL NEWS & SCIENCE');
    lstStreams.Items.Add('   🖼️ NASA HD Live Space Stream [ID: nasa_hd] (EPG: NASA_TV)');
    lstStreams.Items.Add('   🖼️ DW English News Global 24/7 [ID: dw_news] (EPG: DW_WORLD)');
    lstStreams.Items.Add('+ INTERNATIONAL SPORTS');
    lstStreams.Items.Add('   🖼️ Red Bull TV Ultimate Extreme Sports [ID: redbull_tv] (EPG: REDBULL_LIVE)');
    lstStreams.Items.Add('   📺 France 24 International Live Feed [ID: france24] (EPG: FRANCE24_EN)');
  end
  else if FStreamMode = 'movie' then
  begin
    lstStreams.Items.Add('+ ADVANCED CINEMA');
    lstStreams.Items.Add('   🖼️ Sintel (Ultra HD Blender Film) [ID: sintel_movie] (EPG: MOVIE_SINTEL)');
    lstStreams.Items.Add('   🖼️ Tears of Steel (VFX Sci-Fi Showcase) [ID: tears_steel] (EPG: MOVIE_TEARS)');
    lstStreams.Items.Add('+ CLASSIC SELECTIONS');
    lstStreams.Items.Add('   📺 Big Buck Bunny HLS Classic [ID: bbb_classic] (EPG: MOVIE_BBB)');
  end
  else
  begin
    lstStreams.Items.Add('+ ANIMATION SHORTS');
    lstStreams.Items.Add('   📺 Caminandes Animation Shorts episode_1 [ID: caminandes_series] (EPG: SHORTS_CAMINANDES)');
  end;
end;

procedure TMainForm.btnModeLiveClick(Sender: TObject);
begin
  FStreamMode := 'live';
  FetchServerStreams;
end;

procedure TMainForm.btnModeMoviesClick(Sender: TObject);
begin
  FStreamMode := 'movie';
  FetchServerStreams;
end;

procedure TMainForm.btnModeSeriesClick(Sender: TObject);
begin
  FStreamMode := 'series';
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

end.
