test "drop_column removes header and cells" {
  let t : Table = {
    headers: ["a", "b", "c"],
    rows: [["1", "2", "3"], ["4", "5", "6"]],
  }
  let r = match t.drop_column("b") {
    Ok(r) => r
    Err(m) => abort(m)
  }
  assert_eq(r.headers, ["a", "c"])
  assert_eq(r.rows[0], ["1", "3"])
  assert_eq(r.rows[1], ["4", "6"])
}

test "drop_column missing column errors" {
  let t : Table = { headers: ["a"], rows: [["1"]] }
  assert_true(t.drop_column("nope") is Err(_))
}

test "drop_column refuses to drop the last column" {
  let t : Table = { headers: ["a"], rows: [["1"]] }
  assert_true(t.drop_column("a") is Err(_))
}
