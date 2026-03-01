COCOTB_COMMON_PATH="${REPO_ROOT}/src/cocotb"

if [ ! -d "$COCOTB_COMMON_PATH" ]; then
  echo "Error: ${COCOTB_COMMON_PATH} does not exist"
  return 1 2>/dev/null || exit 1
fi

export PYTHONPATH="${COCOTB_COMMON_PATH}:${PYTHONPATH}"
