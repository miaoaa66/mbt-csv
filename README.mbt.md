# miaoaa66/mbt-csv

Self-contained **CSV toolkit** for MoonBit: an RFC 4180-style parser and
writer, a header-aware `Table` with by-name access, filtering, column
selection, typed record helpers, lenient parsing of damaged files, and a
CLI — **zero third-party dependencies** (standard library + `moonbitlang/x`
for CLI file IO only).

## Why this library

mooncakes previously offered only low-level parsing
(`maria/csv_parser@0.1.0`, Apache-2.0): given a string it returns raw
`Array[Array[String]]` and stops there. Every application still has to deal
with header alignment, type conversion, filtering and damaged rows on its
own.

**mbt-csv is an independent implementation that covers the whole pipeline:**

| Capability | Low-level parsers | mbt-csv |
|---|---|---|
| RFC 4180 parsing (quotes, escapes, multiline, CRLF) | ✅ | ✅ |
| custom delimiter / TSV | ✅ | ✅ |
| header-aware `Table`, access columns **by name** | ❌ | ✅ |
| typed record getters (`get_int` / `get_double` / `get_str`) | ❌ | ✅ |
| filter rows by predicate | ❌ | ✅ |
| column selection / projection | ❌ | ✅ |
| lenient mode that skips damaged rows and reports them | ❌ | ✅ |
| writer with automatic quoting + full round-trip | partial | ✅ |
| strict mode with precise `CsvError` diagnostics | partial | ✅ |
| CLI (info / head / get / filter / select / lenient) | ❌ | ✅ |

## Installation

```
moon add miaoaa66/mbt-csv
```

## Quick start

```moonbit
/// Parse into a header-aware table
let t = @csv.parse_table("name,age\nAlice,30\nBob,25")
let t = t.get(0, "name") // Some("Alice")

/// Typed record access
for r in t.records() {
  let name = r.get_str("name")
  let age = r.get_int("age")
}

/// Filter rows
let adults = t.filter(fn(r) { match r.get_int("age") { Ok(v) => v >= 30, Err(_) => false } })

/// Select and export columns
let sel = t.select(["name"])
let csv_text = sel.to_csv_string()

/// Real-world files: skip damaged rows, get a report
let res = @csv.parse_table_lenient(messy_input)
// res.table, res.issues
```

## Error handling

The strict entry points return `Result` and never panic:

```moonbit
match @csv.parse("\"unterminated") {
  Ok(doc) => println(doc.length())
  Err(e) => println(e.message()) // "unterminated quote at row 1, column 12"
}
```

`CsvError` variants: `UnterminatedQuote(row, col)`, `EmptyDocument`,
`ColumnCountMismatch(row, expected, actual)`.

## Parser behavior notes

- quoted fields may contain delimiters, newlines and escaped quotes (`""`)
- both `\r\n` and `\n` (and lone `\r`) end a record
- blank lines are skipped by default (`skip_empty_lines` in `CsvConfig`)
- a quote in the middle of an unquoted field is kept as a literal character
- the parser allows ragged rows; strictness is applied by `parse_table`,
  tolerance by `parse_table_lenient`

## CLI

```bash
moon run cmd/main -- info data.csv
moon run cmd/main -- head data.csv 3
moon run cmd/main -- get data.csv 0 name
moon run cmd/main -- filter data.csv age gt 30
moon run cmd/main -- select data.csv "name,salary"
moon run cmd/main -- lenient data.csv
```

## Development

```bash
moon check   # type check
moon test    # 21 tests covering parsing, writing, table ops and lenient mode
moon run cmd/main -- --help
```

## License

MIT
