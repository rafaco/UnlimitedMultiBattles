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

        ;Gui, Color, 0xfffde7

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
        this.upDownBattles := this.Gui("Add", "UpDown", "ys Range1-999", Settings.battles)
        this.GuiControl("+g", this.upDownBattles, this.UpDownBattlesChanged)
        this.Font("s14 bold")
        this.Gui("Add", "Text", "xp+80 ys+20", " " . Translate("BattlesAmountTail"))
    }

    addTabAmmountCalculated() {
        Gui, Tab, 2
        this.Font("s1")
        this.Gui("Add", "Text")
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
        this.Font("s10 normal")
        this.Gui("Add", "Text", "x10 Section")
        this.Font("s10 bold")
        this.Gui("Add", "Text", "w350 xs Section", "  " . Translate("TimeHeader"))
        this.Font("s10 normal")
        
        ; TODO: vDurationTabSelector gOnDurationTabChanged Choose%selectedDurationTab%
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

        ;vCalculatedDuration
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
        GoSub OnTabChanged
    }
    
    EditBattlesChanged(){
        GoSub OnBattleChangedByEdit
    }
    
    UpDownBattlesChanged(){
        GoSub OnBattleChangedByUpDown
    }

    RankSelectorChanged(){
        GoSub OnCalculatorChanged
    }

    LevelSelectorChanged(){
        GoSub OnCalculatorChanged 
    }

    DifficultySelectorChanged(){
        GoSub OnCalculatorChanged 
    }

    MapSelectorChanged(){
        GoSub OnCalculatorChanged 
    }

    StageSelectorChanged(){
        GoSub OnCalculatorChanged 
    }

    BoostSelectorChanged(){
        GoSub OnCalculatorChanged 
    }

    DurationTabSelectorChanged(){
        GoSub OnDurationTabChanged
    }

    AutoButtonPressed(){
        GoSub TestAuto
    }

    EditMinuteChanged(){
        GoSub OnTimeChangedByEdit
    }
    
    UpDownMinuteChanged(){
        GoSub OnTimeChangedByUpDown
    }

    EditSecondChanged(){
        GoSub OnTimeChangedByEdit
    }
    
    UpDownSecondChanged(){
        GoSub OnTimeChangedByUpDown
    }

    StartScrollButtonPressed(){
        this.controller.GoTo("Result")
        ;GoSub StartScroll
    }
    
    StartBattleButtonPressed(){
        GoSub StartBattles
        this.Hide()
    }


    LoadData(data) {
        this.GuiControl("Choose", this.tabSelector,         data.settings.tab)
        this.GuiControl(        , this.editBattles,         data.settings.battles)
        this.GuiControl(        , this.upDownBattles,       data.settings.battles)
        this.GuiControl("Choose", this.rankSelector,        data.settings.rank)
        this.GuiControl("Choose", this.difficultySelector,  data.settings.difficulty)
        this.GuiControl("Choose", this.mapSelector,         data.settings.map)
        this.GuiControl("Choose", this.stageSelector,       data.settings.stage)
        this.GuiControl("Choose", this.boostSelector,       data.settings.boost)

        levelOptions := Options.GenerateNumericOptions((    data.settings.rank*10)-1)
        this.GuiControl(        , this.levelSelector,       levelOptions)
        this.GuiControl("Choose", this.levelSelector,       data.settings.level)
        
        this.GuiControl(        , this.calculatedRepetitions,data.results.repetitions)
        extratext := FormatNumber(data.results.energy) . " energy  -->  " 
                   . FormatNumber(data.results.silver) . " silver"
        this.GuiControl(        , this.calculatedExtra,     extratext)
    }


    AddListener(controller)
    {
        this.controller := controller
    }
}