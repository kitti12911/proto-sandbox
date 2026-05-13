.PHONY: lint lint-proto ci-lint-proto markdownlint ci-markdownlint fmt pretty format format-check ci-format-check breaking ci-breaking release-plan release-publish

# ____________________ Buf Command ____________________
lint: lint-proto markdownlint

lint-proto:
	./scripts/ci/proto-lint.sh

ci-lint-proto:
	./scripts/ci/proto-lint.sh

markdownlint:
	./scripts/ci/markdownlint.sh

ci-markdownlint:
	./scripts/ci/markdownlint.sh

fmt:
	buf format -w

pretty:
	prettier --write "**/*.{md,markdown,yml,yaml,json,jsonc}"

format: fmt pretty

format-check:
	./scripts/ci/proto-format-check.sh

ci-format-check:
	./scripts/ci/proto-format-check.sh

breaking:
	./scripts/ci/proto-breaking.sh

ci-breaking:
	./scripts/ci/proto-breaking.sh

release-plan:
	./scripts/ci/semantic-release-plan.sh

release-publish:
	./scripts/ci/semantic-release-publish.sh
