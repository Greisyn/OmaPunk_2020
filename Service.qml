pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "CyberSheet.js" as CyberSheet

// Owns Cyberpunk 2020 character data, renders plain text (same sections as the
// CP2020 Character Sheet Ultimate Edition PDF), exports to the user-chosen
// output path, mounts one corner-anchored SheetWindow per screen.
// Theme-awareness lives in the windows (Color/Style).
Item {
  id: root
  property var shell: null
  property var manifest: null
  readonly property string pluginId: (manifest && manifest.id) ? String(manifest.id) : "local.cyberpunk-sheet"

  SheetConfig { id: config }

  readonly property string home: Quickshell.env("HOME")
  readonly property string characterPath: home + "/.config/omarchy/local.cyberpunk-sheet-character.json"

  // ---- identity (blank sheet: everything empty) ----
  property string charName: ""
  property string role: ""
  property string characterPoints: ""
  property string age: ""
  property string rep: ""
  property string humanity: ""
  property string currentIP: ""
  property string money: ""
  property string siblings: ""

  // ---- stats: blank sheet = 0 ----
  property int statINT: 0; property int statREF: 0; property int statTECH: 0
  property int statCOOL: 0; property int statATTR: 0; property int statLUCK: 0
  property int statMA: 0; property int statBODY: 0; property int statEMP: 0

  // ---- armor SP per location: blank sheet = 0 ----
  property int armorHead: 0; property int armorTorso: 0
  property int armorRArm: 0; property int armorLArm: 0
  property int armorRLeg: 0; property int armorLLeg: 0

  // ---- wound boxes marked: blank sheet = 0 ----
  property int dmgLight: 0; property int dmgSerious: 0
  property int dmgCritical: 0; property int dmgMortal: 0

  // ---- special ability ----
  property string specName: ""
  property int specLevel: 0

  // ---- ATTR skills ----
  property int personalGrooming: 0; property int wardrobeStyle: 0
  // ---- BODY skills ----
  property int endurance: 0; property int strengthFeat: 0; property int swimming: 0
  // ---- COOL skills ----
  property int interrogation: 0; property int intimidate: 0; property int oratory: 0
  property int resistTorture: 0; property int streetwise: 0
  // ---- EMPATHY skills ----
  property int humanPerception: 0; property int interview: 0; property int leadership: 0
  property int seduction: 0; property int social: 0; property int persuasion: 0
  property int perform: 0
  // ---- INT skills ----
  property int accounting: 0; property int anthropology: 0; property int awareness: 0
  property int biology: 0; property int botany: 0; property int chemistry: 0
  property int composition: 0; property int diagnose: 0; property int education: 0
  property int gamble: 0; property int geology: 0; property int hideEvade: 0
  property int history: 0; property int librarySearch: 0; property int mathematics: 0
  property int physics: 0; property int programming: 0; property int shadowTrack: 0
  property int stockMarket: 0; property int systemKnowledge: 0; property int teaching: 0
  property int wilderness: 0; property int zoology: 0
  // ---- REF skills ----
  property int archery: 0; property int athletics: 0; property int brawling: 0
  property int dance: 0; property int dodge: 0; property int driving: 0
  property int fencing: 0; property int handgun: 0; property int heavyWeapons: 0
  property int melee: 0; property int motorcycle: 0; property int operateHvy: 0
  property int pilotGyro: 0; property int pilotFixed: 0; property int pilotDirigible: 0
  property int pilotVector: 0; property int rifle: 0; property int stealth: 0
  property int submachinegun: 0
  // ---- TECH skills ----
  property int aeroTech: 0; property int avTech: 0; property int basicTech: 0
  property int cryotank: 0; property int cyberdeckDesign: 0; property int cyberTech: 0
  property int demolitions: 0; property int disguise: 0; property int electSecurity: 0
  property int electronics: 0; property int firstAid: 0; property int forgery: 0
  property int gyroTech: 0; property int paintDraw: 0; property int photoFilm: 0
  property int pharma: 0; property int pickLock: 0; property int pickPocket: 0
  property int playInstrument: 0; property int weaponsmith: 0; property int weaponsTech: 0

  // ---- named skills (free-text name + level) ----
  property string language1Name: ""; property int language1: 0
  property string language2Name: ""; property int language2: 0
  property string language3Name: ""; property int language3: 0
  property string expertName: ""; property int expert: 0
  property string martial1Name: ""; property int martial1: 0
  property string martial2Name: ""; property int martial2: 0
  property string martial3Name: ""; property int martial3: 0
  property string otherAName: ""; property int otherA: 0
  property string otherBName: ""; property int otherB: 0
  property string otherCName: ""; property int otherC: 0

  // ---- skill specializations: star flag + subtext per skill ----
  property bool personalGroomingSpec: false; property string personalGroomingSpecText: "";
  property bool wardrobeStyleSpec: false; property string wardrobeStyleSpecText: "";
  property bool enduranceSpec: false; property string enduranceSpecText: "";
  property bool strengthFeatSpec: false; property string strengthFeatSpecText: "";
  property bool swimmingSpec: false; property string swimmingSpecText: "";
  property bool interrogationSpec: false; property string interrogationSpecText: "";
  property bool intimidateSpec: false; property string intimidateSpecText: "";
  property bool oratorySpec: false; property string oratorySpecText: "";
  property bool resistTortureSpec: false; property string resistTortureSpecText: "";
  property bool streetwiseSpec: false; property string streetwiseSpecText: "";
  property bool humanPerceptionSpec: false; property string humanPerceptionSpecText: "";
  property bool interviewSpec: false; property string interviewSpecText: "";
  property bool leadershipSpec: false; property string leadershipSpecText: "";
  property bool seductionSpec: false; property string seductionSpecText: "";
  property bool socialSpec: false; property string socialSpecText: "";
  property bool persuasionSpec: false; property string persuasionSpecText: "";
  property bool performSpec: false; property string performSpecText: "";
  property bool accountingSpec: false; property string accountingSpecText: "";
  property bool anthropologySpec: false; property string anthropologySpecText: "";
  property bool awarenessSpec: false; property string awarenessSpecText: "";
  property bool biologySpec: false; property string biologySpecText: "";
  property bool botanySpec: false; property string botanySpecText: "";
  property bool chemistrySpec: false; property string chemistrySpecText: "";
  property bool compositionSpec: false; property string compositionSpecText: "";
  property bool diagnoseSpec: false; property string diagnoseSpecText: "";
  property bool educationSpec: false; property string educationSpecText: "";
  property bool gambleSpec: false; property string gambleSpecText: "";
  property bool geologySpec: false; property string geologySpecText: "";
  property bool hideEvadeSpec: false; property string hideEvadeSpecText: "";
  property bool historySpec: false; property string historySpecText: "";
  property bool librarySearchSpec: false; property string librarySearchSpecText: "";
  property bool mathematicsSpec: false; property string mathematicsSpecText: "";
  property bool physicsSpec: false; property string physicsSpecText: "";
  property bool programmingSpec: false; property string programmingSpecText: "";
  property bool shadowTrackSpec: false; property string shadowTrackSpecText: "";
  property bool stockMarketSpec: false; property string stockMarketSpecText: "";
  property bool systemKnowledgeSpec: false; property string systemKnowledgeSpecText: "";
  property bool teachingSpec: false; property string teachingSpecText: "";
  property bool wildernessSpec: false; property string wildernessSpecText: "";
  property bool zoologySpec: false; property string zoologySpecText: "";
  property bool archerySpec: false; property string archerySpecText: "";
  property bool athleticsSpec: false; property string athleticsSpecText: "";
  property bool brawlingSpec: false; property string brawlingSpecText: "";
  property bool danceSpec: false; property string danceSpecText: "";
  property bool dodgeSpec: false; property string dodgeSpecText: "";
  property bool drivingSpec: false; property string drivingSpecText: "";
  property bool fencingSpec: false; property string fencingSpecText: "";
  property bool handgunSpec: false; property string handgunSpecText: "";
  property bool heavyWeaponsSpec: false; property string heavyWeaponsSpecText: "";
  property bool meleeSpec: false; property string meleeSpecText: "";
  property bool motorcycleSpec: false; property string motorcycleSpecText: "";
  property bool operateHvySpec: false; property string operateHvySpecText: "";
  property bool pilotGyroSpec: false; property string pilotGyroSpecText: "";
  property bool pilotFixedSpec: false; property string pilotFixedSpecText: "";
  property bool pilotDirigibleSpec: false; property string pilotDirigibleSpecText: "";
  property bool pilotVectorSpec: false; property string pilotVectorSpecText: "";
  property bool rifleSpec: false; property string rifleSpecText: "";
  property bool stealthSpec: false; property string stealthSpecText: "";
  property bool submachinegunSpec: false; property string submachinegunSpecText: "";
  property bool aeroTechSpec: false; property string aeroTechSpecText: "";
  property bool avTechSpec: false; property string avTechSpecText: "";
  property bool basicTechSpec: false; property string basicTechSpecText: "";
  property bool cryotankSpec: false; property string cryotankSpecText: "";
  property bool cyberdeckDesignSpec: false; property string cyberdeckDesignSpecText: "";
  property bool cyberTechSpec: false; property string cyberTechSpecText: "";
  property bool demolitionsSpec: false; property string demolitionsSpecText: "";
  property bool disguiseSpec: false; property string disguiseSpecText: "";
  property bool electSecuritySpec: false; property string electSecuritySpecText: "";
  property bool electronicsSpec: false; property string electronicsSpecText: "";
  property bool firstAidSpec: false; property string firstAidSpecText: "";
  property bool forgerySpec: false; property string forgerySpecText: "";
  property bool gyroTechSpec: false; property string gyroTechSpecText: "";
  property bool paintDrawSpec: false; property string paintDrawSpecText: "";
  property bool photoFilmSpec: false; property string photoFilmSpecText: "";
  property bool pharmaSpec: false; property string pharmaSpecText: "";
  property bool pickLockSpec: false; property string pickLockSpecText: "";
  property bool pickPocketSpec: false; property string pickPocketSpecText: "";
  property bool playInstrumentSpec: false; property string playInstrumentSpecText: "";
  property bool weaponsmithSpec: false; property string weaponsmithSpecText: "";
  property bool weaponsTechSpec: false; property string weaponsTechSpecText: "";
  property bool language1Spec: false; property string language1SpecText: "";
  property bool language2Spec: false; property string language2SpecText: "";
  property bool language3Spec: false; property string language3SpecText: "";
  property bool expertSpec: false; property string expertSpecText: "";
  property bool martial1Spec: false; property string martial1SpecText: "";
  property bool martial2Spec: false; property string martial2SpecText: "";
  property bool martial3Spec: false; property string martial3SpecText: "";
  property bool otherASpec: false; property string otherASpecText: "";
  property bool otherBSpec: false; property string otherBSpecText: "";
  property bool otherCSpec: false; property string otherCSpecText: "";

  // ---- multiline texts ----
  property string cybernetics: ""
  property string totalHL: ""
  property string totalCost: ""
  property string style: ""
  property string clothes: ""
  property string hair: ""
  property string affections: ""
  property string ethnicity: ""
  property string lifepathLang: ""
  property string familyBg: ""
  property string motivations: ""
  property string traits: ""
  property string valuedPerson: ""
  property string valueMost: ""
  property string feelPeople: ""
  property string valuedPoss: ""
  property string lifeEvents: ""
  property string gear: ""
  property string weapons: ""
  property string chipped: ""
  property string ooc: ""

  property string status: "Ready"
  property bool dataLoaded: false
  property string lastSavedText: ""

  // ---- derived stats for the sheet header (CP2020 core rules) ----
  function derivedRun() { return Math.max(1, parseInt(statMA, 10) || 1) * 3; }
  function derivedLeap() { return Math.round(root.derivedRun() / 4); }
  function derivedCarry() { return (Math.max(1, parseInt(statBODY, 10) || 1)) * 10; }
  function derivedLift() { return (Math.max(1, parseInt(statBODY, 10) || 1)) * 40; }
  function derivedSave() { return Math.max(1, parseInt(statBODY, 10) || 1); }
  function derivedBTM() {
    var b = Math.max(1, parseInt(statBODY, 10) || 1);
    if (b >= 11) return -5;
    if (b >= 9) return -4;
    if (b >= 7) return -3;
    if (b >= 5) return -2;
    if (b >= 3) return -1;
    return 0;
  }

  function snapshot() {
    var d = CyberSheet.defaultData();
    var keys = Object.keys(d);
    for (var i = 0; i < keys.length; i++) {
      var k = keys[i];
      if (root[k] !== undefined) d[k] = root[k];
    }
    return d;
  }

  function applyData(d) {
    if (!d || typeof d !== "object") return;
    var keys = CyberSheet.defaultData();
    for (var k in keys) {
      if (d[k] === undefined || root[k] === undefined) continue;
      if (typeof keys[k] === "boolean") {
        root[k] = (d[k] === true || String(d[k]).toLowerCase() === "true");
      } else if (typeof keys[k] === "number") {
        var n = parseInt(d[k], 10);
        root[k] = isFinite(n) ? n : keys[k];
      } else {
        root[k] = String(d[k]);
      }
    }
  }

  function renderText() {
    return CyberSheet.renderText(snapshot());
  }

  function bump(key, delta, lo, hi) {
    if (root[key] === undefined) return;
    var n = (parseInt(root[key], 10) || 0) + delta;
    n = Math.max(lo, Math.min(hi, n));
    root[key] = n;
    saveSoon();
  }

  // ---- persistence ----
  Timer { id: saveTimer; interval: 400; repeat: false; onTriggered: root.saveNow() }

  function saveSoon() {
    if (!root.dataLoaded) return;
    saveTimer.restart();
  }

  function saveNow() {
    if (!root.dataLoaded) return;
    var text = JSON.stringify(root.snapshot(), null, 2) + "\n";
    root.lastSavedText = text;
    root.writeFile(root.characterPath, text, saveWriter);
  }

  // Deterministic file writer (FileView.setText silently drops writes when
  // its path was just (re)assigned or the file is missing). Quoted heredoc:
  // literal content, no expansion; recreated on every call.
  function shellQuote(s) {
    return "'" + String(s).replace(/'/g, "'\\''") + "'";
  }

  function expandPath(p) {
    var s = String(p || "");
    if (s === "" || s.charAt(0) !== "~") return s;
    if (s === "~") return root.home;
    if (s.indexOf("~/") === 0) return root.home + s.slice(1);
    return s;
  }

  function exportDir() {
    var d = root.expandPath(config.outputDir);
    if (d === "") d = root.home + "/Pictures";
    return d.replace(/\/+$/g, "");
  }

  function exportFileName() {
    return CyberSheet.sheetFileName(root.snapshot());
  }

  function exportFullPath() {
    return root.exportDir() + "/" + root.exportFileName();
  }

  function writeFile(path, text, proc) {
    proc.command = ["sh", "-c",
      "cat > " + root.shellQuote(path) + " <<'__CYBERPUNK_SHEET_EOF__'\n" + text + "__CYBERPUNK_SHEET_EOF__\n"];
    if (proc.running) proc.running = false;
    proc.running = true;
  }

  Process {
    id: saveWriter
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (this.text !== "") root.status = "Save error: " + this.text;
      }
    }
  }
  Process {
    id: exportWriter
    stderr: StdioCollector {
      waitForEnd: true
      onStreamFinished: {
        if (this.text !== "") root.status = "Export error: " + this.text;
      }
    }
  }

  FileView {
    id: characterFile
    path: root.characterPath
    watchChanges: true
    atomicWrites: true
    printErrors: false
    onFileChanged: characterFile.reload()
    onLoaded: {
      if (text() === root.lastSavedText && root.dataLoaded) return;
      try {
        var d = JSON.parse(String(text() || "{}"));
        root.applyData(d);
      } catch (e) { root.applyData(CyberSheet.defaultData()); }
      root.dataLoaded = true;
    }
    onLoadFailed: { root.applyData(CyberSheet.defaultData()); root.dataLoaded = true; }
  }

  // ---- export to output folder, file named per character ----
  function exportNow() {
    root.saveNow();
    var full = root.exportFullPath();
    root.writeFile(full, root.renderText(), exportWriter);
    root.status = "Exported to " + full;
    exportRinse.restart();
  }

  Timer { id: exportRinse; interval: 4000; repeat: false; onTriggered: root.status = "Ready" }

  function pokeStatus(msg) {
    root.status = msg;
    exportRinse.restart();
  }

  function copyForLLM() {    // Best-effort clipboard via wl-copy / xclip; export always works regardless.
    var txt = root.renderText().replace(/'/g, "'\\''");
    copyProc.command = ["sh", "-c", "printf '%s' '" + txt.slice(0, 60000) + "' | (wl-copy 2>/dev/null || xclip -selection clipboard 2>/dev/null || true)"];
    copyProc.running = true;
    root.status = "Copied for LLM (if clipboard tool present). Export to file to be sure.";
    exportRinse.restart();
  }

  Process { id: copyProc }

  function clearSheet() {
    root.applyData(CyberSheet.defaultData());
    root.saveNow();
    root.status = "Sheet cleared.";
    exportRinse.restart();
  }

  // ---- import from an exported plain-text file ----
  property bool importArmed: false

  FileView {
    id: importer
    watchChanges: false
    atomicWrites: false
    printErrors: false
    onLoaded: {
      if (!root.importArmed) return;
      root.importArmed = false;
      root.doImportText(text());
    }
    onLoadFailed: {
      if (!root.importArmed) return;
      root.importArmed = false;
      root.status = "Import failed: cannot read file.";
      exportRinse.restart();
    }
  }

  function importSheet(path) {
    var p = (path === undefined || String(path).replace(/^\s+|\s+$/g, "") === "")
      ? config.importPath : String(path);
    p = root.expandPath(p.replace(/^\s+|\s+$/g, ""));
    if (p === "") {
      root.status = "Import: enter a plain-text sheet path first.";
      exportRinse.restart();
      return;
    }
    root.importArmed = true;
    importer.path = p;
    importer.reload();
  }

  function doImportText(text) {
    var res;
    try {
      res = CyberSheet.parseText(text);
    } catch (e) {
      root.status = "Import failed: could not parse file.";
      exportRinse.restart();
      return;
    }
    root.applyData(res.data);
    root.saveNow();
    var nm = res.data.charName && String(res.data.charName) !== "" ? res.data.charName : "sheet";
    root.status = "Imported " + nm + (res.warnings.length ? " (" + res.warnings[0] + ")" : "") + ".";
    exportRinse.restart();
  }

  Component.onCompleted: characterFile.reload()

  // ---- per-screen floating windows (cliamp-dock / oShelf model) ----
  Variants {
    id: windows
    model: Quickshell.screens
    SheetWindow {
      required property var modelData
      screen: modelData
      service: root
      cfg: config
    }
  }

  IpcHandler {
    target: root.pluginId
    function show(): string { for (var w of windows.instances) w.reveal(); return "shown"; }
    function hide(): string { for (var w2 of windows.instances) w2.collapse(); return "hidden"; }
    function toggle(): string {
      var any = false;
      for (var w3 of windows.instances) if (w3.expanded) { any = true; break; }
      if (any) { for (var w4 of windows.instances) w4.collapse(); return "hidden"; }
      for (var w5 of windows.instances) w5.reveal();
      return "shown";
    }
    function exportSheet(): string { root.exportNow(); return "exported to " + root.exportFullPath(); }
    function clear(): string { root.clearSheet(); return "cleared"; }
    function importSheet(): string { root.importSheet(); return "importing from " + config.importPath; }
    function status(): string {
      var states = [];
      for (var w of windows.instances) states.push(!!w.expanded);
      return JSON.stringify({ character: root.charName, output: root.exportFullPath(), expanded: states, status: root.status });
    }
  }
}
