# Cyberpunk Sheet — bar-icon Omarchy plugin

Bar-icon-driven Cyberpunk 2020 character sheet editor

## Install
```bash
omarchy plugin add https://github.com/Greisyn/OmaPunk_2020.git --enable
```
<img width="1068" height="949" alt="image" src="https://github.com/user-attachments/assets/25180c6c-3479-4e02-8063-a024dcd163e6" />

- **Identity headers**: 9 STATS (+auto-derived Run/Leap/
  Carry/Lift/Save/BTM), armor SP per location, wound boxes, role Special
  Ability, all CP2020 skills by stat (ATTR/BODY/COOL/EMPATHY/INT/REF/TECH)
  plus named Language/Expert/Martial Art/Other skills, cybernetics with
  HL/cost totals, full Lifepath, gear, weapons, chipped skills.
- **Export plain text for LLM roleplay**: CP2020 sections with the skill-hint
  line (`STAT + Skill + 1d10`) and referee instructions.
- **Bar icon only, no floating anchor**: left-click the bar icon toggles the
  sheet card, right-click opens settings. Both cards stay open — no
  hover-dwell, no auto-collapse, no click-off dismiss. The sheet closes via
  its X (or Esc / bar toggle); pin blocks closing entirely until unpinned.
  Settings closes itself a few moments after the mouse leaves it (or
  instantly on an outside click) — or via its Close button / another
  right-click.
- **Output path is configurable**: settings panel + sheet footer. Default:
  `~/Pictures/<Handle>.txt`
- **Field search**: the bar above the sheet filters entry spots by name —
  matching rows stay bright while the rest dim (searching `ref` shows the
  whole REF SKILLS group). Enter jumps to the next match with a highlight flash
  (Shift+Enter goes back), Esc clears the query.
- **Theme-aware**: all chrome uses `Color.*` / `Style.*` — omarchy themes repaint it live.
- **Specializations**: every skill row has a ★ toggle; starring it reveals a
  small subtext line to write the specialization (e.g. Handgun → pistols).
  Exported as `Skill: 8/10 ★ [pistols]` so the LLM knows it too.
- **Card placement**: parks in a screen corner (TL/TR/BL/BR) + size in
  settings — or drag the card by its header to float it anywhere on the
  workspace; the drop position is saved and corner buttons snap it back.
- **Logo**: `logo.png` at the top of the card and
  settings panel (same art as the bar symbol
  (`anchor-icon.png`)). To swap art later, replace those two files and run
  `omarchy-shell shell rescanPlugins`.

## Files

- `manifest.json` — service + bar-widget
- `Service.qml` — character data, JSON persistence, export, per-screen windows, IPC
- `CyberSheet.js` — field lists + plain-text renderer/parser
- `SheetWindow.qml` — sheet editor card (logo header, pin/close actions, field search)
- `SheetGlyph.qml` / `SheetAction.qml` — theme-aware line-icon buttons (pin/close/check style)
- `SheetButton.qml` — filled Export/Copy/Clear/Import buttons
- `SheetConfig.qml` — card corner/size/motion/output prefs → `~/.config/omarchy/local.cyberpunk-sheet.json`
- `BarWidget.qml` — bar icon (left = toggle sheet, right = settings)
- `Panel.qml` — settings (card placement, size, output path, motion)
- `logo.png` — Cyberpunk logo header
- `anchor-icon.png` — icon for the bar

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

## Uninstall
```bash
omarchy plugin remove local.cyberpunk-sheet
```
