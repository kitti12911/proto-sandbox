.PHONY: lint format format-check breaking

# ____________________ Buf Command ____________________
lint:
	buf lint

format:
	buf format -w

format-check:
	buf format --diff --exit-code

breaking:
	@if git cat-file -e main:buf.yaml 2>/dev/null && git ls-tree -r --name-only main | grep -q '\.proto$$'; then \
		buf breaking --against '.git#branch=main'; \
	else \
		echo "Skipping breaking check: main has no protobuf baseline yet."; \
	fi
