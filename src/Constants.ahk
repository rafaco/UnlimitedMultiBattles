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

Class Constants {

    ; Program
    static isDebug := false
    static ScriptVersion := "v1.0.6"
    static ScriptTitle := "UnlimitedMultiBattles"
    static ScriptSite := "https://github.com/rafaco/UnlimitedMultiBattles"
    LocalFolder() {
        return A_AppData . this.FolderSeparator . this.ScriptTitle
    }
    
    ; Game
    static RaidWinTitle := "Raid: Shadow Legends"
    static RaidFileName := "PlariumPlay.exe"
    static DefaultGameFolder := A_AppData . "\..\Local\Plarium\PlariumPlay"
    static ViewNames := "Main|Running|Result|Help|About"
    static XpDataFileName := "XpData.csv"
    static CampaignDataFileName := "CampaignData.csv"

    ; Settings
    static SettingsSection := "SettingsSection"
    static DefaultSettings := { minute: 00, second: 25, battles: 10, tab: 2, boost: 3, difficulty: 3, map: 12, stage: 3, rank: 2, level: 1, onFinish: 1, customGameFolder: "", durationTab: 1}
    SettingsFilePath() {
        return this.LocalFolder() . this.FolderSeparator . this.ScriptTitle . ".ini"
    }
    SettingsFilePathOld() {
        return A_ScriptDir . this.FolderSeparator . this.ScriptTitle . ".ini"
    }
    SettingsFilePathOld2() {
        return A_AppData . this.FolderSeparator . this.ScriptTitle . ".ini"
    }
    
    ; Characters
    static FolderSeparator := "\"
    static InfiniteSymbol := Chr(0x221E)
    static StarSymbol := Chr(0x2605)
    static COLOR_GRAY := "c808080"
    static SS_CENTERIMAGE := 0x200
}