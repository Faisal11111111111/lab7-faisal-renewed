#!/bin/bash
cd presidio-anonymizer
source /home/codegrade/project/.venv/bin/activate 2>/dev/null

points=0; max=15; fb=""
file=tests/operators/test_encrypt.py

# 4.1 function name
grep -q "def test_valid_keys" "$file" \
  && { fb+="✅ has test_valid_keys. "; points=$((points+3)); } \
  || fb+="❌ missing test_valid_keys. "

# 4.2 decorator check — search up to 30 lines before the function
start_line=$(grep -n "def test_valid_keys" "$file" | cut -d: -f1 | head -n1)
if [ -n "$start_line" ]; then
  if awk -v n="$start_line" 'NR>=n-30 && NR<n {print}' "$file" | grep -q "@pytest.mark.parametrize"; then
    fb+="✅ parametrize above function. "; points=$((points+3));
  else
    fb+="❌ parametrize not found above. "
  fi
else
  fb+="⚠️ could not locate function line for decorator check. "
fi

# 4.3 count at least six items inside parametrize list
list_count=$(awk '/@pytest.mark.parametrize/{flag=1;next}/def test_valid_keys/{flag=0}flag' "$file" \
            | grep -cE '["'"'"']|b['"'"'']')
if [ "$list_count" -ge 6 ]; then
  fb+="✅ six key cases found. "; points=$((points+3));
else
  fb+="❌ fewer than six key cases. "
fi

# 4.4 verify includes both string and bytes keys
grep -Eq '"a" \* 16' "$file" && s_ok=1 || s_ok=0
grep -Eq 'b"a" \* 16' "$file" && b_ok=1 || b_ok=0
if [ $s_ok -eq 1 ] && [ $b_ok -eq 1 ]; then
  fb+="✅ includes both string and bytes keys. "; points=$((points+3));
else
  fb+="❌ missing string or bytes key type. "
fi

# 4.5 validate() call in test body
if grep -A10 "def test_valid_keys" "$file" | grep -Eq "Encrypt\(\)\.validate|\.validate"; then
  fb+="✅ calls validate() in test body. "; points=$((points+3));
else
  fb+="❌ missing validate() call. "
fi

echo "Score: $points/$max"
echo "Feedback: $fb"

# Output JSON only if FD 3 exists (CodeGrade)
if [ -e /proc/$$/fd/3 ]; then
  echo "{ \"tag\": \"points\", \"points\": \"$points/$max\" }" >&3
fi
