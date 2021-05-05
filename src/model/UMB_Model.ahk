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

#Include src\model\SettingsModel.ahk
#Include src\model\LanguageModel.ahk
#Include src\model\CalculatorModel.ahk

class UMB_Model
{

    __New(){
        this.Settings   := new SettingsModel()
        this.Language   := new LanguageModel(this.Settings)
        this.Calculator := new CalculatorModel(this.Settings)
    }

    GetValue(key)
    {
        if (key in this.Calculator.values) {
            return this.Calculator.values[key]
        }
        return this.Settings.GetValue(key)
    }

    Save(key, value)
    {
        this.Settings.Save(key, value)
        if (key == "lang") {
            ;Save to language 
        }
        Calculator.Update()
    }

    GetViewModel(viewName)
    {
        if (viewName = "Main")
        {
            return { settings   : this.Settings.values
                   , results    : this.Calculator.values}
        }
    }
}
