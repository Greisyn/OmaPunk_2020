# Cyberpunk Sheet — floating Omarchy plugin

Corner-anchored Cyberpunk 2020 character sheet editor, in the style of
`local.werewolf-sheet`.

## Install
```bash
omarchy plugin add https://github.com/Greisyn/OmaPunk_2020.git --enable
```

- **Edit like the PDF**: identity header, 9 STATS (+auto-derived Run/Leap/
  Carry/Lift/Save/BTM), armor SP per location, wound boxes, role Special
  Ability, all CP2020 skills by stat (ATTR/BODY/COOL/EMPATHY/INT/REF/TECH)
  plus named Language/Expert/Martial Art/Other skills, cybernetics with
  HL/cost totals, full Lifepath, gear, weapons, chipped skills.
- **Export plain text for LLM roleplay**: CP2020 sections with the skill-hint
  line (`STAT + Skill + 1d10`) and referee instructions.
- **Floating + corner-anchored**: dwell the corner handle to reveal,
  leave to collapse, pin open, Esc closes. Corner (TL/TR/BL/BR) + size in settings.
- **Output path is configurable**: settings panel + sheet footer. Default:
  `~/Pictures/<Handle>.txt`
- **Theme-aware**: all chrome uses `Color.*` / `Style.*` — omarchy themes repaint it live.
- **Specializations**: every skill row has a ★ toggle; starring it reveals a
  small subtext line to write the specialization (e.g. Handgun → pistols).
  Exported as `Skill: 8/10 ★ [pistols]` so the LLM knows it too.
- **Floating anchor (drives-style)**: small always-visible square in a screen
  corner showing your `anchor-icon.png` — hover-dwell or tap reveals the
  sheet, leaving collapses it. Toggleable (off = bar icon only), resizable.
- **Drag to move, snap to lock**: click-hold the square and drag it anywhere on
  the workspace; drop near a corner to snap/lock it there, else it floats free
  (card opens beside it). Settings has a lock switch to disable dragging, and
  corner buttons to snap it back. Placement persists in the prefs JSON.
- **Logo**: `CyberTheme.png` from `~/Pictures` at the top of the card and
  settings panel (`logo.png`); same art as anchor + bar symbol
  (`anchor-icon.png`). To swap art later, replace those two files and run
  `omarchy-shell shell rescanPlugins`.

## Files

- `manifest.json` — service + bar-widget
- `Service.qml` — character data, JSON persistence, export, per-screen windows, IPC
- `CyberSheet.js` — field lists + plain-text renderer/parser
- `SheetWindow.qml` — floating editor card (logo-only header, pin/close actions)
- `SheetGlyph.qml` / `SheetAction.qml` — theme-aware line-icon buttons (pin/close/check style)
- `SheetButton.qml` — filled Export/Copy/Clear/Import buttons
- `SheetConfig.qml` — corner/size/motion/output prefs → `~/.config/omarchy/local.cyberpunk-sheet.json`
- `BarWidget.qml` — bar icon (left = toggle, right = settings)
- `Panel.qml` — settings (anchor square, corner, size, output path, motion)
- `logo.png` — Cyberpunk logo header
- `anchor-icon.png` — icon for the floating square + bar

## Actions

- **Export .txt / Copy for LLM** — filled buttons in the card's CHARACTER FILE
  section; exports save as `<Handle>.txt` inside the configured output folder so
  each character gets its own file. Every text row has a ✓ Set button that commits
  exactly what's visible, and Export/Copy auto-commit all fields first — typed
  text is never lost even if you never tabbed out of the field.
- **Import** — paste the path of an exported sheet and press Import to load it
  back. Also via `omarchy-shell local.cyberpunk-sheet importSheet`
  (uses the settings' import path).
- **Clear…** — asks "Clear the entire sheet? …" via a confirmation dialog, then
  resets to a true blank sheet: empty fields, all stats and skills 0.
- **Scrolling** — mouse wheel / touchpad, drag the always-on scrollbar,
  or PageUp / PageDown when the card is focused.

## Note: developing this plugin

Hot-reload (`shell rescanPlugins` / file watcher) reliably picks up
`SheetWindow.qml` / `Panel.qml` / `BarWidget.qml` changes, but does **not**
reliably re-create the long-running `Service` — after editing
`Service.qml` (or `CyberSheet.js` behavior), run:

```bash
omarchy restart shell
```

## State

- Character JSON: `~/.config/omarchy/local.cyberpunk-sheet-character.json`
- Prefs JSON: `~/.config/omarchy/local.cyberpunk-sheet.json`
- Export default: `~/Pictures/<Handle>.txt`

## Commands

```bash
omarchy-shell local.cyberpunk-sheet show
omarchy-shell local.cyberpunk-sheet hide
omarchy-shell local.cyberpunk-sheet toggle
omarchy-shell local.cyberpunk-sheet exportSheet
omarchy-shell local.cyberpunk-sheet status
omarchy-shell shell rescanPlugins
omarchy restart shell
```
