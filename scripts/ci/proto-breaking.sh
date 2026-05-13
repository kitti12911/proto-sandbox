#!/usr/bin/env sh
set -eu

repo_dir="${CI_PROJECT_DIR:-$(pwd)}"
cd "${repo_dir}"

against="${PROTO_BREAKING_AGAINST:-}"
base_branch="${PROTO_BREAKING_BASE_BRANCH:-}"
allow_breaking="${PROTO_ALLOW_BREAKING:-false}"
allow_breaking_message="${PROTO_ALLOW_BREAKING_MESSAGE:-[allow-breaking-api]}"

if [ -n "${base_branch}" ]; then
	git fetch origin "${base_branch}" --depth=1

	if git cat-file -e "FETCH_HEAD:buf.yaml" 2>/dev/null &&
		git ls-tree -r --name-only FETCH_HEAD | grep -q '\.proto$'; then
		git branch --force breaking-baseline FETCH_HEAD
		against=".git#branch=breaking-baseline"
	else
		echo "Skipping breaking check: ${base_branch} has no protobuf baseline yet."
		exit 0
	fi
fi

if [ -z "${against}" ]; then
	if git cat-file -e main:buf.yaml 2>/dev/null &&
		git ls-tree -r --name-only main | grep -q '\.proto$'; then
		against=".git#branch=main"
	else
		echo "Skipping breaking check: main has no protobuf baseline yet."
		exit 0
	fi
fi

set +e
buf breaking --against "${against}"
breaking_status="$?"
set -e

if [ "${breaking_status}" -eq 0 ]; then
	exit 0
fi

if [ "${allow_breaking}" = "true" ]; then
	echo "Breaking changes were detected, but release is allowed because ${allow_breaking_message} is present in the head commit message."
	exit 0
fi

echo "Protobuf breaking changes detected."
echo "Use ${allow_breaking_message} in the head commit message to allow an intentional breaking release on push."
exit "${breaking_status}"
