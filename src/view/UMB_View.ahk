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
#Include src\view\BattlingView.ahk
#Include src\view\BattlingResultView.ahk
#Include src\view\AboutView.ahk
#Include src\view\HelpView.ahk

class UMB_View  {

	__New(){
        this.mainView := new MainView()
        this.secondaryView := ""
    }

    Show(viewName, data:="") {
        Gui,+LastFound
        currentWindowId := A_Gui
        WinGetTitle, currentWindowTitle, ahk_id %A_Gui%
        if (not currentWindowId) {
            params := "xCenter y100 AutoSize"
        }
        else{
            WinGetPos, X, Y, W, H, ahk_id %currentWindowId%
            if (viewName == "Battling" && this.currentViewName != "BattlingResult"){
                ; Going to Battling from Result
                X += 50
                Y += 200
            }
            else if (viewName == "Main"){
                if (this.currentViewName = "Battling" || this.currentViewName = "BattlingResult"){
                    ; Going to Main from Battling or Result 
                    X -= 50
                    Y -= 200
                }
            }
            params := "x" X " y" Y
        }

        if (viewName = "Main") {
            this.secondaryView.Hide()
            this.mainView.LoadData(data)
            this.mainView.Show(params, Constants.ScriptTitle)
            this.isMainView := true
        }
        else{
            this.mainView.Hide()
            this.secondaryView.__Delete()
            this.secondaryView.Destroy()
            if (viewName = "Battling"){
                this.secondaryView := new BattlingView()
            }
            else if (viewName = "BattlingResult"){
                this.secondaryView := new BattlingResultView()
            }
            else if (viewName = "About"){
                this.secondaryView := new AboutView()
            }
            else if (viewName = "Help"){
                this.secondaryView := new HelpView()
            }
            this.secondaryView.AddListener(this.controller)
            this.secondaryView.LoadData(data)
            this.secondaryView.Show(params, Constants.ScriptTitle)
            this.isMainView := false
        }
        this.currentViewName := viewName
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

    Shutdown()
    {
        this.mainView.__Delete()
        this.mainView.Destroy()
        this.secondaryView.__Delete()
        this.secondaryView.Destroy()
    }

    AddListener(controller)
    {
        this.controller := controller
        this.mainView.AddListener(controller)
    }
}
