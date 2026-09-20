///|
/// Unit separator char used to build dedup keys.
fn unit_sep() -> Char {
  Int::unsafe_to_char(31)
}

///|
/// Build a dedup key from a row by joining cells with a unit separator.
fn row_key(r : Array[String]) -> String {
  let buf = StringBuilder()
  for i in 0..<r.length() {
    if i > 0 {
      buf.write_char(unit_sep())
    }
    buf.write_string(r[i])
  }
  buf.to_string()
}

///|
/// Return a new `Table` with duplicate data rows removed, keeping the first
/// occurrence of each row. Header is preserved; row order is preserved.
pub fn Table::unique(self : Table) -> Table {
  let seen : Map[String, Bool] = Map([])
  let rows : Array[Array[String]] = []
  for r in self.rows {
    let k = row_key(r)
    if !seen.contains(k) {
      seen[k] = true
      rows.push(r)
    }
  }
  { headers: self.headers, rows }
}
