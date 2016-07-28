path "secret/myapp/*" {
  policy = "read"
}

path "mysql/creds/readonly" {
  policy = "read"
}

path "mysql/roles/readonly" {
  policy = "read"
}
