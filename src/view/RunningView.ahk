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

Class RunningView extends CGui {

	__New(aParams*){

		global BorderState
		base.__New(aParams*)

        ; Header
        this.Font("s12 bold")
        this.MultiBattleHeader := this.Gui("Add", "Text", "w250 Center", Translate("RunningHeader"))
        
        ; First ProgressBar
        this.Font("s10 norm")
        this.Gui("Add", "Text", "w115 Section", Translate("RunningCurrentBattleMessage"))
        this.CurrentBattleStatus := this.Gui("Add", "Text", "ys w120 Right")
        this.CurrentBattleProgress := this.Gui("Add", "Progress", "xs yp+18 w250 h20 -Smooth", 0)

        ; Second ProgressBar
        this.Gui("Add", "Text", "w115 xs Section", Translate("RunningMultiBattleMessage"))
        this.MultiBattleStatus := this.Gui("Add", "Text", "ys w120 Right")
        this.CurrentBattleProgress := this.Gui("Add", "Progress", "xs yp+18 w250 h20 HwndhPB2 -Smooth", 0)

        ; Time left message
        this.OnFinishMessage := this.Gui("Add", "Text", "w117 xs Section", Translate("RunningTimeLeftMessage"))
        this.OnFinishMessageValue := this.Gui("Add", "Text", "w117 ys Right", "-")

        ; On Finish selector
        this.Font("s3 normal")
        this.Gui("Add", "Text", "xs Section")
        this.Font("s10 normal")
        this.Gui("Add", "Text", "w70 h23 xs Section Left " Constants.SS_CENTERIMAGE, Translate("RunningOnFinishMessage"))
        ; TODO Choose%%
        this.OnFinishSelector := this.Gui("Add", "DropDownList", "ys w175 AltSubmit Choose" selectedOnFinish, Options.OnFinish())
        this.GuiControl("+g", this.OnFinishSelector, this.OnFinishSelectorChanged)
        this.OnFinishCheckbox := this.Gui("Add", "Checkbox", "", Translate("RunningOnFinishCheckbox"))
        this.GuiControl("+g", this.OnFinishCheckbox, this.OnFinishCheckboxChanged)

        ; Stop button
        this.Font("s3 normal")
        this.Gui("Add", "Text", "xs Section")
        this.Font("s10 bold")
        this.Gui("Add", "Text", "xs Section")
        this.Font("s10 normal")
        this.CancelButton := this.Gui("Add", "Button", "ys w200 h30 " Constants.SS_CENTERIMAGE " Center Default", Translate("RunningStopButton"))
        this.GuiControl("+g", this.CancelButton, this.OnCancelButtonPressed)
		
        this.Show("xCenter y100 AutoSize", Constants.ScriptTitle)
	}

    OnFinishSelectorChanged(){
        GoSub OnFinishChanged
    }

    OnFinishCheckboxChanged(){
        GoSub OnFinishCheckboxChanged
    }
    
    OnCancelButtonPressed(){
        this.Hide()
        GoSub ShowResultCanceled
    }

    AddListener(controller)
    {
        this.controller := controller
    }
}