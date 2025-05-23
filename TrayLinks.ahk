; AutoHotkey2 Folder Toolbar Script
; Creates a system tray icon with folder menus that open on the left side

#Requires AutoHotkey v2.0

; Configuration - INI file handling
scriptDir := A_ScriptDir
scriptName := A_ScriptName
SplitPath(scriptName, , , , &nameNoExt)
iniFile := scriptDir . "\" . nameNoExt . ".ini"

; Function to expand environment variables in a path
ExpandPath(path) {
    ; Use ComObject to expand environment variables
    shell := ComObject("WScript.Shell")
    try {
        return shell.ExpandEnvironmentStrings(path)
    } catch {
        ; If expansion fails, return original path
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
                maxLevels: 3
            }
        }
    }

    ; Read settings from INI
    try {
        rawPath := IniRead(iniFile, "Settings", "FolderPath", "%OneDrive%\Links")
        iconIndex := IniRead(iniFile, "Advanced", "IconIndex", "4")
        maxLevels := IniRead(iniFile, "Advanced", "MaxLevels", "3")

        ; Expand environment variables in the path
        expandedPath := ExpandPath(rawPath)

        return {
            folderPath: expandedPath,
            iconIndex: Integer(iconIndex),
            maxLevels: Integer(maxLevels)
        }
    } catch as e {
        MsgBox("Error reading INI file: " . e.Message . "`nUsing default settings.", "Warning", "Icon!")
        return {
            folderPath: EnvGet("OneDrive") . "\Links",
            iconIndex: 4,
            maxLevels: 3
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
A_IconTip := "Folder Links - Click for menu`nPath: " . folderPath

; Customize the tray menu (will show on right-click)
A_TrayMenu.Delete() ; Clear default menu
A_TrayMenu.Add("Open Links Folder", OpenRootFolder)
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Edit Configuration", EditConfig)
A_TrayMenu.Add("Reload Script", ReloadScript)
A_TrayMenu.Add()  ; Separator
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Open Links Folder"

; Global variables
global currentGuis := Map()      ; Store GUIs by level (1, 2, 3)
global currentPaths := Map()     ; Store paths by level
global isMenuVisible := false

; Dark mode colors
global darkColors := {
    background: "202020",
    text: "FFFFFF",
    border: "404040",
    selected: "0078D7"
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
    Reload
}

; Calculate dynamic height for a ListView based on item count
CalculateMenuHeight(itemCount) {
    ; Title area height (text + separator line)
    titleHeight := 40

    ; Height per item - adjusted based on empirical testing
    itemHeight := 21

    ; Target bottom padding
    targetPadding := 16

    ; Ensure at least one item
    if (itemCount < 1)
        itemCount := 1

    ; Calculate adjustment using logarithmic-style curve
    ; This creates a very gentle curve that adds minimal extra padding as item count increases
    adjustment := itemCount > 1 ? Sqrt(itemCount - 1) : 0

    ; Final height calculation with fine-tuned adjustment
    height := titleHeight + (itemCount * itemHeight) + targetPadding

    ; Constrain within reasonable min/max values
    return Max(80, Min(600, height))
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
    global currentGuis, currentPaths

    ; Simple approach: manually check for each possible level in descending order
    ; This works because we only have a few levels (1, 2, 3)
    for l in [5, 4, 3, 2, 1] {
        if (l >= level && currentGuis.Has(l) && IsObject(currentGuis[l])) {
            currentGuis[l].Destroy()
            currentGuis.Delete(l)
            currentPaths.Delete(l)
        }
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
    global currentGuis, currentPaths, darkColors, isMenuVisible

    ; Close menus at and above this level
    CloseMenusAtLevel(level)

    ; Remember the path for this level
    currentPaths[level] := folderToShow

    ; Create new GUI
    menuGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    menuGui.BackColor := darkColors.background
    menuGui.SetFont("s10 c" darkColors.text, "Segoe UI")

    ; Get folder name for title
    SplitPath(folderToShow, &folderName)
    if (level = 1 && folderToShow = folderPath)
        folderName := "Links"

    ; Add title
    menuGui.Add("Text", "x10 y10 w180", folderName)

    ; Add a horizontal line
    menuGui.Add("Text", "x10 y30 w180 h1 c" darkColors.border " 0x10")

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

    ; Create ListView
    listView := menuGui.Add("ListView", "x10 y40 w180 r" numItems " -Multi -Hdr Background" darkColors.background " c" darkColors
        .text, ["Name"])

    ; Force no horizontal scrollbar using direct Windows API
    DllCall("SendMessage", "Ptr", listView.Hwnd, "UInt", 0x1033, "Ptr", 0x8, "Ptr", 0)  ; LVM_SETEXTENDEDLISTVIEWSTYLE with LVS_EX_NOHSCROLL

    ; Disable horizontal scrollbar style
    WinSetStyle(-0x20000, listView.Hwnd)  ; Remove LVS_HSCROLL style (0x20000)

    ; Add event handlers for click and double-click
    listView.OnEvent("Click", ItemClick.Bind(level))
    listView.OnEvent("DoubleClick", ItemDoubleClick.Bind(level))

    ; Add items to the ListView (folders first)
    listItems := []

    ; Add folders
    for folder in folders {
        row := listView.Add("", "📁 " folder.name)
        listItems.Push({ row: row, data: folder })
    }

    ; Add files - hide all extensions
    for file in files {
        ; Split filename to remove extension
        SplitPath(file.name, , , , &nameNoExt)
        row := listView.Add("", "↗️ " nameNoExt)
        listItems.Push({ row: row, data: file })
    }

    ; Store items data with the ListView
    listView.itemData := listItems

    ; Calculate menu height using our helper function
    menuHeight := CalculateMenuHeight(numItems)

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
        if (winClass = "Shell_TrayWnd" || winClass = "NotifyIconOverflowWindow") {
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

        ; Check if clicked on tray area
        if (!clickedOnMenu) {
            try {
                WinGetClass(&winClass, "ahk_id " . winUnderMouse)
                if (winClass = "Shell_TrayWnd" || winClass = "NotifyIconOverflowWindow" ||
                    winClass = "TrayNotifyWnd" || winClass = "SysPager" || winClass = "ToolbarWindow32") {
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

Esc:: ; Esc to close all
{
    global isMenuVisible

    if (isMenuVisible) {
        CloseAllMenus()
    }

}

; End of script