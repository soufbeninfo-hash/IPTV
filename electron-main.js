const { app, BrowserWindow } = require('electron');
const path = require('path');
const { spawn } = require('child_process');

let mainWindow;
let serverProcess;

function startExpressServer() {
  // Start our bundled express proxy local server
  const serverPath = path.join(__dirname, 'dist', 'server.cjs');
  console.log('Booting secondary local server from:', serverPath);
  
  // Set prod environment variables for express server
  const env = Object.assign({}, process.env, {
    NODE_ENV: 'production',
    PORT: '3000'
  });

  serverProcess = spawn('node', [serverPath], { env });

  serverProcess.stdout.on('data', (data) => {
    console.log(`[Express Backend] ${data}`);
  });

  serverProcess.stderr.on('data', (data) => {
    console.error(`[Express Error] ${data}`);
  });
}

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 850,
    title: "Xtream IPTV Flow - Windows Premium Client",
    autoHideMenuBar: true,
    backgroundColor: '#020617', // Match slate-950 UI
    webPreferences: {
      nodeIntegration: false,
      contextIsolation: true,
      sandbox: true
    }
  });

  // Give the express local server 1 second to bind to port 3000 before navigating
  setTimeout(() => {
    mainWindow.loadURL('http://localhost:3000').catch(() => {
      // Fallback in case of slow boot to load the production web host
      mainWindow.loadURL('https://ais-pre-3bpacqhwhlgvo3ic5d5l3p-36788252593.europe-west2.run.app');
    });
  }, 1000);

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.on('ready', () => {
  try {
    startExpressServer();
  } catch (e) {
    console.error('Could not boot local express process natively. Loading remote web layer instead.', e);
  }
  createWindow();
});

app.on('window-all-closed', () => {
  // Gracefully stop backend process on exit
  if (serverProcess) {
    serverProcess.kill();
  }
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('will-quit', () => {
  if (serverProcess) {
    serverProcess.kill();
  }
});
