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

    #Include lib\CGui.ahk
    #Include lib\Gdip_All.ahk
    #Include lib\GDIpHelper.ahk
    #Include lib\CsvTableFunctions.ahk
    ;#Include src\GraphicDetector.ahk
    #Include src\Constants.ahk
    #Include src\Options.ahk
    #Include src\ImageDetector.ahk
    #Include src\MultiBattler.ahk
    #Include src\ScrollAssistant.ahk
    #Include lib\i18n.ahk
    #Include src\LanguageDetector.ahk

    ; Init i18n (TODO: extract)
    language := new LanguageDetector().getLanguage(WinExist(Constants.RaidWinTitle))
    Global i18n := New i18n("i18n", language)

    ;; Init SERVICES (TODO: extract)
    If !pToken := Gdip_Startup()
    {
        MsgBox, w, gdiplus error!, Gdiplus failed to start. Please ensure you have gdiplus on your system
        ExitApp
    }
    scrollAssistant := new ScrollAssistant()


    Program := new UnlimitedMultiBattles()
    Program.Main()
    
return ; End of auto-execute section

#Include src\controller\UMB_Controller.ahk
#Include src\model\UMB_Model.ahk
#Include src\view\UMB_View.ahk

class UnlimitedMultiBattles
{
    Initialize()
    {
		this.Model := new UMB_Model()
		this.View := new UMB_View()
		this.Controller := new UMB_Controller(this.Model, this.View)
    }
	
	Main()
	{
        this.Initialize()
        this.Controller.GoTo("Main")
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
    if (A_ThisMenuItem == Translate("HelpHeader")){
        GoSub ShowHelp
    }
    else if (A_ThisMenuItem == Translate("AboutHeader")){
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
    
    ;UpdateDuration()
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
    
    ;UpdateDuration()
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
        helpView.Show()
    }
    else {
        scrollAssistant.stop()
        GuiControl, , StartScroll, % Translate("ButtonScrollStart")
        helpView.Hide()
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
