.PHONY: install test uninstall shellcheck syntax help

.DEFAULT_GOAL := help

SHELL := /bin/bash
SH_FILES := $(wildcard *.sh)

EXPECTED_FILES := \
	.claude/CLAUDE.md \
	.claude/settings.json \
	.claude/skills

help:
	@echo "Available targets:"
	@echo "  install     Run ./install.sh in the current directory"
	@echo "  test        Install into a scratch dir and verify expected files"
	@echo "  shellcheck  Run shellcheck on all *.sh files"
	@echo "  syntax      Run 'bash -n' on all *.sh files"
	@echo "  uninstall   Restore from a .claude.bak-*/ backup directory"
	@echo "  help        Print this message (default)"

install:
	@test -x ./install.sh || { echo "install.sh not found or not executable"; exit 1; }
	./install.sh

test:
	@set -e; \
	scratch=$$(mktemp -d -t loopkit-test.XXXXXX); \
	echo "Scratch dir: $$scratch"; \
	trap 'rm -rf "$$scratch"' EXIT; \
	cp -R . "$$scratch/src"; \
	cd "$$scratch/src" && ./install.sh --target "$$scratch/home" >/dev/null; \
	missing=0; \
	for f in $(EXPECTED_FILES); do \
		if [ ! -e "$$scratch/home/$$f" ]; then \
			echo "MISSING: $$f"; \
			missing=1; \
		fi; \
	done; \
	if [ $$missing -ne 0 ]; then \
		echo "test FAILED"; exit 1; \
	fi; \
	echo "test OK"

shellcheck:
	@command -v shellcheck >/dev/null 2>&1 || { \
		echo "shellcheck not installed"; exit 1; }
	@if [ -z "$(SH_FILES)" ]; then \
		echo "no *.sh files found"; exit 0; \
	fi
	shellcheck $(SH_FILES)

syntax:
	@if [ -z "$(SH_FILES)" ]; then \
		echo "no *.sh files found"; exit 0; \
	fi
	@for f in $(SH_FILES); do \
		echo "bash -n $$f"; \
		bash -n "$$f" || exit 1; \
	done

uninstall:
	@shopt -s nullglob; \
	backups=(.claude.bak-*/); \
	if [ $${#backups[@]} -eq 0 ]; then \
		echo "no .claude.bak-*/ backups found"; exit 1; \
	fi; \
	echo "Available backups:"; \
	i=1; for b in "$${backups[@]}"; do echo "  $$i) $$b"; i=$$((i+1)); done; \
	read -rp "Select backup number to restore: " choice; \
	target="$${backups[$$((choice-1))]}"; \
	if [ -z "$$target" ] || [ ! -d "$$target" ]; then \
		echo "invalid selection"; exit 1; \
	fi; \
	echo "Restoring from $$target"; \
	rm -rf .claude; \
	cp -R "$$target" .claude; \
	echo "restored .claude from $$target"
