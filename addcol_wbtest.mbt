test "add_column appends values" {
  let t : Table = { headers: ["a"], rows: [["1"], ["2"]] }
  let r = match t.add_column("b", ["x", "y"]) {
    Ok(r) => r
    Err(m) => abort(m)
  }
  assert_eq(r.headers, ["a", "b"])
  assert_eq(r.rows[0], ["1", "x"])
  assert_eq(r.rows[1], ["2", "y"])
}

test "add_column on empty table works" {
  let t : Table = { headers: ["a"], rows: [] }
  let r = match t.add_column("b", []) {
    Ok(r) => r
    Err(m) => abort(m)
  }
  assert_eq(r.headers, ["a", "b"])
  assert_eq(r.n_rows(), 0)
}

test "add_column duplicate name errors" {
  let t : Table = { headers: ["a"], rows: [["1"]] }
  assert_true(t.add_column("a", ["x"]) is Err(_))
}

test "add_column wrong value count errors" {
  let t : Table = { headers: ["a"], rows: [["1"], ["2"]] }
  assert_true(t.add_column("b", ["x"]) is Err(_))
}
