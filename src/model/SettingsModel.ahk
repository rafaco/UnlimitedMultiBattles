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

class SettingsModel
{
    values := {}

    __New() {
        filecreatedir, % Constants.LocalFolder()
        this.settingsPath := Constants.SettingsFilePath()
        this.settingsSection := Constants.SettingsSection
        this.InitStoredValues()
    }

    Get(key) 
    {
        return this.values[key]
    }

    Set(key, value)
    {
        this.Save(this.settingsPath, this.settingsSection, key, value)
        this.values[key] := value
    }

    Save(settingsPath, settingsSection, key, value) {
        IniWrite, %value%, %settingsPath%, %settingsSection%, %key%
        if ErrorLevel
            MsgBox, Error at IniWrite %key% -> %value%.
    }

    InitStoredValues()
    {    
        If (!FileExist(this.settingsPath)){
            this.InitFromDefault(this.settingsPath, this.settingsSection)
            this.CleanOlderVersionFiles()
        }
        else{
            this.InitFromStorage(this.settingsPath, this.settingsSection)
        }

        ; TODO: VERIFY and REMOVE: 
        ; Seems not needed, can be access by this.values
        ; Usefull to get the naming mapping
        ; selectedTab             := this.values.tab
        ; selectedBoost           := this.values.boost
        ; selectedDifficulty      := this.values.difficulty
        ; selectedMap             := this.values.map
        ; selectedStage           := this.values.stage
        ; selectedRank            := this.values.rank
        ; selectedLevel           := this.values.level
        ; selectedOnFinish        := this.values.onFinish
        ; selectedRaidFilePath    := this.values.customGameFolder
        ; selectedDurationTab     := this.values.durationTab
        
        ; TODO: VERIFY and REMOVE: IMPORTANT! not really in settings
        OnFinishCheckboxValue   := 0
    }
    
    ; Init from default settings (first time)
    InitFromDefault(settingsPath, settingsSection) {
        this.values := Constants.DefaultSettings
        for key, value in this.values {
            if (key="minute" || key="second"){
                SetFormat, Float, 02.0
                value += 0.0
                this.values[key] := value
            }        
            IniWrite, %value%, %settingsPath%, %settingsSection%, %key%
        }
    }

    ; Init from stored settings (following times)
    InitFromStorage(settingsPath, settingsSection) {
        this.values := {}
        for key, defaultValue in Constants.DefaultSettings {
            IniRead, storedValue, %settingsPath%, %settingsSection%, %key%
            if (storedValue="ERROR"){
                ; Key never included or corrupted at setting file. Restore defaultValue.
                IniWrite, %defaultValue%, %settingsPath%, %settingsSection%, %key%
                this.values[key] := defaultValue
            }else{
                this.values[key] := storedValue
            }
        }
    }

    ; Clean older versions ini files
    CleanOlderVersionFiles(){
        settingsPathOld := Constants.SettingsFilePathOld()    ;used on versions 1.0.1
        If (FileExist(settingsPathOld)){
            FileDelete, % settingsPathOld  
        }
        settingsPathOld := Constants.SettingsFilePathOld2()         ;used on versions 1.0.2
        If (FileExist(settingsPathOld)){
            FileDelete, % settingsPathOld  
        }
    }
}
