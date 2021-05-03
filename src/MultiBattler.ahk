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
Class MultiBattler {

    testAuto() {
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
        screenDetector.detectScreen(true)
    }

    start() {
        global

        local isGameOpen := this.checkGameOpened()
        if (!isGameOpen){
            return
        }
        
        StartTime := A_TickCount
        Gui, Submit
        GoSub ShowRunning
        isRunning := true

        ; Prepare flags
        replayCounter := 0
        currentRepetition := 0
        repetitions := (TabSelector = 1) ? BattlesValue : (TabSelector = 2) ? calculatedResults.repetitions : -1
        isInfinite := (repetitions = -1)
        waitSeconds := Settings.second + ( Settings.minute * 60 )
        waitSecondsFormatted := this.FormatSeconds(waitSeconds)
        waitMillis := (waitSeconds * 1000)
        stepProgress1 := 100 / waitSeconds
        stepProgress2 := 100 / repetitions 

        ; Initialize Running GUI
        if (isInfinite){
            overview := "Infinited battles, " waitSeconds " seconds each."
            notification := "Starting infinited battles"
        }else{
            totalSeconds := (repetitions * waitSeconds)
            totalMinutes := floor(totalSeconds / 60)
            overview := repetitions " battles of " waitSeconds " seconds"
            notification := "Starting " repetitions " multi-battles (" totalMinutes " min)"
        }
        GuiControl, Running:, MultiBattleOverview, %overview%
        TrayTip, Constants.ScriptTitle, %notification%, 20, 17
        ; TODO: Hide MultiBattleProgress not working
        GuiControl, Running:, % (isInfinite) ? "Hide" : "Show", MultiBattleProgress
        GuiControl, Running:, % (isInfinite) ? "Hide" : "Show", MultiBattleStatus
        local PBS_MARQUEE := 0x8, PBM_SETMARQUEE := 0x40A
        If (isInfinite){
            WinSet, Style, +%PBS_MARQUEE%, % "ahk_id " hPB2
            SendMessage, %PBM_SETMARQUEE%, 1, 50,, % "ahk_id " hPB2
        }
        else{
            WinSet, Style, -%PBS_MARQUEE%, % "ahk_id " hPB2
        }

        ; For each battle
        loop{
            currentRepetition++
            If not isRunning 
                break

            ; Keep battling or finish multi-battle    
            If (!isInfinite && currentRepetition > repetitions)
                break
            
            ; Update Running GUI with current battle
            If (isInfinite){
                GuiControl, Running:, MultiBattleStatus, % currentRepetition . " / Infinite"
            }
            else{
                currentProgress2 := (currentRepetition * stepProgress2)
                GuiControl, Running:, MultiBattleProgress, %currentProgress2%
                GuiControl, Running:, MultiBattleStatus, % currentRepetition . " / " . repetitions . ""
            }
            
            ; Start/Replay battle
            WinGetActiveTitle, PreviouslyActive
            WinActivate, % Constants.RaidWinTitle
            sleep 25    ; TODO: improve waiting for activation 
            local isAdminNeeded := this.checkAdminNeededToSendKeys(Constants.RaidWinTitle)
            if (isAdminNeeded){
                return
            }
            ControlSend, , {Enter}, % Constants.RaidWinTitle
            ControlSend, , r, % Constants.RaidWinTitle
            sleep 25
            WinActivate, %PreviouslyActive%
            
            ; Reset flags
            replayCounter++
            GuiControl, Running:, CurrentBattleProgress, 0
            currentSecond := 1

            ; For each second between battles
            loop{
                If not isRunning 
                    break
                    
                If !isDebug && !WinExist(Constants.RaidWinTitle) {
                    isRunning := false
                    Gosub ShowResultInterrupted
                    break
                }
                
                ; Update Running GUI with battle process
                currentProgress1 := ((currentSecond) * stepProgress1)
                GuiControl, Running:, CurrentBattleProgress, %currentProgress1%
                currentTimeFormatted := this.FormatSeconds(currentSecond)
                GuiControl, Running:, CurrentBattleStatus, %currentTimeFormatted% / %waitSecondsFormatted%  
                if (!isInfinite){
                    totalSeconds := (repetitions * waitSeconds)
                    timeElapsed := (waitSeconds * (currentRepetition-1)) + currentSecond
                    timeLeft := totalSeconds - timeElapsed
                    if (timeLeft<0){
                        timeLeft := 0
                    }
                    GuiControl, Running:, OnFinishMessageValue, % this.FormatSeconds(timeLeft)
                }
                
                ; Keep waiting or start another battle
                if (currentSecond > waitSeconds){
                    break
                }
                sleep 1000
                currentSecond++
            }
        }
        
        if isRunning {
            Gosub ShowResultSuccess
        }
    }

    showResult(){
        global

        MultiBattleDuration := (A_TickCount - StartTime) / 1000
        isRunning := false
        noActivateFlag := ""
        
        if (A_ThisLabel = "ShowResultSuccess"){
            local header := Translate("ResultHeaderSuccess")
            local message := Translate("ResultMessageSuccess")
            GuiControl, Result:, ResultHeader, %header%
            GuiControl, Result:, ResultMessage, %message%
            TrayTip, Constants.ScriptTitle, %message%, 20, 17
            
            if (Settings.onFinish = 1){
                WinActivate, % Constants.RaidWinTitle
            }
            else if (Settings.onFinish = 3){
                WinGetActiveTitle, CurrentlyActive
                noActivateFlag := CurrentlyActive != Constants.ScriptTitle ? "NoActivate" : ""
            }
            
            if (OnFinishCheckbox = 1){
                OnFinishCheckbox := 0
                GuiControl, Result:, OnFinishCheckbox, %OnFinishCheckbox%
                hibernate := 0
                inmediately := 0
                disableWakes := 0
                DllCall("PowrProf\SetSuspendState", "int", hibernate, "int", inmediately, "int", disableWakes)
            }
        }
        else if (A_ThisLabel = "ShowResultCanceled"){
            local header := Translate("ResultHeaderCanceled")
            local message := Translate("ResultMessageCanceled")
            GuiControl, Result:, ResultHeader, %header%
            GuiControl, Result:, ResultMessage, %message%
            TrayTip, Constants.ScriptTitle, %message%, 20, 17
        }
        else{
            local header := Translate("ResultHeaderInterrupted")
            local message := Translate("ResultMessageInterrupted")
            GuiControl, Result:, ResultHeader, %header%
            GuiControl, Result:, ResultMessage, %message%
            TrayTip, Constants.ScriptTitle, %message%, 20, 17
        }
        
        formattedTotal := (repetitions=-1) ? "Infinite" : repetitions
        formattedBattles := (A_ThisLabel = "ShowResultSuccess") ? replayCounter : replayCounter " of " formattedTotal
        GuiControl, Result:, ResultText, % formattedBattles " battles in " this.FormatSeconds(MultiBattleDuration)
        
        Gui,+LastFound
        WinGetPos,x,y
        if (A_ThisLabel = "ShowResultSuccess"){
            x += 50
            y += 200
        }
        Gui, Result:Show, x%x% y%y% %noActivateFlag%, % Constants.ScriptTitle
        HideAllGuisBut(AllGuis, "Result")
    }

    checkGameOpened() {
        global
        if !WinExist(Constants.RaidWinTitle){
            Msgbox, 20, Constants.ScriptTitle, % Translate("UnableToAuto")
            IfMsgbox, no 
            {
                GoSub ShowMain
                return false
            }
            GoSub GoToGame
            return false
        }
        return true
    }

    checkAdminNeededToSendKeys(WinTitle){
        global
        static WM_KEYDOWN=0x100, WM_KEYUP=0x101, vk_to_use=7
        ; Test whether we can send keystrokes to this window.
        ; Use a virtual keycode which is unlikely to do anything:
        PostMessage, WM_KEYDOWN, vk_to_use, 0,, %WinTitle%
        if !ErrorLevel
        {   ; Seems best to post key-up, in case the window is keeping track.
            PostMessage, WM_KEYUP, vk_to_use, 0xC0000000,, %WinTitle%
            return false
        }

        Msgbox, 20, Constants.ScriptTitle, % Translate("UnableToSendKeysToGameMessage")
        IfMsgbox, no 
        {
            GoSub ShowMain
            return true
        }
        GoSub RunScriptAsAdmin
        return true
    }

    FormatSeconds(seconds){
        date = 2000 ;any year above 1600
        date += Floor(seconds), SECONDS
        FormatTime, formattedDate, %date%, mm:ss
        return formattedDate
    }
}