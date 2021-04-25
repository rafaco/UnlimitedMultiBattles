#NoEnv
#SingleInstance Force
SetBatchLines, -1
Process, Priority,, High
SetTitleMatchMode, 3
OnExit, EXIT_LABEL

#Include ..\lib\Gdip_ImageSearch.ahk
#Include ..\lib\Gdip_All.ahk

gdipToken := Gdip_Startup()
Loop
{
    bmpHaystack := Gdip_BitmapFromHWND(WinExist("Raid: Shadow Legends")) ;"Fotos: screenshot_game.jpg"
    bmpNeedle := Gdip_CreateBitmapFromFile("..\images\queries\Home_BattleIcon.png")
    resultList := ""
    resultCount := Gdip_ImageSearch(bmpHaystack,bmpNeedle,resultList,0,0,0,0,0,0,1,10)
}
Until resultCount = 1
MsgBox Success

EXIT_LABEL:
    Gdip_Shutdown(gdipToken)

EXITAPP