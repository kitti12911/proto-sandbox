# proto-sandbox

Central protobuf definitions for sandbox services. Gateway repos such as
`oas-sandbox` and `gql-sandbox` can generate protobuf clients from this
repo while keeping their HTTP and GraphQL contracts in their own projects.

## Requirements

- [buf](https://buf.build/) installed
- VS Code with the `bufbuild/buf` extension for protobuf editing

## Install buf

macOS:

```bash
brew install bufbuild/buf/buf
```

Linux:

```bash
os="$(uname -s)"
arch="$(uname -m)"
base="https://github.com/bufbuild/buf/releases/latest/download"
curl -sSL "${base}/buf-${os}-${arch}" -o /usr/local/bin/buf
chmod +x /usr/local/bin/buf
```

## Project Structure

```text
proto-sandbox/
|-- common/
|   `-- v1/
|       `-- pagination.proto
|-- user/
|   `-- v1/
|       `-- user.proto
|-- .github/
|   `-- workflows/
|       `-- proto-ci.yaml
|-- buf.yaml
|-- Makefile
`-- README.md
```

## API Shape

`user/v1/user.proto` defines the `user.v1.UserService` service and a simple
user resource. The service uses REST-shaped RPCs so gateways can map behavior
clearly:

- `GetUser`
- `ListUsers`
- `CreateUser`
- `UpdateUser`
- `PatchUser`
- `DeleteUser`

`PatchUser` uses `google.protobuf.FieldMask` for frontend-friendly partial
updates:

- Field not in `update_mask`: leave unchanged
- Field in `update_mask` with an empty or default value: clear or reset
- Field in `update_mask` with a value: update

## Gateway Versioning

Keep the protobuf source focused on the domain contract and version it through
package paths such as `user.v1`.

OpenAPI can expose stable REST paths such as `/v1/users` and keep compatibility
through versioned HTTP routes.

GraphQL usually does not need separate protobuf packages. Prefer one evolving
GraphQL schema with additive fields and deprecations at the gateway layer. Add
gateway-specific protobuf files only when a gateway contract genuinely diverges
from the backend domain contract.

## Available Commands

| Command             | Description                                    |
| ------------------- | ---------------------------------------------- |
| `make lint`         | Lint protobuf files with Buf                   |
| `make format`       | Format protobuf files in place                 |
| `make format-check` | Check protobuf formatting without writing      |
| `make breaking`     | Check breaking changes against the main branch |

## Add A Service

Create a directory using the pattern `<service>/<version>/`:

```text
service-name/
`-- v1/
    `-- service_name.proto
```

Set a stable package and Go package option:

```protobuf
package service_name.v1;

option go_package = "github.com/kitti12911/proto-sandbox/gen/grpc/foo/v1;foov1";
```

Then run:

```bash
make lint
make format-check
```

## CI

GitHub Actions runs Buf lint, format, and breaking-change checks on pushes and
pull requests that touch protobuf or tooling files. Third-party actions are
pinned by full commit SHA instead of floating tags.

`buf.yaml` uses:

- STANDARD lint rules
- FILE-level breaking change detection
