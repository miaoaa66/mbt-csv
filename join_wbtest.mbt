test "join_inner matches rows by key" {
  let left : Table = {
    headers: ["id", "name"],
    rows: [["1", "alice"], ["2", "bob"], ["3", "carol"]],
  }
  let right : Table = {
    headers: ["id", "score"],
    rows: [["2", "90"], ["1", "85"], ["4", "70"]],
  }
  let j = match left.join_inner(right, "id") {
    Ok(j) => j
    Err(m) => abort(m)
  }
  assert_eq(j.headers, ["id", "name", "score"])
  assert_eq(j.n_rows(), 2)
  assert_eq(j.rows[0], ["1", "alice", "85"])
  assert_eq(j.rows[1], ["2", "bob", "90"])
}

test "join_inner first occurrence wins on duplicate keys" {
  let left : Table = { headers: ["id"], rows: [["1"]] }
  let right : Table = {
    headers: ["id", "v"],
    rows: [["1", "first"], ["1", "second"]],
  }
  let j = match left.join_inner(right, "id") {
    Ok(j) => j
    Err(m) => abort(m)
  }
  assert_eq(j.rows[0], ["1", "first"])
}

test "join_inner missing key column errors" {
  let left : Table = { headers: ["id"], rows: [["1"]] }
  let right : Table = { headers: ["key", "v"], rows: [["1", "x"]] }
  assert_true(left.join_inner(right, "id") is Err(_))
  assert_true(left.join_inner(right, "key") is Err(_))
}
