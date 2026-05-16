##
## qtop is a tool to monitor queuing systems - https://github.com/qtop/qtop
##
## Copyright (c) 2016 Fotis Georgatos
## Copyright (c) 2016 Sotiris Fragkiskos
## Copyright (c) 2023 Hewlett Packard Enterprise Development LP
##
## SPDX-License-Identifier: MIT
##

PYTHON      ?= python3
PYTEST      ?= $(PYTHON) -m pytest
PIP         ?= pip
QTOP        := $(PYTHON) -m qtop_py.qtop
CONTRIB_DIR  = qtop_py/contrib
# Filter out lines that change on every run (timestamps, paths)
FILTER      := grep -v 'WORKDIR\|Please try it with watch\|Log file created in\|Job accounting summary'

.PHONY: all install dev-install test unit-test func-test func-test-slurm generate-refs lint clean help

all: test

## Install the package
install:
	$(PIP) install .

## Install in editable/development mode
dev-install:
	$(PIP) install -e .

## Run all tests (unit + functional)
test: unit-test func-test

## Run pytest unit tests only
unit-test:
	$(PYTEST) tests/ -v

## Run functional (reference-output diff) tests for all schedulers
func-test:
	@echo "(No news is good news!)"
	@$(MAKE) _func-test-slurm

## Run functional test for Slurm scheduler
func-test-slurm:
	@$(MAKE) _func-test-slurm

_func-test-slurm:
	@echo "Testing slurm..."
	@$(FILTER) $(CONTRIB_DIR)/slurm_dvv_out.ref > /tmp/qtop_testfile
	@$(QTOP) -c ON -s $(CONTRIB_DIR) -raF -b slurm 2>/dev/null \
	    | $(FILTER) \
	    | diff - /tmp/qtop_testfile
	@echo "slurm: OK"

## Run pytest unit tests for Slurm plugin
test-slurm:
	$(PYTEST) tests/plugins/test_slurm.py -v

## Run pytest for PBS sample regressions
test-pbs-samples:
	$(PYTHON) tools/validate_pbs_samples.py $(PBS_SAMPLES_DIR) --limit $(PBS_SAMPLE_LIMIT) --output $(PBS_OUTPUT_DIR)

## Generate reference output files for all schedulers including slurm.
generate-refs:
	@echo "Generating reference output for slurm..."
	@$(QTOP) -c ON -s $(CONTRIB_DIR) -raF -b slurm 2>/dev/null \
	    | $(FILTER) \
	    > $(CONTRIB_DIR)/slurm_dvv_out.ref
	@echo "Done. Reference file: $(CONTRIB_DIR)/slurm_dvv_out.ref"

## Run ruff linter
lint:
	ruff check qtop_py/ tests/

## Remove compiled Python files and caches
clean:
	find . -type f -name '*.pyc' -delete
	find . -type d -name '__pycache__' -delete
	find . -type d -name '*.egg-info' -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name '.pytest_cache' -exec rm -rf {} + 2>/dev/null || true

help:
	@echo "Available targets:"
	@echo "  install          Install the package"
	@echo "  dev-install      Install in editable mode (development)"
	@echo "  test             Run all tests (unit + functional)"
	@echo "  unit-test        Run pytest unit tests"
	@echo "  func-test        Run functional tests (diff against ref files)"
	@echo "  func-test-slurm  Run functional test for Slurm scheduler only"
	@echo "  test-slurm       Run pytest unit tests for Slurm plugin"
	@echo "  test-pbs-samples Run PBS sample regression tests"
	@echo "  generate-refs    (Re)generate reference output files"
	@echo "  lint             Run ruff linter"
	@echo "  clean            Remove compiled files and caches"
