;#Include ../lib/FindText.ahk

Class ScreenDetector{

	ASCII_Battle_Button:="|<>0xFFFFFF@0.49$66.00000000000000000000000000000000000000001k003zU00001k003zs00Q71k003Vs00Q71k003Us00Q71k003UsDtzTlkTU3UsTxzTlkzk3zkwQQ71llk3zU8QQ71nUs3zs0QQ71nUs3UsDwQ71nzs3UQTQQ71nzs3UQsQQ71nU03UwsQQ71nk03VswQQ71lsk3zsTwD3lkzk3zUDyD3lkTU00000000000000000000000000000000000000000000U"
    ASCII_Battle_Icon:="|<>0xFFFDDF@0.45$43.0000000000000030000001w00001szk0007wDy000Dy7zU00Dz3zs00Dz1zy00DzUTzU0DzkDzs0Dzk7zy0Dzs1zzUDzs0TzsDzs07zwDzs01zz7zs00Tznzw007zwzw001zzDw000Tznw0007zww0001zz80000Tzk00007zw00081zz1U0C6Tzls0Djbzxy07ztzzz03zyTzz00zzbzz00Dztzz003zwTz000zw7zU00zw1zs00zy1zy00zzVzzU0zDsz7s0z3wT3y0z0w70zUz0A10DkD00003k300000k000000000000008"

	detect()
	{
        t1:=A_TickCount

        ;WinGetPos, X, Y, W, H, % RaidWinTitle
        ;MsgBox, Calculator is at %X%,%Y% and its size is %W%x%H%

        ; Reset screen size
        WinGetPos, X, Y, W, H, % RaidWinTitle
        if (W!=1149 or H!=712){
            WinMove, %RaidWinTitle%,, X, Y, 1149, 712
            MsgBox, Game rescaled at %X%,%Y% to 1149x712, it was %W%x%H%.
        }
        
        if (ok:=FindText(767-150000, 693-150000, 767+150000, 693+150000, 0, 0, ASCII_Battle_Button))
        {
        CoordMode, Mouse
        X:=ok.1.x, Y:=ok.1.y, Comment:=ok.1.id
        ; Click, %X%, %Y%
        }

        if (ok2:=FindText(X, Y, W, H, 0, 0, ASCII_Battle_Icon,1,1))
        ; FindText(767-150000, 693-150000, 767+150000, 693+150000, 0, 0, ASCII_Battle_Icon))
        {
        CoordMode, Mouse
        X:=ok.1.x, Y:=ok.1.y, Comment:=ok.1.id
        ; Click, %X%, %Y%
        }

        t1:=A_TickCount-t1

        MsgBox, 4096, ASCII detector, % "Found:`t`t`t" Round(ok.MaxIndex() + ok2.MaxIndex())
        . "`n`nASCII_Battle_Button:`t" (ok ? ok.MaxIndex() : "Failed !")
        . "`n`nASCII_Battle_Icon:`t`t" (ok2 ? ok2.MaxIndex() : "Failed !")
        . "`n`nTime:`t`t`t" (t1) " ms"
        ;. "`n`nPos:`t`t`t" X ", " Y

        for i,v in ok
        if (i<=5)
            FindText.MouseTip(ok[i].x, ok[i].y)

        for i,v in ok2
        if (i<=5)
            FindText.MouseTip(ok2[i].x, ok2[i].y)

    }




    ; From https://www.autohotkey.com/boards/viewtopic.php?t=67417
    FindTextAW(text,err1:=0,err0:=0)
    ; FindText only within the active window.  Much faster if you have a large
    ; desktop or are searching for multiple images.
    ; Input parameters x,y,w,h are not needed in this version and err1 and err0
    ; are optional parameters in case they are needed.
    ; This outputs the same array of x,y,w,h,Comment that the main function returns.
    ; Ben Sacherich - 7/17/2019
    {
        t1:=A_TickCount

        WinGetPos, X, Y, W, H, A  ; "A" to get the active window's position.
        
        ;SoundBeep 423, 100	; Uncomment for debugging.
        
        ; Get the coordinates for the center of the window and pass that to the regular FindText function.
        ; This is needed for FindText versions prior to 6.0
        ;W:=W//2
        ;X+=W
        ;H:=H//2
        ;Y+=H
        ;MsgBox, Searching at %X%`, %Y%, %W%`, %H%

        ;if (ok:=FindText(X, Y, W, H, 0, 0, Text,1,0)) ; Take new Screenshot, Find First
        if (ok:=FindText(X, Y, W, H, 0, 0, Text,1,1)) ; Take new Screenshot, Find All
        {
        CoordMode, Mouse
        X:=ok.1.1, Y:=ok.1.2, W:=ok.1.3, H:=ok.1.4, Comment:=ok.1.5, X+=W//2, Y+=H//2
        }
        t1:=A_TickCount-t1

        ; Show a MouseTip on the first two matches. Uncomment for debugging.
        ;for i,v in ok
        ;  if i<=2
        ;    {
        ;    MouseTip(v.1+v.3//2, v.2+v.4//2)
        ;    Comment.=v.5 ", "
        ;    }

        ;if ok	; Uncomment for debugging.
        ;    MsgBox, 4096, % "FindTextAW", % "Time:`t" (t1) " ms`n`n"
        ;        . "Pos:`t" X ", " Y "`n`n"
        ;        . "Found:`t" ok.MaxIndex() "`n`n"
        ;        . "Result:`t" (ok ? "Success!`n`n" Comment : "Failed!"),5
        return, ok.MaxIndex() ? ok:0
    }
}