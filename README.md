# proto-sandbox

Central protobuf definitions for sandbox services. Gateway repos such as
[`oas-sandbox`](https://github.com/kitti12911/oas-sandbox) and
[`gql-sandbox`](https://github.com/kitti12911/gql-sandbox) can generate
protobuf clients from this repo while keeping their HTTP and GraphQL contracts
in their own projects.

## Requirements

- [buf](https://buf.build/) installed
- VS Code with the `bufbuild/buf` extension for protobuf editing

Optional:

- [prettier](https://prettier.io/) for Markdown, YAML, JSON, and JSONC formatting

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

```bash
proto-sandbox/
├── common/
│   └── v1/
│       ├── pagination.proto
│       └── query.proto
├── user/
│   └── v1/
│       └── user.proto
├── worker/
│   └── v1/
│       └── worker.proto
├── .github/
│   └── workflows/
│       ├── proto-ci.yaml
│       └── release.yml
├── buf.yaml
├── Makefile
└── README.md
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

`ListUsers` requests use common query messages from `common/v1/query.proto`:

- `Filter` for validated field filters
- `OrderBy` for validated sorting
- `PaginationRequest` / `PaginationResponse` for page metadata

Supported filter operators include exact, like, case-insensitive like,
comparison operators, null checks, in, between, and exclusive between.

`PatchUser` uses `google.protobuf.FieldMask` for frontend-friendly partial
updates:

- Field not in `update_mask`: leave unchanged
- Field in `update_mask` with an empty or default value: clear or reset
- Field in `update_mask` with a value: update

`worker/v1/worker.proto` defines the `worker.v1.WorkerService` service for
submitting background jobs to worker-backed systems:

- `SubmitJob`

`SubmitJob` carries a job id, type, and JSON object payload. The gateway or
backend implementation owns transport details such as the broker topic.

## Gateway Versioning

Keep the protobuf source focused on the domain contract and version it through
package paths such as `user.v1`.

OpenAPI can expose stable REST paths such as `/v1/users` through
[`oas-sandbox`](https://github.com/kitti12911/oas-sandbox) and keep
compatibility through versioned HTTP routes.

GraphQL usually does not need separate protobuf packages. Prefer one evolving
GraphQL schema with additive fields and deprecations at the gateway layer. Add
gateway-specific protobuf files only when a gateway contract genuinely diverges
from the backend domain contract.

## Contract Releases

The shared protobuf contract is released from `main` with semantic-release.
Conventional Commit messages decide the next version and publish stable tags
such as `v1.2.0`.

Use Conventional Commits to describe contract changes:

- `feat:` for new protobuf APIs or fields.
- `fix:` for compatible corrections.
- `feat!:` or `BREAKING CHANGE:` for incompatible contract changes.

CI runs Buf breaking-change checks on pull requests and pushes. Pull requests
always fail on breaking protobuf changes. On a push to `main`, an intentional
breaking release can continue only when the head commit message contains
`[allow-breaking-api]`.

Example intentional breaking release message:

```text
feat!: rename user status enum values [allow-breaking-api]
```

Use the bypass only after the breaking change has been reviewed and called out
in release notes for downstream consumers.

## Available Commands

| Command                | Description                                    |
| ---------------------- | ---------------------------------------------- |
| `make lint`            | Run protobuf and Markdown linting              |
| `make lint-proto`      | Lint protobuf files with Buf                   |
| `make markdownlint`    | Lint Markdown files                            |
| `make fmt`             | Format protobuf files in place                 |
| `make pretty`          | Format docs and config with Prettier           |
| `make format`          | Run protobuf and Prettier formatting           |
| `make format-check`    | Check protobuf formatting without writing      |
| `make breaking`        | Check breaking changes against the main branch |
| `make release-plan`    | Preview the next semantic-release version      |
| `make release-publish` | Publish a semantic release                     |

## CI Scripts

Provider workflows should call the reusable scripts under `scripts/ci/` from a
toolchain container instead of duplicating commands in CI YAML:

| Script                                   | Description                           |
| ---------------------------------------- | ------------------------------------- |
| `scripts/ci/proto-lint.sh`               | Lint protobuf files with Buf          |
| `scripts/ci/proto-format-check.sh`       | Check protobuf formatting             |
| `scripts/ci/proto-breaking.sh`           | Check protobuf breaking changes       |
| `scripts/ci/markdownlint.sh`             | Run markdownlint-cli2 with pinned npx |
| `scripts/ci/semantic-release-publish.sh` | Publish a semantic release            |

The GitHub workflow resolves shared toolchain images through repository
variables; the scripts themselves are CI-agnostic.

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
pull requests that touch protobuf or tooling files. The workflow uses pinned
toolchain container digests and calls the reusable scripts under `scripts/ci/`.

`buf.yaml` uses:

- STANDARD lint rules
- FILE-level breaking change detection
