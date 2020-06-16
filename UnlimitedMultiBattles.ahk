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
ScriptDescription := "For official 'Raid: Shadow Legends' on Windows"
ScriptSite := "https://github.com/rafaco/UnlimitedMultiBattles"
ScriptAuthor := "Rafael Acosta Alvarez"

;;; Texts
TeamHeader := "1. Prepare your team:"
TeamDescription := "Open the game, select a stage and prepare your farming team but don't press 'Play' already.`n"
DelayHeader := "2. Time between battles:"
RepetitionHeader := "3. Number of battles:"
StartHeader := "4. Start farming:"
StartButton := "Start Multi-Battle"
StopButton := "Stop"
InfiniteMessage := "`nWe will keep playing mult-battles till you press stop."
ManualMessage := "`nEnter any number of multi-battles."
CalculatedMessage := "Exact battles to max out your level 1 champions:"
NoRunningGameError := "You have to open the game and select your team before start."
ClosedGameError := "Canceled, the game has been closed."
UnableToOpenGame := "Unable to open the game from the standard installation folder.`n`nYou have to open it manually."
IntroHelp := "This script allows to replay Raid on background while doing other things on foreground. It quickly swap to Raid game window, press the replay hotkey 'R' and go back to your previous window."
UsageHelp := "1. Open 'Raid: Shadow Legends' on your PC, select the stage and prepare your farming team but don't press 'Play' already.`n2. Then on this application, select your farming options and press 'Start Multi-Battle'."
DelayHelp := "Enter how many seconds you want us to wait between each replay. It depends on your current team speed for the stage you are in. Use your longer run time plus a small margin for the loading screens."
RepetitionHelp := "Select how many times you want to play the stage. In order to avoid wasting your precious energy, you have three available modes: you can run it INFINITELY, enter a MANUAL number or use our handy CALCULATOR to know how many runs to max out your level 1 champions."
StartBattleHelp := "When ready, just press 'Start Multi-Battle' and lay back while we farm for you. Cancel it at any time by pressing 'Stop'."
ScriptHelp := "This script is license under Apache 2.0 and it's source code is hosted at GitHub. Find out more info at his repository."

;;; Constants
RaidWinTitle := "Raid: Shadow Legends"
SettingsFilePath := A_AppData . "/" . ScriptTitle . ".ini"
RaidFilePath := A_AppData . "\..\Local" . "\Plarium\PlariumPlay\PlariumPlay.exe"
SettingsSection := "SettingsSection"
DefaultSettings := { minute: 0, second: 25, battles: 10, tab: 1, stage: 1, boost: 3, star: 1 }
InfiniteSymbol := Chr(0x221E)
TabOptions = Manual|Calculated|Infinite
StageOptions = Brutal 12-3|Brutal 12-6
BoostOptions := "No Boost|Raid Boost|XP Boost|Both Boosts"
StarOptions = 1 Star|2 Star|3 Star|4 Star|5 Star|6 Star
Brutal12_3 := [ [6, 19, 47, 104, 223, 465], [5, 16, 39, 87, 186, 388], [3, 10, 24, 52, 112, 233], [3, 8, 20, 44, 93, 194]]
Brutal12_6 := [ [6, 19, 46, 103, 220, 457], [5, 16, 39, 86, 183, 381], [3, 10, 23, 52, 110, 229], [3, 8, 20, 43, 92, 191]]
CalculatorData := [ Brutal12_3, Brutal12_6 ]


; Init settings (previous values or default ones)
If (!FileExist(SettingsFilePath)){
    Settings := DefaultSettings
    for key, value in Settings{
        IniWrite, %value%, %SettingsFilePath%, %SettingsSection%, %key%
    }
}else{
    Settings := {}
    for key, value in DefaultSettings{
        IniRead, temp, %SettingsFilePath%, %SettingsSection%, %key%
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
Gui, Font, s10 norm
Gui, Add, Text, w280 y+2 Center, %ScriptDescription%
Gui, Add, Button, w50 ys y15 Center gShowInfo, Info
Gui, Add, text, xs w350 0x10
Gui, Font, s10 bold
Gui, Add, Text, xs, %TeamHeader%
Gui, Font, s10 norm
Gui, Add, Text, w2 xs Section, 
Gui, Add, Text, w258 ys, %TeamDescription%
Gui, Add, Button, w50 ys+5 Center gGoToGame, Go
Gui, Font, s10 bold
Gui, Add, Text, xs, %DelayHeader%
Gui, Font, s8 norm
Gui, Add, Text, w45 xs Section,
Gui, Font, s20 
Gui, Add, Edit, ys w55 Right gSettingChangedByEdit vEditMinute +Limit3 +Number, % Settings.minute
Gui, Add, UpDown, ys Range0-60 vUpDownMinute gSettingChangedByUpDown, % Settings.minute
Gui, Font, s12
Gui, Add, Text, ys+8, minutes
Gui, Font, s20 
Gui, Add, Edit, ys w55 Right gSettingChangedByEdit vEditSecond +Limit3 +Number, % Settings.second
Gui, Add, UpDown, ys Range0-59 vUpDownSecond gSettingChangedByUpDown, % Settings.second
Gui, Font, s12
Gui, Add, Text, ys+8, seconds
Gui, Font, s8
Gui, Add, Text,
Gui, Font, s10 bold
Gui, Add, Text, xs Section, %RepetitionHeader%
Gui, Font, s10 norm
TCS_FIXEDWIDTH := 0x0400
TCM_SETITEMSIZE := 0x1329
CtrlWidth := 350
TabWidth := (CtrlWidth) / 3
Gui, Add, Tab3, hwndHTAB w%CtrlWidth% +%TCS_FIXEDWIDTH% vTabSelector gSettingChangedByTab Choose%selectedTab% AltSubmit, %TabOptions%
SendMessage, TCM_SETITEMSIZE, 0, TabWidth, , ahk_id %HTAB%
Gui, Add, text, w350 Section, %ManualMessage%
Gui, Add, Text, xs w80 Section,
Gui, Font, s20 
Gui, Add, Edit, ys+8 w70 Right gSettingChangedByEdit vEditBattles +Limit3 +Number, % Settings.battles
Gui, Add, UpDown, ys Range0-999 vUpDownBattles gSettingChangedByUpDown, % Settings.battles
Gui, Font, s12
Gui, Add, Text, xs+174 ys+16, battles
Gui, Font, s10
Gui, Tab, 2
Gui, Add, text, w350 Section, %CalculatedMessage%
Gui, Add, DropDownList, xs Section w100 vStageSelector gSettingChangedBySelector Choose%selectedStage% AltSubmit, %StageOptions%
Gui, Add, DropDownList, ys w100 vBoostSelector gSettingChangedBySelector Choose%selectedBoost% AltSubmit, %BoostOptions%
Gui, Add, DropDownList, ys w100 vStarSelector gSettingChangedBySelector Choose%selectedStar% AltSubmit, %StarOptions%
Gui, Add, Text, w70 xs Section,
Gui, Font, s20 
Gui, Add, Text, w1 xs+120 right ys vCalculatedRepetitions, %CalculatedRepetitions%
Gui, Font, s12
Gui, Add, Text, w100 xs+174 ys+3, battles
Gui, Font, s10
Gui, Tab, 3
Gui, Add, text, w350 Section, %InfiniteMessage%
Gui, Add, Text, xs w80 Section,
Gui, Font, s45 
Gui, Add, Text, xs+120 ys+12 w70 Right h30 w40 0x200, % InfiniteSymbol
Gui, Font, s12
Gui, Add, Text, xs+174 ys+16, battles
Gui, Font, s10
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

;; 3rd UI: Info
Gui, 3:Font, s10 bold
Gui, 3:Add, Text, w280 Section Center, %ScriptTitle% %ScriptVersion%
Gui, 3:Font, s10 norm
Gui, 3:Add, Text, w280 y+2 Center, %ScriptDescription%
Gui, 3:Add, Button, w50 ys y15 Center gBackFromInfo, Back
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



;;; Labels

ShowInfo:
    Gui,+LastFound
    WinGetPos,x,y
    Gui, 3:Show, x%x% y%y%, %ScriptTitle%
    Gui, 1:Hide
return
   
BackFromInfo:
    Gui,+LastFound
    WinGetPos,x,y
    Gui, 1:Show, x%x% y%y%, %ScriptTitle%
    Gui, 3:Hide
return

GoToSite:
    Run %ScriptSite%
return
    
GoToGame:
    if WinExist(RaidWinTitle){
        ; Game already open, activate window
        WinActivate, %RaidWinTitle%
    }
    else{
        If (FileExist(RaidFilePath)){
            ; Open game
            Run, %RaidFilePath% --args -gameid=101
        }
        else{
            ; Show unable to open game dialog
            MsgBox, 48, %ScriptTitle%, %UnableToOpenGame%
            return
        }
    }
return

SettingChangedByEdit:
    Gui, Submit, NoHide
	;Get Values
	GuiControlGet,MinuteValue,,EditMinute
	GuiControlGet,SecondValue,,EditSecond
    GuiControlGet,BattlesValue,,EditBattles
	;Store on settings
	IniWrite, %MinuteValue%, %SettingsFilePath%, %SettingsSection%, minute
    IniWrite, %SecondValue%, %SettingsFilePath%, %SettingsSection%, second
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
	;Make everything else aware
	GuiControl,,UpDownMinute,%MinuteValue%
	GuiControl,,UpDownSecond,%SecondValue%
    GuiControl,,UpDownBattles,%BattlesValue%
return

SettingChangedByUpDown:
	;Get Values
	GuiControlGet,MinuteValue,,UpDownMinute
	GuiControlGet,SecondValue,,UpDownSecond
    GuiControlGet,BattlesValue,,UpDownBattles
	;Store on settings
	IniWrite, %MinuteValue%, %SettingsFilePath%, %SettingsSection%, minute
    IniWrite, %SecondValue%, %SettingsFilePath%, %SettingsSection%, second
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
	;Make everything else aware
	GuiControl,,EditMinute,%UpDownMinute%
	GuiControl,,EditSecond,%UpDownSecond%
    GuiControl,,EditBattles,%BattlesValue%
return  

SettingChangedBySelector:
    ;Get Values
	GuiControlGet,StageValue,,StageSelector
	GuiControlGet,BoostValue,,BoostSelector
    GuiControlGet,StarValue,,StarSelector
    ;Store on settings
    IniWrite, %StageValue%, %SettingsFilePath%, %SettingsSection%, stage
    IniWrite, %BoostValue%, %SettingsFilePath%, %SettingsSection%, boost
    IniWrite, %StarValue%, %SettingsFilePath%, %SettingsSection%, star
    ;Make everything else aware
    CalculatedRepetitions := CalculatorData[StageValue][BoostValue][StarValue]
    GuiControl,, CalculatedRepetitions, %CalculatedRepetitions%
return
    
SettingChangedByTab:
    ;Get Values
	GuiControlGet,TagValue,,TabSelector
    IniWrite, %TagValue%, %SettingsFilePath%, %SettingsSection%, tab
return

Start:
    if !WinExist(RaidWinTitle){
        MsgBox, 48, %ScriptTitle%, %NoRunningGameError%
        return
    }
    
    StartTime := A_TickCount
    Gui, Submit
    Gui,+LastFound
    WinGetPos,x,y
    Gui, 2:Show, x%x% y%y%, %ScriptTitle%
    Gui, 1:Hide

    isRunning := true
    repetitions := (TabSelector = 1) ? BattlesValue : (TabSelector = 2) ? CalculatedRepetitions : -1
    isInfinite := (repetitions = -1)

    waitSeconds := SecondValue + ( MinuteValue * 60 )
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
                TrayTip, %ScriptTitle%, %ClosedGameError%, 20, 17
                Gui,+LastFound
                WinGetPos,x,y
                MsgBox, 48, %ScriptTitle%, %ClosedGameError%
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
return

GuiClose:
    Gui, Submit
    ; Following values need to be manually stored, as can be changed manually
    IniWrite, %MinuteValue%, %SettingsFilePath%, %SettingsSection%, minute
    IniWrite, %SecondValue%, %SettingsFilePath%, %SettingsSection%, second
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
    
    Gui, 1:Destroy
    Gui, 2:Destroy
    ExitApp
