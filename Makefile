#!/usr/bin/make -f
PACKAGES=$(shell go list ./...)
DOCKER := $(shell which docker)
DOCKER_BUF := $(DOCKER) run --rm -v $(CURDIR):/workspace --workdir /workspace bufbuild/buf:1.0.0-rc8
PROJECT_NAME = $(shell git remote get-url origin | xargs basename -s .git)

###############################################################################
###                           Install                                       ###
###############################################################################
build: go.sum
		@go build -o build/nftd ./cmd/nftd

install: go.sum
		@echo "--> Installing nftd"
		@go install ./cmd/nftd

install-debug: go.sum
	go build -gcflags="all=-N -l" ./cmd/nftd

go.sum: go.mod
	@echo "--> Ensure dependencies have not been modified"
	GO111MODULE=on go mod verify

test:
	@go test -mod=readonly $(PACKAGES) -cover

lint:
	@echo "--> Running linter"
	@golangci-lint run
	@go mod verify

###############################################################################
###                                Protobuf                                 ###
###############################################################################

###############################################################################
###                                Protobuf                                 ###
###############################################################################

protoVer=v0.7
protoImageName=tendermintdev/sdk-proto-gen:$(protoVer)
containerProtoGen=$(PROJECT_NAME)-proto-gen-$(protoVer)
containerProtoGenAny=$(PROJECT_NAME)-proto-gen-any-$(protoVer)
containerProtoGenSwagger=$(PROJECT_NAME)-proto-gen-swagger-$(protoVer)
containerProtoFmt=$(PROJECT_NAME)-proto-fmt-$(protoVer)	

proto-all: proto-gen

proto-gen:
	@echo "Generating Protobuf files"
	@if docker ps -a --format '{{.Names}}' | grep -Eq "^${containerProtoGen}$$"; then docker start -a $(containerProtoGen); else docker run --name $(containerProtoGen) -v $(CURDIR):/workspace --workdir /workspace $(protoImageName) \
		sh ./scripts/protocgen.sh; fi

proto-swagger-gen:
	@echo "Generating Protobuf Swagger"
	@if docker ps -a --format '{{.Names}}' | grep -Eq "^${containerProtoGenSwagger}$$"; then docker start -a $(containerProtoGenSwagger); else docker run --name $(containerProtoGenSwagger) -v $(CURDIR):/workspace --workdir /workspace $(protoImageName) \
		sh ./scripts/protoc-swagger-gen.sh; fi

proto-format:
	@echo "Formatting Protobuf files"
	@if docker ps -a --format '{{.Names}}' | grep -Eq "^${containerProtoFmt}$$"; then docker start -a $(containerProtoFmt); else docker run --name $(containerProtoFmt) -v $(CURDIR):/workspace --workdir /workspace tendermintdev/docker-build-proto \
		find ./ -not -path "./third_party/*" -name "*.proto" -exec clang-format -i {} \; ; fi

proto-lint:
	@$(DOCKER_BUF) lint --error-format=json

########################################

###############################################################################
###                                Initialize                               ###
###############################################################################

init: kill-dev install 
	@echo "Initializing both blockchains..."
	./network/init.sh
	./network/start.sh
	@echo "Initializing relayer..." 
	./network/hermes/restore-keys.sh
	./network/hermes/create-conn.sh

init-golang-rly: kill-dev install
	@echo "Initializing both blockchains..."
	./network/init.sh
	./network/start.sh
	@echo "Initializing relayer..."
	./network/relayer/interchain-nft-config/rly.sh

start: 
	@echo "Starting up test network"
	./network/start.sh

start-rly:
	./network/hermes/start.sh

kill-dev:
	@echo "Killing nftd and removing previous data"
	-@rm -rf ./data
	-@killall nftd 2>/dev/null

########################################
### Local validator nodes using docker and docker-compose

testnet-init:
	@if ! [ -f build/nodecluster/node0/iris/config/genesis.json ]; then docker run --rm -v $(CURDIR)/build:/home irisnet/irishub iris testnet --v 4 --output-dir /home/nodecluster --chain-id irishub-test --keyring-backend test --starting-ip-address 192.168.10.2 ; fi
	@echo "To install jq command, please refer to this page: https://stedolan.github.io/jq/download/"
	@jq '.app_state.auth.accounts+= [{"@type":"/cosmos.auth.v1beta1.BaseAccount","address":"iaa1ljemm0yznz58qxxs8xyak7fashcfxf5lgl4zjx","pub_key":null,"account_number":"0","sequence":"0"}] | .app_state.bank.balances+= [{"address":"iaa1ljemm0yznz58qxxs8xyak7fashcfxf5lgl4zjx","coins":[{"denom":"uiris","amount":"1000000000000"}]}]' build/nodecluster/node0/iris/config/genesis.json > build/genesis_temp.json ;
	@sudo cp build/genesis_temp.json build/nodecluster/node0/iris/config/genesis.json
	@sudo cp build/genesis_temp.json build/nodecluster/node1/iris/config/genesis.json
	@sudo cp build/genesis_temp.json build/nodecluster/node2/iris/config/genesis.json
	@sudo cp build/genesis_temp.json build/nodecluster/node3/iris/config/genesis.json
	@rm build/genesis_temp.json
	@echo "Faucet address: iaa1ljemm0yznz58qxxs8xyak7fashcfxf5lgl4zjx" ;
	@echo "Faucet coin amount: 1000000000000uiris"
	@echo "Faucet key seed: tube lonely pause spring gym veteran know want grid tired taxi such same mesh charge orient bracket ozone concert once good quick dry boss"

testnet-start:
	docker-compose up -d

testnet-stop:
	docker-compose down

testnet-clean:
	docker-compose down
	sudo rm -rf build/*