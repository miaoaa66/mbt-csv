///|
/// Append a new column `name` with the given `values` (one per data row).
///
/// Returns `Err` when the column name already exists or when `values`
/// length differs from the row count.
pub fn Table::add_column(
  self : Table,
  name : String,
  values : Array[String],
) -> Result[Table, String] {
  if self.column_index(name) is Some(_) {
    return Err("column '\{name}' already exists")
  }
  if values.length() != self.rows.length() {
    return Err(
      "got \{values.length()} values for \{self.rows.length()} rows",
    )
  }
  let headers : Array[String] = []
  for h in self.headers {
    headers.push(h)
  }
  headers.push(name)
  let rows : Array[Array[String]] = []
  for i in 0..<self.rows.length() {
    let nr : Array[String] = []
    for c in self.rows[i] {
      nr.push(c)
    }
    nr.push(values[i])
    rows.push(nr)
  }
  Ok({ headers, rows })
}
