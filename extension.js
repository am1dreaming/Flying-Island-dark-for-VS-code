// Flying Island — VS Code patcher.
//
// 1. Island geometry: inlines css/islands.css into workbench.html.
// 2. Vibrancy (optional): makes the main window transparent with a native
//    material (macOS NSVisualEffectView vibrancy, Windows 11 acrylic / mica)
//    by patching the BrowserWindow creation in out/mainImpl.js, and appends
//    css/vibrancy.css so the window chrome lets the blur show through.
//
// Runs inside VS Code itself, so macOS App Management allows the writes.
// Both patches are re-applied automatically after VS Code updates.
const vscode = require("vscode");
const fs = require("fs");
const os = require("os");
const path = require("path");

const NAME = "Flying Island";
const SECTION = "flyingIsland";
const HTML_START = "<!-- flying-island:start -->";
const HTML_END = "<!-- flying-island:end -->";
const JS_START = "/*isl:s*/";
const JS_ORIG = "/*isl:o ";
const JS_END = " isl:e*/";
const CONFIG_DIR = ".flying-island";
const CONFIG_FILE = path.join(os.homedir(), CONFIG_DIR, "vibrancy.json");
// Backups keep the pre-rename name: the first backup is the pristine VS Code file.
const BACKUP_SUFFIX = ".bak-islands";

// The extension used to be "Islands Dark (CLion)". Its blocks, settings and
// theme label are migrated so the two never fight over workbench.html.
const LEGACY = {
  extensionId: "yaroslav.islands-dark-clion",
  section: "islandsDark",
  theme: "Islands Dark",
  html: ["<!-- islands-dark:start -->", "<!-- islands-dark:end -->"],
  configFile: path.join(os.homedir(), ".islands-dark", "vibrancy.json"),
};
const THEME = "Flying Island Dark";

const MAC_MATERIALS = ["sidebar", "under-window", "hud", "window", "content", "fullscreen-ui"];
const WIN_MATERIALS = ["acrylic", "mica", "tabbed"];

// ------------------------------------------------------------------ paths
// VS Code moved the workbench from electron-sandbox (<= ~1.10x) to electron-browser.
function workbenchHtml() {
  const candidates = ["electron-browser", "electron-sandbox"].map((dir) =>
    path.join(vscode.env.appRoot, "out", "vs", "code", dir, "workbench", "workbench.html")
  );
  return candidates.find((f) => fs.existsSync(f)) || candidates[0];
}

function mainJs() {
  const candidates = ["mainImpl.js", "main.js"].map((f) => path.join(vscode.env.appRoot, "out", f));
  return candidates.find((f) => fs.existsSync(f) && /\.BrowserWindow\([\w$]+\)/.test(fs.readFileSync(f, "utf8")));
}

// ----------------------------------------------------------------- config
// backgroundMaterial needs Windows 11 22H2 (build 22621); older Windows would
// just get a black transparent frame, so vibrancy stays off there.
function isWin11() {
  return parseInt(os.release().split(".")[2] || "0", 10) >= 22621;
}

function settings() {
  const cfg = vscode.workspace.getConfiguration(SECTION);
  const requested = cfg.get("vibrancy", "off");
  const opacity = Math.min(1, Math.max(0.3, cfg.get("vibrancyOpacity", 0.4)));
  let material = "off";
  if (requested !== "off") {
    if (process.platform === "darwin") material = MAC_MATERIALS.includes(requested) ? requested : "under-window";
    else if (process.platform === "win32" && isWin11()) material = WIN_MATERIALS.includes(requested) ? requested : "acrylic";
  }
  return { autoApply: cfg.get("autoApply", true), material, opacity, geometry: geometry(cfg) };
}

// Island geometry in px: [setting key, default, min, max] (ranges as in package.json).
const GEOMETRY = {
  gap: ["gap", 4, 0, 16],
  radius: ["radius", 10, 0, 20],
  top: ["margin.top", 0, 0, 16],
  right: ["margin.right", 7, 0, 16],
  bottom: ["margin.bottom", 4, 0, 6],
  left: ["margin.left", 0, 0, 16],
};

function geometry(cfg) {
  const g = {};
  for (const [k, [key, def, min, max]] of Object.entries(GEOMETRY)) {
    const v = Number(cfg.get(key, def));
    g[k] = Number.isFinite(v) ? Math.min(max, Math.max(min, Math.round(v * 2) / 2)) : def;
  }
  return g;
}

function geometryCss(g) {
  return (
    `:root { --isl-gap: ${g.gap}px; --isl-half: ${g.gap / 2}px; --isl-radius: ${g.radius}px; ` +
    `--isl-top: ${g.top}px; --isl-right: ${g.right}px; --isl-bottom: ${g.bottom}px; --isl-left: ${g.left}px; }\n`
  );
}

// --------------------------------------------------------- workbench.html
function stripHtml(html) {
  for (const [start, end] of [[HTML_START, HTML_END], LEGACY.html]) {
    const s = html.indexOf(start);
    if (s < 0) continue;
    const e = html.indexOf(end, s);
    // The block is inserted right before </head>: keep the text before it as is
    // (workbench.html uses CRLF) and drop only the indent the block added.
    html = html.slice(0, s) + html.slice(e + end.length).replace(/^\s*/, "");
  }
  return html;
}

function buildHtml(context, html, { material, opacity, geometry: g = geometry({ get: (_, d) => d }) }) {
  let css = fs.readFileSync(path.join(context.extensionPath, "css", "islands.css"), "utf8");
  css += `\n${geometryCss(g)}`;
  if (material !== "off") {
    css += `\n:root { --isl-vib-alpha: ${opacity}; }\n`;
    css += fs.readFileSync(path.join(context.extensionPath, "css", "vibrancy.css"), "utf8");
  }
  const block = `${HTML_START}\n\t\t<style id="flying-island">\n${css}\n\t\t</style>\n\t\t${HTML_END}\n\t`;
  return stripHtml(html).replace("</head>", () => block + "</head>");
}

// ------------------------------------------------------------ mainImpl.js
// Injected before `this._win=new X.BrowserWindow(opts)`: reads the material
// from ~/.flying-island/vibrancy.json (so switching needs no re-patch), sets
// the native material and stops VS Code from repainting an opaque background.
function vibrancyHook(opts) {
  return (
    `((o)=>{try{const fs=process.getBuiltinModule("fs"),p=process.getBuiltinModule("path"),os=process.getBuiltinModule("os");` +
    `const c=JSON.parse(fs.readFileSync(p.join(os.homedir(),"${CONFIG_DIR}","vibrancy.json"),"utf8"));` +
    `if(!c||!c.material||c.material==="off")return;` +
    `if(process.platform==="darwin"){o.transparent=!0;o.vibrancy=c.material;o.visualEffectState="active"}` +
    `else if(process.platform==="win32"&&parseInt(os.release().split(".")[2]||"0",10)>=22621){o.backgroundMaterial=c.material}` +
    `else return;globalThis.__islVib=!0;o.backgroundColor="#00000000"}catch{}})(${opts})`
  );
}

function stripJs(js) {
  return js.replace(/\/\*isl:s\*\/[\s\S]*?\/\*isl:o ([\s\S]*?) isl:e\*\//g, "$1");
}

function buildJs(js) {
  const clean = stripJs(js);
  // Minified identifiers may contain "$", which \w does not match.
  const m = clean.match(/this\._win=new ([\w$]+)\.BrowserWindow\(([\w$]+)\)/);
  if (!m) return null;
  const [orig, , opts] = m;
  const patched =
    `${JS_START}${vibrancyHook(opts)},${orig},globalThis.__islVib&&(this._win.setBackgroundColor=()=>{})` +
    `${JS_ORIG}${orig}${JS_END}`;
  return clean.replace(orig, () => patched); // function: "$" in identifiers stays literal
}

// ------------------------------------------------------------------ apply
function writeIfChanged(file, next, prev) {
  if (next === prev) return false;
  const backup = file + BACKUP_SUFFIX;
  if (!fs.existsSync(backup)) fs.writeFileSync(backup, prev);
  fs.writeFileSync(file, next);
  return true;
}

function writeVibrancyConfig(material) {
  const next = JSON.stringify({ material }) + "\n";
  const prev = fs.existsSync(CONFIG_FILE) ? fs.readFileSync(CONFIG_FILE, "utf8") : JSON.stringify({ material: "off" }) + "\n";
  if (prev === next) return false;
  fs.mkdirSync(path.dirname(CONFIG_FILE), { recursive: true });
  fs.writeFileSync(CONFIG_FILE, next);
  return true;
}

async function apply(context, { silent } = {}) {
  const cfg = settings();
  let reloadNeeded = false;
  let restartNeeded = false;

  try {
    const file = workbenchHtml();
    const html = fs.readFileSync(file, "utf8");
    reloadNeeded = writeIfChanged(file, buildHtml(context, html, cfg), html);
  } catch (err) {
    vscode.window.showErrorMessage(`${NAME}: cannot patch workbench.html: ${err.message}`);
    return;
  }

  try {
    const file = mainJs();
    const js = file && fs.readFileSync(file, "utf8");
    // An existing hook is refreshed even with glass off, so a hook left by an
    // older version never keeps reading a stale config file.
    if (cfg.material !== "off" || (js && js.includes(JS_START))) {
      const next = js && buildJs(js);
      if (!next) throw new Error("BrowserWindow creation not found (unsupported VS Code build)");
      restartNeeded = writeIfChanged(file, next, js);
    }
    restartNeeded = writeVibrancyConfig(cfg.material) || restartNeeded;
  } catch (err) {
    vscode.window.showErrorMessage(`${NAME}: vibrancy unavailable: ${err.message}`);
  }

  if (restartNeeded) {
    const choice = await vscode.window.showInformationMessage(
      `${NAME}: window material changed. Quit VS Code and open it again to apply.`,
      "Quit VS Code"
    );
    if (choice) vscode.commands.executeCommand("workbench.action.quit");
  } else if (reloadNeeded) {
    const choice = await vscode.window.showInformationMessage(`${NAME}: styles updated. Reload to see them.`, "Reload Window");
    if (choice) vscode.commands.executeCommand("workbench.action.reloadWindow");
  } else if (!silent) {
    vscode.window.showInformationMessage(`${NAME}: everything is already applied.`);
  }
}

async function remove() {
  try {
    const html = workbenchHtml();
    const h = fs.readFileSync(html, "utf8");
    const stripped = stripHtml(h);
    if (stripped !== h) fs.writeFileSync(html, stripped);
    const js = mainJs();
    if (js) {
      const j = fs.readFileSync(js, "utf8");
      if (j.includes(JS_START)) fs.writeFileSync(js, stripJs(j));
    }
    for (const f of [CONFIG_FILE, LEGACY.configFile]) {
      if (fs.existsSync(f)) fs.writeFileSync(f, JSON.stringify({ material: "off" }) + "\n");
    }
    const choice = await vscode.window.showInformationMessage(
      `${NAME}: all patches removed. Quit VS Code and open it again to restore the stock window.`,
      "Quit VS Code"
    );
    if (choice) vscode.commands.executeCommand("workbench.action.quit");
  } catch (err) {
    vscode.window.showErrorMessage(`${NAME}: cannot remove patches: ${err.message}`);
  }
}

// -------------------------------------------------------------- migration
async function migrateFromLegacy() {
  const root = vscode.workspace.getConfiguration();
  const g = vscode.ConfigurationTarget.Global;
  try {
    for (const key of ["autoApply", "vibrancy", "vibrancyOpacity"]) {
      const old = root.inspect(`${LEGACY.section}.${key}`);
      const cur = root.inspect(`${SECTION}.${key}`);
      if (old && old.globalValue !== undefined && cur && cur.globalValue === undefined) {
        await root.update(`${SECTION}.${key}`, old.globalValue, g);
      }
    }
    if (root.inspect("workbench.colorTheme")?.globalValue === LEGACY.theme) {
      await root.update("workbench.colorTheme", THEME, g);
    }
  } catch (err) {
    console.warn(`${NAME}: settings migration skipped: ${err.message}`);
  }
  // Both extensions active would keep re-adding their own <style> block.
  if (vscode.extensions.getExtension(LEGACY.extensionId)) {
    try {
      await vscode.commands.executeCommand("workbench.extensions.uninstallExtension", LEGACY.extensionId);
      vscode.window.showInformationMessage(`${NAME}: removed the old "Islands Dark (CLion)" extension it replaces.`);
    } catch (err) {
      vscode.window.showWarningMessage(
        `${NAME}: please uninstall the old "Islands Dark (CLion)" extension (${LEGACY.extensionId}); it conflicts with this one.`
      );
    }
  }
}

async function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand(`${SECTION}.apply`, () => apply(context)),
    vscode.commands.registerCommand(`${SECTION}.remove`, remove)
  );
  // Migrate first: the settings it copies over must not trigger a second apply.
  await migrateFromLegacy();
  context.subscriptions.push(
    vscode.workspace.onDidChangeConfiguration((e) => {
      if (e.affectsConfiguration(SECTION)) apply(context, { silent: true });
    })
  );
  if (settings().autoApply) apply(context, { silent: true });
}

module.exports = { activate, deactivate() {} };
