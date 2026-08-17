run "normalizes_name" {
  command = apply

  variables {
    name = "  FooBar  "
  }

  assert {
    condition     = output.normalized == "foobar"
    error_message = "normalized deve ser lowercase sem espacos"
  }
}
