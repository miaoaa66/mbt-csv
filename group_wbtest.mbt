test "group_count counts rows per key in first-appearance order" {
  let t : Table = {
    headers: ["cat", "v"],
    rows: [
      ["fruit", "apple"],
      ["veg", "leek"],
      ["fruit", "pear"],
      ["meat", "ham"],
      ["fruit", "plum"],
    ],
  }
  let g = match t.group_count("cat") {
    Ok(g) => g
    Err(m) => abort(m)
  }
  assert_eq(g.length(), 3)
  assert_eq(g[0].key, "fruit")
  assert_eq(g[0].count, 3)
  assert_eq(g[1].key, "veg")
  assert_eq(g[1].count, 1)
  assert_eq(g[2].key, "meat")
  assert_eq(g[2].count, 1)
}

test "group_count on empty table returns empty array" {
  let t : Table = { headers: ["cat"], rows: [] }
  let g = match t.group_count("cat") {
    Ok(g) => g
    Err(m) => abort(m)
  }
  assert_eq(g.length(), 0)
}

test "group_count missing column errors" {
  let t : Table = { headers: ["a"], rows: [["1"]] }
  assert_true(t.group_count("nope") is Err(_))
}
