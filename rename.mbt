///|
/// Rename column `old` to `new`.
///
/// Returns `Err` when `old` does not exist or `new` is already taken.
pub fn Table::rename_column(
  self : Table,
  old : String,
  new : String,
) -> Result[Table, String] {
  if old == new {
    return Ok(self)
  }
  let idx = match self.column_index(old) {
    Some(i) => i
    None => return Err("no column named '\{old}'")
  }
  if self.column_index(new) is Some(_) {
    return Err("column '\{new}' already exists")
  }
  let headers : Array[String] = []
  for i in 0..<self.headers.length() {
    if i == idx {
      headers.push(new)
    } else {
      headers.push(self.headers[i])
    }
  }
  Ok({ headers, rows: self.rows })
}
