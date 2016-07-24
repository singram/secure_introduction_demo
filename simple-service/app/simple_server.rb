# -*- coding: utf-8 -*-
require 'sinatra'
require 'json'
require 'vault'
require 'pp'

# Unbind requests from localhost only
set :bind, '0.0.0.0'

Vault.address = "http://127.0.0.1:8200" # Also reads from ENV["VAULT_ADDR"]
#Vault.token   = "abcd-1234" # Also reads from ENV["VAULT_TOKEN"]

Vault.sys.mounts

pp Vault
pp Vault.sys.seal_status

get '/' do
  content_type 'application/json'
 {'tag_line' => "Hello world"}.to_json
end
