import React, { useState } from "react";
import { Plus, Trash2, Key, Database, Link, Globe, Wifi, Settings, LogIn, KeyRound, AlertCircle, Edit3 } from "lucide-react";
import { XtreamServer } from "../types";

interface ServerManagerProps {
  servers: XtreamServer[];
  activeServer: XtreamServer | null;
  onAddServer: (server: Omit<XtreamServer, "id">) => void;
  onDeleteServer: (id: string) => void;
  onConnect: (server: XtreamServer) => void;
  isConnecting: boolean;
  accentColor: string;
}

export function ServerManager({
  servers,
  activeServer,
  onAddServer,
  onDeleteServer,
  onConnect,
  isConnecting,
  accentColor
}: ServerManagerProps) {
  const [showForm, setShowForm] = useState(false);
  const [name, setName] = useState("");
  const [host, setHost] = useState("");
  const [username, setUsername] = useState("");
  const [password, setPassword] = useState("");

  const [testingId, setTestingId] = useState<string | null>(null);
  const [testResult, setTestResult] = useState<{ success: boolean; error?: string; message?: string } | null>(null);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !host || !username || !password) return;

    // Clean Host input
    let cleanHost = host.trim();
    if (!cleanHost.startsWith("http://") && !cleanHost.startsWith("https://")) {
      cleanHost = `http://${cleanHost}`;
    }

    onAddServer({
      name: name.trim(),
      host: cleanHost,
      username: username.trim(),
      password: password.trim(),
      createdAt: Date.now()
    });

    // Reset fields
    setName("");
    setHost("");
    setUsername("");
    setPassword("");
    setShowForm(false);
  };

  const handleTestConnection = async (srv: XtreamServer, e: React.MouseEvent) => {
    e.stopPropagation();
    setTestingId(srv.id);
    setTestResult(null);

    try {
      const response = await fetch("/api/iptv/test", {
        method: "POST",
        headers: {
          "Content-Type": "application/json"
        },
        body: JSON.stringify({
          host: srv.host,
          username: srv.username,
          password: srv.password
        })
      });

      const data = await response.json();
      if (response.ok && data.success) {
        setTestResult({
          success: true,
          message: `Auth Success! Active. Limit: ${data.info.max_connections || "N/A"} conn. Exp: ${data.info.exp_date ? new Date(parseInt(data.info.exp_date) * 1000).toLocaleDateString() : 'Never'}`
        });
      } else {
        setTestResult({
          success: false,
          error: data.error || "Authentication failed on server side."
        });
      }
    } catch (err: any) {
      setTestResult({
        success: false,
        error: "Network / Offline Error: Could not reach Xtream Server proxy."
      });
    } finally {
      setTestingId(null);
    }
  };

  const loadDefaults = () => {
    setName("Global IPTV Sandbox");
    setHost("http://sg-play.oneup.tv:80");
    setUsername("demo-line");
    setPassword("demo-pass546");
  };

  return (
    <div className="bg-slate-900 border border-slate-800 rounded-lg p-4 font-sans text-sm shadow-xl shrink-0">
      <div className="flex items-center justify-between mb-4 pb-2 border-b border-slate-800">
        <div className="flex items-center gap-2">
          <Database className="w-4 h-4 text-sky-400" />
          <h2 className="font-semibold text-white tracking-wide text-[14px]">IPTV Server Profiles</h2>
        </div>
        <button
          onClick={() => setShowForm(!showForm)}
          className="flex items-center gap-1 py-1 px-2.5 rounded text-white text-xs hover:opacity-90 font-medium transition-opacity"
          style={{ backgroundColor: accentColor }}
        >
          <Plus className="w-3.5 h-3.5" />
          Add Server
        </button>
      </div>

      {testResult && (
        <div className={`p-2.5 mb-3 rounded text-xs flex items-start gap-2 ${testResult.success ? "bg-emerald-950/40 border border-emerald-800/60 text-emerald-300" : "bg-rose-950/40 border border-rose-800/60 text-rose-300"}`}>
          <AlertCircle className="w-4 h-4 mt-0.5 shrink-0" />
          <div>
            <span className="font-semibold">{testResult.success ? "Successful Profile Test:" : "Connection Error:"}</span>{" "}
            {testResult.success ? testResult.message : testResult.error}
          </div>
          <button onClick={() => setTestResult(null)} className="ml-auto text-gray-500 hover:text-white font-medium">×</button>
        </div>
      )}

      {showForm && (
        <form onSubmit={handleSubmit} className="mb-4 p-3.5 bg-slate-950 border border-slate-800 rounded-md space-y-3">
          <div className="flex items-center justify-between">
            <span className="text-xs text-sky-400 font-semibold font-mono uppercase tracking-wider">New Server Details</span>
            <button
              type="button"
              onClick={loadDefaults}
              className="text-[10px] text-gray-400 hover:text-white bg-slate-800 px-1.5 py-0.5 rounded"
              title="Populates with a placeholder test dataset"
            >
              Fill Demo Server
            </button>
          </div>
          
          <div>
            <label className="block text-[11px] text-gray-400 mb-1 font-medium">Profile Friendly Name</label>
            <input
              type="text"
              required
              placeholder="e.g. My Premium IPTV"
              value={name}
              onChange={(e) => setName(e.target.value)}
              className="w-full bg-slate-900 border border-slate-800 rounded px-2.5 py-1.5 text-xs text-white focus:outline-none focus:border-sky-500"
            />
          </div>

          <div>
            <label className="block text-[11px] text-gray-400 mb-1 font-medium">Server Host URL (API address with port)</label>
            <div className="relative">
              <Globe className="absolute left-2.5 top-2 w-3.5 h-3.5 text-gray-500" />
              <input
                type="text"
                required
                placeholder="http://exampleiptv.com:8080"
                value={host}
                onChange={(e) => setHost(e.target.value)}
                className="w-full bg-slate-900 border border-slate-800 rounded pl-8 pr-2.5 py-1.5 text-xs text-white focus:outline-none focus:border-sky-500 font-mono"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-2">
            <div>
              <label className="block text-[11px] text-gray-400 mb-1 font-medium">Username</label>
              <input
                type="text"
                required
                placeholder="User / Login ID"
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                className="w-full bg-slate-900 border border-slate-800 rounded px-2.5 py-1.5 text-xs text-white focus:outline-none focus:border-sky-500"
              />
            </div>
            <div>
              <label className="block text-[11px] text-gray-400 mb-1 font-medium">Password</label>
              <div className="relative">
                <KeyRound className="absolute right-2.5 top-2.5 w-3 h-3 text-gray-500 pointer-events-none" />
                <input
                  type="password"
                  required
                  placeholder="Password"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="w-full bg-slate-900 border border-slate-800 rounded px-2.5 py-1.5 text-xs text-white focus:outline-none focus:border-sky-500"
                />
              </div>
            </div>
          </div>

          <div className="flex items-center gap-2 pt-1.5">
            <button
              type="submit"
              className="px-3 py-1.5 text-xs bg-sky-600 hover:bg-sky-500 text-white rounded font-medium transition-colors"
            >
              Save Profile
            </button>
            <button
              type="button"
              onClick={() => setShowForm(false)}
              className="px-3 py-1.5 text-xs bg-slate-800 hover:bg-slate-700 text-gray-300 rounded transition-colors"
            >
              Cancel
            </button>
          </div>
        </form>
      )}

      {/* Servers list */}
      <div className="space-y-2 max-h-[220px] overflow-y-auto pr-1">
        {servers.length === 0 ? (
          <div className="text-center py-6 text-slate-500 text-xs border border-dashed border-slate-800 rounded-md">
            No saved Xtream servers. Click &quot;Add Server&quot; to register your first IPTV connection.
          </div>
        ) : (
          servers.map((srv) => {
            const isActive = activeServer?.id === srv.id;
            return (
              <div
                key={srv.id}
                onClick={() => !isConnecting && onConnect(srv)}
                className={`group p-2.5 rounded-lg border text-left cursor-pointer transition-all flex items-center justify-between ${
                  isActive
                    ? "bg-slate-800/90 border-sky-400 shadow-md scale-[1.01]"
                    : "bg-slate-950 hover:bg-slate-800/50 border-slate-800"
                }`}
              >
                <div className="flex-1 min-w-0 pr-2">
                  <div className="flex items-center gap-1.5">
                    <span className="font-semibold text-white truncate text-xs">{srv.name}</span>
                    {isActive && (
                      <span className="text-[9px] bg-emerald-500/20 text-emerald-400 px-1 rounded-full font-mono uppercase tracking-wider font-semibold border border-emerald-500/20">
                        active
                      </span>
                    )}
                  </div>
                  <div className="text-[10px] text-gray-500 truncate font-mono mt-0.5">{srv.host}</div>
                  <div className="text-[10px] text-gray-400 truncate mt-0.5">User: {srv.username}</div>
                </div>

                <div className="flex items-center gap-1 shrink-0">
                  <button
                    onClick={(e) => handleTestConnection(srv, e)}
                    disabled={testingId !== null}
                    className="p-1 px-1.5 bg-slate-900 border border-slate-800 rounded hover:bg-slate-800 text-[10px] hover:text-white transition-colors"
                    title="Test connection authenticity"
                  >
                    {testingId === srv.id ? "Testing..." : "Test Link"}
                  </button>
                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      if (confirm(`Remove this server profile? "${srv.name}"`)) {
                        onDeleteServer(srv.id);
                      }
                    }}
                    className="p-1 rounded text-gray-500 hover:text-rose-400 hover:bg-slate-900 transition-all opacity-0 group-hover:opacity-100"
                    title="Delete connection"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>
            );
          })
        )}
      </div>
    </div>
  );
}
