/**
 * @description AutoHotkey2 Folder Toolbar Script
 * Creates a system tray icon with folder menus that open on the left side
 * @author mikrom, ClaudeAI
 * @version 2.0.0
 */

#Requires AutoHotkey v2.0

; Configuration - INI file handling
scriptDir := A_ScriptDir
scriptName := A_ScriptName
SplitPath(scriptName, , , , &nameNoExt)
iniFile := scriptDir . "\" . nameNoExt . ".ini"

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

; Function to read configuration from INI
ReadConfig() {
    global iniFile

    ; Check if INI file exists, create if not
    if (!FileExist(iniFile)) {
        if (!CreateDefaultIni()) {
            ; If we can't create INI, use fallback
            return {
                folderPath: EnvGet("OneDrive") . "\Links",
                iconIndex: 4,
                maxLevels: 3,
                darkMode: false
            }
        }
    }

    ; Read settings from INI
    try {
        rawPath := IniRead(iniFile, "Settings", "FolderPath", "%OneDrive%\Links")
        darkModeRaw := IniRead(iniFile, "Settings", "DarkMode", "false")
        iconIndex := IniRead(iniFile, "Advanced", "IconIndex", "4")
        maxLevels := IniRead(iniFile, "Advanced", "MaxLevels", "3")

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
        return {
            folderPath: EnvGet("OneDrive") . "\Links",
            iconIndex: 4,
            maxLevels: 3,
            darkMode: false
        }
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
A_TrayMenu.Add("TrayLinks", (*) => {})  ; Script name (non-clickable)
A_TrayMenu.Add("v2.0.0", (*) => {})     ; Version (non-clickable)
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Open Links Folder", OpenRootFolder)
A_TrayMenu.Add("Edit Configuration", EditConfig)
A_TrayMenu.Add("Reload Script", ReloadScript)
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Exit", ExitScript)
A_TrayMenu.Default := "TrayLinks"

; Global variables
global currentGuis := Map()      ; Store GUIs by level (1, 2, 3)
global currentPaths := Map()     ; Store paths by level
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

; Get appropriate icon for file type (Windows 11 style)
GetFileIcon(extension) {
    extension := StrLower(extension)

    ; Document files
    if (extension = "txt" || extension = "rtf" || extension = "doc" || extension = "docx")
        return "📄"

    ; PDF files
    if (extension = "pdf")
        return "📕"

    ; Spreadsheet files
    if (extension = "xls" || extension = "xlsx" || extension = "csv")
        return "📊"

    ; Presentation files
    if (extension = "ppt" || extension = "pptx")
        return "📋"

    ; Image files
    if (extension = "jpg" || extension = "jpeg" || extension = "png" || extension = "gif" || extension = "bmp" || extension = "ico")
        return "🖼️"

    ; Video files
    if (extension = "mp4" || extension = "avi" || extension = "mkv" || extension = "mov" || extension = "wmv")
        return "🎬"

    ; Audio files
    if (extension = "mp3" || extension = "wav" || extension = "flac" || extension = "m4a")
        return "🎵"

    ; Archive files
    if (extension = "zip" || extension = "rar" || extension = "7z" || extension = "tar" || extension = "gz")
        return "🗜️"

    ; Executable files
    if (extension = "exe" || extension = "msi" || extension = "bat" || extension = "cmd")
        return "⚙️"

    ; Web files
    if (extension = "html" || extension = "htm" || extension = "php" || extension = "css" || extension = "js")
        return "🌐"

    ; Code files
    if (extension = "py" || extension = "cpp" || extension = "c" || extension = "java" || extension = "cs" || extension = "go")
        return "📝"

    ; Shortcuts and links
    if (extension = "lnk" || extension = "url")
        return "🔗"

    ; Default for unknown files
    return "📄"
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
CalculateMenuHeight(listViewHeight, itemCount := 0) {
    ; Title area height with Windows 11 spacing (title + padding, no separator)
    titleHeight := 40

    ; Consistent bottom padding for all item counts
    bottomPadding := 8

    ; Total window height = title area + ListView height + bottom padding
    height := titleHeight + listViewHeight + bottomPadding

    ; No minimum height constraint - let it size naturally
    return Min(640, height)
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

    for level, gui in currentGuis {
        if (IsObject(gui)) {
            gui.Destroy()
        }
    }

    currentGuis := Map()
    currentPaths := Map()
    isMenuVisible := false
}

; Close menus at and above specified level
CloseMenusAtLevel(level) {
    global currentGuis, currentPaths, config

    ; Check from max level down to the specified level
    for l in Range(config.maxLevels, level, -1) {
        if (currentGuis.Has(l) && IsObject(currentGuis[l])) {
            currentGuis[l].Destroy()
            currentGuis.Delete(l)
            if (currentPaths.Has(l))
                currentPaths.Delete(l)
        }
    }
}

; Helper function to create a range with step
Range(start, end, step := 1) {
    result := []
    if (step > 0) {
        loop {
            if (start > end)
                break
            result.Push(start)
            start += step
        }
    } else {
        loop {
            if (start < end)
                break
            result.Push(start)
            start += step
        }
    }
    return result
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

    ; For folders, navigate as before
    if (item.type = "folder") {
        ; Check if we're at max level
        if (level >= config.maxLevels)
            return

        ; If folder in level 1, close level 2+ and open this folder
        if (level = 1) {
            CloseMenusAtLevel(2)  ; Close level 2 and above
            ShowFolderContents(item.path, 2)  ; Show level 2
        }
        ; If folder in level 2, close level 3+ and open this folder
        else if (level = 2) {
            CloseMenusAtLevel(3)  ; Close level 3 and above
            ShowFolderContents(item.path, 3)  ; Show level 3
        }
        ; For deeper levels, just show next level
        else if (level < config.maxLevels) {
            ShowFolderContents(item.path, level + 1)
        }
    }
    ; For non-folders, just select (do nothing else)
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

; Create and show folder contents for a given level
ShowFolderContents(folderToShow, level := 1) {
    global currentGuis, currentPaths, isMenuVisible

    ; Get current color scheme
    colors := GetColors()

    ; Close menus at and above this level
    CloseMenusAtLevel(level)

    ; Remember the path for this level
    currentPaths[level] := folderToShow

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

    ; Data structures
    folders := []
    files := []

    ; Scan for directories first
    try {
        loop files, folderToShow "\*", "D"  ; Only directories
        {
            ; Skip desktop.ini and hidden directories
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue

            ; Add to folders array
            folders.Push({ name: A_LoopFileName, path: A_LoopFileFullPath, type: "folder" })
        }
    } catch as e {
        ; Handle error silently
    }

    ; Then scan for files
    try {
        loop files, folderToShow "\*", "F"  ; Only files
        {
            ; Skip desktop.ini and hidden files
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue

            ; Add to files array
            files.Push({ name: A_LoopFileName, path: A_LoopFileFullPath, type: "file" })
        }
    } catch as e {
        ; Handle error silently
    }

    ; Calculate the number of items for listview sizing
    numItems := folders.Length + files.Length

    ; Ensure at least 1 item height to avoid empty listview
    if (numItems < 1)
        numItems := 1

    ; Create ListView with Windows 11 styling - two columns for padding control
    listView := menuGui.Add("ListView", "x12 y36 w176 r" numItems " -Multi -Hdr Background" colors.backgroundCard " c" colors.text, ["", "Name"])

    ; Force no scrollbars using multiple methods
    DllCall("SendMessage", "Ptr", listView.Hwnd, "UInt", 0x1033, "Ptr", 0x8, "Ptr", 0)  ; LVM_SETEXTENDEDLISTVIEWSTYLE with LVS_EX_NOHSCROLL

    ; Disable both horizontal and vertical scrollbar styles
    WinSetStyle(-0x20000, listView.Hwnd)   ; Remove LVS_HSCROLL style
    WinSetStyle(-0x200000, listView.Hwnd)  ; Remove WS_VSCROLL style

    ; Additional scrollbar removal via ShowScrollBar API
    DllCall("user32.dll\ShowScrollBar", "Ptr", listView.Hwnd, "Int", 0, "Int", 0)  ; Hide horizontal scrollbar
    DllCall("user32.dll\ShowScrollBar", "Ptr", listView.Hwnd, "Int", 1, "Int", 0)  ; Hide vertical scrollbar

    ; Set column widths: first column 0px (invisible), second column smaller to prevent horizontal scroll
    listView.ModifyCol(1, 0)      ; First column width = 0 (hidden)
    listView.ModifyCol(2, 160)    ; Second column slightly smaller to prevent scrollbars

    ; Add event handlers for click and double-click
    listView.OnEvent("Click", ItemClick.Bind(level))
    listView.OnEvent("DoubleClick", ItemDoubleClick.Bind(level))

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

    ; Get the actual ListView height after items are added
    WinGetPos(, , , &actualListViewHeight, "ahk_id " listView.Hwnd)

    ; Calculate menu height using actual ListView height for consistent bottom padding
    menuHeight := CalculateMenuHeight(actualListViewHeight, numItems)

    ; Position window based on level
    winWidth := 200  ; Fixed width at 200px
    winX := 0

    ; Position menus from left to right based on level
    if (level = 1) {
        ; First level menu appears at mouse position
        CoordMode("Mouse", "Screen")
        MouseGetPos(&mouseX, &mouseY)
        winX := mouseX - 100  ; Center around mouse X
        winY := mouseY - 40   ; Position a bit above the cursor
    } else {
        ; Subsequent levels position to the left of the previous level
        prevGui := currentGuis[level - 1]

        if (IsObject(prevGui)) {
            WinGetPos(&prevX, &prevY, &prevW, &prevH, "ahk_id " prevGui.Hwnd)
            winX := prevX - winWidth - 5
            winY := prevY  ; Same Y position as previous menu
        } else {
            ; Fallback position if previous GUI not found
            CoordMode("Mouse", "Screen")
            MouseGetPos(&mouseX, &mouseY)
            winX := mouseX - (level * (winWidth + 5))
            winY := mouseY - 40
        }
    }

    ; Make sure we don't go off screen
    if (winY + menuHeight > A_ScreenHeight)
        winY := A_ScreenHeight - menuHeight - 20

    if (winX + winWidth > A_ScreenWidth)
        winX := A_ScreenWidth - winWidth - 20

    if (winY < 10)
        winY := 10

    if (winX < 10)
        winX := 10

    ; Show the GUI with the dynamic height
    menuGui.Show("x" winX " y" winY " w" winWidth " h" menuHeight " NoActivate")

    ; Apply Windows 11 styling (drop shadow and rounded corners)
    ApplyWindows11Styling(menuGui.Hwnd)

    ; Store the GUI for this level
    currentGuis[level] := menuGui

    ; Set menu as visible
    isMenuVisible := true
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
        if (IsObject(gui) && (winUnderMouse = gui.Hwnd || hwnd = gui.Hwnd)) {
            clickedOnMenu := true
            break
        }
    }

    ; Also check if clicked on tray (to prevent closing when clicking tray icon)
    try {
        WinGetClass(&winClass, "ahk_id " . winUnderMouse)
        if (winClass = "Shell_TrayWnd" || winClass = "NotifyIconOverflowWindow" ||
            winClass = "TrayNotifyWnd" || winClass = "SysPager" || winClass = "ToolbarWindow32" ||
            winClass = "#32768" || InStr(winClass, "Menu")) {
            clickedOnMenu := true
        }
    } catch {
        ; Ignore errors
    }

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
            if (IsObject(gui) && winUnderMouse = gui.Hwnd) {
                clickedOnMenu := true
                break
            }

            ; Also check child windows (ListView controls)
            if (IsObject(gui)) {
                try {
                    if (DllCall("IsChild", "Ptr", gui.Hwnd, "Ptr", winUnderMouse)) {
                        clickedOnMenu := true
                        break
                    }
                } catch {
                    ; Ignore errors
                }
            }
        }

        ; Check if clicked on tray area or tray menu
        if (!clickedOnMenu) {
            try {
                WinGetClass(&winClass, "ahk_id " . winUnderMouse)
                if (winClass = "Shell_TrayWnd" || winClass = "NotifyIconOverflowWindow" ||
                    winClass = "TrayNotifyWnd" || winClass = "SysPager" || winClass = "ToolbarWindow32" ||
                    winClass = "#32768" || InStr(winClass, "Menu")) {
                    clickedOnMenu := true
                }
            } catch {
                ; Ignore errors
            }
        }

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

/* Esc:: ; Esc to close all
{
    global isMenuVisible

    if (isMenuVisible) {
        CloseAllMenus()
    }

}
 */

; End of script