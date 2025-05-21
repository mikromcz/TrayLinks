; AutoHotkey2 Folder Toolbar Script
; Creates a system tray icon with folder menus

#Requires AutoHotkey v2.0

; Configuration - Using your specified path
folderPath := "C:\Users\uy044\OneDrive - Cummins\Links"

; Set up the tray icon
try {
    TraySetIcon("Shell32.dll", 4)  ; Using folder icon
} catch {
    ; Fallback if that specific icon fails
}

; Set tooltip for the tray icon
A_IconTip := "Cummins Links - Click for menu"

; Customize the tray menu (will show on right-click)
A_TrayMenu.Delete() ; Clear default menu
A_TrayMenu.Add("Open Links Folder", OpenRootFolder)
A_TrayMenu.Add("Exit", (*) => ExitApp())
A_TrayMenu.Default := "Open Links Folder"

; Global variables - must be accessible to all functions
global menuGui := 0
global submenuGuis := Map()  ; Map to store multiple submenu GUIs
global currentHoverPath := ""
global initialMouseX := 0
global initialMouseY := 0
global isMenuVisible := false

; Dark mode colors
global darkColors := {
    background: "202020",
    text: "FFFFFF",
    border: "404040",
    selected: "0078D7"
}

; Calculate dynamic height for a ListView based on item count
CalculateMenuHeight(itemCount, titleHeight := 30)
{
    ; Fixed height per item
    itemHeight := 22

    ; Ensure at least one item row
    if (itemCount < 1)
        itemCount := 1

    ; Basic calculation: title area + (items * height per item)
    baseHeight := titleHeight + (itemCount * itemHeight)

    ; Add small padding (5px) to ensure all items are visible
    height := baseHeight + 5

    ; Constrain within reasonable min/max values
    return Max(100, Min(600, height))
}

; Check if a path is in the parent hierarchy of another path
IsPathInHierarchy(parentPath, childPath)
{
    ; Ensure both paths end with backslash for proper comparison
    if (SubStr(parentPath, -1) != "\")
        parentPath .= "\"
    if (SubStr(childPath, -1) != "\")
        childPath .= "\"

    ; Check if childPath starts with parentPath (is inside the parent folder)
    return InStr(childPath, parentPath) == 1
}

; Get all parent paths for a given path
GetPathHierarchy(path)
{
    hierarchy := [path]
    currentPath := path

    ; Keep getting parent folders until we reach the root
    Loop {
        SplitPath(currentPath, , &parentPath)

        ; Stop when we can't get a parent anymore or at root folder
        if (parentPath = "" || parentPath = folderPath)
            break

        ; Add parent to hierarchy and continue up
        hierarchy.Push(parentPath)
        currentPath := parentPath
    }

    ; Add root folder
    hierarchy.Push(folderPath)

    return hierarchy
}

; Close all submenus but keep main menu
CloseAllSubmenus()
{
    global submenuGuis, currentHoverPath

    ; Close all submenus
    for path, gui in submenuGuis {
        if (IsObject(gui)) {
            gui.Destroy()
        }
    }

    ; Clear the Map
    submenuGuis := Map()
    currentHoverPath := ""
}

; Close submenus that are not in the path hierarchy
CloseUnrelatedSubmenus(currentPath)
{
    global submenuGuis

    ; Get the hierarchy of the current path
    hierarchy := GetPathHierarchy(currentPath)

    ; Go through all open submenus
    for path, gui in submenuGuis.Clone() {
        ; Check if this submenu's path is not in the hierarchy and not a parent of the current path
        isRelated := false
        for _, hierarchyPath in hierarchy {
            if (path = hierarchyPath || IsPathInHierarchy(path, currentPath)) {
                isRelated := true
                break
            }
        }

        ; If not related, close it
        if (!isRelated) {
            CloseSubmenu(path)
        }
    }
}

; Create a submenu GUI
CreateSubmenuGui(path)
{
    global darkColors

    ; Create the submenu GUI
    submenu := Gui("-Caption +ToolWindow +AlwaysOnTop")
    submenu.BackColor := darkColors.background
    submenu.SetFont("s10 c" darkColors.text, "Segoe UI")

    return submenu
}

; Function to handle opening the folder
OpenRootFolder(*)
{
    if DirExist(folderPath)
        Run(folderPath)
    else
        MsgBox("Folder does not exist: " folderPath, "Error", "Icon!")
}

; Function to handle single clicks in the ListView
HandleSingleClick(ctrl, *)
{
    global submenuGuis, currentHoverPath

    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0)
        return

    ; Highlight the row (for visual feedback)
    ctrl.Modify(rowNum, "Select Focus")

    ; Get the selected item data
    if (rowNum > ctrl.itemData.Length)
        return

    item := ctrl.itemData[rowNum].data

    ; Close all submenus when clicking on a non-folder item
    if (item.type != "folder") {
        CloseAllSubmenus()
        currentHoverPath := ""
    }
}

; Function to handle double clicks in the ListView
HandleDoubleClick(ctrl, *)
{
    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0)
        return

    ; Get the item data
    if (rowNum > ctrl.itemData.Length)
        return

    item := ctrl.itemData[rowNum].data

    if (item.type = "folder") {
        ; No action for folders on double-click, handled by hover
    } else {
        ; Open file
        try {
            Run(item.path)
            CloseAllMenus()
        } catch as e {
            MsgBox("Error opening file: " e.Message, "Error", "Icon!")
        }
    }
}

; Function to handle submenu clicks
SubmenuClick(ctrl, *)
{
    global submenuGuis, currentHoverPath

    ; Get selected row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0 || rowNum > ctrl.itemData.Length)
        return

    ; Get the item data
    item := ctrl.itemData[rowNum].data

    if (item.type = "folder") {
        ; No immediate action needed for folders (handled by hover)
    } else {
        ; Close all menus and open file when clicking on a file
        try {
            Run(item.path)
            CloseAllMenus()
        } catch as e {
            MsgBox("Error opening file: " e.Message, "Error", "Icon!")
        }
    }

    ; Close all submenus if clicking on a non-folder item
    if (item.type != "folder") {
        CloseAllSubmenus()
        currentHoverPath := ""
    }
}

; Close specific submenu
CloseSubmenu(path)
{
    global submenuGuis

    if (submenuGuis.Has(path) && IsObject(submenuGuis[path])) {
        submenuGuis[path].Destroy()
        submenuGuis.Delete(path)
    }
}

; Close all menus
CloseAllMenus()
{
    global menuGui, submenuGuis, isMenuVisible

    ; Close all submenus
    for path, gui in submenuGuis {
        if (IsObject(gui)) {
            gui.Destroy()
        }
    }

    ; Clear the Map
    submenuGuis := Map()

    if (IsObject(menuGui)) {
        menuGui.Destroy()
        menuGui := 0
    }

    isMenuVisible := false
}

; Handle global mouse clicks to close menus
OnGlobalMouseClick(wParam, lParam, msg, hwnd)
{
    global menuGui, submenuGuis, isMenuVisible

    ; Only process if menus are visible
    if (!isMenuVisible)
        return

    ; Check if click was on a menu
    clickedOnMenu := false

    ; Check main menu
    if (IsObject(menuGui)) {
        if (hwnd = menuGui.Hwnd)
            clickedOnMenu := true
    }

    ; Check submenus
    for path, gui in submenuGuis {
        if (IsObject(gui) && hwnd = gui.Hwnd)
            clickedOnMenu := true
    }

    ; If clicked outside menus, close all
    if (!clickedOnMenu) {
        CloseAllMenus()
    }
}

; Function to show subfolder contents on hover
ShowSubFolder(ctrl, *)
{
    global menuGui, submenuGuis, currentHoverPath, darkColors

    ; Get the focused row
    rowNum := ctrl.GetNext(0)
    if (rowNum = 0 || rowNum > ctrl.itemData.Length) {
        return
    }

    ; Get the selected item data
    item := ctrl.itemData[rowNum].data

    ; Only proceed if it's a folder
    if (item.type != "folder") {
        return
    }

    ; If we're already showing this folder, don't redraw
    if (currentHoverPath = item.path)
        return

    ; Remember this folder
    currentHoverPath := item.path

    ; Close submenus for this path and its children
    for path, gui in submenuGuis.Clone() {
        if (path = item.path || InStr(path, item.path . "\")) {
            CloseSubmenu(path)
        }
    }

    ; Close submenus that are not related to the current path
    CloseUnrelatedSubmenus(item.path)

    ; Check if the folder has any contents
    folderHasContent := false
    try {
        Loop Files, item.path "\*.*"
        {
            if (A_LoopFileName != "desktop.ini") {
                folderHasContent := true
                break
            }
        }
    }

    ; If folder is empty, don't show submenu
    if (!folderHasContent)
        return

    ; Create the submenu using our helper function
    subGui := CreateSubmenuGui(item.path)

    ; Store the GUI in our map
    submenuGuis[item.path] := subGui

    ; Get folder name for title
    SplitPath(item.path, &folderName)

    ; Add title
    subGui.Add("Text", "x10 y10 w180", "Contents of: " folderName)

    ; Add a separator line
    subGui.Add("Text", "x10 y30 w180 h1 c" darkColors.border " 0x10")

    ; Arrays for folders and files
    subfolders := []
    subfiles := []

    ; First scan for subdirectories
    try {
        Loop Files, item.path "\*", "D"  ; Only directories
        {
            ; Skip desktop.ini
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue

            subfolders.Push({name: A_LoopFileName, path: A_LoopFileFullPath, type: "folder"})
        }
    }

    ; Then scan for files
    try {
        Loop Files, item.path "\*", "F"  ; Only files
        {
            ; Skip desktop.ini
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue

            subfiles.Push({name: A_LoopFileName, path: A_LoopFileFullPath, type: "file"})
        }
    }

    ; Calculate the number of items for listview sizing
    numItems := subfolders.Length + subfiles.Length

    ; Ensure at least 1 item height to avoid empty listview
    if (numItems < 1)
        numItems := 1

    ; Create submenu ListView with proper styles
    subListView := subGui.Add("ListView", "x10 y40 w180 r" numItems " -Multi -Hdr Background" darkColors.background " c" darkColors.text, ["Name"])

    ; Force no horizontal scrollbar using direct Windows API
    DllCall("SendMessage", "Ptr", subListView.Hwnd, "UInt", 0x1033, "Ptr", 0x8, "Ptr", 0)  ; LVM_SETEXTENDEDLISTVIEWSTYLE with LVS_EX_NOHSCROLL

    ; Also set LVS_NOSCROLL style directly on the ListView
    WinSetStyle(-0x20000, subListView.Hwnd)  ; Remove LVS_HSCROLL style (0x20000)

    ; Use click for files in submenu
    subListView.OnEvent("Click", SubmenuClick)

    ; Add items to the submenu ListView
    subListItems := []

    ; Add subfolders first
    for subfolder in subfolders {
        row := subListView.Add("", "📁 " subfolder.name)
        subListItems.Push({row: row, data: subfolder})
    }

    ; Add files - hide all extensions
    for subfile in subfiles {
        ; Split filename to remove extension
        SplitPath(subfile.name, , , , &nameNoExt)
        row := subListView.Add("", "↗️ " nameNoExt)
        subListItems.Push({row: row, data: subfile})
    }

    ; Store items data with the ListView
    subListView.itemData := subListItems

    ; Add hover event for folder items
    subListView.OnEvent("ItemFocus", ShowSubFolder)

    ; Calculate menu height using our helper function
    submenuHeight := CalculateMenuHeight(numItems)

    ; Position submenu
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)

    ; If this is from the main menu, position to the right of it
    if (IsObject(menuGui)) {
        WinGetPos(&mainX, &mainY, &mainW, &mainH, "ahk_id " menuGui.Hwnd)

        ; Position submenu to the right of main menu
        subX := mainX + mainW + 5
        subY := mouseY - 40  ; Position approximately at mouse height
    } else {
        ; Find parent menu if this is from another submenu
        parentFound := false
        SplitPath(item.path, , &parentDir)

        if (submenuGuis.Has(parentDir) && IsObject(submenuGuis[parentDir])) {
            WinGetPos(&parentX, &parentY, &parentW, &parentH, "ahk_id " submenuGuis[parentDir].Hwnd)
            subX := parentX + parentW + 5
            subY := mouseY - 40
            parentFound := true
        }

        ; If no parent found, position based on mouse
        if (!parentFound) {
            subX := mouseX + 20
            subY := mouseY - 40
        }
    }

    ; Make sure we don't go off screen
    winWidth := 200  ; Fixed width at 200px

    if (subY + submenuHeight > A_ScreenHeight)
        subY := A_ScreenHeight - submenuHeight - 20

    if (subY < 10)
        subY := 10

    if (subX + winWidth > A_ScreenWidth) {
        ; If no room on right, show on left of the source menu
        if (IsObject(menuGui)) {
            subX := mainX - winWidth - 5
        } else if (parentFound) {
            subX := parentX - winWidth - 5
        } else {
            subX := mouseX - winWidth - 20
        }

        ; If still no room, position at left edge
        if (subX < 10)
            subX := 10
    }

    ; Show the submenu with the dynamic height
    subGui.Show("x" subX " y" subY " w" winWidth " h" submenuHeight " NoActivate")
}

; Function to show folder contents (main menu)
ShowFolderContents()
{
    global menuGui, initialMouseX, initialMouseY, darkColors, isMenuVisible, folderPath

    ; If menu is already visible, close it and exit
    if (isMenuVisible) {
        CloseAllMenus()
        return
    }

    ; Store initial mouse position for submenu positioning
    CoordMode("Mouse", "Screen")
    MouseGetPos(&initialMouseX, &initialMouseY)

    ; Close existing GUIs
    CloseAllMenus()

    ; Create new GUI
    menuGui := Gui("-Caption +ToolWindow +AlwaysOnTop")
    menuGui.BackColor := darkColors.background
    menuGui.SetFont("s10 c" darkColors.text, "Segoe UI")

    ; Add title
    menuGui.Add("Text", "x10 y10 w180", "Folder: Links")

    ; Add a horizontal line
    menuGui.Add("Text", "x10 y30 w180 h1 c" darkColors.border " 0x10")

    ; Data structures
    folders := []
    files := []

    ; Scan for directories first
    try {
        Loop Files, folderPath "\*", "D"  ; Only directories
        {
            ; Skip desktop.ini and hidden directories
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue

            ; Add to folders array
            folders.Push({name: A_LoopFileName, path: A_LoopFileFullPath, type: "folder"})
        }
    } catch as e {
        ; Handle error silently
    }

    ; Then scan for files
    try {
        Loop Files, folderPath "\*", "F"  ; Only files
        {
            ; Skip desktop.ini and hidden files
            if (A_LoopFileName = "desktop.ini" || SubStr(A_LoopFileName, 1, 1) = ".")
                continue

            ; Add to files array
            files.Push({name: A_LoopFileName, path: A_LoopFileFullPath, type: "file"})
        }
    } catch as e {
        ; Handle error silently
    }

    ; Calculate the number of items for listview sizing
    numItems := folders.Length + files.Length
    ; Ensure at least 1 item height to avoid empty listview
    if (numItems < 1)
        numItems := 1

    ; Create main ListView - use dynamic row count based on items
    listView := menuGui.Add("ListView", "x10 y40 w180 r" numItems " -Multi -Hdr Background" darkColors.background " c" darkColors.text, ["Name"])

    ; Force no horizontal scrollbar using direct Windows API
    DllCall("SendMessage", "Ptr", listView.Hwnd, "UInt", 0x1033, "Ptr", 0x8, "Ptr", 0)  ; LVM_SETEXTENDEDLISTVIEWSTYLE with LVS_EX_NOHSCROLL

    ; Also set LVS_NOSCROLL style directly on the ListView
    WinSetStyle(-0x20000, listView.Hwnd)  ; Remove LVS_HSCROLL style (0x20000)

    listView.OnEvent("DoubleClick", HandleDoubleClick)
    listView.OnEvent("Click", HandleSingleClick)

    ; Add items to the ListView (folders first)
    listItems := []

    ; Add folders
    for folder in folders {
        row := listView.Add("", "📁 " folder.name)
        listItems.Push({row: row, data: folder})
    }

    ; Add files - hide all extensions
    for file in files {
        ; Split filename to remove extension
        SplitPath(file.name, , , , &nameNoExt)
        row := listView.Add("", "↗️ " nameNoExt)
        listItems.Push({row: row, data: file})
    }

    ; Store items data with the ListView
    listView.itemData := listItems

    ; Add event for mouse hover
    listView.OnEvent("ItemFocus", ShowSubFolder)

    ; Calculate menu height using our helper function
    menuHeight := CalculateMenuHeight(numItems)

    ; Position window relative to initial mouse position
    winWidth := 200  ; Fixed width at 200px

    ; Make sure we don't go off screen
    newX := initialMouseX
    newY := initialMouseY - 40  ; Position a bit above the cursor

    if (newY + menuHeight > A_ScreenHeight)
        newY := A_ScreenHeight - menuHeight - 20

    if (newX + winWidth > A_ScreenWidth)
        newX := A_ScreenWidth - winWidth - 20

    if (newY < 10)
        newY := 10

    ; Show the GUI with the dynamic height
    menuGui.Show("x" newX " y" newY " w" winWidth " h" menuHeight " NoActivate")

    ; Set menu as visible
    isMenuVisible := true
}

; Use OnMessage to detect when mouse clicks on tray icon
OnMessage(0x404, TrayIconClick)  ; WM_USER + 4 (0x400 + 4)

; Handle global mouse clicks
OnMessage(0x202, OnGlobalMouseClick)  ; WM_LBUTTONUP

; Handle tray icon click
TrayIconClick(wParam, lParam, *)
{
    if (lParam = 0x201)  ; WM_LBUTTONDOWN
    {
        ShowFolderContents()
    }
    else if (lParam = 0x203)  ; WM_LBUTTONDBLCLK
    {
        OpenRootFolder()
    }
}

; Define a hotkey to force show the menu
#f::  ; Win+F hotkey
{
    ShowFolderContents()
}

; End of script