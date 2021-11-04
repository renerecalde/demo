#!/bin/bash
include .makerc

DOCKER_DB = ${PROJECT_NAME}-server-db
DOCKER_BE = ${PROJECT_NAME}-server-be
DOCKER_NETWORK = ${PROJECT_NAME}-server-network
OS := $(shell uname)

ifeq ($(OS),Linux)
	UID = $(shell id -u)
else
	UID = 1000
endif

help: ## Show this help message
	@echo 'usage: make [target]'
	@echo
	@echo 'targets:'
	@egrep '^(.+)\:\ ##\ (.+)' ${MAKEFILE_LIST} | column -t -c 2 -s ':#'

run: ## Start the containers
	docker network create ${DOCKER_NETWORK} || true
	U_ID=${UID} docker-compose up -d

stop: ## Stop the containers
	U_ID=${UID} docker-compose stop

restart: ## Restart the containers
	$(MAKE) stop && $(MAKE) run

build: ## Rebuilds all the containers
	U_ID=${UID} docker-compose stop && U_ID=${UID} docker-compose build && $(MAKE) run && $(MAKE) prepare

prepare: ## Runs backend commands
	$(MAKE) config-db-user

ssh-be-root: ## ssh's into the be container
	U_ID=${UID} docker exec -it --user 0 ${DOCKER_BE} bash

ssh-be: ## ssh's into the be container
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} bash

code-style: ## Runs php-cs to fix code styling following Symfony rules
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} php-cs-fixer fix src --rules=@Symfony
	U_ID=${UID} docker exec -it --user ${UID} ${DOCKER_BE} php-cs-fixer fix tests --rules=@Symfony

config-db-user:
        U_ID=${UID} docker exec ${DOCKER_DB} sh -c 'exec mysqldump --all-databases -uroot -p root' < /docker/database/configUser.sql


