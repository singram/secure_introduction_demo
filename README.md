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

    sudo apt-get install jq

### To build

Execute the following to run the services.

    ./ms build

### To run

    ./ms run_vault

## Overview

    ./vault audit-enable file path=/root/logs/audit.log
    ./vault policy-write myapp /root/myapp.hcl
    ./vault write secret/myapp/awesome value="sauce"
    ./vault write secret/otherapp/awesome value="pandas"

Change authentication token

    ./vault token-create -policy=myapp -wrap-ttl-60
    ./vault auth cc9a61f9-0c40-27ff-74aa-5a082c4d269f
    ./vault read secret/myapp/awesome
    ./vault write secret/myapp/awesome value="hashicorp"

## References

### Quote source
- http://www.textfiles.com/humor/TAGLINES/

### Secure Introduction
- https://www.youtube.com/watch?v=skENC9aXgco

### Vault
- https://www.hashicorp.com/blog/vault-0.6.html
- https://www.amon.cx/blog/managing-all-secrets-with-vault/

#### PKI
- http://cuddletech.com/?p=959
- https://blog.kintoandar.com/2015/11/vault-PKI-made-easy.html

#### Dynamic user creation
- https://www.pythian.com/blog/dynamic-mysql-credentials-vault/