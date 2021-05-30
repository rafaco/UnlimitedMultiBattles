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

Class BattlingView extends CGui {

	__New(aParams*){

		global BorderState
		base.__New(aParams*)

        this.multiBattleIndeterminateStatus := -1
        
        this.addHeaders()
        this.addProgressBars()
        this.addOnFinishControls()
        this.addBottonButtons()
	}

    addHeaders() {
        this.Font("s12 bold")
        this.MultiBattleHeader := this.Gui("Add", "Text", "w250 Center", Translate("BattlingHeader"))
        this.Font("s10 norm")
        this.MultiBattleOverview := this.Gui("Add", "Text", "Section w250 Center")
    }

    addProgressBars() {
        ; First ProgressBar
        this.Font("s10 norm")
        this.Gui("Add", "Text", "w115 Section", Translate("BattlingCurrentBattleMessage"))
        this.CurrentBattleStatus := this.Gui("Add", "Text", "ys w120 Right")
        this.CurrentBattleProgress := this.Gui("Add", "Progress", "xs yp+18 w250 h20 -Smooth", 0)

        ; Second ProgressBar
        this.Gui("Add", "Text", "w115 xs Section", Translate("BattlingMultiBattleMessage"))
        this.MultiBattleStatus := this.Gui("Add", "Text", "ys w120 Right")
        this.MultiBattleProgress := this.Gui("Add", "Progress", "xs yp+18 w250 h20 -Smooth", 0)

        ; Time left message
        this.TimeLeftMessage := this.Gui("Add", "Text", "w117 xs Section", Translate("BattlingTimeLeftMessage"))
        this.TimeLeftMessageValue := this.Gui("Add", "Text", "w117 ys Right", "-")
    }

    addOnFinishControls() {
        ; On Finish selector
        this.Font("s3 normal")
        this.Gui("Add", "Text", "xs Section")
        this.Font("s10 normal")
        this.Gui("Add", "Text", "w70 h23 xs Section Left " Constants.SS_CENTERIMAGE, Translate("BattlingOnFinishMessage"))
        
        this.OnFinishSelector := this.Gui("Add", "DropDownList", "ys w175 AltSubmit", Options.OnFinish())
        this.GuiControl("+g", this.OnFinishSelector, this.OnFinishSelectorChanged)

        this.OnFinishCheckbox := this.Gui("Add", "Checkbox", "", Translate("BattlingOnFinishCheckbox"))
        this.GuiControl("+g", this.OnFinishCheckbox, this.OnFinishCheckboxChanged)
    }

    addBottonButtons() {
        ; Stop button
        this.Font("s3 normal")
        this.Gui("Add", "Text", "xs Section")
        this.Font("s10 bold")
        this.Gui("Add", "Text", "xs Section")
        this.Font("s10 normal")
        this.CancelButton := this.Gui("Add", "Button", "ys w200 h30 " Constants.SS_CENTERIMAGE " Center Default", Translate("BattlingStopButton"))
        this.GuiControl("+g", this.CancelButton, this.OnCancelButtonPressed)
    }

    OnFinishSelectorChanged(){
        this.controller.OnSettingChanged("onFinish", this.OnFinishSelector.value)
    }

    OnFinishCheckboxChanged(){
        this.controller.OnSettingChanged("SuspendOnFinish", this.OnFinishCheckbox.value)
    }
    
    OnCancelButtonPressed(){
        Gosub, GuiClose
    }

    LoadData(data, changed:="") 
    {
        ;TODO: decide between hide or indeterminate
        ; Second progress bar hide/show
        ;secondProgressHideOrShow := (data.battling.isInfinite) ? "Hide" : "Show"
        ;this.GuiControl(secondProgressHideOrShow, this.MultiBattleProgress)
        ;this.GuiControl(secondProgressHideOrShow, this.MultiBattleStatus)
        
        ; Second progress bar indeterminate
        if (this.multiBattleIndeterminateStatus != data.battling.isInfinite) 
        {
            secondProgressHwnd := this.MultiBattleProgress._hwnd
            PBS_MARQUEE := 0x8, PBM_SETMARQUEE := 0x40A
            If (data.battling.isInfinite){
                WinSet, Style, +%PBS_MARQUEE%, % "ahk_id " secondProgressHwnd
                SendMessage, %PBM_SETMARQUEE%, 1, 50,, % "ahk_id " secondProgressHwnd
            }
            else{
                WinSet, Style, -%PBS_MARQUEE%, % "ahk_id " secondProgressHwnd
            }
            this.multiBattleIndeterminateStatus := data.battling.isInfinite
        }

        this.MultiBattleOverview.value      := data.battling.overview
        this.MultiBattleProgress.value      := data.battling.currentProgress2
        this.MultiBattleStatus.value        := data.battling.multiBattleStatus
        this.CurrentBattleProgress.value    := data.battling.currentProgress1
        this.CurrentBattleStatus.value      := data.battling.currentBattleStatus
        this.TimeLeftMessageValue.value     := data.battling.timeLeftMessage

        this.GuiControl("Choose", this.OnFinishSelector, data.settings.onFinish)
        this.GuiControl("Choose", this.OnFinishCheckbox, data.battling.suspendOnFinish)
    }

    AddListener(controller)
    {
        this.controller := controller
    }
}