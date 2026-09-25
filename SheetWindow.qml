pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls as QQC
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs.Commons
import qs.Ui

// Bar-icon-driven floating Cyberpunk 2020 sheet editor (no floating square
// anchor). Open/close from the bar icon (left-click), IPC (show/hide/toggle),
// the card's X button, or Esc. No hover-dwell, no auto-collapse on mouse
// leave: the card stays open until explicitly closed. Pin (keepOpen) blocks
// every close path (X, Esc, bar toggle, IPC hide) until unpinned.
// Edit like the PDF, exports plain text for LLM roleplay.
// Only the open card takes input; all other pixels pass through to the
// desktop via the layer-shell input mask.
// All colors via Color.* / Style.* so omarchy themes repaint it live.
PanelWindow {
  id: root
  required property var service
  required property var cfg

  readonly property bool atRight: cfg.corner === "topRight" || cfg.corner === "bottomRight"
  readonly property bool atBottom: cfg.corner === "bottomLeft" || cfg.corner === "bottomRight"
  readonly property real topClearance: 44 // keep clear of the top bar
  readonly property bool reducedMotion: cfg.reducedMotion
  property bool expanded: false
  property real openness: expanded ? 1 : 0
  readonly property real cardW: Math.min(width - 32, cfg.sideWidth)
  readonly property real cardH: Math.min(height - 32, cfg.sideHeight)
  // live drag offset (pixels from press origin while dragging the header)
  property real dragDX: 0
  property real dragDY: 0
  readonly property bool dragging: dragHandler.active
  // card position: corner snap, or free placement (drag the header —
  // position persists in cfg.posX/posY as screen fractions)
  readonly property real cornerCardX: {
    var cx = atRight ? width - cardW - cfg.cornerMarginX : cfg.cornerMarginX;
    return Math.max(16, Math.min(width - cardW - 16, cx));
  }
  readonly property real cornerCardY: {
    var cy = atBottom ? height - cardH - cfg.cornerMarginY - 16
      : cfg.cornerMarginY + topClearance + 16;
    return Math.max(16, Math.min(height - cardH - 16, cy));
  }
  readonly property real cardX: {
    if (cfg.placeMode !== "free") return cornerCardX;
    return Math.max(16, Math.min(width - cardW - 16, cfg.posX * width + (dragging ? dragDX : 0)));
  }
  readonly property real cardY: {
    if (cfg.placeMode !== "free") return cornerCardY;
    return Math.max(16, Math.min(height - cardH - 16, cfg.posY * height + (dragging ? dragDY : 0)));
  }

  anchors { top: true; bottom: true; left: true; right: true }
  color: "transparent"
  exclusiveZone: 0
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "cyberpunk-sheet"
  WlrLayershell.keyboardFocus: expanded ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
  mask: Region {
    x: surface.x; y: surface.y
    width: root.expanded ? surface.width : 0; height: surface.height
    radius: surface.radius
  }

  Behavior on openness {
    NumberAnimation {
      duration: root.reducedMotion ? 0 : root.expanded ? cfg.motionDuration : Math.round(cfg.motionDuration * 0.75)
      easing.type: Easing.OutCubic
    }
  }

  function reveal() {
    if (expanded) return;
    expanded = true;
    content.forceActiveFocus();
  }
  // Explicit close only (X button, Esc, bar-icon toggle, IPC hide).
  // Pin (keepOpen) blocks it — unpin first.
  function collapse() {
    if (cfg.keepOpen) return;
    expanded = false;
  }
  function toggle() { expanded ? collapse() : reveal(); }
  // Drop the card after a header drag: persist the free position (screen
  // fractions, clamped 0..1 — on-screen clamping happens in cardX/cardY).
  function commitCardDrag() {
    var fx = (cfg.posX * width + root.dragDX) / width;
    var fy = (cfg.posY * height + root.dragDY) / height;
    root.dragDX = 0; root.dragDY = 0;
    cfg.set("posX", Math.max(0, Math.min(1, fx)));
    cfg.set("posY", Math.max(0, Math.min(1, fy)));
  }
  // ---- field search ----
  // Live-dims rows whose label matches neither the query nor their section
  // (so "handgun" finds Handgun, "ref" finds the whole REF SKILLS group).
  // Enter jumps through matches (Shift+Enter backwards) with a highlight
  // flash; Esc clears the query first instead of closing the card.
  property var searchHits: []
  property int searchIndex: -1
  function applySearch() {
    var q = searchField.text.trim().toLowerCase();
    var st = { sec: "", sub: "", secMatch: {}, hits: [], headers: [] };
    walkSearch(body, q, st);
    for (var j = 0; j < st.headers.length; j++) {
      var h = st.headers[j];
      var t = String(h.text).toLowerCase();
      h.searchDim = !(q === "" || t.indexOf(q) >= 0 || st.secMatch[t] === true);
    }
    root.searchHits = st.hits;
    root.searchIndex = -1;
    matchCount.text = q === "" ? "" : (st.hits.length === 0 ? "0" : String(st.hits.length));
  }
  // In-order walk of the sheet rows. Descends into containers so nested rows
  // take part. Tracks the sheet section (Identity, Stats, Attr Skills, ...)
  // and an optional sub title inside it (level 1, unused here but kept for
  // parity with the sibling sheets). A row matches when its label or its
  // section contains the query.
  function walkSearch(item, q, st) {
    var kids = item ? item.children : null;
    if (!kids) return;
    for (var i = 0; i < kids.length; i++) {
      var it = kids[i];
      if (!it) continue;
      if (it.isSectionHeader === true) {
        var t = String(it.text).toLowerCase();
        if ((it.headerLevel || 0) === 0) { st.sec = t; st.sub = ""; }
        else { st.sub = t; }
        st.headers.push(it);
      } else if (("searchMatch" in it)) {
        var lab = String(it.label || "").toLowerCase();
        var m = (q === "") || (lab.indexOf(q) >= 0)
          || (st.sub !== "" && st.sub.indexOf(q) >= 0)
          || (st.sec !== "" && st.sec.indexOf(q) >= 0);
        it.searchMatch = m;
        if (m && q !== "") {
          st.hits.push(it);
          if (st.sub !== "") st.secMatch[st.sub] = true;
          if (st.sec !== "") st.secMatch[st.sec] = true;
        }
      }
      if (it.children && it.children.length > 0) walkSearch(it, q, st);
    }
  }
  function jumpSearch(dir) {
    var hits = root.searchHits;
    if (hits.length === 0) return;
    root.searchIndex = (((root.searchIndex + dir) % hits.length) + hits.length) % hits.length;
    var it = hits[root.searchIndex];
    if (!it) return;
    // body sits at the Flickable content origin, so body coords are
    // content coords (nested rows need mapToItem, not raw y).
    var p = it.mapToItem(body, 0, 0);
    searchGlow.x = p.x;
    searchGlow.y = p.y;
    searchGlow.width = it.width;
    searchGlow.height = it.height;
    searchGlow.opacity = 1;
    glowTimer.restart();
    var target = p.y - 48;
    var maxY = Math.max(0, scroller.contentHeight - scroller.height);
    scroller.contentY = Math.max(0, Math.min(maxY, target));
    matchCount.text = (root.searchIndex + 1) + "/" + hits.length;
  }
  // Commit every visible text field into the sheet (text the user typed but
  // never tabbed out of). Called before export/copy so nothing is lost.
  function flushAll() {
    function walk(item) {
      if (!item || !item.children) return;
      if (typeof item.flush === "function") {
        try { item.flush(); } catch (e) {}
      }
      var kids = item.children;
      for (var i = 0; i < kids.length; i++) walk(kids[i]);
    }
    walk(body);
  }
  // Refresh the import path each time the card opens so it tracks the
  // current output folder instead of going stale after settings edits.
  onExpandedChanged: { if (expanded) importField.text = cfg.outputDir + "/"; }

  Timer { id: glowTimer; interval: 1200; repeat: false; onTriggered: { searchGlow.opacity = 0; searchGlow.height = 0; } }

  // ---- sheet card ----
  Rectangle {
    id: surface
    objectName: "cyberpunk-sheet-surface"
    x: root.cardX
    y: root.cardY + (root.reducedMotion ? 0 : (1 - root.openness) * (root.atBottom ? 32 : -32))
    width: root.cardW; height: root.cardH
    scale: root.reducedMotion ? 1 : 0.97 + root.openness * 0.03
    opacity: root.openness
    visible: root.openness > 0
    radius: 24
    color: Color.background
    border.width: 1
    border.color: Util.alpha(Color.foreground, 0.15)
    layer.enabled: visible
    layer.effect: MultiEffect { shadowEnabled: true; shadowColor: "#000000"; shadowOpacity: 0.35; shadowBlur: 0.65; shadowVerticalOffset: 8 }

    Rectangle {
      anchors { top: parent.top; left: parent.left; right: parent.right; margins: 1 }
      height: Math.min(parent.height, 120); radius: 23
      gradient: Gradient {
        GradientStop { position: 0; color: Util.alpha(Color.accent, 0.08) }
        GradientStop { position: 1; color: "transparent" }
      }
    }

    // Drag handle: the header strip (above the scroll body at y 96).
    // Grab empty header space to move the card anywhere on the workspace;
    // the drop position persists. Pin/close buttons and fields below sit
    // in later siblings, so their clicks still win on their own pixels.
    Item {
      id: dragHandle
      x: 0; y: 0; width: parent.width; height: 96
      HoverHandler {
        id: dragHover
        cursorShape: dragHandler.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
      }
      DragHandler {
        id: dragHandler
        target: null
        onActiveChanged: {
          if (active) {
            root.dragDX = 0; root.dragDY = 0;
            // Seed free placement from the current corner spot so a first
            // drag off a snapped corner doesn't jump the card.
            if (cfg.placeMode !== "free") {
              cfg.set("posX", root.cornerCardX / root.width);
              cfg.set("posY", root.cornerCardY / root.height);
              cfg.set("placeMode", "free");
            }
          } else root.commitCardDrag();
        }
        onTranslationChanged: { root.dragDX = translation.x; root.dragDY = translation.y; }
      }
    }

    FocusScope {
      id: content
      anchors.fill: parent
      Keys.onEscapePressed: { if (confirm.opened) confirm.canceled(); else root.collapse(); }
      Keys.onPressed: function(event) {
        if (event.key === Qt.Key_PageUp) {
          scroller.contentY = Math.max(0, scroller.contentY - scroller.height);
          event.accepted = true;
        } else if (event.key === Qt.Key_PageDown) {
          scroller.contentY = Math.min(Math.max(0, scroller.contentHeight - scroller.height), scroller.contentY + scroller.height);
          event.accepted = true;
        }
      }

      // header: CyberTheme logo, tinted with the theme accent (MultiEffect
      // colorization — white source + alpha recolors cleanly per theme)
      // Small full-color Cyber2020 mark sits left of the logo.
      Image {
        id: headerIcon
        x: 18; y: 8; width: 64; height: 64
        source: Qt.resolvedUrl("anchor-icon.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: 0.95
      }
      Image {
        id: logo
        x: headerIcon.x + headerIcon.width + 8; y: 12; width: 210; height: 56
        source: Qt.resolvedUrl("logo.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        opacity: 0.95
        layer.enabled: true
        layer.effect: MultiEffect {
          colorization: 1.0
          colorizationColor: Color.accent
        }
      }
      Row {
        anchors.right: parent.right; anchors.rightMargin: 14; y: 22; spacing: 2
        SheetAction { icon: "pin"; hint: cfg.keepOpen ? "Unpin (allow X to close)" : "Pin (X cannot close)"; selected: cfg.keepOpen; onTriggered: cfg.set("keepOpen", !cfg.keepOpen) }
        SheetAction { icon: "close"; hint: cfg.keepOpen ? "Pinned — unpin to close" : "Close sheet"; enabled: !cfg.keepOpen; onTriggered: root.collapse() }
      }

      Row {
        id: searchRow
        x: 16; y: 96; width: parent.width - 32
        spacing: 8
        TextField {
          id: searchField
          width: parent.width - matchCount.width - parent.spacing
          anchors.verticalCenter: parent.verticalCenter
          placeholderText: "Search fields… (Enter jumps, Esc clears)"
          onTextChanged: root.applySearch()
          Keys.onReturnPressed: function(event) {
            root.jumpSearch((event.modifiers & Qt.ShiftModifier) ? -1 : 1);
          }
          Keys.onEscapePressed: function(event) {
            if (text !== "") { text = ""; event.accepted = true; }
          }
        }
        Text {
          id: matchCount
          width: 44
          horizontalAlignment: Text.AlignRight
          anchors.verticalCenter: parent.verticalCenter
          textFormat: Text.PlainText
          color: Util.alpha(Color.foreground, 0.55)
          font.family: Style.fontFamily; font.pixelSize: 11
        }
      }

      Flickable {
        id: scroller
        x: 16; y: searchRow.y + searchRow.height + 8; width: parent.width - 32; height: parent.height - (searchRow.y + searchRow.height + 8) - 64
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        QQC.ScrollBar.vertical: QQC.ScrollBar {
          id: vbar
          policy: QQC.ScrollBar.AlwaysOn
          contentItem: Rectangle {
            implicitWidth: 6; radius: 3
            color: Util.alpha(Color.foreground, (vbar.pressed || vbar.active) ? 0.45 : 0.22)
          }
          background: Rectangle {
            implicitWidth: 6; radius: 3
            color: Util.alpha(Color.foreground, 0.07)
          }
        }

        Column {
          id: body
          width: scroller.width
          spacing: 8

          SectionHeader { text: "IDENTITY" }
          FieldRow { label: "Handle"; initial: service.charName; onCommit: function(v) { service.charName = v; service.saveSoon(); } }
          FieldRow { label: "Role"; initial: service.role; onCommit: function(v) { service.role = v; service.saveSoon(); } }
          FieldRow { label: "Char. Points"; initial: service.characterPoints; onCommit: function(v) { service.characterPoints = v; service.saveSoon(); } }
          FieldRow { label: "Age"; initial: service.age; onCommit: function(v) { service.age = v; service.saveSoon(); } }
          FieldRow { label: "Rep"; initial: service.rep; onCommit: function(v) { service.rep = v; service.saveSoon(); } }
          FieldRow { label: "Humanity"; initial: service.humanity; onCommit: function(v) { service.humanity = v; service.saveSoon(); } }
          FieldRow { label: "Current IP"; initial: service.currentIP; onCommit: function(v) { service.currentIP = v; service.saveSoon(); } }
          FieldRow { label: "Money (eb)"; initial: service.money; onCommit: function(v) { service.money = v; service.saveSoon(); } }
          FieldRow { label: "Siblings"; initial: service.siblings; onCommit: function(v) { service.siblings = v; service.saveSoon(); } }

          SectionSeparator { }
          SectionHeader { text: "STATS" }
          DotRow { label: "INT"; value: service.statINT; onDec: function() { service.bump("statINT", -1, 0, 10); } onInc: function() { service.bump("statINT", 1, 0, 10); } }
          DotRow { label: "REF"; value: service.statREF; onDec: function() { service.bump("statREF", -1, 0, 10); } onInc: function() { service.bump("statREF", 1, 0, 10); } }
          DotRow { label: "TECH"; value: service.statTECH; onDec: function() { service.bump("statTECH", -1, 0, 10); } onInc: function() { service.bump("statTECH", 1, 0, 10); } }
          DotRow { label: "COOL"; value: service.statCOOL; onDec: function() { service.bump("statCOOL", -1, 0, 10); } onInc: function() { service.bump("statCOOL", 1, 0, 10); } }
          DotRow { label: "ATTR"; value: service.statATTR; onDec: function() { service.bump("statATTR", -1, 0, 10); } onInc: function() { service.bump("statATTR", 1, 0, 10); } }
          DotRow { label: "LUCK"; value: service.statLUCK; onDec: function() { service.bump("statLUCK", -1, 0, 10); } onInc: function() { service.bump("statLUCK", 1, 0, 10); } }
          DotRow { label: "MA"; value: service.statMA; onDec: function() { service.bump("statMA", -1, 0, 10); } onInc: function() { service.bump("statMA", 1, 0, 10); } }
          DotRow { label: "BODY"; value: service.statBODY; onDec: function() { service.bump("statBODY", -1, 0, 10); } onInc: function() { service.bump("statBODY", 1, 0, 10); } }
          DotRow { label: "EMP"; value: service.statEMP; onDec: function() { service.bump("statEMP", -1, 0, 10); } onInc: function() { service.bump("statEMP", 1, 0, 10); } }
          Text {
            width: parent.width
            text: "Run " + service.derivedRun() + "m · Leap " + service.derivedLeap() + "m · Carry " + service.derivedCarry() + "kg · Lift " + service.derivedLift() + "kg · Save " + service.derivedSave() + " · BTM " + service.derivedBTM()
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Util.alpha(Color.foreground, 0.6)
            font.family: Style.fontFamily; font.pixelSize: 10
          }

          SectionSeparator { }
          SectionHeader { text: "ARMOR (SP)" }
          DotRow { label: "Head"; value: service.armorHead; max: 30; onDec: function() { service.bump("armorHead", -1, 0, 30); } onInc: function() { service.bump("armorHead", 1, 0, 30); } }
          DotRow { label: "Torso"; value: service.armorTorso; max: 30; onDec: function() { service.bump("armorTorso", -1, 0, 30); } onInc: function() { service.bump("armorTorso", 1, 0, 30); } }
          DotRow { label: "R. Arm"; value: service.armorRArm; max: 30; onDec: function() { service.bump("armorRArm", -1, 0, 30); } onInc: function() { service.bump("armorRArm", 1, 0, 30); } }
          DotRow { label: "L. Arm"; value: service.armorLArm; max: 30; onDec: function() { service.bump("armorLArm", -1, 0, 30); } onInc: function() { service.bump("armorLArm", 1, 0, 30); } }
          DotRow { label: "R. Leg"; value: service.armorRLeg; max: 30; onDec: function() { service.bump("armorRLeg", -1, 0, 30); } onInc: function() { service.bump("armorRLeg", 1, 0, 30); } }
          DotRow { label: "L. Leg"; value: service.armorLLeg; max: 30; onDec: function() { service.bump("armorLLeg", -1, 0, 30); } onInc: function() { service.bump("armorLLeg", 1, 0, 30); } }

          SectionSeparator { }
          SectionHeader { text: "DAMAGE (boxes marked)" }
          DotRow { label: "Light"; value: service.dmgLight; max: 4; onDec: function() { service.bump("dmgLight", -1, 0, 4); } onInc: function() { service.bump("dmgLight", 1, 0, 4); } }
          DotRow { label: "Serious"; value: service.dmgSerious; max: 4; onDec: function() { service.bump("dmgSerious", -1, 0, 4); } onInc: function() { service.bump("dmgSerious", 1, 0, 4); } }
          DotRow { label: "Critical"; value: service.dmgCritical; max: 4; onDec: function() { service.bump("dmgCritical", -1, 0, 4); } onInc: function() { service.bump("dmgCritical", 1, 0, 4); } }
          DotRow { label: "Mortal"; value: service.dmgMortal; max: 4; onDec: function() { service.bump("dmgMortal", -1, 0, 4); } onInc: function() { service.bump("dmgMortal", 1, 0, 4); } }
          Text {
            width: parent.width
            text: "Stun: Light 0 · Serious -1 · Critical -2 · Mortal -3 or worse"
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Util.alpha(Color.foreground, 0.6)
            font.family: Style.fontFamily; font.pixelSize: 10
          }

          SectionSeparator { }
          SectionHeader { text: "SPECIAL ABILITY" }
          FieldRow { label: "Special"; initial: service.specName; onCommit: function(v) { service.specName = v; service.saveSoon(); } }
          DotRow { label: "Special lvl"; value: service.specLevel; onDec: function() { service.bump("specLevel", -1, 0, 10); } onInc: function() { service.bump("specLevel", 1, 0, 10); } }

          SectionSeparator { }
          SectionHeader { text: "ATTR SKILLS" }
          DotRow { label: "Personal Grooming"; value: service.personalGrooming; specKey: "personalGroomingSpec"; specTextKey: "personalGroomingSpecText"; specInitial: service.personalGroomingSpecText; onDec: function() { service.bump("personalGrooming", -1, 0, 10); } onInc: function() { service.bump("personalGrooming", 1, 0, 10); } }
          DotRow { label: "Wardrobe & Style"; value: service.wardrobeStyle; specKey: "wardrobeStyleSpec"; specTextKey: "wardrobeStyleSpecText"; specInitial: service.wardrobeStyleSpecText; onDec: function() { service.bump("wardrobeStyle", -1, 0, 10); } onInc: function() { service.bump("wardrobeStyle", 1, 0, 10); } }

          SectionSeparator { }
          SectionHeader { text: "BODY SKILLS" }
          DotRow { label: "Endurance"; value: service.endurance; specKey: "enduranceSpec"; specTextKey: "enduranceSpecText"; specInitial: service.enduranceSpecText; onDec: function() { service.bump("endurance", -1, 0, 10); } onInc: function() { service.bump("endurance", 1, 0, 10); } }
          DotRow { label: "Strength Feat"; value: service.strengthFeat; specKey: "strengthFeatSpec"; specTextKey: "strengthFeatSpecText"; specInitial: service.strengthFeatSpecText; onDec: function() { service.bump("strengthFeat", -1, 0, 10); } onInc: function() { service.bump("strengthFeat", 1, 0, 10); } }
          DotRow { label: "Swimming"; value: service.swimming; specKey: "swimmingSpec"; specTextKey: "swimmingSpecText"; specInitial: service.swimmingSpecText; onDec: function() { service.bump("swimming", -1, 0, 10); } onInc: function() { service.bump("swimming", 1, 0, 10); } }

          SectionSeparator { }
          SectionHeader { text: "COOL SKILLS" }
          DotRow { label: "Interrogation"; value: service.interrogation; specKey: "interrogationSpec"; specTextKey: "interrogationSpecText"; specInitial: service.interrogationSpecText; onDec: function() { service.bump("interrogation", -1, 0, 10); } onInc: function() { service.bump("interrogation", 1, 0, 10); } }
          DotRow { label: "Intimidate"; value: service.intimidate; specKey: "intimidateSpec"; specTextKey: "intimidateSpecText"; specInitial: service.intimidateSpecText; onDec: function() { service.bump("intimidate", -1, 0, 10); } onInc: function() { service.bump("intimidate", 1, 0, 10); } }
          DotRow { label: "Oratory"; value: service.oratory; specKey: "oratorySpec"; specTextKey: "oratorySpecText"; specInitial: service.oratorySpecText; onDec: function() { service.bump("oratory", -1, 0, 10); } onInc: function() { service.bump("oratory", 1, 0, 10); } }
          DotRow { label: "Resist Torture/Drugs"; value: service.resistTorture; specKey: "resistTortureSpec"; specTextKey: "resistTortureSpecText"; specInitial: service.resistTortureSpecText; onDec: function() { service.bump("resistTorture", -1, 0, 10); } onInc: function() { service.bump("resistTorture", 1, 0, 10); } }
          DotRow { label: "Streetwise"; value: service.streetwise; specKey: "streetwiseSpec"; specTextKey: "streetwiseSpecText"; specInitial: service.streetwiseSpecText; onDec: function() { service.bump("streetwise", -1, 0, 10); } onInc: function() { service.bump("streetwise", 1, 0, 10); } }

          SectionSeparator { }
          SectionHeader { text: "EMPATHY SKILLS" }
          DotRow { label: "Human Perception"; value: service.humanPerception; specKey: "humanPerceptionSpec"; specTextKey: "humanPerceptionSpecText"; specInitial: service.humanPerceptionSpecText; onDec: function() { service.bump("humanPerception", -1, 0, 10); } onInc: function() { service.bump("humanPerception", 1, 0, 10); } }
          DotRow { label: "Interview"; value: service.interview; specKey: "interviewSpec"; specTextKey: "interviewSpecText"; specInitial: service.interviewSpecText; onDec: function() { service.bump("interview", -1, 0, 10); } onInc: function() { service.bump("interview", 1, 0, 10); } }
          DotRow { label: "Leadership"; value: service.leadership; specKey: "leadershipSpec"; specTextKey: "leadershipSpecText"; specInitial: service.leadershipSpecText; onDec: function() { service.bump("leadership", -1, 0, 10); } onInc: function() { service.bump("leadership", 1, 0, 10); } }
          DotRow { label: "Seduction"; value: service.seduction; specKey: "seductionSpec"; specTextKey: "seductionSpecText"; specInitial: service.seductionSpecText; onDec: function() { service.bump("seduction", -1, 0, 10); } onInc: function() { service.bump("seduction", 1, 0, 10); } }
          DotRow { label: "Social"; value: service.social; specKey: "socialSpec"; specTextKey: "socialSpecText"; specInitial: service.socialSpecText; onDec: function() { service.bump("social", -1, 0, 10); } onInc: function() { service.bump("social", 1, 0, 10); } }
          DotRow { label: "Persuasion & Fast Talk"; value: service.persuasion; specKey: "persuasionSpec"; specTextKey: "persuasionSpecText"; specInitial: service.persuasionSpecText; onDec: function() { service.bump("persuasion", -1, 0, 10); } onInc: function() { service.bump("persuasion", 1, 0, 10); } }
          DotRow { label: "Perform"; value: service.perform; specKey: "performSpec"; specTextKey: "performSpecText"; specInitial: service.performSpecText; onDec: function() { service.bump("perform", -1, 0, 10); } onInc: function() { service.bump("perform", 1, 0, 10); } }

          SectionSeparator { }
          SectionHeader { text: "INT SKILLS" }
          DotRow { label: "Accounting"; value: service.accounting; specKey: "accountingSpec"; specTextKey: "accountingSpecText"; specInitial: service.accountingSpecText; onDec: function() { service.bump("accounting", -1, 0, 10); } onInc: function() { service.bump("accounting", 1, 0, 10); } }
          DotRow { label: "Anthropology"; value: service.anthropology; specKey: "anthropologySpec"; specTextKey: "anthropologySpecText"; specInitial: service.anthropologySpecText; onDec: function() { service.bump("anthropology", -1, 0, 10); } onInc: function() { service.bump("anthropology", 1, 0, 10); } }
          DotRow { label: "Awareness/Notice"; value: service.awareness; specKey: "awarenessSpec"; specTextKey: "awarenessSpecText"; specInitial: service.awarenessSpecText; onDec: function() { service.bump("awareness", -1, 0, 10); } onInc: function() { service.bump("awareness", 1, 0, 10); } }
          DotRow { label: "Biology"; value: service.biology; specKey: "biologySpec"; specTextKey: "biologySpecText"; specInitial: service.biologySpecText; onDec: function() { service.bump("biology", -1, 0, 10); } onInc: function() { service.bump("biology", 1, 0, 10); } }
          DotRow { label: "Botany"; value: service.botany; specKey: "botanySpec"; specTextKey: "botanySpecText"; specInitial: service.botanySpecText; onDec: function() { service.bump("botany", -1, 0, 10); } onInc: function() { service.bump("botany", 1, 0, 10); } }
          DotRow { label: "Chemistry"; value: service.chemistry; specKey: "chemistrySpec"; specTextKey: "chemistrySpecText"; specInitial: service.chemistrySpecText; onDec: function() { service.bump("chemistry", -1, 0, 10); } onInc: function() { service.bump("chemistry", 1, 0, 10); } }
          DotRow { label: "Composition"; value: service.composition; specKey: "compositionSpec"; specTextKey: "compositionSpecText"; specInitial: service.compositionSpecText; onDec: function() { service.bump("composition", -1, 0, 10); } onInc: function() { service.bump("composition", 1, 0, 10); } }
          DotRow { label: "Diagnose Illness"; value: service.diagnose; specKey: "diagnoseSpec"; specTextKey: "diagnoseSpecText"; specInitial: service.diagnoseSpecText; onDec: function() { service.bump("diagnose", -1, 0, 10); } onInc: function() { service.bump("diagnose", 1, 0, 10); } }
          DotRow { label: "Education & Gen Know"; value: service.education; specKey: "educationSpec"; specTextKey: "educationSpecText"; specInitial: service.educationSpecText; onDec: function() { service.bump("education", -1, 0, 10); } onInc: function() { service.bump("education", 1, 0, 10); } }
          DotRow { label: "Gamble"; value: service.gamble; specKey: "gambleSpec"; specTextKey: "gambleSpecText"; specInitial: service.gambleSpecText; onDec: function() { service.bump("gamble", -1, 0, 10); } onInc: function() { service.bump("gamble", 1, 0, 10); } }
          DotRow { label: "Geology"; value: service.geology; specKey: "geologySpec"; specTextKey: "geologySpecText"; specInitial: service.geologySpecText; onDec: function() { service.bump("geology", -1, 0, 10); } onInc: function() { service.bump("geology", 1, 0, 10); } }
          DotRow { label: "Hide/Evade"; value: service.hideEvade; specKey: "hideEvadeSpec"; specTextKey: "hideEvadeSpecText"; specInitial: service.hideEvadeSpecText; onDec: function() { service.bump("hideEvade", -1, 0, 10); } onInc: function() { service.bump("hideEvade", 1, 0, 10); } }
          DotRow { label: "History"; value: service.history; specKey: "historySpec"; specTextKey: "historySpecText"; specInitial: service.historySpecText; onDec: function() { service.bump("history", -1, 0, 10); } onInc: function() { service.bump("history", 1, 0, 10); } }
          DotRow { label: "Library Search"; value: service.librarySearch; specKey: "librarySearchSpec"; specTextKey: "librarySearchSpecText"; specInitial: service.librarySearchSpecText; onDec: function() { service.bump("librarySearch", -1, 0, 10); } onInc: function() { service.bump("librarySearch", 1, 0, 10); } }
          DotRow { label: "Mathematics"; value: service.mathematics; specKey: "mathematicsSpec"; specTextKey: "mathematicsSpecText"; specInitial: service.mathematicsSpecText; onDec: function() { service.bump("mathematics", -1, 0, 10); } onInc: function() { service.bump("mathematics", 1, 0, 10); } }
          DotRow { label: "Physics"; value: service.physics; specKey: "physicsSpec"; specTextKey: "physicsSpecText"; specInitial: service.physicsSpecText; onDec: function() { service.bump("physics", -1, 0, 10); } onInc: function() { service.bump("physics", 1, 0, 10); } }
          DotRow { label: "Programming"; value: service.programming; specKey: "programmingSpec"; specTextKey: "programmingSpecText"; specInitial: service.programmingSpecText; onDec: function() { service.bump("programming", -1, 0, 10); } onInc: function() { service.bump("programming", 1, 0, 10); } }
          DotRow { label: "Shadow/Track"; value: service.shadowTrack; specKey: "shadowTrackSpec"; specTextKey: "shadowTrackSpecText"; specInitial: service.shadowTrackSpecText; onDec: function() { service.bump("shadowTrack", -1, 0, 10); } onInc: function() { service.bump("shadowTrack", 1, 0, 10); } }
          DotRow { label: "Stock Market"; value: service.stockMarket; specKey: "stockMarketSpec"; specTextKey: "stockMarketSpecText"; specInitial: service.stockMarketSpecText; onDec: function() { service.bump("stockMarket", -1, 0, 10); } onInc: function() { service.bump("stockMarket", 1, 0, 10); } }
          DotRow { label: "System Knowledge"; value: service.systemKnowledge; specKey: "systemKnowledgeSpec"; specTextKey: "systemKnowledgeSpecText"; specInitial: service.systemKnowledgeSpecText; onDec: function() { service.bump("systemKnowledge", -1, 0, 10); } onInc: function() { service.bump("systemKnowledge", 1, 0, 10); } }
          DotRow { label: "Teaching"; value: service.teaching; specKey: "teachingSpec"; specTextKey: "teachingSpecText"; specInitial: service.teachingSpecText; onDec: function() { service.bump("teaching", -1, 0, 10); } onInc: function() { service.bump("teaching", 1, 0, 10); } }
          DotRow { label: "Wilderness Survival"; value: service.wilderness; specKey: "wildernessSpec"; specTextKey: "wildernessSpecText"; specInitial: service.wildernessSpecText; onDec: function() { service.bump("wilderness", -1, 0, 10); } onInc: function() { service.bump("wilderness", 1, 0, 10); } }
          DotRow { label: "Zoology"; value: service.zoology; specKey: "zoologySpec"; specTextKey: "zoologySpecText"; specInitial: service.zoologySpecText; onDec: function() { service.bump("zoology", -1, 0, 10); } onInc: function() { service.bump("zoology", 1, 0, 10); } }
          FieldRow { label: "Language 1"; initial: service.language1Name; onCommit: function(v) { service.language1Name = v; service.saveSoon(); } }
          DotRow { label: "Language 1 lvl"; value: service.language1; specKey: "language1Spec"; specTextKey: "language1SpecText"; specInitial: service.language1SpecText; onDec: function() { service.bump("language1", -1, 0, 10); } onInc: function() { service.bump("language1", 1, 0, 10); } }
          FieldRow { label: "Language 2"; initial: service.language2Name; onCommit: function(v) { service.language2Name = v; service.saveSoon(); } }
          DotRow { label: "Language 2 lvl"; value: service.language2; specKey: "language2Spec"; specTextKey: "language2SpecText"; specInitial: service.language2SpecText; onDec: function() { service.bump("language2", -1, 0, 10); } onInc: function() { service.bump("language2", 1, 0, 10); } }
          FieldRow { label: "Language 3"; initial: service.language3Name; onCommit: function(v) { service.language3Name = v; service.saveSoon(); } }
          DotRow { label: "Language 3 lvl"; value: service.language3; specKey: "language3Spec"; specTextKey: "language3SpecText"; specInitial: service.language3SpecText; onDec: function() { service.bump("language3", -1, 0, 10); } onInc: function() { service.bump("language3", 1, 0, 10); } }
          FieldRow { label: "Expert"; initial: service.expertName; onCommit: function(v) { service.expertName = v; service.saveSoon(); } }
          DotRow { label: "Expert lvl"; value: service.expert; specKey: "expertSpec"; specTextKey: "expertSpecText"; specInitial: service.expertSpecText; onDec: function() { service.bump("expert", -1, 0, 10); } onInc: function() { service.bump("expert", 1, 0, 10); } }

          SectionSeparator { }
          SectionHeader { text: "REF SKILLS" }
          DotRow { label: "Archery"; value: service.archery; specKey: "archerySpec"; specTextKey: "archerySpecText"; specInitial: service.archerySpecText; onDec: function() { service.bump("archery", -1, 0, 10); } onInc: function() { service.bump("archery", 1, 0, 10); } }
          DotRow { label: "Athletics"; value: service.athletics; specKey: "athleticsSpec"; specTextKey: "athleticsSpecText"; specInitial: service.athleticsSpecText; onDec: function() { service.bump("athletics", -1, 0, 10); } onInc: function() { service.bump("athletics", 1, 0, 10); } }
          DotRow { label: "Brawling"; value: service.brawling; specKey: "brawlingSpec"; specTextKey: "brawlingSpecText"; specInitial: service.brawlingSpecText; onDec: function() { service.bump("brawling", -1, 0, 10); } onInc: function() { service.bump("brawling", 1, 0, 10); } }
          DotRow { label: "Dance"; value: service.dance; specKey: "danceSpec"; specTextKey: "danceSpecText"; specInitial: service.danceSpecText; onDec: function() { service.bump("dance", -1, 0, 10); } onInc: function() { service.bump("dance", 1, 0, 10); } }
          DotRow { label: "Dodge & Escape"; value: service.dodge; specKey: "dodgeSpec"; specTextKey: "dodgeSpecText"; specInitial: service.dodgeSpecText; onDec: function() { service.bump("dodge", -1, 0, 10); } onInc: function() { service.bump("dodge", 1, 0, 10); } }
          DotRow { label: "Driving"; value: service.driving; specKey: "drivingSpec"; specTextKey: "drivingSpecText"; specInitial: service.drivingSpecText; onDec: function() { service.bump("driving", -1, 0, 10); } onInc: function() { service.bump("driving", 1, 0, 10); } }
          DotRow { label: "Fencing"; value: service.fencing; specKey: "fencingSpec"; specTextKey: "fencingSpecText"; specInitial: service.fencingSpecText; onDec: function() { service.bump("fencing", -1, 0, 10); } onInc: function() { service.bump("fencing", 1, 0, 10); } }
          DotRow { label: "Handgun"; value: service.handgun; specKey: "handgunSpec"; specTextKey: "handgunSpecText"; specInitial: service.handgunSpecText; onDec: function() { service.bump("handgun", -1, 0, 10); } onInc: function() { service.bump("handgun", 1, 0, 10); } }
          DotRow { label: "Heavy Weapons"; value: service.heavyWeapons; specKey: "heavyWeaponsSpec"; specTextKey: "heavyWeaponsSpecText"; specInitial: service.heavyWeaponsSpecText; onDec: function() { service.bump("heavyWeapons", -1, 0, 10); } onInc: function() { service.bump("heavyWeapons", 1, 0, 10); } }
          DotRow { label: "Melee"; value: service.melee; specKey: "meleeSpec"; specTextKey: "meleeSpecText"; specInitial: service.meleeSpecText; onDec: function() { service.bump("melee", -1, 0, 10); } onInc: function() { service.bump("melee", 1, 0, 10); } }
          DotRow { label: "Motorcycle"; value: service.motorcycle; specKey: "motorcycleSpec"; specTextKey: "motorcycleSpecText"; specInitial: service.motorcycleSpecText; onDec: function() { service.bump("motorcycle", -1, 0, 10); } onInc: function() { service.bump("motorcycle", 1, 0, 10); } }
          DotRow { label: "Operate Hvy. Machinery"; value: service.operateHvy; specKey: "operateHvySpec"; specTextKey: "operateHvySpecText"; specInitial: service.operateHvySpecText; onDec: function() { service.bump("operateHvy", -1, 0, 10); } onInc: function() { service.bump("operateHvy", 1, 0, 10); } }
          DotRow { label: "Pilot (Gyro)"; value: service.pilotGyro; specKey: "pilotGyroSpec"; specTextKey: "pilotGyroSpecText"; specInitial: service.pilotGyroSpecText; onDec: function() { service.bump("pilotGyro", -1, 0, 10); } onInc: function() { service.bump("pilotGyro", 1, 0, 10); } }
          DotRow { label: "Pilot (Fixed Wing)"; value: service.pilotFixed; specKey: "pilotFixedSpec"; specTextKey: "pilotFixedSpecText"; specInitial: service.pilotFixedSpecText; onDec: function() { service.bump("pilotFixed", -1, 0, 10); } onInc: function() { service.bump("pilotFixed", 1, 0, 10); } }
          DotRow { label: "Pilot (Dirigible)"; value: service.pilotDirigible; specKey: "pilotDirigibleSpec"; specTextKey: "pilotDirigibleSpecText"; specInitial: service.pilotDirigibleSpecText; onDec: function() { service.bump("pilotDirigible", -1, 0, 10); } onInc: function() { service.bump("pilotDirigible", 1, 0, 10); } }
          DotRow { label: "Pilot (Vect. Thrust)"; value: service.pilotVector; specKey: "pilotVectorSpec"; specTextKey: "pilotVectorSpecText"; specInitial: service.pilotVectorSpecText; onDec: function() { service.bump("pilotVector", -1, 0, 10); } onInc: function() { service.bump("pilotVector", 1, 0, 10); } }
          DotRow { label: "Rifle"; value: service.rifle; specKey: "rifleSpec"; specTextKey: "rifleSpecText"; specInitial: service.rifleSpecText; onDec: function() { service.bump("rifle", -1, 0, 10); } onInc: function() { service.bump("rifle", 1, 0, 10); } }
          DotRow { label: "Stealth"; value: service.stealth; specKey: "stealthSpec"; specTextKey: "stealthSpecText"; specInitial: service.stealthSpecText; onDec: function() { service.bump("stealth", -1, 0, 10); } onInc: function() { service.bump("stealth", 1, 0, 10); } }
          DotRow { label: "Submachinegun"; value: service.submachinegun; specKey: "submachinegunSpec"; specTextKey: "submachinegunSpecText"; specInitial: service.submachinegunSpecText; onDec: function() { service.bump("submachinegun", -1, 0, 10); } onInc: function() { service.bump("submachinegun", 1, 0, 10); } }
          FieldRow { label: "Martial Art 1"; initial: service.martial1Name; onCommit: function(v) { service.martial1Name = v; service.saveSoon(); } }
          DotRow { label: "Martial Art 1 lvl"; value: service.martial1; specKey: "martial1Spec"; specTextKey: "martial1SpecText"; specInitial: service.martial1SpecText; onDec: function() { service.bump("martial1", -1, 0, 10); } onInc: function() { service.bump("martial1", 1, 0, 10); } }
          FieldRow { label: "Martial Art 2"; initial: service.martial2Name; onCommit: function(v) { service.martial2Name = v; service.saveSoon(); } }
          DotRow { label: "Martial Art 2 lvl"; value: service.martial2; specKey: "martial2Spec"; specTextKey: "martial2SpecText"; specInitial: service.martial2SpecText; onDec: function() { service.bump("martial2", -1, 0, 10); } onInc: function() { service.bump("martial2", 1, 0, 10); } }
          FieldRow { label: "Martial Art 3"; initial: service.martial3Name; onCommit: function(v) { service.martial3Name = v; service.saveSoon(); } }
          DotRow { label: "Martial Art 3 lvl"; value: service.martial3; specKey: "martial3Spec"; specTextKey: "martial3SpecText"; specInitial: service.martial3SpecText; onDec: function() { service.bump("martial3", -1, 0, 10); } onInc: function() { service.bump("martial3", 1, 0, 10); } }

          SectionSeparator { }
          SectionHeader { text: "TECH SKILLS" }
          DotRow { label: "Aero Tech"; value: service.aeroTech; specKey: "aeroTechSpec"; specTextKey: "aeroTechSpecText"; specInitial: service.aeroTechSpecText; onDec: function() { service.bump("aeroTech", -1, 0, 10); } onInc: function() { service.bump("aeroTech", 1, 0, 10); } }
          DotRow { label: "AV Tech"; value: service.avTech; specKey: "avTechSpec"; specTextKey: "avTechSpecText"; specInitial: service.avTechSpecText; onDec: function() { service.bump("avTech", -1, 0, 10); } onInc: function() { service.bump("avTech", 1, 0, 10); } }
          DotRow { label: "Basic Tech"; value: service.basicTech; specKey: "basicTechSpec"; specTextKey: "basicTechSpecText"; specInitial: service.basicTechSpecText; onDec: function() { service.bump("basicTech", -1, 0, 10); } onInc: function() { service.bump("basicTech", 1, 0, 10); } }
          DotRow { label: "Cryotank Operation"; value: service.cryotank; specKey: "cryotankSpec"; specTextKey: "cryotankSpecText"; specInitial: service.cryotankSpecText; onDec: function() { service.bump("cryotank", -1, 0, 10); } onInc: function() { service.bump("cryotank", 1, 0, 10); } }
          DotRow { label: "Cyberdeck Design"; value: service.cyberdeckDesign; specKey: "cyberdeckDesignSpec"; specTextKey: "cyberdeckDesignSpecText"; specInitial: service.cyberdeckDesignSpecText; onDec: function() { service.bump("cyberdeckDesign", -1, 0, 10); } onInc: function() { service.bump("cyberdeckDesign", 1, 0, 10); } }
          DotRow { label: "Cyber Tech"; value: service.cyberTech; specKey: "cyberTechSpec"; specTextKey: "cyberTechSpecText"; specInitial: service.cyberTechSpecText; onDec: function() { service.bump("cyberTech", -1, 0, 10); } onInc: function() { service.bump("cyberTech", 1, 0, 10); } }
          DotRow { label: "Demolitions"; value: service.demolitions; specKey: "demolitionsSpec"; specTextKey: "demolitionsSpecText"; specInitial: service.demolitionsSpecText; onDec: function() { service.bump("demolitions", -1, 0, 10); } onInc: function() { service.bump("demolitions", 1, 0, 10); } }
          DotRow { label: "Disguise"; value: service.disguise; specKey: "disguiseSpec"; specTextKey: "disguiseSpecText"; specInitial: service.disguiseSpecText; onDec: function() { service.bump("disguise", -1, 0, 10); } onInc: function() { service.bump("disguise", 1, 0, 10); } }
          DotRow { label: "Elect. Security"; value: service.electSecurity; specKey: "electSecuritySpec"; specTextKey: "electSecuritySpecText"; specInitial: service.electSecuritySpecText; onDec: function() { service.bump("electSecurity", -1, 0, 10); } onInc: function() { service.bump("electSecurity", 1, 0, 10); } }
          DotRow { label: "Electronics"; value: service.electronics; specKey: "electronicsSpec"; specTextKey: "electronicsSpecText"; specInitial: service.electronicsSpecText; onDec: function() { service.bump("electronics", -1, 0, 10); } onInc: function() { service.bump("electronics", 1, 0, 10); } }
          DotRow { label: "First Aid"; value: service.firstAid; specKey: "firstAidSpec"; specTextKey: "firstAidSpecText"; specInitial: service.firstAidSpecText; onDec: function() { service.bump("firstAid", -1, 0, 10); } onInc: function() { service.bump("firstAid", 1, 0, 10); } }
          DotRow { label: "Forgery"; value: service.forgery; specKey: "forgerySpec"; specTextKey: "forgerySpecText"; specInitial: service.forgerySpecText; onDec: function() { service.bump("forgery", -1, 0, 10); } onInc: function() { service.bump("forgery", 1, 0, 10); } }
          DotRow { label: "Gyro Tech"; value: service.gyroTech; specKey: "gyroTechSpec"; specTextKey: "gyroTechSpecText"; specInitial: service.gyroTechSpecText; onDec: function() { service.bump("gyroTech", -1, 0, 10); } onInc: function() { service.bump("gyroTech", 1, 0, 10); } }
          DotRow { label: "Paint or Draw"; value: service.paintDraw; specKey: "paintDrawSpec"; specTextKey: "paintDrawSpecText"; specInitial: service.paintDrawSpecText; onDec: function() { service.bump("paintDraw", -1, 0, 10); } onInc: function() { service.bump("paintDraw", 1, 0, 10); } }
          DotRow { label: "Photo & Film"; value: service.photoFilm; specKey: "photoFilmSpec"; specTextKey: "photoFilmSpecText"; specInitial: service.photoFilmSpecText; onDec: function() { service.bump("photoFilm", -1, 0, 10); } onInc: function() { service.bump("photoFilm", 1, 0, 10); } }
          DotRow { label: "Pharmaceuticals"; value: service.pharma; specKey: "pharmaSpec"; specTextKey: "pharmaSpecText"; specInitial: service.pharmaSpecText; onDec: function() { service.bump("pharma", -1, 0, 10); } onInc: function() { service.bump("pharma", 1, 0, 10); } }
          DotRow { label: "Pick Lock"; value: service.pickLock; specKey: "pickLockSpec"; specTextKey: "pickLockSpecText"; specInitial: service.pickLockSpecText; onDec: function() { service.bump("pickLock", -1, 0, 10); } onInc: function() { service.bump("pickLock", 1, 0, 10); } }
          DotRow { label: "Pick Pocket"; value: service.pickPocket; specKey: "pickPocketSpec"; specTextKey: "pickPocketSpecText"; specInitial: service.pickPocketSpecText; onDec: function() { service.bump("pickPocket", -1, 0, 10); } onInc: function() { service.bump("pickPocket", 1, 0, 10); } }
          DotRow { label: "Play Instrument"; value: service.playInstrument; specKey: "playInstrumentSpec"; specTextKey: "playInstrumentSpecText"; specInitial: service.playInstrumentSpecText; onDec: function() { service.bump("playInstrument", -1, 0, 10); } onInc: function() { service.bump("playInstrument", 1, 0, 10); } }
          DotRow { label: "Weaponsmith"; value: service.weaponsmith; specKey: "weaponsmithSpec"; specTextKey: "weaponsmithSpecText"; specInitial: service.weaponsmithSpecText; onDec: function() { service.bump("weaponsmith", -1, 0, 10); } onInc: function() { service.bump("weaponsmith", 1, 0, 10); } }
          DotRow { label: "Weapons Tech"; value: service.weaponsTech; specKey: "weaponsTechSpec"; specTextKey: "weaponsTechSpecText"; specInitial: service.weaponsTechSpecText; onDec: function() { service.bump("weaponsTech", -1, 0, 10); } onInc: function() { service.bump("weaponsTech", 1, 0, 10); } }
          FieldRow { label: "Other A"; initial: service.otherAName; onCommit: function(v) { service.otherAName = v; service.saveSoon(); } }
          DotRow { label: "Other A lvl"; value: service.otherA; specKey: "otherASpec"; specTextKey: "otherASpecText"; specInitial: service.otherASpecText; onDec: function() { service.bump("otherA", -1, 0, 10); } onInc: function() { service.bump("otherA", 1, 0, 10); } }
          FieldRow { label: "Other B"; initial: service.otherBName; onCommit: function(v) { service.otherBName = v; service.saveSoon(); } }
          DotRow { label: "Other B lvl"; value: service.otherB; specKey: "otherBSpec"; specTextKey: "otherBSpecText"; specInitial: service.otherBSpecText; onDec: function() { service.bump("otherB", -1, 0, 10); } onInc: function() { service.bump("otherB", 1, 0, 10); } }
          FieldRow { label: "Other C"; initial: service.otherCName; onCommit: function(v) { service.otherCName = v; service.saveSoon(); } }
          DotRow { label: "Other C lvl"; value: service.otherC; specKey: "otherCSpec"; specTextKey: "otherCSpecText"; specInitial: service.otherCSpecText; onDec: function() { service.bump("otherC", -1, 0, 10); } onInc: function() { service.bump("otherC", 1, 0, 10); } }

          SectionSeparator { }
          SectionHeader { text: "CYBERNETICS" }
          MultiLine { label: "Cybernetics (Type | HL | Cost)"; initial: service.cybernetics; onCommit: function(v) { service.cybernetics = v; service.saveSoon(); } }
          FieldRow { label: "Total HL"; initial: service.totalHL; onCommit: function(v) { service.totalHL = v; service.saveSoon(); } }
          FieldRow { label: "Total Cost"; initial: service.totalCost; onCommit: function(v) { service.totalCost = v; service.saveSoon(); } }

          SectionSeparator { }
          SectionHeader { text: "LIFEPATH" }
          FieldRow { label: "Style"; initial: service.style; onCommit: function(v) { service.style = v; service.saveSoon(); } }
          FieldRow { label: "Clothes"; initial: service.clothes; onCommit: function(v) { service.clothes = v; service.saveSoon(); } }
          FieldRow { label: "Hair"; initial: service.hair; onCommit: function(v) { service.hair = v; service.saveSoon(); } }
          FieldRow { label: "Affections"; initial: service.affections; onCommit: function(v) { service.affections = v; service.saveSoon(); } }
          FieldRow { label: "Ethnicity"; initial: service.ethnicity; onCommit: function(v) { service.ethnicity = v; service.saveSoon(); } }
          FieldRow { label: "Language"; initial: service.lifepathLang; onCommit: function(v) { service.lifepathLang = v; service.saveSoon(); } }
          MultiLine { label: "Family Background"; initial: service.familyBg; onCommit: function(v) { service.familyBg = v; service.saveSoon(); } }
          MultiLine { label: "Motivations"; initial: service.motivations; onCommit: function(v) { service.motivations = v; service.saveSoon(); } }
          MultiLine { label: "Traits"; initial: service.traits; onCommit: function(v) { service.traits = v; service.saveSoon(); } }
          MultiLine { label: "Valued Person"; initial: service.valuedPerson; onCommit: function(v) { service.valuedPerson = v; service.saveSoon(); } }
          MultiLine { label: "Value Most"; initial: service.valueMost; onCommit: function(v) { service.valueMost = v; service.saveSoon(); } }
          MultiLine { label: "Feel About People"; initial: service.feelPeople; onCommit: function(v) { service.feelPeople = v; service.saveSoon(); } }
          MultiLine { label: "Valued Possession"; initial: service.valuedPoss; onCommit: function(v) { service.valuedPoss = v; service.saveSoon(); } }
          MultiLine { label: "Life Events"; initial: service.lifeEvents; onCommit: function(v) { service.lifeEvents = v; service.saveSoon(); } }

          SectionSeparator { }
          SectionHeader { text: "GEAR & WEAPONS" }
          MultiLine { label: "Gear (Type | Cost | Wt)"; initial: service.gear; onCommit: function(v) { service.gear = v; service.saveSoon(); } }
          MultiLine { label: "Weapons"; initial: service.weapons; onCommit: function(v) { service.weapons = v; service.saveSoon(); } }

          SectionSeparator { }
          SectionHeader { text: "NOTES" }
          MultiLine { label: "Chipped Skills"; initial: service.chipped; onCommit: function(v) { service.chipped = v; service.saveSoon(); } }
          MultiLine { label: "OOC instructions to LLM"; initial: service.ooc; onCommit: function(v) { service.ooc = v; service.saveSoon(); } }

          SectionSeparator { }
          SectionHeader { text: "CHARACTER FILE (export / import)" }
          Text {
            width: parent.width
            text: "Folder: " + cfg.outputDir
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            color: Util.alpha(Color.foreground, 0.6)
            font.family: Style.fontFamily; font.pixelSize: 10
          }
          Text {
            width: parent.width
            text: "File: " + service.exportFileName()
            textFormat: Text.PlainText
            elide: Text.ElideMiddle
            color: Color.accent
            font.family: Style.fontFamily; font.pixelSize: 11; font.bold: true
          }
          Row {
            width: parent.width; spacing: 8
            SheetButton { label: "Export"; hint: "Save plain-text sheet, named per character"; onPressed: function() { root.flushAll(); service.exportNow(); } }
            SheetButton { label: "Copy"; hint: "Copy plain-text sheet for LLM chat"; onPressed: function() { root.flushAll(); service.copyForLLM(); } }
            SheetButton { label: "Clear…"; hint: "Reset the whole sheet (asks first)"; onPressed: function() { confirm.opened = true; } }
          }
          Text {
            width: parent.width
            text: service.status
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            color: Color.accent
            font.family: Style.fontFamily; font.pixelSize: 10
          }
          Text {
            width: parent.width
            text: "Import plain-text sheet file:"
            textFormat: Text.PlainText
            color: Util.alpha(Color.foreground, 0.65)
            font.family: Style.fontFamily; font.pixelSize: 11
          }
          TextField {
            id: importField
            width: parent.width
            text: cfg.outputDir + "/"
            placeholderText: "Full path to an exported .txt sheet"
            onAccepted: { service.importSheet(text); }
          }
          Row {
            width: parent.width; spacing: 8
            SheetButton { label: "Import"; hint: "Load sheet from the path above"; onPressed: function() { service.importSheet(importField.text); } }
          }
        }

        // Jump highlight: floats above the rows (direct Flickable child so
        // the Column never repositions it), fades via glowTimer below.
        Rectangle {
          id: searchGlow
          width: body.width; height: 0
          radius: 8
          color: Util.alpha(Color.accent, 0.16)
          opacity: 0
          Behavior on opacity { NumberAnimation { duration: 250 } }
        }
      }

      Rectangle {
        x: 16; y: parent.height - 56; width: parent.width - 32; height: 1
        color: Util.alpha(Color.foreground, 0.075)
      }
      Text {
        x: 18; y: parent.height - 40; width: parent.width - 36
        text: cfg.keepOpen ? "Pinned — unpin to close · drag the header to move" : "Drag the header to move · X or Esc closes · pin blocks closing"
        textFormat: Text.PlainText; elide: Text.ElideRight
        color: Util.alpha(Color.foreground, 0.45)
        font.family: Style.fontFamily; font.pixelSize: 10
      }
    }

    ConfirmDialog {
      id: confirm
      anchors.fill: parent
      message: "Clear the entire sheet? All fields return to blank defaults. This cannot be undone."
      cancelText: "Keep"
      confirmText: "Clear"
      onCanceled: opened = false
      onConfirmed: { opened = false; service.clearSheet(); }
    }
  }

  // ---- reusable rows ----
  // Sheet section title. Unchanged layout; search only dims it via searchDim.
  component SectionHeader: Text {
    property bool isSectionHeader: true
    property int headerLevel: 0
    property bool searchDim: false
    opacity: searchDim ? 0.35 : 1
    textFormat: Text.PlainText
    color: Color.accent
    font.family: Style.fontFamily
    font.pixelSize: 10
    font.bold: true
    font.letterSpacing: 1.2
  }

  // Divider between sheet groups, mirroring the sections of the paper sheet.
  component SectionSeparator: Item {
    width: parent ? parent.width : 0
    height: 12
    Rectangle {
      anchors.verticalCenter: parent.verticalCenter
      width: parent.width; height: 1
      color: Util.alpha(Color.accent, 0.28)
    }
  }

  component FieldRow: Row {
    property string label: ""
    property string initial: ""
    // search: dimmed when the query matches neither label nor section
    property bool searchMatch: true
    opacity: searchMatch ? 1 : 0.22
    signal commit(string value)
    // Push the visible text into the sheet (used by the Set button and
    // by flushAll before export — committing an unchanged value is a no-op).
    function flush() { commit(tf.text); }
    width: parent ? parent.width : 0
    spacing: 8
    // Re-push service values (e.g. after Clear): user typing breaks the
    // text binding, so service-driven changes are re-applied here.
    onInitialChanged: tf.text = initial
    Text {
      text: parent.label; textFormat: Text.PlainText
      width: 96
      color: Util.alpha(Color.foreground, 0.65)
      font.family: Style.fontFamily; font.pixelSize: 11
      anchors.verticalCenter: parent.verticalCenter
      elide: Text.ElideRight
    }
    TextField {
      id: tf
      width: parent.width - 96 - 42 - parent.spacing * 2
      text: parent.initial
      placeholderText: parent.label
      onEditingFinished: { parent.commit(text); }
      onAccepted: { parent.commit(text); }
    }
    SheetAction {
      icon: "check"
      hint: "Set " + parent.label
      anchors.verticalCenter: parent.verticalCenter
      onTriggered: function() { parent.flush(); service.pokeStatus("Set " + parent.label + "."); }
    }
  }

  component DotRow: Column {
    id: dotRoot
    property string label: ""
    property int value: 0
    property int max: 10
    // search: dimmed when the query matches neither label nor section
    property bool searchMatch: true
    opacity: searchMatch ? 1 : 0.22
    // Optional specialization: pass specKey/specTextKey/specInitial and the
    // row gains a star toggle plus a small subtext field for the
    // specialization (e.g. Handgun -> pistols).
    property string specKey: ""
    property string specTextKey: ""
    property string specInitial: ""
    signal dec()
    signal inc()
    // Flush contract for export (see FieldRow): commit visible subtext.
    function flush() {
      if (specTextKey !== "" && specField) specField.commitField();
    }
    width: parent ? parent.width : 0
    spacing: 2
    onSpecInitialChanged: { if (specField) specField.text = specInitial; }
    Row {
      width: dotRoot.width
      spacing: 6
      Text {
        text: dotRoot.label; textFormat: Text.PlainText
        width: Math.max(40, dotRoot.width - (dotRoot.specKey !== "" ? 192 : 150))
        color: Color.foreground
        font.family: Style.fontFamily; font.pixelSize: 11
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
      }
      WidgetButton { text: "−"; onPressed: function() { dotRoot.dec(); } }
      Text {
        text: dotRoot.value + "/" + dotRoot.max; textFormat: Text.PlainText
        width: 40; horizontalAlignment: Text.AlignHCenter
        color: Color.accent
        font.family: Style.fontFamily; font.pixelSize: 11; font.bold: true
        anchors.verticalCenter: parent.verticalCenter
      }
      WidgetButton { text: "+"; onPressed: function() { dotRoot.inc(); } }
      WidgetButton {
        visible: dotRoot.specKey !== ""
        text: "★"
        active: dotRoot.specKey !== "" ? !!service[dotRoot.specKey] : false
        onPressed: function() {
          service[dotRoot.specKey] = !service[dotRoot.specKey];
          service.saveSoon();
        }
      }
    }
    Row {
      visible: dotRoot.specKey !== "" && !!service[dotRoot.specKey]
      width: dotRoot.width
      spacing: 6
      Text {
        text: "↳ spec"; textFormat: Text.PlainText
        width: 84
        color: Util.alpha(Color.accent, 0.8)
        font.family: Style.fontFamily; font.pixelSize: 10
        anchors.verticalCenter: parent.verticalCenter
      }
      TextField {
        id: specField
        width: dotRoot.width - 84 - 6
        text: dotRoot.specInitial
        placeholderText: "Specialization…"
        font.pixelSize: 10
        function commitField() {
          if (dotRoot.specTextKey !== "") service[dotRoot.specTextKey] = text;
        }
        onEditingFinished: { commitField(); }
        onAccepted: { commitField(); }
      }
    }
  }

  component MultiLine: Column {
    property string label: ""
    property string initial: ""
    // search: dimmed when the query matches neither label nor section
    property bool searchMatch: true
    opacity: searchMatch ? 1 : 0.22
    signal commit(string value)
    // Same flush contract as FieldRow (see above).
    function flush() { commit(ta.text); }
    width: parent ? parent.width : 0
    spacing: 4
    // Same re-push as FieldRow (committing the identical value is a no-op).
    onInitialChanged: ta.text = initial
    Row {
      width: parent.width
      spacing: 6
      Text {
        text: parent.parent.label; textFormat: Text.PlainText
        width: parent.width - 42 - parent.spacing
        color: Util.alpha(Color.foreground, 0.65)
        font.family: Style.fontFamily; font.pixelSize: 11
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
      }
      SheetAction {
        icon: "check"
        hint: "Set " + parent.parent.label
        anchors.verticalCenter: parent.verticalCenter
        onTriggered: function() { flush(); service.pokeStatus("Set " + label + "."); }
      }
    }
    QQC.TextArea {
      id: ta
      width: parent.width
      text: parent.initial
      placeholderText: parent.label
      wrapMode: Text.Wrap
      font.family: Style.fontFamily; font.pixelSize: 11
      color: Color.foreground
      selectionColor: Color.accent
      background: Rectangle {
        color: Util.alpha(Color.foreground, 0.05)
        border.width: 1
        border.color: Util.alpha(Color.foreground, 0.15)
        radius: 8
      }
      onTextChanged: { parent.commit(text); }
    }
  }
}
