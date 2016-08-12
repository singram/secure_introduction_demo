# secure_introduction_demo
Working demo of SI (Secure Introduction) in practice

## Goals
- Develop working example of secure introduction best practices using Vault & ruby.

## Clone project

    git clone git@github.com:singram/secure_introduction_demo.git

## Setup

Pre-requisites
- Docker
- Docker-compose

### Installation (debian base)

#### Install Docker

    apt-get install apparmor lxc cgroup-lite
    wget -qO- https://get.docker.com/ | sh
    sudo usermod -aG docker YourUserNameHere
    sudo service docker restart

#### Install Docker-compose  (1.6+)

*MAKE SURE YOU HAVE AN UP TO DATE VERSION OF DOCKER COMPOSE*

To check the version:

    docker-compose --version

To install the 1.6.0:

    sudo su
    curl -L https://github.com/docker/compose/releases/download/1.6.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    exit

Install supporting tools

    sudo apt-get install jq mitmproxy wget libmysqlclient-dev

### To run

Shell 1

    docker-compose up

Shell 2

    mitmproxy -P http://127.0.0.1:8200 -p 8201 -vv

Shell 3

    ./initialize_vault

## Overview

    ./vault audit-enable file path=/root/logs/audit.log
    ./vault policy-write myapp /root/myapp.hcl

    ./vault write secret/myapp/awesome value="sauce"
    ./vault write secret/myapp/db host="mysql" port=3306
    ./vault write secret/otherapp/awesome value="pandas"

    ./vault token-create -display-name=myapp -policy=myapp -wrap-ttl=120
    ./vault unwrap 179a661c-bda2-c382-44df-b8ef0031e378
    ./vault auth cc9a61f9-0c40-27ff-74aa-5a082c4d269f
    ./vault read secret/myapp/awesome
    ./vault read secret/otherapp/awesome
    ./vault write secret/myapp/awesome value="hashicorp"
    ./vault token-lookup 7e8d90cf-19b5-6c6f-9357-26a36b952b29

    ./vault mount mysql
    ./vault write mysql/config/connection connection_url="root:rootpassword@tcp(mysql:3306)/"
    ./vault write mysql/config/lease lease=1h lease_max=24h
    ./vault write mysql/roles/readonly \
       sql="CREATE USER '{{name}}'@'%' IDENTIFIED BY '{{password}}';GRANT SELECT ON *.* TO '{{name}}'@'%';"
    ./vault list /mysql/roles
    ./vault read mysql/creds/readonly

Example application

    cd simple-service
    cd .. && WRAPPED_TOKEN=`./vault token-create -format=json -display-name=myapp -policy=myapp -wrap-ttl=120 | jq -c . | sed -e '#\n##'` && cd -
    echo $WRAPPED_TOKEN
    VAULT_SI_TOKEN=$WRAPPED_TOKEN bundle exec ruby app/simple_server.rb

To renew keys

    curl localhost:4567/renew

To rotate keys

    curl localhost:4567/rotate


## References

### Quote source
- http://www.textfiles.com/humor/TAGLINES/

### Secure Introduction
- https://www.youtube.com/watch?v=skENC9aXgco

### Vault
- https://www.hashicorp.com/blog/vault-0.6.html
- https://www.amon.cx/blog/managing-all-secrets-with-vault/
- http://blogs.cisco.com/cloud/mantl-knows-secrets

#### PKI
- http://cuddletech.com/?p=959
- https://blog.kintoandar.com/2015/11/vault-PKI-made-easy.html

#### Dynamic user creation
- https://www.pythian.com/blog/dynamic-mysql-credentials-vault/

#### HTTP Interception in lieu of documentation
- http://unix.stackexchange.com/questions/103037/what-tool-can-i-use-to-sniff-http-https-traffic