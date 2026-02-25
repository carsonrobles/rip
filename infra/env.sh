#!/usr/bin/env bash
PYTHON=python3.11

if ! command -v $PYTHON &> /dev/null; then
  echo "Error: $PYTHON not found."
  exit 1
fi

$PYTHON -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
pip install -r infra/requirements.txt
