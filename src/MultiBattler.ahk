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

#Include src/GraphicDetector.ahk
#Include src/ImageDetector.ahk

;TODO: remove all global keywords
Class MultiBattler {

    testAuto() {
        global
        ; Detect screens playground

        ; Check if the game is open
        if !WinExist(RaidWinTitle){
            Msgbox, 20, %ScriptTitle%, % UnableToAuto
                IfMsgbox, no 
                {
                    GoSub ShowMain
                    return
                }
                GoSub GoToGame
            return
        }

        ;WinActivate, %RaidWinTitle%
        ;screenDetector := new GraphicDetector()

        ; GDIP ImageDetector dont requiere WinActivate!
        screenDetector := new ImageDetector()
        screenDetector.detectScreen(true)
    }

    start() {
        global

        if !isDebug && !WinExist(RaidWinTitle){
            MsgBox, 48, %ScriptTitle%, %NoRunningGameMessage%
            return
        }
        
        StartTime := A_TickCount
        Gui, Submit
        GoSub ShowRunning

        isRunning := true
        repetitions := (TabSelector = 1) ? BattlesValue : (TabSelector = 2) ? calculatedResults.repetitions : -1
        isInfinite := (repetitions = -1)

        waitSeconds := Settings.second + ( Settings.minute * 60 )
        waitSecondsFormatted := FormatSeconds(waitSeconds)
        waitMillis := (waitSeconds * 1000)

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
        TrayTip, %ScriptTitle%, %notification%, 20, 17

        ; TODO: Hide MultiBattleProgress not working
        GuiControl, Running:, % (isInfinite) ? "Hide" : "Show", MultiBattleProgress
        GuiControl, Running:, % (isInfinite) ? "Hide" : "Show", MultiBattleStatus

        If (isInfinite){
            WinSet, Style, +%PBS_MARQUEE%, % "ahk_id " hPB2
            SendMessage, %PBM_SETMARQUEE%, 1, 50,, % "ahk_id " hPB2
        }
        else{
            WinSet, Style, -%PBS_MARQUEE%, % "ahk_id " hPB2
        }
                
        stepProgress1 := 100 / waitSeconds
        stepProgress2 := 100 / repetitions 

        replayCounter := 0
        currentRepetition := 0
        
        loop{
            currentRepetition++
            If not isRunning 
                break
                
            If (!isInfinite && currentRepetition > repetitions)
                break
            
            If (isInfinite){
                GuiControl, Running:, MultiBattleStatus, % currentRepetition . " / Infinite"
            }
            else{
                currentProgress2 := (currentRepetition * stepProgress2)
                GuiControl, Running:, MultiBattleProgress, %currentProgress2%
                GuiControl, Running:, MultiBattleStatus, % currentRepetition . " / " . repetitions . ""
            }
            
            WinGetActiveTitle, PreviouslyActive
            WinActivate, %RaidWinTitle%
            sleep 25
            
            isAdminNeeded := !CanSendKeysToWin(RaidWinTitle)
            if (isAdminNeeded){
                Msgbox, 20, %ScriptTitle%, % UnableToSendKeysToGameMessage
                IfMsgbox, no 
                {
                    GoSub ShowMain
                    return
                }
                GoSub RunScriptAsAdmin
                return
            }
            
            ControlSend, , {Enter}, %RaidWinTitle%
            ControlSend, , r, %RaidWinTitle%
            replayCounter++
            sleep 25
            WinActivate, %PreviouslyActive%
            
            GuiControl, Running:, CurrentBattleProgress, 0
            currentSecond := 1
            loop{
                If not isRunning 
                    break
                    
                If !isDebug && !WinExist(RaidWinTitle) {
                    isRunning := false
                    Gosub ShowResultInterrupted
                    break
                }
                
                currentProgress1 := ((currentSecond) * stepProgress1)
                GuiControl, Running:, CurrentBattleProgress, %currentProgress1%
                currentTimeFormatted := FormatSeconds(currentSecond)
                GuiControl, Running:, CurrentBattleStatus, %currentTimeFormatted% / %waitSecondsFormatted%  
                
                if (!isInfinite){
                    totalSeconds := (repetitions * waitSeconds)
                    timeElapsed := (waitSeconds * (currentRepetition-1)) + currentSecond
                    timeLeft := totalSeconds - timeElapsed
                    if (timeLeft<0){
                        timeLeft := 0
                    }
                    GuiControl, Running:, OnFinishMessageValue, % FormatSeconds(timeLeft)
                }
                
                if (currentSecond > waitSeconds){
                    break
                }
                sleep 1000
                currentSecond++
            }
        }
        
        If isRunning{
            Gosub ShowResultSuccess
        }
    }

    showResult(){
        global
        
        MultiBattleDuration := (A_TickCount - StartTime) / 1000
        isRunning := false
        noActivateFlag := ""
        
        if (A_ThisLabel = "ShowResultSuccess"){
            TrayTip, %ScriptTitle%, %ResultMessageSuccess%, 20, 17
            GuiControl, Result:, ResultHeader, %ResultHeaderSuccess%
            GuiControl, Result:, ResultMessage, %ResultMessageSuccess%
            
            if (Settings.onFinish = 1){
                WinActivate, %RaidWinTitle%
            }
            else if (Settings.onFinish = 3){
                WinGetActiveTitle, CurrentlyActive
                noActivateFlag := CurrentlyActive != ScriptTitle ? "NoActivate" : ""
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
            TrayTip, %ScriptTitle%, %ResultMessageCanceled%, 20, 17
            GuiControl, Result:, ResultHeader, %ResultHeaderCanceled%
            GuiControl, Result:, ResultMessage, %ResultMessageCanceled%
        }
        else{
            TrayTip, %ScriptTitle%, %ResultMessageInterrupted%, 20, 17
            GuiControl, Result:, ResultHeader, %ResultHeaderInterrupted%
            GuiControl, Result:, ResultMessage, %ResultMessageInterrupted%
        }
        
        formattedTotal := (repetitions=-1) ? "Infinite" : repetitions
        formattedBattles := (A_ThisLabel = "ShowResultSuccess") ? replayCounter : replayCounter " of " formattedTotal
        GuiControl, Result:, ResultText, % formattedBattles " battles in " FormatSeconds(MultiBattleDuration)
        
        Gui,+LastFound
        WinGetPos,x,y
        if (A_ThisLabel = "ShowResultSuccess"){
            x += 50
            y += 200
        }
        Gui, Result:Show, x%x% y%y% %noActivateFlag%, %ScriptTitle%
        HideAllGuisBut(AllGuis, "Result")
    }
}