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

class UMB_Controller
{
    model := "" ;
    view := "" ;

    __new(  model,  view)
    {
        this.model := model ;
        this.view  := view ;
        this.view.AddListener(this) ;
    }

    button1Listener()
    {
        this.model.aSimpleFunction()
        this.view.ed1.text := this.model.aTextVariable
    }
}