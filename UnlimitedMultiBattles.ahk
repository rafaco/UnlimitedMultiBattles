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


;;; Auto-execute section
    #NoEnv                          ; Recommended for performance and compatibility with future AutoHotkey releases.
    ;#Warn                          ; Enable warnings to assist with detecting common errors.
    SendMode Input                  ; Recommended for new scripts due to its superior speed and reliability.
    SetWorkingDir %A_ScriptDir%     ; Ensures a consistent starting directory.
    #SingleInstance Force           ; Only one instance
    #MaxThreadsPerHotkey 1          ; Only one thread
    SetTitleMatchMode 3             ; Exact title match

    ;; Metadata
    ScriptVersion := "v1.0.2"
    ScriptTitle := "UnlimitedMultiBattles"
    ScriptDescription := "This application allows unlimited auto battles on official 'Raid: Shadow Legends' for Windows."
    ProjectDescription := "This is an open source project, license under Apache 2.0 and it's sources are published at GitHub. Find out more at our repository."
    ScriptSite := "https://github.com/rafaco/UnlimitedMultiBattles"


    ;; Constants
    isDebug := false
    AllGuis = Main|Running|Result|Help|About
    RaidWinTitle := "Raid: Shadow Legends"
    SettingsFilePath := A_AppData . "/" . ScriptTitle . ".ini"
    SettingsFilePathOld := A_ScriptDir . "/" . ScriptTitle . ".ini"
    RaidFilePath := A_AppData . "\..\Local" . "\Plarium\PlariumPlay\PlariumPlay.exe"
    SettingsSection := "SettingsSection"
    DefaultSettings := { minute: 0, second: 25, battles: 10, tab: 1, stage: 1, boost: 3, star: 1, onFinish: 3 }
    InfiniteSymbol := Chr(0x221E)
    StarSymbol := Chr(0x2605)
    TCS_FIXEDWIDTH := 0x0400
    TCM_SETITEMSIZE := 0x1329
    Brutal12_3 := [ [6, 19, 47, 104, 223, 465], [5, 16, 39, 87, 186, 388], [3, 10, 24, 52, 112, 233], [3, 8, 20, 44, 93, 194]]
    Brutal12_6 := [ [6, 19, 46, 103, 220, 457], [5, 16, 39, 86, 183, 381], [3, 10, 23, 52, 110, 229], [3, 8, 20, 43, 92, 191]]
    CalculatorData := [ Brutal12_3, Brutal12_6 ]


    ;; Texts
    TeamHeader := "1. Prepare your team"
    BattlesHeader := "2. Select number of battles"
    TimeHeader := "3. Select time between battles"
    StartHeader := "4. Start"
    StartButton := "Start`nMulti-Battle"

    TabOptions = Manual|Max out|Infinite
    StageOptions = Brutal 12-3|Brutal 12-6
    BoostOptions := "No Boost|Raid Boost|XP Boost|Both Boosts"
    StarOptions = 1%StarSymbol%: Level 1-10|2%StarSymbol%: Level 1-20|3%StarSymbol%: Level 1-30|4%StarSymbol%: Level 1-40|5%StarSymbol%: Level 1-50|6%StarSymbol%: Level 1-60

    InfoTeam := "Open the game, select a stage and prepare your team. Don't press 'Play' and come back."
    InfoBattles := "Select how many times you want to play the stage. In order to avoid wasting your precious energy, you have three available modes: you can run it INFINITELY, enter a MANUAL number or use our handy CALCULATOR to know how many runs to max out your level 1 champions."
    InfoStart := "When ready, just press 'Start Multi-Battle' and lay back while we farm for you. Cancel it at any time by pressing 'Stop'."
    InfoTime := "Enter how many seconds you want us to wait between each replay. It depends on your current team speed for the stage you are in. Use your longer run time plus a small margin for the loading screens."

    NoRunningGameMessage := "You have to open the game and select your team before start."
    UnableToOpenGameMessage := "Unable to open the game from the standard installation folder.`n`nYou have to open it manually."
    UnableToSendKeysToGameMessage := "Unable to send keys to the game.`n`nThe game is running as admin but this script isn't. Reopen the game as not admin or reopen this script as admin.`n`nDo you want to run this script as Administrator?"
    RunningHeader := "Running..."
    RunningOnFinishMessage := "On finish:"
    RunningOnFinishOptions = Pop up game window|Pop up results window|Do nothing
    StopButton := "Cancel"

    ResultHeaderSuccess := "Completed!"
    ResultHeaderCanceled := "Cancelled"
    ResultHeaderInterrupted := "Interrupted"
    ResultMessageSuccess := "Multi-Battle finished successfuly"
    ResultMessageCanceled := "Multi-Battle canceled by user"
    ResultMessageInterrupted := "Multi-Battle interrupted, game closed"

        
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
    ; Delete old setting file (used on versions 1.0.1)
    If (FileExist(SettingsFilePathOld)){
        FileDelete, %SettingsFilePathOld%
    }

    ; Prepare selections
    selectedTab := Settings.tab
    selectedStage := Settings.stage
    selectedBoost := Settings.boost
    selectedStar := Settings.star
    selectedOnFinish := Settings.onFinish
    CalculatedRepetitions := CalculatorData[selectedStage][selectedBoost][selectedStar]

    ;; Load Menus and Icon
    Menu, Tray, Icon, images\icon.ico
    Menu, InfoMenu, Add, Help, MenuHandler
    Menu, InfoMenu, Add, About, MenuHandler
    infoLabel := "&Info    "
    Menu, MainMenuBar, Add, %infoLabel%, :InfoMenu, Right
    
    ; Load Main GUI
    Gui, Main:Default
    Gui, Main:Menu, MainMenuBar

    Gui, Main:Font, s10 bold
    Gui, Main:Add, GroupBox, hWndhGrp3 w350 h65 Section, %TeamHeader%
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Text, xp+10 yp+20 w270, %InfoTeam%
    Gui, Main:Add, Button, w50 xp+280 yp-5 Center gGoToGame vTeamButton, Open`nGame
    Gui, Main:Font, s2
    Gui, Main:Add, Text, xs,
    Gui, Main:Font, s10 bold

    Gui Main:Add, GroupBox, hWndhGrp w350 h125, %BattlesHeader%
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Tab3, hwndHTAB xp+10 yp+20 w330 h95 +%TCS_FIXEDWIDTH% vTabSelector gOnTabChanged Choose%selectedTab% AltSubmit, %TabOptions%
    SendMessage, TCM_SETITEMSIZE, 0, (330/3)+20, , ahk_id %HTAB%
    DllCall("SetWindowPos", "Ptr", hGrp, "Ptr", HTab, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x3)
    WinSet Redraw,, ahk_id %HTab%
    Gui, Main:Add, Text, w79 Section,
    Gui, Main:Font, s20 
    Gui, Main:Add, Edit, ys+10 w65 h35 Right gOnBattleChangedByEdit vEditBattles +Limit3 +Number, % Settings.battles
    Gui, Main:Add, UpDown, ys Range1-999 vUpDownBattles gOnBattleChangedByUpDown, % Settings.battles
    Gui, Main:Font, s14
    Gui, Main:Add, Text, xp+80 ys+20, battles

    Gui, Main:Tab, 2
    Gui, Main:Font, s10
    Gui, Main:Add, DropDownList, Section w90 vStageSelector gOnCalculatorChanged Choose%selectedStage% AltSubmit, %StageOptions%
    Gui, Main:Add, DropDownList, ys xp+95 w97 vBoostSelector gOnCalculatorChanged Choose%selectedBoost% AltSubmit, %BoostOptions%
    Gui, Main:Add, DropDownList, ys xp+102 w110 vStarSelector gOnCalculatorChanged Choose%selectedStar% AltSubmit, %StarOptions%
    Gui, Main:Add, Text, w80 xs Section,
    Gui, Main:Font, s20 
    Gui, Main:Add, Text, w50 right ys vCalculatedRepetitions, %CalculatedRepetitions%
    Gui, Main:Font, s14
    Gui, Main:Add, Text, w100 ys+7, battles

    Gui, Main:Tab, 3
    Gui, Main:Font, s10
    Gui, Main:Add, text, w350 h5 Section, 
    Gui, Main:Add, Text, w75 xs Section,
    Gui, Main:Font, s45 
    Gui, Main:Add, Text, w50 h35 ys Right 0x200, % InfiniteSymbol
    Gui, Main:Font, s14
    Gui, Main:Add, Text, w100 ys+7, battles
    Gui, Main:Tab

    Gui, Main:Font, s2
    Gui, Main:Add, Text, x10 Section,
    Gui, Main:Font, s10 bold
    Gui, Main:Add, GroupBox, hWndhGrp2 w350 h70, %TimeHeader%
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Text, xp+10 yp+25 Section w90,
    Gui, Main:Font, s20 
    Gui, Main:Add, Edit, ys w50 h35 Right gOnTimeChangedByEdit vEditMinute +Limit2 +Number,
    Gui, Main:Add, UpDown, ys Range00-60 vUpDownMinute gOnTimeChangedByUpDown
    Gui, Main:Font, s24 bold
    Gui, Main:Add, Text, ys-3 xp+55, :
    Gui, Main:Font, s20 normal
    Gui, Main:Add, Edit, ys xp+15 w50 h35 Right gOnTimeChangedByEdit vEditSecond +Limit2 +Number,
    Gui, Main:Add, UpDown, ys Range00-59 vUpDownSecond gOnTimeChangedByUpDown
    Gui, Main:Font, s14
    Gui, Main:Add, Text, ys+10, min:sec
    GuiControl, , UpDownMinute, % Settings.minute
    GuiControl, , EditMinute, % Settings.minute
    GuiControl, , UpDownSecond, % Settings.second
    GuiControl, , EditSecond, % Settings.second

    Gui, Main:Font, s10 bold
    Gui, Main:Add, Text, w230 x+10 y+20 xs Section,
    Gui, Main:Add, Button, ys w100 0x200 Center gStart, %StartButton%

    ; Load Running GUI
    Gui, Running:Font, s12 bold
    Gui, Running:Add, Text, w250 Center, % RunningHeader
    Gui, Running:Font, s10 normal
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
    Gui, Running:Add, DropDownList, ys w175 vOnFinishSelector gOnFinishChanged Choose%selectedOnFinish% AltSubmit, %RunningOnFinishOptions%
    Gui, Running:Font, s3 normal
    Gui, Running:Add, Text, xs Section,
    Gui, Running:Font, s10 bold
    Gui, Running:Add, Text, xs Section,
    Gui, Running:Add, Button, ys w200 h30 gShowResultCanceled 0x200 Center, %StopButton%

    ; Load Result GUI 
    Gui, Result:Font, s12 bold
    Gui, Result:Add, Text, w250 Center vResultHeader,
    Gui, Result:Font, s10 normal
    Gui, Result:Add, Text, w250 yp+20 Center vResultMessage,
    Gui, Result:Font, s12 normal
    Gui, Result:Add, Text, w250 Center vResultText,
    Gui, Result:Font, s10 bold
    Gui, Result:Add, Text, Section,
    Gui, Result:Add, Button, ys w200 h30 gShowMain 0x200 Center, OK

    ; Load Help GUI
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, w350 Center Section, Help
    Gui, Help:Font, s10 normal
    Gui, Help:Add, Text, w350 xs, %ScriptDescription%
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, xs, %TeamHeader%
    Gui, Help:Font, s10 norm
    Gui, Help:Add, Text, w350 xs Section, %InfoTeam%
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, xs, %BattlesHeader%
    Gui, Help:Font, s10 norm
    Gui, Help:Add, Text, w350 xs Section, %InfoBattles%
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, xs, %TimeHeader%
    Gui, Help:Font, s10 norm
    Gui, Help:Add, Text, w350 xs Section, %InfoTime%
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, xs, %StartHeader%
    Gui, Help:Font, s10 norm
    Gui, Help:Add, Text, w350 xs Section, %InfoStart%
    Gui, Help:Add, Text, w350 xs Section,

    ; Load About GUI
    Gui, About:Font, s10 bold
    Gui, About:Add, Text, w350 h35 xp yp 0x200 BackgroundTrans Section Center, %ScriptTitle% %ScriptVersion%
    Gui, About:Font, s10 norm
    Gui, About:Add, Text, w350 xs Section, %ProjectDescription%
    Gui, About:Add, Button, Section w100 h30 gShowMain 0x200 Center, Back
    Gui, About:Add, Text, w120 ys Section,
    Gui, About:Add, Button, ys w100 h30 gGoToSite 0x200 Center, Go to GitHub
    
    ; Show initial UI (Main)
    Gui, Main:Show, xCenter y150 AutoSize, %ScriptTitle%

return ; End of auto-execute section


;;; Labels
;; Navigation labels

ShowMain:
ShowHelp:
ShowAbout:
ShowRunning:
    Gui,+LastFound
    WinGetPos,x,y
    targetGui := StrReplace(A_ThisLabel, "Show")
    Gui, %targetGui%:Show, x%x% y%y%, %ScriptTitle%
    HideAllGuisBut(AllGuis, targetGui)
return

MenuHandler:
    ;MsgBox, You selected "%A_ThisMenuItem%" in menu "%A_ThisMenu%".
    if (A_ThisMenuItem = "Help"){
        GoSub ShowHelp
    }
    else if (A_ThisMenuItem = "About"){
        GoSub ShowAbout
    }
return

MainGuiClose:
    DestroyAllGuis()  
ExitApp

ResultGuiClose:
HelpGuiClose:
AboutGuiClose:
    GoSub ShowMain
return

RunningGuiClose:
    GoSub ShowResultCanceled
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
            MsgBox, 48, %ScriptTitle%, %UnableToOpenGameMessage%
            return
        }
    }
return

RunScriptAsAdmin:
    if A_IsAdmin{
        MsgBox, % "Skipped: this script is already running as administrator"
        GoSub ShowMain
        return
    }
    Run *RunAs "%A_ScriptFullPath%"
    ExitApp
return


;; OnChange labels

OnTabChanged:
	GuiControlGet,TabValue,,TabSelector
    IniWrite, %TabValue%, %SettingsFilePath%, %SettingsSection%, tab
    Settings.tab := TabValue
return

OnBattleChangedByEdit:
    Gui, Submit, NoHide
    GuiControlGet,BattlesValue,,EditBattles
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
    Settings.battle := BattlesValue
    GuiControl,,UpDownBattles,%BattlesValue%
return

OnBattleChangedByUpDown:
    GuiControlGet,BattlesValue,,UpDownBattles
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
    Settings.battle := BattlesValue
    GuiControl,,EditBattles,%BattlesValue%
return  

OnCalculatorChanged:
	GuiControlGet,StageValue,,StageSelector
	GuiControlGet,BoostValue,,BoostSelector
    GuiControlGet,StarValue,,StarSelector
    IniWrite, %StageValue%, %SettingsFilePath%, %SettingsSection%, stage
    IniWrite, %BoostValue%, %SettingsFilePath%, %SettingsSection%, boost
    IniWrite, %StarValue%, %SettingsFilePath%, %SettingsSection%, star
    Settings.stage := BattlesValue
    Settings.boost := BoostValue
    Settings.star := StarValue
    CalculatedRepetitions := CalculatorData[StageValue][BoostValue][StarValue]
    GuiControl,, CalculatedRepetitions, %CalculatedRepetitions%
return

OnTimeChangedByUpDown:
    Gui, Submit, NoHide
    GuiControlGet,MinuteValue,,UpDownMinute
    GuiControlGet,SecondValue,,UpDownSecond
    SetFormat, Float, 02.0
    MinuteValue += 0.0
    SecondValue += 0.0
    IniWrite, %MinuteValue%, %SettingsFilePath%, %SettingsSection%, minute
    IniWrite, %SecondValue%, %SettingsFilePath%, %SettingsSection%, second
    Settings.minute := MinuteValue
    Settings.second := SecondValue
    GuiControl, , EditMinute, %MinuteValue%
    GuiControl, , EditSecond, %SecondValue%
Return

OnTimeChangedByEdit:
    Gui, Submit, NoHide
    GuiControlGet,MinuteValue,,EditMinute
    GuiControlGet,SecondValue,,EditSecond
    SetFormat, Float, 02.0
    MinuteValue += 0.0
    SecondValue += 0.0
    IniWrite, %MinuteValue%, %SettingsFilePath%, %SettingsSection%, minute
    IniWrite, %SecondValue%, %SettingsFilePath%, %SettingsSection%, second
    Settings.minute := MinuteValue
    Settings.second := SecondValue
    GuiControl,,UpDownMinute,%MinuteValue%
    GuiControl,,UpDownSecond,%SecondValue%
return

OnFinishChanged:
    Gui, submit, nohide
    GuiControlGet, OnFinishValue,,OnFinishSelector
    IniWrite, %OnFinishValue%, %SettingsFilePath%, %SettingsSection%, onFinish
    Settings.onFinish := OnFinishValue
return


;; Core logic labels

Start:
    if !isDebug && !WinExist(RaidWinTitle){
        MsgBox, 48, %ScriptTitle%, %NoRunningGameMessage%
        return
    }
    
    StartTime := A_TickCount
    Gui, Submit
    GoSub ShowRunning

    isRunning := true
    repetitions := (TabSelector = 1) ? BattlesValue : (TabSelector = 2) ? CalculatedRepetitions : -1
    isInfinite := (repetitions = -1)

    waitSeconds := SecondValue + ( MinuteValue * 60 )
    waitSecondsFormatted := TimeFormatter(waitSeconds)
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
        ;sleep 25
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
            currentTimeFormatted := TimeFormatter(currentSecond)
            GuiControl, Running:, CurrentBattleStatus, %currentTimeFormatted% / %waitSecondsFormatted%  
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
    MultiBattleDuration := (A_TickCount - StartTime) / 1000
    isRunning := false
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
    GuiControl, Result:, ResultText, % formattedBattles " battles in " TimeFormatter(MultiBattleDuration)
    
    Gui,+LastFound
    WinGetPos,x,y
    Gui, Result:Show, x%x% y%y% %noActivateFlag%, %ScriptTitle%
    HideAllGuisBut(AllGuis, "Result")
return


;;; Functions

TimeFormatter(seconds){
    date = 2000 ;any year above 1600
    date += Floor(seconds), SECONDS
    FormatTime, formattedDate, %date%, mm:ss
    return formattedDate
}

CanSendKeysToWin(WinTitle)
{
    static WM_KEYDOWN=0x100, WM_KEYUP=0x101, vk_to_use=7
    ; Test whether we can send keystrokes to this window.
    ; Use a virtual keycode which is unlikely to do anything:
    PostMessage, WM_KEYDOWN, vk_to_use, 0,, %WinTitle%
    if !ErrorLevel
    {   ; Seems best to post key-up, in case the window is keeping track.
        PostMessage, WM_KEYUP, vk_to_use, 0xC0000000,, %WinTitle%
        return true
    }
    return false
}

HideAllGuisBut(list, excluded){
    Loop, Parse, list, |
        if (A_LoopField != excluded){
            Gui, %A_LoopField%:Hide
        }
    return
}

DestroyAllGuis(){
    Loop, Parse, AllGuis, |
        Gui, %A_LoopField%:Destroy
    return
}