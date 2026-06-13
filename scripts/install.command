#!/usr/bin/env bash
# DropJPG 설치 도우미 — 개발자 인증서가 없어 Gatekeeper가 막는 quarantine 속성을 제거합니다.
# 사용법: 1) DropJPG.app 을 Applications 폴더로 드래그  2) 이 파일을 더블클릭
set -e

APP="/Applications/DropJPG.app"

echo "============================================"
echo "  DropJPG 설치 도우미"
echo "============================================"
echo

if [ ! -d "$APP" ]; then
    echo "❌ /Applications/DropJPG.app 을 찾을 수 없습니다."
    echo "   먼저 DropJPG.app 을 Applications 폴더로 드래그한 뒤 다시 실행하세요."
    echo
    read -n 1 -s -r -p "아무 키나 누르면 닫힙니다…"
    exit 1
fi

echo "▶ quarantine 속성 제거 중…"
xattr -dr com.apple.quarantine "$APP" || true
echo "▶ 실행 권한 확인 중…"
chmod +x "$APP/Contents/MacOS/DropJPG" 2>/dev/null || true

echo "✅ 완료! DropJPG 를 실행합니다."
open "$APP"
echo
echo "메뉴바 상단에 아이콘이 나타납니다. (Dock에는 표시되지 않음)"
sleep 1
