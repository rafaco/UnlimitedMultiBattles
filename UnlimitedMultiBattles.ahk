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

    #Include, data/Tables.ahk
    
    ;; Metadata
    ScriptVersion := "v1.0.5"
    ScriptTitle := "UnlimitedMultiBattles"
    ScriptDescription := "This application allows unlimited auto battles on official 'Raid: Shadow Legends' for Windows."
    ProjectDescription := "This project is open source project and it's licensed under Apache 2.0. Our source code and additional informations can be found at our Github repository.`n"
    ScriptSite := "https://github.com/rafaco/UnlimitedMultiBattles"


    ;; Constants
    isDebug := false
    AllGuis = Main|Running|Result|Help|About
    RaidWinTitle := "Raid: Shadow Legends"
    LocalFolder := A_AppData . "/" . ScriptTitle
    SettingsFileName := ScriptTitle . ".ini"
    XpDataFileName := "XpData.csv"
    CampaignDataFileName := "CampaignData.csv"
    SettingsFilePath := LocalFolder . "/" . SettingsFileName
    SettingsFilePathOld := A_ScriptDir . "/" . ScriptTitle . ".ini"
    SettingsFilePathOld2 := A_AppData . "/" . ScriptTitle . ".ini"
    RaidFilePath := A_AppData . "\..\Local" . "\Plarium\PlariumPlay\PlariumPlay.exe"
    SettingsSection := "SettingsSection"
    DefaultSettings := { minute: 00, second: 25, battles: 10, tab: 2, boost: 3, difficulty: 3, map: 12, stage: 3, rank: 2, level: 1, onFinish: 1 }
    InfiniteSymbol := Chr(0x221E)
    StarSymbol := Chr(0x2605)
    COLOR_GRAY := "c808080"
    SS_CENTERIMAGE := 0x200
    TCS_FIXEDWIDTH := 0x0400
    TCM_SETITEMSIZE := 0x1329
    PBS_MARQUEE := 0x8
    PBM_SETMARQUEE := 0x40A

    ;; Texts
    TeamHeader := "1. Prepare your team"
    BattlesHeader := "2. Select number of battles"
    TimeHeader := "3. Select battle duration"
    StartHeader := "4. Start"
    StartButton := "Start`nMulti-Battle"

    TabOptions = Manual|Calculated|Infinite
    ;StageOptions = Brutal 12-3|Brutal 12-6
    BoostOptions := "No Boost|Raid Boost|XP Boost|Both Boosts"
    DifficultyOptions := "Normal|Hard|Brutal"
    MapOptions := GenerateNumericOptions(12)
    StageOptions := GenerateNumericOptions(7)
    RankOptions := GenerateRankOptions()

    InfoTeam := "Open the game, select a stage and prepare your team. Don't press 'Play' and come back."
    InfoBattles := "Select how many times you want to play the stage. In order to avoid wasting your precious energy, you have three available modes: you can run it INFINITELY, enter a MANUAL number or use our handy CALCULATOR to know how many runs to max out your champions in a campaign stage."
    InfoStart := "When ready, just press 'Start Multi-Battle' and lay back while we farm for you. Cancel it at any time by pressing 'Stop'."
    InfoTime := "Enter how many seconds you want us to wait between each replay. It depends on your current team speed for the stage you are in. Use your longer run time plus a small margin for the loading screens."

    NoRunningGameMessage := "You have to open the game and select your team before start."
    UnableToOpenGameMessage := "Unable to open the game from the standard installation folder.`n`nYou have to open it manually."
    UnableToSendKeysToGameMessage := "Unable to Multi-Battle: The game is running as admin and this script isn't.`n`nYou can close the game and re-opening it without admin. You can also run this script as admin.`n`nDo you want to run this script as Administrator now?"
    RunningHeader = Multi-battling
    RunningTimeLeftMessage := "Time left: " 
    RunningOnFinishMessage = On finish:
    RunningOnFinishOptions = Bring game to front|Bring this window to front|Don't disturb me
    RunningOnFinishCheckbox = Sleep computer
    StopButton = Cancel

    ResultHeaderSuccess = Completed!
    ResultHeaderCanceled = Cancelled
    ResultHeaderInterrupted = Interrupted
    ResultMessageSuccess = Multi-Battle finished successfuly
    ResultMessageCanceled = Multi-Battle canceled by user
    ResultMessageInterrupted = Multi-Battle interrupted, game closed

    ;; Init LOGIC
    filecreatedir, %LocalFolder%
    InitSettings()
    InitCalculator()


    ;; Load VIEW
    ;Menu, Tray, Icon, images\icon.ico
    Menu, InfoMenu, Add, Help, MenuHandler
    Menu, InfoMenu, Add, About, MenuHandler
    infoLabel := "&Info    "
    Menu, MainMenuBar, Add, %infoLabel%, :InfoMenu, Right
    
    ; Load Main GUI
    Gui, Main:Default
    Gui, Main:Menu, MainMenuBar

    Gui, Main:Font, s10 bold
    Gui, Main:Add, GroupBox,  w350 h65 Section, %TeamHeader%
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Text, xp+10 yp+20 w270, %InfoTeam%
    Gui, Main:Add, Button, w50 xp+280 yp-5 Center gGoToGame vTeamButton, Open`nGame
    Gui, Main:Font, s2
    Gui, Main:Add, Text, xs,
    Gui, Main:Font, s10 bold

    groupBoxHeight := 187
    tabContentHeight := groupBoxHeight - 30
    Gui, Main:Add, Text, w350 xs Section, % "  " . BattlesHeader
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Tab3, hwndHTAB xs yp+20 w350 h%tabContentHeight% +%TCS_FIXEDWIDTH% vTabSelector gOnTabChanged Choose%selectedTab% AltSubmit, %TabOptions%
    SendMessage, TCM_SETITEMSIZE, 0, (350/3)+20, , ahk_id %HTAB%
    DllCall("SetWindowPos", "Ptr", hGrp, "Ptr", HTab, "Int", 0, "Int", 0, "Int", 0, "Int", 0, "UInt", 0x3)
    WinSet Redraw,, ahk_id %HTab%
    Gui, Main:Add, Text, w330 h50 Section Center %SS_CENTERIMAGE%, Enter any number of battles
    Gui, Main:Add, Text, w70 xs Section,
    Gui, Main:Font, s20 
    Gui, Main:Add, Edit, ys+10 w65 h35 Right gOnBattleChangedByEdit vEditBattles +Limit3 +Number, % Settings.battles
    Gui, Main:Add, UpDown, ys Range1-999 vUpDownBattles gOnBattleChangedByUpDown, % Settings.battles
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, xp+80 ys+20, battles

    Gui, Main:Tab, 2
    Gui, Main:Font, s1
    Gui, Main:Add, Text, 
    Gui, Main:Font, s10 normal
    Gui, Main:Add, DropDownList, Section w80 vRankSelector gOnCalculatorChanged Choose%selectedRank% AltSubmit, %RankOptions%
    Gui, Main:Add, Text, ys h25 %SS_CENTERIMAGE% Center, champion from lvl
    Gui, Main:Add, DropDownList, ys w40 vLevelSelector gOnCalculatorChanged Choose%selectedLevel% AltSubmit, %initialLevelOptions%
    Gui, Main:Add, Text, ys h25 %SS_CENTERIMAGE% Center, to Max.
    Gui, Main:Add, DropDownList, xs Section w65 vDifficultySelector gOnCalculatorChanged Choose%selectedDifficulty% AltSubmit, %DifficultyOptions%
    Gui, Main:Add, DropDownList, ys w40 vMapSelector gOnCalculatorChanged Choose%selectedMap% AltSubmit, %MapOptions%
    Gui, Main:Add, DropDownList, ys w35 vStageSelector gOnCalculatorChanged Choose%selectedStage% AltSubmit, %StageOptions%
    Gui, Main:Add, Text, ys h25 %SS_CENTERIMAGE% Center, with
    Gui, Main:Add, DropDownList, ys w97 vBoostSelector gOnCalculatorChanged Choose%selectedBoost% AltSubmit, %BoostOptions%
    Gui, Main:Add, Text, xs Section w70,
    Gui, Main:Font, s20 
    Gui, Main:Add, Text, w58 right ys vCalculatedRepetitions, % calculatedResults.repetitions
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, w100 ys+7, battles
    Gui, Main:Font, s10 %COLOR_GRAY% normal
    Gui, Main:Add, Text, w330 xs yp+25 Section Center vCalculatedExtra,

    Gui, Main:Tab, 3
    Gui, Main:Font
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Text, w330 h60 Section Center %SS_CENTERIMAGE%, Run infinetly till your stop us.
    Gui, Main:Add, Text, w75 xs Section,
    Gui, Main:Font, s45 
    Gui, Main:Add, Text, w50 h35 ys Right %SS_CENTERIMAGE%, % InfiniteSymbol
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, w100 ys+7, % " battles"
    Gui, Main:Tab

    Gui, Main:Font, s2 bold
    Gui, Main:Add, Text, x10 Section,
    Gui, Main:Font, s10 bold
    Gui, Main:Add, Text, w350 xs Section, % "  " . TimeHeader
    Gui, Main:Add, Progress, xs w350 h80 BackgroundDBDBDB Disabled
    Gui, Main:Add, Progress, xp+1 yp+1 w349 h78 BackgroundWhite Disabled
    Gui, Main:Add, Text, xp+5 yp+15 Section BackgroundTrans w60 Right,
    Gui, Main:Font, s20 normal
    Gui, Main:Add, Edit, ys w50 h35 Right gOnTimeChangedByEdit vEditMinute +Limit2 +Number,
    Gui, Main:Add, UpDown, ys Range00-60 vUpDownMinute gOnTimeChangedByUpDown,
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, ys+7 BackgroundTrans, min.
    Gui, Main:Font, s20 normal
    Gui, Main:Add, Edit, ys w50 h35 Right gOnTimeChangedByEdit vEditSecond +Limit2 +Number,
    Gui, Main:Add, UpDown, ys Range00-59 vUpDownSecond gOnTimeChangedByUpDown,
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, ys+7 BackgroundTrans, sec.
    Gui, Main:Font, s10 %COLOR_GRAY% normal
    Gui, Main:Add, Text, h20 w330 xs Section Center %SS_CENTERIMAGE% BackgroundTrans vCalculatedDuration,

    Gui, Main:Font, s10 %COLOR_GRAY%
    Gui, Main:Add, Text, w230 xs Section Right %SS_CENTERIMAGE% ,
    Gui, Main:Font, s10 bold
    Gui, Main:Add, Button, ys+10 w100 %SS_CENTERIMAGE% Center Default gStart, %StartButton%

    ; Load Running GUI
    Gui, Running:Font, s12 bold
    Gui, Running:Add, Text, w250 Center vMultiBattleHeader, % RunningHeader
    Gui, Running:Font, s10 normal
    Gui, Running:Add, Text, w115 Section, Current battle:
    Gui, Running:Add, Text, ys w120 Right vCurrentBattleStatus,
    Gui, Running:Add, Progress, xs yp+18 w250 h20 -Smooth vCurrentBattleProgress, 0
    Gui, Running:Add, Text, w115 xs Section, All battles:
    Gui, Running:Add, Text, ys w120 Right vMultiBattleStatus,
    Gui, Running:Add, Progress, xs yp+18 w250 h20 HwndhPB2 -Smooth vMultiBattleProgress, 0
    Gui, Running:Add, Text, w117 xs Section vOnFinishMessage, % RunningTimeLeftMessage
    Gui, Running:Add, Text, w117 ys Right vOnFinishMessageValue, -
    Gui, Running:Font, s3 normal
    Gui, Running:Add, Text, xs Section,
    Gui, Running:Font, s10 normal
    Gui, Running:Font, s10 normal
    Gui, Running:Add, Text, w60 h23 xs Section Left %SS_CENTERIMAGE%, % RunningOnFinishMessage
    Gui, Running:Add, DropDownList, ys w175 vOnFinishSelector gOnFinishChanged Choose%selectedOnFinish% AltSubmit, %RunningOnFinishOptions%
    Gui, Running:Add, Checkbox, vOnFinishCheckbox gOnFinishCheckboxChanged, % RunningOnFinishCheckbox
    Gui, Running:Font, s3 normal
    Gui, Running:Add, Text, xs Section,
    Gui, Running:Font, s10 bold
    Gui, Running:Add, Text, xs Section,
    Gui, Running:Add, Button, ys w200 h30 gShowResultCanceled %SS_CENTERIMAGE% Center Default, %StopButton%

    ; Load Result GUI 
    Gui, Result:Font, s12 bold
    Gui, Result:Add, Text, w250 Center vResultHeader,
    Gui, Result:Font, s10 normal
    Gui, Result:Add, Text, w250 yp+20 Center vResultMessage,
    Gui, Result:Font, s12 normal
    Gui, Result:Add, Text, w250 Center vResultText,
    Gui, Result:Font, s10 bold
    Gui, Result:Add, Text, Section,
    Gui, Result:Add, Button, ys w100 h30 gShowMain %SS_CENTERIMAGE% Center Default, Done
    Gui, Result:Add, Button, ys w100 h30 gStart %SS_CENTERIMAGE% Center, Replay
    

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
    Gui, Help:Add, Button, Section w100 h30 gShowMain %SS_CENTERIMAGE% Center Default, Back

    ; Load About GUI
    Gui, About:Font, s10 bold
    Gui, About:Add, Text, w350 h35 xp yp %SS_CENTERIMAGE% BackgroundTrans Section Center, %ScriptTitle% %ScriptVersion%
    Gui, About:Font, s10 norm
    Gui, About:Add, Text, w350 xs Section, %ProjectDescription%
    Gui, About:Add, Button, Section w100 h30 gShowMain %SS_CENTERIMAGE% Center Default, Back
    Gui, About:Add, Text, w120 ys Section,
    Gui, About:Add, Button, ys w100 h30 gGoToSite %SS_CENTERIMAGE% Center, Go to GitHub
    
    
    ; Init loaded UIs
    InitTimeComponents()    
    FillCalculatedResults(calculatedResults)
    UpdateDuration()
    
    
    ; Show initial UI (Main)
    Gui, Main:Show, xCenter y100 AutoSize, %ScriptTitle%
    mainGuiShown := true
    
return ; End of auto-execute section


;;; Labels
;; Navigation labels

ShowMain:
ShowHelp:
ShowAbout:
ShowRunning:
    Gui,+LastFound
    WinGetPos,x,y
    if (A_ThisLabel="ShowRunning" && A_Gui !="Result"){
        x += 50
        y += 200
    }
    else if (A_ThisLabel="ShowMain"){
        if (A_Gui="Running" || A_Gui="Result"){
            x -= 50
            y -= 200
        }
    }
    targetGui := StrReplace(A_ThisLabel, "Show")
    Gui, %targetGui%:Show, x%x% y%y%, %ScriptTitle%
    HideAllGuisBut(AllGuis, targetGui)
return

MenuHandler:
    if (A_ThisMenuItem = "Help"){
        GoSub ShowHelp
    }
    else if (A_ThisMenuItem = "About"){
        GoSub ShowAbout
    }else{
        MsgBox, No action for "%A_ThisMenuItem%" in menu "%A_ThisMenu%".
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


;; OnChange controls actions

OnTabChanged:
	GuiControlGet,TabValue,,TabSelector
    IniWrite, %TabValue%, %SettingsFilePath%, %SettingsSection%, tab
    Settings.tab := TabValue
    
    UpdateDuration()
return

OnBattleChangedByEdit:
    Gui, Submit, NoHide
    GuiControlGet,BattlesValue,,EditBattles
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
    Settings.battles := BattlesValue
    GuiControl,,UpDownBattles,%BattlesValue%
    FillEstimatedTime(Settings.second, Settings.minute, BattlesValue)
return

OnBattleChangedByUpDown:
    GuiControlGet,BattlesValue,,UpDownBattles
    IniWrite, %BattlesValue%, %SettingsFilePath%, %SettingsSection%, battles
    Settings.battles := BattlesValue
    GuiControl,,EditBattles,%BattlesValue%
    FillEstimatedTime(Settings.second, Settings.minute, BattlesValue)
return  

OnCalculatorChanged:
    GuiControlGet,DifficultyValue,,DifficultySelector
    GuiControlGet,MapValue,,MapSelector
	GuiControlGet,StageValue,,StageSelector
	GuiControlGet,BoostValue,,BoostSelector
    GuiControlGet,RankValue,,RankSelector
    GuiControlGet,LevelValue,,LevelSelector
    
    maxLvlValue := (RankValue*10)-1
    rankedLevelOptions := GenerateNumericOptions(maxLvlValue)
    GuiControl,,LevelSelector, |%rankedLevelOptions%
    if (LevelValue > maxLvlValue){
        LevelValue := 1
    }
    GuiControl, ChooseString, LevelSelector, %LevelValue%
    
    IniWrite, %DifficultyValue%, %SettingsFilePath%, %SettingsSection%, difficulty
    IniWrite, %StageValue%, %SettingsFilePath%, %SettingsSection%, stage
    IniWrite, %MapValue%, %SettingsFilePath%, %SettingsSection%, map
    IniWrite, %BoostValue%, %SettingsFilePath%, %SettingsSection%, boost
    IniWrite, %RankValue%, %SettingsFilePath%, %SettingsSection%, rank
    IniWrite, %LevelValue%, %SettingsFilePath%, %SettingsSection%, level
    Settings.difficulty := DifficultyValue
    Settings.stage := StageValue
    Settings.map := MapValue
    Settings.boost := BoostValue
    Settings.rank := RankValue
    Settings.level := LevelValue
    
    UpdateCalculator()
    UpdateDuration()
return

OnTimeChangedByUpDown:
    if (!mainGuiShown){
        return
    }
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
    
    UpdateDuration()
Return

OnTimeChangedByEdit:
    if (!mainGuiShown){
        return
    }
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
    
    UpdateDuration()
return

OnFinishChanged:
    Gui, submit, nohide
    GuiControlGet, OnFinishValue,,OnFinishSelector
    IniWrite, %OnFinishValue%, %SettingsFilePath%, %SettingsSection%, onFinish
    Settings.onFinish := OnFinishValue
return

OnFinishCheckboxChanged:
    Gui, submit, nohide
    GuiControlGet, OnFinishCheckboxValue,,OnFinishCheckbox
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
    
return


;;; Functions

InitSettings(){
    global
    If (!FileExist(SettingsFilePath)){
        Settings := DefaultSettings
        for key, value in Settings{
            if (key="minute" || key="second"){
                SetFormat, Float, 02.0
                value += 0.0
                Settings[key] := value
            }        
            IniWrite, %value%, %SettingsFilePath%, %SettingsSection%, %key%
        }
    }else{
        Settings := {}
        for key, value in DefaultSettings{
            IniRead, temp, %SettingsFilePath%, %SettingsSection%, %key%
            Settings[key] := temp
        }
    }
    If (FileExist(SettingsFilePathOld)){
        FileDelete, %SettingsFilePathOld%   ;used on versions 1.0.1
    }
    If (FileExist(SettingsFilePathOld2)){
        FileDelete, %SettingsFilePathOld2%  ;used on versions 1.0.2
    }
    selectedTab := Settings.tab
    selectedBoost := Settings.boost
    selectedDifficulty := Settings.difficulty
    selectedMap := Settings.map
    selectedStage := Settings.stage
    selectedRank := Settings.rank
    selectedLevel := Settings.level
    selectedOnFinish := Settings.onFinish
    
    OnFinishCheckboxValue := 0
}

InitCalculator(){
    global
    FileInstall, data\XpData.csv, %LocalFolder%\%XpDataFileName%
    FileInstall, data\CampaignData.csv, %LocalFolder%\%CampaignDataFileName%
    XpData := ReadTable(LocalFolder . "\" . XpDataFileName, {"Headers" : True}, xpColumnNames)
    CampaignData := ReadTable(LocalFolder . "\" . CampaignDataFileName, {"Headers" : True}, campaignColumnNames)
    initialLevelOptions := GenerateNumericOptions((selectedRank*10)-1)
    calculatedResults := CalculateResults(Settings, CampaignData, XpData)
}

InitTimeComponents(){
    global
    GuiControl, , UpDownMinute, % Settings.minute
    GuiControl, , EditMinute, % Settings.minute
    GuiControl, , UpDownSecond, % Settings.second
    GuiControl, , EditSecond, % Settings.second
}

UpdateCalculator(){
    global Settings
    global campaignData
    global xpData
    global calculatedResults
    
    calculatedResults := CalculateResults(Settings, campaignData, xpData)
    FillCalculatedResults(calculatedResults)
}

CalculateResults(Settings, campaignData, xpData){
    rank := Settings.rank
    level := Settings.level
    levelsToMax := ((Settings.rank) * 10) - (Settings.level)
    Loop,%levelsToMax%{
        currentLevel := Settings.level + A_Index - 1
        currentXp := xpData[currentLevel][Settings.rank]
        requiredXP += currentXp
    }
    map := Settings.map
    difficulty := Settings.difficulty
    stage := Settings.stage
    campaignLine := ((Settings.map-1) * 21) + ((Settings.difficulty-1) * 7) + Settings.stage
    stageXp := campaignData[campaignLine]["XP"]
    stageEnergy := campaignData[campaignLine]["Energie"]
    stageSilver := campaignData[campaignLine]["Silver"]
    boost := Settings.boost
    boostOptionsMultiplier := [1, 1.2, 2, 2.2]
    boostedXp := stageXp * boostOptionsMultiplier[Settings.boost]
    championXp := boostedXp/4
    
    repetitions := Floor(requiredXP / championXp) + 1
    energySpent := stageEnergy * repetitions
    silverEarned := stageSilver * repetitions
    result := { repetitions: repetitions, energy: energySpent, silver: silverEarned }
    
    return result
}

FillCalculatedResults(calculatedResults){
    reps := calculatedResults.repetitions        
    GuiControl,, CalculatedRepetitions, %reps%
    extratext := FormatNumber(calculatedResults.energy) . " energy" . "  -->  " . FormatNumber(calculatedResults.silver) . " silver"
    GuiControl,, CalculatedExtra, %extratext%
}

UpdateDuration(){
    global Settings
    global calculatedResults
    if (Settings.tab=1){        ;Manual
        FillEstimatedTime(Settings.second, Settings.minute, Settings.battles)
    } 
    else if (Settings.tab=2){   ;Calculated
        FillEstimatedTime(Settings.second, Settings.minute, calculatedResults.repetitions)
    }
    else {                      ;Infinite
        FillEstimatedTime(Settings.second, Settings.minute, -1)
    }
}
    
FillEstimatedTime(seconds, minutes, repetitions){
    totalSeconds := (seconds + ( minutes * 60 )) * repetitions
    totalMinutes := Floor(totalSeconds / 60)
    isInfinite := (repetitions=-1)
    if (isInfinite){
        text := "Infinite" 
    }
    else if (totalMinutes=0){
        text := "Less than a minute" 
    }
    else if (totalMinutes<60){
        text := totalMinutes . " minutes"
    }
    else{
        totalHours := Floor(totalMinutes / 60)
        additionalMinutes := totalMinutes - (totalHours*60)
        text := totalHours . " hours and " . additionalMinutes . " minutes"
    }
    if (!isInfinite){
        text .= " aprox."
    }
    GuiControl,, CalculatedDuration, %text%
}

GenerateNumericOptions(items){
    Loop,%items%{
        List .= A_Index
        if (A_Index!=items){
            List .= "|"
        }
    }
    return List
}

GenerateRankOptions(){
    StarSymbol := Chr(0x2605)
    ranks := 6
    Loop,%ranks%{
        currentItem := currentItem . StarSymbol
        List .= currentItem
        if (A_Index!=ranks){
            List .= "|"
        }
    }
    return List
}

FormatSeconds(seconds){
    date = 2000 ;any year above 1600
    date += Floor(seconds), SECONDS
    FormatTime, formattedDate, %date%, mm:ss
    return formattedDate
}

FormatNumber(num){
    ; Add thousands searators
    return RegExReplace(num, "\G(?:-?)\d+?(?=(\d{3})+(?:\D|$))", "$0.")
}
    
CanSendKeysToWin(WinTitle){
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