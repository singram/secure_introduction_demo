# -*- coding: utf-8 -*-
require 'json'
require 'mysql2'
require 'pp'
require 'rufus-scheduler'
require 'vault'

scheduler = Rufus::Scheduler.new

Vault.address = "http://127.0.0.1:8201" # Also reads from ENV["VAULT_ADDR"]
#Vault.token   = "abcd-1234" # Also reads from ENV["VAULT_TOKEN"]

p "Initial secure introduction token is '#{ENV["VAULT_SI_TOKEN"]}'"
begin
  Vault.token = Vault.logical.unwrap_token(ENV["VAULT_SI_TOKEN"])
  p "DONT DO THIS AT HOME.  NEW SECRET TOKEN -> '#{Vault.token}'"
rescue => e
  p "SECURITY BREACH!! Token intercepted or expired"
  exit
end

scheduler.every '5m' do
  unless Vault.token.nil?
    p "Renewing application token"
    pp Vault.auth_token.lookup_self
    Vault.auth_token.renew_self
  end
end

class DatabaseInteractions

  attr_accessor :database_creds, :client

  def initialize
    p "Read some database configuration secrets!"
    db_conf = Vault.logical.read('secret/myapp/db').data
    @host = db_conf[:host]
    @port = db_conf[:port]
    get_creds
  end

  def client
    @client ||= Mysql2::Client.new(:host => @host,
                                   :port => @port,
                                   :username => @database_creds.data[:username],
                                   :password => @database_creds.data[:password])
  end

  def username
    @database_creds.data[:username]
  end

  def get_creds
    p "Requesting new database credentials"
    @database_creds =  Vault.logical.read('mysql/creds/readonly')
  end

  def renew_creds
    p "Renewing database credentials"
    Vault.auth_token.renew(@database_creds.lease_id)
  end

end

db = DatabaseInteractions.new

results = db.client.query("SELECT NOW();")
pp results.first

at_exit {
  Vault.auth_token.revoke_self
  p "Revoking application token"
  p "Revoking database creds - #{db.username} - leaseid #{db.database_creds.lease_id}"
}

require 'sinatra'

# Unbind requests from localhost only
set :bind, '0.0.0.0'

get '/' do
  content_type 'application/json'
 {'tag_line' => "Hello world"}.to_json
end
