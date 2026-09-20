///|
/// Descriptive statistics for one numeric column.
pub struct ColumnStats {
  column : String
  /// Number of data rows with a parseable numeric value.
  count : Int
  /// Number of data rows skipped (missing or non-numeric).
  skipped : Int
  min : Double
  max : Double
  mean : Double
  /// Population standard deviation.
  stdev : Double
} derive(Debug, Eq)

///|
/// Compute descriptive statistics over a numeric column.
///
/// Non-numeric and empty cells are counted as `skipped` rather than failing.
/// Returns `Err` when the column does not exist or when no row carries a
/// numeric value.
pub fn Table::numeric_summary(
  self : Table,
  col : String,
) -> Result[ColumnStats, String] {
  let idx = match self.column_index(col) {
    Some(i) => i
    None => return Err("no column named '\{col}'")
  }
  let nums : Array[Double] = []
  let mut skipped = 0
  for row in self.rows {
    match parse_num(row[idx]) {
      Some(v) => nums.push(v)
      None => skipped += 1
    }
  }
  let n = nums.length()
  if n == 0 {
    return Err("column '\{col}' has no numeric values")
  }
  let mut sum = 0.0
  let mut mn = nums[0]
  let mut mx = nums[0]
  for v in nums {
    sum += v
    if v < mn {
      mn = v
    }
    if v > mx {
      mx = v
    }
  }
  let mean = sum / n.to_double()
  let mut sq = 0.0
  for v in nums {
    let d = v - mean
    sq += d * d
  }
  let variance = sq / n.to_double()
  let stdev = variance.sqrt()
  Ok({
    column: col,
    count: n,
    skipped,
    min: mn,
    max: mx,
    mean,
    stdev,
  })
}
