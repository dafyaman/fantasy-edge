const { app, BrowserWindow, Menu, dialog, shell } = require('electron');
const path = require('path');
const http = require('http');
const isDev = !app.isPackaged;

// Auto-update (GitHub Releases)
const { autoUpdater } = require('electron-updater');

let mainWindow;
let server;

async function startNextServer() {
  // In production we run the Next.js app *inside* Electron (no separate process).
  // We keep the built Next output in an extraResources folder so it is readable outside app.asar.
  const next = require('next');
  const getPort = (await import('get-port')).default;

  const port = await getPort({ port: [3030, 3031, 3032, 3033, 3034, 3035] });

  const nextDir = isDev
    ? path.join(__dirname, '..')
    : path.join(process.resourcesPath, 'next');

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
              autoUpdater.autoDownload = false;
              await autoUpdater.checkForUpdates();
            } catch (e) {
              dialog.showErrorBox('Update check failed', e?.message || String(e));
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
        { role: 'toggledevtools', visible: isDev },
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
    // Only show a dialog when user explicitly checks.
    // electron-updater triggers this for both startup and manual checks.
    // We'll keep it quiet on startup by using checkForUpdatesAndNotify only when packaged.
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

  const startUrl = isDev
    ? process.env.NEXT_DEV_URL || 'http://localhost:3000'
    : await startNextServer();

  await mainWindow.loadURL(startUrl);

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
