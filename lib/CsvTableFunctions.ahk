; CSV Table Functions - by berban
; https://www.autohotkey.com/boards/viewtopic.php?f=6&t=59927
; Last Update: December 12, 2018

; ReadTable()
; Reads a CSV file (or a CSV string) into a table object (just a 2-dimensional array.)
; The function returns an array in the format Array[Row Number][Column Name or Number]
; FileOrString = The path to a CSV file, or a string of tabular CSV-foratted text
; Options = There are 3 options, one or multiple can be specified as named key-value pairs in an array.
;    {"Headers" : True} = Normally a 10x10 CSV table will return an array with 10 rows and 10 columns. Using "Headers" will cause the function to interpret the first row as column headers. Each row will then have named column attributes (Table[2]["Cost"], Table[2]["ID"], etc) instead of numbered columns (Table[2][1], Table[2][2], etc)
;    {"GroupBy" : FieldName} = Will create an array grouped by the specified field (column), which will be in essence a 3-dimensional array. For instance, if {"GroupBy" : 2} is specified where Column 2 is a month field, then Table["October"] would contain all rows where the month is october. This can be useful for quickly retrieving certain values.
;    {"Delimiter" : Delimiter} = Delimiter character, by default a comma for CSV
; ByRef Header = This is an output variable to store the header row if "Headers" is specified in the options. This is to allow the table to be re-written in the same format it was read, otherwise named columns would be ordered alphabetically.
; ByRef RowCount = number of rows read
; ByRef ColCount = number of columns read
; Note: Carriage return (`r) is used as a sort of "special character" and if you have carriage returns separate from newlines for some reason they will be erased.

ReadTable(FileOrString, Options="", ByRef Header="", ByRef RowCount="", ByRef ColCount="")
{
	Array := [], Header := [], GroupedArray := []
	RowCount := 1, Col := 0, ColCount := 0
	For k,v in Options
		%k% := v
	If (Delimiter = "")
		Delimiter := ","
	SearchStartAt := StrLen(Delimiter) + 1
	If FileExist(FileOrString)
		FileRead, FileOrString, %FileOrString%
	Loop, Parse, FileOrString, `n, `r
	{
		Loop, Parse, A_LoopField, %Delimiter%
		{
			If !Quoted {
				Col += 1
				If (Header[Col] = "")
					Header[Col] := Col
				If (InStr(A_LoopField, """") = 1)
					Quoted := [RowCount, Header[Col]]
				Else
					Array[RowCount, Header[Col]] := A_LoopField
			}
			If Quoted {
				If (A_Index = 1) or (QuotedValue = "")
					QuotedValue .= StrReplace(A_LoopField, """""", "`r")
				Else
					QuotedValue .= Delimiter StrReplace(A_LoopField, """""", "`r")
				If InStr(QuotedValue, """", False, SearchStartAt)
					Array[Quoted[1], Quoted[2]] := StrReplace(StrReplace(QuotedValue, """"), "`r", """"), Quoted := QuotedValue := ""
			}
		}
		If Quoted
			QuotedValue .= "`n"
		Else If Headers
			Header := Array[1].Clone(), Headers := False, Array := [], Col := 0
		Else {
			If (Col > ColCount)
				ColCount := Col
			If (GroupBy != "")
				Row := Array[RowCount].Clone(), Row.Delete(GroupBy), GroupedArray[Array[RowCount, GroupBy], Floor(GroupedArray[Array[RowCount, GroupBy]].MaxIndex()) + 1] := Row
			RowCount += 1, Col := 0
		}
	}
	Return GroupBy = "" ? Array : GroupedArray
}


; WriteTable()
; Writes a table into a csv file, overwriting that file if necessary.
; Table = a table array in the same format as that produced with ReadTable()
; OutputPath = the path to the destination CSV file
; Headers = if named column headers were used, provide the ByRef Header value used when the table was read with ReadTable() in this parameter.

WriteTable(ByRef Table, OutputPath, Headers="")
{
	FileDelete, %OutputPath%
	If (Headers = "") {
		Headers := []
		For Key,ColumnName in Table[1]
			Headers[A_Index] := Key
	} Else
		Loop % Headers.MaxIndex()
			Table[0,Headers[A_Index]] := Headers[A_Index]
	For Key,Row in Table
	{
		If (A_Index > 1)
			Output .= "`r`n"
		Loop % Headers.MaxIndex()
			Output .= (A_Index = 1 ? "" : ",") (RegExMatch(Row[Headers[A_Index]], "[,`n`r""]") ? """" StrReplace(Row[Headers[A_Index]], """", """""") """" : Row[Headers[A_Index]])
	}
	Table.Delete(0)
	FileAppend, %Output%, %OutputPath%
	Return ErrorLevel
}


; SortTable()
; Sorts a table based on one or more fields (columns). The sort is simply an insertion sort, so for very large tables it might be desirable to use another more efficient sorting algorithm.
; Input = Table array to sort
; Fields* = One or more fields (columns) to sort the table by. If multiple are given, Field 2 will be used in the event of ties in Field 1, etc.
;    "2" = sort by column 2
;    "Date" = sort by column "Date", if the columns were given named headers
;    "~Date" = sort in inverse order
;    ["Date", "ParseDate"] = sort by Date using function ParseDate() to compare values. This function must accept 2 inputs and return a positive value if the first input is greater, much like the F option in AutoHotkey's Sort commmand.
; The sorted table is returned by the function.

SortTable(Input, Fields*)
{
	Loop % Fields.MaxIndex()
	{
		SortField := Fields[Fields.MaxIndex() + 1 - A_Index]
		If IsObject(SortField)
			SortFunc := SortField[2], SortField := SortField[1]
		Else
			SortFunc := ""
		If (InStr(SortField, "~") = 1)
			SortField := SubStr(SortField, 2), Ascending := False
		Else
			Ascending := True
		Output := []
		For n,Row in Input
			Loop %n%
				If (A_Index = n) {
					Output.InsertAt(A_Index,Row)
					Break
				} Else If (SortFunc != "") {
					If Ascending {
						If (%SortFunc%(Output[A_Index,SortField], Row[SortField]) > 0) {
							Output.InsertAt(A_Index,Row)
							Break
						}
					} Else If (%SortFunc%(Output[A_Index,SortField], Row[SortField]) < 0) {
						Output.InsertAt(A_Index,Row)
						Break
					}
				} Else If Ascending {
					If (Output[A_Index,SortField] > Row[SortField]) {
						Output.InsertAt(A_Index,Row)
						Break
					}
				} Else If (Output[A_Index,SortField] < Row[SortField]) {
					Output.InsertAt(A_Index,Row)
					Break
				}
		Input := Output.Clone()
	}
	Return Input
}