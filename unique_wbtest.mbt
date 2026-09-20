test "unique removes duplicate rows keeping first occurrence" {
  let t : Table = {
    headers: ["a", "b"],
    rows: [["1", "x"], ["2", "y"], ["1", "x"], ["2", "y"], ["3", "z"]],
  }
  let u = t.unique()
  assert_eq(u.n_rows(), 3)
  assert_eq(u.rows[0], ["1", "x"])
  assert_eq(u.rows[1], ["2", "y"])
  assert_eq(u.rows[2], ["3", "z"])
}

test "unique keeps similar but distinct rows" {
  let t : Table = {
    headers: ["a", "b"],
    rows: [["1", "x"], ["1", "y"], ["11", "x"]],
  }
  assert_eq(t.unique().n_rows(), 3)
}

test "unique on table without duplicates is identity-sized" {
  let t : Table = { headers: ["a"], rows: [["1"], ["2"]] }
  assert_eq(t.unique().n_rows(), 2)
}
