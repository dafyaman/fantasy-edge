# Fantasy Edge Desktop (Electron)

This project wraps the existing **Next.js Fantasy Edge app** in an Electron shell and supports **auto-updates via GitHub Releases**.

## Requirements
- Node.js (v18+ recommended; this repo currently runs on v24)
- Windows (for building the `.exe` NSIS installer)
- GitHub repo + Releases (for auto-update)

## Run desktop in development
This runs the Next.js dev server on `http://localhost:3000` and opens Electron pointed at it.

```bash
cd fantasy-edge-app
npm install
npm run dev:desktop
```

Notes:
- DevTools are available in the **View** menu.
- You can override the dev URL:
  ```bash
  set NEXT_DEV_URL=http://localhost:3000
  npm run dev:electron
  ```

## Build Windows installer (.exe)
This builds the Next app and then packages Electron into an NSIS installer.

```bash
cd fantasy-edge-app
npm install
npm run dist:win
```

Output:
- `dist-electron/` contains the `.exe` installer and supporting artifacts.

## Auto-update behavior
- On startup (packaged builds only), the app calls `autoUpdater.checkForUpdates()`.
- The menu has: **Fantasy Edge → Check for updates…**
- When an update is available, it prompts to download, then prompts to install.

## Publish an update (GitHub Releases)
Auto-update uses **electron-updater** + **GitHub Releases**.

### 1) Create/Set GitHub repository
Electron-updater needs a repo to publish to. Set `repository` in `package.json`:

```json
"repository": {
  "type": "git",
  "url": "https://github.com/<OWNER>/<REPO>.git"
}
```

Also ensure the `build.publish` section remains:

```json
"publish": [{ "provider": "github", "releaseType": "release" }]
```

### 2) Set GitHub token (DO NOT COMMIT)
Create a GitHub Personal Access Token (classic) with `repo` scope.

Set it in your shell as `GH_TOKEN` (electron-builder will read it):

**PowerShell**
```powershell
$env:GH_TOKEN = "YOUR_TOKEN_HERE"
```

### 3) Bump version
Bump the app version in `package.json` (SemVer):

- `0.1.0` → `0.1.1` (patch)
- `0.1.0` → `0.2.0` (minor)

### 4) Build + publish
```bash
npm run publish:win
```

This will:
- build Next (`next build`)
- build the Windows installer
- create/update a GitHub Release
- upload artifacts (`.exe`, `latest.yml`, etc.)

Clients will see the update on next startup (or via menu).

## Security / tokens
- **Never commit tokens** (`GH_TOKEN`, API keys, etc.).
- Put secrets in environment variables or `.env.local` (already typically ignored by Next.js).

## Implementation notes
- The packaged app runs the Next.js server **in-process** (no separate `next start` process).
- Next build output (`.next/`) and `public/` are copied into the packaged app at `resources/next/` via `electron-builder.extraResources`.
