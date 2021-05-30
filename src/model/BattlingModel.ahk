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

;TODO: remove all global keywords
Class BattlingModel {

    __New(model)
    {
        this.model := model
    }

    StartDetectionTest() {
        ; Using GDIP ImageDetector dont requiere WinActivate!
        ;WinActivate, %Constants.RaidWinTitle%
        ;screenDetector := new GraphicDetector()
        screenDetector := new ImageDetector()
        screenDetector.detectScreen(true)
    }

    ;TODO: relocate to controller?
    ShowTrayTip(title, message)
    {
        TrayTip, %title%, %message%, 20, 17
    }

    StartMultiBattle(controller)
    {   
        this.controller := controller
        this.game := controller.game
        this.isRunning := true
        
        this.updateValuesOnStart()
        this.ShowTrayTip(Constants.ScriptTitle, this.values.notification)

        ; For each battle
        loop {

            ; Stop battling if cancelled or if all repetitions completed
            isCompleted := not this.values.isInfinite && this.values.currentRepetition - 1 > this.values.repetitions
            If (not this.isRunning || isCompleted){
                break
            }
            
            ; Start/Replay battle
            WinGetActiveTitle, PreviouslyActive
            WinActivate, % Constants.RaidWinTitle
            sleep 25    ; TODO: improve by waiting for activation 
            ControlSend, , {Enter}, % Constants.RaidWinTitle
            ControlSend, , r, % Constants.RaidWinTitle
            sleep 25
            WinActivate, %PreviouslyActive%
            
            this.updateValuesOnBattleStart()

            ; For each second between battles
            loop{
                If not this.isRunning 
                    break
                    
                If !isDebug && !WinExist(Constants.RaidWinTitle) {
                    this.isRunning := false
                     this.updateValuesOnFinish("interrupted")
                    this.controller.GoTo("BattlingResult")
                    break
                }
                
                this.updateValuesBetweenBattles()                
                
                ; Keep waiting or start another battle
                if (this.values.currentSecond > this.values.waitSeconds){
                    break
                }
                sleep 1000
                this.values.currentSecond++
            }
        }
        
        if this.isRunning {
            this.updateValuesOnFinish("success")
            this.controller.GoTo("BattlingResult")
        }
    }

    updateValuesOnStart() 
    {
        StartTime := A_TickCount
        replayCounter := 0
        currentRepetition := 0
        repetitions := (this.model.Get("tab") = 1) ? this.model.Get("battles") 
                     : (this.model.Get("tab") = 2) ? this.model.Get("repetitions") 
                     : -1
        isInfinite := (repetitions = -1)
        waitSeconds := this.model.Get("second") + ( this.model.Get("minute") * 60 )
        waitSecondsFormatted := this.FormatSeconds(waitSeconds)
        waitMillis := (waitSeconds * 1000)
        stepProgress1 := 100 / waitSeconds
        stepProgress2 := 100 / repetitions 

        if (isInfinite){
            overview := "Infinited battles, " waitSeconds " seconds each."
            notification := "Starting infinited battles"
        }else{
            totalSeconds := (repetitions * waitSeconds)
            totalMinutes := floor(totalSeconds / 60)
            overview := repetitions " battles of " waitSeconds " seconds"
            notification := "Starting " repetitions " multi-battles (" totalMinutes " min)"
        }

        this.values     := { StartTime: StartTime
                           , replayCounter: replayCounter
                           , currentRepetition: currentRepetition
                           , repetitions: repetitions
                           , isInfinite: isInfinite
                           , waitSeconds: waitSeconds
                           , waitSecondsFormatted: waitSecondsFormatted
                           , waitMillis: waitMillis
                           , stepProgress1: stepProgress1
                           , stepProgress2: stepProgress2
                           , currentProgress1: 0
                           , currentProgress2: 0
                           , currentSecond: 0
                           , overview: overview
                           , notification: notification}

        ; Reset resultValues
        ; TODO: extract to ResultModel? 
        this.resultValues := {}

        this.controller.UpdateView()
    }

    updateValuesOnBattleStart()
    {
        this.values.currentRepetition++
        If (not this.values.isInfinite){
            this.values.currentProgress2 := this.values.currentRepetition * this.values.stepProgress2
        }
        this.values.replayCounter++
        this.values.currentProgress1 := 0
        this.values.currentSecond := 1
        this.values.currentTimeFormatted := this.FormatSeconds(currentSecond)

        If (this.values.isInfinite){
            this.values.multiBattleStatus := this.values.currentRepetition . " / Infinite"
        }else{
            this.values.multiBattleStatus := this.values.currentRepetition . " / " . this.values.repetitions
        }

        this.controller.UpdateView()
    }

    updateValuesBetweenBattles()
    {
        this.values.currentProgress1 := this.values.currentSecond * this.values.stepProgress1
        this.values.currentTimeFormatted := this.FormatSeconds(currentSecond)
        this.values.currentBattleStatus := this.values.currentTimeFormatted . " / " . this.values.waitSecondsFormatted
  
        if (not this.values.isInfinite){
            totalSeconds := (this.values.repetitions * this.values.waitSeconds)
            timeElapsed := (this.values.waitSeconds * (this.values.currentRepetition-1)) + this.values.currentSecond
            timeLeft := totalSeconds - timeElapsed
            if (timeLeft<0){
                timeLeft := 0
            }
            this.values.timeLeftMessage := this.FormatSeconds(timeLeft)
        }
        else {
            this.values.timeLeftMessage := "-"
        }

        this.controller.UpdateView()
    }

    updateSuspendOnFinish(value){
        this.values.suspendOnFinish := value
    }

    updateValuesOnFinish(result)
    {
        ;Stop battling when cancelled or interrupted
        this.isRunning := false

        ;TODO: relocate to BattlingResultModel and receive battlingData as parama
        battlingData := this.values
        
        if (result = "success")
        {
            header := Translate("ResultHeaderSuccess")
            message := Translate("ResultMessageSuccess")
        }
        else if (result = "cancelled")
        {
            header := Translate("ResultHeaderCanceled")
            message := Translate("ResultMessageCanceled")  
        }
        else if (result = "interrupted")
        {
            header := Translate("ResultHeaderInterrupted")
            message := Translate("ResultMessageInterrupted")
        }
        this.ShowTrayTip(Constants.ScriptTitle, message)

        formattedTotal := (battlingData.repetitions=-1) ? "Infinite" : battlingData.repetitions
        formattedBattles := (result = "success") ? battlingData.replayCounter 
                            : battlingData.replayCounter " of " formattedTotal
        fromattedDuration := this.FormatSeconds((A_TickCount - battlingData.StartTime) / 1000)
        formattedDetail := formattedBattles " battles in " fromattedDuration

        this.valuesOnFinish := {  result: result 
                                , suspendOnFinish: this.values.suspendOnFinish
                                , header: header
                                , message: message
                                , detail: formattedDetail }
    }

    onSuccessResult(){
        noActivateFlag := ""            
        if (this.model.Get("onFinish") = 1){
            WinActivate, % Constants.RaidWinTitle
        }
        else if (this.model.Get("onFinish") = 3){
            WinGetActiveTitle, CurrentlyActive
            noActivateFlag := CurrentlyActive != Constants.ScriptTitle ? "NoActivate" : ""
        }
        
        if (this.values.suspendOnFinish = 1){
            ;Reset value for next run
            this.values.suspendOnFinish := 0
            hibernate := 0
            inmediately := 0
            disableWakes := 0
            DllCall("PowrProf\SetSuspendState", "int", hibernate, "int", inmediately, "int", disableWakes)
        }

        ;TODO: onActivate is not use any more!
        
        ; Gui,+LastFound
        ; WinGetPos,x,y
        ; if (A_ThisLabel = "ShowResultSuccess"){
        ;     x += 50
        ;     y += 200
        ; }
        ; Gui, Result:Show, x%x% y%y% %noActivateFlag%, % Constants.ScriptTitle
        ; HideAllGuisBut(AllGuis, "Result")
    }

    FormatSeconds(seconds){
        date = 2000 ;any year above 1600
        date += Floor(seconds), SECONDS
        FormatTime, formattedDate, %date%, mm:ss
        return formattedDate
    }
}