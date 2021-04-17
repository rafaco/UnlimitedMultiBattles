; #Include ../lib/FindText.ahk
; #Include ../lib/GraphicSearch_export.ahk


Class ScreenDetector {

    ASCII_Screen_Home:="|<ASCII_Screen_Home>0xFFFDDF@0.45$43.0000000000000030000001w00001szk0007wDy000Dy7zU00Dz3zs00Dz1zy00DzUTzU0DzkDzs0Dzk7zy0Dzs1zzUDzs0TzsDzs07zwDzs01zz7zs00Tznzw007zwzw001zzDw000Tznw0007zww0001zz80000Tzk00007zw00081zz1U0C6Tzls0Djbzxy07ztzzz03zyTzz00zzbzz00Dztzz003zwTz000zw7zU00zw1zs00zy1zy00zzVzzU0zDsz7s0z3wT3y0z0w70zUz0A10DkD00003k300000k000000000000008"
    ASCII_Screen_BattleStart:="|<BattleStart_affinitySymbol>*57$14.zwzzDznzszwDyHwAyTDjnvxyzTjwvwCyDi7v7z7zXzlzszwTzU"
    ASCII_Screen_BattleResult:="|<ResultArrowArea110Gray>*110$23.0AM00ss01Us068k0Msk0XtU27lU4TlUFzl17rlaT7nMw7XXk7XDbDUSCDVlzD7VwTSVlDsV6DlUST7lwMTrw1zzwTzzzU"
    ASCII_Screen_With_Dialog:="|<DialogLeftCorner_ColorGold>0xBCA63B@0.69$25.0000Ts000A0003U000s000C00zXXzzssTzyD3zzVkQ00S0003wzzzzk"
    ASCII_Separator_BattleStart_ChampsStart:="|<BattleStartChampsEnd4x5_gray71>*71$4.zkzs"
    ASCII_Separator_BattleStart_ChampsEnd:="|<BattleStartChampsEnd4x5_gray71>*71$4.zkzs"
    ASCII_Separator_BattleResult_ChampsStart:="|<ResultSeparatorThick_Color63>0xE5CC5F@0.63$6.000zz000U"
    ASCII_Separator_BattleResult_ChampsEnd:="|<ResultSeparatorBottom_Color63>0x18CE52@0.63$15.000000s0700s070DzVzwDzU700s0700s000004"
    ASCII_ChampionCornerTopGold:="|<ChampionCornerTopGold_Color63>0xF5DE07@0.63$10.000007wTlU6wPlg6m"
    ASCII_ChampionCornerTopPink:="|<ChampionCornerTopPink_Color63>0xFE78FF@0.63$7.0Dru1SgKE"
    ASCII_ChampionCornerTopBlue:="|<ChampionCornerTopBlue_Color>0x5EB1F1@0.69$9.000DtUBtjB1cB4"
    ASCII_ChampionCornerTopGreen:="|<ChampionCornerTopGreen2_Color69>0x00D14F@0.69$8.00007lwT71m"
    ASCII_ChampionCornerTopGrey:="|<ChampionCornerTopGrey_Color80>0xAEAEAE@0.81$7.003twkMAE"

    ASCII_ChampionMaxLev:="|<ChampionMaxLev_Color69>0x60C8D4@0.69$65.00000000000M3000030000s7000060001kS0000A0003kwS4M0M1tX7XtyBk0k7v6D7mAT01UQPAPBXwQ030zqkqnDss061zhVbaNls0A30D3CBnbk0M30Q6QNzQn0zbss8EVwlY1z7UU0000000000000000000004"

    ASCII_ChampionStarFull:="|<ChampionStarFull_Color100>0xE241C7@0.72$15.0E0200s0701w4TUzztzw7z0Tk3y0Ts770kMU"
    ASCII_ChampionStarHalf:="|<ChampionStarHalf_Gray115>*115$8.zrwzDlwT00473kw7lzTvzs"
    ASCII_ChampionStarInside:="|<ChampionStarInside_Color97>0xDEB223@0.92$10.0040E1V7XwDUy2I02"
    ASCII_Rank66:="|<Rank66>0xDD39C5@0.69$64.000000000000U00000E20020M30M30800Q1UA1UC1k01kC1sD0s70070w7Uw7Uy00uT3tT/tTs1zjwzbyzrzz1zDtzDxzjzk3yTtzDtzDy07wTXyTnyTk0TvzTvzDtz01zjxzjxzby0CAtr6sr6ss0k60k21M/1U20E20E20000000000000000000000000U"
    ASCII_Rank5:="|<Rank5>**70$54.0Q30000000Q3US3kC00q6kK2kG00a6Em6EH01W4EW4MnU3XwTXwzVwzDtz7tzVzUC0k60k03s30M3UQ06A1UA1kC0Q60k60s70k20k60E20E60k60E24M4QXaQnqSQ5rawrqSvA7Ug5Vy7Vg60sC0s70wU"
    ASCII_Rank3:="|<Rank3_GrayDiff90>**90$35.0000001k70s03kC1k06Uq6k09VA8U0l68lU12MTV1yTny3y0k600D0M301n0M30630M30Q60k60k8FWAEUFmCFl1iprau3kz3sQ60M3U8000001"
    
    detect()
	{
        global

        local w := 1149
        local h := 712
        this.fixGameScale(w, h)

        ; Calculate game area
        WinGetPos, X, Y, W, H, % RaidWinTitle
        local x1 := X
        local y1 := Y
        local x2 := X + w
        local y2 := Y + h
        local e1 := 0.1
        local e2 := 0.1
        t1:=A_TickCount
        this.saveScreenArea(x1, y1, x2, y2, LocalFolder, "screen_game.jpg")
        
        ; Screen detection
        local screenWithDialog      := this.detectArea(x1, y1, x2, y2, e1, e2, this.ASCII_Screen_With_Dialog)
        local screenHome            := this.detectArea(x1, y1, x2, y2, e1, e2, this.ASCII_Screen_Home)
        local screenBattleStart     := this.detectArea(x1, y1, x2, y2, e1, e2, this.ASCII_Screen_BattleStart)
        local screenBattleResult    := this.detectArea(x1, y1, x2, y2, e1, e2, this.ASCII_Screen_BattleResult)
        
        ; Battle screens
        if (!screenWithDialog && (screenBattleStart OR screenBattleResult)) {
            
            ; Campions area
            local champX1 := x1
            local champY1 := y1
            local champX2 := x2
            local champY2 := y2
            if screenBattleStart {
                champX2 := x1 + (w / 2)
                local separatorChampsStart  := this.detectArea(x1+15, y1, x1+20, y2, 0, 0.2, this.ASCII_Separator_BattleStart_ChampsStart)
            } else {
                local separatorChampsStart  := this.detectArea(x1+15, y1, x1+20, y2, e1, e2, this.ASCII_Separator_BattleResult_ChampsStart)
            }
            if (separatorChampsStart)
                champsY1 := separatorChampsStart[1].y

            if screenBattleStart {
                local separatorChampsEnd    := this.detectArea(x1+15, champsY1, x1+20, y2, 0, 0.2, this.ASCII_Separator_BattleStart_ChampsEnd)
            } else {
                local separatorChampsEnd    := this.detectArea(x1, champsY1, x2, y2, 0, 0.2, this.ASCII_Separator_BattleResult_ChampsEnd)
            }
            if (separatorChampsEnd)
                champsY2 := separatorChampsEnd[1].y

            
            ; Champions rarity
            local championsCornerGold   := this.detectArea(champX1, champsY1, champX2, champsY2, 0.2, e2, this.ASCII_ChampionCornerTopGold)
            local championsCornerPink   := this.detectArea(champX1, champsY1, champX2, champsY2, e1, e2, this.ASCII_ChampionCornerTopPink)
            local championsCornerBlue   := this.detectArea(champX1, champsY1, champX2, champsY2, 0.2, 0.1, this.ASCII_ChampionCornerTopBlue)
            local championsCornerGreen  := this.detectArea(champX1, champsY1, champX2, champsY2, e1, 0, this.ASCII_ChampionCornerTopGreen)
            local championsCornerGrey   := this.detectArea(champX1, champsY1, champX2, champsY2, 0, 0, this.ASCII_ChampionCornerTopGrey)
            
            ; Campions count
            local champsCountMaxLvl     := this.detectArea(champX1, champsY1, champX2, champsY2, 0.2, e2, this.ASCII_ChampionMaxLev)
            local champsCountTotal      := this.safeSum(championsCornerGold, championsCornerPink, championsCornerBlue, championsCornerGreen, championsCornerGrey)
            
            ; Champions rank
            local rank66                := this.detectArea(champX1, champsY1, champX2, champsY2, 0.3, e1, this.ASCII_Rank66)
            local rank5                 := this.detectArea(champX1, champsY1, champX2, champsY2, 0.3, 0.2, this.ASCII_Rank5)
            local rank3                 := this.detectArea(champX1, champsY1, champX2, champsY2, 0.2, e1, this.ASCII_Rank3)

            ; TODO: Remove - old playground
            local championStarsFull     := this.detectArea(champX1, champsY1, champX2, champsY2, e1, e2, this.ASCII_ChampionStarFull)
            local championStarsHalf     := this.detectArea(champX1, champsY1, champX2, champsY2, e1, e2, this.ASCII_ChampionStarHalf)
            local championStarsInside   := this.detectArea(champX1, champsY1, champX2, champsY2, e1, e2, this.ASCII_ChampionStarInside)

            this.saveScreenArea(champX1, champsY1, champX2, champsY2, LocalFolder, "screenshot_champs.jpg") 
        }
        
        this.saveScreenArea(x1, y1, x2, y2, LocalFolder, "screenshot_screen.jpg") 
        t1:=A_TickCount-t1

        local desc := "Screen "
        if screenWithDialog {
            desc .= "Unknown, a Dialog on top"
        }
        else if screenHome {
            desc .= "Home"
        }
        else if screenBattleStart {
            desc .= "Battle Start"
        }
        else if screenBattleResult {
            desc .= "Battle Result"
        }
        
        if (!screenWithDialog && (screenBattleStart OR screenBattleResult)) {
            desc .= "`n  " champsCountTotal " x champions:"
            if (championsCornerGold) 
                desc .= "`n`t" championsCornerGold.MaxIndex() " x Legendary"
            if (championsCornerPink) 
                desc .= "`n`t" championsCornerPink.MaxIndex() " x Epic" 
            if (championsCornerBlue) 
                desc .= "`n`t" championsCornerBlue.MaxIndex() " x Rare" 
            if (championsCornerGreen) 
                desc .= "`n`t" championsCornerGreen.MaxIndex() " x Uncommon" 
            if (championsCornerGrey) 
                desc .= "`n`t" championsCornerGrey.MaxIndex() " x Common" 
        }

        MsgBox, 4096, Area detection, % desc
            
            . "`n`n`nTime:`t`t`t`t" (t1) " ms"
            
            . "`n`nScreens:"
            . "`n  WithDialog:`t`t`t" (screenWithDialog ? "Yes, " screenWithDialog.MaxIndex() "!" : "No")
            . "`n  Home:`t`t`t`t" (screenHome ? "Yes, " screenHome.MaxIndex() "!" : "No")
            . "`n  Battle Start:`t`t`t" (screenBattleStart ? "Yes, " screenBattleStart.MaxIndex() "!" : "No")
            . "`n  Battle Result:`t`t`t" (screenBattleResult ? "Yes, " screenBattleResult.MaxIndex() "!" : "No")
            
            . "`n`nChampion area:"
            . "`n  SeparatorChampsStart:`t`t" (separatorChampsStart ? "Yes, " separatorChampsStart.MaxIndex() "!" : "No")
            . "`n  SeparatorChampsEnd:`t`t" (separatorChampsEnd ? "Yes, " separatorChampsEnd.MaxIndex() "!" : "No")
            . "`n  Full Area:`t`t" x1 "," y1 " " x2 "," y2
            . "`n  Champ Area:`t`t" x1 "," champsY1 " " x2 "," champsY2
            
            . "`n`nChampions:"
            . "`n  Legendary champions:`t`t" (championsCornerGold ? "Yes, " championsCornerGold.MaxIndex() "!" : "No")
            . "`n  Epic chapions:`t`t`t" (championsCornerPink ? "Yes, " championsCornerPink.MaxIndex() "!" : "No")
            . "`n  Rare champions:`t`t`t" (championsCornerBlue ? "Yes, " championsCornerBlue.MaxIndex() "!" : "No")
            . "`n  Uncommon champions:`t`t" (championsCornerGreen ? "Yes, " championsCornerGreen.MaxIndex() "!" : "No")
            . "`n  Common champions:`t`t" (championsCornerGrey ? "Yes, " championsCornerGrey.MaxIndex() "!" : "No")
            
            . "`n`nOthers:"
            . "`n  championStarsFull:`t`t" (championStarsFull ? "Yes, " championStarsFull.MaxIndex() "!" : "No")
            . "`n  championStarsHalf:`t`t" (championStarsHalf ? "Yes, " championStarsHalf.MaxIndex() "!" : "No")
            . "`n  championStarsInside:`t`t" (championStarsInside ? "Yes, " championStarsInside.MaxIndex() "!" : "No")
            . "`n  champsCountMaxLvl:`t`t" (champsCountMaxLvl ? "Yes, " champsCountMaxLvl.MaxIndex() "!" : "No")
            . "`n  rank66:`t`t`t`t" (rank66 ? "Yes, " rank66.MaxIndex() "!" : "No")
            . "`n  rank5:`t`t`t`t" (rank5 ? "Yes, " rank5.MaxIndex() "!" : "No")
            . "`n  rank3:`t`t`t`t" (rank3 ? "Yes, " rank3.MaxIndex() "!" : "No")            

        this.printResults(championsCornerGrey)

        ;this.detect2()
    } 

    safeSum(params*) {
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

    fixGameScale(fixedW, fixedH) 
    {
        ; TODO: Why this dont print but following scale works?
        ;MsgBox, 4096, ASCII detector, % RaidWinTitle
        
        ; Reset screen size
        WinGetPos, X, Y, W, H, % RaidWinTitle
        if (W!=fixedW or H!=fixedH){
            WinMove, %RaidWinTitle%,, X, Y, fixedW, fixedH
            ;MsgBox, Fixed scale, Game rescaled at %X%,%Y% to 1149x712, it was %W%x%H%.
        }
    }

    saveScreenArea(x1, y1, x2, y2, localFolder, fileName) 
    {
        localPath := localFolder . "\" . fileName
        recta := x1 . ", " . y1  . ", " . x2 . ", " . y2
        CaptureScreen(recta, False, localPath, "")
        ;MsgBox, 4096, Screenshot saved, % "File: " fileName "`nPath: " localFolderPath "`nArea: " recta 
    }
    
    detectArea(x1, y1, x2, y2, e1, e2, graphic)
	{
        ; t1:=A_TickCount
        if (ok1:=FindText(x1, y1, x2, y2, e1, e2, graphic))
        {
            CoordMode, Mouse
            ;X:=ok.1.x, Y:=ok.1.y, Comment:=ok.1.id
            ; Click, %X%, %Y%
        }
        ; t1:=A_TickCount-t1

        ; RegExMatch(graphic, "(?<=<)(.*)(?=>)", name)
        ; MsgBox, 4096, Area detection, % "Found:`t`t`t" Round(ok1.MaxIndex())
        ;     . "`n" name ":`t`t" (ok1 ? ok1.MaxIndex() : "Failed !")
        ;     . "`n`nTime:`t`t`t" (t1) " ms"
        ;     . "`nArea:`t`t" x1 "," y1 " " x2 "," y2

        ; for i,v in ok
        ; if (i<=5)
        ;     FindText.MouseTip(ok[i].x, ok[i].y)
        return ok1
    }

    ; From https://www.autohotkey.com/boards/viewtopic.php?t=67417
    FindTextAW(text,err1:=0,err0:=0)
    ; FindText only within the active window.  Much faster if you have a large
    ; desktop or are searching for multiple images.
    ; Input parameters x,y,w,h are not needed in this version and err1 and err0
    ; are optional parameters in case they are needed.
    ; This outputs the same array of x,y,w,h,Comment that the main function returns.
    ; Ben Sacherich - 7/17/2019
    {
        t1:=A_TickCount

        WinGetPos, X, Y, W, H, A  ; "A" to get the active window's position.
        
        ;SoundBeep 423, 100	; Uncomment for debugging.
        
        ; Get the coordinates for the center of the window and pass that to the regular FindText function.
        ; This is needed for FindText versions prior to 6.0
        ;W:=W//2
        ;X+=W
        ;H:=H//2
        ;Y+=H
        ;MsgBox, Searching at %X%`, %Y%, %W%`, %H%

        ;if (ok:=FindText(X, Y, W, H, 0, 0, Text,1,0)) ; Take new Screenshot, Find First
        if (ok:=FindText(X, Y, W, H, 0, 0, Text,1,1)) ; Take new Screenshot, Find All
        {
        CoordMode, Mouse
        X:=ok.1.1, Y:=ok.1.2, W:=ok.1.3, H:=ok.1.4, Comment:=ok.1.5, X+=W//2, Y+=H//2
        }
        t1:=A_TickCount-t1

        ; Show a MouseTip on the first two matches. Uncomment for debugging.
        ;for i,v in ok
        ;  if i<=2
        ;    {
        ;    MouseTip(v.1+v.3//2, v.2+v.4//2)
        ;    Comment.=v.5 ", "
        ;    }

        ;if ok	; Uncomment for debugging.
        ;    MsgBox, 4096, % "FindTextAW", % "Time:`t" (t1) " ms`n`n"
        ;        . "Pos:`t" X ", " Y "`n`n"
        ;        . "Found:`t" ok.MaxIndex() "`n`n"
        ;        . "Result:`t" (ok ? "Success!`n`n" Comment : "Failed!"),5
        return, ok.MaxIndex() ? ok:0
    }

    detect2()
	{
        global
        t1:=A_TickCount

        ; Reset screen size
        WinGetPos, X, Y, W, H, % RaidWinTitle
        if (W!=1149 or H!=712){
            WinMove, %RaidWinTitle%,, X, Y, 1149, 712
            MsgBox, Game rescaled at %X%,%Y% to 1149x712, it was %W%x%H%.
            WinGetPos, X, Y, W, H, % RaidWinTitle
        }

        MsgBox, 4096, ASCII detector, %RaidWinTitle%
        

        GraphicSearch_query1 := "|<BattleTextGray131>*131$81.zzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzzU7z7k0807Dy0Dw0Tkz01U0tzk1zbly7zXzlzDyTzwyDUTwTyDtznzzblwnzXzlzDyTzwwTaTwTyDtznzzU3slzXzlzDy0Tw0TDDwTyDtzk3zbltszXzlzDyTzwyC07wTyDtznzzbtk0zXzlzDyTzwyATXwTyDtznzzXVXwTXzlz7yDzw0QznwTyDs0k1zUDbyTbznz060DzzzzzzzzzzzzzzzzzzzzzzzzzzzU"
        GraphicSearch_query2 := "|<BattleTextColor100>0xDFDADA@0.81$76.Dw0M3ztzwM0zszs3kDzbzlU3zX1UD03U1k60A0A70w0C070M0k0kQ6M0s0Q1U3031UNU3U1k60A0Dw3b0C070M0zkzkAA0s0Q1U3z31kkk3U1k60A0A37zUC070M0k0kATy0s0Q1U3031lUM3U1k60A0A6A0kC070M0k0zsk30s0Q1znzU0000000000000000000000002"
        GraphicSearch_query3 := "|<BattleTextGray130b>*130$78.zzzzzzzzzzzzzzzzzzzzzzzzzzs1zlw0201nzU3s0zVy0301nzU3twTVzszwTnzbztwT0zszwTnzbztwTAzszwTnzbztszAzszwTnzbzs0yATszwTnzU7s0ySTszwTnzU7twSSDszwTnzbztwQ0DszwTnzbztyQ0DszwTnzbztwMz7szwTnzbzssMz7szwTlzXzs0tzbszwTk1U3s3tzbtzwzk1U3zzzzzzzzzzzzzzzzzzzzzzzzzzU"
        GraphicSearch_query4 := "|<BattleIconColor100>0xFFFDDF@1.00$33.00zs0001z0000Dy0001zk0001y0000Dk0DC0Tt1zk3zs1z0Tw0Dy1zU1zkDw07s0zU1z03w0AM0EM1X063000000A0k00NU6003k0000600000U"
        GraphicSearch_query5 := "|<BattleIconColor80>0xFFFDDF@0.81$42.00Dzk00007zs00003zs00001zy000EEzz300ssTz7U1xwDzzU0zy7zz00Tz3zy00DzVzw007zUzs007z0Ts00Dy0Tw00Ty0Ty00yT0yT01wDVwDU3w7Vs7k7s30k3s7k0001w7U0000s300000E0000000U"
        GraphicSearch_query6 := "|<TitleDsGray175>*157$13.zzzTzjzrz33BjinrSNji6Dzz"
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
        resultObj1 := oGraphicSearch.search(myX, myY, myW, myH, E1, E2, collection)
        if (resultObj1) {
            MsgBox, 4096, Tip, % "Found BattleTextGray131"
            ;X := resultObj1.1.x, Y := resultObj1.1.y, Comment := resultObj1.1.id
            ; Click, %X%, %Y%
        }

        resultObj2 := oGraphicSearch.search(myX, myY, myW, myH, E1, E2, GraphicSearch_query2)
        if (resultObj2) {
            MsgBox, 4096, Tip, % "Found BattleTextColor100"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }

        resultObj3 := oGraphicSearch.search(myX, myY, myW, myH, E1, E2, GraphicSearch_query3)
        if (resultObj3) {
            MsgBox, 4096, Tip, % "Found BattleTextGray130b"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }

        resultObj4 := oGraphicSearch.search(myX, myY, myW, myH, E1, E2, GraphicSearch_query4)
        if (resultObj4) {
            MsgBox, 4096, Tip, % "Found BattleIconColor100"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }

        resultObj5 := oGraphicSearch.search(myX, myY, myW, myH, E1, E2, GraphicSearch_query5)
        if (resultObj5) {
            MsgBox, 4096, Tip, % "Found BattleIconColor80"
            ;X := resultObj2.1.x, Y := resultObj2.1.y, Comment := resultObj2.1.id
            ; Click, %X%, %Y%
        }
        
        resultObj6 := oGraphicSearch.search(myX, myY, myW, myH, E1, E2, GraphicSearch_query6)
        if (resultObj6) {
            MsgBox, 4096, Tip, % "Found TitleDsGray175"
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


