/**
 * @description AutoHotkey2 Folder Toolbar Script
 * Creates a system tray icon with folder menus similar to Windows "pin folder to taskbar" feature removed in Windows 11.
 * @author mikrom, ClaudeAI
 * @version 3.4.0
 */

#Requires AutoHotkey v2.0
#SingleInstance Force

; Script version - keep in sync with the @version tag above
global SCRIPT_VERSION := "3.4.0"

; Screen coordinates for every thread (set once, inherited by all threads)
CoordMode("Mouse", "Screen")
CoordMode("ToolTip", "Screen")

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
; Icon index from imageres.dll (optional)
IconIndex=205

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
    for line in lines {
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

; Every icon in the app - tray and both menus - comes out of this one file.
; Numbers are 1-based icon positions within it, the same numbering the INI's
; IconIndex uses, so swapping the file swaps all of them together.
global ICON_FILE := "imageres.dll"

; Menu item icons. Swap freely - a number that does not resolve on a given
; Windows build just leaves that item without an icon.
global MENU_ICON_OPEN_LOCATION := 195  ; Open item location
global MENU_ICON_OPEN_FOLDER := 205    ; Open links folder
global MENU_ICON_COPY_PATH := 244      ; Copy path
global MENU_ICON_PROPERTIES := 75      ; Properties
global MENU_ICON_VERSION := 77         ; Version / about
global MENU_ICON_EDIT_CONFIG := 248    ; Edit configuration
global MENU_ICON_EXIT := 94            ; Exit

; Set up the tray icon
try {
    TraySetIcon(ICON_FILE, config.iconIndex)
} catch {
    ; Fallback if that specific icon fails
}

; Set tooltip for the tray icon
A_IconTip := "TrayLinks - Click for menu`nPath: " . folderPath . "`nMode: " . (config.darkMode ? "Dark" : "Light")

; Render standard popup menus dark when the INI asks for dark mode
if (config.darkMode)
    EnableDarkMenus()

; Customize the tray menu (will show on right-click)
A_TrayMenu.Delete() ; Clear default menu
A_TrayMenu.Add("TrayLinks", OpenGitHub)  ; Script name - opens GitHub
A_TrayMenu.Add("v" . SCRIPT_VERSION, OpenGitHub)  ; Version - opens GitHub
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Open Links Folder", OpenRootFolder)
A_TrayMenu.Add("Edit Configuration", EditConfig)
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Exit", ExitScript)
A_TrayMenu.Default := "TrayLinks"

; Same icon treatment as the item context menu. The app entry reuses whichever
; icon the INI picked for the tray itself, so the two always match.
SetMenuItemIcon(A_TrayMenu, "TrayLinks", config.iconIndex)
SetMenuItemIcon(A_TrayMenu, "v" . SCRIPT_VERSION, MENU_ICON_VERSION)
SetMenuItemIcon(A_TrayMenu, "Open Links Folder", MENU_ICON_OPEN_FOLDER)
SetMenuItemIcon(A_TrayMenu, "Edit Configuration", MENU_ICON_EDIT_CONFIG)
SetMenuItemIcon(A_TrayMenu, "Exit", MENU_ICON_EXIT)

; Global variables
global currentGuis := Map()      ; Store GUIs by level (1, 2, 3)
global isMenuVisible := false
global mouseHook := 0            ; Low-level mouse hook handle (0 = not installed)
global mouseHookCallback := 0    ; Callback address, created once at startup

; Menu layout metrics (Windows 11 spacing)
; Horizontal layout:  |<- PADDING ->|<- ListView ->|<- PADDING ->|
; Vertical layout:    |<- LIST_TOP ->|<- ListView ->|<- BOTTOM_PADDING ->|
global MENU_WIDTH := 200         ; Menu window width
global MENU_PADDING := 5         ; Gap between the window edge and the ListView (left/right)
global MENU_TITLE_INDENT := 6    ; Extra title indent, to line the title up with the item text
global MENU_LIST_TOP := 36       ; Y position of the ListView = height of the title area
global MENU_ROW_HEIGHT := 20     ; ListView row height - used for sizing and hit-testing
global MENU_MAX_ROWS := 40       ; Rows shown before the ListView starts scrolling
global MENU_BOTTOM_PADDING := 10 ; Gap between the ListView and the bottom window edge
global TOOLTIP_MIN_LENGTH := 24  ; Show a tooltip only for names longer than this

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
    return fileIconMap.Get(StrLower(extension), "📄")
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
        iconIndex: 205,
        maxLevels: 3,
        darkMode: false
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

; Function to exit script
ExitScript(*) {
    ; Clean shutdown - CloseAllMenus() also removes the mouse hook
    CloseAllMenus()
    ExitApp()
}

; Calculate dynamic height for a menu window with consistent padding
CalculateMenuHeight(listViewHeight) {
    ; Total window height = title area + ListView height + bottom padding.
    ; MENU_LIST_TOP is where the ListView actually starts, so MENU_BOTTOM_PADDING
    ; is exactly the gap you see below it. MENU_MAX_ROWS caps listViewHeight,
    ; so no extra clamp is needed here.
    return MENU_LIST_TOP + listViewHeight + MENU_BOTTOM_PADDING
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

    ; No menus open - stop watching global mouse traffic
    RemoveMouseHook()

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
    item := ctrl.itemData[rowNum]

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
ItemDoubleClick(ctrl, *) {
    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0 || rowNum > ctrl.itemData.Length)
        return

    ; Get the selected item data
    item := ctrl.itemData[rowNum]

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
ItemContextMenu(ctrl, item, isRightClick, *) {
    ; Only show context menu on right-click
    if (!isRightClick)
        return

    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0 || rowNum > ctrl.itemData.Length)
        return

    ; Create context menu with Windows 11 styling
    ShowItemContextMenu(ctrl.itemData[rowNum])
}

; Show context menu for an item
ShowItemContextMenu(itemData) {
    contextMenu := Menu()
    contextMenu.Add("Open item location", (*) => OpenItemLocation(itemData))
    contextMenu.Add("Copy path", (*) => CopyItemPath(itemData))
    contextMenu.Add("Properties", (*) => ShowItemProperties(itemData))

    ; Icons go in the gutter Windows already reserves for them, not in the label
    SetMenuItemIcon(contextMenu, "Open item location", MENU_ICON_OPEN_LOCATION)
    SetMenuItemIcon(contextMenu, "Copy path", MENU_ICON_COPY_PATH)
    SetMenuItemIcon(contextMenu, "Properties", MENU_ICON_PROPERTIES)

    ; Show the context menu at cursor position
    ; Use no parameters to show at current cursor position
    contextMenu.Show()
}

; Ask Windows to render this process's standard popup menus in dark mode.
;
; Menu.SetColor() is not the answer here: it sets the menu background brush but
; not the text colour, so a dark background leaves black-on-dark text. Windows
; 10 1809+ can theme menus properly - background, text and hover - but only if
; the process opts in through SetPreferredAppMode and FlushMenuThemes. Those are
; undocumented uxtheme exports available by ordinal only (135 and 136), so this
; is best-effort: on an older build the ordinals resolve to 0 and the menus stay
; light, exactly as before.
EnableDarkMenus() {
    FORCE_DARK := 2  ; PreferredAppMode: Default 0, AllowDark 1, ForceDark 2, ForceLight 3

    try {
        uxtheme := DllCall("GetModuleHandle", "Str", "uxtheme", "Ptr")
        if (!uxtheme)
            uxtheme := DllCall("LoadLibrary", "Str", "uxtheme.dll", "Ptr")
        if (!uxtheme)
            return

        ; Ordinals are passed where the export name would normally go
        setPreferredAppMode := DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 135, "Ptr")
        flushMenuThemes := DllCall("GetProcAddress", "Ptr", uxtheme, "Ptr", 136, "Ptr")
        if (!setPreferredAppMode || !flushMenuThemes)
            return

        DllCall(setPreferredAppMode, "Int", FORCE_DARK)
        DllCall(flushMenuThemes)
    }
}

; Give a menu item its icon. Each call is guarded on its own so one icon number
; that does not resolve on this Windows build cannot cost the others theirs.
SetMenuItemIcon(menuObj, itemName, iconNumber) {
    try {
        menuObj.SetIcon(itemName, ICON_FILE, iconNumber)
    }
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

    ; Clear the tooltip AND the last-shown name, otherwise hovering the same
    ; item again after reopening the menu would be treated as "no change"
    ClearTooltip()
}

; Check if mouse is hovering over any ListView item and show tooltip
CheckForTooltips() {
    global currentGuis

    if (!isMenuVisible) {
        StopTooltipMonitoring()
        return
    }

    MouseGetPos(&mouseX, &mouseY)

    ; Check each active menu GUI
    for level, gui in currentGuis {
        item := HoveredItem(gui, mouseX, mouseY)
        if (IsObject(item)) {
            ShowItemTooltip(item, mouseX, mouseY)
            return
        }
    }

    ; Mouse not over any ListView item - clear tooltip
    ClearTooltip()
}

; Return the item under the given screen position in a menu, or "" if none
HoveredItem(gui, mouseX, mouseY) {
    try {
        ; Check if mouse is over this GUI
        WinGetPos(&winX, &winY, &winW, &winH, "ahk_id " gui.Hwnd)
        if (mouseX < winX || mouseX > winX + winW || mouseY < winY || mouseY > winY + winH)
            return ""

        ; Check if mouse is over the ListView (position is relative to the GUI)
        gui.listView.GetPos(&lvX, &lvY, &lvW, &lvH)
        relX := mouseX - (winX + lvX)
        relY := mouseY - (winY + lvY)
        if (relX < 0 || relX > lvW || relY < 0 || relY > lvH)
            return ""

        ; Determine which row the mouse is over
        rowIndex := Floor(relY / MENU_ROW_HEIGHT) + 1
        itemData := gui.listView.itemData

        return (rowIndex > 0 && rowIndex <= itemData.Length) ? itemData[rowIndex] : ""
    } catch {
        ; Ignore errors with destroyed windows - just skip this GUI
        return ""
    }
}

; Show a tooltip for an item, but only when its displayed name is long
ShowItemTooltip(item, mouseX, mouseY) {
    global lastTooltipItem

    ; For files, remove extension to match ListView display; folders keep full name
    if (item.type = "folder") {
        tooltipText := item.name
    } else {
        SplitPath(item.name, , , , &nameNoExt)
        tooltipText := nameNoExt
    }

    ; Short names are fully visible in the menu already
    if (StrLen(tooltipText) <= TOOLTIP_MIN_LENGTH) {
        ClearTooltip()
        return
    }

    ; Only update tooltip if it's different from last one
    if (tooltipText != lastTooltipItem) {
        ToolTip(tooltipText, mouseX + 15, mouseY + 15)
        lastTooltipItem := tooltipText
    }
}

; Hide the tooltip if one is showing
ClearTooltip() {
    global lastTooltipItem

    if (lastTooltipItem != "") {
        ToolTip()
        lastTooltipItem := ""
    }
}


; Scan a folder and return sorted arrays of {folders, files}
ScanFolder(folderToShow) {
    folders := []
    files := []

    ; Single pass over the directory, split by attribute
    try {
        loop files, folderToShow "\*", "FD"
        {
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue

            if (InStr(A_LoopFileAttrib, "D"))
                folders.Push({ name: A_LoopFileName, path: A_LoopFileFullPath, type: "folder" })
            else
                files.Push({ name: A_LoopFileName, path: A_LoopFileFullPath, type: "file" })
        }
    }

    return { folders: folders, files: files }
}

; Calculate menu window position based on level
CalculateMenuPosition(level, winWidth, menuHeight) {
    global currentGuis

    if (level = 1) {
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
    global currentGuis, isMenuVisible, folderPath

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
    titleX := MENU_PADDING + MENU_TITLE_INDENT
    titleWidth := MENU_WIDTH - titleX - MENU_PADDING
    titleText := menuGui.Add("Text", "x" titleX " y12 w" titleWidth " c" colors.text, folderName)
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

    ; Cap the visible rows - anything beyond that scrolls
    displayRows := Min(numItems, MENU_MAX_ROWS)
    needsScrollbar := numItems > MENU_MAX_ROWS

    ; Create ListView with row count - borderless so it blends into the window:
    ; -E0x200 drops WS_EX_CLIENTEDGE (the light gray frame), -Border drops WS_BORDER
    listViewWidth := MENU_WIDTH - (MENU_PADDING * 2)
    listViewOpts := "x" MENU_PADDING " y" MENU_LIST_TOP " w" listViewWidth " r" displayRows
    listViewOpts .= " -Multi -Hdr -Border -E0x200 Background" colors.backgroundCard " c" colors.text
    listView := menuGui.Add("ListView", listViewOpts, ["", "Name"])

    ; Set column widths first: first column 0px (invisible), second column full width for proper selection
    listView.ModifyCol(1, 0)                    ; First column width = 0 (hidden)
    listView.ModifyCol(2, listViewWidth)        ; Second column fills the rest for full-width selection

    ; Add event handlers for click, double-click, and right-click
    listView.OnEvent("Click", ItemClick.Bind(level))
    listView.OnEvent("DoubleClick", ItemDoubleClick)
    listView.OnEvent("ContextMenu", ItemContextMenu)

    ; Add items to the ListView (folders first) - row order matches itemData order
    listItems := []

    ; Add folders with Windows 11 style icons - using second column
    for folder in folders {
        listView.Add("", "", "🗂️ " folder.name)  ; Empty first column, data in second
        listItems.Push(folder)
    }

    ; Add files - hide all extensions with modern icons - using second column
    for file in files {
        ; Split filename to remove extension
        SplitPath(file.name, , , &ext, &nameNoExt)

        ; Choose icon based on file type (Windows 11 style)
        listView.Add("", "", GetFileIcon(ext) . " " nameNoExt)  ; Empty first column, data in second
        listItems.Push(file)
    }

    ; Store items data with the ListView, and the ListView with its GUI
    listView.itemData := listItems
    menuGui.listView := listView

    ; Calculate equivalent height for window sizing
    menuHeight := CalculateMenuHeight(displayRows * MENU_ROW_HEIGHT)

    ; Position window based on level
    winWidth := MENU_WIDTH
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
        DllCall("user32.dll\ShowScrollBar", "Ptr", listView.Hwnd, "Int", 0, "Int", 0)  ; SB_HORZ, hide
    }

    ; Store the GUI for this level
    currentGuis[level] := menuGui

    ; Set menu as visible, watch for clicks outside and start tooltip monitoring
    isMenuVisible := true
    InstallMouseHook()
    StartTooltipMonitoring()
}

; Low-level mouse hook for better click detection
LowLevelMouseProc(nCode, wParam, lParam) {
    global isMenuVisible, currentGuis

    ; Only process if menus are visible and it's a left button up
    if (nCode >= 0 && isMenuVisible && wParam = 0x202) {  ; WM_LBUTTONUP
        ; Get mouse position from the hook data (MSLLHOOKSTRUCT starts with a POINT)
        mouseX := NumGet(lParam, 0, "Int")  ; x coordinate
        mouseY := NumGet(lParam, 4, "Int")  ; y coordinate

        ; Get window under mouse - mask x so a negative value (monitor left of the
        ; primary one) cannot bleed into the packed y coordinate
        winUnderMouse := DllCall("WindowFromPoint", "Int64", (mouseX & 0xFFFFFFFF) | (mouseY << 32), "Ptr")

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

; Install the low-level mouse hook - only while a menu is open, so the script
; does not sit in the path of every mouse message while idle
InstallMouseHook() {
    global mouseHook, mouseHookCallback

    if (mouseHook)
        return

    try {
        mouseHook := DllCall("SetWindowsHookEx", "Int", 14, "Ptr", mouseHookCallback,
            "Ptr", DllCall("GetModuleHandle", "Ptr", 0, "Ptr"), "UInt", 0, "Ptr")
    } catch {
        mouseHook := 0
    }
}

; Remove the low-level mouse hook
RemoveMouseHook() {
    global mouseHook

    if (!mouseHook)
        return

    try {
        DllCall("UnhookWindowsHookEx", "Ptr", mouseHook)
    }
    mouseHook := 0
}

; Create the hook callback once - the address stays valid for the whole session
mouseHookCallback := CallbackCreate(LowLevelMouseProc)

; Clean up hook on exit
OnExit((*) => RemoveMouseHook())

; Use OnMessage to detect when mouse clicks on tray icon
OnMessage(0x404, TrayIconClick)  ; WM_USER + 4 (0x400 + 4)

; Show the root menu, or close everything if a menu is already open
ToggleMenu() {
    global isMenuVisible, folderPath

    if (isMenuVisible)
        CloseAllMenus()
    else
        ShowFolderContents(folderPath, 1)
}

; Handle tray icon click
TrayIconClick(wParam, lParam, *) {
    if (lParam = 0x201)  ; WM_LBUTTONDOWN
        ToggleMenu()
    else if (lParam = 0x203)  ; WM_LBUTTONDBLCLK
        OpenRootFolder()
}

; Define a hotkey to force show the menu
#f::ToggleMenu()  ; Win+F hotkey

; End of script
