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

class CalculatorModel
{
    ;this.settings := {}
    ;this.XpData := {}
    ;this.CampaignData := {}
    ;this.values := {}

    __New(ByRef settingsModel){
        this.settings := settingsModel.values
        this.XpData := this.ReadXpData()
        this.CampaignData := this.ReadCampaignData()
        this.Update()
    }

    ReadXpData()
    {
        xpDataFullPath := Constants.LocalFolder() . Constants.FolderSeparator . Constants.XpDataFileName
        FileInstall, data\XpData.csv, % xpDataFullPath
        return ReadTable(xpDataFullPath, {"Headers" : True}, xpColumnNames)
    }
    
    ReadCampaignData()
    {
        campaignDataFullPath := Constants.LocalFolder() . Constants.FolderSeparator . Constants.CampaignDataFileName
        FileInstall, data\CampaignData.csv, % campaignDataFullPath
        return ReadTable(campaignDataFullPath, {"Headers" : True}, campaignColumnNames)
    }

    Update()
    {
        levelsToMax := ((this.settings.rank) * 10) - (this.settings.level)
        Loop,%levelsToMax%{
            currentLevel    := this.settings.level + A_Index - 1
            currentXp       := this.XpData[currentLevel][this.settings.rank]
            requiredXP      += currentXp
        }
        campaignLine    := ((this.settings.map-1) * 21) + ((this.settings.difficulty-1) * 7) + this.settings.stage
        stageXp         := this.CampaignData[campaignLine]["XP"]
        stageEnergy     := this.CampaignData[campaignLine]["Energie"]
        stageSilver     := this.CampaignData[campaignLine]["Silver"]
        boostOptionsMultiplier := [1, 1.2, 2, 2.4]
        boostedXp       := stageXp * boostOptionsMultiplier[this.settings.boost]
        championXp      := boostedXp/4
        
        repetitions     := Floor(requiredXP / championXp) + 1
        energySpent     := stageEnergy * repetitions
        silverEarned    := stageSilver * repetitions

        manualTime      := this.PrettyFormatDuration(Settings.second, Settings.minute, Settings.battles)
        calculatedTime  := this.PrettyFormatDuration(Settings.second, Settings.minute, calculatedResults.repetitions)
        infiniteTime    := this.PrettyFormatDuration(Settings.second, Settings.minute, -1)

        this.values     := { repetitions: repetitions
                           , energy: energySpent
                           , silver: silverEarned
                           , manualTime: manualTime
                           , calculatedTime: calculatedTime
                           , infiniteTime: infiniteTime }
    }

    PrettyFormatDuration(seconds, minutes, repetitions){
        totalSeconds := (seconds + ( minutes * 60 )) * repetitions
        totalMinutes := Floor(totalSeconds / 60)
        infiniteMode := (repetitions=-1)
        if (infiniteMode){
            text := "Infinite" 
        }
        else if (totalMinutes=0){
            text := "Less than a minute" 
        }
        else if (totalMinutes<60){
            text := totalMinutes . " minutes"
        }
        else{
            totalHours := Floor(totalMinutes / 60)
            additionalMinutes := totalMinutes - (totalHours*60)
            text := totalHours . " hours and " . additionalMinutes . " minutes"
        }
        if (!infiniteMode){
            text .= " aprox."
        }
        return text
    }

    FormatNumber(num){
        ; Add thousands searators
        return RegExReplace(num, "\G(?:-?)\d+?(?=(\d{3})+(?:\D|$))", "$0.")
    }
}
