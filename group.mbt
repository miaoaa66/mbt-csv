///|
/// A key value with the number of rows carrying it, in first-appearance
/// order.
pub struct KeyCount {
  key : String
  count : Int
} derive(Debug, Eq)

///|
/// Count data rows per distinct value of column `key`.
///
/// Results are ordered by first appearance of each key value in the table.
/// Returns `Err` when the column does not exist.
pub fn Table::group_count(
  self : Table,
  key : String,
) -> Result[Array[KeyCount], String] {
  let idx = match self.column_index(key) {
    Some(i) => i
    None => return Err("no column named '\{key}'")
  }
  let order : Array[String] = []
  let counts : Map[String, Int] = Map([])
  for row in self.rows {
    let k = row[idx]
    match counts.get(k) {
      Some(c) => counts[k] = c + 1
      None => {
        counts[k] = 1
        order.push(k)
      }
    }
  }
  let out : Array[KeyCount] = []
  for k in order {
    match counts.get(k) {
      Some(c) => out.push({ key: k, count: c })
      None => ()
    }
  }
  Ok(out)
}
