import express from "express";
import path from "path";
import dns from "dns";
import { createServer as createViteServer } from "vite";

// Force support for custom dns resolution if needed, let node handle it
dns.setDefaultResultOrder("ipv4first");

async function startServer() {
  const app = express();
  const PORT = 3000;

  // Body parsing middleware
  app.use(express.json({ limit: "50mb" }));
  app.use(express.urlencoded({ extended: true, limit: "50mb" }));

  // API Route: Login and general queries to Xtream IPTV Server
  app.post("/api/iptv/proxy", async (req: express.Request, res: express.Response): Promise<void> => {
    try {
      const { host, username, password, action, category_id, series_id } = req.body;

      if (!host || !username || !password) {
        res.status(400).json({ error: "Missing required parameters (host, username, password)" });
        return;
      }

      // Format clean host base (without trailing slash)
      let cleanHost = host.trim();
      if (cleanHost.endsWith("/")) {
        cleanHost = cleanHost.slice(0, -1);
      }

      // Build target player_api URL
      let targetUrl = `${cleanHost}/player_api.php?username=${encodeURIComponent(username)}&password=${encodeURIComponent(password)}`;
      
      if (action) {
        targetUrl += `&action=${encodeURIComponent(action)}`;
      }
      if (category_id !== undefined && category_id !== null) {
        targetUrl += `&category_id=${encodeURIComponent(category_id)}`;
      }
      if (series_id !== undefined && series_id !== null) {
        targetUrl += `&series_id=${encodeURIComponent(series_id)}`;
      }

      console.log(`[IPTV Proxy] Fetching action "${action || 'login'}" from: ${cleanHost}`);

      // Perform request with a timeout
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 15000); // 15s timeout

      const response = await fetch(targetUrl, {
        method: "GET",
        signal: controller.signal,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/115.0.0.0 Safari/537.36",
          "Accept": "application/json"
        }
      });

      clearTimeout(timeoutId);

      if (!response.ok) {
        res.status(response.status).json({ 
          error: `Xtream server returned status code ${response.status}`,
          status: response.status 
        });
        return;
      }

      // Check content-type to handle it safely
      const contentType = response.headers.get("content-type") || "";
      let data;
      
      if (contentType.includes("application/json")) {
        data = await response.json();
      } else {
        const text = await response.text();
        try {
          data = JSON.parse(text);
        } catch {
          // If response isn't JSON, return text directly or custom parse
          data = text;
        }
      }

      res.json(data);
    } catch (err: any) {
      console.error("[IPTV Proxy Error]:", err.message);
      res.status(500).json({ 
        error: "Failed to connect to the Xtream Server or fetch data.", 
        details: err.message 
      });
    }
  });

  // API Route: Test Server Connection directly
  app.post("/api/iptv/test", async (req: express.Request, res: express.Response): Promise<void> => {
    try {
      const { host, username, password } = req.body;
      if (!host || !username || !password) {
        res.status(400).json({ error: "Missing credentials" });
        return;
      }

      let cleanHost = host.trim();
      if (cleanHost.endsWith("/")) {
        cleanHost = cleanHost.slice(0, -1);
      }

      const targetUrl = `${cleanHost}/player_api.php?username=${encodeURIComponent(username)}&password=${encodeURIComponent(password)}`;
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 8000); // 8s timeout

      const response = await fetch(targetUrl, {
        method: "GET",
        signal: controller.signal,
        headers: {
          "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
        }
      });
      clearTimeout(timeoutId);

      if (!response.ok) {
        res.status(response.status).json({ success: false, error: `HTTP ${response.status}` });
        return;
      }

      const rawText = await response.text();
      let parseData;
      try {
        parseData = JSON.parse(rawText);
      } catch (e) {
        res.status(422).json({ success: false, error: "Response is not valid JSON. Ensure this URL points to a standard Xtream IPTV service API." });
        return;
      }

      if (parseData?.user_info && parseData?.user_info?.auth !== 0) {
        res.json({ success: true, info: parseData.user_info, server: parseData.server_info });
      } else {
        res.json({ success: false, error: "Authentication failed. Invalid username or password." });
      }
    } catch (err: any) {
      res.status(500).json({ success: false, error: err.message });
    }
  });

  // Vite integration
  if (process.env.NODE_ENV !== "production") {
    const vite = await createViteServer({
      server: { middlewareMode: true },
      appType: "spa",
    });
    app.use(vite.middlewares);
  } else {
    const distPath = path.join(process.cwd(), "dist");
    app.use(express.static(distPath));
    app.get("*", (req, res) => {
      res.sendFile(path.join(distPath, "index.html"));
    });
  }

  app.listen(PORT, "0.0.0.0", () => {
    console.log(`[Server] Xtream IPTV Manager proxy server running on http://0.0.0.0:${PORT}`);
  });
}

startServer().catch((err) => {
  console.error("[Fatal Startup Error]:", err);
});
