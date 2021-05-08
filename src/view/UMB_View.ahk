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

#Include src\view\MainView.ahk
#Include src\view\RunningView.ahk
#Include src\view\ResultView.ahk
#Include src\view\AboutView.ahk
#Include src\view\HelpView.ahk

class UMB_View  {

	__New(){
        this.mainView := new MainView()
        this.secondarView := ""
        ;this.runningView := new RunningView()
        ;this.resultView := new ResultView()
        ;this.aboutView := new AboutView()
        ;this.helpView := new HelpView()
    }

    Show(viewName, data:="") {
        Gui,+LastFound
        if (not A_Gui) {
            options := "xCenter y100 AutoSize"
        }
        else{
            WinGetPos, X, Y, W, H, % Constants.RaidWinTitle
            if (viewName == "Running" && A_Gui != "Result"){
                X += 50
                Y += 200
            }
            else if (viewName == "ShowMain"){
                if (A_Gui="Running" || A_Gui="Result"){
                    X -= 50
                    Y -= 200
                }
            }
            options := "x" X " y" Y
        }
        

        if (viewName = "Main") {
            this.secondarView.Hide()
            this.mainView.LoadData(data)
            this.mainView.Show(options, Constants.ScriptTitle)
            this.isMainView := true
        }
        else{
            this.mainView.Hide()
            if (viewName = "Result"){
                this.secondarView := new ResultView()
            }
            else if (viewName = "Running"){
                this.secondarView := new RunningView()
            }
            else if (viewName = "About"){
                this.secondarView := new AboutView()
            }
            else if (viewName = "Help"){
                this.secondarView := new HelpView()
            }
            this.secondarView.AddListener(this.controller)   
            this.secondarView.Show(options, Constants.ScriptTitle)
            this.isMainView := false
        }
    }

    Update(data, changed) {
        if (this.isMainView) {
            this.mainView.LoadData(data, changed)
        }
        else{
            this.secondaryView.LoadData(data, changed)
        }
    }

    UpdateScrollButton(isScrollEnabled)
    {
        this.mainView.UpdateScrollButton(isScrollEnabled)
    }

    AddListener(controller)
    {
        this.controller := controller
        this.mainView.AddListener(controller)
    }
}
