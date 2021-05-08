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

Class MainView extends CGui {

	__New(aParams*){

		global BorderState
		base.__New(aParams*)
        
        ;Gui, Color, 0xe1f5fe

        this.addMenu()
        this.addSectionPrepareTeam()
        this.addSectionAmmount()
        this.addSectionDuration()
        this.addSectionStart()
		
        ;this.Show("xCenter y100 AutoSize", Constants.ScriptTitle)		
	}

    addMenu() {
        menu1       := % Translate("InfoHeader")
        submenu1    := % Translate("HelpHeader")
        submenu2    := % Translate("AboutHeader")
        Menu, InfoMenu, Add, %submenu1%, MenuHandler
        Menu, InfoMenu, Add, %submenu2%, MenuHandler
        infoLabel := "&" . menu1 . "    "
        Menu, MainMenuBar, Add, %infoLabel%, :InfoMenu, Right

        Gui, Menu, MainMenuBar
    }

    
    addSectionPrepareTeam() {
        ; Section 1: Prepare your team
        this.Font("s10 bold")
        this.Gui("Add", "GroupBox", "w350 h72 Section", Translate("TeamHeader"))
        this.Font("s10 normal")
        this.Gui("Add", "Text", "xp+10 yp+20 w270", Translate("InfoTeam"))
        this.teamButton := this.Gui("Add", "Button", "w50 xp+280 yp-5 Center", Translate("ButtonOpenGame"))
        this.GuiControl("+g", this.teamButton, this.TeamButtonPressed)
        this.Font("s2")
        this.Gui("Add", "Text", "xs")
    }

    addSectionAmmount() {
        ; Section 2: Number of battles
        this.Font("s10 bold")
        this.Gui("Add", "Text", "w350 xs Section", "  " . Translate("BattlesHeader"))
        this.Font("s10 normal")
        
        this.tabSelector := this.Gui("Add", "Tab3", "xs yp+20 w350 h157 AltSubmit", Options.BattleAmount())
        this.GuiControl("+g", this.tabSelector, this.TabSelectorChanged)
        this.addTabAmmountManual()
        this.addTabAmmountCalculated(tabSelector)
        this.addTabAmmountInfinite()
        Gui, Tab
    }

    addTabAmmountManual() {
        ;Gui, Tab, 1
        this.Gui("Add", "Text", "w320 h50 Section Center " Constants.SS_CENTERIMAGE, Translate("BattlesAmountManual"))
        this.Gui("Add", "Text", "w70 xs Section")
        this.Font("s20")
        this.editBattles := this.Gui("Add", "Edit", "ys+10 w65 h35 Right +Limit3 +Number")
        this.GuiControl("+g", this.editBattles, this.EditBattlesChanged)
        this.upDownBattles := this.Gui("Add", "UpDown", "ys Range1-999")
        this.GuiControl("+g", this.upDownBattles, this.UpDownBattlesChanged)
        this.Font("s14 bold")
        this.Gui("Add", "Text", "xp+80 ys+20", " " . Translate("BattlesAmountTail"))
    }

    addTabAmmountCalculated() {
        Gui, Tab, 2
        this.Font("s1")
        this.Gui("Add", "Text")
        this.Font("s10 normal")

        this.rankSelector := this.Gui("Add", "DropDownList", "Section w80 AltSubmit", Options.Rank())
        this.GuiControl("+g", this.rankSelector, this.RankSelectorChanged)
        this.Gui("Add", "Text", "ys h25 Center " Constants.SS_CENTERIMAGE, Translate("BattlesAmountCalculatedRankTail"))
        
        this.levelSelector := this.Gui("Add", "DropDownList", "ys w40 AltSubmit")
        this.GuiControl("+g", this.levelSelector, this.LevelSelectorChanged)
        this.Gui("Add", "Text", "ys h25 Center " Constants.SS_CENTERIMAGE, Translate("BattlesAmountCalculatedLevelTail"))

        this.difficultySelector := this.Gui("Add", "DropDownList", "xs Section w65 AltSubmit", Options.Difficulty())
        this.GuiControl("+g", this.difficultySelector, this.DifficultySelectorChanged) 
        
        this.mapSelector := this.Gui("Add", "DropDownList", "ys w40 AltSubmit", Options.Map())
        this.GuiControl("+g", this.mapSelector, this.MapSelectorChanged)
        
        this.stageSelector := this.Gui("Add", "DropDownList", "ys w35 AltSubmit", Options.Stage())
        this.GuiControl("+g", this.stageSelector, this.StageSelectorChanged)
        this.Gui("Add", "Text", "ys h25 Center " Constants.SS_CENTERIMAGE, Translate("BattlesAmountCalculatedStageTail"))
        
        this.boostSelector := this.Gui("Add", "DropDownList", "ys w97 AltSubmit", Options.Boost())
        this.GuiControl("+g", this.boostSelector, this.BoostSelectorChanged)

        this.Gui("Add", "Text", "xs Section w70")
        this.Font("s20")
        this.calculatedRepetitions := this.Gui("Add", "Text", "w58 right ys")
        this.Font("s14 bold")
        this.Gui("Add", "Text", "w100 ys+7", " " . Translate("BattlesAmountTail"))
        
        this.Font("s10 " Constants.COLOR_GRAY " normal")
        this.calculatedExtra := this.Gui("Add", "Text", "w330 xs yp+25 Section Center")
        this.Font()
    }

    addTabAmmountInfinite() {
        Gui, Tab, 3
        this.Font("s10 normal")
        this.Gui("Add", "Text", "w330 h60 Section Center " Constants.SS_CENTERIMAGE, Translate("BattlesAmountInfinite"))
        this.Gui("Add", "Text", "w75 xs Section")
        this.Font("s45")
        this.Gui("Add", "Text", "w50 h35 ys Right " Constants.SS_CENTERIMAGE, Constants.InfiniteSymbol)
        this.Font("s14 bold")
        this.Gui("Add", "Text", "w100 ys+7", " " . Translate("BattlesAmountTail"))
    }
        
     addSectionDuration() {
        this.Font("s2 bold")
        this.Gui("Add", "Text", "x10 Section")
        this.Font("s10 bold")
        this.Gui("Add", "Text", "w350 xs Section", "  " . Translate("TimeHeader"))
        this.Font("s10 normal")
        
        this.durationTabSelector := this.Gui("Add", "Tab3", "xs yp+20 w350 h100 AltSubmit", Options.BattleDuration())
        this.GuiControl("+g", this.durationTabSelector, this.DurationTabSelectorChanged)
        this.addTabDurationAuto()
        this.addTabDurationManual()
        Gui, Tab
    }

    addTabDurationAuto(){
        ;Gui, Tab, 1
        this.autoText := this.Gui("Add", "Text", "w260", Translate("InfoAuto"))
        this.autoButton := this.Gui("Add", "Button", "w50 xp+260 yp Center", Translate("ButtonTestDetector"))
        this.GuiControl("+g", this.autoButton, this.AutoButtonPressed)
        this.Font("s2")
    }

    addTabDurationManual(){
        Gui, Tab, 2
        this.Gui("Add", "Text", "Section BackgroundTrans w60 Right")
        this.Font("s20 normal")

        ;gOnTimeChangedByEdit vEditMinute 
        this.editMinute := this.Gui("Add", "Edit", "ys w52 h35 Right +Limit2 +Number")
        this.GuiControl("+g", this.editMinute, this.EditMinuteChanged)

        ;vUpDownMinute gOnTimeChangedByUpDown
        this.upDownMinute := this.Gui("Add", "UpDown", "ys Range00-60")
        this.GuiControl("+g", this.upDownMinute, this.UpDownMinuteChanged)

        this.Font("s14 bold")
        this.Gui("Add", "Text", "ys+7 BackgroundTrans", Translate("BattlesDurationMinTail"))
        this.Font("s20 normal")

        ;TODO: gOnTimeChangedByEdit vEditSecond 
        this.editSecond := this.Gui("Add", "Edit", "ys w52 h35 Right +Limit2 +Number")
        this.GuiControl("+g", this.editSecond, this.EditSecondChanged)

        ;vUpDownSecond gOnTimeChangedByUpDown
        this.upDownSecond := this.Gui("Add", "UpDown", "ys Range00-59")
        this.GuiControl("+g", this.upDownSecond, this.UpDownSecondChanged)
        
        this.Font("s14 bold")
        this.Gui("Add", "Text", "ys+15 BackgroundTrans", Translate("BattlesDurationSecTail"))
        this.Font("s10 " Constants.COLOR_GRAY " normal")

        this.calculatedDuration := this.Gui("Add", "Text", "h20 w330 xs yp+30 Section Center")
    }

    addSectionStart() {
        this.Font("s10 bold")
        this.Gui("Add", "Text", "xs")

        ;gStartScroll vStartScroll
        this.startScrollButton := this.Gui("Add", "Button", "Section w100 Center Default " Constants.SS_CENTERIMAGE, Translate("ButtonScrollStart"))
        this.GuiControl("+g", this.startScrollButton, this.StartScrollButtonPressed)
        
        this.Gui("Add", "Text", "w100 ys Section Right "  Constants.SS_CENTERIMAGE)

        ;gStartScroll vStartScroll
        this.startBattlesButton := this.Gui("Add", "Button", "ys w100 Center Default " Constants.SS_CENTERIMAGE, Translate("ButtonMultiBattle"))
        this.GuiControl("+g", this.startBattlesButton, this.StartBattlesButtonPressed)
    }


    TeamButtonPressed(){
        GoSub GoToGame
    }

    TabSelectorChanged(){
        this.controller.OnSettingChanged("tab", this.tabSelector.value)
    }
    
    EditBattlesChanged(){
        this.controller.OnSettingChanged("battles", this.editBattles.value)
        this.GuiControl("Focus", this.startBattlesButton)
    }
    
    UpDownBattlesChanged(){
        this.controller.OnSettingChanged("battles", this.upDownBattles.value)
        this.GuiControl("Focus", this.startBattlesButton)
    }

    RankSelectorChanged(){
        this.controller.OnSettingChanged("rank", this.rankSelector.value)
    }

    LevelSelectorChanged(){
        this.controller.OnSettingChanged("level", this.levelSelector.value)
    }

    DifficultySelectorChanged(){
        this.controller.OnSettingChanged("difficulty", this.difficultySelector.value)
    }

    MapSelectorChanged(){
        this.controller.OnSettingChanged("map", this.mapSelector.value)
    }

    StageSelectorChanged(){
       this.controller.OnSettingChanged("stage", this.stageSelector.value)
    }

    BoostSelectorChanged(){
        this.controller.OnSettingChanged("boost", this.boostSelector.value)
    }

    DurationTabSelectorChanged(){
        this.controller.OnSettingChanged("durationTab", this.durationTabSelector.value)
    }

    EditMinuteChanged(){
        value := this.FormatTwoDigits(this.editMinute.value)
        this.controller.OnSettingChanged("minute", value)
        this.GuiControl("Focus", this.startBattlesButton)
    }
    
    UpDownMinuteChanged(){
        value := this.FormatTwoDigits(this.upDownMinute.value)
        this.controller.OnSettingChanged("minute", value)
        this.GuiControl("Focus", this.startBattlesButton)
    }

    EditSecondChanged(){
        value := this.FormatTwoDigits(this.editSecond.value)
        this.controller.OnSettingChanged("second", value)
        this.GuiControl("Focus", this.startBattlesButton)
    }
    
    UpDownSecondChanged(){
        value := this.FormatTwoDigits(this.upDownSecond.value)
        this.controller.OnSettingChanged("second", value)
        this.GuiControl("Focus", this.startBattlesButton)
    }

    
    AutoButtonPressed(){
        this.controller.StartDetectionTest()
    }

    StartScrollButtonPressed(){
        this.controller.StartScroll()
    }
    
    StartBattleButtonPressed(){
        GoSub StartBattles
        this.Hide()
    }


    LoadData(data, changed:="") 
    {
        this.RemoveBuggyListeners()

        ; Ammount selectors
        this.GuiControl("Choose", this.tabSelector,         data.settings.tab)
        ;this.GuiControl(        , this.editBattles,         data.settings.battles)
        this.editBattles.value := data.settings.battles
        this.GuiControl(        , this.upDownBattles,       data.settings.battles)
        this.GuiControl("Choose", this.rankSelector,        data.settings.rank)
        this.GuiControl(        , this.levelSelector,       data.results.levelOptions)
        this.GuiControl("Choose", this.levelSelector,       data.results.levelValue) ;TODO: ChooseString??
        this.GuiControl("Choose", this.difficultySelector,  data.settings.difficulty)
        this.GuiControl("Choose", this.mapSelector,         data.settings.map)
        this.GuiControl("Choose", this.stageSelector,       data.settings.stage)
        this.GuiControl("Choose", this.boostSelector,       data.settings.boost)

        ; Duration selectors
        this.GuiControl("Choose", this.durationTabSelector,data.settings.durationTab)
        ;this.GuiControl(        , this.editMinute,         data.settings.minute)
        ;this.GuiControl(        , this.editSecond,         data.settings.second)
        this.editMinute.value := data.settings.minute
        this.editSecond.value := data.settings.second
        this.GuiControl(        , this.upDownMinute,       data.settings.minute)
        this.GuiControl(        , this.upDownSecond,       data.settings.second)

        ; Calculator output
        this.GuiControl(        , this.calculatedRepetitions,data.results.repetitions)
        this.GuiControl(        , this.calculatedExtra,     data.results.extratext)
        calculatedDuration    := (data.settings.tab=1)    ? data.results.manualTime
                               : (data.settings.tab=2)    ? data.results.calculatedTime
                                                          : data.results.infiniteTime
        this.GuiControl(        , this.calculatedDuration,  calculatedDuration)

        fn := ObjBindMethod(this, "RestoreBuggyListeners")
        SetTimer, %fn%, -1
    }

    RemoveBuggyListeners()
    {
        ; Special treatment for Edit and UpDown controls.
        ; The listener need to be removed before updating the value or it will be fired
        this.GuiControl("-g", this.editBattles)
        this.GuiControl("-g", this.editMinute)
        this.GuiControl("-g", this.editSecond)
        this.GuiControl("-g", this.upDownBattles)
        this.GuiControl("-g", this.upDownMinute)
        this.GuiControl("-g", this.upDownSecond)
    }
     
    RestoreBuggyListeners()
    {
        ; Special treatment for Edit and UpDown controls.
        ; Restoring the listeners after the update of the value
        this.GuiControl("+g", this.editBattles, this.EditBattlesChanged)
        this.GuiControl("+g", this.upDownBattles, this.UpDownBattlesChanged)
        this.GuiControl("+g", this.editMinute, this.EditMinuteChanged)
        this.GuiControl("+g", this.upDownMinute, this.UpDownMinuteChanged)
        this.GuiControl("+g", this.editSecond, this.EditSecondChanged)
        this.GuiControl("+g", this.upDownSecond, this.UpDownSecondChanged)
    }

    UpdateScrollButton(isScrollEnabled)
    {
        this.mainVBiew.UpdateScrollButton(isScrollEnabled)
        buttonText := isScrollEnabled ? Translate("ButtonScrollStop") : Translate("ButtonScrollStart")
        this.startScrollButton.value := buttonText
    }

    FormatTwoDigits(value)
    {
        SetFormat, Float, 02.0
        value += 0.0
        return value
    }


    AddListener(controller)
    {
        this.controller := controller
    }
}