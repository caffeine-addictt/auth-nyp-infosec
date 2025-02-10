# Using multistage builds so the final image is smaller
# https://docs.docker.com/language/golang/build-images/#multi-stage-builds


###################
# 1. Building stage
###################
FROM golang:1.23.6 AS build-stage

# Update CA-Certs
RUN update-ca-certificates

# Set destination for COPY
WORKDIR /nexisAPI

# Add caching
ENV GOCACHE=$HOME/.cache/go-build
RUN --mount=type=cache,target=$GOCACHE go env -w GOCACHE=$GOCACHE

# Download Go modules
# Doing this FIRST so dependencies are cached first
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code.
COPY *.go ./
COPY cmd/ ./cmd/

# Build
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -a -installsuffix cgo -o /nexis



###################
# 2. Run tests
###################
FROM build-stage AS run-test-stage
RUN go test -v ./...



###################
# 3. Deploying
###################
FROM gcr.io/distroless/static-debian11 AS deploy-stage
WORKDIR /

# Copy bin from build stage
COPY --from=build-stage /nexis /nexis

# Expose port 3000
EXPOSE 3000

# Run
ENTRYPOINT ["/nexis"]
