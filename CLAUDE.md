# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrayLinks is a modern AutoHotkey v2.0 script that creates a sophisticated system tray utility with authentic Windows 11 styling. It provides quick access to folders and files through beautiful cascading menus featuring Fluent Design elements, dynamic theming, and contextual file type icons.

## Core Architecture

### Main Script Structure (TrayLinks.ahk)
The script follows a functional architecture with these key components:

1. **Configuration Management** (`TrayLinks.ahk:10-160`)
   - INI file handling with automatic creation of default config
   - Environment variable expansion via `ExpandPath()` using WScript.Shell COM
   - Custom INI parser (`ParseIniValue()`) for Unicode support
   - `DefaultConfig()` fallback for error cases
   - Support for FolderPath, DarkMode, IconIndex, and MaxLevels settings

2. **Windows 11 GUI System** (`TrayLinks.ahk:200-290`)
   - `darkColors` / `lightColors` objects with authentic Windows 11 color schemes
   - `ApplyWindows11Styling()` for DWM API rounded corners and drop shadows
   - `fileIconMap` Map-based lookup for 30+ file extension-to-icon mappings
   - `GetColors()` theme selector based on config

3. **Helper Functions** (`TrayLinks.ahk:292-400`)
   - `IsTrayWindow()` - checks if a window belongs to the system tray area
   - `DefaultConfig()` - centralized fallback configuration
   - `CalculateMenuHeight()` - dynamic window height calculation
   - `ScanFolder()` - scans directory returning `{folders, files}` arrays
   - `CalculateMenuPosition()` - calculates cascading menu position with screen bounds clamping

4. **Event Handling** (`TrayLinks.ahk:434-575`)
   - `ItemClick()` - single-click navigation for folders with consistent submenu closing
   - `ItemDoubleClick()` - opens files/shortcuts
   - `ItemContextMenu()` - right-click context menu with file operations
   - `ShowItemContextMenu()` - creates menu with Open Location, Copy Path, Properties
   - Tooltip monitoring system (`CheckForTooltips()`) for long filenames (>24 chars)

5. **Menu Management** (`TrayLinks.ahk:403-435`)
   - `CloseAllMenus()` - destroys all GUIs and resets state
   - `CloseMenusAtLevel()` - hierarchical closing using while-loop from maxLevels down
   - `currentGuis` Map for multi-level GUI state tracking

6. **Menu Creation** (`TrayLinks.ahk:725-910`)
   - `ShowFolderContents()` - core function that creates GUI, populates ListView, positions window
   - Uses `ScanFolder()` for directory enumeration
   - Uses `CalculateMenuPosition()` for cascading placement
   - Hides horizontal scrollbar for large folders via DllCall

7. **Global Click Detection** (`TrayLinks.ahk:832-920`)
   - `LowLevelMouseProc()` - low-level mouse hook for reliable click-outside detection
   - `OnGlobalMouseClick()` - backup WM_LBUTTONUP handler
   - Both use `IsTrayWindow()` to avoid closing when clicking tray area
   - Race condition safe: GUI handle access wrapped in try-catch

8. **Entry Points** (`TrayLinks.ahk:927-955`)
   - `TrayIconClick()` - left-click toggles menu, double-click opens root folder
   - `Win+F` hotkey - keyboard toggle for menu visibility

### Configuration System
- **Primary Config**: `TrayLinks.ini` (auto-generated if missing)
- **Settings Section**: FolderPath (supports env vars), DarkMode toggle
- **Advanced Section**: IconIndex (Shell32.dll), MaxLevels (1-5)

### Windows 11 Color Theming
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
- Use the "Reload Script" option from tray menu after config changes
- Test environment variable expansion with various Windows env vars

### Key Functions to Understand

1. **ShowFolderContents()** (`TrayLinks.ahk:725`) - Core menu creation with Windows 11 styling
2. **ApplyWindows11Styling()** (`TrayLinks.ahk:235`) - DWM API integration for modern appearance
3. **GetFileIcon()** (`TrayLinks.ahk:286`) - Map-based file type icon lookup
4. **ScanFolder()** (`TrayLinks.ahk:668`) - Directory scanning returning folders and files arrays
5. **CalculateMenuPosition()** (`TrayLinks.ahk:694`) - Cascading menu positioning with screen bounds
6. **CalculateMenuHeight()** (`TrayLinks.ahk:379`) - Dynamic height calculation for consistent padding
7. **ReadConfig()** (`TrayLinks.ahk:105`) - INI parsing with DarkMode support
8. **ReloadScript()** (`TrayLinks.ahk:353`) - Clean resource management during reload
9. **IsTrayWindow()** (`TrayLinks.ahk:293`) - Tray area window detection helper
10. **DefaultConfig()** (`TrayLinks.ahk:305`) - Centralized fallback configuration

## User Interface Guidelines

### Menu Behavior
- Menus appear left-to-right in cascading fashion
- Level 1 appears at mouse cursor position
- Subsequent levels position to the left of previous level
- Auto-positioning prevents off-screen menus

### File Display Rules
- Folders show first with 🗂️ icon (modern file folder)
- Files show contextual icons: 📄 documents, 🎬 videos, 🖼️ images, etc.
- File extensions are hidden in display for cleaner appearance
- Hidden files and desktop.ini are automatically filtered out
- Two-column ListView provides precise left padding control
- Tooltips display full filenames for items longer than 24 characters
- Right-click context menu provides file operations (Open Location, Copy Path, Properties)

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
- **Scrollbar Management**: Horizontal scrollbar hidden via `ShowScrollBar` API after render
- **Dynamic Sizing**: Row-count-based ListView with calculated window height
- **Icon System**: 30+ contextual file type icons via `fileIconMap` Map lookup

### Resource Management
- **Clean Shutdown**: Proper mouse hook cleanup in `ExitScript()` and `ReloadScript()`
- **Memory Efficiency**: Automatic GUI resource cleanup when menus close
- **Performance**: Optimized Windows API calls and minimal resource usage

## Windows API Integration

Key Windows API usage:
- **DWM APIs**: Window styling, rounded corners, drop shadows
- **Low-level mouse hook**: Global click detection with proper cleanup
- **ShowScrollBar**: Horizontal scrollbar hiding for clean appearance
- **Shell32.dll**: Icon extraction for tray icon
- **WScript.Shell**: Environment variable expansion with error handling
- **WindowFromPoint / IsChild**: Window identification in mouse hook

## Testing Considerations

When modifying the script:
1. **Visual Testing**: Verify Windows 11 styling on both dark and light themes
2. **Layout Testing**: Test with various folder sizes (empty, single item, many items)
3. **Environment Testing**: Verify environment variable expansion across different Windows setups
4. **Screen Testing**: Test menu positioning on multi-monitor setups and different DPI settings
5. **Resource Testing**: Verify proper cleanup of GUI resources, mouse hooks, and DWM styling
6. **Theme Testing**: Test theme switching and reload functionality
7. **Icon Testing**: Verify contextual file type icons display correctly for various file types
8. **Race Condition Testing**: Rapidly click to test GUI destruction timing safety

## Code Style Guidelines

- **Windows 11 Colors**: Use the defined color constants in `darkColors` and `lightColors` objects
- **Spacing**: Maintain 8px base padding unit for consistency
- **Typography**: Use Segoe UI Variable with appropriate font weights
- **Error Handling**: Always wrap Windows API calls and GUI handle access in try-catch blocks
- **Resource Cleanup**: Ensure proper cleanup in exit and reload functions
- **ListView Management**: Use two-column approach for padding control
- **Icon Mapping**: Add new file types to the `fileIconMap` Map, not as if-chains
- **Helper Extraction**: Keep `ShowFolderContents()` lean by delegating to helpers like `ScanFolder()` and `CalculateMenuPosition()`
