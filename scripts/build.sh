#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
trap 'echo "빌드 중 오류가 발생했습니다. 위 오류를 확인하세요. 앱 설치·배포는 중단되었습니다." >&2' ERR
if [[ "$(uname -s)" != Darwin ]]; then
  echo 'macOS 14 이상에서 실행해 주세요.' >&2; exit 1
fi
if (( $(sw_vers -productVersion | cut -d. -f1) < 14 )); then
  echo 'macOS 14 이상이 필요합니다.' >&2; exit 1
fi
if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo 'Apple 개발 도구가 필요합니다. 설치 창에서 설치한 뒤 이 파일을 다시 실행하세요.'
  xcode-select --install || true
  exit 1
fi
build_arch="${1:-$(uname -m)}"
case "$build_arch" in arm64|x86_64|universal) ;; *) echo '지원하지 않는 빌드 대상'; exit 1 ;; esac
version="$(cat VERSION)"
mkdir -p build
printf '\n1/3 데이터 계산 검사\n'
xcrun swiftc -swift-version 5 Sources/Core.swift Tests/main.swift -o build/QuotaBarChecks
./build/QuotaBarChecks
printf '\n2/3 앱 빌드 (%s)\n' "$build_arch"
bundle="$PWD/build/QuotaBar.app"
# Remove only a prior generated bundle, never the installed app or user settings.
rm -rf "$bundle"
mkdir -p "$bundle/Contents/MacOS" "$bundle/Contents/Resources"
compile_arch() {
  xcrun swiftc -swift-version 5 -O -parse-as-library -target "$1-apple-macosx14.0" \
    Sources/Core.swift Sources/Setup.swift Sources/QuotaBar.swift -o "build/QuotaBar-$1" \
    -framework SwiftUI -framework AppKit -framework Security -framework ServiceManagement
}
if [[ "$build_arch" == universal ]]; then
  compile_arch arm64
  compile_arch x86_64
  xcrun lipo -create build/QuotaBar-arm64 build/QuotaBar-x86_64 -output "$bundle/Contents/MacOS/QuotaBar"
else
  compile_arch "$build_arch"
  cp "build/QuotaBar-$build_arch" "$bundle/Contents/MacOS/QuotaBar"
fi
cp Resources/*.command "$bundle/Contents/Resources/"
chmod 755 "$bundle/Contents/MacOS/QuotaBar" "$bundle/Contents/Resources/"*.command
cp LICENSE THIRD_PARTY_NOTICES.md PRIVACY.md "$bundle/Contents/Resources/"
cat > "$bundle/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleIdentifier</key><string>local.quotabar.app</string>
<key>CFBundleName</key><string>QuotaBar</string>
<key>CFBundleDisplayName</key><string>QuotaBar</string>
<key>CFBundleExecutable</key><string>QuotaBar</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>CFBundleShortVersionString</key><string>0.2.0</string>
<key>CFBundleVersion</key><string>11</string>
<key>LSMinimumSystemVersion</key><string>14.0</string>
<key>LSUIElement</key><true/>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
plutil -lint "$bundle/Contents/Info.plist"
printf '\n3/3 로컬 서명 및 검증\n'
codesign --force --sign - "$bundle"
codesign --verify --strict --verbose=2 "$bundle"
echo "완료: $bundle ($version). Apple 공증을 받은 앱은 아닙니다."
