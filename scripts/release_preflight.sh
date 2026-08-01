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

check_png_dimensions() {
  local file="$1"
  local expected_width="$2"
  local expected_height="$3"
  local width
  local height
  [[ -f "$file" ]] || return 1
  command -v sips >/dev/null 2>&1 || return 1
  width="$(sips -g pixelWidth "$file" 2>/dev/null | awk '/pixelWidth:/{print $2}')"
  height="$(sips -g pixelHeight "$file" 2>/dev/null | awk '/pixelHeight:/{print $2}')"
  [[ "$width" == "$expected_width" && "$height" == "$expected_height" ]]
}

check_item "Info.plist 문법" plutil -lint ios/Runner/Info.plist
check_item "Bundle ID가 예시값이 아님" bash -c "! rg -q 'com\\.example\\.propertyShot' ios/Runner.xcodeproj/project.pbxproj"
check_item "Development Team 설정" bash -c "rg -q 'DEVELOPMENT_TEAM = [A-Z0-9]+' ios/Runner.xcodeproj/project.pbxproj"
check_item "권리 해시" shasum -a 256 -c assets/licenses/asset_hashes.txt
check_item "CC0 원본 Git 추적" git ls-files --error-unmatch assets/downloads/smooth_physics_props.zip
check_item "출시 문서 Git 추적" git ls-files --error-unmatch harness_docs/release/app_store_metadata.md
check_item "권리 문서 Git 추적" git ls-files --error-unmatch assets/licenses/asset_hashes.txt
check_item "최신 검증 문서 Git 추적" git ls-files --error-unmatch harness_docs/qa/validation_results.md
check_item "앱 아이콘 카탈로그" bash -c "test -f ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json && rg -q 'Icon-App-1024x1024@1x.png' ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json"
check_item "서명 인증서 존재" bash -c "security find-identity -v -p codesigning 2>/dev/null | rg -q 'valid identities found: [1-9]'"
check_item "iPhone 제출 캡처" test -f screenshots/iphone-portrait-gameplay.png
check_item "iPad 제출 캡처" test -f screenshots/ipad-portrait-gameplay.png
check_item "iPhone 캡처 픽셀 규격" check_png_dimensions screenshots/iphone-portrait-gameplay.png 1284 2778
check_item "iPad 캡처 픽셀 규격" check_png_dimensions screenshots/ipad-portrait-gameplay.png 2048 2732
check_item "정책 URL 확정" bash -c "! rg -q '^[-*] \\[ \\] .*URL' harness_docs/release/app_store_metadata.md && ! rg -q '공개 예정|확인 전에는' harness_docs/release/app_store_metadata.md"
check_item "권리대장 검토자 기록" bash -c "! rg -q '\\[ \\] .*검토자' harness_docs/release/asset_rights_ledger.md"
check_item "개인정보 처리방침 준비본" test -f docs/privacy-policy.html
check_item "지원 페이지 준비본" test -f docs/support.html

if (( failures > 0 )); then
  printf '\n출품 사전검사 실패: 외부 설정 또는 제출 자료를 보완해야 합니다.\n'
  exit 1
fi

printf '\n출품 사전검사 통과: 서명·실기기 설치·TestFlight 업로드만 별도 확인하세요.\n'
