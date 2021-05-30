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


;;; Auto-execute section
    #NoEnv                          ; Recommended for performance and compatibility with future AutoHotkey releases.
    ;#Warn                          ; Enable warnings to assist with detecting common errors.
    SendMode Input                  ; Recommended for new scripts due to its superior speed and reliability.
    StringCaseSense On              ; Make string comparisons case sensitive, not sensitives b default
    SetWorkingDir %A_ScriptDir%     ; Ensures a consistent starting directory.
    #SingleInstance Force           ; Only one instance
    #MaxThreadsPerHotkey 1          ; Only one thread
    SetTitleMatchMode 3             ; Exact title match
    SetBatchLines, -1               ; Improve performance
    DllCall("dwmapi\DwmEnableComposition", "uint", 0)
    OnExit, Shutdown

    #Include lib\CGui.ahk
    #Include lib\Gdip_All.ahk
    #Include lib\GDIpHelper.ahk
    #Include lib\CsvTableFunctions.ahk
    #Include lib\i18n.ahk
    ;#Include src\GraphicDetector.ahk
    #Include src\Constants.ahk
    #Include src\Options.ahk
    #Include src\UMB.ahk
    #Include src\controller\UMB_Controller.ahk
    #Include src\model\UMB_Model.ahk
    #Include src\view\UMB_View.ahk
    #Include src\LanguageDetector.ahk

    Program := new UMB()
    Program.Start()
    
return ; End of Auto-execute section

; Labels redirection to UMB
OnMenuClicked:
    Program.OnMenuClicked()
    return

GuiClose:
    Program.OnGuiClose()
    return

Shutdown:
    Program.ShutDown()
    return
