BINARY_NAME:=nyp-auth


# =================================== DEFAULT =================================== #

default: all

## default: Runs build and test
.PHONY: default
all: build

# =================================== HELPERS =================================== #

## help: print this help message
.PHONY: help
help:
	@echo 'Usage:'
	@sed -n 's/^##//p' ${MAKEFILE_LIST} | column -t -s ':' |  sed -e 's/^/ /'

# =================================== DEVELOPMENT =================================== #

## build: builds the binary
.PHONY: build
build: tidy lint test
	npx cross-env GOARCH=amd64 GOOS=linux   go build -ldflags="-s -w" -o $(BINARY_NAME)-linux main.go
	npx cross-env GOARCH=amd64 GOOS=darwin  go build -ldflags="-s -w" -o $(BINARY_NAME)-darwin main.go
	npx cross-env GOARCH=amd64 GOOS=windows go build -ldflags="-s -w" -o $(BINARY_NAME)-windows main.go

## run: Run the program
.PHONY: run
run:
	go run github.com/air-verse/air@latest

## install: Install the program
.PHONY: install
install:
	npm i
	go get ./...

## test: Test the program
.PHONY: test
test:
	go mod verify
	go vet ./...
	go run github.com/securego/gosec/v2/cmd/gosec@latest -quiet ./...
	go run github.com/go-critic/go-critic/cmd/gocritic@latest check -enableAll ./...
	go run github.com/google/osv-scanner/cmd/osv-scanner@latest -r .
	go test -race .

# =================================== QUALITY ================================== #

## tidy: Tidy mod file and format code
.PHONY: tidy
tidy:
	go fmt .
	go mod tidy -v

## clean: Clean binaries
.PHONY: clean
clean:
	go clean
	rm -f ${BINARY_NAME}-linux
	rm -f ${BINARY_NAME}-darwin
	rm -f ${BINARY_NAME}-windows

# https://golangci-lint.run/welcome/install/
## lint: Lint code
.PHONY: lint
lint: tidy
	npm run lint:fix
	go run github.com/golangci/golangci-lint/cmd/golangci-lint@latest run
