/**
 * @description AutoHotkey2 Folder Toolbar Script
 * Creates a system tray icon with folder menus similar to Windows "pin folder to taskbar" feature removed in Windows 11.
 * @author mikrom, ClaudeAI
 * @version 3.3.0
 */

#Requires AutoHotkey v2.0

; Configuration - INI file handling
SplitPath(A_ScriptName, , , , &nameNoExt)
iniFile := A_ScriptDir . "\" . nameNoExt . ".ini"

; Function to expand environment variables in a path
ExpandPath(path) {
    ; Use ComObject to expand environment variables
    try {
        shell := ComObject("WScript.Shell")
        return shell.ExpandEnvironmentStrings(path)
    } catch {
        ; If ComObject creation or expansion fails, return original path
        return path
    }
}

; Function to create default INI file
CreateDefaultIni() {
    global iniFile

    defaultContent := "
(
[Settings]
; Folder path to display in the toolbar
; Can use environment variables like %USERPROFILE%, %OneDrive%, etc.
; Examples:
;   FolderPath=C:\MyLinks
;   FolderPath=%OneDrive%\Links
;   FolderPath=%USERPROFILE%\Desktop\Shortcuts
FolderPath=%OneDrive%\Links

; Dark mode setting (true/false or 1/0)
; true = Dark mode, false = Light mode
DarkMode=true

[Advanced]
; Icon index from Shell32.dll (optional)
IconIndex=4

; Maximum menu levels (1-5)
MaxLevels=3
)"

    try {
        FileAppend(defaultContent, iniFile, "UTF-8")
        return true
    } catch as e {
        MsgBox("Error creating INI file: " . e.Message, "Error", "Icon!")
        return false
    }
}

; Function to parse INI value from content with Unicode support
ParseIniValue(iniContent, section, key, defaultValue) {
    ; Create regex patterns for section and key
    sectionPattern := "i)^\s*\[\s*" . RegExReplace(section, "[\[\]\\^$.*+?{}()|]", "\$0") . "\s*\]\s*$"
    keyPattern := "i)^\s*" . RegExReplace(key, "[\[\]\\^$.*+?{}()|]", "\$0") . "\s*=\s*(.*?)\s*$"

    ; Split content into lines
    lines := StrSplit(iniContent, "`n", "`r")

    ; Find the section
    inSection := false
    for lineNum, line in lines {
        line := Trim(line)

        ; Skip empty lines and comments
        if (line = "" || SubStr(line, 1, 1) = ";" || SubStr(line, 1, 1) = "#")
            continue

        ; Check if this is the start of our section
        if (RegExMatch(line, sectionPattern)) {
            inSection := true
            continue
        }

        ; Check if this is the start of a different section
        if (RegExMatch(line, "^\s*\[.*\]\s*$")) {
            if (inSection)
                break
            continue
        }

        ; If we're in the right section, look for our key
        if (inSection) {
            if (RegExMatch(line, keyPattern, &match)) {
                return match[1]
            }
        }
    }

    return defaultValue
}

; Function to read configuration from INI
ReadConfig() {
    global iniFile

    ; Check if INI file exists, create if not
    if (!FileExist(iniFile)) {
        if (!CreateDefaultIni()) {
            ; If we can't create INI, use fallback
            return DefaultConfig()
        }
    }

    ; Read settings from INI with UTF-8 encoding support
    try {
        ; Use FileRead with UTF-8 encoding to handle Unicode characters
        iniContent := ""
        try {
            iniContent := FileRead(iniFile, "UTF-8")
        } catch {
            ; Fallback to default encoding
            iniContent := FileRead(iniFile)
        }

        ; Parse INI content manually to handle Unicode properly
        rawPath := ParseIniValue(iniContent, "Settings", "FolderPath", "%OneDrive%\Links")
        darkModeRaw := ParseIniValue(iniContent, "Settings", "DarkMode", "false")
        iconIndex := ParseIniValue(iniContent, "Advanced", "IconIndex", "4")
        maxLevels := ParseIniValue(iniContent, "Advanced", "MaxLevels", "3")

        ; Expand environment variables in the path
        expandedPath := ExpandPath(rawPath)

        ; Parse dark mode setting (handle true/false, 1/0, yes/no)
        darkMode := true
        darkModeRaw := Trim(StrLower(darkModeRaw))
        if (darkModeRaw = "false" || darkModeRaw = "0" || darkModeRaw = "no") {
            darkMode := false
        }

        return {
            folderPath: expandedPath,
            iconIndex: Integer(iconIndex),
            maxLevels: Integer(maxLevels),
            darkMode: darkMode
        }
    } catch as e {
        MsgBox("Error reading INI file: " . e.Message . "`nUsing default settings.", "Warning", "Icon!")
        return DefaultConfig()
    }
}

; Load configuration
config := ReadConfig()
folderPath := config.folderPath

; Validate folder path
if (!DirExist(folderPath)) {
    errorMsg := "Folder does not exist: " . folderPath . "`n`n"
    errorMsg .= "Please check the FolderPath setting in: " . iniFile . "`n`n"
    errorMsg .= "Current setting expands to: " . folderPath
    MsgBox(errorMsg, "Configuration Error", "Icon!")

    ; Offer to open INI file for editing
    result := MsgBox("Would you like to open the configuration file for editing?", "Edit Configuration", "YesNo Icon?")
    if (result = "Yes") {
        try {
            Run("notepad.exe `"" . iniFile . "`"")
        } catch {
            Run(iniFile)  ; Fallback to default associated program
        }
    }
    ExitApp
}

; Set up the tray icon
try {
    TraySetIcon("Shell32.dll", config.iconIndex)
} catch {
    ; Fallback if that specific icon fails
}

; Set tooltip for the tray icon
A_IconTip := "Folder Links - Click for menu`nPath: " . folderPath . "`nMode: " . (config.darkMode ? "Dark" : "Light")

; Customize the tray menu (will show on right-click)
A_TrayMenu.Delete() ; Clear default menu
A_TrayMenu.Add("TrayLinks", OpenGitHub)  ; Script name - opens GitHub
A_TrayMenu.Add("v" . getVersionFromScript(), OpenGitHub)     ; Version - opens GitHub
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Open Links Folder", OpenRootFolder)
A_TrayMenu.Add("Edit Configuration", EditConfig)
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Exit", ExitScript)
A_TrayMenu.Default := "TrayLinks"

; Global variables
global currentGuis := Map()      ; Store GUIs by level (1, 2, 3)
global isMenuVisible := false

; Windows 11 Fluent Design color schemes
global darkColors := {
    background: "2D2D2D",      ; Windows 11 dark background
    backgroundCard: "3C3C3C",  ; Card/elevated surface
    text: "FFFFFF",
    textSecondary: "C5C5C5",   ; Secondary text
    border: "484848",          ; Subtle border
    borderAccent: "5A5A5A",    ; Accent border
    selected: "005FB8",        ; Windows 11 accent blue
    selectedHover: "0078D4",   ; Hover state
    shadow: "000000"
}

global lightColors := {
    background: "F9F9F9",      ; Windows 11 light background (slightly off-white)
    backgroundCard: "FFFFFF",  ; Card/elevated surface
    text: "000000",
    textSecondary: "605E5C",   ; Secondary text
    border: "E1DFDD",          ; Subtle border
    borderAccent: "D1D1D1",    ; Accent border
    selected: "005FB8",        ; Windows 11 accent blue
    selectedHover: "0078D4",   ; Hover state
    shadow: "00000020"         ; Light shadow with transparency
}

; Function to get current color scheme based on config
GetColors() {
    global config, darkColors, lightColors
    return config.darkMode ? darkColors : lightColors
}

; Apply Windows 11 modern styling to GUI windows
ApplyWindows11Styling(hwnd) {
    ; Apply drop shadow and rounded corners using DWM API
    try {
        ; Enable drop shadow
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 2, "Int*", 2, "UInt", 4)

        ; Set rounded corners (Windows 11 style)
        ; DWMWCP_ROUND = 2 for rounded corners
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 33, "UInt*", 2, "UInt", 4)

        ; Set border color to match theme
        colors := GetColors()
        borderColor := "0x" colors.borderAccent
        DllCall("dwmapi\DwmSetWindowAttribute", "Ptr", hwnd, "UInt", 34, "UInt*", borderColor, "UInt", 4)
    } catch {
        ; Fallback for older Windows versions - just apply a subtle border
        try {
            WinSetStyle("+0x800000", hwnd)  ; WS_BORDER
        }
    }
}

; File extension to icon mapping (Windows 11 style)
global fileIconMap := Map(
    ; Document files
    "txt", "📄", "rtf", "📄", "doc", "📄", "docx", "📄",
    ; PDF
    "pdf", "📕",
    ; Spreadsheets
    "xls", "📊", "xlsx", "📊", "csv", "📊",
    ; Presentations
    "ppt", "📋", "pptx", "📋",
    ; Images
    "jpg", "🖼️", "jpeg", "🖼️", "png", "🖼️", "gif", "🖼️", "bmp", "🖼️", "ico", "🖼️",
    ; Video
    "mp4", "🎬", "avi", "🎬", "mkv", "🎬", "mov", "🎬", "wmv", "🎬",
    ; Audio
    "mp3", "🎵", "wav", "🎵", "flac", "🎵", "m4a", "🎵",
    ; Archives
    "zip", "🗜️", "rar", "🗜️", "7z", "🗜️", "tar", "🗜️", "gz", "🗜️",
    ; Executables
    "exe", "⚙️", "msi", "⚙️", "bat", "⚙️", "cmd", "⚙️",
    ; Web files
    "html", "🌐", "htm", "🌐", "php", "🌐", "css", "🌐", "js", "🌐",
    ; Code files
    "py", "📝", "cpp", "📝", "c", "📝", "java", "📝", "cs", "📝", "go", "📝",
    ; Shortcuts and links
    "lnk", "🔗", "url", "🔗"
)

; Get appropriate icon for file type
GetFileIcon(extension) {
    global fileIconMap
    extension := StrLower(extension)
    return fileIconMap.Has(extension) ? fileIconMap[extension] : "📄"
}

; Check if a window belongs to the system tray area
IsTrayWindow(winHwnd) {
    try {
        WinGetClass(&winClass, "ahk_id " . winHwnd)
        return (winClass = "Shell_TrayWnd" || winClass = "NotifyIconOverflowWindow" ||
            winClass = "TrayNotifyWnd" || winClass = "SysPager" || winClass = "ToolbarWindow32" ||
            winClass = "#32768" || InStr(winClass, "Menu"))
    } catch {
        return false
    }
}

; Default configuration fallback
DefaultConfig() {
    return {
        folderPath: EnvGet("OneDrive") . "\Links",
        iconIndex: 4,
        maxLevels: 3,
        darkMode: false
    }
}

; Function to get version from script JSDoc header
getVersionFromScript() {
    try {
        ; Read the script file to extract version from header comment
        scriptContent := FileRead(A_ScriptFullPath)

        ; Look for JSDoc @version format first
        if (RegExMatch(scriptContent, "im)@version\s+([\d\.]+)", &match)) {
            return match[1]
        }

        ; Fallback if version not found in expected format
        return "no version"
    } catch {
        ; Fallback version if file reading fails
        return "version error"
    }
}

; Function to open GitHub repository
OpenGitHub(*) {
    try {
        Run("https://github.com/mikromcz/TrayLinks")
    } catch as e {
        MsgBox("Error opening GitHub: " . e.Message, "Error", "Icon!")
    }
}

; Function to edit configuration
EditConfig(*) {
    global iniFile
    try {
        Run("notepad.exe `"" . iniFile . "`"")
    } catch {
        Run(iniFile)  ; Fallback to default associated program
    }
}

; Function to reload script
ReloadScript(*) {
    ; Clean shutdown before reload - unhook mouse first to prevent interference
    try {
        DllCall("UnhookWindowsHookEx", "Ptr", mouseHook)
    }
    ; Close all menus
    CloseAllMenus()
    ; Small delay to ensure cleanup completes
    Sleep(100)
    ; Now reload
    Reload
}

; Function to exit script
ExitScript(*) {
    ; Clean shutdown - unhook mouse first to prevent interference
    try {
        DllCall("UnhookWindowsHookEx", "Ptr", mouseHook)
    }
    ; Close all menus
    CloseAllMenus()
    ; Force exit
    ExitApp()
}

; Calculate dynamic height for a menu window with consistent padding
CalculateMenuHeight(listViewHeight) {
    ; Title area height with Windows 11 spacing (title + padding, no separator)
    titleHeight := 40

    ; Consistent bottom padding for all item counts
    bottomPadding := 12

    ; Total window height = title area + ListView height + bottom padding
    height := titleHeight + listViewHeight + bottomPadding

    ; Max height constraint - 1000px to fit more items while allowing scrolling
    return Min(1000, height)
}

; Function to handle opening the root folder
OpenRootFolder(*) {
    global folderPath

    if DirExist(folderPath)
        Run(folderPath)
    else
        MsgBox("Folder does not exist: " folderPath, "Error", "Icon!")
}

; Close all menus
CloseAllMenus() {
    global currentGuis, isMenuVisible

    ; Stop tooltip monitoring and clear any existing tooltips
    StopTooltipMonitoring()

    for level, gui in currentGuis {
        if (IsObject(gui)) {
            gui.Destroy()
        }
    }

    currentGuis := Map()
    isMenuVisible := false
}

; Close menus at and above specified level
CloseMenusAtLevel(level) {
    global currentGuis, config

    l := config.maxLevels
    while (l >= level) {
        if (currentGuis.Has(l) && IsObject(currentGuis[l])) {
            currentGuis[l].Destroy()
            currentGuis.Delete(l)
        }
        l--
    }
}

; Handle ListView item click - Just select the item
ItemClick(level, ctrl, *) {
    global config

    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0 || rowNum > ctrl.itemData.Length)
        return

    ; Get the selected item data
    item := ctrl.itemData[rowNum].data

    ; Close deeper level menus regardless of item type
    CloseMenusAtLevel(level + 1)

    ; For folders, navigate into the folder
    if (item.type = "folder") {
        if (level >= config.maxLevels)
            return

        ShowFolderContents(item.path, level + 1)
    }
}

; Handle ListView item double-click - Open files/shortcuts
ItemDoubleClick(level, ctrl, *) {
    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0 || rowNum > ctrl.itemData.Length)
        return

    ; Get the selected item data
    item := ctrl.itemData[rowNum].data

    ; Only process for non-folder items (files/shortcuts)
    if (item.type != "folder") {
        ; It's a file or shortcut - open it and close all menus
        try {
            Run(item.path)
            CloseAllMenus()
        } catch as e {
            MsgBox("Error opening file: " e.Message, "Error", "Icon!")
        }
    }
}

; Handle ListView context menu (right-click)
ItemContextMenu(level, ctrl, item, isRightClick, *) {
    ; Only show context menu on right-click
    if (!isRightClick)
        return

    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0 || rowNum > ctrl.itemData.Length)
        return

    ; Get the selected item data
    itemData := ctrl.itemData[rowNum].data

    ; Create context menu with Windows 11 styling
    ShowItemContextMenu(itemData, ctrl)
}

; Show context menu for an item
ShowItemContextMenu(itemData, listViewCtrl) {
    contextMenu := Menu()
    contextMenu.Add("Open item location", (*) => OpenItemLocation(itemData))
    contextMenu.Add("Copy path", (*) => CopyItemPath(itemData))
    contextMenu.Add("Properties", (*) => ShowItemProperties(itemData))

    ; Show the context menu at cursor position
    ; Use no parameters to show at current cursor position
    contextMenu.Show()
}

; Open the item's parent folder and select the item
OpenItemLocation(itemData) {
    try {
        Run('explorer.exe /select,"' . itemData.path . '"')

        ; Close all menus after action
        CloseAllMenus()
    } catch as e {
        MsgBox("Error opening item location: " . e.Message, "Error", "Icon!")
    }
}

; Copy the item's full path to clipboard
CopyItemPath(itemData) {
    try {
        A_Clipboard := itemData.path
    } catch as e {
        MsgBox("Error copying path: " . e.Message, "Error", "Icon!")
    }
}

; Show Windows properties dialog for the item
ShowItemProperties(itemData) {
    try {
        ; Use ShellExecute with "properties" verb to show Properties dialog only
        DllCall("shell32.dll\ShellExecuteW",
            "Ptr", 0,                    ; hwnd
            "WStr", "properties",        ; verb
            "WStr", itemData.path,       ; file
            "WStr", "",                  ; parameters
            "WStr", "",                  ; directory
            "Int", 1)                    ; show command

    } catch as e {
        ; Fallback: try alternative method using rundll32
        try {
            Run('rundll32.exe shell32.dll,OpenAs_RunDLL "' . itemData.path . '"')
        } catch as e2 {
            MsgBox("Error showing properties: " . e.Message, "Error", "Icon!")
        }
    }
}

; Simple tooltip tracking variables
global tooltipActive := false
global lastTooltipItem := ""

; Start tooltip monitoring when menus are visible
StartTooltipMonitoring() {
    global tooltipActive
    if (!tooltipActive) {
        tooltipActive := true
        SetTimer(CheckForTooltips, 100)  ; Check every 100ms
    }
}

; Stop tooltip monitoring when menus close
StopTooltipMonitoring() {
    global tooltipActive
    tooltipActive := false
    SetTimer(CheckForTooltips, 0)
    ToolTip()  ; Clear any existing tooltip
}

; Check if mouse is hovering over any ListView item and show tooltip
CheckForTooltips() {
    global currentGuis, lastTooltipItem

    if (!isMenuVisible) {
        StopTooltipMonitoring()
        return
    }

    ; Get mouse position and window under cursor
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY, &winHwnd)

    ; Check each active menu GUI
    for level, gui in currentGuis {
        if (IsObject(gui)) {
            try {
                ; Check if mouse is over this GUI
                WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " gui.Hwnd)

                if (mouseX >= winX && mouseX <= winX + winW &&
                    mouseY >= winY && mouseY <= winY + winH) {

                    ; Mouse is over this menu - find the ListView control
                    for ctrlHwnd, ctrlObj in gui {
                        if (ctrlObj.Type = "ListView") {
                            ; Get ListView position relative to GUI
                            ctrlObj.GetPos(&lvX, &lvY, &lvW, &lvH)

                            ; Convert to screen coordinates
                            lvScreenX := winX + lvX
                            lvScreenY := winY + lvY

                            ; Check if mouse is over the ListView
                            if (mouseX >= lvScreenX && mouseX <= lvScreenX + lvW &&
                                mouseY >= lvScreenY && mouseY <= lvScreenY + lvH) {

                                ; Calculate relative position within ListView
                                relX := mouseX - lvScreenX
                                relY := mouseY - lvScreenY

                                ; Determine which row (approximate - each row is ~20px)
                                rowIndex := Floor(relY / 20) + 1

                                ; Check if we have data for this row
                                if (rowIndex > 0 && rowIndex <= ctrlObj.itemData.Length) {
                                    itemData := ctrlObj.itemData[rowIndex].data

                                    ; For files, remove extension to match ListView display; folders keep full name
                                    if (itemData.type = "folder") {
                                        tooltipText := itemData.name
                                    } else {
                                        ; Remove extension from filename to match what's shown in ListView
                                        SplitPath(itemData.name, , , , &nameNoExt)
                                        tooltipText := nameNoExt
                                    }

                                    ; Only show tooltip if the name is longer than 24 characters
                                    if (StrLen(tooltipText) > 24) {
                                        ; Only update tooltip if it's different from last one
                                        if (tooltipText != lastTooltipItem) {
                                            ; Set coordinate mode for ToolTip to screen coordinates
                                            CoordMode("ToolTip", "Screen")
                                            ToolTip(tooltipText, mouseX + 15, mouseY + 15)
                                            lastTooltipItem := tooltipText
                                        }
                                    } else {
                                        ; Clear tooltip for short names
                                        if (lastTooltipItem != "") {
                                            ToolTip()
                                            lastTooltipItem := ""
                                        }
                                    }
                                    return
                                }
                            }
                        }
                    }
                }
            } catch {
                ; Ignore errors with destroyed windows - just skip this GUI
            }
        }
    }

    ; Mouse not over any ListView item - clear tooltip
    if (lastTooltipItem != "") {
        ToolTip()
        lastTooltipItem := ""
    }
}


; Scan a folder and return sorted arrays of {folders, files}
ScanFolder(folderToShow) {
    folders := []
    files := []

    try {
        loop files, folderToShow "\*", "D"
        {
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue
            folders.Push({ name: A_LoopFileName, path: A_LoopFileFullPath, type: "folder" })
        }
    }

    try {
        loop files, folderToShow "\*", "F"
        {
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue
            files.Push({ name: A_LoopFileName, path: A_LoopFileFullPath, type: "file" })
        }
    }

    return { folders: folders, files: files }
}

; Calculate menu window position based on level
CalculateMenuPosition(level, winWidth, menuHeight) {
    global currentGuis

    if (level = 1) {
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mouseX, &mouseY)
        winX := mouseX - 100
        winY := mouseY - 40
    } else {
        prevGui := currentGuis.Has(level - 1) ? currentGuis[level - 1] : ""

        if (IsObject(prevGui)) {
            WinGetPos(&prevX, &prevY, &prevW, &prevH, "ahk_id " prevGui.Hwnd)
            winX := prevX - winWidth - 5
            winY := prevY
        } else {
            CoordMode("Mouse", "Screen")
            MouseGetPos(&mouseX, &mouseY)
            winX := mouseX - (level * (winWidth + 5))
            winY := mouseY - 40
        }
    }

    ; Clamp to screen bounds
    winX := Max(10, Min(winX, A_ScreenWidth - winWidth - 20))
    winY := Max(10, Min(winY, A_ScreenHeight - menuHeight - 20))

    return { x: winX, y: winY }
}

; Create and show folder contents for a given level
ShowFolderContents(folderToShow, level := 1) {
    global currentGuis, isMenuVisible

    ; Get current color scheme
    colors := GetColors()

    ; Close menus at and above this level
    CloseMenusAtLevel(level)

    ; Create new GUI with Windows 11 styling
    menuGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    menuGui.BackColor := colors.backgroundCard
    ; Use Segoe UI Variable (Windows 11 font) with slightly larger size
    menuGui.SetFont("s10 c" colors.text, "Segoe UI Variable")

    ; Get folder name for title
    SplitPath(folderToShow, &folderName)
    if (level = 1 && folderToShow = folderPath)
        folderName := "Links"

    ; Add title with modern spacing and clean Windows 11 styling
    titleText := menuGui.Add("Text", "x16 y12 w172 c" colors.text, folderName)
    titleText.SetFont("s10 w600")  ; Semi-bold for title

    ; Scan folder contents
    scanned := ScanFolder(folderToShow)
    folders := scanned.folders
    files := scanned.files

    ; Calculate the number of items for listview sizing
    numItems := folders.Length + files.Length

    ; Ensure at least 1 item height to avoid empty listview
    if (numItems < 1)
        numItems := 1

    ; Calculate max rows that fit in 1000px window (approximately 40 rows)
    maxRows := 40
    displayRows := Min(numItems, maxRows)
    needsScrollbar := numItems > maxRows

    ; Create ListView with row count
    listView := menuGui.Add("ListView", "x12 y36 w176 r" displayRows " -Multi -Hdr Background" colors.backgroundCard " c" colors.text, ["", "Name"])

    ; Set column widths first: first column 0px (invisible), second column full width for proper selection
    listView.ModifyCol(1, 0)      ; First column width = 0 (hidden)
    listView.ModifyCol(2, 172)    ; Second column matches ListView width for full-width selection

    ; Add event handlers for click, double-click, and right-click
    listView.OnEvent("Click", ItemClick.Bind(level))
    listView.OnEvent("DoubleClick", ItemDoubleClick.Bind(level))
    listView.OnEvent("ContextMenu", ItemContextMenu.Bind(level))

    ; Add items to the ListView (folders first)
    listItems := []

    ; Add folders with Windows 11 style icons - using second column
    for folder in folders {
        row := listView.Add("", "", "🗂️ " folder.name)  ; Empty first column, data in second
        listItems.Push({ row: row, data: folder })
    }

    ; Add files - hide all extensions with modern icons - using second column
    for file in files {
        ; Split filename to remove extension
        SplitPath(file.name, , , &ext, &nameNoExt)

        ; Choose icon based on file type (Windows 11 style)
        icon := GetFileIcon(ext)
        row := listView.Add("", "", icon . " " nameNoExt)  ; Empty first column, data in second
        listItems.Push({ row: row, data: file })
    }

    ; Store items data with the ListView
    listView.itemData := listItems

    ; Calculate equivalent height for window sizing
    listViewHeight := displayRows * 20
    menuHeight := CalculateMenuHeight(listViewHeight)

    ; Position window based on level
    winWidth := 200
    pos := CalculateMenuPosition(level, winWidth, menuHeight)

    ; Show the GUI with the dynamic height
    menuGui.Show("x" pos.x " y" pos.y " w" winWidth " h" menuHeight " NoActivate")

    ; Apply Windows 11 styling (drop shadow and rounded corners)
    ApplyWindows11Styling(menuGui.Hwnd)

    ; NOW hide horizontal scrollbar after window is fully shown and rendered
    if (needsScrollbar) {
        ; Small delay to ensure ListView is fully rendered
        Sleep(20)
        ; Large folders: hide only horizontal scrollbar, keep vertical
        DllCall("SendMessage", "Ptr", listView.Hwnd, "UInt", 0x1033, "Ptr", 0x8, "Ptr", 0)  ; LVM_SETEXTENDEDLISTVIEWSTYLE with LVS_EX_NOHSCROLL
        DllCall("user32.dll\ShowScrollBar", "Ptr", listView.Hwnd, "Int", 0, "Int", 0)  ; Hide horizontal scrollbar
    }

    ; Store the GUI for this level
    currentGuis[level] := menuGui

    ; Set menu as visible and start tooltip monitoring
    isMenuVisible := true
    StartTooltipMonitoring()
}

; Handle global mouse clicks to close menus when clicking outside
OnGlobalMouseClick(wParam, lParam, msg, hwnd) {
    global currentGuis, isMenuVisible

    ; Only process if menus are visible
    if (!isMenuVisible)
        return

    ; Get the window under the mouse cursor
    CoordMode("Mouse", "Screen")
    MouseGetPos(, , &winUnderMouse)

    ; Check if click was on any menu or the tray icon
    clickedOnMenu := false

    ; Check each menu GUI
    for level, gui in currentGuis {
        try {
            if (IsObject(gui) && (winUnderMouse = gui.Hwnd || hwnd = gui.Hwnd)) {
                clickedOnMenu := true
                break
            }
        }
    }

    ; Also check if clicked on tray (to prevent closing when clicking tray icon)
    if (!clickedOnMenu && IsTrayWindow(winUnderMouse))
        clickedOnMenu := true

    ; If clicked outside menus and not on tray, close all
    if (!clickedOnMenu) {
        CloseAllMenus()
    }
}

; Low-level mouse hook for better click detection
LowLevelMouseProc(nCode, wParam, lParam) {
    global isMenuVisible

    ; Only process if menus are visible and it's a left button up
    if (nCode >= 0 && isMenuVisible && wParam = 0x202) {  ; WM_LBUTTONUP
        ; Get mouse position from the hook data
        mouseData := NumGet(lParam, 0, "Int")  ; x coordinate
        mouseY := NumGet(lParam, 4, "Int")     ; y coordinate

        ; Get window under mouse
        winUnderMouse := DllCall("WindowFromPoint", "Int64", mouseData | (mouseY << 32), "Ptr")

        ; Check if click was on any menu
        clickedOnMenu := false

        for level, gui in currentGuis {
            if (!IsObject(gui))
                continue

            try {
                if (winUnderMouse = gui.Hwnd) {
                    clickedOnMenu := true
                    break
                }

                ; Also check child windows (ListView controls)
                if (DllCall("IsChild", "Ptr", gui.Hwnd, "Ptr", winUnderMouse)) {
                    clickedOnMenu := true
                    break
                }
            }
        }

        ; Check if clicked on tray area or tray menu
        if (!clickedOnMenu && IsTrayWindow(winUnderMouse))
            clickedOnMenu := true

        ; If clicked outside menus, close them
        if (!clickedOnMenu) {
            SetTimer(() => CloseAllMenus(), -1)  ; Use timer to avoid hook issues
        }
    }

    ; Call next hook
    return DllCall("CallNextHookEx", "Ptr", 0, "Int", nCode, "UInt", wParam, "Ptr", lParam)
}

; Install low-level mouse hook for better click detection
mouseHook := DllCall("SetWindowsHookEx", "Int", 14, "Ptr", CallbackCreate(LowLevelMouseProc), "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr"), "UInt", 0, "Ptr")

; Register for mouse clicks (backup method)
OnMessage(0x202, OnGlobalMouseClick)  ; WM_LBUTTONUP

; Clean up hook on exit
OnExit((*) => DllCall("UnhookWindowsHookEx", "Ptr", mouseHook))

; Use OnMessage to detect when mouse clicks on tray icon
OnMessage(0x404, TrayIconClick)  ; WM_USER + 4 (0x400 + 4)

; Handle tray icon click
TrayIconClick(wParam, lParam, *) {
    global isMenuVisible, folderPath

    if (lParam = 0x201)  ; WM_LBUTTONDOWN
    {
        if (isMenuVisible) {
            CloseAllMenus()
        } else {
            ShowFolderContents(folderPath, 1)
        }
    }
    else if (lParam = 0x203)  ; WM_LBUTTONDBLCLK
    {
        OpenRootFolder()
    }
}

; Define a hotkey to force show the menu
#f::  ; Win+F hotkey
{
    global isMenuVisible, folderPath

    if (isMenuVisible) {
        CloseAllMenus()
    } else {
        ShowFolderContents(folderPath, 1)
    }
}

; End of script