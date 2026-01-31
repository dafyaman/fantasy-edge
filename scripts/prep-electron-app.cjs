const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const projectRoot = path.resolve(__dirname, '..');
const outDir = path.join(projectRoot, 'app');

function rmrf(p) {
  fs.rmSync(p, { recursive: true, force: true });
}

function mkdirp(p) {
  fs.mkdirSync(p, { recursive: true });
}

function copyFile(src, dest) {
  mkdirp(path.dirname(dest));
  fs.copyFileSync(src, dest);
}

function readJson(p) {
  return JSON.parse(fs.readFileSync(p, 'utf8'));
}

function writeJson(p, obj) {
  mkdirp(path.dirname(p));
  fs.writeFileSync(p, JSON.stringify(obj, null, 2) + '\n');
}

console.log('[prep-electron-app] staging app/ ...');

// Don’t nuke app/ every run — deleting huge node_modules trees is slow and can look like a hang.
// Instead, ensure the folder exists and let robocopy mirror/update.
mkdirp(outDir);

// Copy Electron main process entry
copyFile(path.join(projectRoot, 'electron', 'main.cjs'), path.join(outDir, 'electron', 'main.cjs'));

// Create a minimal package.json that MUST exist at the root of app.asar
const rootPkg = readJson(path.join(projectRoot, 'package.json'));

const appPkg = {
  name: rootPkg.name || 'fantasy-edge-app',
  version: rootPkg.version || '0.0.0',
  private: true,
  main: 'electron/main.cjs',
  dependencies: rootPkg.dependencies || {},
};

writeJson(path.join(outDir, 'package.json'), appPkg);

function robocopyMirror(src, dest) {
  if (!fs.existsSync(src)) {
    throw new Error(`Missing path: ${src}`);
  }
  const args = [
    src,
    dest,
    '/MIR',
    '/MT:8',
    '/R:1',
    '/W:1',
    '/NFL',
    '/NDL',
    '/NJH',
    '/NJS',
    '/NP',
  ];
  const res = spawnSync('robocopy', args, { stdio: 'inherit', windowsHide: true });
  const code = res.status ?? 16;
  if (code > 7) {
    console.error(`[prep-electron-app] robocopy failed (${code}) copying ${src} -> ${dest}`);
    process.exit(code);
  }
}

// Copy node_modules so the packaged app can run without reinstalling.
console.log('[prep-electron-app] copying node_modules -> app/node_modules (may take a minute)');
robocopyMirror(path.join(projectRoot, 'node_modules'), path.join(outDir, 'node_modules'));

// Copy Next build output *into app.asar* (under app/next/...) so module resolution works.
console.log('[prep-electron-app] copying .next -> app/next/.next');
robocopyMirror(path.join(projectRoot, '.next'), path.join(outDir, 'next', '.next'));

console.log('[prep-electron-app] copying public -> app/next/public');
robocopyMirror(path.join(projectRoot, 'public'), path.join(outDir, 'next', 'public'));

// Copy next config into app/next so Next can load config from that dir.
const nextConfig = path.join(projectRoot, 'next.config.ts');
if (fs.existsSync(nextConfig)) {
  copyFile(nextConfig, path.join(outDir, 'next', 'next.config.ts'));
}

process.exitCode = 0;

console.log('[prep-electron-app] done');
