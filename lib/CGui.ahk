; Source:  https://github.com/evilC/CGui
;
; Modified by rafaco for Unlimited MultiBattles
;   - Remove #SingleInstance force
;   - Modified #include <CGui_inihandler>
;   - Removed sample
;   - Commented labels for sample


; REQUIRES AHK >= v1.1.20.00
; DEPENDENCIES:
; _Struct():  https://raw.githubusercontent.com/HotKeyIt/_Struct/master/_Struct.ahk - docs: http://www.autohotkey.net/~HotKeyIt/AutoHotkey/_Struct.htm
; sizeof(): https://raw.githubusercontent.com/HotKeyIt/_Struct/master/sizeof.ahk - docs: http://www.autohotkey.net/~HotKeyIt/AutoHotkey/sizeof.htm
; WinStructs: https://github.com/ahkscript/WinStructs

#include <_Struct>
#include <WinStructs>
#include <CGui_inihandler>

;Esc::
;GuiClose:
;	ExitApp

; Wraps All Gui commands - Guis and GuiControls
class _CGui extends _CGuiBase {
	_type := "w"	; Window Type
	
	_ChildGuis := {}
	_ChildControls := {}
	
	; ScrollInfo array - Declared as associative, but consider 0-based indexed. 0-based so SB_HORZ / SB_VERT map to correct elements.
	_ScrollInfos := {0: 0, 1: 0}
	
	; ========================================== GUI COMMAND WRAPPERS =============================
	; Equivalent to Gui, New
	__New(parent := 0, options := 0, aParams*){
		Static SB_HORZ := 0, SB_VERT := 1
		static WM_MOVE := 0x0003, WM_SIZE := 0x0005
		static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
		Static WM_MOUSEWHEEL := 0x020A, WM_MOUSEHWHEEL := 0x020E
		;static WM_CLOSE := 0x0010

		this._parent := parent

		Gui, new, % "hwndhwnd " options
		this._hwnd := hwnd
		
		if (this._parent != 0){
			this._parent._ChildGuis[this._hwnd] := this
		}
		
		; Initialize page and range classes so that all values read 0
		this._RangeRECT := new this.RECT()
		this._PageRECT := new this.RECT()
		this._WindowRECT := new this.RECT()
		;this._TestRECT := new this.RECT()
		
		; Initialize scroll info array
		this._ScrollInfos := {0: this._DLL_GetScrollInfo(SB_HORZ), 1: this._DLL_GetScrollInfo(SB_VERT)}
		
		; Register for ReSize messages
		this._RegisterMessage(WM_SIZE,this._OnSize)
		
		; Register for scroll (drag of thumb) messages
		this._RegisterMessage(WM_HSCROLL,this._OnScroll)
		this._RegisterMessage(WM_VSCROLL,this._OnScroll)
		
		; Register for move message.
		this._RegisterMessage(WM_MOVE,this._OnMove)
		
		; Mouse Wheel
		this._RegisterMessage(WM_MOUSEWHEEL,this._OnWheel)
		this._RegisterMessage(WM_MOUSEHWHEEL,this._OnWheel)
		
		; Close Gui - need method
		;this._RegisterMessage(WM_CLOSE, this._OnExit)
		
	}

	__Delete(){
		;MsgBox % "GUI DELETE - " this._hwnd
		Gui, % this._hwnd ":Destroy"
		;this._parent._GuiChildChangedRange()
		; If top touches range top, left touches page left, right touches page right, or bottom touches page bottom...
		; Removing this GuiControl should trigger a RANGE CHANGE.
		; Same for Gui, Hide?
	}

	Destroy(){
		this._ChildControls := ""
		for msg in _CGui._MessageArray {
			for hwnd in _CGui._MessageArray[msg] {
				if (hwnd = this._hwnd){
					; ALWAYS use .Remove(key, "") else indexes of remaining keys will be altered.
					_CGui._MessageArray[msg].Remove(hwnd,"")
				}
			}
		}
		;MsgBox % this._hwnd
		this._parent._ChildGuis.Remove(this._hwnd, "")
		this._parent._GuiChildChangedRange()
		; Remove all child objects that could stop __Delete firing.
		for key in this {
			if (this[key]._parent = this){
				this[key]._parent := ""
			}
		}
	}
	
	; Simple patch to prefix Gui commands with HWND
	PrefixHwnd(cmd){
		return this._hwnd ":" cmd
	}

	; Equivalent to Gui, Show
	Show(options := "", title := ""){
		Gui, % this.PrefixHwnd("Show"), % options, % title
		;this._GuiSetWindowRECT()
		if (this._parent != 0){
			; Parent GUIs get a WM_MOVE message at start - emulate for children.
			this._OnMove()
		}
	}
	
	; Equivalent to Gui, Hide
	Hide(options := ""){
		Gui, % this.PrefixHwnd("Hide"), % options
	}

	; Equivalent to Gui, Font
	Font(options := ""){
		Gui, % this.PrefixHwnd("Font"), % options
	}

	; Wrapper for Gui commands
	Gui(cmd, aParams*){
		if (cmd = "add"){
			; Create GuiControl
			obj := new this._CGuiControl(this, aParams*)
			return obj
		} else if (cmd = "new"){
			obj := new _CGui(this, aParams*)
			return obj
		}
	}

	; Wraps GuiControl to use hwnds and function binding etc
	GuiControl(cmd := "", ctrl := "", Param3 := ""){
		m := SubStr(cmd,1,1)
		if (m = "+" || m = "-"){
			; Options
			o := SubStr(cmd,2,1)
			if (o = "g"){
				; Bind g-label to _glabel property
				fn := Param3.Bind(this)
				ctrl._glabel := fn
				return this
			}
		} else {
			GuiControl, % this._hwnd ":" cmd, % ctrl._hwnd, % Param3
			return this
		}
	}
	
	; Wraps GuiControlGet
	GuiControlGet(cmd := "", ctrl := "", param4 := ""){
		GuiControlGet, ret, % this._hwnd ":" cmd, % ctrl._hwnd, % Param4
		return ret
	}
	; ========================================== DIMENSIONS =======================================

	/*
	; The PAGE (Size of window) of a Gui / GuiControl changed. For GuiControls, this is the size of the control
	_GuiPageGetRect(){
		RECT := this._DLL_GetClientRect()
		return RECT
	}
	*/

	; A Child of this window changed it's usage of this window's RANGE (in other words, it moved or changed size)
	; old = the Child's old WindowRECT
	_GuiChildChangedRange(Child := 0, old := 0){
		static opposites := {top: "bottom", left: "right", bottom: "top", right: "left"}
		shrank := 0
		
		if (child = 0){
			; Destroy
			Count := 0
			for childHwnd in this._ChildGuis {
				if (!Count){
					this._RangeRECT := new this.RECT()
					this._RangeRECT.Union(this._ChildGuis[childHwnd]._WindowRECT)
					Count++
					continue
				}
				this._RangeRECT.Union(this._ChildGuis[childHwnd]._WindowRECT)
			}
			this._GuiSetScrollbarSize()
			return
		}
		if (!this._RangeRECT.contains(Child._WindowRECT)){
		;if (this._RangeRECT.Union(Child._WindowRECT)){
			this._RangeRECT.Union(Child._WindowRECT)
			this._GuiSetScrollbarSize()
		} else {
			; Detect if child touching edge of range.
			; set the new _WindowRECT and find out how much we moved, and in what direction.
			moved := this._GuiGetMoveAmount(old, Child._WindowRECT)
			for dir in opposites {
				;if (dir = "down"){
					;ToolTip % "moved " this._SerializeRECT(moved)
				;}
				if (moved[dir] > 0){
					;shrank := 1
					opp := opposites[dir]
					;ToolTip % this.name "-" dir "`nOld: " old[opp] " = " this._RangeRECT[opp] " ?"
					if (old[opp] = this._RangeRECT[opp]){
						shrank := 1
						break
					}
				}
			}
			if (shrank){
				; The child was touching an edge of our RANGE, and moved away from it ...
				; ... Union WindowRECTs of all *other* children to see if this child is the only one needing that part of the range ...
				; ... And if so, shrink our Range.

				Count := 0
				for childHwnd in this._ChildGuis {
					if (childHwnd = child._hwnd){
						;MsgBox % "Skipping " this._ChildGuis[childHwnd].name
						continue
					}
					if (!Count){
						this._RangeRECT := new this.RECT()
						this._RangeRECT.Union(this._ChildGuis[childHwnd]._WindowRECT)
						;MsgBox % "including " this._ChildGuis[childHwnd].name
						Count++
						continue
					}
					;MsgBox % "including " this._ChildGuis[childHwnd].name
					this._RangeRECT.Union(this._ChildGuis[childHwnd]._WindowRECT)
					Count++
				}
				;if (!this._RangeRECT.contains(old[childHwnd]._WindowRECT)){
				if (!this._RangeRECT.contains(Child._WindowRECT)){
					this._RangeRECT.Union(Child._WindowRECT)
					this._GuiSetScrollbarSize()
				}
			}
			/*
			if (shrank){
				ToolTip % this.name " shrank`n" this._SerializeRECT(this._RangeRECT) "`nChild: " this._SerializeRECT(Child._WindowRECT)
			} else {
				ToolTip
			}
			*/
		}
		;ToolTip % A_ThisFunc "`nOld: " this._SerializeRECT(oldrange) "`nNew: " this._SerializeRECT(this._RangeRECT)
	}

	/*
	; Works out how big a window's caption / borders are and alters passed coords accordingly.
	ConvertCoords(coords,hwnd){
		static WS_BORDER := 0x00800000, SM_CYCAPTION := 4
		VarSetCapacity(wi,60)
		DllCall("GetWindowInfo","PTR",hwnd,"PTR",&wi)
		; Find size of frame (sizing handles - usually 3px)
		Frame := NumGet(&wi,48,"UInt")
		; Does this window have a "caption" (Title)
		Caption := NumGet(&wi,36,"UInt")
		Caption := Caption & WS_BORDER
		if (Caption = WS_BORDER){
			; Yes - get size of caption
			TitleBar := DllCall("GetSystemMetrics","Int", SM_CYCAPTION)
		} else {
			; No, window is -Border
			TitleBar := 0
		}
		; Adjust coords
		coords := {x: coords.x, y: coords.y}
		;ToolTip % coords.x
		coords.x -= Frame
		coords.y -= TitleBar + Frame
		return coords
	}
	*/

	; ========================================== SCROLL BARS ======================================

	; Is the scrollbar at maximum? (ie all the way at the end).
	_IsScrollBarAtMaximum(bar){
		end := this._ScrollInfos[bar].nPos + this._ScrollInfos[bar].nPage
		diff := ( this._ScrollInfos[bar].nMax - end ) * -1
		if (diff > 0){
			return diff
		} else {
			return 0
		}
	}
	
	; Set the POSITION component of a scrollbar
	_GuiSetScrollbarPos(nTrackPos, bar){
		Static SB_HORZ := 0, SB_VERT := 1
		static SIF_POS := 0x4
		
		this._ScrollInfos[bar].fMask := SIF_POS
		this._ScrollInfos[bar].nPos := nTrackPos
		this._DLL_SetScrollInfo(bar, this._ScrollInfos[bar])
	}
	
	; Set the SIZE component(s) of a scrollbar - PAGE and RANGE
	; bars = 0 = SB_HORZ
	; bars = 1 = SB_VERT
	; bars = 2 (or omit bars) = both bars
	_GuiSetScrollbarSize(bars := 2, PageRECT := 0, RangeRECT := 0, mode := "b"){
		Static SB_HORZ := 0, SB_VERT := 1
		static SIF_DISABLENOSCROLL := 0x8
		static SIF_RANGE := 0x1, SIF_PAGE := 0x2, SIF_POS := 0x4, SIF_ALL := 0x17
		; Index Min / Max property names of a RECT by SB_HORZ = 0, SB_VERT = 1
		static RECTProperties := { 0: {min: "Left", max: "Right"}, 1: {min: "Top", max: "Bottom"} }
		
		; Determine what part of the scrollbars we wish to set.
		if (mode = "p"){
			; Set PAGE
			mask := SIF_PAGE
		} else if (mode = "r"){
			; Set RANGE
			mask := SIF_RANGE
		} else {
			; Default to SET PAGE + RANGE
			mask := SIF_PAGE | SIF_RANGE
		}
		;mask |= SIF_DISABLENOSCROLL	; If the scroll bar's new parameters make the scroll bar unnecessary, disable the scroll bar instead of removing it
		;mask := SIF_ALL

		; If no RECTs passed, use class properties
		if (PageRECT = 0){
			PageRECT := this._PageRECT
		}
		if (RangeRECT = 0){
			RangeRECT := this._RangeRECT
		}
		
		; Alter scroll bars due to client size
		Loop 2 {
			bar := A_Index - 1 ; SB_HORZ = 0, SB_VERT = 1
			if ( ( bar=0 && (bars = 0 || bars = 2) )   ||  ( bar=1 && bars > 0 ) ){
				; If this scroll bar was specified ...
				; ... Adjust this window's ScrollBar Struct as appropriate, ...
				this._ScrollInfos[bar].fMask := mask
				if (mask & SIF_RANGE){
					; Range bits set
					this._ScrollInfos[bar].nMin := RangeRECT[RECTProperties[bar].min]
					this._ScrollInfos[bar].nMax := RangeRECT[RECTProperties[bar].max]
				}
				
				if (mask & SIF_PAGE){
					; Page bits set
					this._ScrollInfos[bar].nPage := PageRECT[RECTProperties[bar].max]
				}
				; ... Then update the Scrollbar.
				this._DLL_SetScrollInfo(bar, this._ScrollInfos[bar])
			}
			
			; If a vertical scrollbar is showing, and you are scrolled all the way to the bottom of the page...
			; ... If you grab the bottom edge of the window and size up, the contents must scroll downwards.
			; I call this a Size-Scroll.
			if (this._ScrollInfos[bar].nPage <= this._ScrollInfos[bar].nMax){
				; Page (Size of window) is less than Max (Size of contents) - scrollbars will be showing.
				diff := this._IsScrollBarAtMaximum(bar)
				
				if (diff > 0){
					; diff is positive, Size-Scroll required
					; Set up vars for call
					if (bar) {
						h := 0
						v := diff
					} else {
						h := diff
						v := 0
					}
					; Size-Scroll the contents.
					this._DLL_ScrollWindows(h,v)
					if (bar){
						this._ScrollInfos[bar].nPos -= v
					} else {
						this._ScrollInfos[bar].nPos	-= h
					}
				}
			}
		}
	}

	; Sets cbSize, returns blank scrollinfo
	_BlankScrollInfo(){
		lpsi := new _Struct(WinStructs.SCROLLINFO)
		lpsi.cbSize := sizeof(WinStructs.SCROLLINFO)
		return lpsi
	}

	; ========================================== DLL CALLS ========================================

	; ACCEPTS x, y
	; Returns a POINT
	_DLL_ScreenToClient(hwnd, x, y){
		; https://msdn.microsoft.com/en-gb/library/windows/desktop/dd162952(v=vs.85).aspx
		lpPoint := new _Struct(WinStructs.POINT, {x: x, y: y})
		r := DllCall("User32.dll\ScreenToClient", "Ptr", hwnd, "Ptr", lpPoint[], "Uint")
		return lpPoint
	}
	
	_DLL_MapWindowPoints(hwndFrom, hwndTo, ByRef lpPoints, cPoints := 2){
		; https://msdn.microsoft.com/en-gb/library/windows/desktop/dd145046(v=vs.85).aspx
		;lpPoints := new _Struct(WinStructs.RECT)
		r := DllCall("User32.dll\MapWindowPoints", "Ptr", hwndFrom, "Ptr", hwndTo, "Ptr", lpPoints[], "Uint", cPoints, "Uint")
		return lpPoints
	}
	
	; Wraps ScrollWindow() DLL Call.
	_DLL_ScrollWindows(XAmount, YAmount, hwnd := 0){
		; https://msdn.microsoft.com/en-us/library/windows/desktop/bb787591%28v=vs.85%29.aspx
		if (!hwnd){
			hwnd := this._hwnd
		}
		;tooltip % "Scrolling " hwnd
		return DllCall("User32.dll\ScrollWindow", "Ptr", hwnd, "Int", XAmount, "Int", YAmount, "Ptr", 0, "Ptr", 0)
	}

	; Wraps ScrollWindow() DLL Call.
	_DLL_ScrollWindow(bar, Amount, hwnd := 0){
		; https://msdn.microsoft.com/en-us/library/windows/desktop/bb787591%28v=vs.85%29.aspx
		if (!hwnd){
			hwnd := this._hwnd
		}
		if (bar){
			XAmount := 0
			YAmount := Amount
		} else {
			XAmount := Amount
			YAmount := 0
		}
		;tooltip % "Scrolling " hwnd
		return DllCall("User32.dll\ScrollWindow", "Ptr", hwnd, "Int", XAmount, "Int", YAmount, "Ptr", 0, "Ptr", 0)
	}

	/*
	; Wraps GetClientRect() Dll call, returns RECT class (Not Structure! Class!)
	_DLL_GetClientRect(hwnd := 0){
		if (hwnd = 0){
			hwnd := this._hwnd
		}
		RECT := new this.RECT()
		DllCall("User32.dll\GetClientRect", "Ptr", hwnd, "Ptr", RECT[])
		return RECT
	}
	*/
	
	; Wraps SetScrollInfo() Dll call.
	; Returns Dll Call return value
	_DLL_SetScrollInfo(fnBar, ByRef lpsi, fRedraw := 1, hwnd := 0){
		; https://msdn.microsoft.com/en-us/library/windows/desktop/bb787595%28v=vs.85%29.aspx
		if (hwnd = 0){
			; Normal use - operate on youurself. Passed hwnd = inspect another window
			hwnd := this._hwnd
		}
		return DllCall("User32.dll\SetScrollInfo", "Ptr", hwnd, "Int", fnBar, "Ptr", lpsi[], "UInt", fRedraw, "UInt")
	}

	;_DLL_GetScrollInfo(fnBar, ByRef lpsi, hwnd := 0){
	; returns a SCROLLINFO structure
	_DLL_GetScrollInfo(fnBar, hwnd := 0){
		; https://msdn.microsoft.com/en-us/library/windows/desktop/bb787583%28v=vs.85%29.aspx
		static SIF_ALL := 0x17
		if (hwnd = 0){
			; Normal use - operate on youurself. Passed hwnd = inspect another window
			hwnd := this._hwnd
		}
		lpsi := this._BlankScrollInfo()
		lpsi.fMask := SIF_ALL
		r := DllCall("User32.dll\GetScrollInfo", "Ptr", hwnd, "Int", fnBar, "Ptr", lpsi[], "UInt")
		return lpsi
		;Return r
	}

	_DLL_GetParent(hwnd := 0){
		if (hwnd = 0){
			hwnd := this._hwnd
		}
		return DllCall("GetParent", "Uint", hwnd, "Uint")
	}

	; ========================================== MESSAGES =========================================
	
	; All messages route through here. Only one message of each kind will be registered, to avoid noise and make debugging easier.
	_MessageHandler(wParam, lParam, msg, hwnd){
		; Call the callback associated with this Message and HWND
		(_CGui._MessageArray[msg][hwnd]).(wParam, lParam, msg, hwnd)
	}
	
	; Register a message with the Message handler.
	_RegisterMessage(msg, callback){
		newmessage := 0
		if (!ObjHasKey(_CGui, "_MessageArray")){
			_Cgui._MessageArray := {}
		}
		if (!ObjHasKey(_CGui._MessageArray, msg)){
			_CGui._MessageArray[msg] := {}
			newmessage := 1
		}
		
		; Add the callback to _MessageArray, so that _MessageHandler can look it up and route to it.
		; Store Array on _CGui, so any class can call it's own .RegisterMessage property.
		fn := callback.Bind(this)
		_CGui._MessageArray[msg][this._hwnd] := fn
		
		; Only subscribe to message if this message has not already been subscribed to.
		if (newmessage){
			fn := this._MessageHandler.Bind(this)
			OnMessage(msg, fn)
		}
	}

	; A scrollbar was dragged
	_OnScroll(wParam, lParam, msg, hwnd){
		;SoundBeep
		; Handles:
		; WM_VSCROLL https://msdn.microsoft.com/en-gb/library/windows/desktop/bb787577(v=vs.85).aspx
		; WM_HSCROLL https://msdn.microsoft.com/en-gb/library/windows/desktop/bb787575(v=vs.85).aspx
		Critical
		static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
		Static SB_HORZ := 0, SB_VERT := 1
		static SB_LINEUP := 0x0, SB_LINEDOWN := 0x1, SB_PAGEUP := 0x2, SB_PAGEDOWN := 0x3, SB_THUMBPOSITION := 0x4, SB_THUMBTRACK := 0x5, SB_TOP := 0x6, SB_BOTTOM := 0x7, SB_ENDSCROLL := 0x8 
		
		if (msg = WM_HSCROLL || msg = WM_VSCROLL){
			bar := msg - 0x114
		} else {
			SoundBeep
			return
		}
		ScrollInfo := this._DLL_GetScrollInfo(bar)
		;OutputDebug, % "SI: " ScrollInfo.nTrackPos ", Bar: " bar

		if (wParam = SB_LINEUP || wParam = SB_LINEDOWN || wParam = SB_PAGEUP || wParam = SB_PAGEDOWN){
			; Line scrolling (Arrows at end of scrollbar clicked) or Page scrolling (Area between handle and arrows clicked)
			; Is an unimplemented flag
			; wParam is direction
			; msg is horiz / vert
			if (wParam = SB_PAGEUP || wParam = SB_PAGEDOWN){
				wParam -= 2
				line := ScrollInfo.nPage
			} else {
				line := 20
			}
			amt := 0
			max := ScrollInfo.nMax - ScrollInfo.nPage
			if (wParam){
				; down
				amt := ScrollInfo.nPos + line
				if (amt > max){
					amt := max
				}
			} else {
				; up
				amt := ScrollInfo.nPos - line
				if (amt < ScrollInfo.nMin){
					amt := ScrollInfo.nMin
				}
			}
			newpos := amt
			amt := ScrollInfo.nPos - amt
			if (amt){
				; IMPORTANT! Update scrollbar pos BEFORE scrolling window.
				; Scrolling window trips _OnMove for children, and scrollbar pos is used by them to determine coordinates.
				this._GuiSetScrollbarPos(newpos, bar)
				this._DLL_ScrollWindow(bar, amt)
			}
		/*
		} else if (wParam = SB_THUMBTRACK){
			; "The user is dragging the scroll box. This message is sent repeatedly until the user releases the mouse button"
			; This is bundled in with the drags, as same code seems good.
		} else if (wParam = SB_THUMBPOSITION || wParam = SB_ENDSCROLL){
			; This is bundled in with the drags, as same code seems good.
			this._GuiSetScrollbarPos(ScrollInfo.nTrackPos, bar)
		} else if (wParam = SB_TOP || wParam = SB_BOTTOM) {
			; "Scrolls to the upper left" / "Scrolls to the lower right"
			; Not entirely sure what these are for, disable for now
			SoundBeep, 100, 100
		*/
		} else if (wParam = SB_ENDSCROLL){
			; Seem to not need to implement this.
			; Routing it through to the main drag block breaks page scrolling (arrow buttons or wheel)
		} else {
			; Drag of scrollbar
			; Handles SB_THUMBTRACK, SB_THUMBPOSITION, SB_ENDSCROLL Flags (Indicated by wParam has set LOWORD, Highest value is 0x8 which is SB_ENDSCROLL) ...
			; These Flags generally only get set once each per drag.
			; ... Also handles drag of scrollbar (wParam has set HIWORD = "current position of the scroll box"), so wParam will be very big.
			; This HIWORD "Flag" gets set lots of times per drag.
			
			; Set the scrollbar pos BEFORE scrolling the window.
			; Scrolling the window will cause WM_MOVE to trigger for children...
			; ... And the position of the window needs to match the postion of the scrollbars at that point in time.
			pos := (ScrollInfo.nTrackPos - this._ScrollInfos[bar].nPos) * -1
			this._GuiSetScrollbarPos(ScrollInfo.nTrackPos, bar)
			
			if (bar){
				; Vertical Bar
				h := 0
				;v := (ScrollInfo.nTrackPos - this._ScrollInfos[bar].nPos) * -1
				v := pos
			} else {
				; Horiz Bar
				;h := (ScrollInfo.nTrackPos - this._ScrollInfos[bar].nPos) * -1
				h := pos
				v := 0
			}
			;OutputDebug, % "[ " this._FormatHwnd() " ] " this._SetStrLen(A_ThisFunc) "   Scrolling window by (x,y) " h ", " v " - new Pos: " this._ScrollInfos[bar].nPos
			;ToolTip % ScrollInfo.nPos "," ScrollInfo.nPage "," ScrollInfo.nMax
			this._DLL_ScrollWindows(h, v)
		}
	}

	; Adjust this._PageRECT when Gui Size Changes (ie it was Resized)
	; Handles WM_SIZE message
	; https://msdn.microsoft.com/en-us/library/windows/desktop/ms632646%28v=vs.85%29.aspx
	_OnSize(wParam, lParam, msg, hwnd){
		; ToDo: Need to check if hwnd matches this._hwnd ?
		static SIZE_RESTORED := 0, SIZE_MINIMIZED := 1, SIZE_MAXIMIZED := 2, SIZE_MAXSHOW := 3, SIZE_MAXHIDE := 4
		
		if (wParam = SIZE_RESTORED || wParam = SIZE_MAXIMIZED){
			old := this._WindowRECT.clone()
			w := lParam & 0xffff
			h := lParam >> 16
			if (w != this._PageRECT.Right || h != this._PageRECT.Bottom){
				; Gui Size Changed - update PAGERECT
				this._PageRECT.Right := w
				this._PageRECT.Bottom := h
			}
			this._GuiSetWindowRECT()
			; Adjust Scrollbars if required
			this._GuiSetScrollbarSize()
			;this._parent._GuiSetScrollbarSize()
			this._parent._GuiChildChangedRange(this, old)
		}
	}
	
	; Called when a GUI Moves.
	; If the GUI moves outside it's parent's RECT, enlarge the parent's RANGE
	; ToDo: Needs work? buggy?
	; OnMove seems to be called for a window when you scroll a window containing it.
	_OnMove(wParam := 0, lParam := 0, msg := 0, hwnd := 0){
		Critical
		old := this._WindowRECT.clone()
		this._GuiSetWindowRECT(wParam, lParam, msg, hwnd)
		;ToolTip % A_ThisFunc "`nOld: " this._SerializeRECT(old) "`nNew: " this._SerializeRECT(this._WindowRECT)
		;if (!this._WindowRECT.Equals(old)){
		;if (!this._parent._RangeRECT.contains(this._WindowRECT)){
			this._parent._GuiChildChangedRange(this, old)
		;}
		return
	}

	; Handles mouse wheel messages
	_OnWheel(wParam, lParam, msg, hwnd){
		Static MK_SHIFT := 0x0004
		Static SB_LINEMINUS := 0, SB_LINEPLUS := 1
		Static WM_MOUSEWHEEL := 0x020A, WM_MOUSEHWHEEL := 0x020E
		Static WM_HSCROLL := 0x0114, WM_VSCROLL := 0x0115
		Static SB_HORZ := 0, SB_VERT := 1
		Critical

		MSG := (Msg = WM_MOUSEWHEEL ? WM_VSCROLL : WM_HSCROLL)
		bar := msg - 0x114
		has_scrollbars := 0
		MouseGetPos,,,,hcurrent,2
		if (hcurrent != ""){
			has_scrollbars :=  this._HasScrollbar(bar, hcurrent)
		}
		if (has_scrollbars = 0){
			; No Sub-item found under cursor, get which main parent gui is under the cursor.
			MouseGetPos,,,hcurrent
			has_scrollbars :=  this._HasScrollbar(bar, hcurrent)
		}
		; Drill down through Hwnds until one is found with scrollbars showing.
		while (!has_scrollbars){
			hcurrent := this._DLL_GetParent(hcurrent)
			has_scrollbars := this._HasScrollbar(bar, hcurrent)
			if (hcurrent = 0){
				; No parent found - end
				break
			}
		}
		; No candidates found - route scroll to main window
		if (!has_scrollbars){
			;MsgBox % this.FormatHex(hwnd)
			hcurrent := hwnd
			return
		}
		
		if (!ObjHasKey(_CGui._MessageArray[msg], hcurrent)){
			return
		}

		SB := ((wParam >> 16) > 0x7FFF) || (wParam < 0) ? SB_LINEPLUS : SB_LINEMINUS
		
		(_CGui._MessageArray[msg][hcurrent]).(sb, 0, msg, hcurrent)
		;return 0
	}
	
	_OnExit(wParam, lParam, msg, hwnd){
		; Need to find close message
		MsgBox EXIT
	}


	; ========================================== MISC =============================================
	
	; Converts a rect to a debugging string
	_SerializeRECT(RECT) {
		return "T: " RECT.Top "`tL: " RECT.Left "`tB: " RECT.Bottom "`tR: " RECT.Right
	}
	
	_HasScrollbar(bar, hwnd){
		sb := this._DLL_GetScrollInfo(bar, hwnd)
		if (sb.nPage && (sb.nPage <= sb.nMax)){
			return 1
		} else {
			return 0
		}
	}
	
	BoolToSgn(bool){
		if (bool){
			return "+"
		} else {
			return "-"
		}
	}

	
	ToolTip(Text, duration := 500){
		fn := this.ToolTipTimer.bind(this)
		this._TooltipActive := fn
		SetTimer, % fn, % "-" duration
		ToolTip % Text
	}
	
	ToolTipTimer(){
		ToolTip
	}

	; ========================================== CLASSES ==========================================
	
	; Wraps GuiControls into an Object
	class _CGuiControl extends _CGuiBase {
		_type := "c"	; Control Type
		_glabel := 0
		; Equivalent to Gui, Add
		__New(parent, ctrltype, options := "", text := ""){
			this._parent := parent
			this._ctrltype := ctrltype
			Gui, % this._parent.PrefixHwnd("Add"), % ctrltype, % "hwndhwnd " options, % text
			;this._parent.Gui("add", ctrltype, "hwndhwnd " options
			this._hwnd := hwnd

			; Hook into OnChange event
			fn := this._OnChange.bind(this)
			GuiControl % "+g", % this._hwnd, % fn

			; Add self to parent's list of GuiControls
			this._parent._ChildControls[this._hwnd] := this

			; Set up RECTs for scrollbars
			this._WindowRECT := new this.RECT()
			this._GuiSetWindowRECT()
			
			; Tell parent to adjust scrollbars
			this._parent._GuiChildChangedRange(this, this._WindowRECT)

		}
		
		__Delete(){
			;MsgBox % "CONTROL DELETE - " this._hwnd
			;Gui, % this._parent.PrefixHwnd("Add"), % ctrltype, % "hwndhwnd " options, % text
			DllCall("DestroyWindow", "UInt", this._hwnd)
			
			; If top touches range top, left touches page left, right touches page right, or bottom touches page bottom...
			; Removing this GuiControl should trigger a RANGE CHANGE.
			; Same for Hiding a GuiControl?
		}
		
		__Get(aParam){
			if (aParam = "value"){
				return this._parent.GuiControlGet(,this)
			}
		}
		
		__Set(aParam, aValue){
			if (aParam = "value"){
				return this._parent.GuiControl(,this, aValue)
			}
		}
		
		; Removes a GUIControl.
		; Does NOT remove the last reference to the Control on the parent, call Destroy, then unset manually to fire __Delete()
		; eg this.childcontrol.Destroy()
		; this.childcontrol := ""
		Destroy(){
			this._parent._ChildControls.Remove(this._hwnd, "")
			this._parent._GuiChildChangedRange()
		}
		
		_OnChange(){
			; Provide hook into change event
			this.OnChange()
			
			; Call bound function if present
			if (ObjHasKey(this,"_glabel") && this._glabel != 0){
				(this._glabel).()
			}
		}
		
		; Override to hook into change event independently of g-labels
		OnChange(){
			
		}
	}

}

; =================================================================================================
; =================================================================================================

; A base class, purely for inheriting.
class _CGuiBase {
	; ========================================== CLASSES ==========================================
	
	; RECT class. Wraps _Struct to provide functionality similar to C
	; https://msdn.microsoft.com/en-us/library/system.windows.rect(v=vs.110).aspx
	class RECT {
		__New(RECT := 0){
			; Initialize RECT
			if (RECT = 0){
				RECT := {Top: 0, Bottom: 0, Left: 0, Right: 0}
			}
			; Create Structure
			this.RECT := new _Struct(WinStructs.RECT, RECT)
		}
		
		__Get(aParam := ""){
			static keys := {Top: 1, Left: 1, Bottom: 1, Right: 1}
			if (aParam = ""){
				; Blank param passed via [] or [""] - pass back RECT Structure
				return this.RECT[""]
			}
			if (ObjHasKey(keys, aParam)){
				; Top / Left / Bottom / Right property requested - return property from Structure
				return this.RECT[aParam]
			}
		}
		
		__Set(aParam := "", aValue := ""){
			static keys := {Top: 1, Left: 1, Bottom: 1, Right: 1}
			
			if (aParam = ""){
				; Blank param passed via [""] - pass back RECT Structure
				return this.RECT[] := aValue
			}
			
			if (ObjHasKey(keys, aParam)){
				; Top / Left / Bottom / Right property specified - Set property of Structure
				this.RECT[aParam] := aValue
			}
		}
		; Syntax Sugar
		
		; Does this RECT contain the passed rect ?
		Contains(RECT){
			;tooltip % A_ThisFunc "`n" this.RECT.Bottom ">=" RECT.Bottom " ?"
			return (this.RECT.Top <= RECT.Top && this.RECT.Left <= RECT.Left && this.RECT.Bottom >= RECT.Bottom && this.RECT.Right >= RECT.Right)
		}
		
		; Is this RECT equal to the passed RECT?
		Equals(RECT){
			return (this.RECT.Top = RECT.Top && this.RECT.Left = RECT.Left && this.RECT.Bottom = RECT.Bottom && this.RECT.Right = RECT.Right)
		}
		
		; Expands the current RECT to include the new RECT
		; Returns TRUE if it the RECT grew.
		Union(RECT){
			Expanded := 0
			if (RECT.Top < this.RECT.Top){
				this.RECT.Top := RECT.Top
				Expanded := 1
			}
			if (RECT.Left < this.RECT.Left){
				this.RECT.Left := RECT.Left
				Expanded := 1
			}
			if (RECT.Right > this.RECT.Right){
				this.RECT.Right := RECT.Right
				Expanded := 1
			}
			if (RECT.Bottom > this.RECT.Bottom){
				this.RECT.Bottom := RECT.Bottom
				Expanded := 1
			}
			return Expanded
		}
	}

	; ========================================== POSITION =========================================
	
	; Sets the Window RECT.
	_GuiSetWindowRECT(wParam := 0, lParam := 0, msg := 0, hwnd := 0){
		Static SB_HORZ := 0, SB_VERT := 1
		if (this._type = "w"){
			; WinGetPos is relative to the SCREEN
			frame := DllCall("GetParent", "Uint", this._hwnd)
			;MsgBox % "frame - " this.FormatHex(frame) ", parent - " this._parent._hwnd
			WinGetPos, PosX, PosY, Width, Height, % "ahk_id " this._hwnd
			;WinGetPos, PosX, PosY, Width, Height, % "ahk_id " frame
			if (this._parent = 0){
				Bottom := PosY + height
				Right := PosX + Width
			} else {
				; The x and y coords do not change when the window scrolls?
				; Base code off these instead?
				; x/y is coord of child RANGE relative to window RANGE.
				;x := lParam & 0xffff
				;y := lParam >> 16
				/*
				; Method flawed - wraps round to 65535 when you move off the top/left edge.
				; Adjust to compensate for child border size
				if (lParam = 0){
					; called without params (ie not from a message) - work out x and y coord
					POINT := new _Struct(WinStructs.POINT)
					POINT.x := 0
					POINT.y := 0
					; Find 0,0 of Child Page relative to Parent's Range
					this._DLL_MapWindowPoints(this._hwnd, this._parent._hwnd, POINT, 1)
				} else {
					POINT := {x: lParam & 0xffff, y: lParam >> 16}
				}
				;POINT := this.ConvertCoords(POINT, this._hwnd)
				*/

				RECT := new _Struct(WinStructs.RECT)
				DllCall("GetWindowRect", "uint", this._hwnd, "Ptr", RECT[])
				POINT := this._DLL_ScreenToClient(this._parent._hwnd, RECT.Left, RECT.Top)
				ScrollInfo := this._parent._DLL_GetScrollInfo(SB_VERT)
				x_offset := this._parent._ScrollInfos[SB_HORZ].nPos
				y_offset := this._parent._ScrollInfos[SB_VERT].nPos
				PosX := POINT.x  + x_offset
				PosY := POINT.y + y_offset
				
				; Offset for scrollbar position
				x_offset := this._parent._ScrollInfos[SB_HORZ].nPos
				y_offset := this._parent._ScrollInfos[SB_VERT].nPos
				
				PosX := POINT.x + x_offset
				PosY := POINT.y + y_offset
				Right := (PosX + Width)
				Bottom := (PosY + height)
				;ToolTip % "Pos: " PosX "," PosY
				;ToolTip % this.name	"`n" this._SerializeRECT(this._WindowRECT) " - " y_offset
			}
		} else {
			GuiControlGet, Pos, % this._parent._hwnd ":Pos", % this._hwnd
			Right := PosX + PosW
			Bottom := PosY + PosH
		}
		
		this._WindowRECT.Left := PosX
		this._WindowRECT.Top := PosY
		this._WindowRECT.Right := Right
		this._WindowRECT.Bottom := Bottom
		;ToolTip % this.name	"`n" this._SerializeRECT(this._WindowRECT) " - " y_offset
		;this._TestRECT.Left := PosX
		;this._TestRECT.Top := PosY
		;this._TestRECT.Right := Right
		;this._TestRECT.Bottom := Bottom
		;ToolTip % A_ThisFunc "`n" this._SerializeRECT(this._TestRECT) " - " y_offset

	}
	
	; Returns a RECT indicating the amount the window moved
	_GuiGetMoveAmount(old, new){
		;ToolTip % "O: " this._SerializeRECT(old) "`nN: " this._SerializeRECT(new)
		moved := new this.RECT()
		if ( (new.Right - new.Left) = (old.Right - old.Left) && (new.Bottom - new.Top) = (old.Bottom - old.Top) ){
			; Moved
			moved.Left := (new.Left - old.Left) * -1	; invert so positive means "we moved left"
			moved.Top := (new.Top - old.Top) * -1
			moved.Right := new.Right - old.Right
			moved.Bottom := new.Bottom - old.Bottom
		} else {
			; resized
			/*
			moved.Left := (new.Left - old.Left)
			moved.Top := (new.Top - old.Top)
			moved.Right := (new.Right - old.Right) * -1
			moved.Bottom := (new.Bottom - old.Bottom) * -1
			*/
			; Swap values, as code calling this is based around Move rather than size, and checks opposite edges.
			moved.Right := (new.Left - old.Left)
			moved.Bottom := (new.Top - old.Top)
			moved.Left := (new.Right - old.Right) * -1
			moved.Top := (new.Bottom - old.Bottom) * -1
		}
		return moved
	}
	
	; ========================================== HELPER ===========================================
	
	; Shorthand way of formatting something as 0x0 format Hex
	FormatHex(val){
		return Format("{:#x}", val+0)
	}
	
	; Human readable hwnd, or padded number if not set
	_FormatHwnd(hwnd := -1){
		if (hwnd = -1){
			hwnd := this._hwnd
		}
		if (!hwnd){
			return 0x000000
		} else {
			return hwnd
		}
	}
	
	; Formats a String to a given length.
	_SetStrLen(func, max := 25){
		if (StrLen(func) > max){
			func := Substr(func, 1, max)
		}
		return Format("{:-" max "s}",func)
	}

}