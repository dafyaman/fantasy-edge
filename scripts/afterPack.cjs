const fs = require('fs');
const path = require('path');

// electron-builder calls this with a context object
exports.default = async function afterPack(context) {
  const asar = require('asar');

  const asarPath = path.join(context.appOutDir, 'resources', 'app.asar');
  if (!fs.existsSync(asarPath)) {
    console.warn('[afterPack] app.asar not found, skipping:', asarPath);
    return;
  }

  const tmpDir = path.join(context.appOutDir, 'resources', '__asar_tmp__');
  fs.rmSync(tmpDir, { recursive: true, force: true });
  fs.mkdirSync(tmpDir, { recursive: true });

  // Extract existing asar
  asar.extractAll(asarPath, tmpDir);

  // Ensure root package.json exists in the archive
  const appDir = context.appDir || context.packager?.appDir || context.packager?.projectDir;
  if (!appDir) {
    console.warn('[afterPack] could not resolve appDir from context; skipping injection');
    return;
  }

  // If we only got projectDir, prefer the staged app/ directory.
  const candidateAppDir = fs.existsSync(path.join(appDir, 'package.json')) ? appDir : path.join(appDir, 'app');
  const sourcePkg = path.join(candidateAppDir, 'package.json');
  const destPkg = path.join(tmpDir, 'package.json');

  if (!fs.existsSync(sourcePkg)) {
    throw new Error(`[afterPack] Expected app package.json missing at ${sourcePkg}`);
  }

  fs.copyFileSync(sourcePkg, destPkg);

  // Repack
  fs.rmSync(asarPath, { force: true });
  await asar.createPackage(tmpDir, asarPath);

  // Cleanup
  fs.rmSync(tmpDir, { recursive: true, force: true });

  console.log('[afterPack] injected package.json into app.asar');
};
