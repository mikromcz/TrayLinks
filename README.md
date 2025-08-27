# TrayLinks - Windows 11 Style Folder Toolbar

A modern system tray utility that provides quick access to folders and files through beautiful cascading menus with authentic Windows 11 styling.

![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Windows](https://img.shields.io/badge/Windows-10%2F11-blue.svg)

## ✨ Features

### 🎨 Modern Windows 11 Design
- **Fluent Design System**: Authentic Windows 11 appearance with rounded corners and drop shadows
- **Dynamic Theming**: Beautiful dark and light modes that adapt to your preferences
- **Modern Typography**: Segoe UI Variable font with proper visual hierarchy
- **Smart File Icons**: Contextual icons for different file types (📄 documents, 🎬 videos, 🖼️ images, etc.)
- **Perfect Spacing**: Consistent padding and margins following Microsoft's design guidelines

### 🚀 Core Functionality
- **System Tray Integration**: Clean tray icon with intuitive folder access
- **Cascading Menus**: Navigate through subfolders with up to 5 levels deep
- **Smart Positioning**: Menus appear to the left of each other, preventing screen overflow
- **Quick Actions**: Single-click to navigate, double-click to open files
- **Right-Click Context Menu**: Open location, copy path, and properties for any file or folder
- **Smart Tooltips**: Hover tooltips for long filenames (>24 characters) with proper positioning
- **Configurable Paths**: Full support for environment variables, network paths, and Unicode characters
- **Auto-Configuration**: Creates INI file automatically with sensible defaults
- **Large Folder Support**: Handles folders with hundreds of items with automatic scrolling
- **Dynamic Versioning**: Version information automatically extracted from script header

### ⌨️ User Experience
- **Keyboard Shortcuts**: Win+F to toggle menu
- **Click Outside to Close**: Intuitive menu dismissal
- **Smooth Interactions**: Responsive design with proper hover states
- **Clean Exit**: Reliable script reloading and exit functionality

## 🚀 Quick Start

1. **Download and Install AutoHotkey v2.0+** from [autohotkey.com](https://www.autohotkey.com/)
2. **Save the script** as `FolderToolbar.ahk` (or any name you prefer)
3. **Run the script** - it will automatically create a configuration file
4. **Look for the folder icon** in your system tray
5. **Click the tray icon** to open your folder menu!

## ⚙️ Configuration

The script automatically creates an INI file (same name as the script) with these settings:

### `TrayLinks.ini` Example:
```ini
[Settings]
; Folder path to display in the toolbar
; Can use environment variables like %USERPROFILE%, %OneDrive%, etc.
; Examples:
;   FolderPath=C:\MyLinks
;   FolderPath=%OneDrive%\Links
;   FolderPath=%USERPROFILE%\Desktop\Shortcuts
FolderPath=%OneDrive%\Links

; Dark mode setting (true/false or 1/0)
; true = Dark mode with Windows 11 dark theme
; false = Light mode with Windows 11 light theme
DarkMode=true

[Advanced]
; Icon index from Shell32.dll (optional)
IconIndex=4

; Maximum menu levels (1-5)
MaxLevels=3
```

### Supported Environment Variables:
- `%OneDrive%` - Your OneDrive folder
- `%USERPROFILE%` - Your user profile folder (C:\Users\YourName)
- `%APPDATA%` - Application data folder
- `%DESKTOP%` - Desktop folder
- `%DOCUMENTS%` - Documents folder
- `%DOWNLOADS%` - Downloads folder
- Any Windows environment variable

### Unicode Support:
Full support for international characters in folder and file names, including:
- European characters (ěščř, áéíóú, ñç, etc.)
- Cyrillic, Asian, and other character sets
- Network paths with Unicode characters

### Configuration Examples:
```ini
# OneDrive Links folder
FolderPath=%OneDrive%\Links

# Desktop shortcuts
FolderPath=%USERPROFILE%\Desktop\Shortcuts

# Custom folder
FolderPath=C:\MyTools

# Network path
FolderPath=\\server\shared\tools
```

## 🎮 Usage

### Mouse Controls:
- **Left-click tray icon**: Toggle folder menu
- **Double-click tray icon**: Open root folder in Explorer
- **Right-click tray icon**: Show context menu with options
- **Single-click item**: Navigate into folders
- **Double-click item**: Open files/shortcuts
- **Right-click item**: Show context menu (Open Location, Copy Path, Properties)
- **Hover over long names**: Display tooltip with full filename
- **Click outside menus**: Close all menus

### Keyboard Shortcuts:
- **Win + F**: Toggle folder menu
- **Esc**: Close all open menus

### Context Menu Options:
- **TrayLinks**: Click to open GitHub repository
- **Version (e.g., v3.1.0)**: Click to open GitHub repository  
- **Open Links Folder**: Opens root folder in Windows Explorer
- **Edit Configuration**: Opens INI file for editing
- **Exit**: Closes the application

## 🛠️ Customization

### Changing the Folder Path:
1. Right-click the tray icon → "Edit Configuration"
2. Modify the `FolderPath` setting (supports Unicode characters like ěščř)
3. Save the file - the script will automatically detect changes

### Switching Themes:
Toggle between Windows 11 dark and light themes:
1. Right-click the tray icon → "Edit Configuration"
2. Set `DarkMode=true` for dark theme or `DarkMode=false` for light theme
3. Save the file - the script will automatically detect changes

### Changing the Icon:
Modify `IconIndex` in the INI file. Common Shell32.dll icons:
- `3` - Computer/PC icon
- `4` - Folder icon (default)
- `5` - Floppy disk icon
- `22` - Gear/settings icon
- `42` - Folder with arrow icon

### Adjusting Menu Levels:
Set `MaxLevels` to control how deep the menus can go (1-5 levels supported).

## 🔧 Troubleshooting

### "Folder does not exist" Error:
1. Check that the path in your INI file is correct
2. Ensure environment variables are valid (e.g., %OneDrive% exists)
3. Try using an absolute path like `C:\YourFolder`
4. The script will offer to open the configuration file for editing

### Script Won't Start:
- Ensure AutoHotkey v2.0+ is installed
- Check that the `.ahk` file isn't corrupted
- Try running AutoHotkey as administrator

### Menus Don't Appear:
- Check that the folder path contains files or subfolders
- Verify the folder isn't empty or all files are hidden
- Try the Win+F hotkey as an alternative

### Environment Variables Not Working:
- Test the variable in Command Prompt: `echo %OneDrive%`
- Some variables might not exist on all systems
- Use absolute paths as a fallback

## 📋 Requirements

- **Windows 10/11** (or Windows 7+ with AutoHotkey v2.0 support)
- **AutoHotkey v2.0 or later**
- **Read access** to the target folder

## 🎯 Best Practices

1. **Organize Your Links**: Create a dedicated folder structure for easy navigation
2. **Use Shortcuts**: Create .lnk files for frequently accessed programs and documents
3. **Limit Depth**: Keep folder structures shallow (2-3 levels) for best usability
4. **Descriptive Names**: Use clear, descriptive folder and file names
5. **Regular Cleanup**: Remove unused shortcuts and organize periodically

## 🤝 Tips & Tricks

- **Pin to Startup**: Add the script to your Windows startup folder for automatic loading
- **Multiple Configurations**: Create different scripts with different INI files for various folder sets
- **Backup Settings**: Keep a backup of your INI file when you have it configured perfectly
- **Network Paths**: Works with network drives and UNC paths
- **Hidden Files**: Hidden and system files are automatically filtered out

## 🎨 Windows 11 Design Details

### Visual Features
- **Fluent Design**: Authentic Windows 11 appearance with proper rounded corners
- **Drop Shadows**: Modern elevation effects using Windows DWM APIs
- **Color Schemes**: 
  - **Dark Mode**: `#2D2D2D` backgrounds with `#3C3C3C` elevated surfaces
  - **Light Mode**: `#F9F9F9` backgrounds with pure white cards
- **Typography**: Segoe UI Variable font with semi-bold titles
- **File Type Icons**: Smart contextual icons:
  - 🗂️ Folders
  - 📄 Documents (TXT, DOC, etc.)
  - 📕 PDF files
  - 📊 Spreadsheets (XLS, CSV)
  - 🖼️ Images (JPG, PNG, etc.)
  - 🎬 Videos (MP4, AVI, etc.)
  - 🎵 Audio files (MP3, WAV, etc.)
  - 🗜️ Archives (ZIP, RAR, etc.)
  - ⚙️ Executables (EXE, MSI, etc.)
  - 🌐 Web files (HTML, CSS, JS)
  - 🔗 Shortcuts and links

### Technical Implementation
- **DWM Integration**: Uses Windows Desktop Window Manager for native styling
- **Precise Spacing**: Consistent 8px padding with perfect alignment
- **No Scrollbars**: Clean ListView implementation without scroll indicators
- **Optimized Layout**: Dynamic height calculation for perfect fit
- **Resource Management**: Proper cleanup for smooth reloading

## 📄 License

This project is open source and available under the MIT License.

## 🐛 Known Issues

- Network paths may have slower response times
- Horizontal scrollbar may briefly flash when opening large folders (automatically hidden)

## ✅ Recent Fixes

- **Fixed submenu closing**: Resolved issue where child menus wouldn't close properly in some cases
- **Long filename handling**: Added tooltips for filenames longer than 24 characters
- **Enhanced context menu**: Added right-click functionality with Open Location, Copy Path, and Properties options

## 💡 Feature Ideas

Feel free to extend the script with:
- Custom icons for different file types
- Favorite folders pinning
- Search functionality
- Multiple root folders
- Custom themes and colors

---

**Enjoy your new folder toolbar! 🎉**

*For questions, issues, or suggestions, feel free to modify the script to suit your needs.*