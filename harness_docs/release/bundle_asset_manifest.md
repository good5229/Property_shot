# 번들 자산 목록

이 문서는 출시 빌드에 포함되는 자산과 저장소에만 보존하는 원본·권리 증거를 구분한다. `build/` 산출물은 저장소에 커밋하지 않으며, 배포 후보 빌드마다 목록을 다시 검증한다.

## 앱 자산

| 경로 | 용도 | 권리 상태 |
|---|---|---|
| `assets/generated/crate-v2.png` | 상자 썸네일·게임 오브젝트 고해상도 스프라이트 | 생성 기록과 상업 이용 전 최종 권리 검토 필요 |
| `assets/generated/stone-v2.png` | 무거운 돌 썸네일·게임 오브젝트 고해상도 스프라이트 | 생성 기록과 상업 이용 전 최종 권리 검토 필요 |
| `assets/generated/jelly-bumper-v1.png` | 젤리 썸네일·게임 오브젝트 고해상도 스프라이트 | 생성 기록과 상업 이용 전 최종 권리 검토 필요 |
| `assets/generated/island-{observatory,lighthouse,bridge}-v1.png` | 섬 복구 현황·집중 지원·완료 연출 시설 컷아웃 | 섬 세계 배경을 참조한 프로젝트 전용 생성 자산, 최종 권리 검토 필요 |
| `assets/generated/nav-{physics-lab,expedition,reward-satchel}-v1.png` | 실험실·관측일지/탐사·런 보상 메뉴 이미지 | 섬 세계 배경을 참조한 프로젝트 전용 생성 자산, 최종 권리 검토 필요 |
| `assets/generated/island-restoration-world-v1.webp` | 홈·섬 지도 세계 배경 | 프로젝트 전용 생성 자산, 최종 권리 검토 필요 |
| `assets/stages/chapter_1.json` | 1장 10단계 정의 | 프로젝트 자체 데이터 |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/` | iOS 아이콘 파생 파일 | 원본에서 규격별 생성 |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/` | 런치 화면 | 프로젝트 전용 구성 |
| `assets/fonts/NanumGothic-*.ttf` | 한글 UI 글꼴 | OFL-1.1, `assets/fonts/OFL.txt` 보관 |
| `assets/audio/property_shot_island_loop.wav` | 모바일·Web 배경 음악 | 프로젝트 자체 합성·생성 스크립트와 SHA-256 보관 |

## 저장소 보존 자산

아래 파일은 출처·재현·편집을 위한 증거이며 `pubspec.yaml`과 Flutter 제품 번들에는 포함하지 않는다.

| 경로 | 보존 목적 |
|---|---|
| `assets/icons/ball.png` | CC0 원본 대조용 레거시 공 |
| `assets/icons/crate.png` | CC0 원본 대조용 레거시 상자 |
| `assets/icons/stone_boulder.png` | CC0 원본 대조용 레거시 돌 |
| `assets/generated/jelly-bumper-v1-source.png` | 젤리 스프라이트 생성·변환 원본 |
| `assets/icons/property_shot_app_icon_source.png` | 플랫폼 앱 아이콘 편집 원본 |
| `assets/downloads/smooth_physics_props.zip` | 외부 CC0 원본 압축파일 |
| `assets/licenses/` | 출처 페이지·법적 코드·해시 증거 |

## 재현 명령

```bash
find build/web/assets/assets -type f | sort

# 저장소에 고정한 자산 해시를 검증한다.
shasum -a 256 -c assets/licenses/asset_hashes.txt

# 제품 번들 경계를 자동 검증한다.
flutter test test/bundle_asset_contract_test.dart
```

## 제출 전 확인

- [x] Flutter Web Release에서 실행 자산 포함·보관 자산 제외 확인
- [ ] 서명된 최종 모바일 앱에서 위 경로가 실제 포함되는지 확인
- [ ] 최종 IPA 또는 앱 번들의 해시를 별도 보관
- [x] 권리대장의 내부 기술 검토자·검토일 기록
- [ ] 개발자 또는 법무 담당자의 최종 권리 승인 기록
