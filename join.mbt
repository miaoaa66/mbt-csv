///|
/// Inner-join two tables on column `key`.
///
/// The result keeps all columns of `self` plus the columns of `other`
/// excluding its key column. Rows are matched by exact key value; rows
/// without a match on either side are dropped. When `other` has duplicate
/// keys, the first occurrence wins.
///
/// Returns `Err` when `key` is missing from either table.
pub fn Table::join_inner(
  self : Table,
  other : Table,
  key : String,
) -> Result[Table, String] {
  let l = match self.column_index(key) {
    Some(i) => i
    None => return Err("no column named '\{key}' in left table")
  }
  let r = match other.column_index(key) {
    Some(i) => i
    None => return Err("no column named '\{key}' in right table")
  }
  let headers : Array[String] = []
  for h in self.headers {
    headers.push(h)
  }
  for i in 0..<other.headers.length() {
    if i != r {
      headers.push(other.headers[i])
    }
  }
  let index : Map[String, Array[String]] = Map([])
  for row in other.rows {
    let k = row[r]
    if !index.contains(k) {
      index[k] = row
    }
  }
  let rows : Array[Array[String]] = []
  for row in self.rows {
    match index.get(row[l]) {
      Some(matched) => {
        let nr : Array[String] = []
        for c in row {
          nr.push(c)
        }
        for i in 0..<matched.length() {
          if i != r {
            nr.push(matched[i])
          }
        }
        rows.push(nr)
      }
      None => ()
    }
  }
  Ok({ headers, rows })
}
