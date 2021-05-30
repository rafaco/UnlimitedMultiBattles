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

Class BattlingResultView extends CGui {

	__New(aParams*){

		global BorderState
		base.__New(aParams*)

        this.addViewControls()
		
        ;this.Show("xCenter y100 AutoSize", Constants.ScriptTitle)
	}

    addViewControls()
    {
        this.Font("s12 bold")
        this.ResultHeader := this.Gui("Add", "Text", "w250 Center")

        this.Font("s10 norm")
        this.ResultMessage := this.Gui("Add", "Text", "w250 yp+20 Center")
        
        this.Font("s12 norm")
        this.ResultText := this.Gui("Add", "Text", "w250 Center")

        this.Font("s10 bold")
        this.Gui("Add", "Text", "Section")

        this.doneButton := this.Gui("Add", "Button", "ys w100 h30 " Constants.SS_CENTERIMAGE " Center Default", Translate("ButtonResultDone"))
        this.replayButton := this.Gui("Add", "Button", "ys w100 h30 " Constants.SS_CENTERIMAGE " Center", Translate("ButtonResultReplay"))
        this.GuiControl("+g", this.doneButton, this.DoneButtonPressed)
        this.GuiControl("+g", this.replayButton, this.ReplayButtonPressed)
    }

    loadData(data){
        this.ResultHeader.value := data.results.header
        this.ResultMessage.value := data.results.message
        this.ResultText.value := data.results.detail
    }

    DoneButtonPressed(){
        this.controller.GoTo("Main")
    }

    ReplayButtonPressed(){
        this.controller.StartMultiBattle()
    }

    AddListener(controller)
    {
        this.controller := controller
    }
}