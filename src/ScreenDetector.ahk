; #Include ../lib/FindText.ahk
; #Include ../lib/GraphicSearch_export.ahk
#Include src/Graphic.ahk

class Area {
    __New(x1:=0, y1:=0, x2:=0, y2:=0){
        this.x1:=x1
        this.y1:=y1
        this.x2:=x2
        this.y2:=y2
    }
}

Class Error {
    static 0 := 0
    static 1 := 0.1
    static 2 := 0.2
    static 3 := 0.3
}

Class ScreenDetector {
    static FIXED_WIDTH := 1149
    static FIXED_HEIGHT := 712

    ; Flag to play with other engines to search, check detectGraphicByPoints for options 
    searchEngine := "FindText"      

    detect(isTest := false)
	{
        global
        ; Init
        t1:=A_TickCount
        this.fixGameScale(this.FIXED_WIDTH, this.FIXED_HEIGHT)
        gameArea := this.calculateGameArea(this.FIXED_WIDTH, this.FIXED_HEIGHT)

        if(isTest){
            this.saveScreenArea(gameArea, "screenshot_game.jpg")
        }        

        ; Screen detection
        screenWithDialog        := this.detectGraphic(Graphic.Screen_With_Dialog, gameArea, Error.2, Error.2)
        screenHome              := this.detectGraphic(Graphic.Screen_Home, gameArea)
        screenBattleStart       := this.detectGraphic(Graphic.Screen_BattleStart, gameArea)
        screenBattlePlay        := this.detectGraphic(Graphic.Screen_BattlePlay, gameArea)
        screenBattleResult      := this.detectGraphic(Graphic.Screen_BattleResult, gameArea, Error.3, Error.3)
        
        ; Battle screens
        if (!screenWithDialog && (screenBattleStart OR screenBattleResult)) {
            
            ; Campions area
            champsArea := gameArea.clone()
            tinyArea := new Area(gameArea.x1 + 15, gameArea.y1, gameArea.x1 + 20, gameArea.y2)
            if screenBattleStart {
                champsArea.x2           := champsArea.x1 + Round(this.FIXED_WIDTH / 2)
                separatorChampsStart    := this.detectGraphic(Graphic.Separator_BattleStart_ChampsStart, tinyArea, Error.0, Error.2)
            } else {
                separatorChampsStart    := this.detectGraphic(Graphic.Separator_BattleResult_ChampsStart, tinyArea)
            }
            if (separatorChampsStart){
                champsArea.y1 := separatorChampsStart[1].y
                tinyArea.y1 := separatorChampsStart[1].y
            }
            
            if screenBattleStart {
                separatorChampsEnd      := this.detectGraphic(Graphic.Separator_BattleStart_ChampsEnd, tinyArea, Error.0, Error.2)
            } else {
                separatorChampsEnd      := this.detectGraphic(Graphic.Separator_BattleResult_ChampsEnd, champsArea, Error.0, Error.2)
            }
            if (separatorChampsEnd)
                champsArea.y2 := separatorChampsEnd[1].y

            ; Leader area
            leaderAreaStart         := new Area(-1551, 707, -1445, 839)
            leaderAreaResultX4      := new Area(-1614, 780, -1496, 972)
            ; leaderAreaResultX5    := new Area()
            
            ; Last champ column area. We can contain one or two champs, we use that to detect campaign/arena
            lastChampAreaBattleStart := new Area(-1757, 641, -1659, 899)
            
            
            ; Champions rarity
            championsCornerGold   := this.detectGraphic(Graphic.ChampionCornerTopGold, champsArea, Error.2, Error.1)
            championsCornerPink   := this.detectGraphic(Graphic.ChampionCornerTopPink, champsArea)
            championsCornerBlue   := this.detectGraphic(Graphic.ChampionCornerTopBlue, champsArea, 0.19, Error.2)
            championsCornerGreen  := this.detectGraphic(Graphic.ChampionCornerTopGreen, champsArea, Error.1, Error.0)
            championsCornerGrey   := this.detectGraphic(Graphic.ChampionCornerTopGrey, champsArea, Error.0, Error.0)
            
            ; Campions count
            champsCountMaxLvl     := this.detectGraphic(Graphic.ChampionMaxLev, champsArea, Error.2, Error.2)
            champsCountTotal      := this.safeSum(championsCornerGold, championsCornerPink, championsCornerBlue, championsCornerGreen, championsCornerGrey)
            
            ; Champions rank
            rank66                := this.detectGraphic(Graphic.Rank66, champsArea, Error.2, Error.1)
            rank5                 := this.detectGraphic(Graphic.Rank5, champsArea, Error.3, Error.2)
            rank3                 := this.detectGraphic(Graphic.Rank3, champsArea, Error.2, Error.1)

            ; TODO: Remove - old playground
            championStarsInside   := this.detectGraphic(Graphic.ChampionStarFull, champsArea)
            championStarsFull     := this.detectGraphic(Graphic.ChampionStarHalf, champsArea)
            championStarsHalf     := this.detectGraphic(Graphic.ChampionStarInside, champsArea)

            if(isTest){
                this.saveScreenArea(champsArea, "screenshot_champs.jpg") 
            }
        }

        t1:=A_TickCount-t1

        
        
        if screenWithDialog {
            screenName := "Hidden by a dialog"
        }
        else if screenHome {
            screenName := "Home"
        }
        else if screenBattleStart {
            screenName := "Battle Start"
        }
        else if screenBattleResult {
            screenName := "Battle Result"
        }
        else if screenBattlePlay {
            screenName := "Playing Battle"
        }
        else {
            screenName := " NOT detected"
        }

        if (isTest){

            ; Build test dialog
            desc :=   "Screen:`t`t`t`t" (screenName)
                    . "`nTime:`t`t`t`t" (t1) " ms"

            if (!screenWithDialog && (screenBattleStart OR screenBattleResult)) {
                desc .= "`n`t" champsCountTotal " x champions:"
                if (championsCornerGold) 
                    desc .= "`n`t`t" championsCornerGold.MaxIndex() " x Legendary"
                if (championsCornerPink) 
                    desc .= "`n`t`t" championsCornerPink.MaxIndex() " x Epic" 
                if (championsCornerBlue) 
                    desc .= "`n`t`t" championsCornerBlue.MaxIndex() " x Rare" 
                if (championsCornerGreen) 
                    desc .= "`n`t`t" championsCornerGreen.MaxIndex() " x Uncommon" 
                if (championsCornerGrey) 
                    desc .= "`n`t`t" championsCornerGrey.MaxIndex() " x Common" 
            }
            
            desc .=   "`n`nScreens:"
                    . "`n  WithDialog:`t`t`t" (screenWithDialog ? screenWithDialog.MaxIndex() : "No")
                    . "`n  Home:`t`t`t`t" (screenHome ? screenHome.MaxIndex() : "No")
                    . "`n  Battle Start:`t`t`t" (screenBattleStart ? screenBattleStart.MaxIndex() : "No")
                    . "`n  Battle Play:`t`t`t" (screenBattlePlay ? screenBattlePlay.MaxIndex() : "No")
                    . "`n  Battle Result:`t`t`t" (screenBattleResult ? screenBattleResult.MaxIndex() : "No")

            if (!screenWithDialog && (screenBattleStart OR screenBattleResult)) {
                desc .=  "`n`nChampion area:"
                        . "`n  SeparatorChampsStart:`t`t" (separatorChampsStart ? separatorChampsStart.MaxIndex() : "No")
                        . "`n  SeparatorChampsEnd:`t`t" (separatorChampsEnd ? separatorChampsEnd.MaxIndex() : "No")
                        . "`n  Game Area:`t" (gameArea ?  gameArea.x1 "," gameArea.y1 "  " gameArea.x2 "," gameArea.y2 : "`t`tNo")
                        . "`n  Champs Area:`t" (champsArea ? champsArea.x1 "," champsArea.y1 "  " champsArea.x2 "," champsArea.y2 : "`t`tNo")
                        . "`n`nChampions:"
                        . "`n  Legendary champions:`t`t" (championsCornerGold ? championsCornerGold.MaxIndex() : "No")
                        . "`n  Epic chapions:`t`t`t" (championsCornerPink ? championsCornerPink.MaxIndex() : "No")
                        . "`n  Rare champions:`t`t`t" (championsCornerBlue ? championsCornerBlue.MaxIndex() : "No")
                        . "`n  Uncommon champions:`t`t" (championsCornerGreen ? championsCornerGreen.MaxIndex() : "No")
                        . "`n  Common champions:`t`t" (championsCornerGrey ? championsCornerGrey.MaxIndex() : "No")
                        . "`n`nOthers:"
                        . "`n  championStarsFull:`t`t" (championStarsFull ? championStarsFull.MaxIndex() : "No")
                        . "`n  championStarsHalf:`t`t" (championStarsHalf ? championStarsHalf.MaxIndex() : "No")
                        . "`n  championStarsInside:`t`t" (championStarsInside ? championStarsInside.MaxIndex() : "No")
                        . "`n  champsCountMaxLvl:`t`t" (champsCountMaxLvl ? champsCountMaxLvl.MaxIndex() : "No")
                        . "`n  rank66:`t`t`t`t" (rank66 ? rank66.MaxIndex() : "No")
                        . "`n  rank5:`t`t`t`t" (rank5 ? rank5.MaxIndex() : "No")
                        . "`n  rank3:`t`t`t`t" (rank3 ? rank3.MaxIndex() : "No")
                        . "`n`nScreenshots:"
                        . "`n  screenshot_game.jpg"
                        . "`n  screenshot_champs.jpg"
            }

            desc .= "`n`n Do you want to go to the screenshot folder?" 

            ; Show debug dialog
            local dialogOptions := 4096+4
            MsgBox, % dialogOptions, Detector test, % desc
            IfMsgbox, yes 
            {
                Run, explore %LocalFolder%
            }

            ; Show detection positions over the game
            ;this.printResults(championsCornerGold)
        }

        return screenName
    }

    fixGameScale(width, height) 
    {
        ; TODO: Why this dont print but following scale works?
        ;MsgBox, 4096, ASCII detector, % RaidWinTitle
        
        ; Reset screen size
        WinGetPos, X, Y, W, H, % RaidWinTitle
        if (W != width OR H != height){
            WinMove, %RaidWinTitle%,, X, Y, width, height
            ;MsgBox, Fixed scale, Game rescaled at %X%,%Y% to 1149x712, it was %W%x%H%.
        }

        ; TODO: IMPORTANT: Move windows into view
    }

    calculateGameArea(width, height) 
    {
        WinGetPos, X, Y, W, H, % RaidWinTitle
        gameArea := new Area(X, Y, X + width, Y + height)
        return gameArea
    }

    detectGraphic(graphic, area, e1:=0.1, e2:=0.1) 
    {
        return this.detectGraphicByPoints(graphic, area.x1, area.y1, area.x2, area.y2, e1, e2)
    }

    detectGraphicByPoints(graphic, x1, y1, x2, y2, e1:=0.1, e2:=0.1)
	{        
        if (this.searchEngine == "FindText"){
            ; Detection with FindText
            result:=FindText(x1, y1, x2, y2, e1, e2, graphic)
        }
        else if (this.searchEngine == "GraphicSearch"){
            ; Detection with GraphicSearch
            if (!this.oGraphicSearch)
                this.oGraphicSearch := new graphicsearch()
            result := this.oGraphicSearch.search(graphic, x1, y1, x2, y2, e1, e2)
        }
        else{
            MsgBox, % dialogOptions, "Develop warning", "Not a valid searchEngine", 
        }
        
        return result
    }

    safeSum(params*) 
    {
        total := 0
        for index,param in params
            if param
                total += param.MaxIndex()
        return total
    }

    printResults(result) 
    {
        for i,v in result
            FindText.MouseTip(result[i].x, result[i].y)
    }

    getCommentFromGraphic(graphic) 
    {
        RegExMatch(graphic, "(?<=<)(.*)(?=>)", comment)
        return comment
    }

    saveScreenArea(area, fileName) 
    {
        this.saveScreenPoints(area.x1, area.y1, area.x2, area.y2, fileName)
    }

    saveScreenPoints(x1, y1, x2, y2, fileName) 
    {
        global
        local localPath := LocalFolder . "\" . fileName
        local rect := x1 . ", " . y1  . ", " . x2 . ", " . y2
        CaptureScreen(rect, False, localPath, "")
        ;MsgBox, 4096, Screenshot saved, % "File: " fileName "`nPath: " localFolderPath "`nArea: " recta 
    }

    ; TODO: Remove, old GraphicSearch playground
    detect2()
	{
        global
        ;MsgBox, 4096, ASCII detector, %RaidWinTitle%
        t1:=A_TickCount

        ; Reset screen size
        WinGetPos, X, Y, W, H, % RaidWinTitle
        if (W!=1149 or H!=712){
            WinMove, %RaidWinTitle%,, X, Y, 1149, 712
            MsgBox, Game rescaled at %X%,%Y% to 1149x712, it was %W%x%H%.
            WinGetPos, X, Y, W, H, % RaidWinTitle
        }

        WinActivate, %RaidWinTitle%

        GraphicSearch_query1 := "|<BattleTextGray131>*131$81.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU7z7k0807Dy0Dw0Tkz01U0tzk1zbly7zXzlzDyTzwyDUTwTyDtznzzblwnzXzlzDyTzwwTaTwTyDtznzzU3slzXzlzDy0Tw0TDDwTyDtzk3zbltszXzlzDyTzwyC07wTyDtznzzbtk0zXzlzDyTzwyATXwTyDtznzzXVXwTXzlz7yDzw0QznwTyDs0k1zUDbyTbznz060DzzzzzzzzzzzzzzzzzzzzzzzzzzzU"
        GraphicSearch_query2 := "|<BattleTextColor100>0xDFDADA@0.81$76.Dw0M3ztzwM0zszs3kDzbzlU3zX1UD03U1k60A0A70w0C070M0k0kQ6M0s0Q1U3031UNU3U1k60A0Dw3b0C070M0zkzkAA0s0Q1U3z31kkk3U1k60A0A37zUC070M0k0kATy0s0Q1U3031lUM3U1k60A0A6A0kC070M0k0zsk30s0Q1znzU0000000000000000000000002"
        GraphicSearch_query3 := "|<BattleTextGray130b>*130$78.zzzzzzzzzzzzzzzzzzzzzzzzzzs1zlw0201nzU3s0zVy0301nzU3twTVzszwTnzbztwT0zszwTnzbztwTAzszwTnzbztszAzszwTnzbzs0yATszwTnzU7s0ySTszwTnzU7twSSDszwTnzbztwQ0DszwTnzbztyQ0DszwTnzbztwMz7szwTnzbzssMz7szwTlzXzs0tzbszwTk1U3s3tzbtzwzk1U3zzzzzzzzzzzzzzzzzzzzzzzzzzU"
        GraphicSearch_query4 := "|<BattleIconColor100>0xFFFDDF@1.00$33.00zs0001z0000Dy0001zk0001y0000Dk0DC0Tt1zk3zs1z0Tw0Dy1zU1zkDw07s0zU1z03w0AM0EM1X063000000A0k00NU6003k0000600000U"
        GraphicSearch_query5 := "|<BattleIconColor80>0xFFFDDF@0.81$42.00Dzk00007zs00003zs00001zy000EEzz300ssTz7U1xwDzzU0zy7zz00Tz3zy00DzVzw007zUzs007z0Ts00Dy0Tw00Ty0Ty00yT0yT01wDVwDU3w7Vs7k7s30k3s7k0001w7U0000s300000E0000000U"
        GraphicSearch_query6 := "|<TitleDsGray175>*157$13.zzzTzjzrz33BjinrSNji6Dzz"
        GraphicSearch_query7 := "|<ResultArrowTopRightSide>0x9C9052@0.68$15.00400k0700s03U0S01s07U0Q03k4D0kw73UwS3lsD71sQTXzSDlsw7U0Ts1z004"
        ASCII_Screen_Home:="|<>0xFFFDDF@0.45$43.0000000000000030000001w00001szk0007wDy000Dy7zU00Dz3zs00Dz1zy00DzUTzU0DzkDzs0Dzk7zy0Dzs1zzUDzs0TzsDzs07zwDzs01zz7zs00Tznzw007zwzw001zzDw000Tznw0007zww0001zz80000Tzk00007zw00081zz1U0C6Tzls0Djbzxy07ztzzz03zyTzz00zzbzz00Dztzz003zwTz000zw7zU00zw1zs00zy1zy00zzVzzU0zDsz7s0z3wT3y0z0w70zUz0A10DkD00003k300000k000000000000008"

        ;n:=150000
        ;resultObj1 := graphicsearch.search(-n, -n, n, n, 0, 0, GraphicSearch_query1)

        myX := X
        myY := Y
        myW := X + 1149
        myH := Y + 712
        E1 := 0.2
        E2 := 0.2

        oGraphicSearch := new graphicsearch()
        collection := GraphicSearch_query1 GraphicSearch_query2 GraphicSearch_query3
        resultObj1 := oGraphicSearch.search(collection, myX, myY, myW, myH, E1, E2)
        if (resultObj1) {
            MsgBox, 4096, Tip, % "Found BattleTextGray131"
            ;X := resultObj1.1.x, Y := resultObj1.1.y, Comment := resultObj1.1.id
            ; Click, %X%, %Y%
        }

        resultObj2 := oGraphicSearch.search(GraphicSearch_query2, myX, myY, myW, myH, E1, E2)
        if (resultObj2) {
            MsgBox, 4096, Tip, % "Found BattleTextColor100"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }

        resultObj3 := oGraphicSearch.search(GraphicSearch_query3, myX, myY, myW, myH, E1, E2)
        if (resultObj3) {
            MsgBox, 4096, Tip, % "Found BattleTextGray130b"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }

        resultObj4 := oGraphicSearch.search(GraphicSearch_query4, myX, myY, myW, myH, E1, E2)
        if (resultObj4) {
            MsgBox, 4096, Tip, % "Found BattleIconColor100"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }

        resultObj5 := oGraphicSearch.search(GraphicSearch_query5, myX, myY, myW, myH, E1, E2)
        if (resultObj5) {
            MsgBox, 4096, Tip, % "Found BattleIconColor80"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }
        
        resultObj6 := oGraphicSearch.search(GraphicSearch_query6, myX, myY, myW, myH, E1, E2)
        if (resultObj6) {
            MsgBox, 4096, Tip, % "Found TitleDsGray175"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }

        resultObj7 := oGraphicSearch.search(GraphicSearch_query7, myX, myY, myW, myH, E1, E2)
        if (resultObj6) {
            MsgBox, 4096, Tip, % "Found ResultArrowTopRightSide"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }

        resultTotal := resultObj1.MaxIndex() + resultObj2.MaxIndex() + resultObj3.MaxIndex() + resultObja.MaxIndex() + resultObj4.MaxIndex() + resultObj5.MaxIndex() + resultObj6.MaxIndex()
        MsgBox, 4096, Tip, % "Found :`t`t`t" Round(resultTotal)
            . "`nTime  :`t`t`t" (A_TickCount-t1) " ms"
            . "`n`n`BattleTextGray131: `t" (resultObj1 ? resultObj1.MaxIndex() " !" : "Failed")
            . "`n`BattleTextColor100:`t" (resultObj2 ? resultObj2.MaxIndex() " !" : "Failed")
            . "`n`BattleTextGray130b:`t" (resultObj3 ? resultObj3.MaxIndex() " !" : "Failed")
            . "`n`BattleIconColor100:`t" (resultObj4 ? resultObj4.MaxIndex() " !" : "Failed")
            . "`n`BattleIconColor80:`t`t" (resultObj5 ? resultObj5.MaxIndex() " !" : "Failed")
            . "`n`TitleDsGray175:`t`t" (resultObj6 ? resultObj6.MaxIndex() " !" : "Failed")
            . "`n`ResultArrowTopRightSide:`t" (resultObj7 ? resultObj7.MaxIndex() " !" : "Failed")
            . "`n`nPosition rect:`t`t" myX "," myY " " myW "," myH
            . "`nPosition vector:`t`t" X "," Y " " W ","H

        for i,v in resultObj1
            if (i<=5)
                oGraphicSearch.mouseTip(resultObj1[i].x, resultObj1[i].y)
        for i,v in resultObj2
            if (i<=5)
                oGraphicSearch.mouseTip(resultObj2[i].x, resultObj2[i].y)
        for i,v in resultObj3
            if (i<=5)
                oGraphicSearch.mouseTip(resultObj3[i].x, resultObj3[i].y)
    }
}


