> Parse CSV files! Parse TSV files! Parse PSV files?!
>
> Yes!! Parse it all! All the DSV files!

# DSV parser for AHK v2!

A simple utility for **reliably** parsing delimiter-separated values (i.e., DSV)
in AutoHotkey v2 scripts, whether that be comma-separated (i.e., CSV), tab-separated
(i.e., TSV), or something else, possibly even exotic ones.

For AutoHotkey v1, check out, <https://github.com/jasonsparc/DSVParser-AHK>

## Features

- [RFC 4180](https://tools.ietf.org/html/rfc4180) compliant.
- Supports newlines and other weird characters in cells enclosed in [text
qualifiers](https://www.quora.com/What-is-a-text-qualifier).
- Allows custom delimiters and text qualifiers.
- Supports multiple delimiters (like Microsoft Excel).
- Supports multiple qualifiers (unlike Microsoft Excel).
- Proper support for malformed inputs (e.g., `"hello" world "foo bar"` will be
parsed as `hello world "foo bar"`).
	- Achieved by treating cells as composed of two components: a
	text-qualified part (i.e., any raw string, excluding unescaped qualifier
	characters), and a delimited text part (i.e., any raw string, including
	qualifier characters, except newlines and delimiter characters).
	- The behavior for ill-formed cells are therefore not undefined.
	- The above treatment is also similar to that of Microsoft Excel.
- Recognizes many ASCII and Unicode line break representations:
	- i.e., `CR`, `LF`, `CR+LF`, `LF+CR`, `VT`, `FF`, `NEL`, `RS`, `GS`,
	`FS`, `LS`, `PS`
	- References:
		- [Newline - Wikipedia](https://en.wikipedia.org/wiki/Newline)
		- [Field separators | C0 and C1 control codes -
		Wikipedia](https://en.wikipedia.org/wiki/C0_and_C1_control_codes#Field_separators)
		- [`str.splitlines([keepends])` | Built-in Types — Python 3.8.0
		documentation](https://docs.python.org/3/library/stdtypes.html#str.splitlines)

## Example

### Basic usage

Download [`dsvparser-ahk2.ahk`][download][^1] then include it in your script
(via [`#Include`][include]) as its library.

[download]: https://raw.githubusercontent.com/jasonsparc/dsvparser-ahk2/master/dsvparser-ahk2.ahk
[include]: https://www.autohotkey.com/docs/v2/lib/_Include.htm

[^1]: **Tip:** Right-click this [link][download] [`dsvparser-ahk2.ahk`][download],
  then "Save link as…" or whatever is the equivalent provided by your browser.

Once you've done that, here's how you might use the library:

```AutoHotkey
; Load a TSV data string
tsvStr := FileRead("data.tsv")

; Parse the TSV data string
MyTable := TSVParser.ToArray(tsvStr)

; Do something with `MyTable`

MsgBox MyTable[2][1] ; Access 1st cell of 2nd row

; ... do something else with `MyTable` ...

; Convert into a CSV, with custom line break settings
csvStr := CSVParser.FromArray(MyTable, "`n", false)

if (FileExist("new-data.csv"))
    FileDelete("new-data.csv")
FileAppend(csvStr, "new-data.csv")
```

### And there's more!

Both `TSVParser` and `CSVParser` are premade instances of the class `DSVParser`.
To read and write in other formats, create a new instance of `DSVParser` and
specify your desired configuration.

Here's a `DSVParser` for pipe-separated values (aka., bar-separated):

```AutoHotkey
global BSVParser := DSVParser("|")
```

Many more utility functions are provided for parsing and formatting DSV strings,
including parsing just a single DSV cell.

Check out the source code! It's really just a tiny file.

## Why not just use `Loop parse`?

AutoHotkey v2 comes with [`Loop parse _, "CSV"`][loop-parse], which allows you
to quickly parse a “single line” of CSV string. However, if your string contains
several lines of text, it will still treat it as if it was a single line of CSV
string. To mitigate this problem, you may first break the string up into several
lines using a file-reading loop (either [`Loop read`][loop-read] or
[``Loop parse _, "`n", "`r"``][loop-parse-ex-file]), then parse each line
separately. However, that ignores the fact that a CSV cell is allowed to contain
multiple lines—Yes! All in a single CSV cell! If your CSV data is quite complex,
`Loop parse` won't be able to handle such cases.

[loop-parse]: https://www.autohotkey.com/docs/v2/lib/LoopParse.htm
[loop-parse-ex-file]: https://www.autohotkey.com/docs/v2/lib/LoopParse.htm#ExFileRead
[loop-read]: https://www.autohotkey.com/docs/v2/lib/LoopRead.htm

For the initial motivation regarding the creation of this library, see the forum
post: “[[Library] DSV Parser - AutoHotkey Community](https://www.autohotkey.com/boards/viewtopic.php?t=70425)”

> P.S. This library can even be used to parse a CSV inside a CSV, inside a CSV,
inside a CSV, inside a…—whatever “RFC 4180” allows.
