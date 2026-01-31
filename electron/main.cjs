const { app, BrowserWindow, Menu, dialog, shell } = require('electron');
const path = require('path');
const http = require('http');
const isDev = !app.isPackaged;

// Auto-update (GitHub Releases)
const { autoUpdater } = require('electron-updater');

let mainWindow;
let server;
let manualUpdateCheck = false;

async function startNextServer() {
  // In production we run the Next.js app *inside* Electron (no separate process).
  const next = require('next');
  const getPort = (await import('get-port')).default;

  const port = await getPort({ port: [3030, 3031, 3032, 3033, 3034, 3035] });

  const nextDir = isDev
    ? path.join(__dirname, '..')
    // In production, keep Next build output inside app.asar so Node module resolution
    // can find react/react-dom from the packaged node_modules.
    : path.join(__dirname, '..', 'next');

  // Hard guard: if this path is wrong, we end up with a blank screen (loadURL never happens).
  const fs = require('fs');
  if (!fs.existsSync(nextDir)) {
    throw new Error(`Next directory not found: ${nextDir}`);
  }

  const nextApp = next({ dev: false, dir: nextDir, hostname: '127.0.0.1', port });
  const handle = nextApp.getRequestHandler();

  await nextApp.prepare();

  server = http.createServer((req, res) => {
    handle(req, res).catch((err) => {
      console.error('Next request handler error:', err);
      res.statusCode = 500;
      res.end('Internal Server Error');
    });
  });

  await new Promise((resolve) => server.listen(port, '127.0.0.1', resolve));

  return `http://127.0.0.1:${port}`;
}

function createMenu() {
  const template = [
    {
      label: 'Fantasy Edge',
      submenu: [
        {
          label: 'Check for updates…',
          click: async () => {
            try {
              manualUpdateCheck = true;
              autoUpdater.autoDownload = false;
              await autoUpdater.checkForUpdates();
            } catch (e) {
              dialog.showErrorBox('Update check failed', e?.message || String(e));
            } finally {
              // reset after the cycle
              setTimeout(() => {
                manualUpdateCheck = false;
              }, 5000);
            }
          },
        },
        { type: 'separator' },
        { role: 'quit' },
      ],
    },
    {
      label: 'View',
      submenu: [
        { role: 'reload' },
        {
          label: 'Toggle Developer Tools',
          accelerator: 'Ctrl+Shift+I',
          click: () => {
            const w = BrowserWindow.getFocusedWindow() || mainWindow;
            if (w) w.webContents.toggleDevTools();
          },
        },
        { type: 'separator' },
        { role: 'resetzoom' },
        { role: 'zoomin' },
        { role: 'zoomout' },
        { type: 'separator' },
        { role: 'togglefullscreen' },
      ],
    },
    {
      label: 'Help',
      submenu: [
        {
          label: 'Project site',
          click: async () => shell.openExternal('https://github.com'),
        },
      ],
    },
  ];

  const menu = Menu.buildFromTemplate(template);
  Menu.setApplicationMenu(menu);
}

function wireAutoUpdater() {
  // Show simple UI for updates.
  autoUpdater.on('error', (err) => {
    console.error('autoUpdater error:', err);
  });

  autoUpdater.on('update-available', async (info) => {
    const res = await dialog.showMessageBox({
      type: 'info',
      buttons: ['Download', 'Later'],
      defaultId: 0,
      cancelId: 1,
      title: 'Update available',
      message: `Version ${info.version} is available. Download now?`,
      detail: 'Fantasy Edge will prompt to install after the download completes.',
    });

    if (res.response === 0) {
      autoUpdater.downloadUpdate();
    }
  });

  autoUpdater.on('update-not-available', async (info) => {
    if (!manualUpdateCheck) return;
    await dialog.showMessageBox({
      type: 'info',
      buttons: ['OK'],
      title: 'No updates',
      message: `You are up to date (v${info.version}).`,
    });
  });

  autoUpdater.on('update-downloaded', async (info) => {
    const res = await dialog.showMessageBox({
      type: 'info',
      buttons: ['Install and restart', 'Later'],
      defaultId: 0,
      cancelId: 1,
      title: 'Update ready',
      message: `Version ${info.version} has been downloaded. Install now?`,
    });

    if (res.response === 0) {
      autoUpdater.quitAndInstall();
    }
  });
}

async function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1300,
    height: 900,
    webPreferences: {
      // Keep Node out of the renderer by default.
      nodeIntegration: false,
      contextIsolation: true,
    },
  });

  // Better diagnostics for "white screen" scenarios
  mainWindow.webContents.on('did-fail-load', (_event, errorCode, errorDesc, validatedURL) => {
    console.error('did-fail-load', { errorCode, errorDesc, validatedURL });
  });
  mainWindow.webContents.on('render-process-gone', (_event, details) => {
    console.error('render-process-gone', details);
  });
  mainWindow.webContents.on('console-message', (_event, level, message, line, sourceId) => {
    console.log('[renderer]', { level, message, line, sourceId });
  });

  let startUrl;
  try {
    startUrl = isDev
      ? process.env.NEXT_DEV_URL || 'http://localhost:3000'
      : await startNextServer();
  } catch (e) {
    const msg = e?.stack || e?.message || String(e);
    console.error('Failed to start Next server:', msg);
    dialog.showErrorBox('Failed to start app', msg);
    startUrl = `data:text/html,${encodeURIComponent(
      `<h2>Failed to start app</h2><pre style=\"white-space:pre-wrap\">${msg}</pre>`
    )}`;
  }

  await mainWindow.loadURL(startUrl);

  // Force DevTools available in production while we’re stabilizing packaged builds.
  try {
    mainWindow.webContents.openDevTools({ mode: 'detach' });
  } catch {
    // ignore
  }

  mainWindow.on('closed', () => {
    mainWindow = null;
  });
}

app.whenReady().then(async () => {
  createMenu();
  wireAutoUpdater();
  await createWindow();

  // Auto-update check on startup (packaged builds only)
  if (!isDev) {
    try {
      autoUpdater.autoDownload = false;
      await autoUpdater.checkForUpdates();
    } catch (e) {
      console.error('Startup update check failed:', e);
    }
  }

  app.on('activate', async () => {
    if (BrowserWindow.getAllWindows().length === 0) await createWindow();
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

app.on('before-quit', () => {
  if (server) {
    try {
      server.close();
    } catch {
      // ignore
    }
  }
});
