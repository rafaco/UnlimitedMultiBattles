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

Class AboutView extends CGui {

	__New(aParams*){

		global BorderState
		base.__New(aParams*)

        this.Font("s10 bold")
        this.Gui("Add", "Text", "w350 h35 xp yp " Constants.SS_CENTERIMAGE " BackgroundTrans Section Center", Constants.ScriptTitle " " Constants.ScriptVersion)
        
        this.Font("s10 norm")
        this.Gui("Add", "Text", "w350 xs Section", Translate("ProjectDescription"))
        this.backButton := this.Gui("Add", "Button", "Section w100 h30 gShowMain " Constants.SS_CENTERIMAGE " Center Default", Translate("ButtonAboutBack"))
        this.GuiControl("+g", this.backButton, this.BackButtonPressed)

        this.Gui("Add", "Text", "w120 ys Section")
        this.githubButton := this.Gui("Add", "Button", "ys w100 h30 gGoToSite " Constants.SS_CENTERIMAGE " Center", Translate("ButtonAboutRepo"))
        this.GuiControl("+g", this.githubButton, this.GithubButtonPressed)
		
        ;this.Show("xCenter y100 AutoSize", Constants.ScriptTitle)		
	}

    BackButtonPressed(){
        GoSub ShowMain
        this.Hide()
    }

    GithubButtonPressed(){
        GoSub GoToSite
    }

    AddListener(controller)
    {
        this.controller := controller
    }
}