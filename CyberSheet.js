.pragma library

// Field lists + plain-text renderer for the Cyberpunk 2020 sheet.
// Mirrors the "CP2020 Character Sheet Ultimate Edition.pdf" in ~/Pictures:
// IDENTITY, STATS (+derived Run/Leap/Carry/Lift/Save/BTM), ARMOR, DAMAGE,
// SPECIAL ABILITY, SKILLS by stat, CYBERNETICS, LIFEPATH, GEAR & WEAPONS, NOTES.
// Render/parse are driven by the same tables so they cannot drift apart.

// [key, label] single-line identity fields.
function identityFields() {
    return [
        ["charName", "Handle"], ["role", "Role"],
        ["characterPoints", "Character Points"], ["age", "Age"],
        ["rep", "Rep"], ["humanity", "Humanity"],
        ["currentIP", "Current IP"], ["money", "Money (eb)"],
        ["siblings", "Siblings"]
    ];
}

// [key, label] STATS (1-10).
function statFields() {
    return [
        ["statINT", "INT"], ["statREF", "REF"], ["statTECH", "TECH"],
        ["statCOOL", "COOL"], ["statATTR", "ATTR"], ["statLUCK", "LUCK"],
        ["statMA", "MA"], ["statBODY", "BODY"], ["statEMP", "EMP"]
    ];
}

// [key, label] armor SP per location (0-30).
function armorFields() {
    return [
        ["armorHead", "Head"], ["armorTorso", "Torso"],
        ["armorRArm", "R. Arm"], ["armorLArm", "L. Arm"],
        ["armorRLeg", "R. Leg"], ["armorLLeg", "L. Leg"]
    ];
}

// [key, label] wound boxes marked per level (0-4).
function damageFields() {
    return [
        ["dmgLight", "Light"], ["dmgSerious", "Serious"],
        ["dmgCritical", "Critical"], ["dmgMortal", "Mortal"]
    ];
}

// Skill groups: {stat, items:[[key,label],...]}. Levels 0-10.
function skillGroups() {
    return [
        { stat: "ATTR", items: [
            ["personalGrooming", "Personal Grooming"], ["wardrobeStyle", "Wardrobe & Style"] ] },
        { stat: "BODY", items: [
            ["endurance", "Endurance"], ["strengthFeat", "Strength Feat"], ["swimming", "Swimming"] ] },
        { stat: "COOL", items: [
            ["interrogation", "Interrogation"], ["intimidate", "Intimidate"],
            ["oratory", "Oratory"], ["resistTorture", "Resist Torture/Drugs"],
            ["streetwise", "Streetwise"] ] },
        { stat: "EMPATHY", items: [
            ["humanPerception", "Human Perception"], ["interview", "Interview"],
            ["leadership", "Leadership"], ["seduction", "Seduction"],
            ["social", "Social"], ["persuasion", "Persuasion & Fast Talk"],
            ["perform", "Perform"] ] },
        { stat: "INT", items: [
            ["accounting", "Accounting"], ["anthropology", "Anthropology"],
            ["awareness", "Awareness/Notice"], ["biology", "Biology"],
            ["botany", "Botany"], ["chemistry", "Chemistry"],
            ["composition", "Composition"], ["diagnose", "Diagnose Illness"],
            ["education", "Education & Gen Know"], ["gamble", "Gamble"],
            ["geology", "Geology"], ["hideEvade", "Hide/Evade"],
            ["history", "History"], ["librarySearch", "Library Search"],
            ["mathematics", "Mathematics"], ["physics", "Physics"],
            ["programming", "Programming"], ["shadowTrack", "Shadow/Track"],
            ["stockMarket", "Stock Market"], ["systemKnowledge", "System Knowledge"],
            ["teaching", "Teaching"], ["wilderness", "Wilderness Survival"],
            ["zoology", "Zoology"] ] },
        { stat: "REF", items: [
            ["archery", "Archery"], ["athletics", "Athletics"],
            ["brawling", "Brawling"], ["dance", "Dance"],
            ["dodge", "Dodge & Escape"], ["driving", "Driving"],
            ["fencing", "Fencing"], ["handgun", "Handgun"],
            ["heavyWeapons", "Heavy Weapons"], ["melee", "Melee"],
            ["motorcycle", "Motorcycle"], ["operateHvy", "Operate Hvy. Machinery"],
            ["pilotGyro", "Pilot (Gyro)"], ["pilotFixed", "Pilot (Fixed Wing)"],
            ["pilotDirigible", "Pilot (Dirigible)"],
            ["pilotVector", "Pilot (Vect. Thrust Vehicle)"],
            ["rifle", "Rifle"], ["stealth", "Stealth"],
            ["submachinegun", "Submachinegun"] ] },
        { stat: "TECH", items: [
            ["aeroTech", "Aero Tech"], ["avTech", "AV Tech"],
            ["basicTech", "Basic Tech"], ["cryotank", "Cryotank Operation"],
            ["cyberdeckDesign", "Cyberdeck Design"], ["cyberTech", "Cyber Tech"],
            ["demolitions", "Demolitions"], ["disguise", "Disguise"],
            ["electSecurity", "Elect. Security"], ["electronics", "Electronics"],
            ["firstAid", "First Aid"], ["forgery", "Forgery"],
            ["gyroTech", "Gyro Tech"], ["paintDraw", "Paint or Draw"],
            ["photoFilm", "Photo & Film"], ["pharma", "Pharmaceuticals"],
            ["pickLock", "Pick Lock"], ["pickPocket", "Pick Pocket"],
            ["playInstrument", "Play Instrument"], ["weaponsmith", "Weaponsmith"],
            ["weaponsTech", "Weapons Tech"] ] }
    ];
}

// Named skills: free-text name + level. Rendered inside their stat group.
function namedSkills() {
    return [
        { nameKey: "language1Name", levelKey: "language1", label: "Language 1", stat: "INT" },
        { nameKey: "language2Name", levelKey: "language2", label: "Language 2", stat: "INT" },
        { nameKey: "language3Name", levelKey: "language3", label: "Language 3", stat: "INT" },
        { nameKey: "expertName", levelKey: "expert", label: "Expert", stat: "INT" },
        { nameKey: "martial1Name", levelKey: "martial1", label: "Martial Art 1", stat: "REF" },
        { nameKey: "martial2Name", levelKey: "martial2", label: "Martial Art 2", stat: "REF" },
        { nameKey: "martial3Name", levelKey: "martial3", label: "Martial Art 3", stat: "REF" },
        { nameKey: "otherAName", levelKey: "otherA", label: "Other A", stat: "TECH" },
        { nameKey: "otherBName", levelKey: "otherB", label: "Other B", stat: "TECH" },
        { nameKey: "otherCName", levelKey: "otherC", label: "Other C", stat: "TECH" }
    ];
}

// [key, label] multi-line notes.
function textFields() {
    return [
        ["cybernetics", "Cybernetics (Type | HL | Cost, one per line)"],
        ["totalHL", "Total HL"], ["totalCost", "Total Cost (eb)"],
        ["style", "Style"], ["clothes", "Clothes"], ["hair", "Hair"],
        ["affections", "Affections"], ["ethnicity", "Ethnicity"],
        ["lifepathLang", "Language"],
        ["familyBg", "Family Background"],
        ["motivations", "Motivations"], ["traits", "Traits"],
        ["valuedPerson", "Valued Person"], ["valueMost", "Value Most"],
        ["feelPeople", "Feel About People"], ["valuedPoss", "Valued Possession"],
        ["lifeEvents", "Life Events (one per year after 16)"],
        ["gear", "Gear (Type | Cost | Wt, one per line)"],
        ["weapons", "Weapons (Name | Type | WA | ... one per line)"],
        ["chipped", "Chipped Skills"],
        ["ooc", "OOC Instructions to LLM"]
    ];
}

function defaultData() {
    // True blank sheet: empty text, everything 0.
    var d = {};
    var idf = identityFields();
    for (var i = 0; i < idf.length; i++) d[idf[i][0]] = "";
    var st = statFields();
    for (var s = 0; s < st.length; s++) d[st[s][0]] = 0;
    var ar = armorFields();
    for (var a = 0; a < ar.length; a++) d[ar[a][0]] = 0;
    var dg = damageFields();
    for (var g = 0; g < dg.length; g++) d[dg[g][0]] = 0;
    d.specName = "";
    d.specLevel = 0;
    var sg = skillGroups();
    for (var h = 0; h < sg.length; h++)
        for (var k = 0; k < sg[h].items.length; k++) d[sg[h].items[k][0]] = 0;
    var ns = namedSkills();
    for (var n = 0; n < ns.length; n++) { d[ns[n].nameKey] = ""; d[ns[n].levelKey] = 0; }
    // Specialization flags + subtext for every skill level key.
    var specKeys = [];
    for (var h2 = 0; h2 < sg.length; h2++)
        for (var k2 = 0; k2 < sg[h2].items.length; k2++) specKeys.push(sg[h2].items[k2][0]);
    for (var n2 = 0; n2 < ns.length; n2++) specKeys.push(ns[n2].levelKey);
    for (var s2 = 0; s2 < specKeys.length; s2++) {
        d[specKeys[s2] + "Spec"] = false;
        d[specKeys[s2] + "SpecText"] = "";
    }
    var tf = textFields();
    for (var t = 0; t < tf.length; t++) d[tf[t][0]] = "";
    return d;
}

function clampInt(v, lo, hi) {
    var n = parseInt(v, 10);
    if (!isFinite(n)) return lo;
    return Math.max(lo, Math.min(hi, n));
}

// Valid [lo, hi] range per numeric data key, mirroring the +/- limits in
// SheetWindow.qml. Used by the service to clamp hand-edited JSON on load
// so crafted files cannot inject out-of-range values into the UI/export.
function limits() {
    var lim = { specLevel: [0, 10] };
    var groups = [statFields(), armorFields(), damageFields()];
    var ranges = [[0, 10], [0, 30], [0, 4]];
    for (var g = 0; g < groups.length; g++)
        for (var i = 0; i < groups[g].length; i++)
            lim[groups[g][i][0]] = ranges[g];
    var sg = skillGroups();
    for (var h = 0; h < sg.length; h++)
        for (var k = 0; k < sg[h].items.length; k++)
            lim[sg[h].items[k][0]] = [0, 10];
    var ns = namedSkills();
    for (var n = 0; n < ns.length; n++)
        lim[ns[n].levelKey] = [0, 10];
    return lim;
}

function btmFor(body) {
    var b = clampInt(body, 1, 15);
    if (b >= 11) return -5;
    if (b >= 9) return -4;
    if (b >= 7) return -3;
    if (b >= 5) return -2;
    if (b >= 3) return -1;
    return 0;
}

// Derived movement/combat stats (CP2020 core rules).
function derive(d) {
    var ma = clampInt(d.statMA, 1, 15);
    var body = clampInt(d.statBODY, 1, 15);
    return {
        run: ma * 3,
        leap: Math.round(ma * 3 / 4),
        carry: body * 10,
        lift: body * 40,
        save: body,
        btm: btmFor(body)
    };
}

function num(d, key, fallback) {
    var v = parseInt(d[key], 10);
    return isFinite(v) ? v : (fallback || 0);
}

// Specialization suffix for a skill level line, e.g. ' ★ [pistols]'.
// Convention: flag key = levelKey + "Spec", text key = levelKey + "SpecText".
function specSuffix(d, levelKey) {
    if (!d[levelKey + "Spec"]) return "";
    var s = " ★";
    var t = d[levelKey + "SpecText"] ? String(d[levelKey + "SpecText"]).replace(/^\s+|\s+$/g, "") : "";
    if (t !== "") s += " [" + t + "]";
    return s;
}

function bulletBlock(s) {
    var lines = String(s || "").split("\n");
    var out = [];
    for (var i = 0; i < lines.length; i++) {
        var t = lines[i].replace(/^\s+|\s+$/g, "");
        if (t !== "") out.push("  - " + t);
    }
    if (!out.length) out.push("  - ");
    return out.join("\n");
}

function namedLabelText(d, ns) {
    var nm = d[ns.nameKey] ? String(d[ns.nameKey]).replace(/^\s+|\s+$/g, "") : "";
    return ns.label + " (" + (nm !== "" ? nm : "unnamed") + ")";
}

function renderText(d) {
    var L = [];
    var i, j, k;
    L.push("CYBERPUNK 2020 - CHARACTER SHEET (Plain Text for LLM)");
    L.push("======================================================");
    L.push("");
    L.push("== IDENTITY ==");
    var idf = identityFields();
    for (i = 0; i < idf.length; i++)
        L.push(idf[i][1] + ": " + (d[idf[i][0]] !== undefined ? d[idf[i][0]] : ""));
    L.push("");
    L.push("== STATS ==");
    var st = statFields();
    for (i = 0; i < st.length; i++)
        L.push("  " + st[i][1] + ": " + num(d, st[i][0]) + "/10");
    var dv = derive(d);
    L.push("Derived: Run " + dv.run + "m, Leap " + dv.leap + "m, Carry " +
           dv.carry + "kg, Lift " + dv.lift + "kg, Save " + dv.save + ", BTM " + dv.btm);
    L.push("");
    L.push("== ARMOR ==");
    var ar = armorFields();
    for (i = 0; i < ar.length; i++)
        L.push("  " + ar[i][1] + ": " + num(d, ar[i][0]) + " SP");
    L.push("");
    L.push("== DAMAGE ==");
    var dg = damageFields();
    for (i = 0; i < dg.length; i++)
        L.push("  " + dg[i][1] + ": " + num(d, dg[i][0]) + "/4");
    L.push("Stun penalties: Light 0 / Serious -1 / Critical -2 / Mortal -3 or worse.");
    L.push("");
    L.push("== SPECIAL ABILITY ==");
    var sn = d.specName ? String(d.specName).replace(/^\s+|\s+$/g, "") : "";
    L.push("Special Ability (" + (sn !== "" ? sn : "unnamed") + "): " + num(d, "specLevel") + "/10");
    L.push("");
    L.push("== SKILLS ==");
    L.push("(Add skill level to its STAT, then roll STAT + Skill + 1d10. Mark chipped skills; see NOTES.)");
    var sg = skillGroups();
    var ns = namedSkills();
    for (i = 0; i < sg.length; i++) {
        L.push(sg[i].stat + ":");
        for (j = 0; j < sg[i].items.length; j++)
            L.push("  " + sg[i].items[j][1] + ": " + num(d, sg[i].items[j][0]) + "/10" + specSuffix(d, sg[i].items[j][0]));
        for (k = 0; k < ns.length; k++)
            if (ns[k].stat === sg[i].stat)
                L.push("  " + namedLabelText(d, ns[k]) + ": " + num(d, ns[k].levelKey) + "/10" + specSuffix(d, ns[k].levelKey));
    }
    L.push("");
    L.push("== CYBERNETICS ==");
    var tf = textFields();
    var tl = {};
    for (i = 0; i < tf.length; i++) tl[tf[i][0]] = tf[i][1];
    L.push(tl.cybernetics + ":");
    L.push(bulletBlock(d.cybernetics));
    L.push("Total HL: " + (d.totalHL !== undefined ? d.totalHL : ""));
    L.push("Total Cost (eb): " + (d.totalCost !== undefined ? d.totalCost : ""));
    L.push("");
    L.push("== LIFEPATH ==");
    var singles = ["style", "clothes", "hair", "affections", "ethnicity",
                   "lifepathLang"];
    for (i = 0; i < singles.length; i++)
        L.push(tl[singles[i]] + ": " + (d[singles[i]] !== undefined ? d[singles[i]] : ""));
    var multis = ["familyBg", "motivations", "traits", "valuedPerson", "valueMost",
                  "feelPeople", "valuedPoss", "lifeEvents"];
    for (i = 0; i < multis.length; i++) {
        L.push(tl[multis[i]] + ":");
        L.push(bulletBlock(d[multis[i]]));
    }
    L.push("");
    L.push("== GEAR & WEAPONS ==");
    L.push(tl.gear + ":");
    L.push(bulletBlock(d.gear));
    L.push(tl.weapons + ":");
    L.push(bulletBlock(d.weapons));
    L.push("");
    L.push("== NOTES ==");
    L.push(tl.chipped + ":");
    L.push(bulletBlock(d.chipped));
    L.push(tl.ooc + ":");
    L.push(bulletBlock(d.ooc));
    L.push("");
    L.push("== LLM INSTRUCTIONS ==");
    var nm = d.charName && String(d.charName).replace(/^\s+|\s+$/g, "") !== ""
        ? String(d.charName).replace(/^\s+|\s+$/g, "") : "this character";
    L.push("'You are the referee for Cyberpunk 2020 (R. Talsorian). I play " + nm +
           ". Use this sheet for stats. Call for rolls like REF+Handgun+1d10 vs DV or " +
           "INT+Awareness/Notice+1d10. Track Humanity, IP, ammo, armor ablation and " +
           "wound stun penalties. Roleplay NPCs and the world, don't godmode my PC.'");
    L.push("======================================================");
    return L.join("\n") + "\n";
}

// Unique per-character file name, e.g. "Morgan-Blackhand.txt".
function sheetFileName(d) {
    var base = d && d.charName ? String(d.charName).replace(/^\s+|\s+$/g, "") : "";
    if (base === "") base = "unnamed-cyberpunk";
    base = base.replace(/\s+/g, "-").replace(/[^A-Za-z0-9-_]/g, "-")
               .replace(/-+/g, "-").replace(/^-+|-+$/g, "");
    if (base === "") base = "unnamed-cyberpunk";
    if (base.length > 80) base = base.slice(0, 80);
    return base + ".txt";
}

// Parse an exported plain-text sheet back into a data object.
// Tolerant: skips unknown lines (Derived, Stun, skill hints).
function parseText(text) {
    var d = defaultData();
    var warnings = [];
    var i, j, k;
    var labelToIdentity = {};
    var idf = identityFields();
    for (i = 0; i < idf.length; i++) labelToIdentity[idf[i][1]] = idf[i][0];
    var levelMap = {};
    var st = statFields();
    for (i = 0; i < st.length; i++) levelMap[st[i][1].toLowerCase()] = { key: st[i][0], max: 10 };
    var sg = skillGroups();
    for (i = 0; i < sg.length; i++)
        for (j = 0; j < sg[i].items.length; j++)
            levelMap[sg[i].items[j][1].toLowerCase()] = { key: sg[i].items[j][0], max: 10 };
    var ar = armorFields();
    for (i = 0; i < ar.length; i++) levelMap[ar[i][1].toLowerCase()] = { key: ar[i][0], max: 30, sp: true };
    var dg = damageFields();
    for (i = 0; i < dg.length; i++) levelMap[dg[i][1].toLowerCase()] = { key: dg[i][0], max: 4, boxes: true };
    var ns = namedSkills();
    var nsByLabel = {};
    for (i = 0; i < ns.length; i++) nsByLabel[ns[i].label.toLowerCase()] = ns[i];
    var textMap = {};
    var tf = textFields();
    for (i = 0; i < tf.length; i++) textMap[tf[i][1].toLowerCase()] = tf[i][0];

    var lines = String(text || "").split("\n");
    var section = "";
    var currentList = null;
    for (var n = 0; n < lines.length; n++) {
        var t = lines[n].replace(/^\s+|\s+$/g, "");
        if (t === "") { currentList = null; continue; }
        if (t.indexOf("==") === 0) { section = t.toUpperCase(); currentList = null; continue; }
        var m;
        if (section.indexOf("IDENTITY") >= 0) {
            m = t.match(/^([^:]+):\s*(.*)$/);
            if (m) {
                var key = labelToIdentity[m[1].replace(/^\s+|\s+$/g, "")];
                if (key) d[key] = m[2].replace(/^\s+|\s+$/g, "");
            }
            continue;
        }
        if (section.indexOf("SPECIAL") >= 0) {
            m = t.match(/^Special Ability \((.*)\)\s*:\s*(\d+)\s*\/\s*10\s*$/i);
            if (m) {
                var nm = m[1].replace(/^\s+|\s+$/g, "");
                d.specName = (nm.toLowerCase() === "unnamed") ? "" : nm;
                var sv = parseInt(m[2], 10);
                d.specLevel = Math.max(0, Math.min(10, isFinite(sv) ? sv : 0));
            }
            continue;
        }
        if (section.indexOf("STATS") >= 0 || section.indexOf("SKILLS") >= 0) {
            // Named skill: "Language 1 (Spanish): 4/10 ★ [slang]".
            m = t.match(/^(.+?)\s*\((.*)\)\s*:\s*(\d+)\s*\/\s*10\s*(.*)$/);
            if (m) {
                var spec = nsByLabel[m[1].replace(/^\s+|\s+$/g, "").toLowerCase()];
                if (spec) {
                    var nn = m[2].replace(/^\s+|\s+$/g, "");
                    d[spec.nameKey] = (nn.toLowerCase() === "unnamed") ? "" : nn;
                    var nv = parseInt(m[3], 10);
                    d[spec.levelKey] = Math.max(0, Math.min(10, isFinite(nv) ? nv : 0));
                    var tail = m[4] || "";
                    d[spec.levelKey + "Spec"] = tail.indexOf("★") >= 0;
                    var tm = tail.match(/\[(.*)\]\s*$/);
                    d[spec.levelKey + "SpecText"] = tm ? tm[1].replace(/^\s+|\s+$/g, "") : "";
                    continue;
                }
            }
            m = t.match(/^(.+?):\s*(\d+)\s*\/\s*10\s*(.*)$/);
            if (m) {
                var spec2 = levelMap[m[1].replace(/^\s+|\s+$/g, "").toLowerCase()];
                if (spec2 && !spec2.sp && !spec2.boxes) {
                    var v = parseInt(m[2], 10);
                    d[spec2.key] = Math.max(0, Math.min(spec2.max, isFinite(v) ? v : 0));
                    var tail2 = m[3] || "";
                    d[spec2.key + "Spec"] = tail2.indexOf("★") >= 0;
                    var tm2 = tail2.match(/\[(.*)\]\s*$/);
                    d[spec2.key + "SpecText"] = tm2 ? tm2[1].replace(/^\s+|\s+$/g, "") : "";
                }
            }
            continue;
        }
        if (section.indexOf("ARMOR") >= 0) {
            m = t.match(/^(.+?):\s*(\d+)\s*SP\s*$/i);
            if (m) {
                var spec3 = levelMap[m[1].replace(/^\s+|\s+$/g, "").toLowerCase()];
                if (spec3 && spec3.sp) {
                    var v3 = parseInt(m[2], 10);
                    d[spec3.key] = Math.max(0, Math.min(30, isFinite(v3) ? v3 : 0));
                }
            }
            continue;
        }
        if (section.indexOf("DAMAGE") >= 0) {
            m = t.match(/^(.+?):\s*(\d+)\s*\/\s*4\s*$/);
            if (m) {
                var spec4 = levelMap[m[1].replace(/^\s+|\s+$/g, "").toLowerCase()];
                if (spec4 && spec4.boxes) {
                    var v4 = parseInt(m[2], 10);
                    d[spec4.key] = Math.max(0, Math.min(4, isFinite(v4) ? v4 : 0));
                }
            }
            continue;
        }
        if (section.indexOf("CYBERNETICS") >= 0 || section.indexOf("LIFEPATH") >= 0 ||
            section.indexOf("GEAR") >= 0 || section.indexOf("NOTES") >= 0) {
            m = t.match(/^([^:]+):\s*(.*)$/);
            if (m && textMap[m[1].replace(/^\s+|\s+$/g, "").toLowerCase()] !== undefined) {
                currentList = textMap[m[1].replace(/^\s+|\s+$/g, "").toLowerCase()];
                d[currentList] = m[2].replace(/^\s+|\s+$/g, "");
                continue;
            }
            if (currentList) {
                var b = t.match(/^-\s?(.*)$/);
                if (b) {
                    if (d[currentList] !== "") d[currentList] += "\n";
                    d[currentList] += b[1];
                }
            }
            continue;
        }
    }
    var tks = [];
    for (i = 0; i < tf.length; i++) tks.push(tf[i][0]);
    var singles = ["totalHL", "totalCost", "style", "clothes", "hair",
                   "affections", "ethnicity", "lifepathLang"];
    for (var q = 0; q < tks.length; q++) {
        if (singles.indexOf(tks[q]) >= 0) continue;
        var parts = String(d[tks[q]] || "").split("\n");
        var kept = [];
        for (var r = 0; r < parts.length; r++) {
            var pv = parts[r].replace(/^\s+|\s+$/g, "");
            if (pv !== "" && pv !== "-") kept.push(pv);
        }
        d[tks[q]] = kept.join("\n");
    }
    if ((d.charName || "") === "") warnings.push("No handle found — check the file is an exported sheet.");
    return { data: d, warnings: warnings };
}
