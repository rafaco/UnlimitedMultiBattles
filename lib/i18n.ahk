/*
    i18n for AutoHotkey
    Version: 1.0.0
    Author: Maël Schweighardt (https://github.com/iammael/i18n-autohotkey)
    License: MIT (https://github.com/iammael/i18n-autohotkey/blob/master/LICENSE)
*/

Class i18n {
    __New(languageFolder, languageFile, devMode := False)
    {
        this.LanguageFolder := languageFolder
        this.LanguageFile := languageFolder "\" languageFile ".ini"
        this.DevMode := DevMode
        If !FileExist(this.LanguageFile)
        {
            MsgBox, 16, Fatal Error, % "Couldn't load language file '" this.LanguageFile "'. Program aborted."
            ExitApp -1
        }
    }

    ReplaceArgs(textToParse, Byref var, ByRef index) 
    {
        return StrReplace(textToParse, "{" . index . "}", var)
    }
}

Translate(key, args*)
{
    translatedText := GetValueFromIni(key, i18n.LanguageFile)
    ;Deal with error
    If !translatedText
    {
        If i18n.DevMode {
            Loop {
                If translatedText
                    break
                MsgBox, % 16+2, Dev Mode, % "File " i18n.LanguageFile " is missing string for key {" key "}.`nPress Ignore to continue anyway."
                IfMsgBox, Abort
                    ExitApp
                IfMsgBox, Retry
                    translatedText := GetValueFromIni(key, languageFile)
                Else
                    return % "{" key "}"
            }
        }
        Else
            return % "{" key "}"
    }

    ;check and replace args ({1}, {2}, ...)
        Loop % args.MaxIndex()
            translatedText := i18n.ReplaceArgs(translatedText, args[A_Index], A_Index)
    return translatedText
}

GetValueFromIni(ByRef key, ByRef languageFile)
{
    IniRead, readValue, %languageFile%, Strings, %key%, %A_Space%
    
    If !readValue
        return readValue

    translatedText := readValue
    
    ;Check for multiline message (key2, key3 etc...)
    i := 2
    Loop {
        IniRead, readValue, %languageFile%, Strings, %key%%i%, %A_Space%
        If !readValue
            return translatedText
        Else
            translatedText := translatedText . "`n" . readValue
        i++
    }
}
