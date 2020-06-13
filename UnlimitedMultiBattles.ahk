;
;   Copyright 2020 Rafael Acosta Alvarez
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


#NoEnv                          ; Recommended for performance and compatibility with future AutoHotkey releases.
;#Warn                          ; Enable warnings to assist with detecting common errors.
SendMode Input                  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%     ; Ensures a consistent starting directory.
#SingleInstance Force           ; Only one instance
#MaxThreadsPerHotkey 1          ; Only one thread
SetTitleMatchMode 3             ; Exact title match

;;; Metadata
ScriptVersion := "v1.0.0"
ScriptTitle := "UnlimitedMultiBattles"
ScriptDescription := "For official 'Raid: Shadow Legend' on Windows"
ScriptSite := "https://github.com/rafaco/UnlimitedMultiBattles"
ScriptAuthor := "Rafael Acosta Alvarez"

;;; Texts
DelayHeader := "1. Time between battles:"
RepetitionHeader := "2. Number of battles:"
StartHeader := "3. Start farming:"
StartButton := "Start Multi-Battle"
StopButton := "Stop"
InfiniteMessage := "`nInfinite mode, we will keep replaying till you press stop."
ManualMessage := "`nManually select the number of times you want to multi-play."
NoGameError := "Raid Shadow Legends is not running, please start it."
IntroHelp := "This script allows to replay Raid on background while doing other things on foreground. It quickly swap to Raid game window, press the replay hotkey 'R' and go back to your previous window."
UsageHelp := "1. Open 'Raid: Shadow Legends' on your PC, select the stage and prepare your farming team but don't press 'Play' already.`n2. Then on this application, select your farming options and press 'Start Multi-Battle'."
DelayHelp := "Enter how many seconds you want us to wait between each replay. It depends on your current team speed for the stage you are in. Use your longer run time plus a small margin for the loading screens."
RepetitionHelp := "Select how many times you want to play the stage. In order to avoid wasting your precious energy, you have three available modes: you can run it INFINITELY, enter a MANUAL number or use our handy CALCULATOR to know how many runs to max out your level 1 champions."
StartBattleHelp := "When ready, just press 'Start Multi-Battle' and lay back while we farm for you. Cancel it at any time by pressing 'Stop'."
ScriptHelp := "This script is license under Apache 2.0 and it's source code is hosted at GitHub. Find out more info at his repository."

;;; Constants
RaidWinTitle := "Raid: Shadow Legends"
SettingsFile := ScriptTitle . ".ini"
SettingsSection := "SettingsSection"
DefaultSettings := { delay: 25, repetitions: 10, tab: 1, stage: 1, boost: 3, star: 1 }
TabOptions = Manual|Calculated|Infinite
StageOptions = Brutal 12-3|Brutal 12-6
BoostOptions := "None 0%|Raid Boost +20%|XP Boost +100%|Both +120%"
StarOptions = 1 Star|2 Star|3 Star|4 Star|5 Star|6 Star
Brutal12_3 := [ [6, 19, 47, 104, 223, 465], [5, 16, 39, 87, 186, 388], [3, 10, 24, 52, 112, 233], [3, 8, 20, 44, 93, 194]]
Brutal12_6 := [ [6, 19, 46, 103, 220, 457], [5, 16, 39, 86, 183, 381], [3, 10, 23, 52, 110, 229], [3, 8, 20, 43, 92, 191]]
CalculatorData := [ Brutal12_3, Brutal12_6 ]

;;; StartUp
if !WinExist(RaidWinTitle)
{
    ; Show error, game start required
    MsgBox, 48, %ScriptTitle%, %NoGameError%
    ExitApp
}
else
{
    ; Init previous settings or default values
    If (!FileExist(SettingsFile)){
        Settings := DefaultSettings
        for key, value in Settings{
            IniWrite, %value%, %SettingsFile%, %SettingsSection%, %key%
        }
    }else{
        Settings := {}
        for key, value in DefaultSettings{
            IniRead, temp, %SettingsFile%, %SettingsSection%, %key%
            Settings[key] := temp
        }
    }

    ; Prepare selections
    selectedTab := Settings.tab
    selectedStage := Settings.stage
    selectedBoost := Settings.boost
    selectedStar := Settings.star
    CalculatedRepetitions := CalculatorData[selectedStage][selectedBoost][selectedStar]


    ;;; Load UIs
    ;; 1st UI: Home
    Gui, Font, s10 bold
    Gui, Add, Text, w280 Section Center, %ScriptTitle% %ScriptVersion%
    Gui, Font, s8 norm
    Gui, Add, Text, w280 y+2 Center, %ScriptDescription%
    Gui, Add, Button, w50 ys y15 Center gHelp, Info
    Gui, Add, text, xs w350 0x10

    Gui, Font, s10 bold
	Gui, Add, Text, xs, %DelayHeader%
    Gui, Font, s8 norm
    Gui, Add, Text, w85 xs Section,
    Gui, Font, s20 
    Gui, Add, Button, ys w30 h40 Center gDelayMinus, -
    Gui, Add, Edit, ys w50 right vDelayEdit, % Settings.delay
    Gui, Add, Button, ys w30 h40 Center gDelayPlus, +
    Gui, Font, s12
    Gui, Add, Text, w100 ys+8, seconds
    Gui, Font, s8

    Gui, Add, Text,
    Gui, Font, s10 bold
    Gui, Add, Text, xs Section, %RepetitionHeader%
    Gui, Font, s8 norm
    TCS_FIXEDWIDTH := 0x0400
    TCM_SETITEMSIZE := 0x1329
    CtrlWidth := 350
    TabWidth := (CtrlWidth) / 3
    Gui, Add, Tab3, hwndHTAB w%CtrlWidth% +%TCS_FIXEDWIDTH% vTabSelector gTabChanged Choose%selectedTab% AltSubmit, %TabOptions%
    SendMessage, TCM_SETITEMSIZE, 0, TabWidth, , ahk_id %HTAB%

    Gui, Add, text, w350 Section, %ManualMessage%
    Gui, Add, Text, xs w73 Section,
    Gui, Font, s20 
    Gui, Add, Button, ys w30 h40 Center gRepetitionsMinus, -
    Gui, Add, Edit, ys w50 right vRepetitionsEdit, % Settings.repetitions
    Gui, Add, Button, ys w30 h40 Center gRepetitionsPlus, +
    Gui, Font, s12
    Gui, Add, Text, w100 ys+20, battles
    Gui, Font, s8
    Gui, Tab, 2
    Gui, Add, text, w100 Section, Stage:
    Gui, Add, DropDownList, w100 vStageSelector gStageChanged Choose%selectedStage% AltSubmit, %StageOptions%
    Gui, Add, text, w100 ys, Boost:
    Gui, Add, DropDownList, w100 vBoostSelector gBoostChanged Choose%selectedBoost% AltSubmit, %BoostOptions%
    Gui, Add, text, w100 ys, Champion (lvl 1):
    Gui, Add, DropDownList, w100 vStarSelector gStarChanged Choose%selectedStar% AltSubmit, %StarOptions%
    Gui, Add, Text, w85 xs Section,
    Gui, Font, s20 
    Gui, Add, Text, w60 right ys vCalculatedRepetitions, %CalculatedRepetitions%
    Gui, Font, s12
    Gui, Add, Text, w100 ys+8, battles
    Gui, Font, s8
    Gui, Tab, 3
    Gui, Add, text, w350 Section, %InfiniteMessage%
    Gui, Add, Text, w85 Section,
    Gui, Font, s20 
    Gui, Add, Text, w40 ys right, INFINITE
    Gui, Font, s12
    Gui, Add, Text, w100 ys+8, battles
    Gui, Font, s8
    Gui, Tab 

    Gui, Add, Text,
    Gui, Font, s10 bold
    Gui, Add, Button, w350 h30 Center gStart, %StartButton%
    Gui, Font, s8 norm
    Gui, Add, Text,,

    ;; 2nd UI: Progress
    Gui, 2:Font,bold
    Gui, 2:Add, Text, w250 Center vWorkingTitle,
    Gui, 2:Font
    Gui, 2:Add, Progress, w250 h20 -Smooth vWorkingProgress1, 0
    Gui, 2:Add, Progress, w250 h20 -Smooth vWorkingProgress2, 0
    Gui, 2:Add, Text, w250 Center vWorkingStatus
    Gui, 2:Font, s10 bold
    Gui, 2:Add, Button, w250 h30 gStop, %StopButton%
    Gui, 2:Font, s8 norm

    ;; 3rd UI: Help
    Gui, 3:Font, s10 bold
    Gui, 3:Add, Text, w280 Section Center, %ScriptTitle% %ScriptVersion%
    Gui, 3:Font, s8 norm
    Gui, 3:Add, Text, w280 y+2 Center, %ScriptDescription%
    Gui, 3:Add, Button, w50 ys y15 Center gBackFromHelp, Back
    Gui, 3:Add, text, xs w350 0x10    
    Gui, 3:Font, s10 bold
    Gui, 3:Add, Text, w350 Center xs, Help
    Gui, 3:Font, s8 norm
    Gui, 3:Add, Text, w350 xs Section, %IntroHelp%
    Gui, 3:Font, s9 bold
    Gui, 3:Add, Text, xs, Usage
    Gui, 3:Font, s8 norm
    Gui, 3:Add, Text, w350 xs Section, %UsageHelp%
    Gui, 3:Font, s9 bold
    Gui, 3:Add, Text, xs, %DelayHeader%
    Gui, 3:Font, s8 norm
    Gui, 3:Add, Text, w350 xs Section, %DelayHelp%
    Gui, 3:Font, s9 bold
    Gui, 3:Add, Text, xs, %RepetitionHeader%
    Gui, 3:Font, s8 norm
    Gui, 3:Add, Text, w350 xs Section, %RepetitionHelp%
    Gui, 3:Add, Text, w350 xs Section, %StartBattleHelp%
    Gui, 3:Add, text, xs w350 0x10
    Gui, 3:Font, s10 bold
    Gui, 3:Add, Text, w350 Center xs, About
    Gui, 3:Font, s8 norm
    Gui, 3:Add, Text, w280 xs Section, %ScriptHelp%
    Gui, 3:Add, Button, w50 ys Center gGoToSite, Site
    Gui, 3:Add, Text, xs

    ; Show 1st UI
    Gui, 1:Show, xCenter y150 AutoSize, %ScriptTitle%
    return
}

Help:
    Gui,+LastFound
    WinGetPos,x,y
    Gui, 3:Show, x%x% y%y%, %ScriptTitle%
    Gui, 1:Hide
    Return
    return
   
BackFromHelp:
    Gui,+LastFound
    WinGetPos,x,y
    Gui, 1:Show, x%x% y%y%, %ScriptTitle%
    Gui, 3:Hide
    Return

GoToSite:
    Run %ScriptSite%
    return
    
DelayMinus:
DelayPlus:
    Gui, Submit, NoHide
    If (A_GuiControl = "+") 
        DelayEdit++
    else 
        DelayEdit--
    IniWrite, %DelayEdit%, %SettingsFile%, %SettingsSection%, delay
    GuiControl,, DelayEdit, %DelayEdit%
    return
    
RepetitionsMinus:
RepetitionsPlus:
    Gui, Submit, NoHide
    If (A_GuiControl = "+") 
        RepetitionsEdit++
    else 
        RepetitionsEdit--
    IniWrite, %RepetitionsEdit%, %SettingsFile%, %SettingsSection%, repetitions
    GuiControl,, RepetitionsEdit, %RepetitionsEdit%
    return

TabChanged:
    Gui, Submit, NoHide
    IniWrite, %TabSelector%, %SettingsFile%, %SettingsSection%, tab
    return

StageChanged:
BoostChanged:
StarChanged:
    Gui, Submit, NoHide
    CalculatedRepetitions := CalculatorData[StageSelector][BoostSelector][StarSelector]
    GuiControl,, CalculatedRepetitions, %CalculatedRepetitions%
    IniWrite, %StageSelector%, %SettingsFile%, %SettingsSection%, stage
    IniWrite, %BoostSelector%, %SettingsFile%, %SettingsSection%, boost
    IniWrite, %StarSelector%, %SettingsFile%, %SettingsSection%, star
    return

Start:
    StartTime := A_TickCount
    Gui, Submit
    Gui,+LastFound
    WinGetPos,x,y
    Gui, 2:Show, x%x% y%y%, %ScriptTitle%
    Gui, 1:Hide

    isRunning := true
    repetitions := (TabSelector = 1) ? RepetitionsEdit : (TabSelector = 2) ? CalculatedRepetitions : -1
    isInfinite := (repetitions = -1)

    waitSeconds := DelayEdit
    waitMillis := (waitSeconds * 1000)

    if (isInfinite){
        title := "Farming infinitely, " waitSeconds " seconds each."
        notification := "Starting infinited runs"
    }else{
        totalSeconds := (repetitions * waitSeconds)
        totalMinutes := floor(totalSeconds / 60)
        title := "Farming " repetitions " runs of " waitSeconds " seconds: " totalMinutes " min. aprox."
        notification := "Starting " repetitions " runs estimated in " totalMinutes " minutes"
    }
    GuiControl, 2:, WorkingTitle, %title%
    TrayTip, %ScriptTitle%, %notification%, 20, 17

    ; TODO: Hide WorkingProgress2 not working
    GuiControl, 2:, % (isInfinite) ? "Hide" : "Show", WorkingProgress2
    GuiControl, 2:, % (isInfinite) ? "Hide" : "Show", WorkingStatus

    stepProgress1 := floor(100 / waitSeconds)
    stepProgress2 := floor(100 / repetitions)   

    currentRepetition := 0
    loop{
        currentRepetition++
        If not isRunning 
            break
            
        If (!isInfinite && currentRepetition > repetitions)
            break
        
        If (!isInfinite){
            currentProgress2 := (currentRepetition * stepProgress2)
            GuiControl, 2:, WorkingProgress2, %currentProgress2%
            GuiControl, 2:, WorkingStatus, %currentRepetition% / %repetitions% runs
        }else{
            GuiControl, 2:, WorkingProgress2, 100
            GuiControl, 2:, WorkingStatus, %currentRepetition% runs
        }
        
        WinGetActiveTitle, PreviouslyActive
        WinActivate, %RaidWinTitle%
        ;sleep 100
        ControlSend, , {Enter}, %RaidWinTitle%
        ;sleep 100
        ControlSend, , r, %RaidWinTitle%
        sleep 100
        WinActivate, %PreviouslyActive%
        
        GuiControl, 2:, WorkingProgress1, 0
        currentSecond := 0
        loop{
            If not isRunning 
                break
                
            If !WinExist(RaidWinTitle) {
                isRunning := false
                TrayTip, %ScriptTitle%, Canceled, game closed, 20, 17
                Gui,+LastFound
                WinGetPos,x,y
                MsgBox, 48, %ScriptTitle%, %NoGameError%
                Gui, 1:Show, x%x% y%y%, %ScriptTitle%
                Gui, 2:Hide
                break
            }
            
            currentProgress1 := ((currentSecond) * stepProgress1)
            GuiControl, 2:, WorkingProgress1, %currentProgress1%
            if (currentSecond >= waitSeconds){
                break
            }
            sleep 1000
            currentSecond++
        }
	}
    
    If isRunning{
        isRunning := false
        ElapsedTime := (A_TickCount - StartTime) / 1000
        MsgBox,  %ElapsedTime% seconds have elapsed.
        TrayTip, %ScriptTitle%, Farmed %repetitions% times!, 20, 17
        Gui,+LastFound
        WinGetPos,x,y
        Gui, 1:Show, x%x% y%y%, %ScriptTitle%
        Gui, 2:Hide
    }
    return

Stop:
    isRunning := false
    TrayTip, %ScriptTitle%, Canceled by user, 20, 17
    Gui,+LastFound
    WinGetPos,x,y
    Gui, 1:Show, x%x% y%y%, %ScriptTitle%
    Gui, 2:Hide
    Return

GuiClose:
    Gui, Submit
    ; Following values need to be manually stored, as can be changed manually
    IniWrite, %DelayEdit%, %SettingsFile%, %SettingsSection%, delay
    IniWrite, %RepetitionsEdit%, %SettingsFile%, %SettingsSection%, repetitions
    
    Gui, 1:Destroy
    Gui, 2:Destroy
    ExitApp
