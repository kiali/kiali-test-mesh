NAME ?= "KialiTestService"
BINARY_NAME ?=kiali-test-service
# Identifies the current build.
# These will be embedded in the app and displayed when it starts.
VERSION ?= 0.0.1.Final-SNAPSHOT
COMMIT_HASH ?= $(shell git rev-parse HEAD)

# Environment variables set when running the Go compiler.
GO_BUILD_ENVVARS = \
        GOOS=linux \
        GOARCH=amd64 \
        CGO_ENABLED=0 \

DOCKER_NAME ?= kiali/kiali-test-service
DOCKER_TAG ?= latest

all: build

build:
	@echo Building...
	${GO_BUILD_ENVVARS} go build \
		-o ${GOPATH}/bin/${BINARY_NAME} -ldflags "-X main.name=${NAME} -X main.version=${VERSION} -X main.commitHash=${COMMIT_HASH}"

docker-build:
	@echo Building the docker image : ${DOCKER_NAME}:${DOCKER_TAG}
	@mkdir -p _output/docker
	@cp ${GOPATH}/bin/kiali-test-service _output/docker
	@cp deploy/docker/* _output/docker
	@docker build -t ${DOCKER_NAME}:${DOCKER_TAG} _output/docker

clean:
	@echo "Cleaning any build artifacts"
	@echo "  - Removing the _output directory"
	@rm -rf _output
	@echo "  - Removing the binary from \$$GOPATH/bin"
	@rm -f ${GOPATH}/bin/kiali-test-service
