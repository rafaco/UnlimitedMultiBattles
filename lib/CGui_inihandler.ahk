; CGui Patch to implement desired Persistent settings technique ========================================================
; OnChange is a class function that normally does nothing. The rest of this class is specific to your implementation

; Implement GuiControl persistence with IniRead / IniWrite
class CGui extends _CGui {
;class CWindow extends _CScrollGui {
	Class _CGuiControl extends _CGui._CGuiControl {
		__New(aParams*){
			base.__New(aParams*)
			; Work out name of INI
			SplitPath, A_ScriptName,,,,ScriptName
			this._ScriptName .= ScriptName ".ini"
		}
		; hook into the onchange event
		OnChange(){
			; IniWrite
			if (this._PersistenceName){
				IniWrite, % this.value, % this._ScriptName, Settings, % this._PersistenceName
			}
		}
		
		; Set a GuiControl to be persistent.
		; If called on a GuiControl, and there is an existing setting for it, set the control to the setting value
		MakePersistent(Name){
			; IniRead
			this._PersistenceName := Name
			IniRead, val, % this._ScriptName, Settings, % this._PersistenceName, -1
			if (val != -1){
				this.value := val
			}
		}
	}
}
