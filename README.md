# SPDX to OCI Artiafact

This is a simple tool to convert an SPDX to a OCI Artifact and push the SPDX doc to an OCI registry with annotations.

## Docker Image

To securely use `obom` using docker image, you need [notation](https://notaryproject.dev/docs/installation/cli/) installed to verify the image.

The certificate can be obtained from the `main` branch. The fingerprint of the certificate MUST be verified.
```sh
curl -LO https://raw.githubusercontent.com/notation-playground/obom/main/obom.crt
openssl x509 -noout -fingerprint -sha256 -inform pem -in obom.crt
```
The certificate SHA256 fingerprint MUST be
```
BB:94:F4:64:D7:E8:AA:B0:F3:04:C4:84:C5:E3:70:68:B3:2A:46:07:FD:7E:A6:C3:ED:BD:50:0F:49:6F:4B:20
```

Before verification, the above certificate is required to be added to the notation trust store and the corresponding trust policy is required to be updated.

```bash
# Add cert to the trust store
notation cert add --type ca --store obom obom.crt

# If policy is already configured, use `notation policy show` to get the policy
# and update it. Otherwise, create a new one as follows
cat > policy.json <<EOF
{
    "version": "1.0",
    "trustPolicies": [
        {
            "name": "obom",
            "registryScopes": [
                "ghcr.io/notation-playground/obom"
            ],
            "signatureVerification": {
                "level": "strict"
            },
            "trustStores": [
                "ca:obom"
            ],
            "trustedIdentities": [
                "*"
            ]
        }
    ]
}
EOF

# Update the trust policy
notation policy import policy.json
```

Verify and pull the image `ghcr.io/notation-playground/obom:v0.0.3`:
```sh
notation verify ghcr.io/notation-playground/obom:v0.0.3

# On successful verification, use the digest from the above output to pull the image
docker pull ghcr.io/notation-playground/obom@sha256:dcf111db8aad5c9c10b5c9a024c9c9adf5074ebaa07cf9b278d6cd19e79638b1

# Re-tag it for convenience
docker tag ghcr.io/notation-playground/obom@sha256:dcf111db8aad5c9c10b5c9a024c9c9adf5074ebaa07cf9b278d6cd19e79638b1 obom:v0.0.3
```

Download the example spdx document and show it using `obom`.
```sh
curl -LO https://raw.githubusercontent.com/notation-playground/obom/main/examples/SPDXJSONExample-v2.3.spdx.json
docker run --rm -it -v .:/workspace obom:v0.0.3 show -f SPDXJSONExample-v2.3.spdx.json
```

## Build

Run `make` to build the binary or use the following command to build the binary.

```bash
go build -ldflags "-s -w" -o obom main.go
```

## Install

```bash
go get github.com/sajayantony/obom
```

## Usage

```
  obom [command] 
```

## Sub Commands 

- [obom show](#obom-show) - Show SPDX Document
- [obom push](#obom-push) - Push SPDX Document to OCI Registry
- [obom packages](#obom-packages) - List Packages
- [obom files](#obom-files) - List Files

### obom show

Sub command that shows the SPDX Document summary.

```bash
$ obom show -f ./examples/SPDXJSONExample-v2.3.spdx.json
================================================================================
Document Name:         SPDX-Tools-v2.0
DataLicense:           CC0-1.0
Document Namespace:    http://spdx.org/spdxdocs/spdx-example-444504E0-4F89-41D3-9A0C-0305E82C3301
SPDX Version:          SPDX-2.3
Packages:              4
Files:                 5
Digest:                sha256:2de3741a7be1be5f5e54e837524f2ec627fedfb82307dc004ae03b195abc092f
================================================================================
```

### obom push

Sub command that pushes the SPDX Document to an OCI registry and adds annotations to the OCI Artifact.
Annotations are the SPDX Document properties and can be overriden by the command line flags.


```bash
$ obom push -f ./examples/SPDXJSONExample-v2.3.spdx.json localhost:5001/spdx:example
================================================================================
Document Name:         SPDX-Tools-v2.0
DataLicense:           CC0-1.0
Document Namespace:    http://spdx.org/spdxdocs/spdx-example-444504E0-4F89-41D3-9A0C-0305E82C3301
SPDX Version:          SPDX-2.3
Packages:              4
Files:                 5
Digest:                sha256:2de3741a7be1be5f5e54e837524f2ec627fedfb82307dc004ae03b195abc092f
================================================================================
Adding ./examples/SPDXJSONExample-v2.3.spdx.json: sha256:2de3741a7be1be5f5e54e837524f2ec627fedfb82307dc004ae03b195abc092f
Pushing localhost:5001/spdx:example sha256:07cc47f237cca9b699f2aba6d2684a20ece88268492e577194394030ca52e3de

```

You can view the manifest of the pushed artifact using the following command.

```bash
$ oras manifest get localhost:5001/spdx/annotations:test --pretty
{
  "schemaVersion": 2,
  "mediaType": "application/vnd.oci.image.manifest.v1+json",
  "config": {
    "mediaType": "text/spdx",
    "digest": "sha256:44136fa355b3678a1146ad16f7e8649e94fb4fc21fe77e8310c060f61caaff8a",
    "size": 2
  },
  "layers": [
    {
      "mediaType": "text/spdx",
      "digest": "sha256:2de3741a7be1be5f5e54e837524f2ec627fedfb82307dc004ae03b195abc092f",
      "size": 21342,
      "annotations": {
        "org.opencontainers.image.title": "./examples/SPDXJSONExample-v2.3.spdx.json"
      }
    }
  ],
  "annotations": {
    "org.opencontainers.image.created": "2023-05-10T19:43:14Z",
    "org.spdx.license": "CC0-1.0",
    "org.spdx.name": "SPDX-Tools-v2.0",
    "org.spdx.namespace": "http://spdx.org/spdxdocs/spdx-example-444504E0-4F89-41D3-9A0C-0305E82C3301",
    "org.spdx.version": "SPDX-2.3"
  }
}
```

## obom packages

Subcommand that lists the packages in the SPDX Document. 

```shell
$ obom packages -f ./temp/manifest.spdx.json | head -5
pkg:nuget/Microsoft.Extensions.Configuration.Json@3.1.4
pkg:nuget/Microsoft.Extensions.FileProviders.Abstractions@3.1.4
pkg:nuget/Microsoft.Extensions.Configuration.Binder@3.1.4
pkg:nuget/Microsoft.Azure.Storage.Blob@11.1.2
pkg:nuget/Microsoft.Azure.Storage.File@11.1.2
```

## obom files

Subcommand that lists the files in the SPDX Document.

```shell
obom files -f ./examples/SPDXJSONExample-v2.3.spdx.json
./src/org/spdx/parser/DOAPProject.java
./lib-source/commons-lang3-3.1-sources.jar
./lib-source/jena-2.6.3-sources.jar
./docs/myspec.pdf
./package/foo.c
```
