#!/bin/bash

CMD=$1
shift
PARAMS=$*
CURRENT_BRANCH_NAME=`git rev-parse --abbrev-ref HEAD`
SCRIPT_NAME=ms
export DOCKER_HOST_IP=`ifconfig docker0 | grep "inet addr" | awk -F'[: ]+' '{ print $4 }'`

function help {
    echo "Usage:"
    echo "    ./${SCRIPT_NAME} build"
    echo "    ./${SCRIPT_NAME} clean"
    echo "    ./${SCRIPT_NAME} docker_host_ip"
    echo "    ./${SCRIPT_NAME} docker_ips"
    echo "    ./${SCRIPT_NAME} purge"
    echo "    ./${SCRIPT_NAME} purge_all"
    echo "    ./${SCRIPT_NAME} run_probes"
    echo "    ./${SCRIPT_NAME} run_vault"
    echo "    ./${SCRIPT_NAME} stats"
    echo
}

function build {
    docker-compose rm -fv
    docker-compose build
}

case $CMD in
    "build")
        build
        ;;
    "clean")
        echo "Removing unneeded containers and images..."
        docker rm `docker ps --no-trunc -aq`
        docker images -q --filter "dangling=true" | xargs docker rmi
        ;;
    "docker_host_ip")
        echo $DOCKER_HOST_IP
        ;;
    "docker_ips")
        docker ps -q | xargs -n 1 docker inspect --format '{{ .NetworkSettings.IPAddress }} {{ .Name }}' | sed 's/ \// /'
        ;;
    "help")
        help
        ;;
    "purge")
        echo "Removing api containers and images..."
        docker rm $(docker ps --no-trunc -aq --filter="name=springcloudmicroservices")
        docker rmi -f $(docker images -q --filter="label=srai.micro.project=true")
        ;;
    "purge_all")
        echo "Removing all docker containers and images..."
        docker rm -f $(docker ps -a -q)
        docker rmi -f $(docker images -q)
        ;;
    "run_probes")
        echo "Starting services for docker probes..."
        exec docker-compose -f docker-compose-probes.yml up
        ;;
    "run_vault")
        echo "Starting services ..."
        exec docker-compose up
        ;;
    "stats")
        echo "Displaying docker stats..."
        docker stats $(docker ps  | sed 1d | awk '{print $NF}')
        ;;
    *)
        echo "I don't know what you want me to do"
        help
        ;;
esac
