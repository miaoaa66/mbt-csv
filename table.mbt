///|
/// A header-aware CSV table: the first parsed record is treated as the
/// header row, all remaining records as data rows.
pub struct Table {
  /// Header (column names).
  headers : Array[String]
  /// Data rows.
  rows : Array[Array[String]]
} derive(Debug)

///|
/// Build a `Table` from a parsed document.
///
/// Strict mode: every data row must have exactly as many fields as the
/// header, otherwise `Err(ColumnCountMismatch)` is returned. For damaged
/// files use `parse_table_lenient` instead.
pub fn Table::from_document(
  doc : Array[Array[String]],
) -> Result[Table, CsvError] {
  if doc.length() == 0 {
    return Err(EmptyDocument)
  }
  let header = doc[0]
  for i in 1..<doc.length() {
    let r = doc[i]
    if r.length() != header.length() {
      return Err(ColumnCountMismatch(i, header.length(), r.length()))
    }
  }
  let data : Array[Array[String]] = []
  for i in 1..<doc.length() {
    data.push(doc[i])
  }
  Ok({ headers: header, rows: data })
}

///|
/// Parse a CSV string directly into a `Table` (strict mode).
pub fn parse_table(
  input : String,
  config? : CsvConfig,
) -> Result[Table, CsvError] {
  let cfg = match config {
    Some(c) => c
    None => CsvConfig::default()
  }
  match parse_with_config(input, cfg) {
    Ok(doc) => Table::from_document(doc)
    Err(e) => Err(e)
  }
}

///|
/// Number of data rows (excluding the header).
pub fn Table::n_rows(self : Table) -> Int {
  self.rows.length()
}

///|
/// Number of columns.
pub fn Table::n_cols(self : Table) -> Int {
  self.headers.length()
}

///|
/// Index of a column by name, `None` when the column does not exist.
pub fn Table::column_index(self : Table, name : String) -> Int? {
  for i, h in self.headers {
    if h == name {
      return Some(i)
    }
  }
  None
}

///|
/// Cell value at `row_idx` (0-based data row) in column `name`.
/// Returns `None` when the row/column does not exist.
pub fn Table::get(self : Table, row_idx : Int, name : String) -> String? {
  match self.column_index(name) {
    Some(ci) =>
      match self.rows.get(row_idx) {
        Some(r) => r.get(ci)
        None => None
      }
    None => None
  }
}

///|
/// One data row together with the table headers, allowing by-name access.
pub struct Record {
  headers : Array[String]
  cells : Array[String]
} derive(Debug)

///|
/// Value of a column in this record; `None` when the column does not exist.
pub fn Record::get(self : Record, name : String) -> String? {
  for i, h in self.headers {
    if h == name {
      return self.cells.get(i)
    }
  }
  None
}

///|
/// String value of a column; `Err` with a message when missing.
pub fn Record::get_str(self : Record, name : String) -> Result[String, String] {
  match self.get(name) {
    Some(v) => Ok(v)
    None => Err("missing column '\{name}'")
  }
}

///|
/// Integer value of a column; `Err` when missing or not a valid integer.
pub fn Record::get_int(self : Record, name : String) -> Result[Int, String] {
  match self.get(name) {
    Some(v) => {
      let parsed = try {
        Ok(@string.parse_int(v))
      } catch {
        _ => Err("column '\{name}' is not an integer: '\{v}'")
      }
      parsed
    }
    None => Err("missing column '\{name}'")
  }
}

///|
/// Double value of a column; `Err` when missing or not a valid number.
pub fn Record::get_double(
  self : Record,
  name : String,
) -> Result[Double, String] {
  match self.get(name) {
    Some(v) => {
      let parsed = try {
        Ok(@string.parse_double(v))
      } catch {
        _ => Err("column '\{name}' is not a number: '\{v}'")
      }
      parsed
    }
    None => Err("missing column '\{name}'")
  }
}

///|
/// All data rows as `Record` values (by-name access).
pub fn Table::records(self : Table) -> Array[Record] {
  let out : Array[Record] = []
  for r in self.rows {
    out.push({ headers: self.headers, cells: r })
  }
  out
}

///|
/// Keep only the data rows whose `Record` satisfies `pred`.
/// The header is preserved.
pub fn Table::filter(self : Table, pred : (Record) -> Bool) -> Table {
  let kept : Array[Array[String]] = []
  for r in self.rows {
    let rec : Record = { headers: self.headers, cells: r }
    if pred(rec) {
      kept.push(r)
    }
  }
  { headers: self.headers, rows: kept }
}

///|
/// Keep only the given columns (in the given order).
/// Returns `Err` listing the first unknown column name.
pub fn Table::select(self : Table, cols : Array[String]) -> Result[Table, String] {
  let idx : Array[Int] = []
  for c in cols {
    match self.column_index(c) {
      Some(i) => idx.push(i)
      None => return Err("unknown column '\{c}'")
    }
  }
  let headers : Array[String] = []
  for i in idx {
    headers.push(self.headers[i])
  }
  let rows : Array[Array[String]] = []
  for r in self.rows {
    let nr : Array[String] = []
    for i in idx {
      nr.push(r[i])
    }
    rows.push(nr)
  }
  Ok({ headers: headers, rows: rows })
}

///|
/// Convert back to a plain document (header first).
pub fn Table::to_document(self : Table) -> Array[Array[String]] {
  let out : Array[Array[String]] = [self.headers]
  for r in self.rows {
    out.push(r)
  }
  out
}

///|
/// Serialize the table back to CSV text (header included).
pub fn Table::to_csv_string(self : Table, config? : CsvConfig) -> String {
  let cfg = match config {
    Some(c) => c
    None => CsvConfig::default()
  }
  document_to_string(self.to_document(), config=cfg)
}
