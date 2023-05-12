FROM mcr.microsoft.com/oss/go/microsoft/golang:1.20-cbl-mariner2.0 as build
ADD . /workspace/src
WORKDIR /workspace/src
RUN go build -ldflags "-s -w" -o obom main.go

FROM mcr.microsoft.com/cbl-mariner/distroless/base:2.0
COPY --from=build /workspace/src/obom /bin/obom
WORKDIR /workspace
ENTRYPOINT  ["/bin/obom"]
