.PHONY: lint-scripts
lint-scripts:
	shellcheck -S warning scripts/*.sh scripts/lib/*.sh
	@echo "✓ shellcheck passed"