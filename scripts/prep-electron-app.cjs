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

// Copy node_modules so the packaged app can run without reinstalling.
// This is heavier than ideal, but reliable for now.
const srcNodeModules = path.join(projectRoot, 'node_modules');
const dstNodeModules = path.join(outDir, 'node_modules');

if (!fs.existsSync(srcNodeModules)) {
  throw new Error('node_modules not found. Run `npm install` first.');
}

console.log('[prep-electron-app] copying node_modules -> app/node_modules (may take a minute)');
// robocopy exit codes: 0-7 are success.
const args = [
  srcNodeModules,
  dstNodeModules,
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

// robocopy exit codes 0-7 are success (0 = nothing copied)
// https://learn.microsoft.com/windows-server/administration/windows-commands/robocopy#return-codes
const res = spawnSync('robocopy', args, { stdio: 'inherit', windowsHide: true });
const code = res.status ?? 16;
if (code > 7) {
  console.error(`[prep-electron-app] robocopy failed with exit code ${code}`);
  process.exit(code);
}

process.exitCode = 0;

console.log('[prep-electron-app] done');
