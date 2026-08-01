#!/usr/bin/env bash
set -euo pipefail

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root_dir"

failures=0
check_item() {
  local name="$1"
  shift
  if "$@"; then
    printf '통과: %s\n' "$name"
  else
    printf '실패: %s\n' "$name"
    failures=1
  fi
}

check_item "Info.plist 문법" plutil -lint ios/Runner/Info.plist
check_item "Bundle ID가 예시값이 아님" bash -c "! rg -q 'com\\.example\\.propertyShot' ios/Runner.xcodeproj/project.pbxproj"
check_item "Development Team 설정" bash -c "rg -q 'DEVELOPMENT_TEAM = [A-Z0-9]+' ios/Runner.xcodeproj/project.pbxproj"
check_item "권리 해시" shasum -a 256 -c assets/licenses/asset_hashes.txt
check_item "출시 문서 추적 가능" bash -c "! git check-ignore -q harness_docs/release/app_store_metadata.md"
check_item "iPhone 제출 캡처" test -f screenshots/iphone-portrait-gameplay.png
check_item "iPad 제출 캡처" test -f screenshots/ipad-portrait-gameplay.png
check_item "정책 URL 확정" bash -c "! rg -q '^[-*] \\[ \\] .*URL' harness_docs/release/app_store_metadata.md"
check_item "권리대장 검토자 기록" bash -c "! rg -q '\\[ \\] .*검토자' harness_docs/release/asset_rights_ledger.md"

if (( failures > 0 )); then
  printf '\n출품 사전검사 실패: 외부 설정 또는 제출 자료를 보완해야 합니다.\n'
  exit 1
fi

printf '\n출품 사전검사 통과: 서명·실기기 설치·TestFlight 업로드만 별도 확인하세요.\n'
