# Changelog

All notable changes to TrayLinks are documented in this file.

This file starts at 3.5.0. Earlier releases carried no release notes beyond their
version number, so see the git history for those.

## [Unreleased]

### Fixed

- Tooltips showed the wrong filename once a long list was scrolled — they counted
  visible rows rather than items. The same arithmetic also drifted at any display
  scaling other than 100%, and where menus overlapped, the one underneath could
  claim the hover
- Hidden and system files appeared in menus, despite the README saying they are
  filtered — most visibly Office's `~$` lock files while a document is open
- A single invalid INI value (say `MaxLevels=abc`) threw away the whole file,
  including a valid `FolderPath`, which usually ended in a "folder does not exist"
  error. Each setting now falls back on its own
- `MaxLevels` outside 1–5 is clamped as documented; `0` stopped menus from closing
- A missing `IconIndex` fell back to `4` rather than the documented `205`
- Menus were clamped to the primary screen and could sit over the taskbar; they now
  stay inside the work area of the monitor under the mouse. Win+F on a second
  monitor no longer throws the menu onto the primary one
- Submenu placement mixed scaled and unscaled pixels, so on a scaled display
  submenus overlapped their parent (no change at 100% scaling)
- "Properties" failures went unreported: the error check never fired, and its
  fallback opened the "Open with" dialog rather than Properties
- The border fallback for Windows 10 never applied, leaving menus unoutlined
- The DWM border colour was passed as RGB where Windows expects BGR. Invisible with
  the current greys, but any non-grey `borderAccent` would have had red and blue swapped

### Changed

- The DarkMode fallback now matches the INI that new installs get (dark), instead
  of three different places disagreeing about the default

## [3.5.0] - 2026-09-28

The same changes shipped as 3.4.0 on 2026-09-22; the two were reconciled into
3.5.0, so there is no separate 3.4.0 entry.

### ⚠️ Upgrade note

`IconIndex` now indexes `imageres.dll` instead of `Shell32.dll`. An existing
`TrayLinks.ini` keeps its number but will show a **different icon** — a stock
`IconIndex=4` especially. New installs default to `205`, a folder. Pick a new
number from `imageres.dll` if your tray icon looks wrong after upgrading.

### Added

- Icons on both menus — the item context menu and the tray menu — via `Menu.SetIcon()`
- Dark popup menus when `DarkMode=true`. Windows paints them, so text and hover
  states follow too. Needs Windows 10 1809 or newer; on older builds the menus
  stay light
- `#SingleInstance Force`, so restarting no longer leaves two tray icons behind
- Named layout and icon constants (`MENU_PADDING`, `MENU_LIST_TOP`, `ICON_FILE`,
  `MENU_ICON_*`, …) collecting values that were previously scattered inline

### Changed

- The ListView is borderless and blends into the menu window
- Tighter menu spacing: 5px sides, 10px below the list, name column at full width
- All icons now come from one place, `ICON_FILE` (`imageres.dll`) — the tray icon
  included. Changing that one constant moves every icon in the app
- The low-level mouse hook is installed only while a menu is open. It previously
  sat in the path of every system-wide mouse message for the whole session
- Folder scanning enumerates each directory once instead of twice
- Tooltip hit-testing reuses the ListView cached on its menu instead of walking
  the window's controls ten times a second
- The version shown in the tray menu comes from a constant rather than the script
  re-reading and regex-scanning its own source file at startup
- The tray tooltip says "TrayLinks" instead of "Folder Links"

### Fixed

- Clicking outside a menu did not close it on monitors positioned to the left of
  the primary one: a negative X coordinate corrupted the packed point passed to
  `WindowFromPoint`
- A tooltip did not reappear for the same long filename after its menu had been
  closed and reopened, because the last-shown name was never cleared
- The gap below the list was 16px while the constant governing it claimed 12, so
  adjusting that value never produced the spacing it advertised

### Removed

- `ReloadScript()`, orphaned since its tray menu entry was dropped in 3.1.0
- A backup click-outside handler that could never fire, since it only received
  messages sent to the script's own windows
- Startup version detection that read and regex-scanned the whole script file
- A no-op `DllCall` that used the wrong ListView message constant; the adjacent
  `ShowScrollBar` call was doing the work
- Unused parameters, a redundant wrapper object allocated per menu item, and a
  height clamp that could never trigger
