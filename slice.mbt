///|
/// First `n` data rows as a new `Table` (header preserved).
/// `n <= 0` yields a table with no data rows; `n` beyond the row count
/// is clamped to all rows.
pub fn Table::head(self : Table, n : Int) -> Table {
  let len = self.rows.length()
  let limit = if n < 0 {
    0
  } else if n > len {
    len
  } else {
    n
  }
  let out : Array[Array[String]] = []
  for i in 0..<limit {
    out.push(self.rows[i])
  }
  { headers: self.headers, rows: out }
}

///|
/// Last `n` data rows as a new `Table` (header preserved).
/// `n <= 0` yields a table with no data rows; `n` beyond the row count
/// is clamped to all rows.
pub fn Table::tail(self : Table, n : Int) -> Table {
  let len = self.rows.length()
  let start = if n <= 0 {
    len
  } else if n > len {
    0
  } else {
    len - n
  }
  let out : Array[Array[String]] = []
  for i in start..<len {
    out.push(self.rows[i])
  }
  { headers: self.headers, rows: out }
}
