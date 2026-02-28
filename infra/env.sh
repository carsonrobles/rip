#!/usr/bin/env bash
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

"$PYTHON" -m venv .venv || abort "Failed to create venv" || return 1
source .venv/bin/activate || abort "Failed to activate venv" || return 1
python -m pip install -U pip || abort "pip upgrade failed" || return 1
pip install -r infra/requirements.txt || abort "requirements install failed" || return 1
