#!/bin/bash
set -euo pipefail
export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"
mkdir -p "$HOME/QuotaBar-Connect"
cd "$HOME/QuotaBar-Connect"
if ! command -v claude >/dev/null 2>&1; then
  echo 'Claude 도구를 찾지 못했습니다. QuotaBar 연결 도우미의 공식 설치 안내를 확인하세요.'
  exit 1
fi
echo '본인 구독 계정으로 로그인하세요. 이 창의 인증 URL이나 코드를 다른 사람에게 보내지 마세요.'
claude auth login
echo '로그인 명령이 종료되었습니다. QuotaBar에서 구독 수정 → CodexBar 연결 → 저장 및 조회를 진행하세요.'
