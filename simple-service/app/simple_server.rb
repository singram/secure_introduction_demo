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

unless ENV["VAULT_SI_TOKEN"]
  puts "ERROR!! No wrapped secure introduction token supplied in VAULT_SI_TOKEN"
  exit
end

wrapper_token = Vault::WrapInfo.new(JSON.parse(ENV["VAULT_SI_TOKEN"], symbolize_names: true)[:wrap_info] )

puts "Initial secure introduction token is '#{wrapper_token.token}'"
begin
  Vault.token = Vault.logical.unwrap_token(wrapper_token.token)
  puts "DONT DO THIS AT HOME.  NEW SECRET TOKEN -> '#{Vault.token}'"
rescue => e
  if Time.now < wrapper_token.creation_time + wrapper_token.ttl
    puts "SECURITY BREACH!! Token intercepted!!!"
  else
    stale_seconds = Time.now() - (wrapper_token.creation_time + wrapper_token.ttl)
    puts "Token expired by #{stale_seconds.to_i} seconds!!!"
  end
  exit
end

def renew_application_token
  puts "Renewing application token lease"
  Vault.auth_token.renew_self
end

def rotate_application_token
  puts "Rotating application token"
  new_token = Vault.auth_token.create_orphan({"policies":["myapp"],
                                              "display_name":"myapp",
                                              "num_uses":0,
                                              "renewable":true})
  if new_token.auth
    Vault.auth_token.revoke_self
    Vault.token = new_token.auth.client_token
    puts "DONT DO THIS AT HOME.  NEW SECRET TOKEN -> '#{Vault.token}'"
  end
end

#===================================
# Renew the main token lease appropriately
#===================================

scheduler = Rufus::Scheduler.new

# Renew the lease of the main application token
scheduler.every '59s' do
  unless Vault.token.nil?
    begin
      print "Checking token #{Vault.token}"
      current_token = Vault.auth_token.lookup_self
      puts " - ttl til rotation #{current_token.data[:ttl]}"
      if current_token.data[:ttl] <= 60
        rotate_application_token
      else
        renew_application_token
      end
    rescue => e
      pp Vault.token
      pp e
    end
  end
end

#===================================
# Database credential & connection wrapper
#===================================

class DatabaseInteractions

  def initialize
    puts "Read some database configuration secrets!"
    db_conf = Vault.logical.read('secret/myapp/db').data
    @host = db_conf[:host]
    @port = db_conf[:port]
  end

  def client
    @client ||= Mysql2::Client.new(:host => @host,
                                   :port => @port,
                                   :username => username,
                                   :password => creds.data[:password]).tap{puts "Username - #{username}"}
  end

  def username
    creds.data[:username]
  end

  def creds
    @creds ||=  Vault.logical.read('mysql/creds/readonly')
  end

  def rotate_credentials
    puts "Lazy rotating database credentials"
    client.close
    @creds = nil
    @client = nil
  end

  def renew_credentials_lease
    puts "Renewing database credential lease"
    Vault.sys.renew(creds.lease_id)
  rescue => e
    puts 'Database credential lease renewal failed.'
    rotate_credentials
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
  puts "Revoking application token"
  puts "Revoking database creds - #{db.username} - leaseid #{db.creds.lease_id}"
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

get '/rotate' do
  rotate_application_token
  db.rotate_credentials
  {'time' => db.time.to_s}.to_json
end

get '/renew' do
  renew_application_token
  db.renew_credentials_lease
  {'time' => db.time.to_s}.to_json
end
