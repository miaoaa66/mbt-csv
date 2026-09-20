// Whitebox tests: run in package scope against the public API.

///|
test "basic parsing" {
  match parse("name,age,city\nAlice,30,NYC\nBob,25,LA") {
    Ok(doc) => {
      assert_eq(doc.length(), 3)
      assert_eq(doc[0][0], "name")
      assert_eq(doc[1][1], "30")
      assert_eq(doc[2][2], "LA")
    }
    Err(_) => fail("parse should succeed")
  }
}

///|
test "quoted field with comma" {
  match parse("product,price\n\"Widget, large\",19.99") {
    Ok(doc) => {
      assert_eq(doc[1][0], "Widget, large")
      assert_eq(doc[1][1], "19.99")
    }
    Err(_) => fail("parse should succeed")
  }
}

///|
test "escaped quotes inside quoted field" {
  match parse("\"She said \"\"hello\"\"\",end") {
    Ok(doc) => {
      assert_eq(doc[0][0], "She said \"hello\"")
      assert_eq(doc[0][1], "end")
    }
    Err(_) => fail("parse should succeed")
  }
}

///|
test "multiline quoted field" {
  match parse("a,b\n\"line1\nline2\",x") {
    Ok(doc) => {
      assert_eq(doc[1][0], "line1\nline2")
      assert_eq(doc[1][1], "x")
      // 3 source lines, but only 2 records
      assert_eq(doc.length(), 2)
    }
    Err(_) => fail("parse should succeed")
  }
}

///|
test "crlf row endings" {
  match parse("a,b\r\n1,2\r\n3,4\r\n") {
    Ok(doc) => {
      assert_eq(doc.length(), 3)
      assert_eq(doc[2][0], "3")
    }
    Err(_) => fail("parse should succeed")
  }
}

///|
test "trailing newline does not create empty record" {
  match parse("a,b\n1,2\n") {
    Ok(doc) => assert_eq(doc.length(), 2)
    Err(_) => fail("parse should succeed")
  }
}

///|
test "trailing delimiter keeps empty last field" {
  match parse("a,b\n1,") {
    Ok(doc) => {
      assert_eq(doc[1].length(), 2)
      assert_eq(doc[1][1], "")
    }
    Err(_) => fail("parse should succeed")
  }
}

///|
test "empty input" {
  match parse("") {
    Ok(doc) => assert_eq(doc.length(), 0)
    Err(_) => fail("parse should succeed")
  }
}

///|
test "blank line skipped by default and kept on demand" {
  match parse("a,b\n1,2\n\n3,4") {
    Ok(doc) => assert_eq(doc.length(), 3)
    Err(_) => fail("parse should succeed")
  }
  let cfg : CsvConfig = {
    delimiter: ',',
    quote: '"',
    skip_empty_lines: false,
  }
  match parse_with_config("a,b\n1,2\n\n3,4", cfg) {
    Ok(doc) => assert_eq(doc.length(), 4)
    Err(_) => fail("parse_with_config should succeed")
  }
}

///|
test "custom delimiter and tsv" {
  match parse_with_config("a;b;c\n1;2;3", CsvConfig::with_delimiter(';')) {
    Ok(doc) => {
      assert_eq(doc[1][2], "3")
    }
    Err(_) => fail("parse should succeed")
  }
  match parse_tsv("a\tb\n1\t2") {
    Ok(doc) => assert_eq(doc[1][1], "2")
    Err(_) => fail("parse_tsv should succeed")
  }
}

///|
test "unterminated quote error" {
  match parse("\"never closed") {
    Ok(_) => fail("parse should fail")
    Err(UnterminatedQuote(row, col)) => {
      assert_eq(row, 1)
      assert_true(col > 0)
    }
    Err(_) => fail("expected UnterminatedQuote")
  }
}

///|
test "writer escapes and roundtrips" {
  let doc : Array[Array[String]] = [
    ["name", "desc"],
    ["plain", "with, comma"],
    ["q\"uote", "multi\nline"],
  ]
  let out = document_to_string(doc)
  match parse(out) {
    Ok(back) => {
      assert_eq(back.length(), 3)
      assert_eq(back[1][1], "with, comma")
      assert_eq(back[2][0], "q\"uote")
      assert_eq(back[2][1], "multi\nline")
    }
    Err(_) => fail("roundtrip parse should succeed")
  }
}

///|
test "needs_quoting and escape_field" {
  let cfg = CsvConfig::default()
  assert_true(!needs_quoting("plain", cfg))
  assert_true(needs_quoting("a,b", cfg))
  assert_true(needs_quoting("say \"hi\"", cfg))
  assert_true(needs_quoting("a\nb", cfg))
  assert_eq(escape_field("plain", cfg), "plain")
  assert_eq(escape_field("a,b", cfg), "\"a,b\"")
  assert_eq(escape_field("a\"b", cfg), "\"a\"\"b\"")
}

///|
test "table from_document and parse_table" {
  match parse_table("id,name,score\n1,Alice,90\n2,Bob,85") {
    Ok(t) => {
      assert_eq(t.n_rows(), 2)
      assert_eq(t.n_cols(), 3)
      assert_eq(t.headers[1], "name")
      assert_eq(t.get(0, "name"), Some("Alice"))
      assert_eq(t.get(1, "score"), Some("85"))
      assert_eq(t.get(0, "missing"), None)
      assert_eq(t.get(9, "name"), None)
    }
    Err(_) => fail("parse_table should succeed")
  }
}

///|
test "table rejects ragged rows" {
  match parse_table("id,name\n1,Alice,extra") {
    Ok(_) => fail("parse_table should fail")
    Err(ColumnCountMismatch(row, expected, actual)) => {
      assert_eq(row, 1)
      assert_eq(expected, 2)
      assert_eq(actual, 3)
    }
    Err(_) => fail("expected ColumnCountMismatch")
  }
  match parse_table("") {
    Ok(_) => fail("parse_table should fail")
    Err(EmptyDocument) => assert_true(true)
    Err(_) => fail("expected EmptyDocument")
  }
}

///|
test "records with typed getters" {
  match parse_table("id,name,score\n1,Alice,90.5") {
    Ok(t) => {
      let recs = t.records()
      assert_eq(recs.length(), 1)
      let r = recs[0]
      assert_eq(r.get_str("name"), Ok("Alice"))
      assert_eq(r.get_int("id"), Ok(1))
      match r.get_double("score") {
        Ok(v) => assert_true((v - 90.5).abs() < 0.000000001)
        Err(_) => fail("get_double should succeed")
      }
      assert_eq(r.get_int("score"), Err("column 'score' is not an integer: '90.5'"))
      assert_eq(r.get_str("nope"), Err("missing column 'nope'"))
    }
    Err(_) => fail("parse_table should succeed")
  }
}

///|
test "filter by name" {
  match parse_table("name,age\nAlice,30\nBob,25\nCarol,35") {
    Ok(t) => {
      let adults = t.filter(
        fn(r) {
          match r.get_int("age") {
            Ok(v) => v >= 30
            Err(_) => false
          }
        },
      )
      assert_eq(adults.n_rows(), 2)
      assert_eq(adults.get(0, "name"), Some("Alice"))
      assert_eq(adults.get(1, "name"), Some("Carol"))
      // original table untouched
      assert_eq(t.n_rows(), 3)
    }
    Err(_) => fail("parse_table should succeed")
  }
}

///|
test "select columns" {
  match parse_table("a,b,c\n1,2,3") {
    Ok(t) =>
      match t.select(["c", "a"]) {
        Ok(t2) => {
          assert_eq(t2.headers[0], "c")
          assert_eq(t2.headers[1], "a")
          assert_eq(t2.rows[0][0], "3")
          assert_eq(t2.rows[0][1], "1")
        }
        Err(_) => fail("select should succeed")
      }
    Err(_) => fail("parse_table should succeed")
  }
  match parse_table("a,b\n1,2") {
    Ok(t) =>
      match t.select(["a", "zzz"]) {
        Ok(_) => fail("select should fail")
        Err(msg) => assert_eq(msg, "unknown column 'zzz'")
      }
    Err(_) => fail("parse_table should succeed")
  }
}

///|
test "to_csv_string roundtrip" {
  match parse_table("name,note\nA,\"has, comma\"\nB,plain") {
    Ok(t) => {
      let s = t.to_csv_string()
      assert_true(s.contains("\"has, comma\""))
      match parse_table(s) {
        Ok(t2) => {
          assert_eq(t2.n_rows(), 2)
          assert_eq(t2.get(0, "note"), Some("has, comma"))
        }
        Err(_) => fail("roundtrip should succeed")
      }
    }
    Err(_) => fail("parse_table should succeed")
  }
}

///|
test "lenient parsing skips damaged rows" {
  match parse_table_lenient("id,name\n1,Alice\nragged\n2,Bob") {
    Ok(res) => {
      assert_eq(res.table.n_rows(), 2)
      assert_eq(res.table.get(0, "name"), Some("Alice"))
      assert_eq(res.table.get(1, "name"), Some("Bob"))
      assert_eq(res.issues.length(), 1)
      assert_eq(res.issues[0].row, 2)
    }
    Err(_) => fail("parse_table_lenient should succeed")
  }
  // parse-level corruption still fails
  match parse_table_lenient("\"unterminated") {
    Ok(_) => fail("lenient parse should fail on corrupt input")
    Err(_) => assert_true(true)
  }
}

///|
test "error messages readable" {
  assert_eq(
    UnterminatedQuote(1, 5).message(),
    "unterminated quote at row 1, column 5",
  )
  assert_eq(ColumnCountMismatch(2, 3, 4).message(), "row 2 has 4 fields, expected 3")
}
