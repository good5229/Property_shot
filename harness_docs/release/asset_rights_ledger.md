# 에셋 권리대장

## 감사 범위

이 문서는 앱에 실제 포함되는 외부 이미지와 자체 제작 비주얼을 구분하고, 상업 공개 전에 이용 권리를 확인하기 위한 기록이다. 기술 교차검토와 법무 승인은 별개이며, 이 문서의 내부 검토 기록은 법률 의견을 대신하지 않는다.

## 외부 에셋

| 파일 | 원본 | 사용 위치 | 라이선스 | 해시 기록 |
|---|---|---|---|---|
| `assets/icons/ball.png` | `Sprites/Ball 1.png` in `smooth_physics_props.zip` | 레거시 보관 자산, 현재 UI 미사용 | CC0 1.0 Universal | `assets/licenses/asset_hashes.txt` |
| `assets/icons/crate.png` | `Sprites/Crate Wood.png` in `smooth_physics_props.zip` | 레거시 보관 자산, 현재 UI 미사용 | CC0 1.0 Universal | `assets/licenses/asset_hashes.txt` |
| `assets/icons/stone_boulder.png` | `Sprites/Stone Boulder.png` in `smooth_physics_props.zip` | 레거시 보관 자산, 현재 UI 미사용 | CC0 1.0 Universal | `assets/licenses/asset_hashes.txt` |

- 원저작자: Reactorcore
- 작품명: Smooth Physics Obstacle Props
- 원본 페이지: https://opengameart.org/content/smooth-physics-obstacle-props
- 원본 페이지 오프라인 보존본: `assets/licenses/opengameart-smooth-physics-obstacle-props.html`
- CC0 안내: https://creativecommons.org/publicdomain/zero/1.0/
- CC0 법적 코드: https://creativecommons.org/publicdomain/zero/1.0/legalcode
- CC0 법적 코드 오프라인 보존본: `assets/licenses/cc0-1.0-legalcode.html`
- 원본 압축파일: `assets/downloads/smooth_physics_props.zip`
- 변환 이력: 현재 세 파일은 원본 압축파일의 PNG와 바이트 동일하며, 게임 렌더러에서 크기와 위치만 조정한다.
- 출처 표기 정책: CC0 조건상 의무는 없지만 스토어·저작권 문서에는 `Smooth Physics Obstacle Props by Reactorcore, CC0`를 권장 표기로 사용한다.
- 해시 검증: `shasum -a 256 -c assets/licenses/asset_hashes.txt`를 실행하며, 파일이 교체되면 체크섬 행만 갱신한다.

### 런 보상 아이콘

- 자산: Flutter `Icons`가 제공하는 Google Material Icons 9종(기존 런 보상 8종+다음 스테이지 팁 1종)
- 용도: 런 보상 효과별 식별 아이콘
- 원본: https://github.com/google/material-design-icons
- 라이선스: Apache License 2.0
- 라이선스 원문: https://github.com/google/material-design-icons/blob/master/LICENSE
- 번들 방식: `uses-material-design: true`를 통해 Flutter가 아이콘 글꼴을 포함하며 별도 래스터 파일을 추가하지 않는다.

## 자체 제작·생성 비주얼

- `lib/game/property_shot_game.dart`의 Canvas 렌더링: 프로젝트 자체 코드, 별도 외부 라이선스 없음.
- `assets/icons/property_shot_app_icon_source.png`: 프로젝트 전용 생성 이미지. 생성 프롬프트와 사용 목적은 `harness_docs/release/store_assets.md`에 기록한다.
- `assets/generated/crate-v2.png`: Codex 기본 이미지 생성 도구로 만든 고해상도 상자 스프라이트. 외부 원본을 입력하지 않았고 초록색 키 배경을 알파로 제거해 게임 화면과 팝업에 사용한다. 생성 프롬프트 요약과 상업 이용 전 최종 권리 검토 항목은 `harness_docs/release/store_assets.md`에 기록한다.
- `assets/generated/stone-v2.png`: Codex 기본 이미지 생성 도구로 만든 고해상도 무거운 돌 스프라이트. 외부 원본을 입력하지 않았고 초록색 키 배경을 알파로 제거해 게임 화면과 팝업에 사용한다. 생성 프롬프트 요약과 상업 이용 전 최종 권리 검토 항목은 `harness_docs/release/store_assets.md`에 기록한다.
- `assets/generated/jelly-bumper-v1.png`: Codex 기본 이미지 생성 도구로 만든 고해상도 젤리 범퍼 스프라이트. 외부 원본을 입력하지 않았고 초록색 키 배경을 알파로 제거해 게임 화면과 팝업에 사용한다. 원본과 변환 이력, 생성 프롬프트 요약과 상업 이용 전 최종 권리 검토 항목은 `harness_docs/release/store_assets.md`에 기록한다.
- `assets/generated/gate-closed-v1.png`, `switch-pad-v1.png`, `balloon-v1.png`: 첫 항해 단계 삽화의 팔레트·외곽선·장난감 질감을 내부 스타일 참조로 사용한 프로젝트 전용 RGBA 게임 기믹 스프라이트다. 문은 코드가 좌우 패널을 분리해 개방 상태를 표현하고, 스위치와 풍선은 실제 판정 상태에 맞춰 압축·색 변화·파열 연출을 적용한다. 제3자 이미지·텍스트·로고·워터마크는 입력하지 않았다.
- `assets/generated/ball-{base,heavy,bouncy,sticky,sharp}-v1.png`, `hole-flag-v1.png`, `wall-segment-v1.png`, `crate-v3.png`, `stone-v3.png`, `jelly-bumper-v2.png`, `sticky-pad-v1.png`, `spike-source-v1.png`, `power-slider-v1.png`, `rotating-reflector-v1.png`: 게임 보드의 남은 Canvas 표현과 구형 고세부 스프라이트를 같은 장난감 섬 팔레트와 굵은 청록 외곽선으로 통일한 프로젝트 전용 RGBA 자산이다. 내부 단계 삽화와 기존 자체 생성 자산만 시각 언어 참고로 사용했고, 외부 작품·문자·로고·워터마크를 입력하지 않았다. 실제 물리 충돌체는 이미지와 독립된 기존 좌표·크기를 유지한다.
- `assets/generated/island-restoration-world-v1.webp`: Codex 기본 이미지 생성 도구로 만든 프로젝트 전용 섬 세계 배경을 WebP로 최적화한 번들 자산. 외부 이미지를 입력하거나 특정 작품의 화풍을 요구하지 않았으며, 관측소·등대·다리의 복구 목표를 홈과 섬 지도에서 한 장면으로 연결한다. 생성 프롬프트와 사용 목적은 `harness_docs/release/store_assets.md`에 기록한다.
- `assets/generated/island-observatory-v2.png`, `island-lighthouse-v2.png`, `island-bridge-v2.png`: 첫 항해 단계 삽화의 팔레트·굵은 외곽선·둥근 장난감 질감을 시각 참조로 사용해 다시 만든 RGBA 시설 컷아웃이다. 복구 상태는 UI에서 동일 이미지의 회색 바탕을 컬러로 채워 표현하며, 제3자 이미지나 특정 작품명은 입력하지 않았다.
- `assets/generated/nav-physics-lab-v1.png`, `nav-expedition-v1.png`, `nav-reward-satchel-v1.png`: Material 기호만으로 구분하기 어려운 핵심 메뉴를 위해 섬 세계 배경의 팔레트·재질만 참조해 생성한 RGBA 메뉴 컷아웃이다. 실험 장치·나침반/관측일지·보상 가방을 각각 나타내며 글자·로고·워터마크를 포함하지 않는다.
- `assets/generated/nav-helm-v1.png`, `nav-stage-map-v1.png`, `nav-replay-v1.png`, `nav-daily-challenge-v1.png`, `nav-activities-v1.png`, `hint-key-v1.png`, `hint-lantern-v2.png`: 시작·지도·리플레이·오늘의 도전·활동 묶음·힌트의 장식형 이모지와 일반 기호를 대체하는 프로젝트 전용 RGBA 삽화다. 등불 v2는 24~40px 표시에서 깨져 보이던 미세 장식과 광점을 제거하고 큰 발광 몸체·손잡이·받침만 남긴 소형 표시 전용 자산이다. 첫 항해 단계 삽화만 내부 스타일 참조로 사용했으며 글자·로고·워터마크·제3자 이미지를 입력하지 않았다.
- `assets/generated/stage-icon-*-v1.png` 10종: 첫 항해의 각 단계가 가르치는 무거움·탄성·스위치/문·뾰족함/풍선·속성 이전·가속 발판·잔류 공·연쇄 점수·회전 반사판·속성 종합을 각각 한 장면으로 표현한 프로젝트 전용 RGBA 삽화다. 기존 프로젝트 돌·젤리 자산만 팔레트와 재질 참고로 입력했고, 생성 뒤 흰색·격자 배경을 별도 이미지 편집으로 실제 알파 처리했다. 글자·로고·워터마크·제3자 작품명은 입력하지 않았다.
- 생성 자산과 NanumGothic 글꼴의 현재 SHA-256은 `assets/licenses/asset_hashes.txt`에 함께 고정한다. 자산 교체 시 생성 원본·변환 이력·최종 번들 목록과 해시를 같은 작업에서 갱신한다.
- 게임 보드의 공 얼굴·광택·속성 색상은 위 속성 공 스프라이트를 사용하고, `GameBallIconPainter`는 시각 자산을 비활성화한 테스트와 비게임 UI의 안전한 대체 표현으로 유지한다. `assets/icons/ball.png`는 저장소에 권리 증거로 남지만 제품 번들에서는 제외한다.
- 가속 발판은 `power-slider-v1.png`가 기본 몸체와 방향 화살표를 담당하고, 실제 작동 링과 속도 피드백은 `lib/game/property_shot_game.dart`의 Canvas 연출을 유지한다. 390×844·768×1024 Golden에서 물리 방향과 이미지 회전의 일치를 검증한다.
- `assets/audio/property_shot_island_loop.wav`: `tool/generate_background_music.dart`가 22,050Hz 모노 PCM으로 결정론적 생성한 16초 섬 테마다. 코드에 고정한 화음·벨·펄스 합성만 사용하며 외부 음원·샘플·생성형 오디오 입력은 없다. 같은 스크립트를 다시 실행해 재현할 수 있고 SHA-256은 `assets/licenses/asset_hashes.txt`에 고정한다.
- `audioplayers 6.8.1`: 위 자체 음원을 Android·iOS·Web에서 반복 재생하는 MIT 라이선스 Flutter 패키지다. 패키지 음원은 사용하지 않으며 `pubspec.lock`과 Flutter 라이선스 고지에 버전·라이선스를 보존한다.

## 제품 번들 경계

- Flutter 자산 선언은 디렉터리 단위가 아니라 최종 실행 파일 단위로 고정한다.
- 제품 번들에는 플레이 스프라이트 3개, 섬 세계 배경 1개, 시설·메뉴·힌트 컷아웃, 단계 삽화 10개, 자체 음악 1개, 단계 정의 1개와 선언된 글꼴만 포함한다.
- 생성 원본, 앱 아이콘 작업 원본, CC0 레거시 이미지, 라이선스 증거와 README는 저장소에는 보존하되 Flutter 자산 번들에서 제외한다.
- `test/bundle_asset_contract_test.dart`가 실행 파일의 포함과 보관 파일의 제외를 회귀 검사한다.

## 검토 기록

| 검토일 | 검토자 | 범위 | 결과 |
|---|---|---|---|
| 2026-08-08 KST | Codex 내부 교차검토 | 출처·오프라인 증거·해시·Flutter 번들 경계 | 기술 증거 일치, 법무 승인 미수행 |

## 상업 공개 전 확인 항목

- [x] OpenGameArt 원본 페이지와 CC0 안내의 오프라인 보존본 추가
- [x] Flutter Web Release에서 최종 번들 파일 목록 검증
- [x] 내부 기술 검토자·검토일 기록
- [ ] 개발자 또는 법무 담당자의 최종 권리 승인 기록
- [ ] 앱스토어 제출 자료에 권장 출처 표기 반영
