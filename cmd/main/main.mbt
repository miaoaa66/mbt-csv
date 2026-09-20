///|
/// Split a string on whitespace, commas and semicolons.
fn tokens_of(s : String) -> Array[String] {
  let out : Array[String] = []
  let buf = StringBuilder()
  for ch in s {
    if ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r' || ch == ',' || ch == ';' {
      if buf.to_string().length() > 0 {
        out.push(buf.to_string())
        buf.reset()
      }
    } else {
      buf.write_char(ch)
    }
  }
  if buf.to_string().length() > 0 {
    out.push(buf.to_string())
  }
  out
}

///|
/// Simple substring search without extra dependencies.
fn str_contains(haystack : String, needle : String) -> Bool {
  let hlen = haystack.length()
  let nlen = needle.length()
  if nlen == 0 {
    return true
  }
  if nlen > hlen {
    return false
  }
  let h = haystack.to_array()
  let nd = needle.to_array()
  for i in 0..<(hlen - nlen + 1) {
    let mut ok = true
    for j in 0..<nlen {
      if h[i + j] != nd[j] {
        ok = false
        break
      }
    }
    if ok {
      return true
    }
  }
  false
}

///|
/// Parse an integer, returns -1 on failure (sufficient for CLI indices).
fn parse_int_or(s : String, fallback : Int) -> Int {
  let mut value = 0
  let mut sign = 1
  let chars = s.to_array()
  let mut i = 0
  if chars.length() > 0 && (chars[0] == '-' || chars[0] == '+') {
    if chars[0] == '-' {
      sign = -1
    }
    i = 1
  }
  if i >= chars.length() {
    return fallback
  }
  for k in i..<chars.length() {
    let cc = chars[k].to_int()
    if cc < 48 || cc > 57 {
      return fallback
    }
    value = value * 10 + (cc - 48)
  }
  sign * value
}

///|
/// Build the filter predicate for `filter <col> <op> <value>`.
fn make_pred(
  col : String,
  op : String,
  value : String,
) -> ((@csv.Record) -> Bool) {
  fn(r : @csv.Record) -> Bool {
    match r.get(col) {
      Some(v) =>
        match op {
          "eq" => v == value
          "ne" => v != value
          "contains" => str_contains(v, value)
          "gt" =>
            match (try? @str.parse_double(v), try? @str.parse_double(value)) {
              (Ok(a), Ok(b)) => a > b
              _ => v > value
            }
          "lt" =>
            match (try? @str.parse_double(v), try? @str.parse_double(value)) {
              (Ok(a), Ok(b)) => a < b
              _ => v < value
            }
          _ => {
            println("error: unknown operator '\{op}' (use eq/ne/gt/lt/contains)")
            false
          }
        }
      None => false
    }
  }
}

///|
fn print_usage() -> Unit {
  println("mbt-csv - CSV parsing, filtering and export")
  println("")
  println("Usage: mbt-csv <command> <file.csv> [args...]")
  println("")
  println("Commands:")
  println("  info <file>                      show headers and dimensions")
  println("  head <file> [n]                  first n data rows (default 5)")
  println("  get <file> <row> <col>           one cell (row is 0-based)")
  println("  filter <file> <col> <op> <val>   print matching rows")
  println("                                   ops: eq | ne | gt | lt | contains")
  println("  select <file> <col1,col2,...>    print only the given columns")
  println("  lenient <file>                   parse and report skipped damaged rows")
}

///|
/// Load a file as a lenient table; prints warnings/errors and returns None
/// when the file cannot be used.
fn load_table(path : String) -> @csv.Table? raise {
  let content = try? @fs.read_file_to_string(path)
  let text = match content {
    Ok(t) => t
    Err(_) => {
      println("error: cannot read file '\{path}'")
      return None
    }
  }
  match @csv.parse_table_lenient(text) {
    Ok(res) => {
      for issue in res.issues {
        println("warning: record \{issue.row}: \{issue.reason}")
      }
      Some(res.table)
    }
    Err(e) => {
      println("error: \{e.message()}")
      None
    }
  }
}

///|
fn main raise {
  let args = @env.args()
  let rest : Array[String] = []
  for i in 1..<args.length() {
    rest.push(args[i])
  }
  if rest.length() == 0 {
    print_usage()
    return
  }
  let cmd = rest[0]
  if cmd == "-h" || cmd == "--help" {
    print_usage()
    return
  }
  if rest.length() < 2 {
    println("error: missing file argument")
    return
  }
  let path = rest[1]
  let table = match load_table(path) {
    Some(t) => t
    None => return
  }
  match cmd {
    "info" => {
      println("file    : \{path}")
      println("columns : \{table.n_cols()}")
      println("rows    : \{table.n_rows()}")
      println("headers : \{@csv.row_to_string(table.headers)}")
    }
    "head" => {
      let n = if rest.length() >= 3 { parse_int_or(rest[2], 5) } else { 5 }
      println(@csv.row_to_string(table.headers))
      let limit = if n < table.n_rows() { n } else { table.n_rows() }
      for i in 0..<limit {
        println(@csv.row_to_string(table.rows[i]))
      }
    }
    "get" => {
      if rest.length() < 4 {
        println("error: usage: get <file> <row> <col>")
        return
      }
      let row_idx = parse_int_or(rest[2], -1)
      match table.get(row_idx, rest[3]) {
        Some(v) => println(v)
        None => println("error: no cell at row \{row_idx}, column '\{rest[3]}'")
      }
    }
    "filter" => {
      if rest.length() < 5 {
        println("error: usage: filter <file> <col> <op> <value>")
        return
      }
      let pred = make_pred(rest[2], rest[3], rest[4])
      let kept = table.filter(pred)
      println(@csv.row_to_string(kept.headers))
      for r in kept.rows {
        println(@csv.row_to_string(r))
      }
    }
    "select" => {
      if rest.length() < 3 {
        println("error: usage: select <file> <col1,col2,...>")
        return
      }
      let cols = tokens_of(rest[2])
      match table.select(cols) {
        Ok(t2) => println(t2.to_csv_string())
        Err(msg) => println("error: \{msg}")
      }
    }
    "lenient" => {
      let content = try? @fs.read_file_to_string(path)
      match content {
        Err(_) => {
          println("error: cannot read file '\{path}'")
          return
        }
        Ok(text) =>
          match @csv.parse_table_lenient(text) {
            Ok(res) => {
              println("parsed rows : \{res.table.n_rows()}")
              println("skipped     : \{res.issues.length()}")
              for issue in res.issues {
                println("  record \{issue.row}: \{issue.reason}")
              }
            }
            Err(e) => println("error: \{e.message()}")
          }
      }
    }
    _ => println("error: unknown command '\{cmd}' (try --help)")
  }
}
