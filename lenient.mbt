///|
/// A problem found while parsing a damaged file in lenient mode.
pub struct LenientIssue {
  /// 1-based index of the offending record inside the parsed document
  /// (1 is the header row).
  row : Int
  /// What was wrong with it.
  reason : String
} derive(Debug)

///|
/// Result of lenient parsing: a well-formed `Table` plus a list of skipped
/// records.
pub struct LenientResult {
  table : Table
  issues : Array[LenientIssue]
} derive(Debug)

///|
/// Parse a CSV string into a `Table`, **skipping** data rows whose field
/// count does not match the header instead of failing.
///
/// This is the recommended entry point for real-world files: it never loses
/// valid data, and every skipped row is reported in `issues` so callers can
/// log or display it. Parse-level corruption (e.g. an unterminated quote)
/// still fails with `Err(CsvError)`.
pub fn parse_table_lenient(
  input : String,
  config? : CsvConfig,
) -> Result[LenientResult, CsvError] {
  let cfg = match config {
    Some(c) => c
    None => CsvConfig::default()
  }
  let doc = match parse_with_config(input, cfg) {
    Ok(d) => d
    Err(e) => return Err(e)
  }
  if doc.length() == 0 {
    return Err(EmptyDocument)
  }
  let header = doc[0]
  let data : Array[Array[String]] = []
  let issues : Array[LenientIssue] = []
  for i in 1..<doc.length() {
    let r = doc[i]
    if r.length() == header.length() {
      data.push(r)
    } else {
      issues.push({
        row: i,
        reason: "skipped: got \{r.length()} fields, expected \{header.length()}",
      })
    }
  }
  Ok({ table: { headers: header, rows: data }, issues: issues })
}
