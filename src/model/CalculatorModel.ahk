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
    ;this.results := {}

    __New(ByRef settingsModel){
        this.settings := settingsModel.values
        InitCalculator()
    }

    InitCalculator()
    {
        xpDataFullPath := Constants.LocalFolder() . Constants.FolderSeparator . Constants.XpDataFileName
        FileInstall, data\XpData.csv, % xpDataFullPath
        this.XpData := ReadTable(xpDataFullPath, {"Headers" : True}, xpColumnNames)

        campaignDataFullPath := Constants.LocalFolder() . Constants.FolderSeparator . Constants.CampaignDataFileName
        FileInstall, data\CampaignData.csv, % campaignDataFullPath
        this.CampaignData := ReadTable(campaignDataFullPath, {"Headers" : True}, campaignColumnNames)
        
        this.results := this.CalculateResults()

        ;TODO: RELOCATE: this dont belong here
        initialLevelOptions := Options.GenerateNumericOptions((selectedRank*10)-1)
    }

    CalculateResults(){

        levelsToMax := ((this.settings.rank) * 10) - (this.settings.level)
        Loop,%levelsToMax%{
            currentLevel := this.settings.level + A_Index - 1
            currentXp := xpData[currentLevel][this.settings.rank]
            requiredXP += currentXp
        }
        campaignLine := ((this.settings.map-1) * 21) + ((this.settings.difficulty-1) * 7) + this.settings.stage
        stageXp := campaignData[campaignLine]["XP"]
        stageEnergy := campaignData[campaignLine]["Energie"]
        stageSilver := campaignData[campaignLine]["Silver"]
        boostOptionsMultiplier := [1, 1.2, 2, 2.4]
        boostedXp := stageXp * boostOptionsMultiplier[this.settings.boost]
        championXp := boostedXp/4
        
        repetitions := Floor(requiredXP / championXp) + 1
        energySpent := stageEnergy * repetitions
        silverEarned := stageSilver * repetitions
        result := { repetitions: repetitions, energy: energySpent, silver: silverEarned }
        
        return result
    }
}
