# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrayLinks is a modern AutoHotkey v2.0 script that creates a sophisticated system tray utility with authentic Windows 11 styling. It provides quick access to folders and files through beautiful cascading menus featuring Fluent Design elements, dynamic theming, and contextual file type icons.

## Core Architecture

### Main Script Structure (TrayLinks.ahk)
The script follows a functional architecture with these key components:

1. **Configuration Management** (`TrayLinks.ahk:18-181`)
   - INI file handling with automatic creation of default config
   - Environment variable expansion via `ExpandPath()` using WScript.Shell COM
   - Custom INI parser (`ParseIniValue()`) for Unicode support
   - `DefaultConfig()` is the single source of fallbacks: `ReadConfig()` validates
     each value on its own and falls back per setting, so one typo cannot discard
     the rest of the file. MaxLevels is clamped to 1-5
   - Support for FolderPath, DarkMode, IconIndex, and MaxLevels settings

2. **Windows 11 GUI System** (`TrayLinks.ahk:220-333`)
   - `darkColors` / `lightColors` objects with authentic Windows 11 color schemes
   - `ApplyWindows11Styling()` for DWM API rounded corners and drop shadows
   - `fileIconMap` Map-based lookup for 30+ file extension-to-icon mappings
   - `GetColors()` theme selector based on config

3. **Helper Functions** (`TrayLinks.ahk:335-399`)
   - `IsTrayWindow()` - checks if a window belongs to the system tray area
   - `DefaultConfig()` - centralized fallback configuration
   - `CalculateMenuHeight()` - dynamic window height calculation
   - `ScanFolder()` - scans directory returning `{folders, files}` arrays
   - `CalculateMenuPosition()` - cascading position, clamped to `GetWorkAreaAt()`:
     the work area of the monitor under the mouse, so menus stay off the taskbar and
     on the right monitor. Converts the menu's logical size to screen pixels first,
     since `Gui.Show` DPI-scales w/h but not x/y

4. **Event Handling** (`TrayLinks.ahk:436-704`)
   - `ItemClick()` - single-click navigation for folders with consistent submenu closing
   - `ItemDoubleClick()` - opens files/shortcuts
   - `ItemContextMenu()` - right-click context menu with file operations
   - `ShowItemContextMenu()` - creates menu with Open Location, Copy Path, Properties
   - `SetMenuItemIcon()` - `Menu.SetIcon()` per item from `ICON_FILE`, so icons sit in the gutter
     Windows reserves rather than in the label text; numbers in the `MENU_ICON_*`
     constants, guarded individually so one bad number costs only its own icon.
     Used by both the item context menu and the tray menu
   - `EnableDarkMenus()` - opts the process into dark popup menus in dark mode
   - Tooltip monitoring (`CheckForTooltips()`) split into `HoveredItem()` hit-testing,
     `ShowItemTooltip()` and `ClearTooltip()`, for names longer than `TOOLTIP_MIN_LENGTH`.
     `MouseGetPos` flag 2 finds the ListView actually on top; `HoveredItem()` then asks
     it via `LVM_SUBITEMHITTEST`. Do not go back to dividing by a row height - that
     counts visible rows, not items, so it breaks on scrolled lists and at DPI scaling

5. **Menu Management** (`TrayLinks.ahk:402-434`)
   - `CloseAllMenus()` - destroys all GUIs and resets state
   - `CloseMenusAtLevel()` - hierarchical closing using while-loop from maxLevels down
   - `currentGuis` Map for multi-level GUI state tracking

6. **Menu Creation** (`TrayLinks.ahk:792-901`)
   - `ShowFolderContents()` - core function that creates GUI, populates ListView, positions window
   - Uses `ScanFolder()` for directory enumeration
   - Uses `CalculateMenuPosition()` for cascading placement
   - Hides horizontal scrollbar for large folders via DllCall

7. **Global Click Detection** (`TrayLinks.ahk:904-985`)
   - `LowLevelMouseProc()` - low-level mouse hook for reliable click-outside detection
   - `InstallMouseHook()` / `RemoveMouseHook()` - the hook exists only while a menu is
     open, so the script stays out of the global mouse path while idle
   - Uses `IsTrayWindow()` to avoid closing when clicking tray area
   - Race condition safe: GUI handle access wrapped in try-catch

8. **Entry Points** (`TrayLinks.ahk:991-1009`)
   - `ToggleMenu()` - shared show/hide logic
   - `TrayIconClick()` - left-click toggles menu, double-click opens root folder
   - `Win+F` hotkey - keyboard toggle for menu visibility

### Configuration System
- **Primary Config**: `TrayLinks.ini` (auto-generated if missing)
- **Settings Section**: FolderPath (supports env vars), DarkMode toggle
- **Advanced Section**: IconIndex (position within `ICON_FILE`), MaxLevels (1-5)

### Windows 11 Color Theming
The menu windows are painted from the colour objects below. The two *popup*
menus (tray and item context) are standard Win32 menus painted by Windows, so
they follow `EnableDarkMenus()` instead - see the dark mode note under Windows
API Integration.

Two authentic Windows 11 themes controlled by DarkMode setting:
- **Dark Mode**: `#2D2D2D` background, `#3C3C3C` elevated surfaces, `#005FB8` accent
- **Light Mode**: `#F9F9F9` background, white elevated surfaces, `#005FB8` accent
- **Typography**: Segoe UI Variable font with semi-bold titles and proper hierarchy

## Development Environment

### AutoHotkey Setup
- Uses AutoHotkey v2.0+ (required, not backward compatible)
- Local AutoHotkey64.exe included in project directory
- VS Code configuration in `.vscode/settings.json` with AHK++ extension settings

### File Structure
```
TrayLinks/
├── TrayLinks.ahk          # Main script file
├── TrayLinks.ini          # Configuration file (auto-generated)
├── AutoHotkey64.exe       # AutoHotkey v2 interpreter
├── README.md              # User documentation
├── CHANGELOG.md           # Release notes, newest first
├── LICENSE.txt            # MIT license
└── .vscode/settings.json  # VS Code AutoHotkey configuration
```

## Common Development Tasks

### Running/Testing the Script
```bash
# Run the script directly
.\AutoHotkey64.exe TrayLinks.ahk

# Or double-click TrayLinks.ahk if AutoHotkey is installed system-wide
```

### Configuration Testing
- Modify `TrayLinks.ini` to test different paths and settings
- Restart the script after config changes (there is no in-app reload)
- Test environment variable expansion with various Windows env vars

### Key Functions to Understand

1. **ShowFolderContents()** (`TrayLinks.ahk:792`) - Core menu creation with Windows 11 styling
2. **ApplyWindows11Styling()** (`TrayLinks.ahk:271`) - DWM API integration for modern appearance
3. **GetFileIcon()** (`TrayLinks.ahk:329`) - Map-based file type icon lookup
4. **ScanFolder()** (`TrayLinks.ahk:708`) - Single-pass directory scan returning folders and files arrays
5. **CalculateMenuPosition()** (`TrayLinks.ahk:737`) - Cascading menu positioning with screen bounds
6. **CalculateMenuHeight()** (`TrayLinks.ahk:383`) - Dynamic height calculation for consistent padding
7. **ReadConfig()** (`TrayLinks.ahk:113`) - INI parsing with DarkMode support
8. **InstallMouseHook()** / **RemoveMouseHook()** (`TrayLinks.ahk:954`) - Mouse hook lifecycle
9. **IsTrayWindow()** (`TrayLinks.ahk:335`) - Tray area window detection helper
10. **DefaultConfig()** (`TrayLinks.ahk:347`) - Centralized fallback configuration

## User Interface Guidelines

### Menu Behavior
- Menus appear left-to-right in cascading fashion
- Level 1 appears at mouse cursor position
- Subsequent levels position to the left of previous level
- Auto-positioning keeps menus inside the work area of the monitor under the mouse

### File Display Rules
- Folders show first with 🗂️ icon (modern file folder)
- Files show contextual icons: 📄 documents, 🎬 videos, 🖼️ images, etc.
- File extensions are hidden in display for cleaner appearance
- Hidden items, system files, desktop.ini and dot-files are filtered out. The system
  check is files-only: Windows can mark a folder system just to give it a custom icon
- Two-column ListView provides precise left padding control
- Tooltips display full filenames for items longer than 24 characters
- Right-click context menu provides file operations (Open Location, Copy Path, Properties),
  each with a real icon set via `Menu.SetIcon()`

## Error Handling Patterns

The script uses try-catch blocks around:
- File system operations (folder scanning, file access)
- Windows API calls (icon setting, window manipulation)
- INI file operations (reading/writing configuration)
- GUI handle access in mouse hooks (race condition protection)

Configuration errors show user-friendly dialogs with options to edit the INI file.

## Windows 11 Implementation Details

### Fluent Design Integration
- **DWM APIs**: `DwmSetWindowAttribute` for rounded corners and drop shadows
- **Modern Colors**: Authentic Windows 11 color palette with proper contrast ratios
- **Typography**: Segoe UI Variable font with weight variations for hierarchy
- **Spacing**: Microsoft-standard 8px base unit for consistent padding

### ListView Optimization
- **Two-Column Workaround**: First column with 0 width for precise left padding control
- **Borderless**: `-Border -E0x200` drops the client edge so the ListView blends into the window
- **Scrollbar Management**: Horizontal scrollbar hidden via `ShowScrollBar` API after render
- **Dynamic Sizing**: Row-count-based ListView with calculated window height
- **Icon System**: 30+ contextual file type icons via `fileIconMap` Map lookup

### Resource Management
- **Clean Shutdown**: Mouse hook removed in `CloseAllMenus()` and on `OnExit`
- **Memory Efficiency**: Automatic GUI resource cleanup when menus close
- **Performance**: Optimized Windows API calls and minimal resource usage

## Windows API Integration

Key Windows API usage:
- **DWM APIs**: Window styling, rounded corners, drop shadows
- **Low-level mouse hook**: Global click detection with proper cleanup
- **ShowScrollBar**: Horizontal scrollbar hiding for clean appearance
- **Icon extraction**: The tray icon and both menus' items all come from the single
  `ICON_FILE` DLL (`imageres.dll`), indexed by the `MENU_ICON_*` constants and the
  INI's IconIndex. Changing `ICON_FILE` moves every icon at once, so the INI
  default and the README's icon list have to move with it
- **uxtheme ordinals 135/136**: `SetPreferredAppMode` + `FlushMenuThemes` make the
  standard popup menus render dark. Undocumented and Windows 10 1809+ only, so the
  call is best-effort and silently leaves menus light when unavailable. Do not
  reach for `Menu.SetColor()` instead: it changes the background but not the text
  colour, giving black-on-dark
- **WScript.Shell**: Environment variable expansion with error handling
- **WindowFromPoint / IsChild**: Window identification in mouse hook
- **LVM_SUBITEMHITTEST / ScreenToClient**: Tooltip hit-testing, exact under scrolling and DPI scaling
- **MonitorGet / MonitorGetWorkArea**: Per-monitor, taskbar-aware menu placement
- **HRESULT, not exceptions**: `DllCall` only throws when a function cannot be called.
  Most Windows APIs report failure through their return value, so a `try` alone
  never sees it - check the result (see `ApplyWindows11Styling()`, `ShowItemProperties()`)

## Testing Considerations

When modifying the script:
1. **Visual Testing**: Verify Windows 11 styling on both dark and light themes
2. **Layout Testing**: Test with various folder sizes (empty, single item, many items)
3. **Environment Testing**: Verify environment variable expansion across different Windows setups
4. **Screen Testing**: Test menu positioning on multi-monitor setups and different DPI settings
5. **Resource Testing**: Verify proper cleanup of GUI resources, mouse hooks, and DWM styling
6. **Theme Testing**: Test theme switching by editing the INI and restarting
7. **Icon Testing**: Verify contextual file type icons display correctly for various file types
8. **Race Condition Testing**: Rapidly click to test GUI destruction timing safety

## Code Style Guidelines

- **Windows 11 Colors**: Use the defined color constants in `darkColors` and `lightColors` objects
- **Spacing**: Maintain 8px base padding unit for consistency
- **Typography**: Use Segoe UI Variable with appropriate font weights
- **Error Handling**: Always wrap Windows API calls and GUI handle access in try-catch blocks
- **Resource Cleanup**: Ensure proper cleanup on exit and whenever menus close
- **ListView Management**: Use two-column approach for padding control
- **Icon Mapping**: Add new file types to the `fileIconMap` Map, not as if-chains. ListView items use emoji in their text; menu items use `Menu.SetIcon()` instead, since emoji in a menu label fall back to a monochrome symbol font and leave the icon gutter empty
- **Helper Extraction**: Keep `ShowFolderContents()` lean by delegating to helpers like `ScanFolder()` and `CalculateMenuPosition()`
- **Magic Numbers**: Put layout values in the `MENU_*` constants near the top, not inline. `MENU_PADDING` drives left/right spacing and the ListView width; `MENU_LIST_TOP` and `MENU_BOTTOM_PADDING` drive the vertical gaps; `MENU_ROW_HEIGHT` sizes the window only - hit-testing asks the ListView instead
- **Version**: Update both the JSDoc `@version` header and the `SCRIPT_VERSION` constant, and add a `CHANGELOG.md` entry
