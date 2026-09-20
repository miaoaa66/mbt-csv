test "sort_by numeric ascending" {
  let t : Table = {
    headers: ["name", "age"],
    rows: [["bob", "30"], ["alice", "25"], ["carol", "9"]],
  }
  let s = match t.sort_by("age") {
    Ok(s) => s
    Err(m) => abort(m)
  }
  assert_eq(s.rows[0][0], "carol")
  assert_eq(s.rows[1][0], "alice")
  assert_eq(s.rows[2][0], "bob")
}

test "sort_by numeric beats lexicographic" {
  // Lexicographically "10" < "9", numerically "9" < "10".
  let t : Table = { headers: ["v"], rows: [["10"], ["9"], ["100"]] }
  let s = match t.sort_by("v") {
    Ok(s) => s
    Err(m) => abort(m)
  }
  assert_eq(s.rows[0][0], "9")
  assert_eq(s.rows[1][0], "10")
  assert_eq(s.rows[2][0], "100")
  let s2 = match t.sort_by("v", numeric=false) {
    Ok(s) => s
    Err(m) => abort(m)
  }
  assert_eq(s2.rows[0][0], "10")
  assert_eq(s2.rows[1][0], "100")
  assert_eq(s2.rows[2][0], "9")
}

test "sort_by falls back to string compare on non-numeric cells" {
  let t : Table = { headers: ["v"], rows: [["b"], ["10"], ["a"]] }
  let s = match t.sort_by("v") {
    Ok(s) => s
    Err(m) => abort(m)
  }
  // Codepoint order: digits ('1' = 49) sort before letters ('a' = 97).
  assert_eq(s.rows[0][0], "10")
  assert_eq(s.rows[1][0], "a")
  assert_eq(s.rows[2][0], "b")
}

test "sort_by missing column errors" {
  let t : Table = { headers: ["a"], rows: [["1"]] }
  assert_true(t.sort_by("nope") is Err(_))
}

test "sort_by is stable for equal keys" {
  let t : Table = {
    headers: ["k", "tag"],
    rows: [["1", "first"], ["1", "second"], ["0", "zero"]],
  }
  let s = match t.sort_by("k") {
    Ok(s) => s
    Err(m) => abort(m)
  }
  assert_eq(s.rows[0][1], "zero")
  assert_eq(s.rows[1][1], "first")
  assert_eq(s.rows[2][1], "second")
}
