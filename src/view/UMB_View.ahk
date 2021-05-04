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
        this.runningView := new RunningView()
        this.resultView := new ResultView()
        this.aboutView := new AboutView()
        this.helpView := new HelpView()
    }

    ShowGui() {
        this.helpView.Show("xCenter y100 AutoSize", Constants.ScriptTitle)
    }

    AddListener(controller)
    {
        this.controller := controller
        this.mainView.AddListener(controller)
        this.runningView.AddListener(controller)
        this.resultView.AddListener(controller)
        this.aboutView.AddListener(controller)
        this.helpView.AddListener(controller)
    }
}
