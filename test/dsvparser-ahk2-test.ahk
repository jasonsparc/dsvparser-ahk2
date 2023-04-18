#Requires AutoHotkey v2.0
#Warn ; Enable warnings to assist with detecting common errors.

#Include ..\dsvparser-ahk2.ahk

; -----------------------------------------------------------------------------
; Properties tests

Assert(',' == CSVParser.Ds)
Assert('"' == CSVParser.Qs)

Assert("`t" == TSVParser.Ds)
Assert("`"" == TSVParser.Qs)

MSVParser := DSVParser("| `n", "'`"|```r`n")
Assert("|" == MSVParser.D)
Assert("'" == MSVParser.Q)
Assert("| `n" == MSVParser.delimiters)
Assert("'`"|```r`n" == MSVParser.qualifiers)

; Test `ToString`

Assert(DSVParser.Prototype.HasProp("ToString"))

Assert(String(CSVParser))
Assert(String(TSVParser))

Assert(String(CSVParser) == String(CSVParser))
Assert(String(TSVParser) == String(TSVParser))

; -----------------------------------------------------------------------------
; Basic white-box tests

sample := "12345`t`"hello`t`"world`t`r`n"
expected := "12345`t`"hello`tworld`"`t"

Assert("12345" == TSVParser.FetchCell(sample, , 1))
Assert("2345" == TSVParser.FetchCell(sample, , 2))

Assert("hello`tworld" == TSVParser.FetchCell(sample, &isLastInRow, 7))
Assert(!isLastInRow)

Assert("" == TSVParser.FetchCell(sample, &isLastInRow, 20))
Assert(!isLastInRow)

Assert("" == TSVParser.FetchCell(sample, &isLastInRow, 21))
Assert(isLastInRow)

; -----------------------------------------------------------------------------
; All tests ended

MsgBox "All tests passed!", , "Iconi"

ExitApp ; =====================================================================
; -----------------------------------------------------------------------------
; Utilities

Assert(condition, extra:="") {
	if (!condition) {
		if (extra && StrLen(extra) < 5) {
			extra2 := "`r`nUnicode:"
			loop StrLen(extra)
				extra2 .= " " Format("0x{:X}", Ord(SubStr(extra, A_Index, 1)))
			extra .= extra2
		}
		throw Error("Assertion failed!", -1, extra)
	}
}
