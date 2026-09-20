///|
/// Remove column `name` from the table.
///
/// Returns `Err` when the column does not exist, or when it is the only
/// column left (a CSV table always has at least one column).
pub fn Table::drop_column(
  self : Table,
  name : String,
) -> Result[Table, String] {
  let idx = match self.column_index(name) {
    Some(i) => i
    None => return Err("no column named '\{name}'")
  }
  if self.headers.length() == 1 {
    return Err("cannot drop the only column '\{name}'")
  }
  let headers : Array[String] = []
  for i in 0..<self.headers.length() {
    if i != idx {
      headers.push(self.headers[i])
    }
  }
  let rows : Array[Array[String]] = []
  for r in self.rows {
    let nr : Array[String] = []
    for i in 0..<r.length() {
      if i != idx {
        nr.push(r[i])
      }
    }
    rows.push(nr)
  }
  Ok({ headers, rows })
}
