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

Class HelpView extends CGui {

	__New(aParams*){

		global BorderState
		base.__New(aParams*)

        this.Font("s11 bold")
        this.Gui("Add", "Text", "w350 Center Section", Translate("HelpHeader"))
        this.Font("s10 normal")
        this.Gui("Add", "Text", "w350 xs", Translate("ScriptDescription"))
        
        this.Font("s11 bold")
        this.Gui("Add", "Text", "w350 xs", Translate("TeamHeader"))
        this.Font("s10 normal")
        this.Gui("Add", "Text", "w350 xs", Translate("InfoTeam"))

        this.Font("s11 bold")
        this.Gui("Add", "Text", "w350 xs", Translate("BattlesHeader"))
        this.Font("s10 normal")
        this.Gui("Add", "Text", "w350 xs", Translate("InfoBattles"))

        this.Font("s11 bold")
        this.Gui("Add", "Text", "w350 xs", Translate("TimeHeader"))
        this.Font("s10 normal")
        this.Gui("Add", "Text", "w350 xs", Translate("InfoTime"))

        this.Font("s11 bold")
        this.Gui("Add", "Text", "w350 xs", Translate("StartHeader"))
        this.Font("s10 normal")
        this.Gui("Add", "Text", "w350 xs", Translate("InfoStart"))
        
        this.Gui("Add", "Text", "w350 xs Section")
        this.backButton := this.Gui("Add", "Button", "Section w100 h30 " Constants.SS_CENTERIMAGE " Center Default", Translate("ButtonAboutBack"))
        this.GuiControl("+g", this.backButton, this.BackButtonPressed)
		
        ;this.Show("xCenter y100 AutoSize", Constants.ScriptTitle)		
	}

    BackButtonPressed(){
        GoSub ShowMain
        this.Hide()
    }

    AddListener(controller)
    {
        this.controller := controller
    }
}