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
ScriptVersion := "v1.0.2"
ScriptTitle := "UnlimitedMultiBattles"
ScriptDescription := "For official 'Raid: Shadow Legends' on Windows"
ScriptSite := "https://github.com/rafaco/UnlimitedMultiBattles"
ScriptAuthor := "Rafael Acosta Alvarez"

;;; Texts
TeamHeader := "1. Prepare your team"
TeamDescription := "Open the game, select a stage and prepare your team. Don't press 'Play' and come back."
DelayHeader := "3. Select time between battles"
RepetitionHeader := "2. Select number of battles"
StartHeader := "4. Start farming"
StartButton := "Start Multi-Battle"
StopButton := "Cancel"
InfiniteMessage := "We will keep playing multi-battles till you press stop."
ManualMessage := "Enter any number of multi-battles."
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

RunningHeader := "Running..."
RunningOnFinishMessage := "On finish:"
RunningOnFinishOptions = Show game window|Show results window|Keep on background
ResultHeaderSuccess := "Completed!"
ResultHeaderCanceled := "Cancelled"
ResultHeaderInterrupted := "Interrupted"
ResultMessageSuccess := "Multi-Battle finished successfuly"
ResultMessageCanceled := "Multi-Battle canceled by user"
ResultMessageInterrupted := "Multi-Battle interrupted, game closed"

;;; Constants
isDebug := false
AllGui = Main|Running|Result|Info
RaidWinTitle := "Raid: Shadow Legends"
SettingsFilePath := A_AppData . "/" . ScriptTitle . ".ini"
RaidFilePath := A_AppData . "\..\Local" . "\Plarium\PlariumPlay\PlariumPlay.exe"
SettingsSection := "SettingsSection"
DefaultSettings := { minute: 0, second: 25, battles: 10, tab: 1, stage: 1, boost: 3, star: 1, onFinish: 3 }
InfiniteSymbol := Chr(0x221E)
StarSymbol := Chr(0x2605)
GearSymbol := Chr(0x2699)
InfoSymbol := Chr(0x2139)
TCS_FIXEDWIDTH := 0x0400
TCM_SETITEMSIZE := 0x1329
TabOptions = Manual|Max out|Infinite
StageOptions = Brutal 12-3|Brutal 12-6
BoostOptions := "No Boost|Raid Boost|XP Boost|Both Boosts"
StarOptions = 1%StarSymbol%: Level 1-10|2%StarSymbol%: Level 1-20|3%StarSymbol%: Level 1-30|4%StarSymbol%: Level 1-40|5%StarSymbol%: Level 1-50|6%StarSymbol%: Level 1-60
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
selectedOnFinish := Settings.onFinish
CalculatedRepetitions := CalculatorData[selectedStage][selectedBoost][selectedStar]


;;; Load UIs

;; 1st UI: Main
Gui, Main:Add, Picture, w350 h35 vpic, images\HeaderBackground.jpg

Gui, Main:Font, s10 bold
Gui, Main:Add, Text, w300 h35 xp yp 0x200 BackgroundTrans Section Center, %ScriptTitle% %ScriptVersion%
;Gui, Main:Font, s10 norm
;Gui, Main:Add, Text, w280 y+2 Center, %ScriptDescription%
Gui, Main:Font, s10 norm
Gui, Main:Add, Button, ys yp+5 Center gShowInfo, Info
;Gui, Main:Add, text, xs w350 0x10 
Gui, Main:Font, s2
Gui, Main:Add, Text, xs Section,

Gui, Main:Font, s10 bold
Gui, Main:Add, Text, xs Section, %TeamHeader%
Gui, Main:Font, s10 norm
Gui, Main:Add, Text, w287.5 xs vTeamDescription, %TeamDescription%
Gui, Main:Add, Button, w50 ys+15 Center gGoToGame vTeamButton, Open`nGame
Gui, Main:Font, s2
Gui, Main:Add, Text, xs,
Gui, Main:Font, s10 bold
Gui, Main:Add, Text, xs Section, %RepetitionHeader%
Gui, Main:Font, s10 norm
Gui, Main:Add, Tab3, hwndHTAB w350 +%TCS_FIXEDWIDTH% vTabSelector gSettingChangedByTab Choose%selectedTab% AltSubmit, %TabOptions%
SendMessage, TCM_SETITEMSIZE, 0, (350/3)+20, , ahk_id %HTAB%
Gui, Main:Add, Text, w75 Section,
Gui, Main:Font, s20 
Gui, Main:Add, Edit, ys+10 w70 Right gSettingChangedByEdit vEditBattles +Limit3 +Number, % Settings.battles
Gui, Main:Add, UpDown, ys Range1-999 vUpDownBattles gSettingChangedByUpDown, % Settings.battles
Gui, Main:Font, s14
Gui, Main:Add, Text, xs+174 ys+16, battles

Gui, Main:Tab, 2
Gui, Main:Font, s10
Gui, Main:Add, DropDownList, Section w90 vStageSelector gSettingChangedBySelector Choose%selectedStage% AltSubmit, %StageOptions%
Gui, Main:Add, DropDownList, ys w100 vBoostSelector gSettingChangedBySelector Choose%selectedBoost% AltSubmit, %BoostOptions%
Gui, Main:Add, DropDownList, ys w110 vStarSelector gSettingChangedBySelector Choose%selectedStar% AltSubmit, %StarOptions%
Gui, Main:Add, Text, w106 xs Section,
Gui, Main:Font, s20 
Gui, Main:Add, Text, w45 right ys vCalculatedRepetitions, %CalculatedRepetitions%
Gui, Main:Font, s14
Gui, Main:Add, Text, w100 ys+4, battles

Gui, Main:Tab, 3
Gui, Main:Font, s10
Gui, Main:Add, text, w350 h5 Section, 
Gui, Main:Add, Text, w106 xs Section,
Gui, Main:Font, s45 
Gui, Main:Add, Text, w45 h30 ys Right 0x200, % InfiniteSymbol
Gui, Main:Font, s14
Gui, Main:Add, Text, w100 ys+4, battles
Gui, Main:Tab
Gui, Main:Font, s2
Gui, Main:Add, Text, Section,
Gui, Main:Font, s10 bold
Gui, Main:Add, Text, xs, %DelayHeader%
Gui, Main:Font, s10 norm

Gui, Main:Add, Tab3, hwndHTAB w350 +%TCS_FIXEDWIDTH%, Manual
SendMessage, TCM_SETITEMSIZE, 0, (350/3)+20, , ahk_id %HTAB%
Gui, Main:Add, Text, Section w15,
Gui, Main:Font, s20 
Gui, Main:Add, Edit, ys w55 Right gSettingChangedByEdit vEditMinute +Limit3 +Number, % Settings.minute
Gui, Main:Add, UpDown, ys Range0-60 vUpDownMinute gSettingChangedByUpDown, % Settings.minute
Gui, Main:Font, s14
Gui, Main:Add, Text, ys+8, minutes
Gui, Main:Font, s20 
Gui, Main:Add, Edit, ys w55 Right gSettingChangedByEdit vEditSecond +Limit3 +Number, % Settings.second
Gui, Main:Add, UpDown, ys Range0-59 vUpDownSecond gSettingChangedByUpDown, % Settings.second
Gui, Main:Font, s14
Gui, Main:Add, Text, ys+8, seconds
Gui, Main:Tab

Gui, Main:Font, s2
Gui, Main:Add, Text, Section,
Gui, Main:Font, s10 bold
Gui, Main:Add, Text, w60 xs Section,
Gui, Main:Add, Button, ys w200 h30 0x200 Center gStart, %StartButton%

;; GUI: Running
Gui, Running:Font, s12 bold
Gui, Running:Add, Text, w250 Center, % RunningHeader
Gui, Running:Font, s10 normal
;Gui, Running:Add, Text, w250 Center vMultiBattleOverview, 
Gui, Running:Add, Text, w115 Section, Multi-Battle:
Gui, Running:Add, Text, ys w120 Right vMultiBattleStatus,
Gui, Running:Add, Progress, xs yp+18 w250 h20 -Smooth vMultiBattleProgress, 0
Gui, Running:Add, Text, w115 Section, Current battle:
Gui, Running:Add, Text, ys w120 Right vCurrentBattleStatus,
Gui, Running:Add, Progress, xs yp+18 w250 h20 -Smooth vCurrentBattleProgress, 0
Gui, Running:Font, s3 normal
Gui, Running:Add, Text, xs Section,
Gui, Running:Font, s10 normal
Gui, Running:Add, Text, w60 h23 Section Left 0x200, % RunningOnFinishMessage
Gui, Running:Add, DropDownList, ys w175 vOnFinishSelector gSettingChangedOnFinish Choose%selectedOnFinish% AltSubmit, %RunningOnFinishOptions%
Gui, Running:Font, s3 normal
Gui, Running:Add, Text, xs Section,
Gui, Running:Font, s10 bold
Gui, Running:Add, Text, xs Section,
Gui, Running:Add, Button, ys w200 h30 gShowResultCanceled 0x200 Center, %StopButton%

;; GUI: Result
Gui, Result:Font, s12 bold
Gui, Result:Add, Text, w250 Center vResultHeader,
Gui, Result:Font, s10 normal
Gui, Result:Add, Text, w250 yp+20 Center vResultMessage,
Gui, Result:Font, s12 normal
Gui, Result:Add, Text, w250 Center vResultText,
Gui, Result:Font, s10 bold
Gui, Result:Add, Text, Section,
Gui, Result:Add, Button, ys w200 h30 gShowMain 0x200 Center, OK


;; 3rd UI: Info
Gui, Info:Font, s10 bold
Gui, Info:Add, Text, w280 Section Center, %ScriptTitle% %ScriptVersion%
Gui, Info:Font, s10 norm
Gui, Info:Add, Text, w280 y+2 Center, %ScriptDescription%
Gui, Info:Add, Button, w50 ys y15 Center gShowMain, Back
Gui, Info:Add, text, xs w350 0x10    
Gui, Info:Font, s10 bold
Gui, Info:Add, Text, w350 Center xs, Help
Gui, Info:Font, s8 norm
Gui, Info:Add, Text, w350 xs Section, %IntroHelp%
Gui, Info:Font, s9 bold
Gui, Info:Add, Text, xs, Usage
Gui, Info:Font, s8 norm
Gui, Info:Add, Text, w350 xs Section, %UsageHelp%
Gui, Info:Font, s9 bold
Gui, Info:Add, Text, xs, %DelayHeader%
Gui, Info:Font, s8 norm
Gui, Info:Add, Text, w350 xs Section, %DelayHelp%
Gui, Info:Font, s9 bold
Gui, Info:Add, Text, xs, %RepetitionHeader%
Gui, Info:Font, s8 norm
Gui, Info:Add, Text, w350 xs Section, %RepetitionHelp%
Gui, Info:Add, Text, w350 xs Section, %StartBattleHelp%
Gui, Info:Add, text, xs w350 0x10
Gui, Info:Font, s10 bold
Gui, Info:Add, Text, w350 Center xs, About
Gui, Info:Font, s8 norm
Gui, Info:Add, Text, w280 xs Section, %ScriptHelp%
Gui, Info:Add, Button, w50 ys Center gGoToSite, Site
Gui, Info:Add, Text, xs

; Show initial UI (Main)
Gui, Main:Default
Gui, Main:Show, xCenter y150 AutoSize, %ScriptTitle%

return


;;; Labels

ShowMain:
ShowRunning:
ShowResult:
ShowInfo:
    Gui,+LastFound
    WinGetPos,x,y
    targetGui := StrReplace(A_ThisLabel, "Show")
    Gui, %targetGui%:Show, x%x% y%y%, %ScriptTitle%
    Loop, Parse, AllGui, |
        if (A_LoopField != targetGui){
            Gui, %A_LoopField%:Hide
        }
return

InfoTooltip:
    message := ""
    if (A_GuiControl="SettingsButton"){
        message := "Comming soon"
    }
    ToolTip, Button '%A_GuiControl%' clicked.`n`n%message%
    SetTimer, RemoveToolTip, -5000
return

RemoveToolTip:
    ToolTip
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
	GuiControlGet,MinuteValue,,EditMinute
	GuiControlGet,SecondValue,,EditSecond
    GuiControlGet,BattlesValue,,EditBattles
	IniWrite, %MinuteValue%, %SettingsFilePath%, %SettingsSection%, minute
    IniWrite, %SecondValue%, %SettingsFilePath%, %SettingsSection%, second
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
	GuiControl,,UpDownMinute,%MinuteValue%
	GuiControl,,UpDownSecond,%SecondValue%
    GuiControl,,UpDownBattles,%BattlesValue%
return

SettingChangedByUpDown:
	GuiControlGet,MinuteValue,,UpDownMinute
	GuiControlGet,SecondValue,,UpDownSecond
    GuiControlGet,BattlesValue,,UpDownBattles
	IniWrite, %MinuteValue%, %SettingsFilePath%, %SettingsSection%, minute
    IniWrite, %SecondValue%, %SettingsFilePath%, %SettingsSection%, second
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
	GuiControl,,EditMinute,%UpDownMinute%
	GuiControl,,EditSecond,%UpDownSecond%
    GuiControl,,EditBattles,%BattlesValue%
return  

SettingChangedBySelector:
	GuiControlGet,StageValue,,StageSelector
	GuiControlGet,BoostValue,,BoostSelector
    GuiControlGet,StarValue,,StarSelector
    IniWrite, %StageValue%, %SettingsFilePath%, %SettingsSection%, stage
    IniWrite, %BoostValue%, %SettingsFilePath%, %SettingsSection%, boost
    IniWrite, %StarValue%, %SettingsFilePath%, %SettingsSection%, star
    CalculatedRepetitions := CalculatorData[StageValue][BoostValue][StarValue]
    GuiControl,, CalculatedRepetitions, %CalculatedRepetitions%
return
    
SettingChangedByTab:
	GuiControlGet,TagValue,,TabSelector
    IniWrite, %TagValue%, %SettingsFilePath%, %SettingsSection%, tab
    Settings.tag := TagValue
return

SettingChangedOnFinish:
    Gui, submit, nohide
    GuiControlGet, OnFinishValue,,OnFinishSelector
    IniWrite, %OnFinishValue%, %SettingsFilePath%, %SettingsSection%, onFinish
    Settings.onFinish := OnFinishValue
return

Start:
    if !isDebug && !WinExist(RaidWinTitle){
        MsgBox, 48, %ScriptTitle%, %NoRunningGameError%
        return
    }
    
    StartTime := A_TickCount
    Gui, Submit
    GoSub ShowRunning

    isRunning := true
    repetitions := (TabSelector = 1) ? BattlesValue : (TabSelector = 2) ? CalculatedRepetitions : -1
    isInfinite := (repetitions = -1)

    waitSeconds := SecondValue + ( MinuteValue * 60 )
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
            GuiControl, Running:, MultiBattleProgress, %currentProgress2%
            GuiControl, Running:, MultiBattleStatus, %currentRepetition% / %repetitions% battles
        }else{
            GuiControl, Running:, MultiBattleProgress, 100
            GuiControl, Running:, MultiBattleStatus, %currentRepetition% battles
        }
        
        WinGetActiveTitle, PreviouslyActive
        WinActivate, %RaidWinTitle%
        ;sleep 100
        ControlSend, , {Enter}, %RaidWinTitle%
        ;sleep 100
        ControlSend, , r, %RaidWinTitle%
        sleep 100
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
            GuiControl, Running:, CurrentBattleStatus, %currentSecond% / %waitSeconds% seconds  
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
    
return

ShowResultSuccess:
ShowResultCanceled:
ShowResultInterrupted:
    isRunning := false
    
    MultiBattleDuration := (A_TickCount - StartTime) / 1000
    date = 2000 ;any year above 1600
    date += Floor(MultiBattleDuration), SECONDS
    FormatTime, formattedDuration, %date%, mm:ss
    
    noActivateFlag := ""
    
    if (A_ThisLabel = "ShowResultSuccess"){
        TrayTip, %ScriptTitle%, %ResultMessageSuccess%, 20, 17
        GuiControl, Result:, ResultHeader, %ResultHeaderSuccess%
        GuiControl, Result:, ResultMessage, %ResultMessageSuccess%
        
        if (Settings.onFinish = 3 ){
            WinGetActiveTitle, CurrentlyActive
            noActivateFlag := CurrentlyActive != ScriptTitle ? "NoActivate" : ""
        }
        else if (Settings.onFinish = 1){
            WinActivate, %RaidWinTitle%
        }
    }
    else if (A_ThisLabel = "ShowResultCanceled"){
        TrayTip, %ScriptTitle%, %ResultMessageCanceled%, 20, 17
        ;GuiControl, Result:, ResultHeader, +cDA4F49
        GuiControl, Result:, ResultHeader, %ResultHeaderCanceled%
        GuiControl, Result:, ResultMessage, %ResultMessageCanceled%
    }
    else{
        TrayTip, %ScriptTitle%, %ResultMessageInterrupted%, 20, 17
        GuiControl, Result:, ResultHeader, %ResultHeaderInterrupted%
        GuiControl, Result:, ResultMessage, %ResultMessageInterrupted%
    }
    
    ;GuiControl, Result:, MultiBattleOverview, %overview%
    formattedBattles := (A_ThisLabel = "ShowResultSuccess") ? currentRepetition : currentRepetition " of " repetitions
    GuiControl, Result:, ResultText, % formattedBattles " battles in " formattedDuration
    
    Gui,+LastFound
    WinGetPos,x,y
    Gui, Result:Show, x%x% y%y% %noActivateFlag%, %ScriptTitle%
    Loop, Parse, AllGui, |
        if (A_LoopField != "Result"){
            Gui, %A_LoopField%:Hide
        }
return


GuiClose:
    Gui, Submit
    ; Following values need to be manually stored, as can be changed manually
    IniWrite, %MinuteValue%, %SettingsFilePath%, %SettingsSection%, minute
    IniWrite, %SecondValue%, %SettingsFilePath%, %SettingsSection%, second
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
    
    Loop, Parse, AllGui, |
        Gui, %A_LoopField%:Destroy
    ExitApp
