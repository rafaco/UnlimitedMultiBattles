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

#Include src\controller\GameController.ahk
#Include src\ImageDetector.ahk
#Include src\ScrollAssistant.ahk

class UMB_Controller
{
    model := ""
    view := ""

    __new(model,  view)
    {
        this.model := model
        this.view  := view
        this.view.AddListener(this)

        ; Init SERVICES (TODO: relocate to model??)
        this.game := new GameController(this)
        thi.pToken := Gdip_Startup()
        this.scrollAssistant := new ScrollAssistant()
    }

    GoTo(viewName) 
    {
        viewModel := this.model.GetViewModel(viewName)
        this.view.Show(viewName, viewModel)
    }

    OnSettingChanged(key, value) 
    {
        this.model.Set(key, value)
        this.UpdateView(key)
    }

    UpdateView(change:="")
    {
        currentView := this.view.currentViewName
        viewModel := this.model.GetViewModel(currentView)
        this.view.Update(viewModel, change)
    }

    OpenGame()
    {
        this.game.Open()
    }

    StartScroll()
    {
        if (!this.scrollAssistant.isRunning()) {
            this.scrollAssistant.start()
            this.view.UpdateScrollButton(true)
        }
        else {
            scrollAssistant.stop()
            this.view.UpdateScrollButton(false)
        }
    }

    StartDetectionTest()
    {
        if (!this.game.isOpen()){
            this.ShowGameRequiredDialog()
            return
        }

        this.model.Battling.StartDetectionTest()
    }

    StartMultiBattle()
    {
        if (!this.game.isOpen()){
            this.ShowGameRequiredDialog()
            return
        }

        if (this.game.isAdminNeededToSendKeys()){
            this.RunScriptAsAdmin()
            return
        }

        this.view.Show("Battling")
        this.model.Battling.StartMultiBattle(this)
    }

    ShowGameRequiredDialog()
    {
        scriptTitle := Constants.ScriptTitle
        Msgbox, 20, %scriptTitle%, % Translate("UnableToAuto")
        IfMsgbox, no 
        {
            return
        }
        this.game.Open()
    }

    RunScriptAsAdmin()
    {
        scriptTitle := Constants.ScriptTitle
        if A_IsAdmin{
            MsgBox, , %scriptTitle%, % "Skipped: this script is already running as administrator"
            return
        }
        Msgbox, 20, %scriptTitle%, % Translate("UnableToSendKeysToGameMessage")
        IfMsgbox, no 
        {
            return
        }
        Run *RunAs "%A_ScriptFullPath%"
        ExitApp
    }

    ShowTrayTip(title, message)
    {
        TrayTip, %title%, %message%, 20, 17
    }

    OnMenuClicked()
    {
        if (A_ThisMenuItem == Translate("HelpHeader")){
            this.GoTo("Help")
        }
        else if (A_ThisMenuItem == Translate("AboutHeader")){
            this.GoTo("About")
        }else{
            MsgBox, No action for "%A_ThisMenuItem%" in menu "%A_ThisMenu%".
        }
    }

    OnGuiClose()
    {
        if (this.view.currentViewName = "Main")
        {
            ExitApp
        }
        else if (this.view.currentViewName = "Battling")
        {
            this.model.Battling.updateValuesOnFinish("cancelled")
            this.GoTo("BattlingResult")
        }
        else
        {
            this.GoTo("Main") 
        }
    }

    Shutdown()
    {
        this.view.Shutdown()
        Gdip_Shutdown(this.pToken)
    }
}