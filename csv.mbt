///|
/// Configuration for the CSV parser and writer.
pub struct CsvConfig {
  /// Field separator (default `','`).
  delimiter : Char
  /// Quote character (default `'"'`).
  quote : Char
  /// Whether records consisting of a single empty field (blank lines)
  /// are dropped when parsing (default `true`).
  skip_empty_lines : Bool
} derive(Eq, Debug)

///|
/// Default configuration: comma delimiter, double-quote, skip blank lines.
pub fn CsvConfig::default() -> CsvConfig {
  { delimiter: ',', quote: '"', skip_empty_lines: true }
}

///|
/// Configuration with a custom delimiter (e.g. `';'` or `'\t'`).
pub fn CsvConfig::with_delimiter(delimiter : Char) -> CsvConfig {
  { delimiter: delimiter, quote: '"', skip_empty_lines: true }
}

///|
/// Errors reported by the strict parser.
pub enum CsvError {
  /// A quoted field was never closed (row, column are 1-based).
  UnterminatedQuote(Int, Int)
  /// `Table::from_document` was given an empty document.
  EmptyDocument
  /// A data row has a different field count than the header
  /// (row is the 1-based data row index; expected vs actual field count).
  ColumnCountMismatch(Int, Int, Int)
} derive(Eq, Debug)

///|
/// Human-readable description of a `CsvError`.
pub fn CsvError::message(self : CsvError) -> String {
  match self {
    UnterminatedQuote(row, col) =>
      "unterminated quote at row \{row}, column \{col}"
    EmptyDocument => "the input contains no records"
    ColumnCountMismatch(row, expected, actual) =>
      "row \{row} has \{actual} fields, expected \{expected}"
  }
}

///|
/// Parse a CSV string with the default configuration.
pub fn parse(input : String) -> Result[Array[Array[String]], CsvError] {
  parse_with_config(input, CsvConfig::default())
}

///|
/// Parse a tab-separated string.
pub fn parse_tsv(input : String) -> Result[Array[Array[String]], CsvError] {
  parse_with_config(input, CsvConfig::with_delimiter('\t'))
}

///|
/// Parse a CSV string with a custom configuration.
///
/// Behavior notes:
/// - Handles quoted fields containing delimiters, newlines and escaped
///   quotes (`""` inside a quoted field).
/// - Accepts both `\r\n` and `\n` row endings (a lone `\r` also ends a row).
/// - A quote in the middle of an unquoted field is treated as a literal
///   character (lenient, matches common implementations).
/// - The parser does not enforce equal field counts per row; use
///   `Table::from_document` (strict) or `parse_table_lenient` (skip) on top.
pub fn parse_with_config(
  input : String,
  config : CsvConfig,
) -> Result[Array[Array[String]], CsvError] {
  let chars = input.to_array()
  let n = chars.length()
  let rows : Array[Array[String]] = []
  let field = StringBuilder()
  let mut row : Array[String] = []
  let mut in_quotes = false
  let mut last_was_row_end = true
  let mut i = 0
  let mut row_no = 1
  let mut col_no = 1
  while i < n {
    let ch = chars[i]
    if in_quotes {
      if ch == config.quote {
        if i + 1 < n && chars[i + 1] == config.quote {
          // escaped quote ""
          field.write_char(config.quote)
          i = i + 2
          continue
        }
        in_quotes = false
        i = i + 1
        continue
      }
      if ch == '\n' {
        row_no = row_no + 1
        col_no = 1
      }
      field.write_char(ch)
      i = i + 1
      continue
    }
    if ch == config.quote && field.to_string().length() == 0 {
      in_quotes = true
      i = i + 1
      continue
    }
    if ch == config.delimiter {
      row.push(field.to_string())
      field.reset()
      col_no = col_no + 1
      last_was_row_end = false
      i = i + 1
      continue
    }
    if ch == '\r' || ch == '\n' {
      // consume the second half of a CRLF pair
      if ch == '\r' && i + 1 < n && chars[i + 1] == '\n' {
        i = i + 1
      }
      row.push(field.to_string())
      field.reset()
      let is_blank = row.length() == 1 && row[0].length() == 0
      if !(config.skip_empty_lines && is_blank) {
        rows.push(row)
      }
      row = []
      last_was_row_end = true
      row_no = row_no + 1
      col_no = 1
      i = i + 1
      continue
    }
    field.write_char(ch)
    last_was_row_end = false
    i = i + 1
  }
  if in_quotes {
    return Err(UnterminatedQuote(row_no, col_no))
  }
  // flush the final record unless the input ended exactly on a row boundary
  if !last_was_row_end {
    row.push(field.to_string())
    let is_blank = row.length() == 1 && row[0].length() == 0
    if !(config.skip_empty_lines && is_blank) {
      rows.push(row)
    }
  }
  Ok(rows)
}
