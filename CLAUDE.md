# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrayLinks is an AutoHotkey v2.0 script that creates a customizable system tray utility providing quick access to folders and files through cascading menus. The application displays a folder icon in the system tray and shows hierarchical folder menus when clicked.

## Core Architecture

### Main Script Structure (TrayLinks.ahk)
The script follows a functional architecture with these key components:

1. **Configuration Management** (`TrayLinks.ahk:6-112`)
   - INI file handling with automatic creation of default config
   - Environment variable expansion (e.g., %OneDrive%, %USERPROFILE%)
   - Support for FolderPath, DarkMode, IconIndex, and MaxLevels settings

2. **GUI System** (`TrayLinks.ahk:319-474`)
   - Dynamic menu creation using AutoHotkey GUI controls
   - ListView-based folder/file display with icons (📁 for folders, ↗️ for files)
   - Cascading menus that position left-to-right based on level
   - Dynamic height calculation based on item count

3. **Event Handling** (`TrayLinks.ahk:261-317`, `TrayLinks.ahk:476-581`)
   - Single-click navigation for folders
   - Double-click to open files/shortcuts
   - Global mouse hook for click-outside-to-close functionality
   - Tray icon click detection for menu toggle

4. **Menu Management** (`TrayLinks.ahk:231-259`)
   - Multi-level menu state tracking using Maps
   - Hierarchical menu closing (close levels at/above specified level)
   - Maximum depth control (1-5 levels configurable)

### Configuration System
- **Primary Config**: `TrayLinks.ini` (auto-generated if missing)
- **Settings Section**: FolderPath (supports env vars), DarkMode toggle
- **Advanced Section**: IconIndex (Shell32.dll), MaxLevels (1-5)

### Color Theming
Two built-in themes controlled by DarkMode setting:
- Dark: #202020 background, white text, blue selection
- Light: White background, black text, blue selection

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

1. **ShowFolderContents()** (`TrayLinks.ahk:320-474`) - Core menu creation logic
2. **ReadConfig()** (`TrayLinks.ahk:61-109`) - INI parsing and env var expansion  
3. **ItemClick/ItemDoubleClick()** (`TrayLinks.ahk:262-317`) - User interaction handlers
4. **CloseMenusAtLevel()** (`TrayLinks.ahk:247-259`) - Menu hierarchy management

## User Interface Guidelines

### Menu Behavior
- Menus appear left-to-right in cascading fashion
- Level 1 appears at mouse cursor position
- Subsequent levels position to the left of previous level
- Auto-positioning prevents off-screen menus

### File Display Rules
- Folders show first with 📁 prefix
- Files show after folders with ↗️ prefix  
- File extensions are hidden in display
- Hidden files and desktop.ini are filtered out

## Error Handling Patterns

The script uses try-catch blocks around:
- File system operations (folder scanning, file access)
- Windows API calls (icon setting, window manipulation)
- INI file operations (reading/writing configuration)

Configuration errors show user-friendly dialogs with options to edit the INI file.

## Windows API Integration

Key Windows API usage:
- Low-level mouse hook for global click detection
- Shell32.dll icon extraction for tray icon
- Window positioning and styling APIs
- Environment variable expansion via WScript.Shell

## Testing Considerations

When modifying the script:
1. Test with empty folders, folders with many items, and nested structures
2. Verify environment variable expansion with different Windows setups  
3. Test menu positioning on different screen configurations
4. Verify proper cleanup of GUI resources and hooks on script exit