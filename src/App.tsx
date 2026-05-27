import React, { useState, useEffect, useMemo } from "react";
import { 
  Monitor, Database, RefreshCcw, Wifi, WifiOff, CheckCircle, 
  HelpCircle, Settings, LogIn, AlertCircle, Play, Film, Tv, 
  Folder, Search, Clock, FileDown, Eye, Check, Sliders, Info, ExternalLink, Moon, Sparkles, AlertTriangle
} from "lucide-react";
import { XtreamServer, UserInfo, ServerInfo, IptvCategory, IptvStream, StreamMode, FONTS_LIST, ACCENTS_LIST } from "./types";
import { TitleBar } from "./components/TitleBar";
import { ServerManager } from "./components/ServerManager";
import { ExternalPlayerGuide } from "./components/ExternalPlayerGuide";

// Fallback high-quality public mock channels when IPTV credentials aren't loaded or connected
const MOCK_CATEGORIES: Record<StreamMode, IptvCategory[]> = {
  live: [
    { category_id: "all", category_name: "All Channels", parent_id: 0 },
    { category_id: "news", category_name: "Global News", parent_id: 0 },
    { category_id: "space", category_name: "Documentary & Space", parent_id: 0 },
    { category_id: "entertainment", category_name: "Entertainment & Music", parent_id: 0 },
  ],
  movie: [
    { category_id: "all", category_name: "All Movies", parent_id: 0 },
    { category_id: "scifi", category_name: "Sci-Fi & Cinema", parent_id: 0 },
    { category_id: "classic", category_name: "Indie Classics", parent_id: 0 }
  ],
  series: [
    { category_id: "all", category_name: "All Shows", parent_id: 0 },
    { category_id: "anime", category_name: "Animation Hub", parent_id: 0 }
  ]
};

const MOCK_STREAMS: Record<StreamMode, IptvStream[]> = {
  live: [
    { 
      num: 1, 
      name: "NASA HD Live Space Stream", 
      stream_id: "nasa_hd", 
      stream_icon: "https://upload.wikimedia.org/wikipedia/commons/e/e5/NASA_logo.svg", 
      category_id: "space" 
    },
    { 
      num: 2, 
      name: "DW English News Global 24/7", 
      stream_id: "dw_news", 
      stream_icon: "https://upload.wikimedia.org/wikipedia/commons/5/5c/Deutsche_Welle_logo.svg", 
      category_id: "news" 
    },
    { 
      num: 3, 
      name: "Red Bull TV Ultimate Extreme Sports", 
      stream_id: "redbull_tv", 
      stream_icon: "https://upload.wikimedia.org/wikipedia/en/2/23/Red_Bull_Media_House_logo.png", 
      category_id: "entertainment" 
    },
    { 
      num: 4, 
      name: "France 24 International Live Feed", 
      stream_id: "france24", 
      stream_icon: "https://upload.wikimedia.org/wikipedia/commons/3/39/France_24_logo.svg", 
      category_id: "news" 
    }
  ],
  movie: [
    {
      num: 1,
      name: "Sintel (Ultra HD Blender Film)",
      stream_id: "sintel_movie",
      stream_icon: "https://durian.blender.org/wp-content/uploads/2010/06/cover_sintel_medium.jpg",
      category_id: "scifi",
      container_extension: "mp4"
    },
    {
      num: 2,
      name: "Tears of Steel (VFX Sci-Fi Showcase)",
      stream_id: "tears_steel",
      stream_icon: "https://mango.blender.org/wp-content/uploads/2012/03/poster_small.jpg",
      category_id: "scifi",
      container_extension: "mkv"
    },
    {
      num: 3,
      name: "Big Buck Bunny HLS Classic",
      stream_id: "bbb_classic",
      stream_icon: "https://peach.blender.org/wp-content/uploads/title_anouncement.jpg",
      category_id: "classic",
      container_extension: "mp4"
    }
  ],
  series: [
    {
      num: 1,
      name: "Caminandes Animation Shorts (Season 1)",
      stream_id: "caminandes_series",
      stream_icon: "https://upload.wikimedia.org/wikipedia/commons/f/f6/Caminandes_Llama_Drama.jpg",
      category_id: "anime",
      releaseDate: "2013",
      plot: "An animated series following Koro the llama as he tries to cross a desolate Patagonian road.",
    }
  ]
};

// Map stream ID directly to public secure sandbox URLs so external players can play them
const getMockStreamUrl = (streamId: string): string => {
  switch (streamId) {
    case "nasa_hd":
      return "https://nasa-i.akamaihd.net/hls/live/253565/NASA-NTV1-Public/master.m3u8";
    case "dw_news":
      return "https://dwstream4-lh.akamaihd.net/i/dwstream4_live@131375/index_1_av-p.m3u8";
    case "redbull_tv":
      return "https://g8-rb-tv-multi-live.redbull.akamaized.net/v1/master/92f8fafe074a3f5509a25b29054778ae994fbf93/rb-tv-live/master.m3u8";
    case "france24":
      return "https://static.france24.com/live/F24_EN_LO_HLS/live_web.m3u8";
    case "sintel_movie":
      return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/Sintel.mp4";
    case "tears_steel":
      return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/TearsOfSteel.mp4";
    case "bbb_classic":
      return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
    case "caminandes_series":
      return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantDream.mp4";
    default:
      return "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4";
  }
};

export default function App() {
  // Saved server list in state
  const [servers, setServers] = useState<XtreamServer[]>(() => {
    try {
      const saved = localStorage.getItem("xtream_servers");
      return saved ? JSON.parse(saved) : [];
    } catch {
      return [];
    }
  });

  // Selected / Connected IPTV server
  const [activeServer, setActiveServer] = useState<XtreamServer | null>(() => {
    try {
      const savedObj = localStorage.getItem("xtream_active_server");
      return savedObj ? JSON.parse(savedObj) : null;
    } catch {
      return null;
    }
  });

  // App customization settings
  const [fontFamily, setFontFamily] = useState<string>(() => {
    return localStorage.getItem("xtream_font") || FONTS_LIST[0].id;
  });

  const [accentColorId, setAccentColorId] = useState<string>(() => {
    return localStorage.getItem("xtream_accent") || "blue";
  });

  const [rememberLastServer, setRememberLastServer] = useState<boolean>(() => {
    const saved = localStorage.getItem("xtream_remember_last");
    return saved !== "false"; // Default to true
  });

  const [isDemoMode, setIsDemoMode] = useState<boolean>(true);

  // States for backend data retrieval
  const [userInfo, setUserInfo] = useState<UserInfo | null>(null);
  const [serverInfo, setServerInfo] = useState<ServerInfo | null>(null);
  
  const [isConnecting, setIsConnecting] = useState(false);
  const [isConnected, setIsConnected] = useState(false);
  const [connectError, setConnectError] = useState<string | null>(null);

  // Browse streams and categories
  const [streamMode, setStreamMode] = useState<StreamMode>("live");
  const [categories, setCategories] = useState<IptvCategory[]>([]);
  const [streams, setStreams] = useState<IptvStream[]>([]);
  const [isLoadingStreams, setIsLoadingStreams] = useState(false);
  const [selectedCategoryId, setSelectedCategoryId] = useState<string>("all");
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedStream, setSelectedStream] = useState<IptvStream | null>(null);

  // Get active accent config
  const activeAccent = useMemo(() => {
    return ACCENTS_LIST.find(a => a.id === accentColorId) || ACCENTS_LIST[0];
  }, [accentColorId]);

  // Update Font / Accent inside local storage
  const handleFontChange = (id: string) => {
    setFontFamily(id);
    localStorage.setItem("xtream_font", id);
  };

  const handleAccentChange = (id: string) => {
    setAccentColorId(id);
    localStorage.setItem("xtream_accent", id);
  };

  const handleRememberToggle = () => {
    const nextVal = !rememberLastServer;
    setRememberLastServer(nextVal);
    localStorage.setItem("xtream_remember_last", String(nextVal));
    if (!nextVal) {
      localStorage.removeItem("xtream_last_opened_id");
    } else if (activeServer) {
      localStorage.setItem("xtream_last_opened_id", activeServer.id);
    }
  };

  // Profile modifications
  const addServer = (newSrv: Omit<XtreamServer, "id">) => {
    const serverWithId: XtreamServer = {
      ...newSrv,
      id: crypto.randomUUID()
    };
    const updated = [...servers, serverWithId];
    setServers(updated);
    localStorage.setItem("xtream_servers", JSON.stringify(updated));

    // Connect automatically to the newly added profile
    connectToServer(serverWithId);
  };

  const deleteServer = (id: string) => {
    const updated = servers.filter(s => s.id !== id);
    setServers(updated);
    localStorage.setItem("xtream_servers", JSON.stringify(updated));

    if (activeServer?.id === id) {
      setActiveServer(null);
      setIsConnected(false);
      localStorage.removeItem("xtream_active_server");
      localStorage.removeItem("xtream_last_opened_id");
    }
  };

  // Perform Connection to selected server profile
  const connectToServer = async (server: XtreamServer) => {
    setIsConnecting(true);
    setConnectError(null);
    setSelectedStream(null);
    setIsConnected(false);

    try {
      // Set local active server indicator
      setActiveServer(server);
      localStorage.setItem("xtream_active_server", JSON.stringify(server));
      
      if (rememberLastServer) {
        localStorage.setItem("xtream_last_opened_id", server.id);
      }

      console.log(`Connecting to server: ${server.name} via Proxy API...`);

      const res = await fetch("/api/iptv/proxy", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          host: server.host,
          username: server.username,
          password: server.password
        })
      });

      if (!res.ok) {
        throw new Error(`Server connection returned status ${res.status}`);
      }

      const rawData = await res.json();
      
      if (rawData && rawData.user_info) {
        if (rawData.user_info.auth === 0) {
          throw new Error("Xtream Authentication Rejected. Check your username & password.");
        }
        
        setUserInfo(rawData.user_info);
        setServerInfo(rawData.server_info || {});
        setIsConnected(true);
        setIsDemoMode(false); // Valid connection succeeds, exit demo fallback mode!
        
        // Success: Load categories for Live
        fetchCategoriesAndStreams(server, "live");
      } else {
        throw new Error("Response is valid but does not resemble a typical Xtream player API structure.");
      }
    } catch (err: any) {
      console.warn("Failed connection to private IPTV server. Falling back to Live Sandbox channels.", err);
      // Give beautiful feedback
      setConnectError(`Could not connect to ${server.name}. Details: ${err.message}. Showing public sandbox fallback streams for preview navigation!`);
      // Re-initialize lists with Fallback mock dataset so system is immediately interactive
      setIsDemoMode(true);
      setIsConnected(true);
      loadMockData("live");
    } finally {
      setIsConnecting(false);
    }
  };

  // Load appropriate local test lists when offline/demo
  const loadMockData = (mode: StreamMode) => {
    setCategories(MOCK_CATEGORIES[mode]);
    setStreams(MOCK_STREAMS[mode]);
    setSelectedCategoryId("all");
  };

  // Fetch lists from real stream APIs or handle simulation
  const fetchCategoriesAndStreams = async (server: XtreamServer, mode: StreamMode) => {
    if (isDemoMode) {
      loadMockData(mode);
      return;
    }

    setIsLoadingStreams(true);
    try {
      let actionCategory = "get_live_categories";
      let actionStreams = "get_live_streams";

      if (mode === "movie") {
        actionCategory = "get_vod_categories";
        actionStreams = "get_vod_streams";
      } else if (mode === "series") {
        actionCategory = "get_series_categories";
        actionStreams = "get_series";
      }

      // Fetch Categories
      const catRes = await fetch("/api/iptv/proxy", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          host: server.host,
          username: server.username,
          password: server.password,
          action: actionCategory
        })
      });

      let loadedCategories: IptvCategory[] = [];
      if (catRes.ok) {
        const rawCats = await catRes.json();
        if (Array.isArray(rawCats)) {
          loadedCategories = rawCats;
        }
      }

      // Prepend 'All' category
      const cleanedCats = [
        { category_id: "all", category_name: "All " + (mode === "live" ? "Channels" : mode === "movie" ? "Movies" : "Shows"), parent_id: 0 },
        ...loadedCategories
      ];
      setCategories(cleanedCats);

      // Fetch Streams
      const streamsRes = await fetch("/api/iptv/proxy", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          host: server.host,
          username: server.username,
          password: server.password,
          action: actionStreams
        })
      });

      if (streamsRes.ok) {
        const rawStreams = await streamsRes.json();
        if (Array.isArray(rawStreams)) {
          setStreams(rawStreams);
        } else {
          setStreams([]);
        }
      }

      setSelectedCategoryId("all");
      setSelectedStream(null);
    } catch (e) {
      console.error("Error fetching playlists:", e);
      // fallback to mock on error
      setIsDemoMode(true);
      loadMockData(mode);
    } finally {
      setIsLoadingStreams(false);
    }
  };

  // Switch between Live, Movies, and Series categories
  const handleModeChange = (mode: StreamMode) => {
    setStreamMode(mode);
    if (activeServer && !isDemoMode) {
      fetchCategoriesAndStreams(activeServer, mode);
    } else {
      loadMockData(mode);
    }
  };

  // Filter streams by search and selected category
  const filteredStreams = useMemo(() => {
    let result = streams;
    if (selectedCategoryId !== "all") {
      result = result.filter(s => String(s.category_id) === String(selectedCategoryId));
    }
    if (searchQuery.trim() !== "") {
      const q = searchQuery.toLowerCase();
      result = result.filter(s => s.name.toLowerCase().includes(q));
    }
    return result;
  }, [streams, selectedCategoryId, searchQuery]);

  // Handle auto-boot on startup to connect to the last opened profile
  useEffect(() => {
    const lastOpenedId = localStorage.getItem("xtream_last_opened_id");
    if (rememberLastServer && lastOpenedId && servers.length > 0) {
      const target = servers.find(s => s.id === lastOpenedId);
      if (target) {
        connectToServer(target);
      } else {
        // Fallback demo setup if no matches
        setIsDemoMode(true);
        loadMockData("live");
      }
    } else {
      // default demo
      setIsDemoMode(true);
      loadMockData("live");
    }
  }, []);

  // Prepare standard launch url object for either private server format or safe proxy mock HLS formats
  const formattedStreamObjectForPlayer = useMemo(() => {
    if (!selectedStream) return null;
    
    if (isDemoMode) {
      // Force stream URL mapping to the safe public mp4/hls URLs
      const targetHost = window.location.origin; // server handles mapping
      return {
        ...selectedStream,
        // Override generated stream id mapping to public urls
        stream_id: selectedStream.stream_id,
        // In the player panel guide, build raw fallback HLS URL for player launch instead of player_api link
        direct_source: getMockStreamUrl(String(selectedStream.stream_id))
      };
    }
    
    return selectedStream;
  }, [selectedStream, isDemoMode]);

  // Find css-font to inject dynamically into upper parent
  const activeFontFamily = useMemo(() => {
    const selected = FONTS_LIST.find(f => f.id === fontFamily);
    return selected ? selected.css : '"Inter", sans-serif';
  }, [fontFamily]);

  return (
    <div 
      className="min-h-screen bg-slate-950 text-slate-200 flex flex-col overflow-hidden select-none"
      style={{ fontFamily: activeFontFamily }}
    >
      {/* Dynamic Native Style Title Bar */}
      <TitleBar 
        activeServer={activeServer}
        isConnected={isConnected}
        isConnecting={isConnecting}
        onRefresh={() => activeServer && connectToServer(activeServer)}
        accentColor={activeAccent.color}
      />

      {/* Main Grid Content Area */}
      <div className="flex-1 flex flex-col md:flex-row h-[calc(100vh-4.5rem)] overflow-hidden">
        
        {/* Left Hand: Profiles, Settings & Customization */}
        <aside className="w-full md:w-80 bg-slate-900 border-r border-slate-800 flex flex-col shrink-0 overflow-y-auto">
          
          {/* Header Action branding */}
          <div className="p-4 border-b border-slate-800 bg-slate-950 flex items-center justify-between">
            <div className="flex items-center space-x-2.5">
              <div 
                className="w-8 h-8 rounded-md flex items-center justify-center text-white" 
                style={{ backgroundColor: activeAccent.color }}
              >
                <Monitor className="w-4.5 h-4.5" />
              </div>
              <div>
                <span className="font-bold tracking-tight text-white block leading-none">NexusStream</span>
                <span className="text-[10px] text-gray-500 uppercase tracking-wider font-mono">Xtream Client</span>
              </div>
            </div>

            <div className="flex items-center gap-1">
              <button 
                onClick={() => {
                  setIsDemoMode(!isDemoMode);
                  loadMockData(streamMode);
                  setSelectedStream(null);
                }}
                className={`text-[9px] uppercase px-2 py-0.5 rounded font-mono font-bold tracking-wider transition-all border ${
                  isDemoMode 
                    ? "bg-amber-600/15 border-amber-500/40 text-amber-400" 
                    : "bg-slate-950 border-slate-800 text-gray-500"
                }`}
                title="Toggles demo database without a real IPTV host address"
              >
                {isDemoMode ? "Live Demo" : "Private Node"}
              </button>
            </div>
          </div>

          <div className="p-4 space-y-4">
            
            {/* Servers Profiles Section */}
            <ServerManager 
              servers={servers}
              activeServer={activeServer}
              onAddServer={addServer}
              onDeleteServer={deleteServer}
              onConnect={connectToServer}
              isConnecting={isConnecting}
              accentColor={activeAccent.color}
            />

            {/* Application Configuration card */}
            <div className="bg-slate-950 border border-slate-850 rounded-lg p-3 space-y-3.5">
              <div className="flex items-center justify-between pb-1 border-b border-slate-900">
                <div className="flex items-center space-x-1.5">
                  <Sliders className="w-3.5 h-3.5 text-zinc-400" />
                  <span className="text-xs font-semibold text-slate-300">Preferences Dashboard</span>
                </div>
                <div className="text-[9px] px-1.5 py-0.5 rounded bg-slate-900 text-slate-400 font-mono">COM</div>
              </div>

              {/* Remember Last Server Switch */}
              <div className="flex items-center justify-between cursor-pointer" onClick={handleRememberToggle}>
                <span className="text-xs text-slate-450">Remember Last Config</span>
                <button 
                  className={`w-9 h-5 rounded-full transition-colors relative flex items-center px-0.5 ${rememberLastServer ? 'bg-emerald-600' : 'bg-slate-800'}`}
                >
                  <span className={`w-4 h-4 rounded-full bg-white transition-transform block ${rememberLastServer ? 'translate-x-4' : 'translate-x-0'}`} />
                </button>
              </div>

              {/* App Colors Choice */}
              <div>
                <span className="block text-[10px] text-gray-500 font-bold uppercase tracking-wider mb-1.5">Accent Palette</span>
                <div className="flex gap-1.5">
                  {ACCENTS_LIST.map((acc) => (
                    <button
                      key={acc.id}
                      onClick={() => handleAccentChange(acc.id)}
                      className={`w-5 h-5 rounded-full border flex items-center justify-center text-white text-[9px] ${acc.bgClass} ${
                        accentColorId === acc.id ? "ring-2 ring-white border-transparent" : "border-slate-800"
                      }`}
                      title={acc.name}
                    >
                      {accentColorId === acc.id && "✓"}
                    </button>
                  ))}
                </div>
              </div>

              {/* App Fonts Grid Choice Checkbox styled cards */}
              <div>
                <span className="block text-[10px] text-gray-500 font-bold uppercase tracking-wider mb-2">Typography & Style</span>
                <div className="grid grid-cols-2 gap-1.5">
                  {FONTS_LIST.map((f) => {
                    const selected = fontFamily === f.id;
                    return (
                      <div
                        key={f.id}
                        onClick={() => handleFontChange(f.id)}
                        className={`p-2 rounded border cursor-pointer transition-all ${
                          selected 
                            ? "bg-slate-900 border-zinc-500 text-white" 
                            : "bg-slate-950 border-slate-900 text-gray-400 hover:text-white"
                        }`}
                      >
                        <div className="text-xs font-semibold">Aa</div>
                        <div className="text-[9px] truncate mt-0.5 font-medium">{f.name.split(" ")[0]}</div>
                      </div>
                    );
                  })}
                </div>
              </div>
            </div>

            {/* Active IPTV Session Information */}
            {activeServer && (
              <div className="bg-slate-950 border border-slate-900 rounded p-3 text-xs space-y-2">
                <span className="text-[9px] font-bold text-gray-500 uppercase tracking-widest block">Active Meta-Core</span>
                <div className="space-y-1 font-mono text-[11px] text-gray-450">
                  <div className="flex justify-between">
                    <span>Authenticity:</span>
                    <span className="text-emerald-400 font-semibold uppercase">{isDemoMode ? "Sandbox" : "Verified Cloud"}</span>
                  </div>
                  {userInfo && (
                    <>
                      <div className="flex justify-between">
                        <span>Max Clients:</span>
                        <span className="text-slate-300">{userInfo.max_connections || "N/A"}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Format:</span>
                        <span className="text-slate-300">{userInfo.allowed_output_formats?.join(", ") || "ts / m3u8"}</span>
                      </div>
                      <div className="flex justify-between">
                        <span>Expiry Date:</span>
                        <span className="text-amber-400">
                          {userInfo.exp_date ? new Date(parseInt(userInfo.exp_date) * 1000).toLocaleDateString() : "Lifetime"}
                        </span>
                      </div>
                    </>
                  )}
                </div>
              </div>
            )}

          </div>
        </aside>

        {/* Right Hand Side: Content Player Engine & Channels Stream Table */}
        <main className="flex-1 bg-slate-950 flex flex-col overflow-hidden">
          
          {/* Top Panel: Server Metadata Stats */}
          <div className="p-4 border-b border-slate-900 bg-slate-900/10 grid grid-cols-1 sm:grid-cols-3 gap-3 shrink-0">
            <div className="bg-slate-900/60 border border-slate-850 p-3 rounded flex items-center justify-between">
              <div>
                <div className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Active Server Profile</div>
                <div className="text-sm font-semibold text-white truncate max-w-[150px]">
                  {activeServer ? activeServer.name : "Local Playback Offline"}
                </div>
              </div>
              <Database className="w-5 h-5 text-indigo-400 shrink-0" />
            </div>

            <div className="bg-slate-900/60 border border-slate-850 p-3 rounded flex items-center justify-between">
              <div>
                <div className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Stream Category Mode</div>
                <div className="text-sm font-semibold text-white capitalize">
                  {streamMode === "live" ? "Live Broadcasts" : streamMode === "movie" ? "VOD Cinema" : "Series & TV Shows"}
                </div>
              </div>
              <div 
                className="w-5 h-5 rounded-full flex items-center justify-center font-mono text-[10px] text-white font-bold"
                style={{ backgroundColor: activeAccent.color }}
              >
                {streamMode.charAt(0).toUpperCase()}
              </div>
            </div>

            <div className="bg-slate-900/60 border border-slate-850 p-3 rounded flex items-center justify-between">
              <div>
                <div className="text-[10px] font-bold text-slate-500 uppercase tracking-widest">Available Streams Found</div>
                <div className="text-sm font-semibold text-emerald-400">
                  {streams.length > 0 ? `${streams.length.toLocaleString()} Loaded` : "No Active Streams"}
                </div>
              </div>
              <CheckCircle className="w-5 h-5 text-emerald-400 shrink-0" />
            </div>
          </div>

          {connectError && (
            <div className="m-4 p-3 bg-indigo-950/40 border border-indigo-800/40 rounded text-xs text-indigo-300 flex items-start gap-2 shrink-0">
              <Info className="w-4 h-4 text-sky-400 shrink-0 mt-0.5" />
              <div className="flex-1 leading-relaxed">
                <strong>Attention Mode:</strong> {connectError}
              </div>
              <button onClick={() => setConnectError(null)} className="text-gray-400 hover:text-white font-semibold">×</button>
            </div>
          )}

          {/* Sub-Header: IPTV Media Hub Categorizer Filters */}
          <div className="p-3 border-b border-slate-900 bg-slate-950 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3 shrink-0">
            {/* View Switching tabs */}
            <div className="flex bg-slate-900 p-1 rounded-md self-start border border-slate-850">
              <button
                onClick={() => handleModeChange("live")}
                className={`flex items-center gap-1.5 px-3 py-1 rounded-sm text-xs font-semibold transition-all ${
                  streamMode === "live"
                    ? "bg-slate-800 text-white shadow"
                    : "text-gray-400 hover:text-white"
                }`}
              >
                <Tv className="w-3.5 h-3.5" />
                Live Broadcasts
              </button>
              <button
                onClick={() => handleModeChange("movie")}
                className={`flex items-center gap-1.5 px-3 py-1 rounded-sm text-xs font-semibold transition-all ${
                  streamMode === "movie"
                    ? "bg-slate-800 text-white shadow"
                    : "text-gray-400 hover:text-white"
                }`}
              >
                <Film className="w-3.5 h-3.5" />
                VOD Blockbusters
              </button>
              <button
                onClick={() => handleModeChange("series")}
                className={`flex items-center gap-1.5 px-3 py-1 rounded-sm text-xs font-semibold transition-all ${
                  streamMode === "series"
                    ? "bg-slate-800 text-white shadow"
                    : "text-gray-400 hover:text-white"
                }`}
              >
                <Folder className="w-3.5 h-3.5" />
                Series / TV Shows
              </button>
            </div>

            {/* Quick Stream Search Bar */}
            <div className="relative self-stretch sm:w-60">
              <Search className="absolute left-2.5 top-2.5 w-3.5 h-3.5 text-slate-500" />
              <input
                type="text"
                placeholder={`Search ${streamMode === 'live' ? 'live channels' : 'movies'}...`}
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                className="w-full bg-slate-900/90 border border-slate-800 rounded pl-8 pr-3 py-1.5 text-xs text-white focus:outline-none focus:border-indigo-500"
              />
            </div>
          </div>

          {/* Catalog Two Column Shell: Categories Left & Streams Grid Right */}
          <div className="flex-1 flex overflow-hidden">
            
            {/* Categories left slider */}
            <div className="w-48 bg-slate-900/30 border-r border-slate-900 flex flex-col shrink-0">
              <div className="p-2 border-b border-slate-900 bg-slate-950">
                <span className="text-[10px] font-bold text-gray-500 uppercase tracking-widest pl-1">Media Genres</span>
              </div>
              <div className="flex-1 overflow-y-auto p-1.5 space-y-1">
                {categories.map((cat) => {
                  const isSelected = selectedCategoryId === cat.category_id;
                  return (
                    <button
                      key={cat.category_id}
                      onClick={() => {
                        setSelectedCategoryId(cat.category_id);
                        setSelectedStream(null);
                      }}
                      className={`w-full text-left p-2 rounded text-xs transition-colors flex items-center justify-between ${
                        isSelected
                          ? "bg-slate-800 text-white font-semibold"
                          : "text-gray-400 hover:bg-slate-900 hover:text-white"
                      }`}
                    >
                      <span className="truncate">{cat.category_name}</span>
                      {isSelected && <span className="w-1.5 h-1.5 rounded-full bg-white shrink-0 ml-1.5" />}
                    </button>
                  );
                })}
              </div>
            </div>

            {/* Channels Lists View / Selected Detailed Playback Area */}
            <div className="flex-1 flex flex-col md:flex-row overflow-hidden bg-slate-950/60">
              
              {/* Central Catalog Table */}
              <div className="flex-1 flex flex-col min-w-0 border-r border-slate-900">
                <div className="p-2.5 bg-slate-900/40 border-b border-slate-900 flex items-center justify-between text-xs text-gray-400 font-mono">
                  <span>Selected Stream Segment Catalog ({filteredStreams.length} listings)</span>
                  {isDemoMode && <span className="text-[10px] text-amber-500 animate-pulse font-bold">● Viewing Mock Channels</span>}
                </div>

                <div className="flex-1 overflow-y-auto p-3">
                  {isLoadingStreams ? (
                    <div className="h-full flex flex-col items-center justify-center space-y-2 text-gray-400 py-12">
                      <RefreshCcw className="w-6 h-6 animate-spin text-sky-450" />
                      <p className="text-xs">Connecting to IPTV API endpoint... Retrieving channel listings.</p>
                    </div>
                  ) : filteredStreams.length === 0 ? (
                    <div className="h-full flex flex-col items-center justify-center text-center p-6 text-gray-500 max-w-sm mx-auto py-16">
                      <Tv className="w-10 h-10 text-slate-700 mb-2" />
                      <p className="text-xs">No media listings match the current criteria.</p>
                      <p className="text-[11px] text-slate-600 mt-1">Try toggling different media categories or search keywords.</p>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-2">
                      {filteredStreams.map((st) => {
                        const isChosen = selectedStream?.stream_id === st.stream_id;
                        return (
                          <div
                            key={st.stream_id}
                            onClick={() => setSelectedStream(st)}
                            className={`p-2.5 rounded-lg border transition-all cursor-pointer flex items-center gap-3 text-left relative ${
                              isChosen
                                ? "bg-slate-800 border-zinc-500 shadow"
                                : "bg-slate-900/45 hover:bg-slate-900/80 border-slate-850"
                            }`}
                          >
                            {/* Icon fallback placeholder */}
                            <div className="w-10 h-10 rounded bg-slate-950 border border-slate-800 flex items-center justify-center shrink-0 overflow-hidden relative">
                              {st.stream_icon ? (
                                <img 
                                  src={st.stream_icon} 
                                  alt="" 
                                  className="w-full h-full object-contain p-0.5"
                                  onError={(e) => {
                                    (e.target as HTMLElement).style.display = 'none';
                                  }}
                                />
                              ) : (
                                <Tv className="w-4 h-4 text-gray-500" />
                              )}
                              <span className="absolute bottom-0 right-0 text-[8px] bg-slate-900 text-gray-400 px-0.5 rounded font-mono border-l border-t border-slate-800">
                                #{st.num}
                              </span>
                            </div>

                            <div className="flex-1 min-w-0">
                              <span className="block text-xs font-semibold text-white truncate group-hover:text-amber-400">
                                {st.name}
                              </span>
                              <span className="block text-[10px] text-gray-500 font-mono truncate">
                                Category: {st.category_id || "default"}
                              </span>
                            </div>
                            
                            {isChosen && (
                              <div className="absolute right-2 top-2">
                                <span className="w-2 h-2 rounded-full bg-emerald-400 block" />
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  )}
                </div>
              </div>

              {/* Action Sidebar: Direct Windows Launch URLs generator info layout */}
              <div className="w-full md:w-80 bg-slate-900/50 p-4 shrink-0 overflow-y-auto space-y-4">
                <ExternalPlayerGuide 
                  server={activeServer || { id: "demo-id", name: "NASA Public IPTV Network", host: window.location.origin, username: "public", password: "vip", createdAt: Date.now() }}
                  activeStream={formattedStreamObjectForPlayer}
                  mode={streamMode}
                  accentColor={activeAccent.color}
                />

                {/* Technical stream specifications card box */}
                <div className="bg-slate-900/40 border border-slate-850 p-3 rounded-lg text-xs space-y-2">
                  <span className="text-[10px] font-bold text-gray-500 uppercase tracking-widest block flex items-center gap-1">
                    <Sliders className="w-3.5 h-3.5" />
                    Format Settings Info
                  </span>
                  <p className="text-[11px] text-gray-400 leading-tight">
                    Xtream API generates streaming addresses that point directly to the media stream protocol files. Standard applications like <strong className="text-gray-200">VLC</strong> or <strong className="text-gray-200">PotPlayer</strong> have optimized streaming buffers for high bitrate IPTV feeds.
                  </p>
                  
                  <div className="border-t border-slate-850 pt-2 space-y-1 font-mono text-[10px] text-gray-500">
                    <div>Live Feed: <code className="text-indigo-400">MPEG-TS (.ts)</code></div>
                    <div>VOD Cinema: <code className="text-indigo-400">MP4 / MKV Container</code></div>
                    <div>HLS Support: <code className="text-emerald-400">Supported (External)</code></div>
                  </div>
                </div>

                {isDemoMode && (
                  <div className="p-3 bg-amber-955/20 border border-amber-800/40 rounded text-[11px] text-amber-300 space-y-1.5">
                    <div className="font-semibold flex items-center gap-1.5">
                      <Check className="w-3.5 h-3.5 bg-amber-500/20 rounded p-0.5 text-amber-400" />
                      Testing Workspace Active
                    </div>
                    <p className="text-gray-400 leading-tight">
                      To load your private custom channel categories, click on <strong className="text-amber-400">Add Server</strong> on the left profile card with host credentials.
                    </p>
                  </div>
                )}
              </div>

            </div>
          </div>

        </main>
      </div>

      {/* Standard Fluent Windows-Like Status Footer */}
      <footer className="h-8 bg-slate-900 border-t border-slate-800 px-4 flex items-center justify-between text-[10px] text-slate-500 shrink-0 font-mono">
        <div className="flex space-x-4">
          <span>Client System: Active (Windows Native Protocol Mock)</span>
          <span className="flex items-center">
            <span className="w-1.5 h-1.5 bg-emerald-500 rounded-full mr-1.5"></span>
            Cloud API Relay: Operational
          </span>
        </div>
        <div>Launch Protocol: VLC / PotPlayer protocol-handlers active</div>
      </footer>
    </div>
  );
}
