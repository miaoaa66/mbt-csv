///|
/// Parse a string as a double; `None` when not numeric.
fn parse_num(s : String) -> Double? {
  try {
    Some(@string.parse_double(s))
  } catch {
    _ => None
  }
}

///|
/// Compare two strings numerically when both parse as doubles, otherwise
/// lexicographically.
fn cmp_mixed(a : String, b : String) -> Int {
  match (parse_num(a), parse_num(b)) {
    (Some(x), Some(y)) =>
      if x < y {
        -1
      } else if x > y {
        1
      } else {
        0
      }
    _ => cmp_str(a, b)
  }
}

///|
/// Compare two strings codepoint-wise (true lexicographic order).
///
/// NOTE: MoonBit's built-in `String` comparison operators (`<`, `>`) are
/// length-first (shorter string compares smaller), NOT lexicographic, so we
/// must compare character by character ourselves.
fn cmp_str(a : String, b : String) -> Int {
  let ab = a.to_array()
  let bb = b.to_array()
  let n = if ab.length() < bb.length() {
    ab.length()
  } else {
    bb.length()
  }
  for i in 0..<n {
    let ca = ab[i].to_int()
    let cb = bb[i].to_int()
    if ca < cb {
      return -1
    }
    if ca > cb {
      return 1
    }
  }
  if ab.length() < bb.length() {
    -1
  } else if ab.length() > bb.length() {
    1
  } else {
    0
  }
}

///|
/// Return a new `Table` with data rows sorted by the values of `col`.
///
/// With `numeric~ = true` (default) rows are compared numerically when both
/// values parse as doubles, falling back to string comparison otherwise.
/// With `numeric~ = false` rows are compared lexicographically.
///
/// Returns `Err` when the column does not exist. The sort is stable: rows
/// with equal keys keep their original relative order.
pub fn Table::sort_by(
  self : Table,
  col : String,
  numeric? : Bool = true,
) -> Result[Table, String] {
  let idx = match self.column_index(col) {
    Some(i) => i
    None => return Err("no column named '\{col}'")
  }
  let cmp = if numeric { cmp_mixed } else { cmp_str }
  let out : Array[Array[String]] = []
  for r in self.rows {
    out.push(r)
  }
  // Decorate-sort-undecorate with the original position as tie breaker to
  // guarantee stability without relying on the sort implementation.
  let n = out.length()
  let decorated : Array[(Array[String], Int)] = []
  for i in 0..<n {
    decorated.push((out[i], i))
  }
  decorated.sort_by(fn(a, b) {
    let c = cmp(a.0[idx], b.0[idx])
    if c == 0 {
      a.1 - b.1
    } else {
      c
    }
  })
  let sorted : Array[Array[String]] = []
  for d in decorated {
    sorted.push(d.0)
  }
  Ok({ headers: self.headers, rows: sorted })
}
