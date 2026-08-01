# 에셋 권리대장

## 감사 범위

이 문서는 앱에 실제 포함되는 외부 이미지와 자체 제작 비주얼을 구분하고, 앱스토어 제출 전에 상업 이용 권리를 확인하기 위한 기록이다.

## 외부 에셋

| 파일 | 원본 | 사용 위치 | 라이선스 | 해시 기록 |
|---|---|---|---|---|
| `assets/icons/ball.png` | `Sprites/Ball 1.png` in `smooth_physics_props.zip` | 공 썸네일 | CC0 1.0 Universal | `assets/licenses/asset_hashes.txt` |
| `assets/icons/crate.png` | `Sprites/Crate Wood.png` in `smooth_physics_props.zip` | 상자 썸네일·게임 화면 | CC0 1.0 Universal | `assets/licenses/asset_hashes.txt` |
| `assets/icons/stone_boulder.png` | `Sprites/Stone Boulder.png` in `smooth_physics_props.zip` | 무거운 돌 썸네일·게임 화면 | CC0 1.0 Universal | `assets/licenses/asset_hashes.txt` |

- 원저작자: Reactorcore
- 작품명: Smooth Physics Obstacle Props
- 원본 페이지: https://opengameart.org/content/smooth-physics-obstacle-props
- CC0 안내: https://creativecommons.org/publicdomain/zero/1.0/
- CC0 법적 코드: https://creativecommons.org/publicdomain/zero/1.0/legalcode
- 원본 압축파일: `assets/downloads/smooth_physics_props.zip`
- 변환 이력: 현재 세 파일은 원본 압축파일의 PNG와 바이트 동일하며, 게임 렌더러에서 크기와 위치만 조정한다.
- 출처 표기 정책: CC0 조건상 의무는 없지만 스토어·저작권 문서에는 `Smooth Physics Obstacle Props by Reactorcore, CC0`를 권장 표기로 사용한다.
- 해시 검증: `shasum -a 256 -c assets/licenses/asset_hashes.txt`를 실행하며, 파일이 교체되면 체크섬 행만 갱신한다.

## 자체 제작·생성 비주얼

- `lib/game/property_shot_game.dart`의 Canvas 렌더링: 프로젝트 자체 코드, 별도 외부 라이선스 없음.
- `assets/icons/property_shot_app_icon_source.png`: 프로젝트 전용 생성 이미지. 생성 프롬프트와 사용 목적은 `harness_docs/release/store_assets.md`에 기록한다.
- `assets/generated/crate-v2.png`: Codex 기본 이미지 생성 도구로 만든 고해상도 상자 스프라이트. 외부 원본을 입력하지 않았고 초록색 키 배경을 알파로 제거해 게임 화면과 팝업에 사용한다. 생성 프롬프트 요약과 상업 이용 전 최종 권리 검토 항목은 `harness_docs/release/store_assets.md`에 기록한다.

## 출품 전 확인 항목

- [ ] OpenGameArt 원본 페이지와 CC0 안내의 오프라인 보존본 추가
- [ ] 최종 번들에 포함되는 파일 목록과 해시 재생성
- [ ] 개발자 또는 법무 담당자의 최종 검토자·검토일 기록
- [ ] 앱스토어 제출 자료에 권장 출처 표기 반영
