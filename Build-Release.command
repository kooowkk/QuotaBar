#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
# Builds locally; no cloud runner, upload, signing subscription, or account export.
bash scripts/build.sh universal
version="$(cat VERSION)"
release_name="QuotaBar-$version-macOS-universal"
mkdir -p dist
staging="$(mktemp -d "$PWD/build/release.XXXXXX")"
trap 'rm -rf "$staging"' EXIT
mkdir -p "$staging/$release_name"
ditto build/QuotaBar.app "$staging/$release_name/QuotaBar.app"
cp docs/INSTALL.md "$staging/$release_name/READ-ME-FIRST.md"
cp LICENSE THIRD_PARTY_NOTICES.md PRIVACY.md "$staging/$release_name/"
# Only the clean bundle and public docs are packaged. No home-directory files.
ditto -c -k --keepParent "$staging/$release_name" "dist/$release_name.zip"
(cd dist && shasum -a 256 "$release_name.zip" > "$release_name.zip.sha256")
open dist
echo '배포 ZIP 생성 완료. 새 앱을 실제로 테스트한 뒤 GitHub Releases에 ZIP과 sha256을 올리세요.'
echo '이 명령은 GitHub에 자동으로 게시하지 않습니다.'
