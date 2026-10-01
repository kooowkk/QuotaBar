#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
if [[ "$(uname -s)" != Darwin ]]; then echo 'macOS에서 실행해 주세요.'; exit 1; fi
if pgrep -x QuotaBar >/dev/null; then
  echo '기존 QuotaBar 설정 → QuotaBar 종료를 누른 뒤 다시 실행하세요.'; exit 1
fi
bash scripts/build.sh
mkdir -p "$HOME/Applications"
target="$HOME/Applications/QuotaBar.app"
if [[ -e "$target" ]]; then
  mv "$target" "$HOME/Applications/QuotaBar-backup-$(date +%Y%m%d-%H%M%S)-$$.app"
fi
ditto build/QuotaBar.app "$target"
open "$target"
echo '설치 완료. 메뉴바 구독 → 구독 관리·설정 → 연결 도우미를 확인하세요.'
echo '기존 계정 로그인과 구독 설정은 유지됩니다.'
