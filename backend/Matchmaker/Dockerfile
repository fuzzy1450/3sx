# -------- Build Stage --------
FROM swift:latest AS builder

WORKDIR /build

COPY . .

#Clean Environment
RUN swift package clean

# Fetch dependencies
RUN swift package resolve

# Build in release mode
RUN swift build -c release



FROM swift:slim
WORKDIR /3sx-matchmaking
COPY --from=builder /build/.build/release .
ENTRYPOINT ["./matchmaker"]

