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

Class LanguageDetector{

	defaultLang := "en"

	getLanguage(window)
	{
		languageCode := this.getDefaultLCID()
		languageName := this.getNameFromCode(languageCode)
		;MsgBox, 0, LCID, % "DefaultLCID lang: " . languageCode . " --> " . languageName
		if languageName 
			return languageName

		languageCode := this.getKeyboardLanguage(window)
		languageName := this.getNameFromCode(languageCode)
		;MsgBox % "Keyboard lang: " . languageCode . " --> " . languageName
		if languageName 
			return languageName

		languageCode := this.getSystemLanguageCode()
		languageName := this.getNameFromCode(languageCode)
		;MsgBox % "System lang: " . languageCode . " --> " . languageName	
		if languageName 
			return languageName

		;MsgBox % "Default lang: " . defaultLang
		return defaultLang
	}

	getSystemLanguageCode()
	{
		return A_Language
	}

	getKeyboardLanguage(_hWnd=0)
	{
		if !_hWnd
			ThreadId=0
		else
			if !ThreadId := DllCall("user32.dll\GetWindowThreadProcessId", "Ptr", _hWnd, "UInt", 0, "UInt")
				return false
		
		if !KBLayout := DllCall("user32.dll\GetKeyboardLayout", "UInt", ThreadId, "UInt")
			return false
		
		;TODO: seems returning decimal instead of hex and getNameFromCode() always fails
		return KBLayout & 0xFFFF
	}

	getDefaultLCID(LCID := 0x0400) {
		; msdn.microsoft.com/en-us/library/windows/desktop/dd317768(v=vs.85).aspx
		; LOCALE_INVARIANT = 0x007F, LOCALE_SYSTEM_DEFAULT = 0x0800, LOCALE_USER_DEFAULT = 0x0400
		; LOCALE_CUSTOM_DEFAULT = 0x0C00, LOCALE_CUSTOM_UI_DEFAULT = 0x1400, LOCALE_CUSTOM_UNSPECIFIED = 0x1000 <<< Win Vista+
		result := DllCall("ConvertDefaultLocale", "UInt", LCID, "UInt")
		return Format("{:04X}", result)
	}

	getNameFromCode(code)
	{
		if (code="0409" or code="0809" or code="0c09" or code="1009" or code="1409"
			or code="1809" or code="1c09" or code="2009" or code="2409" or code="2809"
			or code="2c09" or code="3009" or code="3409") {
			return "en"
		}
		else if (code="040a" or code="080a" or code="0c0a" or code="100a" or code="140a" 
			or code="180a" or code="1c0a" or code="200a" or code="240a" or code="280a"
			or code="2c0a" or code="300a" or code="340a" or code="380a" or code="3c0a" 
			or code="400a" or code="440a" or code="480a" or code="4c0a" or code="500a") {
			return "es"
		}
		;else if (code="040c" or code="080c" or code="0c0c" or code="100c" or code="140c"
		;		or code="180c") {
		;	return "fr"
		;}
		;else if (code="0416" or code="0816") {
		;	return "pt"
		;}
		return null
	}
}