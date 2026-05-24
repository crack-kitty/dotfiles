#!/bin/bash
input=$(cat)

# Model - handle both string and object formats
MODEL=$(echo "$input" | jq -r 'if .model | type == "object" then .model.display_name else .model // "claude" end' | sed 's/ (.*//')

# Git branch
CWD=$(echo "$input" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD=$(pwd)
GIT_BRANCH=$(git -C "$CWD" symbolic-ref --short HEAD 2>/dev/null || echo "—")

# Context window usage
USED=$(echo "$input" | jq -r '((.context_window.total_input_tokens // 0) + (.context_window.total_output_tokens // 0))')
MAX=$(echo  "$input" | jq -r '.context_window.context_window_size // 200000')
PCT=$(echo  "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)
USED_K=$(( USED / 1000 ))
MAX_K=$((  MAX  / 1000 ))

# Rate limits
RL5=$(echo "$input" | jq -r '.rate_limits.five_hour.used_percentage // 0' | cut -d. -f1)
RL7=$(echo "$input" | jq -r '.rate_limits.seven_day.used_percentage // 0' | cut -d. -f1)

printf "🤖 %s │ 📂 %s │ 🌿 %s │ 🧠 %sk/%sk %s%% │ ⏱ 5h:%s%% 7d:%s%%" \
  "$MODEL" "$CWD" "$GIT_BRANCH" "$USED_K" "$MAX_K" "$PCT" "$RL5" "$RL7"
