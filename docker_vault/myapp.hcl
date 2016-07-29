path "secret/myapp/*" {
  policy = "read"
}

path "auth/token/create*" {
  policy = "write"
}

path "mysql/creds/readonly" {
  policy = "read"
}

path "mysql/roles/readonly" {
  policy = "read"
}
