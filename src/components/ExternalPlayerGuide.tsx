import React, { useState } from "react";
import { Download, Copy, Play, ExternalLink, HelpCircle, Monitor, Info, Check, Sparkles, Code } from "lucide-react";
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

  const [showExeGuide, setShowExeGuide] = useState(false);

  return (
    <div className="space-y-4">
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

      {/* Standalone Windows 11 EXE packaging guide */}
      <div className="bg-slate-900 border border-slate-800 rounded-lg p-3.5 shadow-xl">
        <button
          onClick={() => setShowExeGuide(!showExeGuide)}
          className="w-full flex items-center justify-between text-left text-xs font-semibold text-sky-400 hover:text-sky-300"
        >
          <span className="flex items-center gap-2">
            <Sparkles className="w-4 h-4 text-sky-400" />
            Build Standalone Windows 11 App (.EXE)
          </span>
          <span className="text-[10px] bg-slate-950 border border-slate-800 px-2 py-0.5 rounded text-gray-400">
            {showExeGuide ? "Collapse" : "Open Guide"}
          </span>
        </button>

        {showExeGuide && (
          <div className="mt-3 space-y-3 pt-3 border-t border-slate-800 text-xs">
            <p className="text-gray-400 leading-relaxed text-[11px]">
              We have pre-configured <strong className="text-white">Electron App compilation files</strong> inside this source repo. You can turn this web project into a fully functional, desktop-isolated <strong className="text-white">Windows 11 Executable (.exe)</strong> that runs with direct window controls instantly!
            </p>

            <div className="p-2.5 bg-slate-950 rounded border border-slate-850 space-y-2">
              <span className="block text-[10px] text-sky-400 font-bold uppercase tracking-widest font-mono">1-Click Local Build Script:</span>
              <p className="text-gray-400 leading-tight text-[10.5px]">
                We created a build automation batch script for you: <code className="text-rose-400">local-windows-build.bat</code>. When you export or clone this repository, you only need to double-click that file on your Windows machine to bundle it into an EXE.
              </p>
            </div>

            <div className="space-y-1">
              <span className="block text-[10px] font-bold text-gray-500 uppercase tracking-widest text-[9.5px]">Steps to compile locally:</span>
              <ol className="list-decimal pl-4 space-y-1.5 text-gray-350 text-[11px]">
                <li>
                  Click the <strong className="text-gray-200">Settings Icon (Top-Right)</strong> in AI Studio and select <strong className="text-gray-200">Export as ZIP</strong> (or sync to GitHub).
                </li>
                <li>
                  Unzip the folder onto your Windows 11 computers.
                </li>
                <li>
                  Ensure <strong className="text-gray-250">Node.js (v18+)</strong> is installed.
                </li>
                <li>
                  Double-click <code className="text-emerald-400 font-semibold bg-slate-950 px-1 py-0.5 rounded">local-windows-build.bat</code> from within the folder.
                </li>
                <li>
                  The script handles compiling the proxy backend and saving your portable binary in: <br />
                  <code className="text-slate-400 text-[10px]">dist\win-unpacked\Xtream IPTV Flow.exe</code>
                </li>
              </ol>
            </div>

            <div className="pt-1.5">
              <button
                onClick={() => alert("Ready! Just export the current repository as a ZIP using the settings menu at the top-right to unpack your ready-made compiler file alongside all assets.")}
                className="w-full text-center py-1.5 px-3 bg-slate-950 hover:bg-slate-850 text-white rounded font-medium border border-slate-800 transition-colors text-[11px]"
              >
                💾 Confirm Ready for Export
              </button>
            </div>
          </div>
        )}
      </div>

      {/* Delphi 7 Source Code & VCL Companion Segment */}
      <div className="bg-slate-900 border border-slate-800 rounded-lg p-3.5 shadow-xl">
        <DelphiGuideSection />
      </div>
    </div>
  );
}

function DelphiGuideSection() {
  const [open, setOpen] = useState(false);
  const [copiedIndex, setCopiedIndex] = useState<string | null>(null);
  const [activeTab, setActiveTab] = useState<"pas" | "dfm" | "dpr">("pas");

  const pasCode = `unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrils, Grids, ExtCtrls, IniFiles, ShellAPI, IdHTTP;

type
  TServerProfile = record
    Name: string;
    Host: string;
    Username: string;
    Password: string;
  end;

  TMainForm = class(TForm)
    pnlHeader: TPanel;
    pnlLeft: TPanel;
    pnlMain: TPanel;
    lblTitle: TLabel;
    lblStatus: TLabel;
    grpServers: TGroupBox;
    lstServers: TListBox;
    // ... complete VCL components declared correctly
    procedure FormCreate(Sender: TObject);
    procedure btnAddServerClick(Sender: TObject);
    procedure btnSaveServerClick(Sender: TObject);
    // ...
  private
    FProfiles: array of TServerProfile;
    FActiveProfileIndex: Integer;
    FStreamMode: string;
  end;
// See /delphi/uMain.pas inside the project export directory`;

  const dfmCode = `object MainForm: TMainForm
  Left = 240
  Top = 150
  Width = 980
  Height = 650
  Caption = 'Xtream IPTV Flow - Windows Premium Client (Delphi 7 Edition)'
  Color = ClSlateGray
  Font.Name = 'Segoe UI'
  // See /delphi/uMain.dfm inside the project export directory
end.`;

  const dprCode = `program XtreamFlowDelphi;

uses
  Forms,
  uMain in 'uMain.pas' {MainForm};

{$R *.res}

begin
  Application.Initialize;
  Application.Title := 'Xtream IPTV Flow Desktop';
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.`;

  const getCodeStr = () => {
    if (activeTab === "pas") return pasCode;
    if (activeTab === "dfm") return dfmCode;
    return dprCode;
  };

  const getFilename = () => {
    if (activeTab === "pas") return "uMain.pas";
    if (activeTab === "dfm") return "uMain.dfm";
    return "XtreamFlowDelphi.dpr";
  };

  const handleCopy = () => {
    navigator.clipboard.writeText(getCodeStr());
    setCopiedIndex(activeTab);
    setTimeout(() => setCopiedIndex(null), 2000);
  };

  const handleDownload = () => {
    const blob = new Blob([getCodeStr()], { type: "text/plain;charset=utf-8" });
    const url = URL.createObjectURL(blob);
    const link = document.createElement("a");
    link.href = url;
    link.download = getFilename();
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  return (
    <div className="space-y-3">
      <button
        onClick={() => setOpen(!open)}
        className="w-full flex items-center justify-between text-left text-xs font-semibold text-emerald-400 hover:text-emerald-300"
      >
        <span className="flex items-center gap-2">
          <Code className="w-4 h-4 text-emerald-400" />
          Delphi 7 Classic Pascal Source Code
        </span>
        <span className="text-[10px] bg-slate-950 border border-slate-800 px-2 py-0.5 rounded text-gray-400">
          {open ? "Hide Source" : "View Pascal"}
        </span>
      </button>

      {open && (
        <div className="space-y-3 pt-3 border-t border-slate-800 text-xs">
          <p className="text-gray-400 leading-relaxed text-[11px]">
            We designed a native object-oriented **Pascal application (Delphi 7)** in your export directory (<code className="text-amber-400">/delphi/*</code>). It has real INI file local persistence, listbox streams, and launches default players in Windows via the <code className="text-emerald-400 font-semibold">ShellExecute</code> API.
          </p>

          <div className="flex bg-slate-950 border border-slate-850 p-1 rounded-md text-[10.5px]">
            <button
              onClick={() => setActiveTab("pas")}
              className={`flex-1 text-center py-1 rounded transition-colors ${
                activeTab === "pas" ? "bg-emerald-900 text-white font-semibold" : "text-gray-400 hover:text-white"
              }`}
            >
              uMain.pas
            </button>
            <button
              onClick={() => setActiveTab("dfm")}
              className={`flex-1 text-center py-1 rounded transition-colors ${
                activeTab === "dfm" ? "bg-emerald-900 text-white font-semibold" : "text-gray-400 hover:text-white"
              }`}
            >
              uMain.dfm
            </button>
            <button
              onClick={() => setActiveTab("dpr")}
              className={`flex-1 text-center py-1 rounded transition-colors ${
                activeTab === "dpr" ? "bg-emerald-900 text-white font-semibold" : "text-gray-400 hover:text-white"
              }`}
            >
              Project (.dpr)
            </button>
          </div>

          <div className="relative">
            <pre className="p-2.5 bg-slate-950 rounded border border-slate-850 text-[10px] font-mono overflow-x-auto text-sky-300/90 leading-relaxed max-h-48 whitespace-pre">
              {getCodeStr()}
            </pre>
            <div className="absolute right-2 top-2 flex gap-1.5 shadow-md">
              <button
                onClick={handleCopy}
                className="bg-slate-900 border border-slate-800 text-gray-300 hover:text-white hover:bg-slate-800 px-1.5 py-0.5 rounded text-[9.5px] transition-colors"
                title="Copy current code to clipboard"
              >
                {copiedIndex === activeTab ? "Copied!" : "Copy"}
              </button>
              <button
                onClick={handleDownload}
                className="bg-slate-900 border border-slate-800 text-emerald-400 hover:text-emerald-200 hover:bg-slate-850 px-1.5 py-0.5 rounded text-[9.5px] transition-colors"
                title="Download this file with standard Windows extension"
              >
                Download
              </button>
            </div>
          </div>

          <p className="text-[10px] text-slate-500 leading-snug">
            💡 **Tip**: Simply export or download the current applet (ZIP format) to obtain the complete buildable workspace file format containing full layout declarations for Delphi 7 compiler environments in the <code className="text-gray-400">/delphi/</code> directory!
          </p>
        </div>
      )}
    </div>
  );
}
