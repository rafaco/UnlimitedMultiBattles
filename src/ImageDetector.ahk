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

#Include lib/Gdip_ImageSearch.ahk
#Include src/Image.ahk

class ImageArea {
    __New(x1:=0, y1:=0, x2:=0, y2:=0){
        this.x1:=x1
        this.y1:=y1
        this.x2:=x2
        this.y2:=y2
    }

    printSize(title:="ImageArea") {
        message := "Width: " . this.x2 - this.x1 . "`nHeight: " . this.y2 - this.y1
        MsgBox,, %title%, % message 
    }

    contains(x, y){
        return x>=this.x1 AND x<=this.x2 AND y>=this.y1 AND y<=this.y2
    }

    sliceBottom(percentage:=0) {
        if (percentage <= 0){
            return this
        }
        result := new ImageArea(this.x1, this.y1, this.x2, this.y2)
        result.y2 := result.y2 - ((result.y2 - result.y1)*(100 - percentage)//100)
        return result
    }

    sliceTop(percentage:=0) {
        if (percentage <= 0){
            return this
        }
        result := new ImageArea(this.x1, this.y1, this.x2, this.y2)
        result.y1 := result.y1 + ((result.y2 - result.y1)*(100 - percentage)//100)
        return result
    }

    sliceLeft(percentage:=0) {
        if (percentage <= 0){
            return this
        }
        result := new ImageArea(this.x1, this.y1, this.x2, this.y2)
        result.x1 := result.x1 + ((result.x2 - result.x1)*(100 - percentage)//100)
        return result
    }

    sliceRight(percentage:=0) {
        if (percentage <= 0){
            return this
        }
        result := new ImageArea(this.x1, this.y1, this.x2, this.y2)
        result.x2 := result.x2 - ((result.x2 - result.x1)*(100 - percentage)//100)
        return result
    }
}

Class Error {
    static 0 := 0
    static 1 := 0.1
    static 2 := 0.2
    static 3 := 0.3
}

Class ImageDetector {
    static FIXED_WIDTH := 1149
    static FIXED_HEIGHT := 712  

    detectScreen(isTest := false)
	{
        global
        ; Init
        t1:=A_TickCount
        this.fixGameScale(this.FIXED_WIDTH, this.FIXED_HEIGHT)
        this.gdipTarget := WinExist("Raid: Shadow Legends")
        
        gameArea := new ImageArea(0, 0, this.FIXED_WIDTH, this.FIXED_HEIGHT)

        ; Screen detection
        ;screenWithDialog        := this.detectGraphic(Graphic.Screen_With_Dialog, gameArea, Error.2, Error.2)
        screenHome              := this.detectImage(Image.Screen_Home, gameArea.sliceTop(80))
        screenChamps            := this.detectImage(Image.Screen_Champs, gameArea.sliceBottom(80), 10, 0xFFFFFF)
        screenChampVault        := this.detectImage(Image.Screen_ChampVault, gameArea.sliceBottom(80))
        
        screenBattleStart       := this.detectImage(Image.Screen_BattleStart, gameArea.sliceBottom(60))
        screenBattlePlay        := this.detectImage(Image.Screen_BattlePlay, gameArea.sliceTop(60), 80)
        screenBattleLoading     := this.detectImage(Image.Screen_BattleLoading, gameArea.sliceTop(80))
        screenBattleResult      := this.detectImage(Image.Screen_BattleResult, gameArea.sliceBottom(80))
        screenBattleResultVictory := this.detectImage(Image.Screen_BattleResultVictory, gameArea.sliceBottom(80), 10)
        screenBattleResultDefeat  := this.detectImage(Image.Screen_BattleResultDefeat, gameArea.sliceBottom(80))
        
        if (screenWithDialog>0) {
            screenName := "Hidden by a dialog"
        }
        else if (screenHome>0) {
            screenName := "Home"
        }
        else if (screenChamps>0) {
            screenName := "Champions"
        }
        else if (screenChampVault>0) {
            screenName := "Champion Vault"
        }
        else if (screenBattleStart>0) {
            screenName := "Battle Start"
        }
        else if (screenBattleLoading>0) {
            screenName := "Loading Battle"
        }
        else if (screenBattlePlay>0) {
            screenName := "Playing Battle"
        }
        else if (screenBattleResult>0) {
            screenName := "Battle Result"
        }
        else {
            screenName := "NOT detected"
        }
        
        t1:=A_TickCount-t1

        if (isTest){

            ; Build test dialog
            desc :=   "Screen:`t`t`t`t" (screenName)
                    . "`nTime:`t`t`t`t" (t1) " ms"

            if (screenBattleResult) {
                if (screenBattleResultVictory) {
                    desc .= "`n`tVICTORY"
                }
                else if (screenBattleResultVictory) {
                    desc .= "`n`tDEFEAT"
                }
            }
            desc .=   "`n`nScreens:"
                    ;. "`n  WithDialog:`t`t`t" (screenWithDialog ? screenWithDialog : "No")
                    . "`n  Home:`t`t`t`t" (screenHome>0 ? screenHome : "No")
                    . "`n  Champions:`t`t`t" (screenChamps>0 ? screenChamps : "No")
                    . "`n  Champion Vault:`t`t`t" (screenChampVault>0 ? screenChampVault : "No")
                    . "`n  Battle Start:`t`t`t" (screenBattleStart>0 ? screenBattleStart : "No")
                    . "`n  Battle Play:`t`t`t" (screenBattlePlay>0 ? screenBattlePlay : "No")
                    . "`n  Battle Result:`t`t`t" (screenBattleResult>0 ? screenBattleResult : "No")
                    . "`n  Battle Result Victory:`t`t" (screenBattleResultVictory>0 ? screenBattleResultVictory : "No")
                    . "`n  Battle Result Defeat:`t`t" (screenBattleResultDefeat>0 ? screenBattleResultDefeat : "No")

            desc .= "`n`n Do you want to go to the screenshot folder?" 

            ; Show debug dialog
            local dialogOptions := 4096+4
            MsgBox, % dialogOptions, Detector test, % desc
            IfMsgbox, yes 
            {
                local targetUrl := Constants.LocalFolder()
                Run, explore %targetUrl%
            }

            ; Show detection positions over the game
            this.printResults(championsCornerBlue)
        }

        Gdip_DisposeImage(this.bmpHaystack)
        this.bmpHaystack := 0
        return screenName
    }

    detectChampionsScreen()
	{
        global
        this.fixGameScale(this.FIXED_WIDTH, this.FIXED_HEIGHT)
        this.gdipTarget := WinExist("Raid: Shadow Legends")
        
        gameArea := new ImageArea(0, 0, this.FIXED_WIDTH, this.FIXED_HEIGHT)
        topArea := gameArea.sliceBottom(80)

        ; Screen detection
        screenChamps            := this.detectImage(Image.Screen_Champs, topArea, 10, 0xFFFFFF)
        screenChampVault        := this.detectImage(Image.Screen_ChampVault, topArea)

        this.saveBitmapArea(bmpHaystack, topArea, "Champions_screen.jpg") 
        
        if (screenChampVault>0) {
            screenName := "Champions with Vault"
        }
        else if (screenChamps>0) {
            screenName := "Champions"
        }
        else {
            screenName := ""
        }

        Gdip_DisposeImage(this.bmpHaystack)
        this.bmpHaystack := 0
        return screenName
    }

    detectScroll(isTest := false, currentPage := 0)
	{
        global
        ; Init
        t1:=A_TickCount
        this.fixGameScale(this.FIXED_WIDTH, this.FIXED_HEIGHT)
        this.gdipTarget := WinExist("Raid: Shadow Legends")
        
        gameArea := new ImageArea(0, 0, this.FIXED_WIDTH, this.FIXED_HEIGHT)
        scrollArea := gameArea.sliceRight(24).sliceLeft(98).sliceTop(82).sliceBottom(89)
        
        scrollEnds              := this.detectImage(Image.Scroll_Champs_Empty, scrollArea, 15)
        
        isPageBorder := Mod(currentPage, 100) == 0
        if (isPageBorder){
            this.saveBitmapArea(this.bmpHaystack, scrollArea, "scrollArea_" . currentPage . ".jpg")
        }

        if (scrollEnds>0) {
            scrollStatus := "End"
        }
        else if (screenHome>0) {
            scrollStatus := "Middle"
        }
        
        t1:=A_TickCount-t1

        if (isTest){

            ; Build test dialog
            desc :=   "Scroll:`t`t`t`t" (scrollStatus)
                    . "`nTime:`t`t`t`t" (t1) " ms"

            desc .=   "`n`Scroll:"
                    . "`n  scrollEnds:`t`t`t`t" (scrollEnds>0 ? scrollEnds : "No")
            desc .= "`n`n Do you want to go to the screenshot folder?" 

            ; Show debug dialog
            local dialogOptions := 4096+4
            MsgBox, % dialogOptions, Detector test, % desc
            IfMsgbox, yes 
            {
                local targetUrl := Constants.LocalFolder()
                Run, explore %targetUrl%
            }

            ; Show detection positions over the game
            ;this.printResults(championsCornerBlue)
        }
        Gdip_DisposeImage(this.bmpHaystack)
        this.bmpHaystack := 0
        
        return scrollStatus
    }



    detectImage(image, area, e:=0, trans:=0) 
    {
        return this.detectImageByPoints(image, area.x1, area.y1, area.x2, area.y2, e, trans)
    }

    detectImageByPoints(image, x1, y1, x2, y2, e:=0, trans:=0)
	{
        if (!this.bmpHaystack){
            this.bmpHaystack := Gdip_BitmapFromHWND(this.gdipTarget)
        }
        bmpNeedle := Gdip_CreateBitmapFromFile(image)
        resultList := ""
        resultCount := Gdip_ImageSearch(this.bmpHaystack,bmpNeedle,resultList,x1, y1, x2, y2,e,trans,1,10)
        Gdip_DisposeImage(bmpNeedle)

        if (resultCount < 0) {
            if (resultCount == -1001){
                errorMessage := "invalid haystack and/or needle bitmap pointer"
            }else if (resultCount == -1002){
                errorMessage := "invalid variation value"
            }else if (resultCount == -1003){
                errorMessage := "X1 and Y1 cannot be negative"
            }else if (resultCount == -1004){
                errorMessage := "unable to lock haystack bitmap bits"
            }else if (resultCount == -1005){
                errorMessage := "unable to lock needle bitmap bits"
            }
            MsgBox, "Gdip_ImageSearch error: " . %errorMessage%
        }
        
        return resultCount
    }

    fixGameScale(width, height) 
    {
        ; TODO: Why this dont print but following scale works?
        ;MsgBox, 4096, ASCII detector, % RaidWinTitle
        
        ; Reset screen size
        WinGetPos, X, Y, W, H, % Constants.RaidWinTitle
        if (W != width OR H != height){
            WinMove, Constants.RaidWinTitle,, X, Y, width, height
            ;MsgBox, Fixed scale, Game rescaled at %X%,%Y% to 1149x712, it was %W%x%H%.
        }

        ; TODO: IMPORTANT: Move windows into view
    }

    calculateGameArea(width, height) 
    {
        WinGetPos, X, Y, W, H, % Constants.RaidWinTitle
        gameArea := new ImageArea(X, Y, X + width, Y + height)
        return gameArea
    }

    saveBitmapArea(bitmap, area, fileName) 
    {
        localPath := Constants.LocalFolder() . Constants.FolderSeparator . fileName
        bitmap2 := this.Gdip_CropImage(bitmap, area.x1, area.y1, area.x2-area.x1, area.y2-area.y1)
        Gdip_SaveBitmapToFile(bitmap2, localPath)
    }

    Gdip_CropImage(pBitmap, x, y, w, h)
    {
        pBitmap2 := Gdip_CreateBitmap(w, h), G2 := Gdip_GraphicsFromImage(pBitmap2)
        Gdip_DrawImage(G2, pBitmap, 0, 0, w, h, x, y, w, h)
        Gdip_DeleteGraphics(G2)
        return pBitmap2
    }

}


