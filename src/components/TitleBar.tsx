import React, { useState, useEffect } from "react";
import { Monitor, RefreshCcw, Wifi, WifiOff, CheckCircle, Database } from "lucide-react";
import { XtreamServer } from "../types";

interface TitleBarProps {
  activeServer: XtreamServer | null;
  isConnected: boolean;
  isConnecting: boolean;
  onRefresh: () => void;
  accentColor: string;
}

export function TitleBar({ activeServer, isConnected, isConnecting, onRefresh, accentColor }: TitleBarProps) {
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [timeStr, setTimeStr] = useState("");

  const handleMaximize = () => {
    if (!document.fullscreenElement) {
      document.documentElement.requestFullscreen().catch(() => {});
      setIsFullscreen(true);
    } else {
      document.exitFullscreen().catch(() => {});
      setIsFullscreen(false);
    }
  };

  useEffect(() => {
    const handleSubFullscreen = () => {
      setIsFullscreen(!!document.fullscreenElement);
    };
    document.addEventListener("fullscreenchange", handleSubFullscreen);
    return () => document.removeEventListener("fullscreenchange", handleSubFullscreen);
  }, []);

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setTimeStr(now.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', second: '2-digit' }));
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <div className="h-10 border-b border-gray-800 bg-slate-950 text-gray-300 flex items-center justify-between px-3 select-none text-xs font-sans shrink-0">
      {/* Title & App brand */}
      <div className="flex items-center gap-2">
        <div 
          className="w-5 h-5 rounded flex items-center justify-center text-white" 
          style={{ backgroundColor: accentColor }}
        >
          <Monitor className="w-3.5 h-3.5 stroke-[2.5]" />
        </div>
        <span className="font-semibold tracking-wide text-white">Xtream Flow</span>
        <span className="text-gray-500">|</span>
        <span className="text-[10px] uppercase font-mono bg-gray-900 border border-gray-800 text-gray-400 px-1.5 py-0.5 rounded tracking-wider">
          Windows Client v1.4
        </span>
      </div>

      {/* Active IPTV Connection display */}
      <div className="flex items-center gap-3">
        {activeServer ? (
          <div className="flex items-center gap-2 bg-slate-900 border border-slate-800 py-0.5 px-2.5 rounded-full">
            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse" />
            <span className="text-gray-300 truncate max-w-[140px] font-mono">
              {activeServer.name}
            </span>
            <span className="text-gray-500 text-[10px]">({activeServer.host.replace(/^https?:\/\//, '')})</span>
            {isConnecting ? (
              <RefreshCcw className="w-3 h-3 text-sky-400 animate-spin" />
            ) : isConnected ? (
              <CheckCircle className="w-3 h-3 text-emerald-400" />
            ) : (
              <WifiOff className="w-3 h-3 text-rose-400" />
            )}
          </div>
        ) : (
          <div className="flex items-center gap-2 bg-slate-900/50 border border-slate-800/80 py-0.5 px-2.5 rounded-full text-gray-500">
            <WifiOff className="w-3 h-3" />
            <span className="text-[11px]">No server connected</span>
          </div>
        )}

        {/* Realtime Desk Clock */}
        <div className="hidden md:block font-mono bg-slate-900 border border-slate-800 px-2.5 py-0.5 rounded text-gray-400 text-[11px]">
          {timeStr}
        </div>
      </div>

      {/* Operating System window control mimics */}
      <div className="flex items-center gap-1">
        {activeServer && isConnected && (
          <button
            onClick={onRefresh}
            title="Reload IPTV Server Data"
            className="w-7 h-7 flex items-center justify-center hover:bg-slate-800 text-gray-400 hover:text-white rounded"
          >
            <RefreshCcw className={`w-3.5 h-3.5 ${isConnecting ? 'animate-spin' : ''}`} />
          </button>
        )}
        
        {/* Minimize */}
        <button 
          onClick={() => alert("Windows desktop client mock: Minimize action hides the window to system tray.")}
          className="w-7 h-7 flex items-center justify-center hover:bg-slate-800 text-gray-400 hover:text-white rounded transition-colors"
          title="Minimize"
        >
          <span className="w-2.5 h-[1.5px] bg-gray-400 block" />
        </button>
        
        {/* Maximize */}
        <button 
          onClick={handleMaximize}
          className="w-7 h-7 flex items-center justify-center hover:bg-slate-800 text-gray-400 hover:text-white rounded transition-colors"
          title={isFullscreen ? "Restore Window" : "Maximize Screen"}
        >
          <div className="w-2.5 h-2.5 border-1.5 border-gray-400 rounded-sm" />
        </button>

        {/* Close */}
        <button 
          onClick={() => {
            if (confirm("Disconnect and close Xtream Flow mock session?")) {
              window.close();
            }
          }}
          className="w-7 h-7 flex items-center justify-center hover:bg-rose-600 group rounded transition-colors"
          title="Close App"
        >
          <span className="text-gray-400 group-hover:text-white text-base leading-none font-medium">×</span>
        </button>
      </div>
    </div>
  );
}
