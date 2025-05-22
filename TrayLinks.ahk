; AutoHotkey2 Folder Toolbar Script
; Creates a system tray icon with folder menus that open on the left side

#Requires AutoHotkey v2.0

; Configuration - Using environment variables
folderPath := EnvGet("onedrive") . "\Links"  ; Expanded path for internal use "%onedrive%\Links"

if (!DirExist(folderPath)) {
    MsgBox("Folder does not exist: " folderPath . "`nPlease check the path configuration.", "Error", "Icon!")
    ExitApp
}

; Set up the tray icon
try {
    TraySetIcon("Shell32.dll", 4)  ; Using folder icon
} catch {
    ; Fallback if that specific icon fails
}

; Set tooltip for the tray icon
A_IconTip := "Folder Links - Click for menu"

; Customize the tray menu (will show on right-click)
A_TrayMenu.Delete() ; Clear default menu
A_TrayMenu.Add("Open Links Folder", OpenRootFolder)
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
    for l in [3, 2, 1] {
        if (l >= level && currentGuis.Has(l) && IsObject(currentGuis[l])) {
            currentGuis[l].Destroy()
            currentGuis.Delete(l)
            currentPaths.Delete(l)
        }
    }
}

; Handle ListView item click - Just select the item
ItemClick(level, ctrl, *) {
    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0 || rowNum > ctrl.itemData.Length)
        return

    ; Get the selected item data
    item := ctrl.itemData[rowNum].data

    ; For folders, navigate as before
    if (item.type = "folder") {
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
        else if (level < 3) {  ; Limit to 3 levels
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

    ; Check if click was on any menu
    clickedOnMenu := false

    for level, gui in currentGuis {
        if (IsObject(gui) && hwnd = gui.Hwnd)
            clickedOnMenu := true
    }

    ; If clicked outside menus, close all
    if (!clickedOnMenu) {
        CloseAllMenus()
    }
}

; Register for mouse clicks
OnMessage(0x202, OnGlobalMouseClick)  ; WM_LBUTTONUP

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
