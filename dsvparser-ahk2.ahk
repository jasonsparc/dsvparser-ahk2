#Requires AutoHotkey v2.0

global CSVParser := DSVParser(",")
global TSVParser := DSVParser("`t")

class DSVParser {

	; Creates a new DSVParser with the specified settings.
	__New(Delimiters, Qualifiers:='"') {
		if (StrLen(Delimiters) <= 0)
			throw Error("No delimiter specified.", -1)

		this.___Ds := Delimiters
		this.___Qs := Qualifiers

		this.___D := SubStr(this.___Ds, 1, 1)
		this.___Q := SubStr(this.___Qs, 1, 1)
	}

	; -------------------------------------------------------------------------
	; Properties

	Delimiters => this.___Ds
	Ds => this.Delimiters

	Qualifiers => this.___Qs
	Qs => this.Qualifiers

	DefaultDelimiter => this.___D
	D => this.DefaultDelimiter

	DefaultQualifier => this.___Q
	Q => this.DefaultQualifier

	; -------------------------------------------------------------------------
	; Methods

	; Given a DSV string, parses a single DSV cell from it, spits it out to the
	; specified "OutCell" output variable, and then returns the next position in
	; the input string where parsing may continue.
	;
	; The return value can be 0 to signal that the string was fully consumed and
	; that there is nothing left to parse.
	;
	; The output variable "OutIsLastInRow" will be set to true if the current
	; cell being parsed was detected to be the last cell of the current row.
	;
	NextCell(InString, &OutCell:="", &OutIsLastInRow:=false, StartingPos:=1) {
		local regexNeedle
		if (ObjHasOwnProp(this, "NextCell__regex")) {
			regexNeedle := this.NextCell__regex
		} else {
			; Line break characters. See:
			; - https://en.wikipedia.org/wiki/Newline#Unicode
			; - https://docs.python.org/3/library/stdtypes.html#str.splitlines
			static nl := "`r`n`v`f" chr(0x85) chr(0x1E) chr(0x1D) chr(0x1C) chr(0x2028) chr(0x2029)

			ds := RegExReplace(this.___Ds, "[\Q\.*?+[{|()^$}]\E]", "\$0")
			qs := RegExReplace(this.___Qs, "[\Q\.*?+[{|()^$}]\E]", "\$0")

			this.NextCell__regex := regexNeedle := "SsD)"
				. (StrLen(this.___Qs) > 1 ? "(?:"
					. "(?P<Qualifier>[" qs "])"
					. "(?P<Qualified>(?:(?!\1).|\1\1)*)"
					. "\1"
				. ")?" : (qs ? "(?:"
					. "(?P<Qualifier>" qs ")"
					. "(?P<Qualified>(?:[^" qs "]|" qs qs ")*)"
					. qs
				. ")?" : ""
					. "(?P<Qualifier>)"
					. "(?P<Qualified>)"
				. ""))
				. "(?P<Delimited>[^" ds nl "]*)"
				. "(?:"
					. "(?P<Delimiter>[" ds "])"
					. "|`r`n?|`n`r?" ; -- https://en.wikipedia.org/wiki/Newline#Representation
					. "|.|$"
				. ")"
		}
		found := RegExMatch(InString, regexNeedle, &match, Max(StartingPos, 1))

		q := match.Qualifier
		; According to the RFC, Implementors should:
		; "be conservative in what you do, be liberal in what you accept from
		; others" (RFC 793, Section 2.10) (RFC 4180, Page 4)
		OutCell := StrReplace(match.Qualified, q q, q) . match.Delimited
		; The above treatment is also the same as that of Microsoft Excel.

		nextPos := found + match.Len
		if (StrLen(match.Delimiter)) {
			; Found a delimiter. Therefore, there should be a next cell, even if
			; it's an empty one.
			OutIsLastInRow := false
			return nextPos
		}

		OutIsLastInRow := true
		; The last record in the file may or may not have an ending line break.
		; (RFC 4180, Section 2.2)
		return nextPos > StrLen(InString) ? 0 : nextPos
	}

	FetchCell(InString, &OutIsLastInRow:=false, InOutPos:=1) {
		if (not InOutPos is VarRef)
			_InOutPos := InOutPos, InOutPos := &_InOutPos

		%InOutPos% := this.NextCell(InString, &cell, &OutIsLastInRow, %InOutPos%)
		return cell
	}

	ToString() => ObjHasOwnProp(this, "___ToString")
		? this.___ToString
		: this.___ToString := Type(this) " { "
			. "Ds '" RegExReplace(this.Delimiters, "['``]", "``$0") "' "
			. "Qs '" RegExReplace(this.Qualifiers, "['``]", "``$0") "' }"
}
