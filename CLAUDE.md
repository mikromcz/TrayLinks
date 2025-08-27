# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

TrayLinks is a modern AutoHotkey v2.0 script that creates a sophisticated system tray utility with authentic Windows 11 styling. It provides quick access to folders and files through beautiful cascading menus featuring Fluent Design elements, dynamic theming, and contextual file type icons.

## Core Architecture

### Main Script Structure (TrayLinks.ahk)
The script follows a functional architecture with these key components:

1. **Configuration Management** (`TrayLinks.ahk:6-112`)
   - INI file handling with automatic creation of default config
   - Environment variable expansion (e.g., %OneDrive%, %USERPROFILE%)
   - Support for FolderPath, DarkMode, IconIndex, and MaxLevels settings

2. **Windows 11 GUI System** (`TrayLinks.ahk:430-600`)
   - Modern menu creation with Fluent Design styling
   - Two-column ListView workaround for precise left padding control
   - Contextual file type icons with smart recognition (`GetFileIcon()`)
   - Windows DWM API integration for rounded corners and drop shadows
   - Dynamic height calculation with consistent 8px bottom padding

3. **Event Handling** (`TrayLinks.ahk:469-506`, `TrayLinks.ahk:508-567`)
   - Single-click navigation for folders with consistent submenu closing
   - Double-click to open files/shortcuts
   - Right-click context menu with file operations (Open Location, Copy Path, Properties)
   - Global mouse hook for click-outside-to-close functionality
   - Tray icon click detection for menu toggle
   - Smart tooltip system for long filenames (>24 chars) with improved positioning
   - Fixed submenu closing behavior to ensure all child menus close properly

4. **Menu Management** (`TrayLinks.ahk:231-259`)
   - Multi-level menu state tracking using Maps
   - Hierarchical menu closing (close levels at/above specified level)
   - Maximum depth control (1-5 levels configurable)

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

1. **ShowFolderContents()** (`TrayLinks.ahk:430-600`) - Core menu creation with Windows 11 styling
2. **ApplyWindows11Styling()** (`TrayLinks.ahk:190-211`) - DWM API integration for modern appearance
3. **GetFileIcon()** (`TrayLinks.ahk:213-267`) - Contextual file type icon selection
4. **CalculateMenuHeight()** (`TrayLinks.ahk:296-309`) - Precise height calculation for consistent padding
5. **ReadConfig()** (`TrayLinks.ahk:61-109`) - INI parsing with DarkMode support
6. **ReloadScript()** (`TrayLinks.ahk:279-291`) - Clean resource management during reload

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

Configuration errors show user-friendly dialogs with options to edit the INI file.

## Windows 11 Implementation Details

### Fluent Design Integration
- **DWM APIs**: `DwmSetWindowAttribute` for rounded corners and drop shadows
- **Modern Colors**: Authentic Windows 11 color palette with proper contrast ratios
- **Typography**: Segoe UI Variable font with weight variations for hierarchy
- **Spacing**: Microsoft-standard 8px base unit for consistent padding

### ListView Optimization
- **Two-Column Workaround**: First column with 0 width for precise left padding control
- **Scrollbar Removal**: Multiple methods including `ShowScrollBar` API calls
- **Dynamic Sizing**: Actual ListView height measurement for perfect window sizing
- **Icon System**: 20+ contextual file type icons with smart extension mapping

### Resource Management
- **Clean Shutdown**: Proper mouse hook cleanup in `ExitScript()` and `ReloadScript()`
- **Memory Efficiency**: Automatic GUI resource cleanup when menus close
- **Performance**: Optimized Windows API calls and minimal resource usage

## Windows API Integration

Key Windows API usage:
- **DWM APIs**: Window styling, rounded corners, drop shadows
- **Low-level mouse hook**: Global click detection with proper cleanup
- **ShowScrollBar**: Comprehensive scrollbar removal
- **Shell32.dll**: Icon extraction for tray icon
- **WScript.Shell**: Environment variable expansion with error handling

## Testing Considerations

When modifying the script:
1. **Visual Testing**: Verify Windows 11 styling on both dark and light themes
2. **Layout Testing**: Test with various folder sizes (empty, single item, many items)
3. **Environment Testing**: Verify environment variable expansion across different Windows setups
4. **Screen Testing**: Test menu positioning on multi-monitor setups and different DPI settings
5. **Resource Testing**: Verify proper cleanup of GUI resources, mouse hooks, and DWM styling
6. **Theme Testing**: Test theme switching and reload functionality
7. **Icon Testing**: Verify contextual file type icons display correctly for various file types

## Code Style Guidelines

- **Windows 11 Colors**: Use the defined color constants in `darkColors` and `lightColors` objects
- **Spacing**: Maintain 8px base padding unit for consistency
- **Typography**: Use Segoe UI Variable with appropriate font weights
- **Error Handling**: Always wrap Windows API calls in try-catch blocks
- **Resource Cleanup**: Ensure proper cleanup in exit and reload functions
- **ListView Management**: Use two-column approach for padding control