import React, { useState } from "react";
import { Download, Copy, Play, ExternalLink, HelpCircle, Monitor, Info, Check, Sparkles } from "lucide-react";
import { XtreamServer, IptvStream, StreamMode } from "../types";

interface ExternalPlayerGuideProps {
  server: XtreamServer | null;
  activeStream: IptvStream | null;
  mode: StreamMode;
  accentColor: string;
}

export function ExternalPlayerGuide({ server, activeStream, mode, accentColor }: ExternalPlayerGuideProps) {
  const [copied, setCopied] = useState(false);
  const [selectedPlayer, setSelectedPlayer] = useState<"vlc" | "potplayer" | "mpv" | "m3u" | "copy">("m3u");

  if (!server) return null;

  // Build the direct Xtream multimedia link format
  const getStreamLink = () => {
    if (!activeStream) return "";
    const cleanHost = server.host.endsWith("/") ? server.host.slice(0, -1) : server.host;
    const user = encodeURIComponent(server.username);
    const pass = encodeURIComponent(server.password);
    const id = activeStream.stream_id;

    if (mode === "live") {
      // Live stream endpoint: usually ts or m3u8
      return `${cleanHost}/live/${user}/${pass}/${id}.ts`;
    } else if (mode === "movie") {
      const ext = activeStream.container_extension || "mp4";
      return `${cleanHost}/movie/${user}/${pass}/${id}.${ext}`;
    } else {
      // Series episode (the activeStream itself for episodes is loaded differently, but standard stream layout matches movie)
      const ext = activeStream.container_extension || "mp4";
      return `${cleanHost}/series/${user}/${pass}/${id}.${ext}`;
    }
  };

  const streamUrl = getStreamLink();

  // Custom protocol mappings
  const getProtocolLink = () => {
    if (!streamUrl) return "";
    if (selectedPlayer === "vlc") {
      // vlc://http://... protocol launcher
      return `vlc://${streamUrl}`;
    }
    if (selectedPlayer === "potplayer") {
      // potplayer://http://... protocol launcher
      return `potplayer://${streamUrl}`;
    }
    if (selectedPlayer === "mpv") {
      // mpv://http://... with handlers
      return `mpv://${streamUrl}`;
    }
    return streamUrl;
  };

  const handleCopy = () => {
    if (!streamUrl) return;
    navigator.clipboard.writeText(streamUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const handleDownloadSingleM3u = () => {
    if (!activeStream || !streamUrl) return;
    const filename = `${activeStream.name.replace(/[^a-z0-9]/gi, "_").toLowerCase()}.m3u`;
    const m3uContent = `#EXTM3U\n#EXTINF:-1 tvg-logo="${activeStream.stream_icon || ""}" group-title="${activeStream.category_id || ""}",${activeStream.name}\n${streamUrl}\n`;
    
    const blob = new Blob([m3uContent], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = filename;
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-lg p-4 font-sans text-sm shadow-xl">
      <div className="flex items-center gap-2 mb-3 pb-2 border-b border-slate-800">
        <Monitor className="w-4 h-4 text-emerald-400" />
        <h3 className="font-semibold text-white tracking-wide text-[13px]">Windows Playback Hub</h3>
      </div>

      {!activeStream ? (
        <div className="text-center py-6 text-gray-500 text-xs text-balance">
          Select a channel or title to generate launch links & custom playlist files.
        </div>
      ) : (
        <div className="space-y-3.5">
          <div className="p-2.5 bg-slate-950 border border-slate-800/80 rounded">
            <div className="text-[10px] text-sky-400 font-semibold font-mono uppercase tracking-wide mb-1">Target Media Stream</div>
            <div className="text-xs font-semibold text-white truncate">{activeStream.name}</div>
            <div className="text-[9.5px] font-mono text-gray-400 truncate mt-1 bg-slate-900 px-1.5 py-1 rounded select-all border border-slate-850">
              {streamUrl}
            </div>
          </div>

          <div>
            <span className="block text-[11px] text-gray-400 mb-2 font-medium">Choose Launch Method for Windows:</span>
            
            <div className="grid grid-cols-2 gap-1.5">
              <button
                onClick={() => setSelectedPlayer("m3u")}
                className={`py-1.5 px-2.5 rounded text-left text-xs font-medium border transition-all ${
                  selectedPlayer === "m3u"
                    ? "bg-slate-850 text-white border-zinc-500"
                    : "bg-slate-950 text-gray-400 border-slate-850 hover:bg-slate-900"
                }`}
              >
                💾 Instant M3U (VLC/Any)
              </button>
              
              <button
                onClick={() => setSelectedPlayer("potplayer")}
                className={`py-1.5 px-2.5 rounded text-left text-xs font-medium border transition-all ${
                  selectedPlayer === "potplayer"
                    ? "bg-slate-850 text-white border-zinc-500"
                    : "bg-slate-950 text-gray-400 border-slate-850 hover:bg-slate-900"
                }`}
              >
                🚀 PotPlayer Link
              </button>

              <button
                onClick={() => setSelectedPlayer("vlc")}
                className={`py-1.5 px-2.5 rounded text-left text-xs font-medium border transition-all ${
                  selectedPlayer === "vlc"
                    ? "bg-slate-850 text-white border-zinc-500"
                    : "bg-slate-950 text-gray-400 border-slate-850 hover:bg-slate-900"
                }`}
              >
                🍊 VLC App Link
              </button>

              <button
                onClick={() => setSelectedPlayer("copy")}
                className={`py-1.5 px-2.5 rounded text-left text-xs font-medium border transition-all ${
                  selectedPlayer === "copy"
                    ? "bg-slate-850 text-white border-zinc-500"
                    : "bg-slate-950 text-gray-400 border-slate-850 hover:bg-slate-900"
                }`}
              >
                📋 Copy Link Only
              </button>
            </div>
          </div>

          <div className="pt-2 border-t border-slate-850">
            {selectedPlayer === "m3u" && (
              <div className="space-y-2">
                <p className="text-[11px] text-gray-400 leading-relaxed">
                  Downloads a mini M3U file. Double-clicking this in Windows will trigger your default external media player (MPC-HC, VLC, or PotPlayer) to boot and stream this channel instantly.
                </p>
                <button
                  onClick={handleDownloadSingleM3u}
                  className="w-full py-2 px-3 rounded hover:opacity-90 transition-all font-semibold text-xs text-white justify-center flex items-center gap-1.5 shadow-md"
                  style={{ backgroundColor: accentColor }}
                >
                  <Download className="w-3.5 h-3.5" />
                  Generate & Download .M3U Playlist
                </button>
              </div>
            )}

            {selectedPlayer === "potplayer" && (
              <div className="space-y-2">
                <p className="text-[11px] text-gray-400 leading-relaxed">
                  Triggers PotPlayer Directly using the registered protocol handler on Windows. Make sure PotPlayer is installed on your machine.
                </p>
                <a
                  href={getProtocolLink()}
                  onClick={(e) => {
                    // Let protocol launch naturally
                  }}
                  className="w-full py-2 px-3 rounded text-center hover:opacity-90 transition-all font-semibold text-xs text-white inline-flex items-center justify-center gap-1.5 shadow-md"
                  style={{ backgroundColor: accentColor }}
                >
                  <Play className="w-3.5 h-3.5 fill-current" />
                  Launch in PotPlayer
                </a>
              </div>
            )}

            {selectedPlayer === "vlc" && (
              <div className="space-y-2">
                <p className="text-[11px] text-gray-400 leading-relaxed">
                  Attempts to deep-link straight to your VLC desktop application via the registered <code className="bg-slate-950 px-1 py-0.5 rounded text-rose-300">vlc://</code> protocol on Windows.
                </p>
                <a
                  href={getProtocolLink()}
                  className="w-full py-2 px-3 rounded text-center hover:opacity-90 transition-all font-semibold text-xs text-white inline-flex items-center justify-center gap-1.5 shadow-md"
                  style={{ backgroundColor: accentColor }}
                >
                  <ExternalLink className="w-3.5 h-3.5" />
                  Launch in VLC Media Player
                </a>
              </div>
            )}

            {selectedPlayer === "copy" && (
              <div className="space-y-2">
                <p className="text-[11px] text-gray-400 leading-relaxed">
                  Copies the direct raw HLS/TS source link to your clipboard. You can paste this URL into VLC (<code className="bg-slate-950 px-1 rounded text-orange-400">Ctrl+N</code>) or PotPlayer to custom-stream manually.
                </p>
                <button
                  onClick={handleCopy}
                  className="w-full py-2 px-3 rounded hover:opacity-90 transition-all font-semibold text-xs text-white justify-center flex items-center gap-1.5 shadow-md"
                  style={{ backgroundColor: accentColor }}
                >
                  {copied ? (
                    <>
                      <Check className="w-3.5 h-3.5" />
                      Copied with Success!
                    </>
                  ) : (
                    <>
                      <Copy className="w-3.5 h-3.5" />
                      Copy stream URL to Clipboard
                    </>
                  )}
                </button>
              </div>
            )}
          </div>

          <div className="p-2 bg-slate-950/50 border border-slate-850/50 rounded flex items-start gap-1.5">
            <Info className="w-3.5 h-3.5 text-amber-500 shrink-0 mt-0.5" />
            <p className="text-[10px] text-gray-400 text-balance leading-tight">
              IPTV servers run best on Windows with <strong className="text-gray-300">VLC</strong> or <strong className="text-gray-300">PotPlayer</strong>. If a feed buffers, use PotPlayer which excels with MPEG-TS feeds.
            </p>
          </div>
        </div>
      )}
    </div>
  );
}
