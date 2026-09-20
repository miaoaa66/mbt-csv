test "rename_column renames the header" {
  let t : Table = { headers: ["a", "b"], rows: [["1", "2"]] }
  let r = match t.rename_column("a", "x") {
    Ok(r) => r
    Err(m) => abort(m)
  }
  assert_eq(r.headers, ["x", "b"])
  assert_eq(r.rows[0], ["1", "2"])
}

test "rename_column to same name is a no-op" {
  let t : Table = { headers: ["a", "b"], rows: [["1", "2"]] }
  assert_true(t.rename_column("a", "a") is Ok(_))
}

test "rename_column missing column errors" {
  let t : Table = { headers: ["a"], rows: [["1"]] }
  assert_true(t.rename_column("nope", "x") is Err(_))
}

test "rename_column to existing name errors" {
  let t : Table = { headers: ["a", "b"], rows: [["1", "2"]] }
  assert_true(t.rename_column("a", "b") is Err(_))
}
