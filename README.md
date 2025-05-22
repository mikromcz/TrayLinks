# AutoHotkey Folder Toolbar

A customizable system tray utility that provides quick access to folders and files through cascading menus that appear on the left side of your cursor.

![AutoHotkey](https://img.shields.io/badge/AutoHotkey-v2.0+-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)

## ✨ Features

- **System Tray Integration**: Clean tray icon with folder access
- **Cascading Menus**: Navigate through subfolders with up to 5 levels deep
- **Dark Theme**: Modern dark UI that's easy on the eyes
- **Configurable Paths**: Support for both absolute paths and environment variables
- **Smart Positioning**: Menus appear to the left of each other, preventing screen overflow
- **File Type Recognition**: Folders show 📁 icon, files show ↗️ icon
- **Quick Actions**: Single-click to navigate, double-click to open files
- **Keyboard Shortcuts**: Win+F to toggle menu, Esc to close
- **Auto-Configuration**: Creates INI file automatically with sensible defaults

## 🚀 Quick Start

1. **Download and Install AutoHotkey v2.0+** from [autohotkey.com](https://www.autohotkey.com/)
2. **Save the script** as `FolderToolbar.ahk` (or any name you prefer)
3. **Run the script** - it will automatically create a configuration file
4. **Look for the folder icon** in your system tray
5. **Click the tray icon** to open your folder menu!

## ⚙️ Configuration

The script automatically creates an INI file (same name as the script) with these settings:

### `FolderToolbar.ini` Example:
```ini
[Settings]
; Folder path to display in the toolbar
; Can use environment variables like %USERPROFILE%, %OneDrive%, etc.
; Examples:
;   FolderPath=C:\MyLinks
;   FolderPath=%OneDrive%\Links
;   FolderPath=%USERPROFILE%\Desktop\Shortcuts
FolderPath=%OneDrive%\Links

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
- **Click outside menus**: Close all menus

### Keyboard Shortcuts:
- **Win + F**: Toggle folder menu
- **Esc**: Close all open menus

### Context Menu Options:
- **Open Links Folder**: Opens root folder in Windows Explorer
- **Edit Configuration**: Opens INI file for editing
- **Reload Script**: Reloads the script after configuration changes
- **Exit**: Closes the application

## 🛠️ Customization

### Changing the Folder Path:
1. Right-click the tray icon → "Edit Configuration"
2. Modify the `FolderPath` setting
3. Right-click the tray icon → "Reload Script"

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

## 📄 License

This project is open source and available under the MIT License.

## 🐛 Known Issues

- Very long file names might be truncated in the display
- Network paths may have slower response times
- Some special characters in folder names might not display correctly

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