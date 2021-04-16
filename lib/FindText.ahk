;/*
;===========================================
;  FindText - Capture screen image into text and then find it
;  https://autohotkey.com/boards/viewtopic.php?f=6&t=17834
;
;  Author  : FeiYue
;  Version : 8.4
;  Date    : 2021-04-02
;
;  Usage:  (required AHK v1.1.31+)
;  1. Capture the image to text string.
;  2. Test find the text string on full Screen.
;  3. When test is successful, you may copy the code
;     and paste it into your own script.
;     Note: Copy the "FindText()" function and the following
;     functions and paste it into your own script Just once.
;  4. The more recommended way is to save the script as
;     "FindText.ahk" and copy it to the "Lib" subdirectory
;     of AHK program, instead of copying the "FindText()"
;     function and the following functions, add a line to
;     the beginning of your script: #Include <FindText>
;
;===========================================
;*/


;--------------------------------
;  FindText - Capture screen image into text and then find it
;--------------------------------
;  returnArray := FindText(
;      X1 --> the search scope's upper left corner X coordinates
;    , Y1 --> the search scope's upper left corner Y coordinates
;    , X2 --> the search scope's lower right corner X coordinates
;    , Y2 --> the search scope's lower right corner Y coordinates
;    , err1 --> Fault tolerance percentage of text       (0.1=10%)
;    , err0 --> Fault tolerance percentage of background (0.1=10%)
;    , Text --> can be a lot of text parsed into images, separated by "|"
;    , ScreenShot --> if the value is 0, the last screenshot will be used
;    , FindAll --> if the value is 0, Just find one result and return
;    , JoinText --> if the value is 1, Join all Text for combination lookup
;    , offsetX --> Set the max text offset (X) for combination lookup
;    , offsetY --> Set the max text offset (Y) for combination lookup
;    , dir --> Nine directions for searching: up, down, left, right and center
;  )
;
;  The function returns a second-order array containing
;  all lookup results, Any result is an associative array
;  {1:X, 2:Y, 3:W, 4:H, x:X+W//2, y:Y+H//2, id:Comment}
;  if no image is found, the function returns 0.
;  All coordinates are relative to Screen, colors are in RGB format
;
;  If the return variable is set to "ok", ok.1 is the first result found.
;  Where ok.1.1 is the X coordinate of the upper left corner of the found image,
;  and ok.1.2 is the Y coordinate of the upper left corner of the found image,
;  ok.1.3 is the width of the found image, and ok.1.4 is the height of the found image,
;  ok.1.x <==> ok.1.1+ok.1.3//2 ( is the Center X coordinate of the found image ),
;  ok.1.y <==> ok.1.2+ok.1.4//2 ( is the Center Y coordinate of the found image ),
;  ok.1.id is the comment text, which is included in the <> of its parameter.
;  ok.1.x can also be written as ok[1].x, which supports variables. (eg: ok[A_Index].x)
;
;--------------------------------

FindText(args*)
{
  return FindText.FindText(args*)
}

Class FindText
{  ;// Class Begin

static bind:=[], bits:=[], Lib:=[]

__New()
{
  this.bind:=[], this.bits:=[], this.Lib:=[]
}

__Delete()
{
  if (this.bits.hBM)
    DllCall("DeleteObject", "Ptr",this.bits.hBM)
}

FindText(x1:=0, y1:=0, x2:=0, y2:=0, err1:=0, err0:=0
  , text:="", ScreenShot:=1, FindAll:=1
  , JoinText:=0, offsetX:=20, offsetY:=10, dir:=1)
{
  local
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  centerX:=Round(x1+x2)//2, centerY:=Round(y1+y2)//2
  if (x1*x1+y1*y1+x2*x2+y2*y2<=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
  , info:=[]
  Loop, Parse, text, |
    if IsObject(j:=this.PicInfo(A_LoopField))
      info.Push(j)
  if (w<1 or h<1 or !(num:=info.MaxIndex()) or !bits.Scan0)
  {
    SetBatchLines, %bch%
    return 0
  }
  arr:=[], in:={zx:zx, zy:zy, zw:zw, zh:zh
  , sx:x-zx, sy:y-zy, sw:w, sh:h}, k:=0
  For i,j in info
    k:=Max(k, j.2*j.3), in.comment .= j.11
  VarSetCapacity(s1, k*4), VarSetCapacity(s0, k*4)
  , VarSetCapacity(ss, 2*(w+2)*(h+2))
  , FindAll:=(dir=9 ? 1 : FindAll)
  , JoinText:=(num=1 ? 0 : JoinText)
  , allpos_max:=(FindAll or JoinText ? 10240 : 1)
  , VarSetCapacity(allpos, allpos_max*8)
  Loop, 2
  {
    if (err1=0 and err0=0) and (num>1 or A_Index>1)
      err1:=0.05, err0:=0.05
    Loop, % JoinText ? 1 : num
    {
      this.PicFind(arr, in, info, A_Index, err1, err0
        , FindAll, JoinText, offsetX, offsetY, dir
        , bits, ss, s1, s0, allpos, allpos_max)
      if (!FindAll and arr.MaxIndex())
        Break
    }
    if (err1!=0 or err0!=0 or arr.MaxIndex() or info.1.12)
      Break
  }
  if (dir=9)
    arr:=this.Sort2(arr, centerX, centerY)
  SetBatchLines, %bch%
  return arr.MaxIndex() ? arr:0
}

PicFind(arr, in, info, index, err1, err0
  , FindAll, JoinText, offsetX, offsetY, dir
  , bits, ByRef ss, ByRef s1, ByRef s0
  , ByRef allpos, allpos_max)
{
  local
  static MyFunc:=""
  if (!MyFunc)
  {
    x32:=""
    . "5557565383EC608B6C247483FD050F84900900008B8424B800000085C00F8E35"
    . "0F000031FF31C0896C2474C744240C00000000C74424040000000031C9C74424"
    . "1400000000897C241089C5908D7426008B5C24108BBC24B40000008B7424148B"
    . "54240C01DF89D829DE8B9C24B400000003B424B000000085DB0F8EB802000089"
    . "3C2489EB89D7EB21908DB426000000008BAC24AC00000083C70483C00189548D"
    . "0083C1013904247429837C24740389FA0F45D0803C063175D78BAC24A8000000"
    . "83C70483C00189549D0083C30139042475D78BB424B40000000174241489DD89"
    . "F083442404018BBC249C0000008B742404017C24108BBC2488000000017C240C"
    . "39B424B80000000F8543FFFFFF894424248B8424B8000000896C240C8B6C2474"
    . "894C24108944242031C08B74240C39B424BC0000008B5C24100F4DF0399C24C0"
    . "0000008974240C0F4CC339C6894424100F4DC683FD03894424040F84F1010000"
    . "8B8424880000008BB424940000000FAF842498000000C1E6028974243001F08B"
    . "B42488000000894424348B84249C000000F7D885ED8D0486894424200F85A006"
    . "00008B442478C744241C00000000C744242800000000C1E8100FB6E88B442478"
    . "0FB6C4894424140FB6442478894424188B84249C000000C1E0028944242C8B84"
    . "24A000000085C00F8EA80D00008B4424348B7C2408896C24088BAC249C000000"
    . "31D285ED0F8E8A0000008BB424840000008B6C242803AC24A400000001C60344"
    . "242C89442424038424840000008904240FB67E028B4C24080FB6160FB646012B"
    . "5424182B44241489FB01CF29CB8D8F000400000FAFC00FAFCBC1E00B0FAFCBBB"
    . "FE05000029FB0FAFDA01C10FAFD301CA3954247C0F93450083C60483C5013B34"
    . "2475AD8B9C249C000000015C24288B44242489DA8344241C018B74241C034424"
    . "2039B424A00000000F854BFFFFFF8B8424A0000000897C240889542424894424"
    . "208B84249C0000002B8424B4000000BA01000000C644243C00C644243800C744"
    . "244C00000000C744245400000000894424588B8424A00000002B8424B8000000"
    . "894424348B84248000000083E80183F8070F86A7000000C78424800000000100"
    . "00008B4424348B7424588944245889742434E9A500000031C0E9A3FDFFFFC744"
    . "242000000000C78424BC0000000000000083FD058B84249C0000000F94442438"
    . "83FD030F9444243C0384249400000031D22B8424B4000000894424588B842498"
    . "000000038424A00000002B8424B8000000894424348B8424980000008944244C"
    . "8B842494000000894424548B84248000000083E80183F8070F8759FFFFFF83BC"
    . "2480000000040F8E56FFFFFF8B4424548B74244C8944244C897424548B742458"
    . "3974244C0F8F950B00008B842480000000897424508B74240CC744242C000000"
    . "0083E80183E0018944245C8B8424940000000FAFC20FAF942498000000894424"
    . "408B8424A80000008D04B08BB4248400000089542444894424488B7C245C8B44"
    . "24508B5C242485FF0F4444244C83BC2480000000050F4DD80F4D442420895C24"
    . "248B5C2434894424208B44245439D80F8F5E0100008944241C8DB42600000000"
    . "83BC2480000000058B4424208B5C241C0F4DC3894424208B4424240F4CC3807C"
    . "243800894424248B4424200F854F010000807C243C000F85240200000FAF8424"
    . "9C0000008B5424048B5C242485D28D2C180F8E8A0000008BBC24C00000008B94"
    . "24A400000031C08B9C24BC000000896C24188B4C240C89B4248400000001EA89"
    . "7C24148B6C24048B7C2410891C24669039C17E1B8B9C24A80000008B348301D6"
    . "803E00750A832C24010F88F102000039C77E1C8B9C24AC0000008B348301D680"
    . "3E00740B836C2414010F88D102000083C00139C575BA8B6C24188BB424840000"
    . "008B44240C85C074258B9C24A40000008B8424A80000008D0C2B8B5C24486690"
    . "8B1083C00401CA39D8C6020075F28B442424034424408B5C242C8BBC24C40000"
    . "008904DF8B442420034424448944DF0483C3013B9C24C8000000895C242C7D2B"
    . "8344241C018B44241C394424340F8DADFEFFFF8344244C01836C2450018B4424"
    . "4C394424580F8D4FFEFFFF8B44242C83C4605B5E5F5DC258008DB42600000000"
    . "0FAF8424880000008B5C24248D04988B5C24048944241885DB0F8E6FFFFFFF8B"
    . "4424088BAC24BC00000031D2891424F7D8896C242889442414EB4E908D742600"
    . "89FA0FB6EE89FA29E90FB6EA29EB3B4C24080F9FC289D58B54241439D00F9CC0"
    . "09C539D10F9CC009E83B5C24080F9FC108C8755239D37C4E830424018B042439"
    . "4424040F84A70100008B8424A80000008B3C248B5C2418031CB88B8424AC0000"
    . "008B3CB80FB6441E0289F9C1E9100FB6C929C83B4424080FB64C1E010FB61C1E"
    . "0F8E7AFFFFFF836C24280179AB897C2478E9EAFEFFFF8D76008DBC2700000000"
    . "0FAF8424880000008B5C24248B4C24048D04988904240344247885C90FB65C06"
    . "010FB67C06020FB60406895C2414894424180F8E76FEFFFF8B8424C000000031"
    . "DB894424308B8424BC000000894424288B442408897C2408908DB42600000000"
    . "395C240C7E618B8424A80000008B0C248B7C2408030C980FB6440E020FB6540E"
    . "010FB60C0E2B5424142B4C241889C501F829FD8DB8000400000FAFD20FAFFDC1"
    . "E20B0FAFFDBDFE05000029C50FAFE901FA0FAFCD01D13B4C247C760B836C2428"
    . "010F8892000000395C24107E5D8B8424AC0000008B0C248B7C2408030C980FB6"
    . "440E020FB6540E010FB60C0E2B5424142B4C241889C501F829FD8DB800040000"
    . "0FAFD20FAFFDC1E20B0FAFFDBDFE05000029C50FAFE901FA0FAFCD01D13B4C24"
    . "7C7707836C243001782F83C301395C24040F8529FFFFFF89442408E96EFDFFFF"
    . "8BB42484000000E994FDFFFF8D742600897C2478E955FDFFFF89442408E97EFD"
    . "FFFF83FD010F842C06000083FD020F84910300008B4424780FB67C2478C74424"
    . "2C00000000C744243000000000C1E8100FB6D08B44247889D50FB6DC8B44247C"
    . "C1E8100FB6C88B44247C29CD01CA896C243C89DD8914240FB6F40FB644247C29"
    . "F501DE896C241489FD8974241829C501F8894424288B84249C000000896C241C"
    . "C1E002894424388B8424A000000085C00F8EBF0600008B4C24348B6C243C8B84"
    . "249C00000085C00F8E830500008B8424840000008B542430039424A400000001"
    . "C8034C243889CF894C242403BC2484000000EB33391C247C3D394C24147F3739"
    . "4C24187C3189F30FB6F33974241C0F9EC3397424280F9DC183C00483C20121D9"
    . "884AFF39C7741E0FB658020FB648010FB63039DD7EBE31C983C00483C201884A"
    . "FF39C775E28BB4249C000000017424308B4C242489F08344242C018B74242C03"
    . "4C242039B424A00000000F854EFFFFFF894424248B8424A000000089442420E9"
    . "1DF9FFFF8B44247C894424048B442478894424088B44247C85C00F8580010000"
    . "8B8424B00000008B0089C78B8424B400000081E7FFFFFF008D88FFFFFF3F8B84"
    . "24B80000008D1C8D0000000083E8010FAF8424B400000089C28B8424B0000000"
    . "8B049089042425FFFFFF0039F80F95C089C68B8424B00000008B048889F125FF"
    . "FFFF0039F80F95C008C175218B8424B40000008BB424B00000008D8402FFFFFF"
    . "3F8B048625FFFFFF0039F87405BFFFFFFFFF8B8424B800000085C00F8EDDF8FF"
    . "FF8D43048B4C2404C744241800000000C744241400000000C744241C00000000"
    . "89442420896C24748BB424B400000031C085F67E5F8BB424B00000008B5C241C"
    . "8B4424188B6C24208D349E01C529C68934248B34248B140681E2FFFFFF0039D7"
    . "741E8BB424A80000008D1C8D0000000089048E8BB424AC00000083C10189141E"
    . "83C00439C575CB8BB424B40000000174241C89F083442414018B7424148B9424"
    . "880000000154241839B424B80000000F8573FFFFFF894424248B8424BC000000"
    . "8B6C2474894C24040FAFC1C1F808898424BC0000008B8424B800000089442420"
    . "8B44240483F8010F8E04F8FFFF8BB424AC000000896C24748BAC24AC0000008D"
    . "7E04BE01000000893C2489C78B042489F28B58FC89C129E93918751E83C20183"
    . "C00439D77FEE83C6018304240439F775DB8B6C2474E9B7F7FFFF39D674E88B9C"
    . "24A8000000038C24A80000008B9424A80000008B1CB3895C24148B19891CB28B"
    . "5C241483C60189198B1C248304240439F78B13895424788B1089138B5C247889"
    . "187589EBAC8B84249C0000008BBC24980000000FAF8424A00000008D5FFF0384"
    . "24A4000000891C24894424188B84249C0000000384249400000089C689442428"
    . "8B842498000000038424A000000039D80F8C060100000FAF9C248800000083C0"
    . "018BBC2494000000C7442420000000008944242C89E82B84249400000083EF01"
    . "897C24248D7E01895C241C89C301F3895C24348B442424394424280F8C0B0300"
    . "008B14248B5C241C8B742420035C24302BB42494000000039C2484000000C1EA"
    . "1F0374241889542414EB4F908D7426003984248C0000007E4A807C2414007543"
    . "8B1424399424900000007E370FB64BFE0FB653FD83C3040FB66BF86BD24B6BC9"
    . "2601D189EAC1E20429EA01CAC1FA078854060183C00139F8741889C2C1EA1F84"
    . "D274ADC64406010083C00183C30439F875E88B5C2434015C242089F883042401"
    . "8B9424880000008B34240154241C3974242C0F853BFFFFFF894424248B84249C"
    . "0000008B8C24A000000083C00285C98944241C0F8E490200008B8424A0000000"
    . "8B6C2418036C241CC744241801000000C74424240000000083C001894424208B"
    . "84249C000000896C241483C004894424288B44247C8B94249C00000085D20F8E"
    . "D10100008B4424148B5C24248B742428039C24A400000089C12B8C249C000000"
    . "89C201C6890C2489F68DBC27000000000FB642010FB62ABF0100000003442478"
    . "39E8723C0FB66A0239E872348B0C240FB669FF39E872290FB66EFF39E872210F"
    . "B669FE39E872190FB62939E872120FB66EFE39E8720A0FB63E39F80F92C189CF"
    . "89F98304240183C201880B83C60183C3018B3C24397C241475968BB4249C0000"
    . "00017424248D560183442418018B7424188B5C241C015C2414397424200F8532"
    . "FFFFFF895424248944247CE951F4FFFF31C0E9FFFAFFFF8B4424788BB424A000"
    . "000031EDC74424140000000083C001C1E007894424788B84249C000000C1E002"
    . "85F6894424180F8EE9000000892C248B4424348B6C24788B9C249C00000031D2"
    . "85DB7E688B8C24840000008B5C2414039C24A400000001C1034424188944241C"
    . "0384248400000089C78DB426000000000FB651020FB641010FB6316BC04B6BD2"
    . "2601C289F0C1E00429F001D039C50F970383C10483C30139F975D58BBC249C00"
    . "0000017C24148B44241C89FA830424018B34240344242039B424A00000000F85"
    . "73FFFFFF8B8424A00000008954242489442420E969F3FFFFC744241000000000"
    . "C744240C00000000C744242000000000E9B3F1FFFFBA01000000E9C9FEFFFFC7"
    . "44242C00000000E95FF6FFFF8B442424E987FDFFFFC744242000000000E91FF3"
    . "FFFFC744242001000000E912F3FFFF90"
    x64:=""
    . "4157415641554154555756534883EC784C8B9C24E00000004C8BA42420010000"
    . "83F90589CE89542458448944241044898C24D8000000488BBC2428010000488B"
    . "AC24300100000F841D0A0000448B8C24480100004585C90F8E4E1000004C899C"
    . "24E0000000448B9C244001000031C04C89A424200100004531FF31DB4531ED45"
    . "31F6C74424080000000044895424144189C431C04585DB7E654863542408478D"
    . "143B4489F848039424380100004489E1EB1B83C0014D63CD83C1044183C50148"
    . "83C2014139C24689448D00742983FE034189C8440F45C0803A3175D683C0014D"
    . "63CE83C1044183C6014883C2014139C24689048F75D744015C24084489D883C3"
    . "014403BC24100100004403A424E8000000399C24480100000F8574FFFFFF8944"
    . "24408B8424480100004C8B9C24E00000004C8BA42420010000448B5424148944"
    . "241431C04439B42450010000440F4DF04439AC2458010000440F4DE84539EE45"
    . "89EF450F4DFE83FE030F84350200008B8424E80000008B9C24000100000FAF84"
    . "24080100008D04988B9C24E8000000894424288B842410010000F7D885F68D04"
    . "83894424080F85190700008B5C24584889D889DE0FB6C4C1EE1089C10FB6C340"
    . "0FB6F689C28B84241801000085C00F8E0A0F00008B84241001000031DB44897C"
    . "2418448974242044896C24304189DF448B742428448B6C24108B9C2410010000"
    . "C1E0024C89A424200100004889AC2430010000C7442414000000004189D48944"
    . "24404C899C24E000000089CD4889BC242801000031C085DB0F8E88000000488B"
    . "BC24E00000004963C64531DB4C8D4C070248637C24144803BC24200100006690"
    . "450FB611410FB651FE410FB641FF4429E24489D14101F24189D0418D92000400"
    . "0029F129E80FAFD10FAFC00FAFD1C1E00B8D0402BAFE0500004429D2410FAFD0"
    . "410FAFD001D04139C5420F93041F4983C3014983C1044439DB7FA54403742440"
    . "015C241489D84183C70144037424084439BC24180100000F8557FFFFFF894424"
    . "408B842418010000448B7C2418448B742420448B6C24304C8B9C24E00000004C"
    . "8BA42420010000488BBC2428010000488BAC2430010000894424148B84241001"
    . "00002B842440010000BA01000000C644244400C644243800C744245C00000000"
    . "C744246400000000894424688B8424180100002B842448010000894424308B84"
    . "24D800000083E80183F8070F86A0000000C78424D8000000010000008B442430"
    . "8B5C246889442468895C2430E99E000000C744241400000000C7842450010000"
    . "0000000083FE058B8424100100000F9444243883FE030F944424440384240001"
    . "000031D22B842440010000894424688B842408010000038424180100002B8424"
    . "48010000894424308B8424080100008944245C8B842400010000894424648B84"
    . "24D800000083E80183F8070F8760FFFFFF83BC24D8000000040F8E5DFFFFFF8B"
    . "4424648B5C245C8944245C895C24648B5C2468395C245C0F8F8A0C00008B8424"
    . "D80000004889AC24300100004489ED4D89E54989FC895C2460C7442420000000"
    . "0083E80183E0018944246C8B8424000100000FAFC20FAF942408010000894424"
    . "48418D46FF488D448704488BBC24300100008954244C48894424508B44246C8B"
    . "5C244085C08B4424600F4444245C83BC24D8000000050F4DD80F4D442414895C"
    . "24408B5C2430894424148B44246439D80F8F1B01000089442408660F1F440000"
    . "83BC24D8000000058B4424148B5C24080F4DC3894424148B4424400F4CC3807C"
    . "243800894424400F8513010000807C2444000F85E80100008B4C24140FAF8C24"
    . "10010000034C24404585FF7E528B9C2458010000448B8C245001000031C06690"
    . "4139C689C27E194189C84503048443807C050000750A4183E9010F887E000000"
    . "39D57E1289CA03148741807C150000740583EB0178684883C0014139C77FC145"
    . "85F6741F4C8B4424504C89E00F1F400089CA03104883C0044C39C041C6441500"
    . "0075ED8B5C24208B54244003542448488BB4246001000089D801C04898891486"
    . "8B5424140354244C8954860489D883C0013B842468010000894424207D2B8344"
    . "2408018B442408394424300F8DEFFEFFFF8344245C01836C2460018B44245C39"
    . "4424680F8D92FEFFFF8B4424204883C4785B5E5F5D415C415D415E415FC36690"
    . "8B4424148B5C24400FAF8424E80000004585FF8D04980F8E67FFFFFF8B9C2450"
    . "0100004489D6896C245831D2F7DE448974242889C54189D9EB52660F1F440000"
    . "894C24180FB6CF4189CE8B4C24184429F1440FB6F34529F04439D1410F9FC639"
    . "F00F9CC04109C639F10F9CC04109C64539D00F9FC04108C6754E4139F07C4948"
    . "83C2014139D70F8EE9010000458B04948B1C974101E889D9418D4002C1E9100F"
    . "B6C94898410FB6040329C8418D48014D63C04439D0470FB604034863C9410FB6"
    . "0C0B0F8E78FFFFFF4183E90179B18B6C2458448B742428895C2458E9DEFEFFFF"
    . "8B4424148B5C24400FAF8424E80000008D049889C6034424584585FF8D500248"
    . "63D2410FB61C138D50014898410FB604034863D2410FB60C130F8E64FEFFFF8B"
    . "9424580100004C89AC24200100004531C94C89A424280100004889BC24300100"
    . "004189F54189C489CF895424288B942450010000895424180F1F840000000000"
    . "4539CE4589C87E6E488B842428010000428B14884401EA8D42024898450FB614"
    . "038D42014863D2410FB614134898410FB604034489D64101DA418D8A00040000"
    . "29DE4429E20FAFCE29F80FAFC00FAFCEBEFE050000C1E00B4429D60FAFF201C8"
    . "0FAFD601C23B542410760B836C2418010F88B10000004439C57E70488B842430"
    . "010000428B14884401EA8D42024898450FB614038D42014863D2410FB6141348"
    . "98410FB604034589D04101DA418D8A000400004129D84429E2410FAFC829F80F"
    . "AFC0410FAFC841B8FE050000C1E00B4529D0440FAFC201C8410FAFD001C23B54"
    . "24107707836C242801783C4983C1014539CF0F8F08FFFFFF4C8BAC2420010000"
    . "4C8BA42428010000488BBC2430010000E90EFDFFFF8B6C2458448B742428895C"
    . "2458E9FCFCFFFF4C8BAC24200100004C8BA42428010000488BBC2430010000E9"
    . "1AFDFFFF83FE010F84F606000083FE020F84A00300008B5C2458C74424200000"
    . "000089D8440FB6C3C1E810440FB6C84889D88B5C24100FB6CC4489CE894C2418"
    . "89D8C1E8100FB6D04889D80FB6C429D689C18B44241829C8894424380FB6C344"
    . "89C329C34401C0448B842418010000895C2414418D1C1189DA8B5C2418894424"
    . "188B84241001000001CBC1E00289D931DB4585C0894424300F8E800700004489"
    . "542444448974244844896C244C448B742428448B6C2438448B94241001000044"
    . "897C24404889BC24280100004189CF4889AC243001000089D789DD31C04585D2"
    . "7E744963C64863DD31D2498D4403024C01E3EB334439C77C404139CD7F3B4139"
    . "CF7C3644394C2414410F9EC044394C24180F9DC14883C0044421C1880C134883"
    . "C2014139D27E24440FB6000FB648FF440FB648FE4439C67EBB31C94883C00488"
    . "0C134883C2014139D27FDC44037424304401D54489D083442420014403742408"
    . "8B5C2420399C24180100000F856AFFFFFF448B7C2440894424408B8424180100"
    . "00448B542444448B742448448B6C244C488BBC2428010000488BAC2430010000"
    . "89442414E9B2F8FFFF8B442410448B54245885C04189C70F8566010000488B84"
    . "2438010000488B8C24380100004C8B8C24380100008B0089C3894424088B8424"
    . "4801000081E3FFFFFF0083E8010FAF84244001000089C248638424400100008B"
    . "4481FC25FFFFFF0039D84863C2418B04810F95C125FFFFFF0039D80F95C008C1"
    . "75198B84244001000001D04898418B4481FC25FFFFFF0039D87405BBFFFFFFFF"
    . "448B84244801000031C031C931D24585C00F8E7AF8FFFF448B8C244001000089"
    . "B424C000000089CE4C899C24E00000004C89A424200100004189C34489542408"
    . "4189D431C04585C97E45488B8C24380100004963C431D24C8D14814489D96690"
    . "418B049225FFFFFF0039C374104D63C74183C70142890C8742894485004883C2"
    . "0183C1044139D17FD74501CC4489C883C60144039C24E800000039B424480100"
    . "0075A0894424408B842450010000448B5424088BB424C00000004C8B9C24E000"
    . "00004C8BA42420010000410FAFC7C1F808898424500100008B84244801000089"
    . "4424144183FF010F8EB7F7FFFF488D47044C8D4D044489542408BB0100000049"
    . "89C2458B41FC4C89C889DA0F1F4400004889C14829E9443900752683C2014883"
    . "C0044139D77FE983C3014983C2044983C1044139DF75CB448B542408E963F7FF"
    . "FF39D374E24801F9418B1283C301448B014983C2044983C104458942FC89118B"
    . "10418B49FC418951FC4139DF894C24588908758EEBC18B8424100100008B9C24"
    . "080100000FAF84241801000083EB0148984C01E048894424088B842410010000"
    . "0384240001000089C1894424288B8424080100000384241801000039D80F8C6C"
    . "0100008B94240001000083C001448954244C89442430448B9424F00000004889"
    . "BC2428010000C74424400000000083EA0144897C244844897424504189D18954"
    . "241889DA4489C889D74889AC2430010000C1E0020FAF9C24E800000089442420"
    . "4898488944243889F02B84240001000089C6895C24148D590101CE897424448B"
    . "442418394424280F8C710300008B7424148B5424204189FE488B6C24384C6344"
    . "244041C1EE1F4C0344240801F24C63FE4863D24D8D0C134829D5EB520F1F4000"
    . "4139C27E524584F6754D39BC24F80000007E44410FB64902410FB6510183C001"
    . "4983C0016BD24B6BC92601D14A8D540D004983C104420FB6343A89F2C1E20429"
    . "F201D1C1F907418848FF39D8741C89C2C1EA1F84D274A983C00141C600004983"
    . "C1044983C00139D875E48B4C2444014C244089D883C7018B8C24E8000000014C"
    . "2414397C24300F8533FFFFFF448B7C2448448B54244C448B742450488BBC2428"
    . "010000488BAC2430010000894424408B8424100100008B9C241801000083C002"
    . "85DB0F8EA3020000488B5C2408489844897C24384889442418448B7C24588B54"
    . "24104C899C24E0000000488D440301C744240801000000C74424400000000044"
    . "895424444889C38B8424180100004989DB83C001894424144863842410010000"
    . "488D700348F7D048894424288B842410010000488974242083E8014883C00148"
    . "89442430448B8C24100100004585C90F8EFF010000488B44242048634C24404E"
    . "8D0C18488B4424284C01E14E8D0418488B4424304A8D34184C89D80F1F440000"
    . "0FB610440FB650FFBB010000004401FA4439D2724B440FB650014439D2724145"
    . "0FB650FF4439D27237450FB651FF4439D2722D450FB650FE4439D27223450FB6"
    . "104439D2721A450FB651FE4439D27210450FB6114439D20F92C3660F1F440000"
    . "4883C00188194983C1014883C1014983C0014839F075898B8424100100008BB4"
    . "24100100000174244083C00183442408018B5C24084C035C2418395C24140F85"
    . "20FFFFFF448B7C2438448B54244489442440895424104C8B9C24E0000000E958"
    . "F3FFFF8B8424100100008B54245831F6C744241400000000C1E00283C2018944"
    . "24188B842418010000C1E2078954245885C00F8E23F3FFFF44897C2440448954"
    . "24204889BC2428010000448B7C2458448B9424100100008B7C242831C04585D2"
    . "7E5348635C24144863C74531C0498D4C03024C01E30FB6110FB641FF440FB649"
    . "FE6BC04B6BD22601C24489C8C1E0044429C801D04139C7420F9704034983C001"
    . "4883C1044539C27FCC037C241844015424144489D083C601037C240839B42418"
    . "0100007596448B7C2440894424408B842418010000448B542420488BBC242801"
    . "000089442414E970F2FFFF4531ED4531F6C744241400000000E984F0FFFF8B44"
    . "2418E92DFDFFFFC744242000000000E935F5FFFFB801000000E9AEFEFFFFC744"
    . "241400000000E930F2FFFFC744241401000000E923F2FFFF9090909090909090"
    this.MCode(MyFunc, A_PtrSize=8 ? x64:x32)
  }
  num:=info.MaxIndex(), j:=info[index]
  , text:=j.1, w:=j.2, h:=j.3, len1:=j.4, len0:=j.5
  , e1:=(j.12 ? j.6 : Round(len1*err1))
  , e0:=(j.12 ? j.7 : Round(len0*err0))
  , mode:=j.8, color:=j.9, n:=j.10, comment:=j.11
  , sx:=in.sx, sy:=in.sy, sw:=in.sw, sh:=in.sh, Stride:=bits.Stride
  if (JoinText and index>1)
  {
    x:=in.x, y:=in.y, sw:=Min(x+offsetX+w,sx+sw), sx:=x, sw-=sx
    , sh:=Min(y+offsetY+h,sy+sh), sy:=Max(y-offsetY,sy), sh-=sy
  }
  if (mode=5 and n>0)
  {
    ListLines, % (lls:=A_ListLines)?"Off":"Off"
    r:=StrSplit(text,"/"), text:=0, i:=1, k:=-4
    Loop, % n
      NumPut(((v:=r[i++])>>16)*Stride+(v&0xFFFF)*4
      , s1, k+=4, "uint"), NumPut(r[i++], s0, k, "uint")
    ListLines, %lls%
  }
  else if (mode=3)
  {
    color:=(color//w)*Stride+Mod(color,w)*4
  }
  ok:=!bits.Scan0 ? 0 : DllCall(&MyFunc
    , "int",mode, "uint",color, "uint",n, "int",dir
    , "Ptr",bits.Scan0, "int",Stride, "int",in.zw, "int",in.zh
    , "int",sx, "int",sy, "int",sw, "int",sh
    , "Ptr",&ss, "Ptr",&s1, "Ptr",&s0
    , (mode=5 ? "Ptr":"AStr"),text
    , "int",w, "int",h, "int",e1, "int",e0
    , "Ptr",&allpos, "int",allpos_max)
  pos:=[]
  Loop, % ok
    pos.Push( NumGet(allpos, 8*A_Index-8, "uint")
    , NumGet(allpos, 8*A_Index-4, "uint") )
  Loop, % ok
  {
    x:=pos[2*A_Index-1], y:=pos[2*A_Index]
    if (!JoinText)
    {
      x1:=x+in.zx, y1:=y+in.zy
      , arr.Push( {1:x1, 2:y1, 3:w, 4:h
      , x:x1+w//2, y:y1+h//2, id:comment} )
    }
    else if (index=1)
    {
      in.x:=x+w, in.y:=y, in.minY:=y, in.maxY:=y+h
      Loop, % num-1
        if !this.PicFind(arr, in, info, A_Index+1, err1, err0
        , FindAll, JoinText, offsetX, offsetY, 5
        , bits, ss, s1, s0, allpos, 1)
          Continue, 2
      x1:=x+in.zx, y1:=in.minY+in.zy
      , w1:=in.x-x, h1:=in.maxY-in.minY
      , arr.Push( {1:x1, 2:y1, 3:w1, 4:h1
      , x:x1+w1//2, y:y1+h1//2, id:in.comment} )
    }
    else
    {
      in.x:=x+w, in.y:=y
      , (y<in.minY && in.minY:=y)
      , (y+h>in.maxY && in.maxY:=y+h)
      return 1
    }
    if (!FindAll and arr.MaxIndex())
      return
  }
}

GetBitsFromScreen(ByRef x, ByRef y, ByRef w, ByRef h
  , ScreenShot:=1, ByRef zx:="", ByRef zy:=""
  , ByRef zw:="", ByRef zh:="")
{
  local
  static Ptr:="Ptr"
  bits:=this.bits
  if (!ScreenShot)
  {
    zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
    if IsByRef(x)
      w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
      , h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
    return bits
  }
  bch:=A_BatchLines, cri:=A_IsCritical
  Critical
  if (id:=this.BindWindow(0,0,1))
  {
    WinGet, id, ID, ahk_id %id%
    WinGetPos, zx, zy, zw, zh, ahk_id %id%
  }
  if (!id)
  {
    SysGet, zx, 76
    SysGet, zy, 77
    SysGet, zw, 78
    SysGet, zh, 79
  }
  bits.zx:=zx, bits.zy:=zy, bits.zw:=zw, bits.zh:=zh
  , w:=Min(x+w,zx+zw), x:=Max(x,zx), w-=x
  , h:=Min(y+h,zy+zh), y:=Max(y,zy), h-=y
  if (zw>bits.oldzw or zh>bits.oldzh or !bits.hBM)
  {
    hBM:=bits.hBM
    , bits.hBM:=this.CreateDIBSection(zw, zh, bpp:=32, ppvBits)
    , bits.Scan0:=(!bits.hBM ? 0:ppvBits)
    , bits.Stride:=((zw*bpp+31)//32)*4
    , bits.oldzw:=zw, bits.oldzh:=zh
    , DllCall("DeleteObject", Ptr,hBM)
  }
  if (bits.hBM) and !(w<1 or h<1)
  {
    mDC:=DllCall("CreateCompatibleDC", Ptr,0, Ptr)
    oBM:=DllCall("SelectObject", Ptr,mDC, Ptr,bits.hBM, Ptr)
    if (id)
    {
      if (mode:=this.BindWindow(0,0,0,1))<2
      {
        hDC2:=DllCall("GetDCEx", Ptr,id, Ptr,0, "int",3, Ptr)
        DllCall("BitBlt",Ptr,mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
        , Ptr,hDC2, "int",x-zx, "int",y-zy, "uint",0xCC0020|0x40000000)
        DllCall("ReleaseDC", Ptr,id, Ptr,hDC2)
      }
      else
      {
        hBM2:=this.CreateDIBSection(zw, zh)
        mDC2:=DllCall("CreateCompatibleDC", Ptr,0, Ptr)
        oBM2:=DllCall("SelectObject", Ptr,mDC2, Ptr,hBM2, Ptr)
        DllCall("PrintWindow", Ptr,id, Ptr,mDC2, "uint",(mode>3)*3)
        DllCall("BitBlt",Ptr,mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
        , Ptr,mDC2, "int",x-zx, "int",y-zy, "uint",0xCC0020|0x40000000)
        DllCall("SelectObject", Ptr,mDC2, Ptr,oBM2)
        DllCall("DeleteDC", Ptr,mDC2)
        DllCall("DeleteObject", Ptr,hBM2)
      }
    }
    else if IsFunc(k:="GetBitsFromScreen2")
    {
      bits.mDC:=mDC, %k%(bits, x-zx, y-zy, w, h)
      , zx:=bits.zx, zy:=bits.zy, zw:=bits.zw, zh:=bits.zh
    }
    else
    {
      win:=DllCall("GetDesktopWindow", Ptr)
      hDC:=DllCall("GetWindowDC", Ptr,win, Ptr)
      DllCall("BitBlt",Ptr,mDC,"int",x-zx,"int",y-zy,"int",w,"int",h
      , Ptr,hDC, "int",x, "int",y, "uint",0xCC0020|0x40000000)
      DllCall("ReleaseDC", Ptr,win, Ptr,hDC)
    }
    if this.CaptureCursor(0,0,0,0,0,1)
      this.CaptureCursor(mDC, zx, zy, zw, zh)
    DllCall("SelectObject", Ptr,mDC, Ptr,oBM)
    DllCall("DeleteDC", Ptr,mDC)
  }
  Critical, %cri%
  SetBatchLines, %bch%
  return bits
}

CreateDIBSection(w, h, bpp:=32, ByRef ppvBits:=0, ByRef bi:="")
{
  local
  VarSetCapacity(bi, 40, 0), NumPut(40, bi, 0, "int")
  , NumPut(w, bi, 4, "int"), NumPut(-h, bi, 8, "int")
  , NumPut(1, bi, 12, "short"), NumPut(bpp, bi, 14, "short")
  return DllCall("CreateDIBSection", "Ptr",0, "Ptr",&bi
    , "int",0, "Ptr*",ppvBits:=0, "Ptr",0, "int",0, "Ptr")
}

PicInfo(text)
{
  local
  static info:=[]
  if !InStr(text,"$")
    return
  key:=(r:=StrLen(text))<1000 ? text
    : DllCall("ntdll\RtlComputeCrc32", "uint",0
    , "Ptr",&text, "uint",r*(1+!!A_IsUnicode), "uint")
  if (info[key])
    return info[key]
  v:=text, comment:="", seterr:=e1:=e0:=len1:=len0:=0
  ; You Can Add Comment Text within The <>
  if RegExMatch(v,"<([^>]*)>",r)
    v:=StrReplace(v,r), comment:=Trim(r1)
  ; You can Add two fault-tolerant in the [], separated by commas
  if RegExMatch(v,"\[([^\]]*)]",r)
  {
    v:=StrReplace(v,r), r:=StrSplit(r1, ",")
    , seterr:=1, e1:=r.1, e0:=r.2
  }
  color:=StrSplit(v,"$").1, v:=Trim(SubStr(v,InStr(v,"$")+1))
  mode:=InStr(color,"##") ? 5
    : InStr(color,"-") ? 4 : InStr(color,"#") ? 3
    : InStr(color,"**") ? 2 : InStr(color,"*") ? 1 : 0
  color:=RegExReplace(color, "[*#\s]")
  if (mode=5) and (v~="[^\s\w/]") and FileExist(v)
  {
    if !IsObject(r:=info["file:" v])
    {
      if !(hBM:=LoadPicture(v))
        return
      VarSetCapacity(bm, size:=(A_PtrSize=8 ? 32:24), 0)
      DllCall("GetObject","Ptr",hBM,"int",size,"Ptr",&bm)
      w:=NumGet(bm,4,"int"), h:=Abs(NumGet(bm,8,"int"))
      hBM2:=this.CreateDIBSection(w, h, 32, ppvBits)
      this.CopyHBM(hBM2, 0, 0, hBM, 0, 0, w, h)
      DllCall("DeleteObject", "Ptr",hBM)
      if (w<1 or h<1 or !ppvBits)
        return
      info["file:" v]:=r:=[ppvBits, w, h]
    }
    v:=r.1, w:=r.2, h:=r.3, n:=0, len1:=1<<8
  }
  else if (mode=5)
  {
    v:=Trim(StrReplace(RegExReplace(v,"\s"),",","/"),"/")
    r:=StrSplit(v,"/"), n:=r.MaxIndex()//3
    if (!n)
      return
    v:="", x1:=x2:=r.1, y1:=y2:=r.2, i:=j:=-2
    ListLines, % (lls:=A_ListLines)?"Off":"Off"
    Loop, % n
      x:=r[i+=3], y:=r[i+1]
      , (x<x1 && x1:=x), (x>x2 && x2:=x)
      , (y<y1 && y1:=y), (y>y2 && y2:=y)
    Loop, % n
      v.="/" (r[j+=3]-x1)|((r[j+1]-y1)<<16)
      . "/0x" . StrReplace(r[j+2],"0x")
    ListLines, %lls%
    v:=SubStr(v,2), w:=x2-x1+1, h:=y2-y1+1, len1:=n
  }
  else
  {
    r:=StrSplit(v,"."), w:=r.1
    , v:=this.base64tobit(r.2), h:=StrLen(v)//w
    if (w<1 or h<1 or StrLen(v)!=w*h)
      return
    if (mode=4)
    {
      r:=StrSplit(StrReplace(color,"0x"),"-")
      , color:=Round("0x" r.1), n:=Round("0x" r.2)
    }
    else
    {
      r:=StrSplit(color,"@")
      , color:=r.1, n:=Round(r.2,2)+(!r.2)
      , n:=Floor(512*9*255*255*(1-n)*(1-n))
    }
    StrReplace(v,"1","",len1), len0:=StrLen(v)-len1
  }
  e1:=Floor(len1*e1), e0:=Floor(len0*e0)
  return info[key]:=[v, w, h, len1, len0, e1, e0
    , mode, color, n, comment, seterr]
}

CopyHBM(hBM1, x1, y1, hBM2, x2, y2, w2, h2)
{
  local
  static Ptr:="Ptr"
  mDC1:=DllCall("CreateCompatibleDC", Ptr,0, Ptr)
  oBM1:=DllCall("SelectObject", Ptr,mDC1, Ptr,hBM1, Ptr)
  mDC2:=DllCall("CreateCompatibleDC", Ptr,0, Ptr)
  oBM2:=DllCall("SelectObject", Ptr,mDC2, Ptr,hBM2, Ptr)
  DllCall("BitBlt", Ptr,mDC1
  , "int",x1, "int",y1, "int",w2, "int",h2
  , Ptr,mDC2, "int",x2, "int",y2, "uint",0xCC0020)
  DllCall("SelectObject", Ptr,mDC2, Ptr,oBM2)
  DllCall("DeleteDC", Ptr,mDC2)
  DllCall("SelectObject", Ptr,mDC1, Ptr,oBM1)
  DllCall("DeleteDC", Ptr,mDC1)
}

CopyBits(Scan01,Stride1,x1,y1,Scan02,Stride2,x2,y2,w2,h2)
{
  local
  ListLines, % (lls:=A_ListLines)?"Off":"Off"
    p1:=Scan01+(y1-1)*Stride1+x1*4
  , p2:=Scan02+(y2-1)*Stride2+x2*4, w2*=4
  Loop, % h2
    DllCall("RtlMoveMemory", "Ptr",p1+=Stride1
    , "Ptr",p2+=Stride2, "Ptr",w2)
  ListLines, %lls%
}

; Bind the window so that it can find images when obscured
; by other windows, it's equivalent to always being
; at the front desk. Unbind Window using FindText.BindWindow(0)

BindWindow(bind_id:=0, bind_mode:=0, get_id:=0, get_mode:=0)
{
  local
  bind:=this.bind
  if (get_id)
    return bind.id
  if (get_mode)
    return bind.mode
  if (bind_id)
  {
    bind.id:=bind_id, bind.mode:=bind_mode, bind.oldStyle:=0
    if (bind_mode & 1)
    {
      WinGet, oldStyle, ExStyle, ahk_id %bind_id%
      bind.oldStyle:=oldStyle
      WinSet, Transparent, 255, ahk_id %bind_id%
      Loop, 30
      {
        Sleep, 100
        WinGet, i, Transparent, ahk_id %bind_id%
      }
      Until (i=255)
    }
  }
  else
  {
    bind_id:=bind.id
    if (bind.mode & 1)
      WinSet, ExStyle, % bind.oldStyle, ahk_id %bind_id%
    bind.id:=0, bind.mode:=0, bind.oldStyle:=0
  }
}

; Use FindText.CaptureCursor(1) to Capture Cursor
; Use FindText.CaptureCursor(0) to Cancel Capture Cursor

CaptureCursor(hDC:=0, zx:=0, zy:=0, zw:=0, zh:=0, get_cursor:=0)
{
  local
  if (get_cursor)
    return this.Cursor
  if (hDC=1 or hDC=0) and (zw=0)
  {
    this.Cursor:=hDC
    return
  }
  Ptr:=(A_PtrSize ? "Ptr":"UInt"), PtrSize:=(A_PtrSize=8 ? 8:4)
  VarSetCapacity(mi, 40, 0), NumPut(16+PtrSize, mi, "int")
  DllCall("GetCursorInfo", Ptr,&mi)
  bShow   := NumGet(mi, 4, "int")
  hCursor := NumGet(mi, 8, Ptr)
  x := NumGet(mi, 8+PtrSize, "int")
  y := NumGet(mi, 12+PtrSize, "int")
  if (!bShow) or (x<zx or y<zy or x>=zx+zw or y>=zy+zh)
    return
  VarSetCapacity(ni, 40, 0)
  DllCall("GetIconInfo", Ptr,hCursor, Ptr,&ni)
  xCenter  := NumGet(ni, 4, "int")
  yCenter  := NumGet(ni, 8, "int")
  hBMMask  := NumGet(ni, (PtrSize=8?16:12), Ptr)
  hBMColor := NumGet(ni, (PtrSize=8?24:16), Ptr)
  DllCall("DrawIconEx", Ptr,hDC
    , "int",x-xCenter-zx, "int",y-yCenter-zy, Ptr,hCursor
    , "int",0, "int",0, "int",0, "int",0, "int",3)
  DllCall("DeleteObject", Ptr,hBMMask)
  DllCall("DeleteObject", Ptr,hBMColor)
}

MCode(ByRef code, hex)
{
  local
  ListLines, % (lls:=A_ListLines)?"Off":"Off"
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  VarSetCapacity(code, len:=StrLen(hex)//2)
  Loop, % len
    NumPut("0x" SubStr(hex,2*A_Index-1,2),code,A_Index-1,"uchar")
  DllCall("VirtualProtect","Ptr",&code,"Ptr",len,"uint",0x40,"Ptr*",0)
  SetBatchLines, %bch%
  ListLines, %lls%
}

base64tobit(s)
{
  local
  Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    . "abcdefghijklmnopqrstuvwxyz"
  ListLines, % (lls:=A_ListLines)?"Off":"Off"
  Loop, Parse, Chars
  {
    i:=A_Index-1, v:=(i>>5&1) . (i>>4&1)
      . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1)
    s:=RegExReplace(s,"[" A_LoopField "]",StrReplace(v,"0x"))
  }
  ListLines, %lls%
  return RegExReplace(RegExReplace(s,"10*$"),"[^01]+")
}

bit2base64(s)
{
  local
  s:=RegExReplace(s,"[^01]+")
  s.=SubStr("100000",1,6-Mod(StrLen(s),6))
  s:=RegExReplace(s,".{6}","|$0")
  Chars:="0123456789+/ABCDEFGHIJKLMNOPQRSTUVWXYZ"
    . "abcdefghijklmnopqrstuvwxyz"
  ListLines, % (lls:=A_ListLines)?"Off":"Off"
  Loop, Parse, Chars
  {
    i:=A_Index-1, v:="|" . (i>>5&1) . (i>>4&1)
      . (i>>3&1) . (i>>2&1) . (i>>1&1) . (i&1)
    s:=StrReplace(s,StrReplace(v,"0x"),A_LoopField)
  }
  ListLines, %lls%
  return s
}

xywh2xywh(x1,y1,w1,h1, ByRef x, ByRef y, ByRef w, ByRef h
  , ByRef zx:="", ByRef zy:="", ByRef zw:="", ByRef zh:="")
{
  local
  SysGet, zx, 76
  SysGet, zy, 77
  SysGet, zw, 78
  SysGet, zh, 79
  w:=Min(x1+w1,zx+zw), x:=Max(x1,zx), w-=x
  , h:=Min(y1+h1,zy+zh), y:=Max(y1,zy), h-=y
}

ASCII(s)
{
  local
  if RegExMatch(s,"\$(\d+)\.([\w+/]+)",r)
  {
    s:=RegExReplace(this.base64tobit(r2),".{" r1 "}","$0`n")
    s:=StrReplace(StrReplace(s,"0","_"),"1","0")
  }
  else s=
  return s
}

; You can put the text library at the beginning of the script,
; and Use FindText.PicLib(Text,1) to add the text library to PicLib()'s Lib,
; Use FindText.PicLib("comment1|comment2|...") to get text images from Lib

PicLib(comments, add_to_Lib:=0, index:=1)
{
  local
  Lib:=this.Lib
  if (add_to_Lib)
  {
    re:="<([^>]*)>[^$]+\$\d+\.[\w+/]+"
    Loop, Parse, comments, |
      if RegExMatch(A_LoopField,re,r)
      {
        s1:=Trim(r1), s2:=""
        Loop, Parse, s1
          s2.="_" . Format("{:d}",Ord(A_LoopField))
        Lib[index,s2]:=r
      }
    Lib[index,""]:=""
  }
  else
  {
    Text:=""
    Loop, Parse, comments, |
    {
      s1:=Trim(A_LoopField), s2:=""
      Loop, Parse, s1
        s2.="_" . Format("{:d}",Ord(A_LoopField))
      Text.="|" . Lib[index,s2]
    }
    return Text
  }
}

; Decompose a string into individual characters and get their data

PicN(Number, index:=1)
{
  return this.PicLib(RegExReplace(Number,".","|$0"), 0, index)
}

; Use FindText.PicX(Text) to automatically cut into multiple characters
; Can't be used in ColorPos mode, because it can cause position errors

PicX(Text)
{
  local
  if !RegExMatch(Text,"(<[^$]+)\$(\d+)\.([\w+/]+)",r)
    return Text
  v:=this.base64tobit(r3), Text:=""
  c:=StrLen(StrReplace(v,"0"))<=StrLen(v)//2 ? "1":"0"
  txt:=RegExReplace(v,".{" r2 "}","$0`n")
  While InStr(txt,c)
  {
    While !(txt~="m`n)^" c)
      txt:=RegExReplace(txt,"m`n)^.")
    i:=0
    While (txt~="m`n)^.{" i "}" c)
      i:=Format("{:d}",i+1)
    v:=RegExReplace(txt,"m`n)^(.{" i "}).*","$1")
    txt:=RegExReplace(txt,"m`n)^.{" i "}")
    if (v!="")
      Text.="|" r1 "$" i "." this.bit2base64(v)
  }
  return Text
}

; Screenshot and retained as the last screenshot.

ScreenShot(x1:=0, y1:=0, x2:=0, y2:=0)
{
  this.FindText(x1, y1, x2, y2)
}

; Get the RGB color of a point from the last screenshot.
; If the point to get the color is beyond the range of
; Screen, it will return White color (0xFFFFFF).

GetColor(x, y, fmt:=1)
{
  local
  bits:=this.GetBitsFromScreen(0,0,0,0,0,zx,zy,zw,zh)
  , c:=(x<zx or x>=zx+zw or y<zy or y>=zy+zh or !bits.Scan0)
  ? 0xFFFFFF : NumGet(bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4,"uint")
  return (fmt ? Format("0x{:06X}",c&0xFFFFFF) : c)
}

; Set the RGB color of a point in the last screenshot

SetColor(x, y, color:=0x000000)
{
  local
  bits:=this.GetBitsFromScreen(0,0,0,0,0,zx,zy,zw,zh)
  if !(x<zx or x>=zx+zw or y<zy or y>=zy+zh or !bits.Scan0)
    NumPut(color,bits.Scan0+(y-zy)*bits.Stride+(x-zx)*4,"uint")
}

; Identify a line of text or verification code
; based on the result returned by FindText().
; offsetX is the maximum interval between two texts,
; if it exceeds, a "*" sign will be inserted.
; offsetY is the maximum height difference between two texts.
; Return Association array {text:Text, x:X, y:Y, w:W, h:H}

Ocr(ok, offsetX:=20, offsetY:=20)
{
  local
  ocr_Text:=ocr_X:=ocr_Y:=min_X:=dx:=""
  For k,v in ok
    x:=v.1
    , min_X:=(A_Index=1 or x<min_X ? x : min_X)
    , max_X:=(A_Index=1 or x>max_X ? x : max_X)
  While (min_X!="" and min_X<=max_X)
  {
    LeftX:=""
    For k,v in ok
    {
      x:=v.1, y:=v.2
      if (x<min_X) or Abs(y-ocr_Y)>offsetY
        Continue
      ; Get the leftmost X coordinates
      if (LeftX="" or x<LeftX)
        LeftX:=x, LeftY:=y, LeftW:=v.3, LeftH:=v.4, LeftOCR:=v.id
    }
    if (LeftX="")
      Break
    if (ocr_X="")
      ocr_X:=LeftX, min_Y:=LeftY, max_Y:=LeftY+LeftH
    ; If the interval exceeds the set value, add "*" to the result
    ocr_Text.=(ocr_Text!="" and LeftX>dx ? "*":"") . LeftOCR
    ; Update for next search
    min_X:=LeftX+LeftW-LeftW//2, dx:=LeftX+LeftW+offsetX
    , ocr_Y:=LeftY, (LeftY<min_Y && min_Y:=LeftY)
    , (LeftY+LeftH>max_Y && max_Y:=LeftY+LeftH)
  }
  return {text:ocr_Text, x:ocr_X, y:min_Y
    , w: min_X-ocr_X, h: max_Y-min_Y}
}

; Sort the results returned by FindText() from left to right
; and top to bottom, ignore slight height difference

Sort(ok, dy:=10)
{
  local
  if !IsObject(ok)
    return ok
  ypos:=[]
  For k,v in ok
  {
    x:=v.x, y:=v.y, add:=1
    For k2,v2 in ypos
      if Abs(y-v2)<=dy
      {
        y:=v2, add:=0
        Break
      }
    if (add)
      ypos.Push(y)
    n:=(y*150000+x) "." k, s:=A_Index=1 ? n : s "-" n
  }
  Sort, s, N D-
  ok2:=[]
  Loop, Parse, s, -
    ok2.Push( ok[(StrSplit(A_LoopField,".")[2])] )
  return ok2
}

; Reordering according to the nearest distance

Sort2(ok, px, py)
{
  local
  if !IsObject(ok)
    return ok
  For k,v in ok
    n:=((v.x-px)**2+(v.y-py)**2) "." k, s:=A_Index=1 ? n : s "-" n
  Sort, s, N D-
  ok2:=[]
  Loop, Parse, s, -
    ok2.Push( ok[(StrSplit(A_LoopField,".")[2])] )
  return ok2
}

; Prompt mouse position in remote assistance

MouseTip(x:="", y:="", w:=10, h:=10, d:=4)
{
  local
  if (x="")
  {
    VarSetCapacity(pt,16,0), DllCall("GetCursorPos","ptr",&pt)
    x:=NumGet(pt,0,"uint"), y:=NumGet(pt,4,"uint")
  }
  x:=Round(x-w-d), y:=Round(y-h-d), w:=(2*w+1)+2*d, h:=(2*h+1)+2*d
  ;-------------------------
  Gui, _MouseTip_: +AlwaysOnTop -Caption +ToolWindow +Hwndmyid -DPIScale
  Gui, _MouseTip_: Show, Hide w%w% h%h%
  ;-------------------------
  DetectHiddenWindows, % (dhw:=A_DetectHiddenWindows)?"On":"On"
  i:=w-d, j:=h-d
  s=0-0 %w%-0 %w%-%h% 0-%h% 0-0  %d%-%d% %i%-%d% %i%-%j% %d%-%j% %d%-%d%
  WinSet, Region, %s%, ahk_id %myid%
  DetectHiddenWindows, %dhw%
  ;-------------------------
  Gui, _MouseTip_: Show, NA x%x% y%y%
  Loop, 4
  {
    Gui, _MouseTip_: Color, % A_Index & 1 ? "Red" : "Blue"
    Sleep, 500
  }
  Gui, _MouseTip_: Destroy
}

; Quickly get the search data of screen image

GetTextFromScreen(x1, y1, x2, y2, Threshold:=""
  , ScreenShot:=1, ByRef rx:="", ByRef ry:="")
{
  local
  SetBatchLines, % (bch:=A_BatchLines)?"-1":"-1"
  x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
  if (w<1 or h<1)
  {
    SetBatchLines, %bch%
    return
  }
  ListLines, % (lls:=A_ListLines)?"Off":"Off"
  gs:=[], k:=0
  Loop, %h%
  {
    j:=y+A_Index-1
    Loop, %w%
      i:=x+A_Index-1, c:=this.GetColor(i,j,0)
      , gs[++k]:=(((c>>16)&0xFF)*38+((c>>8)&0xFF)*75+(c&0xFF)*15)>>7
  }
  if InStr(Threshold,"**")
  {
    Threshold:=StrReplace(Threshold,"*")
    if (Threshold="")
      Threshold:=50
    s:="", sw:=w, w-=2, h-=2, x++, y++
    Loop, %h%
    {
      y1:=A_Index
      Loop, %w%
        x1:=A_Index, i:=y1*sw+x1+1, j:=gs[i]+Threshold
        , s.=( gs[i-1]>j || gs[i+1]>j
        || gs[i-sw]>j || gs[i+sw]>j
        || gs[i-sw-1]>j || gs[i-sw+1]>j
        || gs[i+sw-1]>j || gs[i+sw+1]>j ) ? "1":"0"
    }
    Threshold:="**" Threshold
  }
  else
  {
    Threshold:=StrReplace(Threshold,"*")
    if (Threshold="")
    {
      pp:=[]
      Loop, 256
        pp[A_Index-1]:=0
      Loop, % w*h
        pp[gs[A_Index]]++
      IP:=IS:=0
      Loop, 256
        k:=A_Index-1, IP+=k*pp[k], IS+=pp[k]
      Threshold:=Floor(IP/IS)
      Loop, 20
      {
        LastThreshold:=Threshold
        IP1:=IS1:=0
        Loop, % LastThreshold+1
          k:=A_Index-1, IP1+=k*pp[k], IS1+=pp[k]
        IP2:=IP-IP1, IS2:=IS-IS1
        if (IS1!=0 and IS2!=0)
          Threshold:=Floor((IP1/IS1+IP2/IS2)/2)
        if (Threshold=LastThreshold)
          Break
      }
    }
    s:=""
    Loop, % w*h
      s.=gs[A_Index]<=Threshold ? "1":"0"
    Threshold:="*" Threshold
  }
  ;--------------------
  w:=Format("{:d}",w), CutUp:=CutDown:=0
  re1=(^0{%w%}|^1{%w%})
  re2=(0{%w%}$|1{%w%}$)
  While RegExMatch(s,re1)
    s:=RegExReplace(s,re1), CutUp++
  While RegExMatch(s,re2)
    s:=RegExReplace(s,re2), CutDown++
  rx:=x+w//2, ry:=y+CutUp+(h-CutUp-CutDown)//2
  s:="|<>" Threshold "$" w "." this.bit2base64(s)
  ;--------------------
  SetBatchLines, %bch%
  ListLines, %lls%
  return s
}

; Quickly save screen image to BMP file for debugging

SavePic(file, x1:=0, y1:=0, x2:=0, y2:=0, ScreenShot:=1)
{
  local
  static Ptr:="Ptr"
  if (x1*x1+y1*y1+x2*x2+y2*y2<=0)
    n:=150000, x:=y:=-n, w:=h:=2*n
  else
    x:=Min(x1,x2), y:=Min(y1,y2), w:=Abs(x2-x1)+1, h:=Abs(y2-y1)+1
  bits:=this.GetBitsFromScreen(x,y,w,h,ScreenShot,zx,zy,zw,zh)
  if (w<1 or h<1 or !bits.hBM)
    return
  hBM:=this.CreateDIBSection(w, h, bpp:=24, ppvBits, bi)
  this.CopyHBM(hBM, 0, 0, bits.hBM, x-zx, y-zy, w, h)
  size:=((w*bpp+31)//32)*4*h, NumPut(size, bi, 20, "uint")
  VarSetCapacity(bf, 14, 0), StrPut("BM", &bf, "CP0")
  NumPut(54+size, bf, 2, "uint"), NumPut(54, bf, 10, "uint")
  f:=FileOpen(file,"w"), f.RawWrite(bf,14), f.RawWrite(bi,40)
  , f.RawWrite(ppvBits+0, size), f.Close()
  DllCall("DeleteObject", Ptr,hBM)
}

; Show the saved BMP file

ShowPic(file:="", show:=1)
{
  local
  static Ptr:="Ptr"
  Gui, FindText_Screen: Destroy
  if (file="") or !FileExist(file)
    return
  bits:=this.GetBitsFromScreen(0,0,0,0,1,zx,zy,zw,zh)
  hBM:=bits.hBM, hBM2:=LoadPicture(file)
  this.CopyHBM(hBM, 0, 0, hBM2, 0, 0, zw, zh)
  DllCall("DeleteObject", Ptr,hBM2)
  if (!show)
    return
  Gui, FindText_Screen: +AlwaysOnTop -Caption +ToolWindow -DPIScale +E0x08000000
  Gui, FindText_Screen: Margin, 0, 0
  Gui, FindText_Screen: Add, Pic,, HBITMAP:*%hBM%
  Gui, FindText_Screen: Show, NA x%zx% y%zy% w%zw% h%zh%, Show Pic
}

; Running AHK code dynamically with new threads

Class Thread
{
  __New(args*)
  {
    this.pid:=this.Exec(args*)
  }
  __Delete()
  {
    Process, Close, % this.pid
  }
  Exec(s, Ahk:="", args:="")
  {
    local
    Ahk:=Ahk ? Ahk:A_IsCompiled ? A_ScriptDir "\AutoHotkey.exe":A_AhkPath
    s:="DllCall(""SetWindowText"",""Ptr"",A_ScriptHwnd,""Str"",""<AHK>"")`n"
      . StrReplace(s,"`r"), pid:=""
    Try
    {
      shell:=ComObjCreate("WScript.Shell")
      oExec:=shell.Exec("""" Ahk """ /f * " args)
      oExec.StdIn.Write(s)
      oExec.StdIn.Close(), pid:=oExec.ProcessID
    }
    Catch
    {
      f:=A_Temp "\~ahk.tmp"
      s:="`n FileDelete, " f "`n" s
      FileDelete, %f%
      FileAppend, %s%, %f%
      r:=ObjBindMethod(this, "Clear")
      SetTimer, %r%, -3000
      Run, "%Ahk%" /f "%f%" %args%,, UseErrorLevel, pid
    }
    return pid
  }
  Clear()
  {
    FileDelete, % A_Temp "\~ahk.tmp"
    SetTimer,, Off
  }
}

WindowToScreen(ByRef x, ByRef y, x1, y1, id:="")
{
  local
  WinGetPos, winx, winy,,, % id ? "ahk_id " id : "A"
  x:=x1+Floor(winx), y:=y1+Floor(winy)
}

ScreenToWindow(ByRef x, ByRef y, x1, y1, id:="")
{
  local
  this.WindowToScreen(dx,dy,0,0,id), x:=x1-dx, y:=y1-dy
}

ClientToScreen(ByRef x, ByRef y, x1, y1, id:="")
{
  local
  if (!id)
    WinGet, id, ID, A
  VarSetCapacity(pt,8,0), NumPut(0,pt,"int64")
  , DllCall("ClientToScreen","Ptr",id,"Ptr",&pt)
  , x:=x1+NumGet(pt,"int"), y:=y1+NumGet(pt,4,"int")
}

ScreenToClient(ByRef x, ByRef y, x1, y1, id:="")
{
  local
  this.ClientToScreen(dx,dy,0,0,id), x:=x1-dx, y:=y1-dy
}

QPC()  ; <==> A_TickCount
{
  local
  static c:=0, f:=0, init:=DllCall("QueryPerformanceFrequency", "Int*",f)
  return (!DllCall("QueryPerformanceCounter","Int64*",c))*0+(c/f)*1000
}

; It is not like FindText always use Screen Coordinates,
; But like built-in command ImageSearch using CoordMode Settings

ImageSearch(ByRef rx, ByRef ry, x1, y1, x2, y2, text
  , ScreenShot:=1, FindAll:=0)
{
  local
  dx:=dy:=0
  if (A_CoordModePixel="Window")
    this.WindowToScreen(dx,dy,0,0)
  else if (A_CoordModePixel="Client")
    this.ClientToScreen(dx,dy,0,0)
  if (ok:=this.FindText(x1+dx, y1+dy, x2+dx, y2+dy
    , 0, 0, text, ScreenShot, FindAll))
  {
    rx:=ok.1.x-dx, ry:=ok.1.y-dy, ErrorLevel:=0
    return 1
  }
  else
  {
    rx:=ry:="", ErrorLevel:=1
    return 0
  }
}


/***** C source code of machine code *****

int __attribute__((__stdcall__)) PicFind(
  int mode, unsigned int c, unsigned int n, int dir
  , unsigned char * Bmp, int Stride, int zw, int zh
  , int sx, int sy, int sw, int sh
  , char * ss, unsigned int * s1, unsigned int * s0
  , char * text, int w, int h, int err1, int err0
  , unsigned int * allpos, int allpos_max )
{
  int ok=0, o, i, j, k, v, r, g, b, rr, gg, bb;
  int x, y, x1, y1, x2, y2, len1, len0, e1, e0, max;
  int r_min, r_max, g_min, g_max, b_min, b_max, x3, y3;
  unsigned char * gs;
  unsigned int * Bmp2;
  //----------------------
  // MultiColor or PixelSearch or ImageSearch Mode
  if (mode==5)
  {
    max=n; v=c;
    if (max==0)  // ImageSearch
    {
      o=0; Bmp2=(unsigned int *)text;
      i=Bmp2[0]&0xFFFFFF; j=Bmp2[w-1]&0xFFFFFF;
      k=Bmp2[w*h-w]&0xFFFFFF; r=Bmp2[w*h-1]&0xFFFFFF;
      if (i!=j || i!=k || i!=r) i=-1;
      for (y=0; y<h; y++)
      {
        for (x=0; x<w; x++)
        {
          j=Bmp2[o++]&0xFFFFFF;
          if (j!=i) { s1[max]=y*Stride+x*4; s0[max++]=j; }
        }
      }
      err1=(err1*max)>>8;
    }
    for (i=1; i<max; i++)
    {
      for (j=i; j<max; j++)
        if (s0[j]!=s0[i-1])
        {
          if (j==i) break;
          c=s1[i]; s1[i]=s1[j]; s1[j]=c;
          c=s0[i]; s0[i]=s0[j]; s0[j]=c; break;
        }
    }
    goto StartLookUp;
  }
  //----------------------
  // Generate Lookup Table
  o=0; len1=0; len0=0;
  for (y=0; y<h; y++)
  {
    for (x=0; x<w; x++)
    {
      i=(mode==3) ? y*Stride+x*4 : y*sw+x;
      if (text[o++]=='1')
        s1[len1++]=i;
      else
        s0[len0++]=i;
    }
  }
  if (err1>=len1) len1=0;
  if (err0>=len0) len0=0;
  max=(len1>len0) ? len1 : len0;
  //----------------------
  // Color Position Mode
  // only used to recognize multicolored Verification Code
  if (mode==3) goto StartLookUp;
  //----------------------
  // Generate Two Value Image
  o=sy*Stride+sx*4; j=Stride-sw*4; i=0;
  if (mode==0)  // Color Mode
  {
    rr=(c>>16)&0xFF; gg=(c>>8)&0xFF; bb=c&0xFF;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]-rr; g=Bmp[1+o]-gg; b=Bmp[o]-bb; v=r+rr+rr;
        ss[i]=((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n) ? 1:0;
      }
  }
  else if (mode==1)  // Gray Threshold Mode
  {
    c=(c+1)<<7;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
        ss[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15<c) ? 1:0;
  }
  else if (mode==2)  // Gray Difference Mode
  {
    gs=(unsigned char *)(ss+sw*sh);
    x2=sx+sw; y2=sy+sh;
    for (y=sy-1; y<=y2; y++)
    {
      for (x=sx-1; x<=x2; x++, i++)
        if (x<0 || x>=zw || y<0 || y>=zh)
          gs[i]=0;
        else
        {
          o=y*Stride+x*4;
          gs[i]=(Bmp[2+o]*38+Bmp[1+o]*75+Bmp[o]*15)>>7;
        }
    }
    k=sw+2; i=0;
    for (y=1; y<=sh; y++)
      for (x=1; x<=sw; x++, i++)
      {
        o=y*k+x; n=gs[o]+c;
        ss[i]=(gs[o-1]>n || gs[o+1]>n
          || gs[o-k]>n   || gs[o+k]>n
          || gs[o-k-1]>n || gs[o-k+1]>n
          || gs[o+k-1]>n || gs[o+k+1]>n) ? 1:0;
      }
  }
  else  // (mode==4) Color Difference Mode
  {
    r=(c>>16)&0xFF; g=(c>>8)&0xFF; b=c&0xFF;
    rr=(n>>16)&0xFF; gg=(n>>8)&0xFF; bb=n&0xFF;
    r_min=r-rr; g_min=g-gg; b_min=b-bb;
    r_max=r+rr; g_max=g+gg; b_max=b+bb;
    for (y=0; y<sh; y++, o+=j)
      for (x=0; x<sw; x++, o+=4, i++)
      {
        r=Bmp[2+o]; g=Bmp[1+o]; b=Bmp[o];
        ss[i]=(r>=r_min && r<=r_max
            && g>=g_min && g<=g_max
            && b>=b_min && b<=b_max) ? 1:0;
      }
  }
  //----------------------
  StartLookUp:
  if (mode==5 || mode==3)
    { x1=sx; y1=sy; x2=sx+sw-w; y2=sy+sh-h; k=0; }
  else
    { x1=0; y1=0; x2=sw-w; y2=sh-h; k=1; }
  if (dir<1 || dir>8) dir=1;
  // 1 ==> Top to Bottom ( Left to Right )
  // 2 ==> Top to Bottom ( Right to Left )
  // 3 ==> Bottom to Top ( Left to Right )
  // 4 ==> Bottom to Top ( Right to Left )
  // 5 ==> Left to Right ( Top to Bottom )
  // 6 ==> Left to Right ( Bottom to Top )
  // 7 ==> Right to Left ( Top to Bottom )
  // 8 ==> Right to Left ( Bottom to Top )
  if (dir>4) { i=x1; j=x2; x1=y1; x2=y2; y1=i; y2=j; }
  for (y3=y1; y3<=y2; y3++)
  {
    i=((dir-1)&3>1) ? y1+y2-y3 : y3;
    if (dir>4) {x=i;} else {y=i;}
    for (x3=x1; x3<=x2; x3++)
    {
      i=(dir&1==0) ? x1+x2-x3 : x3;
      if (dir>4) {y=i;} else {x=i;}
      //----------------------
      if (mode==5)
      {
        o=y*Stride+x*4; e1=err1;
        for (i=0; i<max; i++)
        {
          j=o+s1[i]; c=s0[i]; r=Bmp[2+j]-((c>>16)&0xFF);
          g=Bmp[1+j]-((c>>8)&0xFF); b=Bmp[j]-(c&0xFF);
          if ((r>v||r<-v||g>v||g<-v||b>v||b<-v) && (--e1)<0)
            goto NoMatch;
        }
      }
      else if (mode==3)
      {
        o=y*Stride+x*4; e1=err1; e0=err0;
        j=o+c; rr=Bmp[2+j]; gg=Bmp[1+j]; bb=Bmp[j];
        for (i=0; i<max; i++)
        {
          if (i<len1)
          {
            j=o+s1[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
            if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b>n && (--e1)<0)
              goto NoMatch;
          }
          if (i<len0)
          {
            j=o+s0[i]; r=Bmp[2+j]-rr; g=Bmp[1+j]-gg; b=Bmp[j]-bb; v=r+rr+rr;
            if ((1024+v)*r*r+2048*g*g+(1534-v)*b*b<=n && (--e0)<0)
              goto NoMatch;
          }
        }
      }
      else
      {
        o=y*sw+x; e1=err1; e0=err0;
        for (i=0; i<max; i++)
        {
          if (i<len1 && ss[o+s1[i]]==0 && (--e1)<0) goto NoMatch;
          if (i<len0 && ss[o+s0[i]]!=0 && (--e0)<0) goto NoMatch;
        }
        // Clear the image that has been found
        for (i=0; i<len1; i++)
          ss[o+s1[i]]=0;
      }
      allpos[ok*2]=k*sx+x; allpos[ok*2+1]=k*sy+y;
      if (++ok>=allpos_max) goto Return1;
      NoMatch:;
    }
  }
  //----------------------
  Return1:
  return ok;
}

*/

}