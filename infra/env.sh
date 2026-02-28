#!/usr/bin/env bash

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)

if [ -z "$REPO_ROOT" ]; then
  echo "Error: not inside a git repo"
  return 1 2>/dev/null || exit 1
fi

PYTHON=python3.11

# helper: works both when sourced and executed
abort() {
  echo "ERROR: $*" >&2
  return 1 2>/dev/null || exit 1
}

# Linux-only python-dev check
if [[ "$(uname -s)" == "Linux" ]]; then
  if command -v dpkg >/dev/null 2>&1; then
    if ! dpkg -s python3.11-dev >/dev/null 2>&1; then
      abort "python3.11-dev is not installed. Run: sudo apt-get install -y python3.11-dev" || return 1
      # the "|| return 1" makes it unmissable when sourced
    fi
  fi
fi

if ! command -v "$PYTHON" >/dev/null 2>&1; then
  abort "$PYTHON not found." || return 1
fi

"$PYTHON" -m venv ${REPO_ROOT}/.venv || abort "Failed to create venv" || return 1
source ${REPO_ROOT}/.venv/bin/activate || abort "Failed to activate venv" || return 1
python -m pip install -U pip || abort "pip upgrade failed" || return 1
pip install -r ${REPO_ROOT}/infra/requirements.txt || abort "requirements install failed" || return 1

COCOTB_COMMON_PATH="${REPO_ROOT}/src/cocotb"

if [ ! -d "$COCOTB_COMMON_PATH" ]; then
  echo "Error: ${COCOTB_COMMON_PATH} does not exist"
  return 1 2>/dev/null || exit 1
fi

export PYTHONPATH="${COCOTB_COMMON_PATH}:${PYTHONPATH}"
