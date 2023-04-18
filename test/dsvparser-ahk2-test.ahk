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

Assert("12345" == TSVParser.FetchCell(sample))
Assert(ObjHasOwnProp(TSVParser, "NextCell__regex"))

Assert("12345" == TSVParser.FetchCell(sample, , 1))
Assert("2345" == TSVParser.FetchCell(sample, , 2))

Assert("hello`tworld" == TSVParser.FetchCell(sample, &isLastInRow, 7))
Assert(!isLastInRow)

Assert("" == TSVParser.FetchCell(sample, &isLastInRow, 20))
Assert(!isLastInRow)

Assert("" == TSVParser.FetchCell(sample, &isLastInRow, 21))
Assert(isLastInRow)

Assert(expected == TSVParser.FormatRow(TSVParser.FetchRow(sample)))

Assert(expected == TSVParser.FromArray(TSVParser.ToArray(sample), , false))
Assert(expected "`r`n" expected == TSVParser.FromArray(TSVParser.ToArray(sample sample), , false))
Assert(expected "`r`n`t`t`r`n" expected == TSVParser.FromArray(TSVParser.ToArray(sample "`n" sample), , false))

NQ_TSVParser := DSVParser("`t", "")
Assert(sample == NQ_TSVParser.FromArray(NQ_TSVParser.ToArray(sample)))

; Empty strings

Assert("" == TSVParser.FormatCell(TSVParser.FetchCell("", &isLastInRow)))
Assert(isLastInRow)

Assert(ObjHasOwnProp(TSVParser, "FormatCell__regex"))

Assert("" == TSVParser.FormatRow(TSVParser.FetchRow("")))
Assert("" == TSVParser.FromArray(TSVParser.ToArray(""), , false))

Assert("" == NQ_TSVParser.FromArray(NQ_TSVParser.ToArray(""), , false))

; Single cells

Assert("1" == TSVParser.FormatCell(TSVParser.FetchCell("1", &isLastInRow)))
Assert(isLastInRow)

Assert("1" == TSVParser.FormatRow(TSVParser.FetchRow("1")))
Assert("1" == TSVParser.FromArray(TSVParser.ToArray("1"), , false))

Assert("1" == NQ_TSVParser.FromArray(NQ_TSVParser.ToArray("1"), , false))

; Optional blank last line

Assert("1" == TSVParser.FormatCell(TSVParser.FetchCell("1`r`n", &isLastInRow, &(inOutPos := 1))))
Assert(isLastInRow && inOutPos == 0)

Assert("1" == TSVParser.FormatRow(TSVParser.FetchRow("1`r`n", &(inOutPos := 1))))
Assert(inOutPos == 0)
Assert("1`t2" == TSVParser.FormatRow(TSVParser.FetchRow("1`t2`r`n", &(inOutPos := 1))))
Assert(inOutPos == 0)
Assert("1`t2" == TSVParser.FormatRow(TSVParser.FetchRow("1`t2`r`n`r`n", &(inOutPos := 1))))
Assert(inOutPos == 6)
Assert("" == TSVParser.FormatRow(TSVParser.FetchRow("1`t2`f`r`n", &(inOutPos := 4))))
Assert(inOutPos == 5)
Assert("`t" == TSVParser.FormatRow(TSVParser.FetchRow("1`t2`r3`n`t`r`n`r`n", &(inOutPos := 7))))
Assert(inOutPos == 10)
Assert("`t" == TSVParser.FormatRow(TSVParser.FetchRow("1`t2`r3`n`t`r`n", &(inOutPos := 7))))
Assert(inOutPos == 0)

Assert("1`r`n" == TSVParser.FromArray(TSVParser.ToArray("1`r`n`r`n"), , false))
Assert("1`r`n`r`n" == TSVParser.FromArray(TSVParser.ToArray("1`r`n`r`n")))

Assert("1`t2`r`n`t" == TSVParser.FromArray(TSVParser.ToArray("1`t2`r`n`r`n"), , false))
Assert("1`t2`r`n`t`r`n" == TSVParser.FromArray(TSVParser.ToArray("1`t2`r`n`r`n")))

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
