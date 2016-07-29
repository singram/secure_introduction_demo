# -*- coding: utf-8 -*-
require 'json'
require 'mysql2'
require 'pp'
require 'rufus-scheduler'
require 'vault'


Vault.address = "http://127.0.0.1:8201" # Also reads from ENV["VAULT_ADDR"]
#Vault.token   = "abcd-1234" # Also reads from ENV["VAULT_TOKEN"]

#===================================
# Secure Introduction of application
#===================================

p "Initial secure introduction token is '#{ENV["VAULT_SI_TOKEN"]}'"
begin
  Vault.token = Vault.logical.unwrap_token(ENV["VAULT_SI_TOKEN"])
  p "DONT DO THIS AT HOME.  NEW SECRET TOKEN -> '#{Vault.token}'"
rescue => e
  p "SECURITY BREACH!! Token intercepted or expired"
  exit
end

#===================================
# Renew the main token lease appropriately
#===================================

scheduler = Rufus::Scheduler.new

# Renew the lease of the main application token
scheduler.every '1m' do
  unless Vault.token.nil?
    current_token = Vault.auth_token.lookup_self
    p "Renewing application token lease - ttl til rotation #{current_token.data[:ttl]}"
    if current_token.data[:ttl] < 60*5
      new_token = Vault.auth_token.create({"policies":["myapp"],
                                           "display_name":"myapp",
                                           "num_uses":0,
                                           "renewable":true})
      if new_token.auth
        old_token = Vault.token
        Vault.token = new_token.auth.client_token
        Vault.auth_token.revoke_tree(old_token)
      end
    else
      Vault.auth_token.renew_self
    end
  end
end

#===================================
# Database credential & connection wrapper
#===================================

class DatabaseInteractions

  def initialize
    p "Read some database configuration secrets!"
    db_conf = Vault.logical.read('secret/myapp/db').data
    @host = db_conf[:host]
    @port = db_conf[:port]
  end

  def client
    @client ||= Mysql2::Client.new(:host => @host,
                                   :port => @port,
                                   :username => username,
                                   :password => creds.data[:password])
  end

  def username
    creds.data[:username]
  end

  def creds
    @creds ||=  Vault.logical.read('mysql/creds/readonly')
  end

  def rotate_creds
    p "Lazy rotating database credentials"
    @creds = nil
    @client = nil
  end

  def renew_cred_lease
    p "Renewing database credential lease"
    Vault.auth_token.renew(creds.lease_id)
  rescue => e
    p 'Database credential lease renewal failed.'
    rotate_creds
  end

  def time
    results = client.query("SELECT NOW();")
    results.first
  end

end

db = DatabaseInteractions.new

pp db.time


#===================================
# Register handler to revoke application token
# This will also revoke any database creds under this token
#===================================

at_exit {
  Vault.auth_token.revoke_self
  p "Revoking application token"
  p "Revoking database creds - #{db.username} - leaseid #{db.creds.lease_id}"
}


#===================================
# "Example" App
#===================================



require 'sinatra'

# Unbind requests from localhost only
set :bind, '0.0.0.0'

get '/' do
  content_type 'application/json'
 {'time' => db.time.to_s}.to_json
end
