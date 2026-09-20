test "to_json_string emits array of objects" {
  let t : Table = {
    headers: ["name", "age"],
    rows: [["alice", "30"], ["bob", "25"]],
  }
  assert_eq(
    t.to_json_string(),
    "[{\"name\":\"alice\",\"age\":\"30\"},{\"name\":\"bob\",\"age\":\"25\"}]",
  )
}

test "to_json_string escapes special characters" {
  let t : Table = {
    headers: ["q"],
    rows: [["say \"hi\"\nline\ttab\\path"]],
  }
  assert_eq(
    t.to_json_string(),
    "[{\"q\":\"say \\\"hi\\\"\\nline\\ttab\\\\path\"}]",
  )
}

test "to_json_string on empty table yields empty array" {
  let t : Table = { headers: ["a"], rows: [] }
  assert_eq(t.to_json_string(), "[]")
}
