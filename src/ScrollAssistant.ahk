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

;TODO: remove all global keywords
Class ScrollAssistant {

    ICON_NAMES := ["TOP", " UP", "DWN", "END"]

    testScroll(isTest := false, currentPage := 0) {
        global
        ; Detect screens playground

        local isGameOpen := this.checkGameOpened()
        if (!isGameOpen){
            return
        }

        ;WinActivate, %Constants.RaidWinTitle%
        ;screenDetector := new GraphicDetector()

        ; GDIP ImageDetector dont requiere WinActivate!
        screenDetector := new ImageDetector()
        return screenDetector.detectScroll(isTest, currentPage)
    }

    isRunning() {
        return this.isScrollRunning
    }

    isShowing() {
        return this.isScrollShowing
    }

    start() {
        ; local isGameOpen := this.checkGameOpened()
        ; if (!isGameOpen){
        ;     return
        ; }

        if (this.isScrollRunning) {
            this.stop()
        }
        else if (this.isScrollShowing) {
            this.hide()
        }

        this.isScrollRunning := true
        this.isScrollShowing := false
        this.screenDetector := new ImageDetector()
        this.initView()

        fn := ObjBindMethod(this, "whileStarted")
        SetTimer, %fn%, -0

        return
    }

    stop() {
        this.isScrollRunning := false
        if (this.isScrollShowing) {
            this.hide()
        }
        SelectObject(this.hdc, this.obm)
        DeleteObject(this.hbm)
        DeleteDC(this.hdc)
        Gdip_DeleteGraphics(this.pGraphics)
    }

    whileStarted() {
        If not this.isScrollRunning
            return

        screen := this.screenDetector.detectChampionsScreen()
        if (screen == ""){
            if (this.isScrollShowing) {
                this.hide()
            }
        }else{
            if (not this.isScrollShowing) {
                this.show()
            }
        }
        fn := ObjBindMethod(this, "whileStarted")
        SetTimer, %fn%, -1000
    }

    show() {
        this.isScrollShowing := true
        this.updateView()
        registerMouseListeners()
    }

    hide() {
        this.isScrollShowing := false
        unregisterMouseListeners()
        Gdip_GraphicsClear(this.pGraphics)
        UpdateLayeredWindow(this.overlayHwnd, this.hdc, this.layerX, this.layerY, this.layerW, this.layerH)
    }

        

    initView(){
        iconFileNames := ["outline_vertical_align_top_black_24dp.png"
                        , "outline_vertical_align_bottom_black_24dp.png"]

        this.iconN := this.ICON_NAMES.MaxIndex()    ; icon number
        this.iconW := 50                            ; icon width in pixels
        this.iconH := (this.iconW*3)//4             ; icon height in pixels
        this.iconPositions:={}                      ; global array with the positions of icons

        Gui, 1: -Caption +E0x80000 +LastFound +OwnDialogs +Owner +hwndhwnd +alwaysontop
        Gui, 1: Show, NA
        this.overlayHwnd := hwnd
        
        ; Get game pos and size
        WinGetPos, winX, winY, winW, winH, % Constants.RaidWinTitle
        SysGet, winTitleBarH, 43 ; The height of a button in a window's caption or title bar, in pixels.

        ; Disable Resize
        ;toggleWinResizable(Constants.RaidWinTitle) 

        ; Calculate layer pos and size
        this.layerW := this.iconW
        this.layerX := winX + ((winW-this.layerW)//4) + 2
        this.layerY := winY + (20 * winH)//100
        this.layerH := winH - (32 * winH)//100

        ; Create layer
        this.hbm := Gdip_CreateDIBSection(this.layerW,this.layerH)
        this.hdc := CreateCompatibleDC()
        this.obm := SelectObject(this.hdc, this.hbm)
        this.pGraphics := Gdip_GraphicsFromHDC(this.hdc)
        Gdip_SetSmoothingMode(this.pGraphics,4)
        Gdip_SetInterpolationMode(this.pGraphics,7)
        Gdip_GraphicsClear(this.pGraphics) ;, 0xfffff59d) 

        ; Positioning the layer and showing it (empty)
        UpdateLayeredWindow(this.overlayHwnd, this.hdc, this.layerX, this.layerY, this.layerW, this.layerH)

        ; Prepare tme for mouse moves
        VarSetCapacity(this.tme, 16, 0)
        NumPut(16, this.tme, 0)
        NumPut(2, this.tme, 4)
        NumPut(this.overlayHwnd, this.tme, 8)
    }

    updateView(){
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
        ; Update the layer
        UpdateLayeredWindow(this.overlayHwnd, this.hdc, this.layerX, this.layerY, this.layerW, this.layerH)
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
        }
    }

    onIconClicked( position ) {
        iconPressed := this.ICON_NAMES[position]

        WinActivate, % Constants.RaidWinTitle
        WinWaitActive, % Constants.RaidWinTitle
        WinGet, winID, ID, % Constants.RaidWinTitle
        WinGetPos, winX, winY, winW, winH, % Constants.RaidWinTitle

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
    OnMessage(0x0200, "onMouseMove")
    OnMessage(0x0201, "onLeftButtonDown")
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
    OnMessage(0x0200, "onMouseMove", 0)
    OnMessage(0x0201, "onLeftButtonDown", 0)
}