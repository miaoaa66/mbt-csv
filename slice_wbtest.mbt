test "head returns first n rows" {
  let t : Table = {
    headers: ["a", "b"],
    rows: [["1", "x"], ["2", "y"], ["3", "z"]],
  }
  let h = t.head(2)
  assert_eq(h.n_rows(), 2)
  assert_eq(h.rows[0][0], "1")
  assert_eq(h.rows[1][0], "2")
  assert_eq(h.headers, t.headers)
}

test "head clamps beyond row count" {
  let t : Table = { headers: ["a"], rows: [["1"], ["2"]] }
  assert_eq(t.head(10).n_rows(), 2)
  assert_eq(t.head(0).n_rows(), 0)
  assert_eq(t.head(-1).n_rows(), 0)
}

test "tail returns last n rows" {
  let t : Table = {
    headers: ["a", "b"],
    rows: [["1", "x"], ["2", "y"], ["3", "z"]],
  }
  let l = t.tail(2)
  assert_eq(l.n_rows(), 2)
  assert_eq(l.rows[0][0], "2")
  assert_eq(l.rows[1][0], "3")
}

test "tail clamps beyond row count" {
  let t : Table = { headers: ["a"], rows: [["1"], ["2"]] }
  assert_eq(t.tail(10).n_rows(), 2)
  assert_eq(t.tail(0).n_rows(), 0)
}
