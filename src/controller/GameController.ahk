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


class GameController
{

    __new(controller)
    {
        this.controller := controller
        this.model := controller.model
    }

    GetWinTitle()
    {
        return Constants.RaidWinTitle
    }

    GetFullPath()
    {
        fileFolder := this.model.Get("customGameFolder") != "" ? this.model.Get("customGameFolder") : Constants.DefaultGameFolder
        return fileFolder . Constants.FolderSeparator . Constants.RaidFileName
    }

    isOpen()
    {
        return WinExist(this.getWinTitle())
    }

    isAdminNeededToSendKeys()
    {
        currentGameTitle := this.getWinTitle()
        static WM_KEYDOWN=0x100, WM_KEYUP=0x101, vk_to_use=7
        ; Test whether we can send keystrokes to this window.
        ; Use a virtual keycode which is unlikely to do anything:
        PostMessage, WM_KEYDOWN, vk_to_use, 0,, %currentGameTitle%
        if !ErrorLevel
        {   ; Seems best to post key-up, in case the window is keeping track.
            PostMessage, WM_KEYUP, vk_to_use, 0xC0000000,, %currentGameTitle%
            return false
        }
        return true
    }

    Open()
    {
        ; If game is already open, activate their window
        if (this.isOpen()){
            WinActivate, % this.getWinTitle()
            return
        }
        
        fullPath := this.GetFullPath()

        ; If game not in default folder, ask for custom folder 
        if (!FileExist(fullPath)){
            ; Show select custom folder dialog
            FileSelectFolder, OutputVar, , 0, % Translate("UnableToFindGameMessage")
            if (!OutputVar || OutputVar == ""){
                MsgBox, % Translate("NoFolderSelectedMessage")
                return
            }
            newFullPath := OutputVar . Constants.FolderSeparator . Constants.RaidFileName
            if (!FileExist(newFullPath)){
                MsgBox, % Translate("NoGameInFolderMessage")
                return
            }
            
            ; Save custom raid folder
            this.model.Set("customGameFolder", OutputVar)
            fullPath := newFullPath
        }
        
        ; Open game from default or custom folder
        if (FileExist(fullPath))
            Run, %fullPath% --args -gameid=101
    }
}
