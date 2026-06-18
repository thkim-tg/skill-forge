#!/bin/bash
# ugc-image-gen 스킬 설치
# 사용법: bash install.sh
SKILL_DIR="$HOME/.claude/skills/ugc-image-gen"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$SKILL_DIR"
cp "$SCRIPT_DIR/SKILL.md" "$SKILL_DIR/SKILL.md"
echo "✅ 설치 완료: $SKILL_DIR"
echo "   Claude Code에서 '/ugc-image-gen' 또는 'UGC 이미지 만들어줘'로 사용"
