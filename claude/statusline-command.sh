#!/bin/bash
input=$(cat)

# Model - handle both string and object formats
MODEL=$(echo "$input" | jq -r 'if .model | type == "object" then .model.display_name else .model // "claude" end' | sed 's/ (.*//')

# Git branch
CWD=$(echo "$input" | jq -r '.cwd // empty')
[ -z "$CWD" ] && CWD=$(pwd)
GIT_BRANCH=$(git -C "$CWD" symbolic-ref --short HEAD 2>/dev/null || echo "—")

# Context window usage
PCT=$(echo "$input" | jq -r '.context_window.used_percentage // 0' | cut -d. -f1)

printf "🤖 %s │ 📂 %s │ 🌿 %s │ 📊 %s%%" "$MODEL" "$CWD" "$GIT_BRANCH" "$PCT"
