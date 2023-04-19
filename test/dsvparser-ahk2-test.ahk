#Requires AutoHotkey v2.0
#Warn ; Enable warnings to assist with detecting common errors.

#Include ..\dsvparser-ahk2.ahk

RunHint := Gui("-SysMenu")
RunHint.MarginY *= 2
RunHint.BackColor := "FFFFFF"
RunHint.AddText("W300 Center c000000", "Running tests...")
RunHint.Show()

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

sampleArrayOfArrays := TSVParser.ToArray(sample sample sample)
Assert(sampleArrayOfArrays[1][2] == "hello`tworld")
Assert(sampleArrayOfArrays[2][3] == "")
Assert(sampleArrayOfArrays.Length == 3)
Assert(sampleArrayOfArrays[3].Length == 3)

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
; Parsing tests: Normal DSV cells

Assert("Carol" == CSVParser.FetchCell("Carol,Alice,Bob"))
Assert("Alice" == CSVParser.FetchCell("Carol,Alice,Bob", , 7))
Assert("Bob" == CSVParser.FetchCell("Carol,Alice,Bob", , 13))

Assert("Carol" == TSVParser.FetchCell("Carol`tAlice`tBob"))
Assert("Alice" == TSVParser.FetchCell("Carol`tAlice`tBob", , 7))
Assert("Bob" == TSVParser.FetchCell("Carol,Alice,Bob", , 13))

Assert("Carol,Alice,Bob" == CSVParser.FormatRow(CSVParser.FetchRow("Carol,Alice,Bob")))
Assert("Carol`tAlice`tBob" == TSVParser.FormatRow(TSVParser.FetchRow("Carol`tAlice`tBob")))

MSVParser := DSVParser("| `n")
d1 := MSVParser.D

loop parse MSVParser.Delimiters
{
	d := A_LoopField
	Assert("Carol" == MSVParser.FetchCell("Carol" d "Alice" d "Bob"), d)
	Assert("Alice" == MSVParser.FetchCell("Carol" d "Alice" d "Bob", , 7), d)
	Assert("Bob" == MSVParser.FetchCell("Carol" d "Alice" d "Bob", , 13), d)

	Assert("Carol" d1 "Alice" d1 "Bob" == MSVParser.FormatRow(MSVParser.FetchRow("Carol" d "Alice" d "Bob")))
}

Assert("Alice" == CSVParser.FormatCell("Alice"))
Assert("Alice" == TSVParser.FormatCell("Alice"))

; -----------------------------------------------------------------------------
; Parsing tests: Text-qualified DSV cells

Assert("Carol" == CSVParser.FetchCell("`"Carol`",Alice,Bob"))
Assert("Alice" == CSVParser.FetchCell("Carol,`"Alice`",Bob", , 7))
Assert("Bob" == CSVParser.FetchCell("Carol,Alice,`"Bob`"", , 13))

; Embedded delimiters, qualifiers, newlines
Assert("foo,bar" == CSVParser.FetchCell("`"foo,bar`",`"Hello`nWorld`""))
Assert("foo`"bar" == CSVParser.FetchCell("`"foo`"`"bar`",`"Hello`nWorld`""))
Assert("Hello`"World" == CSVParser.FetchCell("`"foo`r`nbar`",`"Hello`"`"World`"", , 12))
Assert("Hello`r`nWorld" == CSVParser.FetchCell("`"foo,bar`",`"Hello`r`nWorld`"", , 11))

CSVParser2 := DSVParser(",", "`"'|```r")
loop parse CSVParser2.Qualifiers
{
	q := A_LoopField
	Assert("Carol" == CSVParser2.FetchCell(q "Carol" q ",Alice,Bob"), q)
	Assert("Alice" == CSVParser2.FetchCell("Carol," q "Alice" q ",Bob", , 7), q)
	Assert("Bob" == CSVParser2.FetchCell("Carol,Alice," q "Bob" q, , 13), q)

	allQualifiedCells := q "Carol" q "," q "Alice" q "," q  "Bob" q
	Assert("Carol" == CSVParser2.FetchCell(allQualifiedCells), q)
	Assert("Alice" == CSVParser2.FetchCell(allQualifiedCells, , 9), q)
	Assert("Bob" == CSVParser2.FetchCell(allQualifiedCells, , 17), q)

	; Parse cells after a text-qualified cell
	Assert("Alice" == CSVParser2.FetchCell(q "Carol," q "Alice,Bob", , 9), q)
	Assert("Bob" == CSVParser2.FetchCell("Carol," q "Alice" q ",Bob", , 15), q)

	; Embedded delimiters, qualifiers, newlines
	Assert("foo,bar" == CSVParser2.FetchCell(q "foo,bar" q "," q "Hello`nWorld" q), q)
	Assert("foo" q "bar" == CSVParser2.FetchCell(q "foo" q q "bar" q "," q "Hello`nWorld" q), q)
	Assert("Hello" q "World" == CSVParser2.FetchCell(q "foo`r`nbar" q "," q "Hello" q q "World" q, , 12), q)
	Assert((q == "`r" ? "Hello" : "Hello`r`nWorld") == CSVParser2.FetchCell(q "foo,bar" q "," q "Hello`r`nWorld" q, , 11), q)
	Assert((q == "`"" ? "HelloWorld`"" : "Hello`"World") == CSVParser2.FetchCell(q "foo,bar" q "," q "Hello`"World" q, , 11), q)
}

Assert("Alice" == CSVParser2.FormatCell("Alice"))

q := CSVParser2.Q, qs := CSVParser2.Qualifiers, qs2 := StrReplace(qs, q, q q)
Assert(q "Alice" qs2 "Carol" q == CSVParser2.FormatCell("Alice" qs "Carol"))

ds := CSVParser2.Delimiters
Assert(q "Alice" ds "Carol" q == CSVParser2.FormatCell("Alice" ds "Carol"))
Assert(q "Alice" ds q q "Carol" q == CSVParser2.FormatCell("Alice" ds q "Carol"))
Assert(q "Alice" ds qs2 "Carol" q == CSVParser2.FormatCell("Alice" ds qs "Carol"))

Assert(q "Alice" q q ds "Carol" q == CSVParser2.FormatCell("Alice" q ds "Carol"))
Assert(q "Alice" qs2 ds "Carol" q == CSVParser2.FormatCell("Alice" qs ds "Carol"))

Assert(q "Alice`nCarol" q == CSVParser2.FormatCell("Alice`nCarol"))
Assert(q "Alice`r`nCarol" q == CSVParser2.FormatCell("Alice`r`nCarol"))
Assert(q "Alice`r" q q ds "`nCarol" q == CSVParser2.FormatCell("Alice`r" q ds "`nCarol"))

; -----------------------------------------------------------------------------
; Parsing tests with sample data files

FileEncoding "UTF-8-RAW"
targetDir := "data\malformed vs. expected"

parser := CSVParser, ext := "csv"
malformed := FileRead(targetDir "\malformed." ext)
expected := FileRead(targetDir "\expected." ext)
Assert(StrLen(malformed) > 0)
Assert(expected == parser.FromArray(parser.ToArray(malformed)))

parser := TSVParser, ext := "tsv"
malformed := FileRead(targetDir "\malformed." ext)
expected := FileRead(targetDir "\expected." ext)
Assert(StrLen(malformed) && StrLen(expected))
Assert(expected == parser.FromArray(parser.ToArray(malformed)))

parser := DSVParser("|"), ext := "psv"
malformed := FileRead(targetDir "\malformed." ext)
expected := FileRead(targetDir "\expected." ext)
Assert(StrLen(malformed) && StrLen(expected))
Assert(expected == parser.FromArray(parser.ToArray(malformed)))

parser := DSVParser("|", "'"), ext := "sq.psv"
malformed := FileRead(targetDir "\malformed." ext)
expected := FileRead(targetDir "\expected." ext)
Assert(StrLen(malformed) && StrLen(expected))
Assert(expected == parser.FromArray(parser.ToArray(malformed)))

parser := DSVParser(chr(0x1F), chr(0x10)), ext := "dle.usv"
malformed := FileRead(targetDir "\malformed." ext)
expected := FileRead(targetDir "\expected." ext)
Assert(StrLen(malformed) && StrLen(expected))
Assert(expected == parser.FromArray(parser.ToArray(malformed)))

parser := DSVParser(chr(0x1F), chr(0x10)), ext := "dle.rs.usv"
malformed := FileRead(targetDir "\malformed." ext)
expected := FileRead(targetDir "\expected." ext)
Assert(StrLen(malformed) && StrLen(expected))
Assert(expected == parser.FromArray(parser.ToArray(malformed), chr(0x1E)))

; -----------------------------------------------------------------------------
; Parsing tests with sample data files: CSV<=>TSV conversions

FileEncoding "UTF-8-RAW"

target := "data\123abc_()"
csvData := FileRead(target ".csv")
tsvData := FileRead(target ".tsv")
Assert(StrLen(csvData) && StrLen(tsvData))
Assert(tsvData == TSVParser.FromArray(CSVParser.ToArray(csvData)))
Assert(csvData == CSVParser.FromArray(TSVParser.ToArray(tsvData)))

target := "data\Alice & Bob"
csvData := FileRead(target ".csv")
tsvData := FileRead(target ".tsv")
Assert(StrLen(csvData) && StrLen(tsvData))
Assert(tsvData == TSVParser.FromArray(CSVParser.ToArray(csvData)))
Assert(csvData == CSVParser.FromArray(TSVParser.ToArray(tsvData)))

target := "data\sales-data"
csvData := FileRead(target ".csv")
tsvData := FileRead(target ".tsv")
Assert(StrLen(csvData) && StrLen(tsvData))
Assert(tsvData == TSVParser.FromArray(CSVParser.ToArray(csvData)))
Assert(csvData == CSVParser.FromArray(TSVParser.ToArray(tsvData)))

; "TheBeatles" demo files from:
; - https://github.com/JnLlnd/ObjCSV

target := "data\TheBeatles"
csvData := FileRead(target ".csv")
tsvData := FileRead(target ".tsv")
Assert(StrLen(csvData) && StrLen(tsvData))
Assert(tsvData == TSVParser.FromArray(CSVParser.ToArray(csvData)))
Assert(csvData == CSVParser.FromArray(TSVParser.ToArray(tsvData)))

target := "data\TheBeatles-LOVE"
csvData := FileRead(target ".csv")
tsvData := FileRead(target ".tsv")
Assert(StrLen(csvData) && StrLen(tsvData))
Assert(tsvData == TSVParser.FromArray(CSVParser.ToArray(csvData)))
Assert(csvData == CSVParser.FromArray(TSVParser.ToArray(tsvData)))

target := "data\TheBeatles-Lyrics"
csvData := FileRead(target ".csv")
tsvData := FileRead(target ".tsv")
Assert(StrLen(csvData) && StrLen(tsvData))
Assert(tsvData == TSVParser.FromArray(CSVParser.ToArray(csvData)))
Assert(csvData == CSVParser.FromArray(TSVParser.ToArray(tsvData)))

; -----------------------------------------------------------------------------
; All tests ended

RunHint.Destroy()
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
		global RunHint
		RunHint.Destroy()
		throw Error("Assertion failed!", -1, extra)
	}
}
