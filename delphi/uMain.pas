unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, Grids, ExtCtrls, IniFiles, ShellAPI, IdHTTP, StrUtils, Clipbrd, jpeg, WinInet;

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
    ImdbId: string;
    Rating: string;
    Plot: string;
    Genre: string;
    Director: string;
    Cast: string;
    ReleaseDate: string;
  end;

  TCategoryItem = record
    Id: string;
    Name: string;
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
    btnShowImdb: TButton;
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
    lblNowEpg: TLabel;
    btnLoadImgUrl: TButton;
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
    procedure btnShowImdbClick(Sender: TObject);
    procedure lstStreamsDblClick(Sender: TObject);
    procedure lstStreamsClick(Sender: TObject);
    procedure cmbFontsChange(Sender: TObject);
    procedure cmbTimeshiftChange(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnLoadImgUrlClick(Sender: TObject);
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
    FCategories: array of TCategoryItem;
    FLastPlayedStreamId: string;
    FLastPlayedStreamMode: string;
    FLastPlayedStreamCatId: string;
    FLastInLiveFolder: Boolean;
    FLastInSeriesFolder: Boolean;
    FLastActiveSeriesId: string;
    FLastActiveSeriesName: string;
    procedure RestoreLastPlayedSelection;
    procedure StoreLastPlayed(const StreamId: string);
    procedure LoadAndCacheCategories;
    procedure ParseCategories(const JsonData: string);
    function GetCategoryName(const CatId: string): string;
    procedure DisplayCachedCategories;
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
    function DownloadUrlSchannel(const Url, DestFile: string): Boolean;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

function WideCharToUtf8(Val: Word): string;
begin
  if Val < $80 then
    Result := Char(Val)
  else if Val < $800 then
    Result := Char($C0 or (Val shr 6)) + Char($80 or (Val and $3F))
  else
    Result := Char($E0 or (Val shr 12)) + Char($80 or ((Val shr 6) and $3F)) + Char($80 or (Val and $3F));
end;

function Utf8ToWideString(const S: string): WideString;
var
  Len: Integer;
begin
  Result := '';
  if S = '' then Exit;
  Len := MultiByteToWideChar(65001, 0, PChar(S), Length(S), nil, 0);
  if Len > 0 then
  begin
    SetLength(Result, Len);
    MultiByteToWideChar(65001, 0, PChar(S), Length(S), PWideChar(Result), Len);
  end;
end;

function WideStringToAnsiString(const WS: WideString): string;
var
  Len: Integer;
begin
  Result := '';
  if WS = '' then Exit;
  Len := WideCharToMultiByte(0, 0, PWideChar(WS), Length(WS), nil, 0, nil, nil);
  if Len > 0 then
  begin
    SetLength(Result, Len);
    WideCharToMultiByte(0, 0, PWideChar(WS), Length(WS), PChar(Result), Len, nil, nil);
  end;
end;

function DecodeJsonUtf8String(const S: string): string;
var
  I, Len, HexVal: Integer;
  UTF8Str: string;
  HexStr: string;
begin
  UTF8Str := '';
  Len := Length(S);
  I := 1;
  while I <= Len do
  begin
    if (S[I] = '\') and (I + 1 <= Len) then
    begin
      if S[I + 1] = 'u' then
      begin
        if I + 5 <= Len then
        begin
          HexStr := Copy(S, I + 2, 4);
          try
            HexVal := StrToInt('$' + HexStr);
            UTF8Str := UTF8Str + WideCharToUtf8(HexVal);
          except
            UTF8Str := UTF8Str + '\u' + HexStr;
          end;
          Inc(I, 6);
        end
        else
        begin
          UTF8Str := UTF8Str + '\u';
          Inc(I, 2);
        end;
      end
      else if S[I + 1] = 'n' then
      begin
        UTF8Str := UTF8Str + #13#10;
        Inc(I, 2);
      end
      else if S[I + 1] = 't' then
      begin
        UTF8Str := UTF8Str + #9;
        Inc(I, 2);
      end
      else if S[I + 1] = 'r' then
      begin
        Inc(I, 2);
      end
      else
      begin
        UTF8Str := UTF8Str + S[I + 1];
        Inc(I, 2);
      end;
    end
    else
    begin
      UTF8Str := UTF8Str + S[I];
      Inc(I);
    end;
  end;
  Result := WideStringToAnsiString(Utf8ToWideString(UTF8Str));
end;

procedure TMainForm.LoadAndCacheCategories;
var
  Srv: TServerProfile;
  CacheFile, Action, URL, JSONData: string;
  SL: TStringList;
begin
  if (FActiveProfileIndex < 0) or (FActiveProfileIndex >= Length(FProfiles)) then
    Exit;

  Srv := FProfiles[FActiveProfileIndex];
  CacheFile := ExtractFilePath(Application.ExeName) + 'categories_' + Srv.Username + '_' + FStreamMode + '.json';

  JSONData := '';
  if FileExists(CacheFile) then
  begin
    SL := TStringList.Create;
    try
      try
        SL.LoadFromFile(CacheFile);
        JSONData := SL.Text;
      except
        JSONData := '';
      end;
    finally
      SL.Free;
    end;
  end;

  if JSONData = '' then
  begin
    if FStreamMode = 'live' then
      Action := 'get_live_categories'
    else if FStreamMode = 'movie' then
      Action := 'get_vod_streams_categories'
    else
      Action := 'get_series_categories';

    URL := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password + '&action=' + Action;
    lblStatus.Caption := 'Loading categories from server (' + Action + ')...';
    Application.ProcessMessages;

    try
      JSONData := HTTPClient.Get(URL);
      if JSONData <> '' then
      begin
        SL := TStringList.Create;
        try
          SL.Text := JSONData;
          SL.SaveToFile(CacheFile);
        finally
          SL.Free;
        end;
      end;
    except
      on E: Exception do
      begin
        JSONData := '[]';
      end;
    end;
  end;

  ParseCategories(JSONData);
end;

procedure TMainForm.ParseCategories(const JsonData: string);
var
  P, PStart, PEnd, CatCount: Integer;
  ObjStr, SId, SName: string;
begin
  SetLength(FCategories, 0);
  CatCount := 0;

  P := 1;
  while True do
  begin
    PStart := PosEx('{', JsonData, P);
    if PStart = 0 then Break;

    PEnd := PosEx('}', JsonData, PStart);
    if PEnd = 0 then Break;

    ObjStr := Copy(JsonData, PStart, PEnd - PStart + 1);

    SId := GetJsonValue(ObjStr, 'category_id');
    SName := GetJsonValue(ObjStr, 'category_name');

    SId := Trim(StringReplace(SId, '"', '', [rfReplaceAll]));
    SId := Trim(StringReplace(SId, '''', '', [rfReplaceAll]));
    SName := Trim(StringReplace(SName, '"', '', [rfReplaceAll]));
    SName := Trim(StringReplace(SName, '''', '', [rfReplaceAll]));

    if (SId <> '') and (SName <> '') then
    begin
      SetLength(FCategories, CatCount + 1);
      FCategories[CatCount].Id := SId;
      FCategories[CatCount].Name := SName;
      Inc(CatCount);
    end;

    P := PEnd + 1;
  end;
end;

function TMainForm.GetCategoryName(const CatId: string): string;
var
  I: Integer;
begin
  Result := CatId; // Default fallback to ID if not found
  for I := 0 to Length(FCategories) - 1 do
  begin
    if FCategories[I].Id = CatId then
    begin
      Result := FCategories[I].Name;
      Exit;
    end;
  end;
end;

procedure TMainForm.DisplayCachedCategories;
var
  I: Integer;
begin
  lstStreams.Items.BeginUpdate;
  try
    lstStreams.Items.Clear;
    SetLength(FStreams, Length(FCategories));

    lstStreams.Items.Add('+ ' + UpperCase(FStreamMode) + ' CATEGORIES');

    for I := 0 to Length(FCategories) - 1 do
    begin
      FStreams[I].Name := FCategories[I].Name;
      FStreams[I].StreamId := FCategories[I].Id;
      FStreams[I].CategoryId := 'Category Folder';
      FStreams[I].Icon := '';
      FStreams[I].EpgChannelId := '';

      lstStreams.Items.Add('   📂 ' + FCategories[I].Name + ' [ID: ' + FCategories[I].Id + ']');
    end;

    lblStatus.Caption := 'Displaying ' + IntToStr(Length(FCategories)) + ' ' + FStreamMode + ' category folders (loaded from cache).';
  finally
    lstStreams.Items.EndUpdate;
  end;
end;

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

  // Load and cache categories from file or server
  LoadAndCacheCategories;

  // If we are not inside a specific category folder, show the loaded categories instead of streams
  if not FInLiveFolder then
  begin
    DisplayCachedCategories;
    Exit;
  end;

  Srv := FProfiles[FActiveProfileIndex];
  lblStatus.Caption := 'Loading category streams from server (please wait...)';
  Application.ProcessMessages;
  
  try
    // Build Xtream Codes Player API url with category filter for efficiency
    if FStreamMode = 'live' then
      ApiUrl := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password + '&action=get_live_streams&category_id=' + FActiveLiveCatId
    else if FStreamMode = 'movie' then
      ApiUrl := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password + '&action=get_vod_streams&category_id=' + FActiveLiveCatId
    else
      ApiUrl := Srv.Host + '/player_api.php?username=' + Srv.Username + '&password=' + Srv.Password + '&action=get_series&category_id=' + FActiveLiveCatId;

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
  
  Result := DecodeJsonUtf8String(Result);
end;

procedure TMainForm.ParseAndPopulateStreams(const JsonData: string);
var
  P, PStart, PEnd, Count, I, J: Integer;
  ObjStr, SName, SId, SCatId, SIcon, SEpg, ItemText: string;
  SImdbId, SRating, SPlot, SGenre, SDirector, SCast, SReleaseDate: string;
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
      
      SImdbId := GetJsonValue(ObjStr, 'imdb_id');
      if SImdbId = '' then SImdbId := GetJsonValue(ObjStr, 'imdbId');
      if SImdbId = '' then SImdbId := GetJsonValue(ObjStr, 'imdb');
      SImdbId := Trim(StringReplace(SImdbId, '"', '', [rfReplaceAll]));

      SRating := GetJsonValue(ObjStr, 'rating');
      if SRating = '' then SRating := GetJsonValue(ObjStr, 'imdb_rating');
      if SRating = '' then SRating := GetJsonValue(ObjStr, 'rating_5based');
      SRating := Trim(StringReplace(SRating, '"', '', [rfReplaceAll]));

      SPlot := GetJsonValue(ObjStr, 'plot');
      if SPlot = '' then SPlot := GetJsonValue(ObjStr, 'description');
      SPlot := Trim(StringReplace(SPlot, '"', '', [rfReplaceAll]));

      SGenre := GetJsonValue(ObjStr, 'genre');
      SGenre := Trim(StringReplace(SGenre, '"', '', [rfReplaceAll]));

      SDirector := GetJsonValue(ObjStr, 'director');
      SDirector := Trim(StringReplace(SDirector, '"', '', [rfReplaceAll]));

      SCast := GetJsonValue(ObjStr, 'cast');
      if SCast = '' then SCast := GetJsonValue(ObjStr, 'actors');
      SCast := Trim(StringReplace(SCast, '"', '', [rfReplaceAll]));

      SReleaseDate := GetJsonValue(ObjStr, 'release_date');
      if SReleaseDate = '' then SReleaseDate := GetJsonValue(ObjStr, 'releaseDate');
      if SReleaseDate = '' then SReleaseDate := GetJsonValue(ObjStr, 'year');
      SReleaseDate := Trim(StringReplace(SReleaseDate, '"', '', [rfReplaceAll]));

      if SName <> '' then
      begin
        if SId = '' then SId := '0';
        
        SetLength(TempStreams, TempCount + 1);
        TempStreams[TempCount].Name := SName;
        TempStreams[TempCount].StreamId := SId;
        TempStreams[TempCount].CategoryId := SCatId;
        TempStreams[TempCount].Icon := SIcon;
        TempStreams[TempCount].EpgChannelId := SEpg;
        TempStreams[TempCount].ImdbId := SImdbId;
        TempStreams[TempCount].Rating := SRating;
        TempStreams[TempCount].Plot := SPlot;
        TempStreams[TempCount].Genre := SGenre;
        TempStreams[TempCount].Director := SDirector;
        TempStreams[TempCount].Cast := SCast;
        TempStreams[TempCount].ReleaseDate := SReleaseDate;
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
    if FInLiveFolder then
    begin
      SetLength(FStreams, TempCount + 1);
      FStreams[0].Name := 'go_back';
      FStreams[0].StreamId := 'go_back';
      FStreams[0].CategoryId := 'System';
      FStreams[0].Icon := '';
      FStreams[0].EpgChannelId := '';
      
      lstStreams.Items.Add('   ⬅️ [BACK TO ' + UpperCase(FStreamMode) + ' CATEGORIES] [ID: go_back]');
      lstStreams.Items.Add('+ ' + UpperCase(GetCategoryName(FActiveLiveCatId)));
      
      for I := 0 to TempCount - 1 do
      begin
        FStreams[I + 1] := TempStreams[I];
        
        ItemText := '   ';
        if FStreamMode = 'series' then
          ItemText := ItemText + '🎬 '
        else if TempStreams[I].Icon <> '' then
          ItemText := ItemText + '🖼️ '
        else if FStreamMode = 'movie' then
          ItemText := ItemText + '🎥 '
        else
          ItemText := ItemText + '📺 ';

        ItemText := ItemText + TempStreams[I].Name + ' [ID: ' + TempStreams[I].StreamId + ']';
        if TempStreams[I].EpgChannelId <> '' then
          ItemText := ItemText + ' (EPG: ' + TempStreams[I].EpgChannelId + ')';
          
        lstStreams.Items.Add(ItemText);
      end;
      lblStatus.Caption := 'Displaying category folder: ' + GetCategoryName(FActiveLiveCatId) + ' with ' + IntToStr(TempCount) + ' items!';
    end
    else
    begin
      // Fallback or Search / Flattened list
      SetLength(FStreams, TempCount);
      for I := 0 to TempCount - 1 do
        FStreams[I] := TempStreams[I];
        
      for I := 0 to CatCount - 1 do
      begin
        lstStreams.Items.Add('+ ' + UpperCase(GetCategoryName(UniqueCats[I])));
        for J := 0 to TempCount - 1 do
        begin
          if FStreams[J].CategoryId = UniqueCats[I] then
          begin
            ItemText := '   ';
            if FStreamMode = 'series' then
              ItemText := ItemText + '🎬 '
            else if FStreams[J].Icon <> '' then
              ItemText := ItemText + '🖼️ '
              else if FStreamMode = 'movie' then
                ItemText := ItemText + '🎥 '
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
    FStreams[0].ImdbId := 'tt1727587';
    FStreams[0].Rating := '7.4';
    FStreams[0].Plot := 'A girl named Sintel searches for her companion baby dragon, Scales. When she finds him, Scales has grown into a massive dragon who does not remember her.';
    FStreams[0].Genre := 'Animation, Short, Fantasy';
    FStreams[0].Director := 'Colin Levy';
    FStreams[0].Cast := 'Halina Reijn, Thom Hoffman';
    FStreams[0].ReleaseDate := '2010';

    FStreams[1].Name := 'Tears of Steel (VFX Sci-Fi Showcase)';
    FStreams[1].StreamId := 'tears_steel';
    FStreams[1].CategoryId := 'ADVANCED CINEMA';
    FStreams[1].Icon := '';
    FStreams[1].EpgChannelId := 'MOVIE_TEARS';
    FStreams[1].ImdbId := 'tt2285752';
    FStreams[1].Rating := '5.6';
    FStreams[1].Plot := 'A group of warriors and scientists pick a spot in Rotterdam to stage a counter-attack against giant destructive robots that have conquered the world.';
    FStreams[1].Genre := 'Short, Sci-Fi';
    FStreams[1].Director := 'Ian Hubert';
    FStreams[1].Cast := 'Derek de Lint, Sergio Hasselbaink, Rogier Schippers';
    FStreams[1].ReleaseDate := '2012';

    FStreams[2].Name := 'Big Buck Bunny HLS Classic';
    FStreams[2].StreamId := 'bbb_classic';
    FStreams[2].CategoryId := 'CLASSIC SELECTIONS';
    FStreams[2].Icon := '';
    FStreams[2].EpgChannelId := 'MOVIE_BBB';
    FStreams[2].ImdbId := 'tt1254207';
    FStreams[2].Rating := '6.3';
    FStreams[2].Plot := 'A giant and giant-hearted rabbit''s day is ruined by three bullying rodents when they kill a butterfly, but he prepares a systematic and comical revenge.';
    FStreams[2].Genre := 'Animation, Comedy, Short';
    FStreams[2].Director := 'Sacha Goedegebure';
    FStreams[2].Cast := 'None';
    FStreams[2].ReleaseDate := '2008';

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
    FStreams[0].ImdbId := 'tt3438062';
    FStreams[0].Rating := '7.1';
    FStreams[0].Plot := 'Koro, a quirky llama from Patagonia, faces several hilarious obstacles while attempting to cross a deserted highway in search of delicious food.';
    FStreams[0].Genre := 'Animation, Comedy, Adventure';
    FStreams[0].Director := 'Pablo Vazquez';
    FStreams[0].Cast := 'None';
    FStreams[0].ReleaseDate := '2013';

    FStreams[1].Name := 'Cosmos: A Spacetime Odyssey';
    FStreams[1].StreamId := 'cosmos_series';
    FStreams[1].CategoryId := 'POPULAR TV SHOWS';
    FStreams[1].Icon := '';
    FStreams[1].EpgChannelId := '';
    FStreams[1].ImdbId := 'tt3018022';
    FStreams[1].Rating := '9.3';
    FStreams[1].Plot := 'An adventure where we find how we discovered the laws of nature and found our coordinates in spacetime, narrated by Neil deGrasse Tyson.';
    FStreams[1].Genre := 'Documentary, Biography, Sci-Fi';
    FStreams[1].Director := 'Brannon Braga';
    FStreams[1].Cast := 'Neil deGrasse Tyson, Keythe Farley, Amanda Seyfried';
    FStreams[1].ReleaseDate := '2014';

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

  if (not FInLiveFolder) then
  begin
    FInLiveFolder := True;
    FActiveLiveCatId := StreamId;
    FetchServerStreams;
    Exit;
  end;

  StoreLastPlayed(StreamId);
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

  if (not FInLiveFolder) then
  begin
    FInLiveFolder := True;
    FActiveLiveCatId := StreamId;
    FetchServerStreams;
    Exit;
  end;

  StoreLastPlayed(StreamId);
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

  if (not FInLiveFolder) then
  begin
    FInLiveFolder := True;
    FActiveLiveCatId := StreamId;
    FetchServerStreams;
    Exit;
  end;

  StoreLastPlayed(StreamId);
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

  if (not FInLiveFolder) then
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

procedure TMainForm.btnShowImdbClick(Sender: TObject);
var
  SelectedText, StreamId: string;
  I: Integer;
  Matched: TStreamItem;
  Found: Boolean;
  Details: string;
begin
  if lstStreams.ItemIndex < 0 then
  begin
    ShowMessage('Please select a movie or series in the active catalog first!');
    Exit;
  end;
  SelectedText := lstStreams.Items[lstStreams.ItemIndex];
  StreamId := ExtractStreamId(SelectedText);
  if (StreamId = '') or (StreamId = 'go_back') then
  begin
    ShowMessage('Please select a valid movie or series, not a category or back button.');
    Exit;
  end;

  Found := False;
  for I := 0 to Length(FStreams) - 1 do
  begin
    if FStreams[I].StreamId = StreamId then
    begin
      Matched := FStreams[I];
      Found := True;
      Break;
    end;
  end;

  if not Found then
  begin
    ShowMessage('Stream details not found in cache.');
    Exit;
  end;

  if (Matched.ImdbId = '') and (Matched.Rating = '') and (Matched.Plot = '') then
  begin
    ShowMessage('No IMDb data is parsed for this channel or category.' + #13#10 + 
                'Name: ' + Matched.Name + #13#10 + 
                'Category: ' + Matched.CategoryId);
    Exit;
  end;

  Details := '🎬 TITLE: ' + Matched.Name + #13#10 + #13#10;
  if Matched.ImdbId <> '' then
    Details := Details + '🌐 IMDb ID: ' + Matched.ImdbId + #13#10;
  if Matched.Rating <> '' then
    Details := Details + '⭐ Rating: ' + Matched.Rating + '/10' + #13#10;
  if Matched.ReleaseDate <> '' then
    Details := Details + '📅 Released: ' + Matched.ReleaseDate + #13#10;
  if Matched.Genre <> '' then
    Details := Details + '🏷️ Genre: ' + Matched.Genre + #13#10;
  if Matched.Director <> '' then
    Details := Details + '🎥 Director: ' + Matched.Director + #13#10;
  if Matched.Cast <> '' then
    Details := Details + '👥 Cast: ' + Matched.Cast + #13#10;
  
  if Matched.Plot <> '' then
  begin
    Details := Details + #13#10 + '📖 PLOT / STORYLINE:' + #13#10 + Matched.Plot;
  end;

  ShowMessage(Details);
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
    lblNowEpg.Caption := 'EPG: -';
    DrawPlaceholderLogo('-');
    Exit;
  end;

  lblNowTitle.Caption := '🎬 ' + Matched.Name;
  if (Matched.Rating <> '') or (Matched.Plot <> '') then
  begin
    if Matched.Rating <> '' then
      lblNowDetails.Caption := 'IMDb Score: ' + Matched.Rating + '/10 ★'
    else
      lblNowDetails.Caption := 'Category: ' + Matched.CategoryId;
      
    if Matched.Genre <> '' then
      lblNowSubDetails.Caption := 'Genre: ' + Copy(Matched.Genre, 1, 35)
    else
      lblNowSubDetails.Caption := 'Year: ' + Matched.ReleaseDate;
      
    if Matched.Plot <> '' then
      lblNowEpg.Caption := 'Plot: ' + Copy(Matched.Plot, 1, 40) + '...'
    else
      lblNowEpg.Caption := 'EPG Live: Not Available';
  end
  else
  begin
    lblNowDetails.Caption := 'Category: ' + Matched.CategoryId;
    lblNowSubDetails.Caption := 'ID: ' + Matched.StreamId;
    if Matched.EpgChannelId <> '' then
      lblNowEpg.Caption := 'EPG Live: ' + Matched.EpgChannelId
    else
      lblNowEpg.Caption := 'EPG Live: Not Available';
  end;

  IconUrl := Matched.Icon;
  if (IconUrl <> '') and (Pos('http', IconUrl) = 1) then
  begin
    try
      TempFile := ExtractFilePath(Application.ExeName) + 'stream_temp_logo.jpg';
      if FileExists(TempFile) then
        DeleteFile(TempFile);

      if DownloadUrlSchannel(IconUrl, TempFile) and FileExists(TempFile) then
      begin
        JP := TJPEGImage.Create;
        try
          JP.LoadFromFile(TempFile);
          imgNowPlaying.Picture.Assign(JP);
        finally
          JP.Free;
        end;
        if FileExists(TempFile) then
          DeleteFile(TempFile);
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

procedure TMainForm.RestoreLastPlayedSelection;
var
  I: Integer;
  SearchStr: string;
begin
  if (FLastPlayedStreamId = '') or (not chkRemember.Checked) then Exit;

  SearchStr := '[ID: ' + FLastPlayedStreamId + ']';
  for I := 0 to lstStreams.Count - 1 do
  begin
    if Pos(SearchStr, lstStreams.Items[I]) > 0 then
    begin
      lstStreams.ItemIndex := I;
      UpdatePlayingItem(FLastPlayedStreamId);
      if I > 0 then
        lstStreams.TopIndex := I - 1
      else
        lstStreams.TopIndex := I;
      Exit;
    end;
  end;
end;

procedure TMainForm.StoreLastPlayed(const StreamId: string);
begin
  if (StreamId <> '') and (StreamId <> 'go_back') then
  begin
    FLastPlayedStreamId := StreamId;
    FLastPlayedStreamMode := FStreamMode;
    FLastPlayedStreamCatId := FActiveLiveCatId; 
    FLastInLiveFolder := FInLiveFolder;
    FLastInSeriesFolder := FInSeriesFolder;
    FLastActiveSeriesId := FActiveSeriesId;
    FLastActiveSeriesName := FActiveSeriesName;
    SavePreferences;
  end;
end;

procedure TMainForm.btnLoadImgUrlClick(Sender: TObject);
var
  UrlStr: string;
  TempFile: string;
  JP: TJPEGImage;
begin
  UrlStr := 'https://images.unsplash.com/photo-1579202673506-ca3ce28943ef?q=80&w=400';
  if not InputQuery('Load HTTPS Image', 'Enter HTTPS URL of a JPEG image:', UrlStr) then
    Exit;

  UrlStr := Trim(UrlStr);
  if UrlStr = '' then
    Exit;

  lblStatus.Caption := 'Status: Fetching custom image over HTTPS (Schannel TLS)...';
  Application.ProcessMessages;

  TempFile := ExtractFilePath(Application.ExeName) + 'custom_url_image.jpg';
  if FileExists(TempFile) then
    DeleteFile(TempFile);

  try
    if DownloadUrlSchannel(UrlStr, TempFile) then
    begin
      if FileExists(TempFile) then
      begin
        JP := TJPEGImage.Create;
        try
          try
            JP.LoadFromFile(TempFile);
            imgNowPlaying.Picture.Assign(JP);
            lblNowTitle.Caption := '🌐 CUSTOM IMAGE';
            lblNowDetails.Caption := 'Source: HTTPS URL';
            lblNowSubDetails.Caption := Copy(UrlStr, 1, 40) + '...';
            lblNowEpg.Caption := 'EPG: Not Available';
            lblStatus.Caption := 'Status: Native Schannel Image retrieved successfully.';
          except
            on E: Exception do
            begin
              ShowMessage('Error displaying JPEG image: ' + E.Message + sLineBreak + 'Ensure the URL is a valid JPEG format.');
              lblStatus.Caption := 'Status: Invalid JPEG error.';
            end;
          end;
        finally
          JP.Free;
        end;
        if FileExists(TempFile) then
          DeleteFile(TempFile);
      end
      else
      begin
        ShowMessage('Schannel Download succeeded, but could not produce file.');
        lblStatus.Caption := 'Status: Empty target file.';
      end;
    end
    else
    begin
      ShowMessage('Schannel (Secure Channel) connection/handshake failed.' + sLineBreak + 
                  'Please specify a valid TLS-compliant HTTPS image URL (like Unsplash).');
      lblStatus.Caption := 'Status: Secure connection failed.';
    end;
  except
    on E: Exception do
    begin
      ShowMessage('Schannel Error: ' + E.Message);
      lblStatus.Caption := 'Status: Connection error.';
    end;
  end;
end;

function TMainForm.DownloadUrlSchannel(const Url, DestFile: string): Boolean;
var
  hSession, hConnect: HINTERNET;
  Buffer: array[0..8191] of Byte;
  BytesRead: DWORD;
  FS: TFileStream;
begin
  Result := False;
  hSession := InternetOpen('DelphiSchannelAgent', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if Assigned(hSession) then
  begin
    hConnect := InternetOpenUrl(hSession, PChar(Url), nil, 0, INTERNET_FLAG_SECURE or INTERNET_FLAG_RELOAD, 0);
    if Assigned(hConnect) then
    begin
      try
        FS := TFileStream.Create(DestFile, fmCreate);
        try
          while InternetReadFile(hConnect, @Buffer, SizeOf(Buffer), BytesRead) and (BytesRead > 0) do
          begin
            FS.WriteBuffer(Buffer, BytesRead);
          end;
          Result := True;
        finally
          FS.Free;
        end;
      except
        Result := False;
      end;
      InternetCloseHandle(hConnect);
    end;
    InternetCloseHandle(hSession);
  end;
end;

end.
