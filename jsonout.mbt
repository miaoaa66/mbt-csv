///|
/// Escape a string per RFC 8259 (JSON) string rules.
fn json_escape(s : String) -> String {
  let buf = StringBuilder()
  for ch in s {
    let code = ch.to_int()
    if ch == '"' {
      buf.write_string("\\\"")
    } else if ch == '\\' {
      buf.write_string("\\\\")
    } else if ch == '\n' {
      buf.write_string("\\n")
    } else if ch == '\r' {
      buf.write_string("\\r")
    } else if ch == '\t' {
      buf.write_string("\\t")
    } else if code < 32 {
      buf.write_string("\\u")
      let hex : Array[Char] = [
        '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd',
        'e', 'f',
      ]
      buf.write_char(hex[(code >> 12) & 0xf])
      buf.write_char(hex[(code >> 8) & 0xf])
      buf.write_char(hex[(code >> 4) & 0xf])
      buf.write_char(hex[code & 0xf])
    } else {
      buf.write_char(ch)
    }
  }
  buf.to_string()
}

///|
/// Serialize the table as a JSON array of objects (one object per data row,
/// keyed by header name). Cell values are emitted as JSON strings.
///
/// This is a hand-rolled RFC 8259 writer to keep the package dependency-free.
pub fn Table::to_json_string(self : Table) -> String {
  let buf = StringBuilder()
  buf.write_char('[')
  for i in 0..<self.rows.length() {
    if i > 0 {
      buf.write_char(',')
    }
    buf.write_char('{')
    let row = self.rows[i]
    for c in 0..<self.headers.length() {
      if c > 0 {
        buf.write_char(',')
      }
      buf.write_char('"')
      buf.write_string(json_escape(self.headers[c]))
      buf.write_string("\":")
      buf.write_char('"')
      buf.write_string(json_escape(row[c]))
      buf.write_char('"')
    }
    buf.write_char('}')
  }
  buf.write_char(']')
  buf.to_string()
}
