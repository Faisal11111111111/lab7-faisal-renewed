#!/bin/bash

# Always run from this directory
cd "$(dirname "$0")"

# Activate virtual environment
if [ -f "/home/codegrade/project/.venv/bin/activate" ]; then
  source /home/codegrade/project/.venv/bin/activate
elif [ -f ".venv/bin/activate" ]; then
  source .venv/bin/activate
fi

points=0
max=15
fb=""
file=tests/operators/test_encrypt.py

# Run pytest using POETRY
poetry run pytest -q tests/operators/test_encrypt.py --cov=presidio_anonymizer --cov-report=term > out.txt 2>&1 || true

# Extract clean coverage
cov=$(grep -E "operators/encrypt\.py" out.txt | grep -Eo '[0-9]+%' | tr -d '%' | tail -1)
cov=${cov:-0}
if ! [[ "$cov" =~ ^[0-9]+$ ]]; then cov=0; fi

# 3.1 correct function name
if grep -q "def test_given_verifying_an_invalid_length_bytes_key_then_ipe_raised" "$file"; then
  fb+="✅ correct test name. "
  points=$((points+3))
else
  fb+="❌ incorrect test name. "
fi

# 3.2 correct patch target
if grep -q "AESCipher.is_valid_key_size" "$file"; then
  fb+="✅ correct patch target. "
  points=$((points+3))
else
  fb+="❌ incorrect patch target. "
fi

# 3.3 renamed mock variable
if grep -q "mock_is_valid_key_size" "$file"; then
  fb+="✅ mock variable renamed correctly. "
  points=$((points+3))
else
  fb+="❌ mock variable not renamed. "
fi

# 3.4 return value set
if grep -q "mock_is_valid_key_size.return_value" "$file"; then
  fb+="✅ mock return_value set. "
  points=$((points+3))
else
  fb+="❌ missing return_value. "
fi

# 3.5 coverage
if [ "$cov" -ge 100 ]; then
  fb+="✅ 100% coverage. "
  points=$((points+3))
else
  fb+="❌ coverage <100% ($cov%). "
fi

echo "Score: $points/$max"
echo "Feedback: $fb"
echo "{ \"tag\": \"points\", \"points\": \"$points/$max\" }" >&3

