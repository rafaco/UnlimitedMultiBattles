class graphicsearch {

	static noMatchVal := false ;the value to return when no matches were found
	static defaultOptionsObj := { "x1": 0
								, "y1": 0
								, "x2": A_ScreenWidth
								, "y2": A_ScreenHeight
								, "err1": 0 ;foreground
								, "err0": 0 ;background
								, "screenshot": 1
								, "findall": 1
								, "joinqueries": 0
								, "offsetx": 0
								, "offsety": 0 }
	static savedScreenshot := []

	; .search
	static lastSearchQuery      := ""
	static lastSearchOptions    := {}
	; .scan
	static lastScanQuery      := ""
	static lastScanOptions    := {}
	

	find(x1, y1, x2, y2, err1, err0, query, screenShot:=1, findall:=1, joinqueries:=0, offsetx:=20, offsety:=10)
	{
		savedBatchLines := A_BatchLines
		SetBatchLines, -1

		x := (x1 < x2 ? x1:x2), y := (y1 < y2 ? y1:y2)
		, w := Abs(x2 - x1)+1, h := Abs(y2 - y1)+1
		, this.xywh2xywh(x, y, w, h, x, y, w, h, zx, zy, zw, zh)
		if (w < 1 || h < 1) {
			SetBatchLines, %savedBatchLines%
			return this.noMatchVal
		}
		bits := this.getBitsFromScreen(x, y, w, h, screenShot, zx, zy, zw, zh)
		sx := x - zx, sy := y-zy, sw := w, sh := h, arr := [], info := []
		loop, Parse, query, |
		if IsObject(j := this.picInfo(A_LoopField))
			info.Push(j)
		if (!(num := info.MaxIndex()) || !bits.1) {
			SetBatchLines, %savedBatchLines%
			return this.noMatchVal
		}
		VarSetCapacity(input, num*7*4), k := 0
		loop, % num
			k += Round(info[A_Index].2 * info[A_Index].3)
			VarSetCapacity(s1, k * 4), VarSetCapacity(s0, k * 4)
			, VarSetCapacity(gs, sw * sh), VarSetCapacity(ss, sw * sh)
			, allpos_max := (findall ? 1024 : 1)
			, VarSetCapacity(allpos, allpos_max*4)
		loop, 2
		{
			if (err1 = 0 && err0 = 0) && (num > 1 || A_Index>1) {
				err1 := 0.1, err0 := 0.05
			}
			if (joinqueries == 1) {
				j := info[1], mode := j.8, color := j.9, n := j.10
				, w1 := -1, h1 := j.3, comment := "", v := "", i := 0
				loop, % num
				{
					j := info[A_Index], w1+=j.2+1, comment.=j.11
					loop, 7
					{
						NumPut((A_Index=1 ? StrLen(v)
						: A_Index=6 && err1 && !j.12 ? Round(j.4 * err1)
						: A_Index=7 && err0 && !j.12 ? Round(j.5 * err0)
						: j[A_Index]), input, 4*(i++), "int")
					}
					v .= j.1
				}
				ResultObj := this.picFind( mode, color, n, offsetx, offsety
				, bits, sx, sy, sw, sh, gs, ss, v, s1, s0
				, input,num*7, allpos, allpos_max )
				loop, % ResultObj
				{
					pos := NumGet(allpos, 4*(A_Index-1), "uint")
					, rx := (pos&0xFFFF)+zx, ry := (pos>>16)+zy
					, arr.Push( {1:rx, 2:ry, 3:w1, 4:h1
					, x:rx+w1//2, y:ry+h1//2, id:comment} )
				}
			} else {
				for i, j in info {
					mode := j.8, color := j.9, n := j.10, comment := j.11
					, w1 := j.2, h1 := j.3, v := j.1
					loop, 7
						NumPut((A_Index=1 ? 0
						: A_Index=6 && err1 && !j.12 ? Round(j.4*err1)
						: A_Index=7 && err0 && !j.12 ? Round(j.5*err0)
						: j[A_Index]), input, 4*(A_Index-1), "int")
					ResultObj := this.picFind( mode,color,n,offsetx,offsety
					, bits,sx,sy,sw,sh,gs,ss,v,s1,s0
					, input,7,allpos,allpos_max )
					loop, % ResultObj
						pos := NumGet(allpos, 4*(A_Index-1), "uint")
						, rx := (pos&0xFFFF)+zx, ry := (pos>>16)+zy
						, arr.Push( {1:rx, 2:ry, 3:w1, 4:h1
						, x:rx+w1//2, y:ry+h1//2, id:comment} )
					if (ResultObj && !findall) {
						break
					}
				}
			}
			if (err1=0 && err0=0 && num=1 && !arr.MaxIndex())
			{
				k := 0
				for i,j in info {
					k += (!j.12)
				}
				if (k = 0) {
					break
				}
			} else {
				break
			}
		}
		; return this.noMatchVal if no results found
		if (arr.Count() = 0) {
			SetBatchLines, %savedBatchLines%
			return this.noMatchVal
		}
		; return array of found elements if more than 0 found
		SetBatchLines, %savedBatchLines%
		return arr
	}


	main_search(param_query, param_options:="")
	{
		; create default if needed
		if (!IsObject(param_options)) {
			param_options := this.defaultOptionsObj.Clone()
		}
		; merge with default for any blank parameters
		for Key, Value in this.defaultOptionsObj {
			if (param_options.HasKey(Key) == false) { ; if the key is existing in param_options
				param_options[Key] := Value
			}
		}

		; pass the parameters to .find and return
		return this.find(param_options.x1, param_options.y1, param_options.x2, param_options.y2, param_options.err1, param_options.err0, param_query
			, param_options.screenshot, param_options.findall, param_options.joinqueries, param_options.offsetx, param_options.offsety)
	}


	search(param_query, param_options:="")
	{
		; create default if needed
		if (!IsObject(param_options)) {
			param_options := this.defaultOptionsObj.Clone()
		}
		; save parameters for use in future
		this.lastSearchQuery := param_query
		this.lastSearchOptions := param_options

		; pass the parameters to .find and return
		return this.main_search(param_query, param_options)
	}


	searchAgain(param_query:="", param_options:="") 
	{
		; save new query if entered
		if (param_query != "") {
			this.lastSearchQuery := param_query
		}
		if (param_options != "") {
			this.lastSearchOptions := param_options
		}
		; pass saved arguments to .search and return
		return this.main_search(this.lastSearchQuery, this.lastSearchOptions)
	}


	scan(param_query, x1:=0, y1:=0, x2:="", y2:="", err1:=0, err0:=0, screenshot:=1
		, findall:=1, joinqueries:=1, offsetx:=20, offsety:=10)
	{
		if (x2 == "") {
			x2 := A_ScreenWidth
		}
		if (y2 == "") {
			y2 := A_ScreenHeight
		}

		; save parameters for use in future and build search object
		this.lastScanQuery := param_query
		this.lastScanOptions := { "x1": x1
								, "y1": y1
								, "x2": x2
								, "y2": y2
								, "err1": err1
								, "err0": err0
								, "screenshot": screenshot
								, "findall": findall
								, "joinqueries": joinqueries
								, "offsetx": offsetx
								, "offsety": offsety }
		; pass the parameters to .find and return
		return this.main_search(param_query, this.lastScanOptions)
	}


	scanAgain(param_query:="", x1:="", y1:="", x2:="", y2:="", err1:="", err0:="", screenshot:=""
		, findall:="", joinqueries:="", offsetx:="", offsety:="")
	{
		; save new query if entered
		if (param_query != "") {
			this.lastScanQuery := param_query
		}
		if (x1 != "") {
			this.lastScanOptions.x1 := x1
		}
		if (y1 != "") {
			this.lastScanOptions.y1 := y1
		}
		if (x2 != "") {
			this.lastScanOptions.x2 := x2
		}
		if (err1 != "") {
			this.lastScanOptions.err1 := err1
		}
		if (err0 != "") {
			this.lastScanOptions.err0 := err0
		}
		if (screenshot != "") {
			this.lastScanOptions.screenshot := screenshot
		}
		if (findall != "") {
			this.lastScanOptions.findall := findall
		}
		if (joinqueries != "") {
			this.lastScanOptions.joinqueries := joinqueries
		}
		if (offsetx != "") {
			this.lastScanOptions.offsetx := offsetx
		}
		if (offsety != "") {
			this.lastScanOptions.offsety := offsety
		}
		; pass saved arguments to .search and return
		return this.main_search(this.lastScanQuery, this.lastScanOptions)
	}


	; Bind the window so that it can find images when obscured
	; by other windows, it's equivalent to always being
	; at the front desk. Unbind Window using bindWindow(0)
	bindWindow(window_id := 0, set_exstyle := 0, get := 0)
	{
		local
		static id := 0, old := 0
		if (get)
		return id
		if (window_id)
		{
		id := window_id, old := 0
		if (set_exstyle)
		{
			WinGet, old, ExStyle, ahk_id %id%
			WinSet, Transparent, 255, ahk_id %id%
			loop, 30
			{
			Sleep, 100
			WinGet, i, Transparent, ahk_id %id%
			}
			until (i=255)
		}
		}
		else
		{
		if (old)
			WinSet, ExStyle, %old%, ahk_id %id%
		id := old := 0
		}
	}


	xywh2xywh(x1,y1,w1,h1, ByRef x,ByRef y,ByRef w,ByRef h, ByRef zx:="", ByRef zy:="", ByRef zw:="", ByRef zh:="")
	{
		local
		SysGet, zx, 76
		SysGet, zy, 77
		SysGet, zw, 78
		SysGet, zh, 79
		left := x1, right := x1+w1-1, up := y1, down := y1+h1-1
		left := left<zx ? zx:left, right := right>zx+zw-1 ? zx+zw-1:right
		up := up<zy ? zy:up, down := down>zy+zh-1 ? zy+zh-1:down
		x := left, y := up, w := right-left+1, h := down-up+1
	}


	getBitsFromScreen(x, y, w, h, screenShot:=1, zx:="", zy:="", zw:="", zh:="")
	{
		local
		static hBM := "", bits := [], Ptr := A_PtrSize ? "UPtr" : "UInt"
		static init := !this.getBitsFromScreen(0,0,0,0,1)
		if (!screenShot) {
			zx := bits.3, zy := bits.4, zw := bits.5, zh := bits.6
			return bits
		}
		savedBatchLines := A_BatchLines, savedIsCritical := A_IsCritical
		Critical
		if (zw<1 or zh<1) {
			SysGet, zx, 76
			SysGet, zy, 77
			SysGet, zw, 78
			SysGet, zh, 79
		}
		if (zw>bits.5 or zh>bits.6 or !hBM) {
			DllCall("DeleteObject", Ptr,hBM), hBM := "", bpp := 32
			VarSetCapacity(bi, 40, 0), NumPut(40, bi, 0, "int")
			NumPut(zw, bi, 4, "int"), NumPut(-zh, bi, 8, "int")
			NumPut(1, bi, 12, "short"), NumPut(bpp, bi, 14, "short")
			hBM := DllCall("CreateDIBSection", Ptr,0, Ptr,&bi
				, "int",0, Ptr "*",ppvBits := 0, Ptr,0, "int",0, Ptr)
			Scan0 := (!hBM ? 0:ppvBits), Stride := ((zw*bpp+31)//32)*4
			bits.1 := Scan0, bits.2 := Stride
			bits.3 := zx, bits.4 := zy, bits.5 := zw, bits.6 := zh
			x := zx, y := zy, w := zw, h := zh
		}
		if (hBM) and !(w<1 or h<1) {
			win := DllCall("GetDesktopWindow", Ptr)
			hDC := DllCall("GetWindowDC", Ptr,win, Ptr)
			mDC := DllCall("CreateCompatibleDC", Ptr,hDC, Ptr)
			oBM := DllCall("SelectObject", Ptr,mDC, Ptr,hBM, Ptr)
			DllCall("BitBlt",Ptr,mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
				, Ptr,hDC, "int",x-zx, "int",y-zy, "uint",0x00CC0020|0x40000000)
			DllCall("ReleaseDC", Ptr,win, Ptr,hDC)
			if (id := this.bindWindow(0,0,1)) {
				WinGet, id, ID, ahk_id %id%
			}
			if (id) {
				WinGetPos, wx, wy, ww, wh, ahk_id %id%
				left := x, right := x+w-1, up := y, down := y+h-1
				left := left<wx ? wx:left, right := right>wx+ww-1 ? wx+ww-1:right
				up := up<wy ? wy:up, down := down>wy+wh-1 ? wy+wh-1:down
				x := left, y := up, w := right-left+1, h := down-up+1
			}
			if (id) and !(w<1 or h<1) {
				hDC2 := DllCall("GetDCEx", Ptr,id, Ptr,0, "int",3, Ptr)
				DllCall("BitBlt",Ptr,mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
					, Ptr,hDC2, "int",x-wx, "int",y-wy, "uint",0x00CC0020|0x40000000)
				DllCall("ReleaseDC", Ptr,id, Ptr,hDC2)
			}
			DllCall("SelectObject", Ptr,mDC, Ptr,oBM)
			DllCall("DeleteDC", Ptr,mDC)
		}
		Critical, %savedIsCritical%
		SetBatchLines, %savedBatchLines%
		return bits
	}


	picInfo(text)
	{
		local
		static info := []
		if !InStr(text,"$")
		return
		if (info[text])
		return info[text]
		v := text, comment := "", e1 := e0 := 0, set_e1_e0 := 0
		; You Can Add Comment Text within The <>
		if RegExMatch(v,"<([^>]*)>",r)
		v := StrReplace(v,r), comment := Trim(r1)
		; You can Add two fault-tolerant in the [], separated by commas
		if RegExMatch(v,"\[([^\]]*)]",r)
		{
		v := StrReplace(v,r)
		r := StrSplit(r1, ",")
		e1 := r.1, e0 := r.2, set_e1_e0 := 1
		}
		r := StrSplit(v,"$")
		color := r.1, v := r.2
		r := StrSplit(v,".")
		w1 := r.1, v := this.base64tobit(r.2), h1 := StrLen(v)//w1
		if (w1<1 or h1<1 or StrLen(v)!=w1*h1)
		return
		mode := InStr(color,"-") ? 4 : InStr(color,"#") ? 3
		: InStr(color,"**") ? 2 : InStr(color,"*") ? 1 : 0
		if (mode=4)
		{
		color := StrReplace(color,"0x")
		r := StrSplit(color,"-")
		color := "0x" r.1, n := "0x" r.2
		}
		else
		{
		color := RegExReplace(color,"[*#]")
		r := StrSplit(color,"@")
		color := r.1, n := Round(r.2,2)+(!r.2)
		, n := Floor(9*255*255*(1-n)*(1-n))
		}
		StrReplace(v,"1","",len1), len0 := StrLen(v)-len1
		, e1 := Round(len1*e1), e0 := Round(len0*e0)
		return info[text] := [v,w1,h1,len1,len0,e1,e0
		, mode,color,n,comment,set_e1_e0]
	}


	picFind(mode, color, n, offsetX, offsetY, bits, sx, sy, sw, sh
		, ByRef gs, ByRef ss, ByRef text, ByRef s1, ByRef s0
		, ByRef input, num, ByRef allpos, allpos_max)
	{
		local
		static MyFunc := "", Ptr := A_PtrSize ? "UPtr" : "UInt"
		if (!MyFunc)
		{
		x32 := "5557565383EC788B8424CC0000008BBC24CC000000C7442"
		. "424000000008B40048B7F148944243C8B8424CC000000897C2"
		. "42C8BBC24CC0000008B40088B7F18894424388B8424CC00000"
		. "0897C24308B400C89C6894424288B8424CC0000008B401039C"
		. "6894424200F4DC68944241C8B8424D000000085C00F8E15010"
		. "0008BB424CC0000008B44242489F78B0C868B7486048B44870"
		. "88974241085C0894424180F8ED700000089CD894C2414C7442"
		. "40C00000000C744240800000000C744240400000000890C248"
		. "D76008DBC27000000008B5C24108B7424088B4C24148B54240"
		. "C89DF89F029F101F78BB424C000000001CE85DB7E5E8B0C248"
		. "9EB893C2489D7EB198BAC24C800000083C70483C00189548D0"
		. "083C101390424742C83BC248C0000000389FA0F45D0803C063"
		. "175D48BAC24C400000083C70483C00189549D0083C30139042"
		. "475D48B7424100174241489DD890C2483442404018BB424B00"
		. "000008B442404017424088BBC24A4000000017C240C3944241"
		. "80F8554FFFFFF83442424078B442424398424D00000000F8FE"
		. "BFEFFFF83BC248C000000030F84A00600008B8424A40000008"
		. "BB424A80000000FAF8424AC0000008BBC24A40000008D2CB08"
		. "B8424B0000000F7D88D04878BBC248C0000008944241085FF0"
		. "F84F702000083BC248C000000010F847F08000083BC248C000"
		. "000020F84330900008B8424900000008B9C24940000000FB6B"
		. "C24940000000FB6B42490000000C744241800000000C744242"
		. "400000000C1E8100FB6DF0FB6D08B84249000000089D10FB6C"
		. "4894424088B842494000000C1E8100FB6C029C101D08904248"
		. "B442408894C24408B4C240801D829D9894424088D043E894C2"
		. "40489F129F9894424148BBC24B40000008B8424B0000000894"
		. "C240C89E98B6C2440C1E00285FF894424340F8EBA0000008BB"
		. "424B000000085F60F8E910000008B8424A00000008B5424240"
		. "39424BC00000001C8034C243489CF894C244003BC24A000000"
		. "0EB3D8D76008DBC2700000000391C247C3D394C24047F37394"
		. "C24087C3189F30FB6F33974240C0F9EC3397424140F9DC183C"
		. "00483C20121D9884AFF39F8741E0FB658020FB648010FB6303"
		. "9DD7EBE31C983C00483C201884AFF39F875E28BB424B000000"
		. "0017424248B4C24408344241801034C24108B442418398424B"
		. "40000000F8546FFFFFF8B8424B00000002B44243C8944240C8"
		. "B8424B40000002B442438894424600F886D0900008B4424288"
		. "BBC24C40000008B74243CC744241000000000C744243800000"
		. "000C7442434000000008D3C8789C583EE01897C246C8974247"
		. "48B44240C85C00F88E70000008B7C24388B8424AC000000BE0"
		. "0000000C704240000000001F8C1E0108944246889F82B84249"
		. "C0000000F49F08B84249C000000897424640FAFB424B000000"
		. "001F8894424708974245C8DB6000000008B04240344241089C"
		. "1894424088B442430394424200F84AA0100008B5C241C89C60"
		. "38C24BC00000031C08B54242C85DB0F8EC8010000897424048"
		. "B7C2420EB2D39C77E1C8BB424C80000008B1C8601CB803B007"
		. "40B836C240401782B8D74260083C0013944241C0F849101000"
		. "039C57ECF8BB424C40000008B1C8601CB803B0174BE83EA017"
		. "9B9830424018B04243944240C0F8D68FFFFFF83442438018BB"
		. "424B00000008B44243801742410394424600F8DEFFEFFFF8B4"
		. "C243483C47889C85B5E5F5DC250008B8424900000008BB424B"
		. "4000000C744240C00000000C744241400000000C1E8100FB6C"
		. "08904248B8424900000000FB6C4894424040FB684249000000"
		. "0894424088B8424B0000000C1E00285F68944242489E88BAC2"
		. "4940000000F8E24FEFFFF8B9C24B000000085DB7E758B9C24A"
		. "00000008B7424148BBC24A000000003B424BC00000001C3034"
		. "424248944241801C78D76008DBC27000000000FB643020FB64"
		. "B012B04242B4C24040FB6132B5424080FAFC00FAFC98D04400"
		. "FAFD28D04888D045039C50F930683C30483C60139DF75C98BB"
		. "C24B0000000017C24148B4424188344240C01034424108B742"
		. "40C39B424B40000000F8566FFFFFFE985FDFFFF85ED7E358B7"
		. "424088BBC24BC00000031C08B54242C8D1C378BB424C400000"
		. "08B0C8601D9803901740983EA010F8890FEFFFF83C00139C57"
		. "5E683BC24D0000000070F8EAA0100008B442474030424C7442"
		. "44007000000896C2444894424288B8424CC00000083C020894"
		. "4243C8B44243C8B9424B00000008B7C24288B0029C28944245"
		. "08B84249800000001F839C20F4EC289C68944244C39FE0F8C0"
		. "90100008B44243C8B700C8B78108B6808897424148B7014897"
		. "C242489C7897424548BB424B40000002B700489F08B7424703"
		. "9C60F4EC68BB424C4000000894424188B47FC89442404C1E00"
		. "201C6038424C8000000894424588B4424648B7C2428037C245"
		. "C3B442418894424040F8F8700000085ED7E268B8C24BC00000"
		. "08B54242431C08D1C398B0C8601D9803901740583EA01784A8"
		. "3C00139C575EA8B4424148B4C245439C8747E85C07E7A8B9C2"
		. "4BC000000896C244831C08B6C245801FBEB0983C0013944241"
		. "4745C8B54850001DA803A0074EC83E90179E78B6C244890834"
		. "424040103BC24B00000008B442404394424180F8D79FFFFFF8"
		. "3442428018B4424283944244C0F8D4CFFFFFF830424018B6C2"
		. "4448B04243944240C0F8D7EFCFFFFE911FDFFFF8B4424288B7"
		. "C245083442440078344243C1C8D4438FF894424288B4424403"
		. "98424D00000000F8F7FFEFFFF8B6C24448B7C24348B0424038"
		. "424A80000008BB424D40000000B4424688D4F01398C24D8000"
		. "0008904BE0F8ED8FCFFFF85ED7E278B7424088BBC24BC00000"
		. "08B8424C40000008D1C378B74246C8B1083C00401DA39F0C60"
		. "20075F283042401894C24348B04243944240C0F8DDEFBFFFFE"
		. "971FCFFFF89F68DBC27000000008B74243C8B8424900000003"
		. "1D2F7F60FAF8424A40000008D0490894424188B8424B000000"
		. "0038424A800000029F0894424348B8424AC000000038424B40"
		. "000002B442438398424AC0000008944243C0F8F560400008B8"
		. "424A40000008BB424A80000000FAF8424AC000000C74424240"
		. "00000008D04B0034424188BB424A0000000894424388B44243"
		. "4398424A80000000F8F320100008B8424AC000000C1E010894"
		. "424408B442438894424148B8424A8000000894424088B44241"
		. "40FB67C060289C52B6C2418893C240FB67C0601897C24040FB"
		. "63C068B44241C85C00F8E1E0100008B442430894424108B442"
		. "42C8944240C31C0EB678D76008DBC2700000000394424207E4"
		. "A8B9C24C80000008B0C8301E90FB6540E020FB65C0E012B142"
		. "42B5C24040FB60C0E0FAFD20FAFDB29F98D14520FAFC98D149"
		. "A8D144A39942494000000720C836C2410017865908D7426008"
		. "3C0013944241C0F84A3000000394424287E9D8B9C24C400000"
		. "08B0C8301E90FB6540E020FB65C0E012B14242B5C24040FB60"
		. "C0E0FAFD20FAFDB29F98D14520FAFC98D149A8D144A3B94249"
		. "40000000F865BFFFFFF836C240C010F8950FFFFFF834424080"
		. "183442414048B442408394424340F8DEFFEFFFF838424AC000"
		. "000018BBC24A40000008B44243C017C24383B8424AC0000000"
		. "F8D99FEFFFF8B4C242483C4785B5E89C85F5DC250008D74260"
		. "08B7C24248B4424400B4424088B9C24D40000008D4F013B8C2"
		. "4D80000008904BB0F8D64FAFFFF894C2424EB848B842490000"
		. "0008B8C24B4000000C7042400000000C74424040000000083C"
		. "001C1E00789C68B8424B0000000C1E00285C98944240889E88"
		. "9F50F8EAFF8FFFF8B9424B000000085D27E5F8B8C24A000000"
		. "08B5C2404039C24BC00000001C1034424088944240C038424A"
		. "000000089C70FB651020FB641010FB6316BC04B6BD22601C28"
		. "9F0C1E00429F001D039C50F970383C10483C30139F975D58BB"
		. "424B0000000017424048B44240C83042401034424108B34243"
		. "9B424B40000007582E92CF8FFFF8B8424B0000000C70424000"
		. "00000C744240400000000C1E002894424088B8424B40000008"
		. "5C00F8E920000008B8424B000000085C07E6F8B8C24A000000"
		. "08B5C24048BB424B800000001E9036C240801DE039C24BC000"
		. "000896C240C03AC24A00000000FB651020FB6410183C1040FB"
		. "679FC83C60183C3016BC04B6BD22601C289F8C1E00429F801D"
		. "0C1F8078846FFC643FF0039CD75CC8BBC24B0000000017C240"
		. "48B6C240C83042401036C24108B0424398424B40000000F856"
		. "EFFFFFF83BC24B4000000020F8E60F7FFFF8B8424BC0000000"
		. "38424B00000008BAC24B800000003AC24B0000000C74424040"
		. "1000000894424088B8424B400000083E8018944240C8B8424B"
		. "000000083C0018944241083BC24B0000000027E798B4424108"
		. "9E92B8C24B00000008B5C240889EA8D34288D45FE8904240FB"
		. "642010FB63A0384249000000039F87C360FB67A0239F87C2E0"
		. "FB6790139F87C260FB63E39F87C1F0FB63939F87C180FB6790"
		. "239F87C100FB67EFF39F87C080FB67E0139F87D04C64301018"
		. "3C20183C30183C10183C6013B0C2475A3834424040103AC24B"
		. "00000008B4424048BBC24B0000000017C24083944240C0F855"
		. "8FFFFFFE96FF6FFFF83C47831C95B89C85E5F5DC2500090909"
		. "090909090"
		x64 := "4157415641554154555756534881EC88000000488B84245"
		. "0010000488BB42450010000448B94245801000089542428448"
		. "944240844898C24E80000008B40048B76144C8BBC244001000"
		. "04C8BB42448010000C74424180000000089442430488B84245"
		. "00100008974241C488BB424500100008B40088B76188944243"
		. "C488B842450010000897424388B400C89C789442440488B842"
		. "4500100008B401039C7894424100F4DC74585D289442454488"
		. "B84245001000048894424200F8ECB000000488B442420448B0"
		. "8448B68048B400885C0894424040F8E940000004489CE44890"
		. "C244531E431FF31ED0F1F8400000000004585ED7E614863142"
		. "4418D5C3D0089F848039424380100004589E0EB1D0F1F0083C"
		. "0014D63D94183C0044183C1014883C20139C34789149E74288"
		. "3F9034589C2440F45D0803A3175D783C0014C63DE4183C0048"
		. "3C6014883C20139C34789149F75D844012C2483C50103BC241"
		. "80100004403A42400010000396C24047582834424180748834"
		. "424201C8B442418398424580100000F8F35FFFFFF83F9030F8"
		. "43D0600008B8424000100008BBC24080100000FAF842410010"
		. "0008BB424000100008D3CB88B842418010000F7D885C9448D2"
		. "C860F841101000083F9010F844108000083F9020F84E008000"
		. "08B742428C744240400000000C74424180000000089F0440FB"
		. "6CEC1E8104589CC0FB6D84889F08B7424080FB6D44189DB89F"
		. "0440FB6C64889F1C1E8100FB6CD89D60FB6C08D2C0A8B94242"
		. "00100004129C301C3438D040129CE4529C48904248B8424180"
		. "10000C1E00285D2894424080F8E660100004C89BC244001000"
		. "0448BBC24180100004585FF0F8E91040000488B8C24F800000"
		. "04863C74C6354241831D24C03942430010000488D440102EB3"
		. "A0F1F80000000004439C37C4039CE7F3C39CD7C384539CC410"
		. "F9EC044390C240F9DC14421C141880C124883C2014883C0044"
		. "139D70F8E2D040000440FB6000FB648FF440FB648FE4539C37"
		. "EBB31C9EBD58B5C2428448B8C242001000031ED4531E44889D"
		. "84189DB0FB6DB0FB6F48B84241801000041C1EB10450FB6DBC"
		. "1E0024585C98904240F8EA10000004C89BC24400100004C89B"
		. "42448010000448B7C2408448BB424180100004585F67E60488"
		. "B8C24F80000004D63D44C039424300100004863C74531C94C8"
		. "D440102410FB600410FB648FF410FB650FE4429D829F10FAFC"
		. "029DA0FAFC98D04400FAFD28D04888D04504139C7430F93040"
		. "A4983C1014983C0044539CE7FC4033C244501F483C5014401E"
		. "F39AC2420010000758C4C8BBC24400100004C8BB4244801000"
		. "08B8424180100002B4424308904248B8424200100002B44243"
		. "C894424680F88750800008B7C24404D89F5488BAC243001000"
		. "0448B7424104C89FEC74424040000000048C74424280000000"
		. "0C74424200000000089F883E801498D4487044189FF4889442"
		. "4088B44243083E801894424788B042485C00F88D9000000488"
		. "B5C24288B8424100100004D89EC448B6C245401D8C1E010894"
		. "4247089D82B8424F000000089C7B8000000000F49C731FF894"
		. "4246C0FAF842418010000894424648B8424F000000001D8894"
		. "42474908B442404897C24188D1C388B4424384139C60F84AB0"
		. "000004189C131C04585ED448B44241C7F36E9C30000000F1F4"
		. "0004139CE7E1B418B148401DA4863D2807C150000740B4183E"
		. "901782E0F1F4400004883C0014139C50F8E920000004139C78"
		. "9C17ECC8B148601DA4863D2807C15000174BD4183E80179B74"
		. "883C701393C240F8D7AFFFFFF4D89E54883442428018B9C241"
		. "8010000488B442428015C2404394424680F8DFCFEFFFF8B4C2"
		. "42089C84881C4880000005B5E5F5D415C415D415E415FC3458"
		. "5FF7E278B4C241C4C8B4424084889F28B0201D84898807C050"
		. "001740583E90178934883C2044939D075E583BC24580100000"
		. "70F8EE60100008B442478488B8C24500100000344241844896"
		. "C2450448BAC241801000044897C24404883C1204889742410C"
		. "744243C07000000448974244448897C24484989CF895C247C8"
		. "9C64C89642430418B074489EA29C28944245C8B8424E800000"
		. "001F039C20F4EC239F0894424580F8CD0000000418B47148BB"
		. "C2420010000412B7F0449635FFC458B4F08458B670C8944246"
		. "08B442474458B771039C70F4FF8488B44241048C1E3024C8D1"
		. "41848035C24308B442464448D04068B44246C39F84189C37F7"
		. "2904585C97E234489F131D2418B04924401C04898807C05000"
		. "1740583E90178464883C2014139D17FE28B4424604139C40F8"
		. "4AA0000004585E40F8EA100000089C131D2EB0D4883C201413"
		. "9D40F8E8E0000008B04934401C04898807C05000074E483E90"
		. "179DF4183C3014501E84439DF7D8F83C601397424580F8D6EF"
		. "FFFFF488B7C2448448B7C2440448B742444448B6C2450488B7"
		. "424104C8B6424304883C701393C240F8D97FDFFFFE918FEFFF"
		. "F6690037C240844017C241883442404014401EF8B442404398"
		. "424200100000F854DFBFFFF4C8BBC2440010000E996FCFFFF8"
		. "B44245C8344243C074983C71C8D7406FF8B44243C398424580"
		. "100000F8F87FEFFFF448B7C2440448B742444448B6C2450488"
		. "B7C24488B5C247C488B7424104C8B64243048634424208B542"
		. "418039424080100004C8B9C24600100000B5424708D4801398"
		. "C2468010000418914830F8E9AFDFFFF4585FF7E1D4C8B44240"
		. "84889F08B104883C00401DA4C39C04863D2C64415000075EB4"
		. "883C701393C24894C24200F8DBAFCFFFFE93BFDFFFF0F1F440"
		. "0008B7C24308B44242831D2F7F70FAF8424000100008D04908"
		. "94424208B8424180100000384240801000029F8894424308B8"
		. "42410010000038424200100002B44243C39842410010000894"
		. "424440F8F2B0400008B8424000100008BBC24080100000FAF8"
		. "42410010000448B642440448B6C24544C8B8C24F8000000C74"
		. "42428000000008D04B8034424208944243C8B4424303984240"
		. "80100000F8F360100008B8424100100008B6C243CC1E010894"
		. "424408B8424080100008904248D450289EF2B7C24204585ED4"
		. "898450FB61C018D45014898410FB61C014863C5410FB634010"
		. "F8E1C0100008B442438894424188B44241C8944240431C0EB6"
		. "90F1F800000000044395424107E4E418B0C8601F98D5102448"
		. "D41014863C9410FB60C094863D24D63C0410FB61411470FB60"
		. "40129F10FAFC94429DA4129D80FAFD2450FAFC08D1452428D1"
		. "4828D144A395424087207836C241801786B4883C0014139C50"
		. "F8E9F0000004139C44189C27E96418B0C8701F98D5102448D4"
		. "1014863C9410FB60C094863D24D63C0410FB61411470FB6040"
		. "129F10FAFC94429DA4129D80FAFD2450FAFC08D1452428D148"
		. "28D144A3B5424080F864BFFFFFF836C2404010F8940FFFFFF8"
		. "304240183C5048B0424394424300F8DE6FEFFFF83842410010"
		. "000018BBC24000100008B442444017C243C3B8424100100000"
		. "F8D95FEFFFF8B4C2428E95CFBFFFF48634424288B5424400B1"
		. "424488BBC24600100008D48013B8C24680100008914870F8D3"
		. "5FBFFFF8304240183C504894C24288B0424394424300F8D7AF"
		. "EFFFFEB92448B5C2428448B84242001000031DB8B842418010"
		. "00031F6448B9424180100004183C30141C1E3074585C08D2C8"
		. "5000000000F8E6BF9FFFF4585D27E57488B8C24F80000004C6"
		. "3CE4C038C24300100004863C74531C0488D4C01020FB6110FB"
		. "641FF440FB661FE6BC04B6BD22601C24489E0C1E0044429E00"
		. "1D04139C3430F9704014983C0014883C1044539C27FCC01EF4"
		. "401D683C3014401EF399C24200100007595E9FBF8FFFF8B8C2"
		. "4200100008B84241801000031DB31F6448B8C241801000085C"
		. "98D2C85000000007E7D4585C97E694C63C6488B8C24F800000"
		. "04863C74D89C24C038424300100004C0394242801000031D24"
		. "88D4C0102440FB6190FB641FF4883C104440FB661FA6BC04B4"
		. "56BDB264101C34489E0C1E0044429E04401D8C1F8074188041"
		. "241C60410004883C2014139D17FC401EF4401CE83C3014401E"
		. "F399C2420010000758383BC2420010000020F8E4BF8FFFF486"
		. "3B424180100008B9C24180100008BBC2420010000488D56014"
		. "48D67FFBF010000004889D0480394243001000048038424280"
		. "100004889D58D53FD4C8D6A0183BC241801000002488D1C067"
		. "E7E4989C04D8D5C05004989D94929F04889E90FB610440FB65"
		. "0FF035424284439D27C44440FB650014439D27C3A450FB6104"
		. "439D27C31450FB6114439D27C28450FB650FF4439D27C1E450"
		. "FB650014439D27C14450FB651FF4439D27C0A450FB65101443"
		. "9D27D03C601014883C0014983C1014883C1014983C0014C39D"
		. "8759383C7014801F54889D84139FC0F8562FFFFFFE968F7FFF"
		. "F31C9E9D9F8FFFF909090909090909090909090"
		this.mCode(MyFunc, A_PtrSize=8 ? x64:x32)
		}
		return !bits.1 ? 0:DllCall(&MyFunc, "int",mode, "uint",color
		, "uint",n, "int",offsetX, "int",offsetY, Ptr,bits.1
		, "int",bits.2, "int",sx, "int",sy, "int",sw, "int",sh
		, Ptr,&gs, Ptr,&ss, "AStr",text, Ptr,&s1, Ptr,&s0
		, Ptr,&input, "int",num, Ptr,&allpos, "int",allpos_max)
	}


	mCode(ByRef code, hex)
	{
		local
		bch := A_BatchLines
		SetBatchLines, -1
		VarSetCapacity(code, len := StrLen(hex)//2)
		lls := A_ListLines=0 ? "Off" : "On"
		ListLines, Off
		loop, % len
		NumPut("0x" SubStr(hex,2*A_Index-1,2),code,A_Index-1,"uchar")
		ListLines, %lls%
		Ptr := A_PtrSize ? "UPtr" : "UInt", PtrP := Ptr "*"
		DllCall("VirtualProtect",Ptr,&code, Ptr,len,"uint",0x40,PtrP,0)
		SetBatchLines, %bch%
	}


	base64tobit(s)
	{
		local
		Chars := "0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		. "abcdefghijklmnopqrstuvwxyz"
		lls := A_ListLines=0 ? "Off" : "On"
		ListLines, Off
		loop, Parse, Chars
		{
		i := A_Index-1, v := (i>>5&1) . (i>>4&1)
			. (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1)
		s := RegExReplace(s,"[" A_LoopField "]",StrReplace(v,"0x"))
		}
		ListLines, %lls%
		return RegExReplace(RegExReplace(s,"10*$"),"[^01]+")
	}


	bit2base64(s)
	{
		local
		s := RegExReplace(s,"[^01]+")
		s.=SubStr("100000",1,6-Mod(StrLen(s),6))
		s := RegExReplace(s,".{6}","|$0")
		Chars := "0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZ"
		. "abcdefghijklmnopqrstuvwxyz"
		lls := A_ListLines=0 ? "Off" : "On"
		ListLines, Off
		loop, Parse, Chars
		{
		i := A_Index-1, v := "|" . (i>>5&1) . (i>>4&1)
			. (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1)
		s := StrReplace(s,StrReplace(v,"0x"),A_LoopField)
		}
		ListLines, %lls%
		return s
	}


	convertASCII(s)
	{
		local
		if RegExMatch(s,"\$(\d+)\.([\w+/]+)",r)
		{
		s := RegExReplace(this.base64tobit(r2),".{" r1 "}","$0`n")
		s := StrReplace(StrReplace(s,"0","_"),"1","0")
		}
		else s=
		return s
	}


	; You can put the text library at the beginning of the script,
	; and Use this.picLib(Text,1) to add the text library to this.picLib()'s Lib,
	; Use this.picLib("comment1|comment2|...") to get text images from Lib
	picLib(comments, add_to_Lib := 0, index := 1)
	{
		local
		static Lib := []
		if (add_to_Lib)
		{
		re := "<([^>]*)>[^$]+\$\d+\.[\w+/]+"
		loop, Parse, comments, |
			if RegExMatch(A_LoopField,re,r)
			{
			s1 := Trim(r1), s2 := ""
			loop, Parse, s1
				s2.="_" . Format("{:d}",Ord(A_LoopField))
			Lib[index,s2] := r
			}
		Lib[index,""] := ""
		}
		else
		{
		Text := ""
		loop, Parse, comments, |
		{
			s1 := Trim(A_LoopField), s2 := ""
			loop, Parse, s1
			s2.="_" . Format("{:d}",Ord(A_LoopField))
			Text.="|" . Lib[index,s2]
		}
		return Text
		}
	}


	picN(Number, index := 1)
	{
		return this.picLib(RegExReplace(Number,".","|$0"), 0, index)
	}


	; Use picX(Text) to automatically cut into multiple characters
	; Can't be used in ColorPos mode, because it can cause position errors
	picX(Text)
	{
		local
		if !RegExMatch(Text,"\|([^$]+)\$(\d+)\.([\w+/]+)",r)
		return Text
		v := this.base64tobit(r3), Text := ""
		c := StrLen(StrReplace(v,"0"))<=StrLen(v)//2 ? "1":"0"
		wz := RegExReplace(v,".{" r2 "}","$0`n")
		while InStr(wz,c)
		{
		while !(wz~="m`n)^" c)
			wz := RegExReplace(wz,"m`n)^.")
		i := 0
		while (wz~="m`n)^.{" i "}" c)
			i := Format("{:d}",i+1)
		v := RegExReplace(wz,"m`n)^(.{" i "}).*","$1")
		wz := RegExReplace(wz,"m`n)^.{" i "}")
		if (v!="")
			Text.="|" r1 "$" i "." this.bit2base64(v)
		}
		return Text
	}


	; screenShot and retained as the last screenShot.
	screenShot(x1 := "", y1 := "", x2 := "", y2 := "")
	{
		local
		if (x1+y1+x2+y2="") {
			n := 150000, x := y:=-n, w := h:=2*n
		} else {
			x := (x1<x2 ? x1:x2), y := (y1<y2 ? y1:y2)
			, w := Abs(x2-x1)+1, h := Abs(y2-y1)+1
			this.xywh2xywh(x,y,w,h,x,y,w,h,zx,zy,zw,zh)
			this.getBitsFromScreen(x,y,w,h,1,zx,zy,zw,zh)
		}
	}


	; Get the RGB color of a point from the last this.screenShot.
	; If the point to get the color is beyond the range of
	; Screen, it will return White color (0xFFFFFF).
	screenShot_GetColor(x,y)
	{
		local
		bits := this.getBitsFromScreen(0,0,0,0,0,zx,zy,zw,zh)
		return (x<zx or x>zx+zw-1 or y<zy or y>zy+zh-1 or !bits.1)
		? "0xFFFFFF" : Format("0x{:06X}",NumGet(bits.1
		+(y-zy)*bits.2+(x-zx)*4,"uint")&0xFFFFFF)
	}


	; Identify a line of text or verification code
	; based on the result returned by this.search()
	; Return Associative array {ocr:Text, x:X, y:Y}
	resultOCR(ok, offsetX := 20, offsetY := 20)
	{
		local
		ocr_Text := ocr_X := ocr_Y := min_X := ""
		for k,v in ok
		x := v.1
		, min_X := (A_Index=1 or x<min_X ? x : min_X)
		, max_X := (A_Index=1 or x>max_X ? x : max_X)
		while (min_X!="" and min_X<=max_X)
		{
		LeftX := ""
		for k,v in ok
		{
			x := v.1, y := v.2, w := v.3, h := v.4
			if (x<min_X) or Abs(y-ocr_Y)>offsetY
			continue
			; Get the leftmost X coordinates
			if (LeftX="" or x<LeftX)
			LeftX := x, LeftY := y, LeftW := w, LeftH := h, LeftOCR := v.id
			else if (x=LeftX)
			{
			loop, 100
			{
				err := (A_Index-1)/100+0.000001
				if this.search(LeftX,LeftY,LeftX+LeftW-1,LeftY+LeftH-1,err,err,Text,0).Count()
				break
				if this.search(x, y, x+w-1, y+h-1, err, err, Text, 0).Count()
				{
				LeftX := x, LeftY := y, LeftW := w, LeftH := h, LeftOCR := v.id
				break
				}
			}
			}
		}
		if (ocr_X="")
			ocr_X := LeftX, ocr_Y := LeftY
		; If the interval exceeds the set value, add "*" to the result
		ocr_Text.=(ocr_Text!="" and LeftX-min_X>offsetX ? "*":"") . LeftOCR
		; Update min_X for next search
		min_X := LeftX+LeftW
		}
		return {ocr:ocr_Text, x:ocr_X, y:ocr_Y}
	}


	; Sort the results objects from left to right and top to bottom, ignoring slight height difference
	resultSort(param_resultObj, param_ydistance:=10)
	{
		resultObj := param_resultObj.clone()
		ypos := []
		for k,v in resultObj {
			x := v.x, y := v.y, add := 1
			for k2,v2 in ypos
				if (Abs(y-v2) <= param_ydistance) {
				y := v2, add := 0
				break
			}
			if (add)
				ypos.Push(y)
			n := (y*150000+x) "." k, s := A_Index=1 ? n : s "-" n
		}
		Sort, s, N D-
		resultObj2 := []
		loop, Parse, s, -
		resultObj2.Push( resultObj[(StrSplit(A_LoopField,".")[2])] )
		return resultObj2
	}


	; Re-order resultObj according to the nearest distance
	resultSortDistance(param_resultObj, param_x:=1, param_y:=1)
	{
		resultObj := param_resultObj.clone()
		for k, v in resultObj {
			x := v.1+v.3//2, y := v.2+v.4//2
			n := ((x-param_x)**2+(y-param_y)**2) "." k
			; save the square root to the result object pre-sorting
			resultObj[A_Index].distance := round(sqrt(StrSplit(n, ".")[1]), 2)
			s := A_Index = 1 ? n : s "-" n
		}
		Sort, s, N D-
		resultObj2 := []
		loop, Parse, s, -
		{
			resultObj2.Push(resultObj[(StrSplit(A_LoopField,".")[2])])
		}
		return resultObj2
	}


	; Prompt mouse position in remote assistance
	mouseTip(x := "", y := "")
	{
		local
		if (x="") {
			VarSetCapacity(pt,16,0), DllCall("GetCursorPos","ptr",&pt)
			x := NumGet(pt,0,"uint"), y := NumGet(pt,4,"uint")
		}
		x := Round(x-10), y := Round(y-10), w := h:=2*10+1
		;-------------------------
		Gui, _mouseTip_: +AlwaysOnTop -Caption +ToolWindow +Hwndmyid +E0x08000000
		Gui, _mouseTip_: Show, Hide w%w% h%h%
		;-------------------------
		dhw := A_DetectHiddenWindows
		DetectHiddenWindows, On
		d := 4, i := w-d, j := h-d
		s=0-0 %w%-0 %w%-%h% 0-%h% 0-0
		s=%s%  %d%-%d% %i%-%d% %i%-%j% %d%-%j% %d%-%d%
		WinSet, Region, %s%, ahk_id %myid%
		DetectHiddenWindows, %dhw%
		;-------------------------
		Gui, _mouseTip_: Show, NA x%x% y%y%
		loop, 4
		{
			Gui, _mouseTip_: Color, % A_Index & 1 ? "Red" : "Blue"
			Sleep, 500
		}
		Gui, _mouseTip_: Destroy
	}


	getTextFromScreen(x1, y1, x2, y2, Threshold := "", screenShot := 1, ByRef rx := "", ByRef ry := "")
	{
		local
		bch := A_BatchLines
		SetBatchLines, -1
		x := (x1<x2 ? x1:x2), y := (y1<y2 ? y1:y2)
		, w := Abs(x2-x1)+1, h := Abs(y2-y1)+1
		, this.xywh2xywh(x,y,w,h,x,y,w,h,zx,zy,zw,zh)
		if (w<1 or h<1) {
			SetBatchLines, %bch%
			return []
		}
		lls := A_ListLines=0 ? "Off" : "On"
		ListLines, Off
		this.getBitsFromScreen(x,y,w,h,this.screenShot,zx,zy,zw,zh)
		gc := [], k := 0
		loop, %h% {
			j := y+A_Index-1
			loop, %w%
			{
				i := x+A_Index-1, c := this.this.screenShot_GetColor(i,j), gc[++k] := (((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
			}
		}
		Threshold := StrReplace(Threshold,"*")
		if (Threshold="") {
			pp := []
			loop, 256
				pp[A_Index-1] := 0
			loop, % w*h
				pp[gc[A_Index]]++
			IP := IS := 0
			loop, 256
				k := A_Index-1, IP+=k*pp[k], IS+=pp[k]
			Threshold := Floor(IP/IS)
			loop, 20
			{
				LastThreshold := Threshold
				IP1 := IS1 := 0
				loop, % LastThreshold+1
					k := A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
					IP2 := IP-IP1, IS2 := IS-IS1
					if (IS1!=0 and IS2!=0)
						Threshold := Floor((IP1/IS1+IP2/IS2)/2)
					if (Threshold=LastThreshold)
						break
			}
		}
		s := ""
		loop, % w*h
		s .= gc[A_Index]<=Threshold ? "1":"0"
		;--------------------
		w := Format("{:d}",w), CutUp := CutDown := 0
		re1 = (^0{%w%}|^1{%w%})
		re2 = (0{%w%}$|1{%w%}$)
		while RegExMatch(s,re1)
			s := RegExReplace(s,re1), CutUp++
		while RegExMatch(s,re2)
			s := RegExReplace(s,re2), CutDown++
			rx := x+w//2, ry := y+CutUp+(h-CutUp-CutDown)//2
			s := "|<>*" Threshold "$" w "." this.bit2base64(s)
		;--------------------
		SetBatchLines, %bch%
		ListLines, %lls%
		return s
	}
}
