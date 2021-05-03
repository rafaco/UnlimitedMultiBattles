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


;;; Auto-execute section
    #NoEnv                          ; Recommended for performance and compatibility with future AutoHotkey releases.
    ;#Warn                          ; Enable warnings to assist with detecting common errors.
    SendMode Input                  ; Recommended for new scripts due to its superior speed and reliability.
    StringCaseSense On              ; Make string comparisons case sensitive, not sensitives b default
    SetWorkingDir %A_ScriptDir%     ; Ensures a consistent starting directory.
    #SingleInstance Force           ; Only one instance
    #MaxThreadsPerHotkey 1          ; Only one thread
    SetTitleMatchMode 3             ; Exact title match
    SetBatchLines, -1               ; Improve performance
    DllCall("dwmapi\DwmEnableComposition", "uint", 0)
    OnExit, Shutdown

    #Include lib/Gdip_All.ahk
    #Include lib/GDIpHelper.ahk
    #Include lib/CsvTableFunctions.ahk
    ;#Include src/GraphicDetector.ahk
    #Include src/Constants.ahk
    #Include src/Options.ahk
    #Include src/ImageDetector.ahk
    #Include src/MultiBattler.ahk
    #Include src/ScrollAssistant.ahk
    #Include lib/i18n.ahk
    #Include src/LanguageDetector.ahk


    ; Init translations
    language := new LanguageDetector().getLanguage(WinExist(Constants.RaidWinTitle))
    Global i18n := New i18n("i18n", language)

    ;; Init LOGIC
    filecreatedir, % Constants.LocalFolder()
    InitSettings()
    InitCalculator()

    If !pToken := Gdip_Startup()
    {
        MsgBox, w, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
        ExitApp
    }
    scrollAssistant := new ScrollAssistant()


    ;; Load VIEW
    SS_CENTERIMAGE := 0x200 ; TODO: extract from view after MVC
    ;Menu, Tray, Icon, images\icon.ico
    Menu, InfoMenu, Add, Help, MenuHandler
    Menu, InfoMenu, Add, About, MenuHandler
    infoLabel := "&Info    "
    Menu, MainMenuBar, Add, %infoLabel%, :InfoMenu, Right
    
    ; Load Main GUI
    Gui, Main:Default
    Gui, Main:Menu, MainMenuBar

    ; Section 1: Prepare your team
    Gui, Main:Font, s10 bold
    Gui, Main:Add, GroupBox,  w350 h72 Section, % Translate("TeamHeader")
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Text, xp+10 yp+20 w270, % Translate("InfoTeam")
    Gui, Main:Add, Button, w50 xp+280 yp-5 Center gGoToGame vTeamButton, Open`nGame
    Gui, Main:Font, s2
    Gui, Main:Add, Text, xs,

    ; Section 2: Number of battles
    Gui, Main:Font, s10 bold
    Gui, Main:Add, Text, w350 xs Section, % "  " . Translate("BattlesHeader")
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Tab3, hwndHTAB xs yp+20 w350 h157 vTabSelector gOnTabChanged Choose%selectedTab% AltSubmit, % Options.BattleAmount()
    Gui, Main:Add, Text, w320 h50 Section Center %SS_CENTERIMAGE%, % Translate("BattlesAmountManual")
    Gui, Main:Add, Text, w70 xs Section,
    Gui, Main:Font, s20 
    Gui, Main:Add, Edit, ys+10 w65 h35 Right gOnBattleChangedByEdit vEditBattles +Limit3 +Number, % Settings.battles
    Gui, Main:Add, UpDown, ys Range1-999 vUpDownBattles gOnBattleChangedByUpDown, % Settings.battles
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, xp+80 ys+20, % " " . Translate("BattlesAmountTail")

    Gui, Main:Tab, 2
    Gui, Main:Font, s1
    Gui, Main:Add, Text, 
    Gui, Main:Font, s10 normal
    Gui, Main:Add, DropDownList, Section w80 vRankSelector gOnCalculatorChanged Choose%selectedRank% AltSubmit, % Options.Rank()
    Gui, Main:Add, Text, ys h25 %SS_CENTERIMAGE% Center, % Translate("BattlesAmountCalculatedRankTail")
    Gui, Main:Add, DropDownList, ys w40 vLevelSelector gOnCalculatorChanged Choose%selectedLevel% AltSubmit, %initialLevelOptions%
    Gui, Main:Add, Text, ys h25 %SS_CENTERIMAGE% Center, % Translate("BattlesAmountCalculatedLevelTail")
    Gui, Main:Add, DropDownList, xs Section w65 vDifficultySelector gOnCalculatorChanged Choose%selectedDifficulty% AltSubmit, % Options.Difficulty()
    Gui, Main:Add, DropDownList, ys w40 vMapSelector gOnCalculatorChanged Choose%selectedMap% AltSubmit, % Options.Map()
    Gui, Main:Add, DropDownList, ys w35 vStageSelector gOnCalculatorChanged Choose%selectedStage% AltSubmit, % Options.Stage()
    Gui, Main:Add, Text, ys h25 %SS_CENTERIMAGE% Center, % Translate("BattlesAmountCalculatedStageTail")
    Gui, Main:Add, DropDownList, ys w97 vBoostSelector gOnCalculatorChanged Choose%selectedBoost% AltSubmit, % Options.Boost()
    Gui, Main:Add, Text, xs Section w70,
    Gui, Main:Font, s20 
    Gui, Main:Add, Text, w58 right ys vCalculatedRepetitions, % calculatedResults.repetitions
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, w100 ys+7, % " " . Translate("BattlesAmountTail")
    Gui, Main:Font, "s10 "Constants.COLOR_GRAY" normal"
    Gui, Main:Add, Text, w330 xs yp+25 Section Center vCalculatedExtra,

    Gui, Main:Tab, 3
    Gui, Main:Font
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Text, w330 h60 Section Center %SS_CENTERIMAGE%, % Translate("BattlesAmountInfinite")
    Gui, Main:Add, Text, w75 xs Section,
    Gui, Main:Font, s45 
    Gui, Main:Add, Text, w50 h35 ys Right %SS_CENTERIMAGE%, % Constants.InfiniteSymbol
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, w100 ys+7, % " " . Translate("BattlesAmountTail")
    Gui, Main:Tab

    Gui, Main:Font, s2 bold
    Gui, Main:Add, Text, x10 Section,
    Gui, Main:Font, s10 bold
    Gui, Main:Add, Text, w350 xs Section, % "  " . Translate("TimeHeader")
   
    ; Section 3: Duration
    Gui, Main:Font, s10 norm
    Gui, Main:Add, Tab3, hwndHTAB xs yp+20 w350 h100 vDurationTabSelector gOnDurationTabChanged Choose%selectedDurationTab% AltSubmit, % Options.BattleDuration()
    Gui, Main:Add, Text, w260 vAutoText, % Translate("InfoAuto")
    Gui, Main:Add, Button, w50 xp+260 yp Center gTestAuto vAutoButton, % Translate("ButtonTestDetector")
    Gui, Main:Font, s2
    
    Gui, Main:Tab, 2
    Gui, Main:Add, Text, Section BackgroundTrans w60 Right,
    Gui, Main:Font, s20 normal
    Gui, Main:Add, Edit, ys w52 h35 Right gOnTimeChangedByEdit vEditMinute +Limit2 +Number,
    Gui, Main:Add, UpDown, ys Range00-60 vUpDownMinute gOnTimeChangedByUpDown,
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, ys+7 BackgroundTrans, % Translate("BattlesDurationMinTail")
    Gui, Main:Font, s20 normal
    Gui, Main:Add, Edit, ys w52 h35 Right gOnTimeChangedByEdit vEditSecond +Limit2 +Number,
    Gui, Main:Add, UpDown, ys Range00-59 vUpDownSecond gOnTimeChangedByUpDown,
    Gui, Main:Font, s14 bold
    Gui, Main:Add, Text, ys+15 BackgroundTrans, % Translate("BattlesDurationSecTail")
    Gui, Main:Font, "s10 "Constants.COLOR_GRAY" normal"
    Gui, Main:Add, Text, h20 w330 xs yp+30 Section Center vCalculatedDuration,
    Gui, Main:Tab
    
    ; Section 4: Start button
    Gui, Main:Font, s10 bold
    Gui, Main:Add, Text, xs
    Gui, Main:Add, Button, Section w100 %SS_CENTERIMAGE% Center Default gStartScroll vStartScroll, % Translate("ButtonScrollStart")
    Gui, Main:Add, Text, w100 ys Section Right %SS_CENTERIMAGE% ,
    Gui, Main:Add, Button, ys w100 %SS_CENTERIMAGE% Center Default gStartBattles, % Translate("ButtonMultiBattle")

    ; Load Running GUI
    Gui, Running:Font, s12 bold
    Gui, Running:Add, Text, w250 Center vMultiBattleHeader, % Translate("RunningHeader")
    Gui, Running:Font, s10 normal
    Gui, Running:Add, Text, w115 Section, Current battle:
    Gui, Running:Add, Text, ys w120 Right vCurrentBattleStatus,
    Gui, Running:Add, Progress, xs yp+18 w250 h20 -Smooth vCurrentBattleProgress, 0
    Gui, Running:Add, Text, w115 xs Section, All battles:
    Gui, Running:Add, Text, ys w120 Right vMultiBattleStatus,
    Gui, Running:Add, Progress, xs yp+18 w250 h20 HwndhPB2 -Smooth vMultiBattleProgress, 0
    Gui, Running:Add, Text, w117 xs Section vOnFinishMessage, % Translate("RunningTimeLeftMessage")
    Gui, Running:Add, Text, w117 ys Right vOnFinishMessageValue, -
    Gui, Running:Font, s3 normal
    Gui, Running:Add, Text, xs Section,
    Gui, Running:Font, s10 normal
    Gui, Running:Font, s10 normal
    Gui, Running:Add, Text, w60 h23 xs Section Left %SS_CENTERIMAGE%, % Translate("RunningOnFinishMessage")
    Gui, Running:Add, DropDownList, ys w175 vOnFinishSelector gOnFinishChanged Choose%selectedOnFinish% AltSubmit, % Options.OnFinish()
    Gui, Running:Add, Checkbox, vOnFinishCheckbox gOnFinishCheckboxChanged, % Translate("RunningOnFinishCheckbox")
    Gui, Running:Font, s3 normal
    Gui, Running:Add, Text, xs Section,
    Gui, Running:Font, s10 bold
    Gui, Running:Add, Text, xs Section,
    Gui, Running:Add, Button, ys w200 h30 gShowResultCanceled %SS_CENTERIMAGE% Center Default, % Translate("RunningStopButton")

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
    Gui, Result:Add, Button, ys w100 h30 gStartBattles %SS_CENTERIMAGE% Center, Replay
    

    ; Load Help GUI
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, w350 Center Section, Help
    Gui, Help:Font, s10 normal
    Gui, Help:Add, Text, w350 xs, % Translate("ScriptDescription")
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, xs, % Translate("TeamHeader")
    Gui, Help:Font, s10 norm
    Gui, Help:Add, Text, w350 xs Section, % Translate("InfoTeam")
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, xs, % Translate("BattlesHeader")
    Gui, Help:Font, s10 norm
    Gui, Help:Add, Text, w350 xs Section, % Translate("InfoBattles")
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, xs, % Translate("TimeHeader")
    Gui, Help:Font, s10 norm
    Gui, Help:Add, Text, w350 xs Section, % Translate("InfoTime")
    Gui, Help:Font, s11 bold
    Gui, Help:Add, Text, xs, % Translate("StartHeader")
    Gui, Help:Font, s10 norm
    Gui, Help:Add, Text, w350 xs Section, % Translate("InfoStart")
    Gui, Help:Add, Text, w350 xs Section,
    Gui, Help:Add, Button, Section w100 h30 gShowMain %SS_CENTERIMAGE% Center Default, Back

    ; Load About GUI
    Gui, About:Font, s10 bold
    Gui, About:Add, Text, w350 h35 xp yp %SS_CENTERIMAGE% BackgroundTrans Section Center, % Constants.ScriptTitle " " Constants.ScriptVersion
    Gui, About:Font, s10 norm
    Gui, About:Add, Text, w350 xs Section, % Translate("ProjectDescription")
    Gui, About:Add, Button, Section w100 h30 gShowMain %SS_CENTERIMAGE% Center Default, Back
    Gui, About:Add, Text, w120 ys Section,
    Gui, About:Add, Button, ys w100 h30 gGoToSite %SS_CENTERIMAGE% Center, Go to GitHub
    
    
    ; Init loaded UIs
    InitTimeComponents()    
    FillCalculatedResults(calculatedResults)
    UpdateDuration()

    Prog := new Program()
    Prog.Main()
    
    
    ; Show initial UI (Main)
    Gui, Main:Show, xCenter y100 AutoSize, % Constants.ScriptTitle
    mainGuiShown := true
    
return ; End of auto-execute section

class Program
{
    Initialize()
    {
        SetWorkingDir,% A_ScriptDir
		this.View := new View()
		this.Model := new Model()
		this.Controller := new Controller(this.Model, this.View)
		this.View.showGui()
    }
	
	Main()
	{
        this.Initialize()
        this.Controller.OpenSettingsView()
	}
}



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
    Gui, %targetGui%:Show, x%x% y%y%, % Constants.ScriptTitle
    HideAllGuisBut(Constants.ViewNames, targetGui)
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

Shutdown:
    DestroyAllGuis()
    Gdip_Shutdown(pToken)
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
    Run % Constants.ScriptSite
return
    
GoToGame:
    ; If game is already open, activate their window
    if WinExist(Constants.RaidWinTitle){
        WinActivate, % Constants.RaidWinTitle
        return
    }
    
    ; If game not in default folder, ask for installation folder 
    fileFolder := Settings.customGameFolder != "" ? Settings.customGameFolder : Constants.DefaultGameFolder
    filePath := fileFolder . Constants.FolderSeparator . Constants.RaidFileName
    if (!FileExist(filePath)){
        ; Show select folder dialog
        FileSelectFolder, OutputVar, , 0, % Translate("UnableToFindGameMessage")
        if (!OutputVar || OutputVar == ""){
            MsgBox, % Translate("NoFolderSelectedMessage")
            return
        }
        newFilePath := OutputVar . Constants.FolderSeparator . Constants.RaidFileName
        if (!FileExist(newFilePath)){
            MsgBox, % Translate("NoGameInFolderMessage")
            return
        }
           
        ; Save custom raid folder
        settingsPath := Constants.SettingsFilePath()
        settingsSection := Constants.SettingsSection
        IniWrite, %OutputVar%, %settingsPath%, %settingsSection%, customGameFolder
        Settings.customGameFolder := OutputVar
        filePath := newFilePath
    }
    
    ; Open game from selected folder
    if (FileExist(filePath))
        Run, %filePath% --args -gameid=101
      
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
    settingsPath := Constants.SettingsFilePath()
    settingsSection := Constants.SettingsSection
    IniWrite, %TabValue%, %settingsPath%, %settingsSection%, tab
    Settings.tab := TabValue
    
    UpdateDuration()
return

OnDurationTabChanged:
	GuiControlGet,TabValue,,DurationTabSelector
    settingsPath := Constants.SettingsFilePath()
    settingsSection := Constants.SettingsSection
    IniWrite, %TabValue%, %settingsPath%, %settingsSection%, durationTab
    Settings.durationTab := TabValue
    
    ;UpdateDuration()
return

OnBattleChangedByEdit:
    Gui, Submit, NoHide
    GuiControlGet,BattlesValue,,EditBattles
    settingsPath := Constants.SettingsFilePath()
    settingsSection := Constants.SettingsSection
    IniWrite, %BattlesValue%, %settingsPath%, %settingsSection%, battles
    Settings.battles := BattlesValue
    GuiControl,,UpDownBattles,%BattlesValue%
    FillEstimatedTime(Settings.second, Settings.minute, BattlesValue)
return

OnBattleChangedByUpDown:
    GuiControlGet,BattlesValue,,UpDownBattles
    settingsPath := Constants.SettingsFilePath()
    settingsSection := Constants.SettingsSection
    IniWrite, %BattlesValue%, %settingsPath%, %settingsSection%, battles
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
    rankedLevelOptions := Options.GenerateNumericOptions(maxLvlValue)
    GuiControl,,LevelSelector, |%rankedLevelOptions%
    if (LevelValue > maxLvlValue){
        LevelValue := 1
    }
    GuiControl, ChooseString, LevelSelector, %LevelValue%
    
    settingsPath := Constants.SettingsFilePath()
    settingsSection := Constants.SettingsSection
    IniWrite, %DifficultyValue%, %settingsPath%, %settingsSection%, difficulty
    IniWrite, %StageValue%, %settingsPath%, %settingsSection%, stage
    IniWrite, %MapValue%, %settingsPath%, %settingsSection%, map
    IniWrite, %BoostValue%, %settingsPath%, %settingsSection%, boost
    IniWrite, %RankValue%, %settingsPath%, %settingsSection%, rank
    IniWrite, %LevelValue%, %settingsPath%, %settingsSection%, level
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
    settingsPath := Constants.SettingsFilePath()
    settingsSection := Constants.SettingsSection
    IniWrite, %MinuteValue%, %settingsPath%, %settingsSection%, minute
    IniWrite, %SecondValue%, %settingsPath%, %settingsSection%, second
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
    settingsPath := Constants.SettingsFilePath()
    settingsSection := Constants.SettingsSection
    IniWrite, %MinuteValue%, %settingsPath%, %settingsSection%, minute
    IniWrite, %SecondValue%, %settingsPath%, %settingsSection%, second
    Settings.minute := MinuteValue
    Settings.second := SecondValue
    GuiControl,,UpDownMinute,%MinuteValue%
    GuiControl,,UpDownSecond,%SecondValue%
    
    UpdateDuration()
return

OnFinishChanged:
    Gui, submit, nohide
    GuiControlGet, OnFinishValue,,OnFinishSelector
    settingsPath := Constants.SettingsFilePath()
    settingsSection := Constants.SettingsSection
    IniWrite, %OnFinishValue%, %settingsPath%, %settingsSection%, onFinish
    Settings.onFinish := OnFinishValue
return

OnFinishCheckboxChanged:
    Gui, submit, nohide
    GuiControlGet, OnFinishCheckboxValue,,OnFinishCheckbox
return


;; MultiBattler

TestAuto:
    new MultiBattler().testAuto()
return

StartScroll:
    if (!scrollAssistant.isRunning()) {
        scrollAssistant.start()
        GuiControl, , StartScroll, % Translate("ButtonScrollStop")
    }
    else {
        scrollAssistant.stop()
        GuiControl, , StartScroll, % Translate("ButtonScrollStart")
    }
return

StartBattles:
    new MultiBattler().start()
return

ShowResultSuccess:
ShowResultCanceled:
ShowResultInterrupted:
    new MultiBattler().showResult()
return


;;; Functions

InitSettings(){
    global
    local settingsPath := Constants.SettingsFilePath()
    local settingsSection := Constants.SettingsSection
    If (!FileExist(settingsPath)){
        Settings := Constants.DefaultSettings
        for key, value in Settings{
            if (key="minute" || key="second"){
                SetFormat, Float, 02.0
                value += 0.0
                Settings[key] := value
            }        
            IniWrite, %value%, %settingsPath%, %settingsSection%, %key%
        }
    }else{
        Settings := {}
        for key, defaultValue in Constants.DefaultSettings{
            IniRead, storedValue, %settingsPath%, %settingsSection%, %key%
            if (storedValue="ERROR"){
                ; Key never included or corrupted at setting file. Restore defaultValue.
                IniWrite, %defaultValue%, %settingsPath%, %settingsSection%, %key%
                Settings[key] := defaultValue
            }else{
                Settings[key] := storedValue
            }
        }
    }
    local settingsPathOld := Constants.SettingsFilePathOld()    ;used on versions 1.0.1
    If (FileExist(settingsPathOld)){
        FileDelete, % settingsPathOld  
    }
    settingsPathOld := Constants.SettingsFilePathOld2()         ;used on versions 1.0.2
    If (FileExist(settingsPathOld)){
        FileDelete, % settingsPathOld  
    }
    selectedTab := Settings.tab
    selectedBoost := Settings.boost
    selectedDifficulty := Settings.difficulty
    selectedMap := Settings.map
    selectedStage := Settings.stage
    selectedRank := Settings.rank
    selectedLevel := Settings.level
    selectedOnFinish := Settings.onFinish
    selectedRaidFilePath := Settings.customGameFolder
    selectedDurationTab := Settings.durationTab
    
    OnFinishCheckboxValue := 0
}

InitCalculator(){
    global
    FileInstall, data\XpData.csv, % Constants.LocalFolder() Constants.FolderSeparator Constants.XpDataFileName
    FileInstall, data\CampaignData.csv, % Constants.LocalFolder() Constants.FolderSeparator Constants.CampaignDataFileName
    XpData := ReadTable(Constants.LocalFolder() . Constants.FolderSeparator . Constants.XpDataFileName, {"Headers" : True}, xpColumnNames)
    CampaignData := ReadTable(Constants.LocalFolder() . Constants.FolderSeparator . Constants.CampaignDataFileName, {"Headers" : True}, campaignColumnNames)
    initialLevelOptions := Options.GenerateNumericOptions((selectedRank*10)-1)
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
    boostOptionsMultiplier := [1, 1.2, 2, 2.4]
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
    infiniteMode := (repetitions=-1)
    if (infiniteMode){
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
    if (!infiniteMode){
        text .= " aprox."
    }
    GuiControl,, CalculatedDuration, %text%
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

HideAllGuisBut(list, excluded){
    Loop, Parse, list, |
        if (A_LoopField != excluded){
            Gui, %A_LoopField%:Hide
        }
    return
}

DestroyAllGuis(){
    names := Constants.ViewNames
    Loop, Parse, names, |
        Gui, %A_LoopField%:Destroy
    return
}
