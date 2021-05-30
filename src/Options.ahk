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

Class Options {

    BattleAmount() { 
        return this.TranslatedOptions("OptionBattleAmountManual"
                                     ,"OptionBattleAmountCalculated"
                                     ,"OptionBattleAmountInfinite")
    }
    BattleDuration() { 
        return this.TranslatedOptions("OptionBattleDurationAuto"
                                     ,"OptionBattleDurationManual")
    }
    Boost() {
        return this.TranslatedOptions("OptionBoostNo"
                                     ,"OptionBoostRaid"
                                     ,"OptionBoostXP"
                                     ,"OptionBoostBoth")
    }
    Difficulty() { 
        return this.TranslatedOptions("OptionDifficultyNormal"
                                     ,"OptionDifficultyHard"
                                     ,"OptionDifficultyBrutal")
    }
    Map() { 
        return this.GenerateNumericOptions(12)
    }
    Stage() { 
        return this.GenerateNumericOptions(7)
    }
    Rank() { 
        return this.GenerateRankOptions()
    }
    OnFinish() { 
        return this.TranslatedOptions("OptionBattlingOnFinishGame"
                                     ,"OptionBattlingOnFinishThis"
                                     ,"OptionBattlingOnFinishNothing")
    }


    TranslatedOptions(params*) {
        for index,param in params {
            List .= Translate(param)
            if (index!=params.MaxIndex()){
                List .= "|"
            }
        }
        return List
    }

    GenerateNumericOptions(items){
        Loop,%items%{
            List .= A_Index
            if (A_Index!=items){
                List .= "|"
            }
        }
        return List
    }

    GenerateRankOptions(){
        ranks := 6
        Loop,%ranks%{
            currentItem := currentItem . Constants.StarSymbol
            List .= currentItem
            if (A_Index!=ranks){
                List .= "|"
            }
        }
        return List
    }

}