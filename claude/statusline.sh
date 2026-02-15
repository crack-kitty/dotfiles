#!/bin/bash

# Find Python (python3 on Linux/Mac, python on Windows)
PY=$(command -v python3 2>/dev/null || command -v python 2>/dev/null)
[ -z "$PY" ] && { echo "Claude"; exit 0; }

$PY -c "
import sys, json
try:
    data = json.load(sys.stdin)
    model = data.get('model', {}).get('display_name', 'Claude')
    cw = data.get('context_window', {})
    used = cw.get('used_percentage')
    remaining = cw.get('remaining_percentage')
    if used is None or remaining is None:
        print(model, end='')
        sys.exit(0)
    used_int = int(round(used))
    rem_int = int(round(remaining))
    if used_int >= 90:
        c = '\033[31m'
    elif used_int >= 70:
        c = '\033[33m'
    else:
        c = '\033[32m'
    r = '\033[0m'
    s = f'{c}{model}{r} | Context: {c}{used_int}%{r}'
    if rem_int <= 5:
        s += f' {c}[CRITICAL: {rem_int}% remaining!]{r}'
    elif rem_int <= 10:
        s += f' {c}[WARNING: {rem_int}% remaining]{r}'
    print(s, end='')
except Exception:
    print('Claude', end='')
"
