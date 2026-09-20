///|
/// Tolerant double comparison for tests.
fn close(a : Double, b : Double) -> Bool {
  let d = a - b
  d < 0.000001 && -d < 0.000001
}

///|
test "numeric_summary computes stats over numeric column" {
  let t : Table = {
    headers: ["name", "age"],
    rows: [["a", "20"], ["b", "30"], ["c", "abc"], ["d", ""], ["e", "40"]],
  }
  let s = match t.numeric_summary("age") {
    Ok(s) => s
    Err(m) => abort(m)
  }
  assert_eq(s.column, "age")
  assert_eq(s.count, 3)
  assert_eq(s.skipped, 2)
  assert_true(close(s.min, 20.0))
  assert_true(close(s.max, 40.0))
  assert_true(close(s.mean, 30.0))
}

test "numeric_summary single value has zero stdev" {
  let t : Table = { headers: ["v"], rows: [["5"]] }
  let s = match t.numeric_summary("v") {
    Ok(s) => s
    Err(m) => abort(m)
  }
  assert_true(close(s.stdev, 0.0))
  assert_true(close(s.mean, 5.0))
}

test "numeric_summary column without numbers errors" {
  let t : Table = { headers: ["v"], rows: [["x"], ["y"]] }
  assert_true(t.numeric_summary("v") is Err(_))
}

test "numeric_summary missing column errors" {
  let t : Table = { headers: ["a"], rows: [["1"]] }
  assert_true(t.numeric_summary("nope") is Err(_))
}
