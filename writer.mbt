///|
/// Whether a field contains characters that require quoting on output
/// (delimiter, quote character, CR or LF).
pub fn needs_quoting(s : String, config : CsvConfig) -> Bool {
  for ch in s {
    if ch == config.delimiter || ch == config.quote || ch == '\r' || ch == '\n' {
      return true
    }
  }
  false
}

///|
/// Escape a single field: wrap it in quotes when needed and double any
/// embedded quote characters.
pub fn escape_field(s : String, config : CsvConfig) -> String {
  if !needs_quoting(s, config) {
    return s
  }
  let sb = StringBuilder()
  sb.write_char(config.quote)
  for ch in s {
    if ch == config.quote {
      sb.write_char(config.quote)
    }
    sb.write_char(ch)
  }
  sb.write_char(config.quote)
  sb.to_string()
}

///|
/// Serialize one record to a CSV line (without a trailing row ending).
pub fn row_to_string(
  row : Array[String],
  config? : CsvConfig,
) -> String {
  let cfg = match config {
    Some(c) => c
    None => CsvConfig::default()
  }
  let sb = StringBuilder()
  for i, f in row {
    if i > 0 {
      sb.write_char(cfg.delimiter)
    }
    sb.write_string(escape_field(f, cfg))
  }
  sb.to_string()
}

///|
/// Serialize a full document. Records are joined with `\r\n`
/// (per RFC 4180); the output does not end with a trailing row ending.
pub fn document_to_string(
  doc : Array[Array[String]],
  config? : CsvConfig,
) -> String {
  let cfg = match config {
    Some(c) => c
    None => CsvConfig::default()
  }
  let sb = StringBuilder()
  for i, row in doc {
    if i > 0 {
      sb.write_string("\r\n")
    }
    sb.write_string(row_to_string(row, config=cfg))
  }
  sb.to_string()
}
