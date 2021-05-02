;
;   Copyright 2021 Rafael Acosta Alvarez
;    
;   Licensed under the Apache License, Version 2.0 (the "License");
;   you may not use this file except in compliance with the License.
;   You may obtain a copy of the License at
;    
;        http://www.apache.org/licenses/LICENSE-2.0
;    
;   Unless required by applicable law or agreed to in writing, software
;   distributed under the License is distributed on an "AS IS" BASIS,
;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;   See the License for the specific language governing permissions and
;   limitations under the License.

#Include lib\GDIpHelper.ahk
#Include src/ImageDetector.ahk

;TODO: remove all global keywords
Class ScrollAssistant {

    winTitle := "Raid: Shadow Legends"
    LocalFolder := A_AppData . "/" . "UnlimitedMultiBattles"
    ICON_NAMES := ["TOP", " UP", "DWN", "END"]

    testScroll(isTest := false, currentPage := 0) {
        global
        ; Detect screens playground

        local isGameOpen := this.checkGameOpened()
        if (!isGameOpen){
            return
        }

        ;WinActivate, %RaidWinTitle%
        ;screenDetector := new GraphicDetector()

        ; GDIP ImageDetector dont requiere WinActivate!
        screenDetector := new ImageDetector()
        return screenDetector.detectScroll(isTest, currentPage)
    }

    start() {
        If !this.pToken := Gdip_Startup()
        {
            MsgBox, w, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
            ExitApp
        }

        this.loadView()

        ; Prepare tme for mouse moves
        VarSetCapacity(this.tme, 16, 0)
        NumPut(16, this.tme, 0)
        NumPut(2, this.tme, 4)
        NumPut(this.overlayHwnd, this.tme, 8)

        registerMouseListeners()
    }

    pause() {
        Gdip_GraphicsClear(this.pGraphics)
        UpdateLayeredWindow(this.overlayHwnd, this.hdc, 0, 0, this.layerW, this.layerH)
    }

    stop() {
        this.pause()

        unregisterMouseListeners()

        SelectObject(this.hdc, this.obm)
        DeleteObject(this.hbm)
        DeleteDC(this.hdc)
        Gdip_DeleteGraphics(this.pGraphics)
        Gdip_Shutdown(this.pToken)
    }
        

    loadView(){
        iconFileNames := ["outline_vertical_align_top_black_24dp.png"
                        , "outline_vertical_align_bottom_black_24dp.png"]

        this.iconN := this.ICON_NAMES.MaxIndex()          ; icons number
        this.iconW := 50                            ; icons width in pixels
        this.iconH := (this.iconW*3)//4             ; icons height in pixels
        this.iconPositions:={}                      ; global array with the positions of icons

        Gui, 1: -Caption +E0x80000 +LastFound +OwnDialogs +Owner +hwndhwnd +alwaysontop
        Gui, 1: Show, NA
        this.overlayHwnd := hwnd
        
        ; Get game pos and size
        WinGetPos, winX, winY, winW, winH, % this.winTitle
        SysGet, winTitleBarH, 43 ; The height of a button in a window's caption or title bar, in pixels.

        ; Disable Resize
        ;toggleWinResizable(this.winTitle) 

        ; Calculate layer pos and size
        this.layerW := this.iconW ;iconN*iconW+(iconN+1)*10
        this.layerX := winX + ((winW-this.layerW)//4) + 2 ;(a_screenwidth-layerW)//2
        this.layerY := winY + (20 * winH)//100 ; 2 * winTitleBarH +  ;(a_screenheight-layerH)//2
        this.layerH := winH - (32 * winH)//100 ; + winH + layerY ;iconW

        ; Create layer
        this.hbm := Gdip_CreateDIBSection(this.layerW,this.layerH)
        this.hdc := CreateCompatibleDC()
        this.obm := SelectObject(this.hdc, this.hbm)
        this.pGraphics := Gdip_GraphicsFromHDC(this.hdc)
        Gdip_SetSmoothingMode(this.pGraphics,4)
        Gdip_SetInterpolationMode(this.pGraphics,7)
        Gdip_GraphicsClear(this.pGraphics) ;, 0xfffff59d) 
        
        ; Add icons to layer
        loop % this.iconN
        {
            ; Draw icon background image
            iconBackX := 0
            iconBackY := (A_Index - 1) * (this.layerH - this.iconH)/(this.iconN - 1)
            sFile := A_ScriptDir . "\images\overlay\" . "icon_bookmark.png"
            pBitmap:=Gdip_CreateBitmapFromFile(sFile)
            Gdip_DrawImage(this.pGraphics, pBitmap, iconBackX, iconBackY, this.iconW, this.iconH)
            Gdip_DisposeImage(pBitmap)

            ; Draw icon text
            iconTextText := this.ICON_NAMES[A_Index]
            iconFontH := 16
            iconFontBackColor := "ff37474f"
            iconFontColor := "ff00b0ff"
            iconTextX :=  iconBackX
            iconTextY :=  iconBackY + (this.iconH/2) - (iconFontH/2)
            iconTextOptions := "x" . iconTextX . " y" . iconTextY . "c" . iconFontColor . " s" . iconFontH 
                    . " r4 Left Bold"
            Gdip_TextToGraphics(this.pGraphics, iconTextText, iconTextOptions)

            ; Store each icon position in parent, to detect the clicked item
            this.iconPositions[A_Index] := iconBackY  
        }

        ; Positioning the layer
        UpdateLayeredWindow(hwnd, this.hdc, this.layerX, this.layerY, this.layerW, this.layerH)
    }

    handleMouseLeave(wParam, lParam, Msg, hwnd) {
        tooltip 
    }

    handleMouseMove(wParam, lParam, Msg, hwnd) {
        DllCall( "TrackMouseEvent", "uint", &this.tme )
        this.xg := lParam & 0xFFFF
        this.yg := lParam >> 16
    }

    handleLeftButtonDown(wParam, lParam, Msg, hwnd) {     
        if (hwnd != this.overlayHwnd){
            return
        }

        message := "wParam: " . wParam . "`nlParam: " . lParam . "`nMsg: " . Msg . "`nhwnd: " . hwnd
        MsgBox,, %title%, % message 
        ; Detect icon clicked
        loop % this.iconN
        {
            if (this.yg > this.iconPositions[A_Index] 
                and this.yg < this.iconPositions[A_Index] + this.iconH)
            {
                button:=A_Index
                break
            }
            else
                button:=""
        }

        if (button) {
            this.onIconClicked(button)
            ; Temp patch: OnMessage(0x2A3,"OnMouseLeave") is not working
            fn := ObjBindMethod(scrollAssistant, "handleMouseLeave", wParam, lParam, Msg, hwnd)
            SetTimer, %fn%, -2000
        }
    }

    onIconClicked( position ) {
        iconPressed := this.ICON_NAMES[position]

        WinActivate, % this.winTitle
        WinWaitActive, % this.winTitle
        WinGet, winID, ID, % this.winTitle
        WinGetPos, winX, winY, winW, winH, % this.winTitle

        scrollX := winX + (this.layerX - winX)//2
        scrollY := this.layerY + this.yg ; + 50
        CoordMode, Mouse, Screen
        MouseMove, scrollX, scrollY
        
        gameArea := new ImageArea(winX, winY, winX + winW, winY + winH)
        scrollArea := gameArea.sliceRight(24).sliceLeft(98).sliceTop(82).sliceBottom(89)
        screenDetector := new ImageDetector()

        pageLenth := 11
        pageNumber := (iconPressed == "TOP" OR iconPressed == "END") ? 30 : 1
        scrollCount := pageLenth * pageNumber
        Loop %scrollCount% {
            
            ; Cancel scrolling if out of scroll area
            MouseGetPos, mouseX, mouseY
            if (!scrollArea.contains(mouseX, mouseY)){
                break
            }

            isNewPage := Mod(A_Index, pageLenth) == 0
            
            if (iconPressed == "TOP" OR iconPressed == " UP") {
                ; TODO:
                ; Research if MouseClick with less aceleration
                ; Or using new coords intead of initials! :)
        
                ;MouseClick, WheelUp, scrollX, scrollY
                Click, WheelUp
            }
            else if (iconPressed == "DWN" OR iconPressed == "END") {
                ;MouseClick, WheelDown, scrollX, scrollY
                Click, WheelDown
            }
            
            if (!isNewPage){
                Sleep, 5
                Continue
            }

            ; Cancel scrolling if screen end detected (WIP)
            if (screenDetector.detectScroll(false, A_Index) == "End") {
                break
            }
        }
    }
}


; TODO: global mouse event listeners
registerMouseListeners(){
    ; Register window listeners (not all working)
    OnMessage(0x02A3, "onMouseLeave")
    OnMessage(0x0200, "onMouseMove")
    OnMessage(0x0201, "onLeftButtonDown")
}
onMouseLeave(wParam, lParam, Msg, hwnd ) {
    fn := ObjBindMethod(scrollAssistant, "handleMouseLeave", wParam, lParam, Msg, hwnd)
    SetTimer, %fn%, 1
}
onMouseMove(wParam, lParam, Msg, hwnd ) {
    fn := ObjBindMethod(scrollAssistant, "handleMouseMove", wParam, lParam, Msg, hwnd)
    SetTimer, %fn%, 1
}
onLeftButtonDown(wParam, lParam, msg, hwnd){
    fn := ObjBindMethod(scrollAssistant, "handleLeftButtonDown", wParam, lParam, Msg, hwnd)
    SetTimer, %fn%, -10
}
unregisterMouseListeners(){
    OnMessage(0x02A3, "onMouseLeave", 0)
    OnMessage(0x0200, "onMouseMove", 0)
    OnMessage(0x0201, "onLeftButtonDown", 0)
}