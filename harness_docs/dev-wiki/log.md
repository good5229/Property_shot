# Dev-Wiki Log

Append-only chronology.

Use consistent headings so entries are easy to grep.

## [2026-08-06] physics-qa | PS-OBJ-02 final PASS

- Sol 최종 통합에서 테스트 호스트의 `Canvas.toImage` 대기가 끝나지 않는 보조 crop 검사를 제거하고, 제품 코드에 남아 있던 테스트 전용 완료 보류 플래그도 함께 제거했다. 화면 검증은 390x844·768x1024의 14개 Golden과 실제 orientation 0·1·2 렌더 상태, 일반·저모션 다중 회전 일정 검사로 유지한다.
- 강화된 replay signature가 기존 저장 지문과 충돌한 두 회귀를 확인했다. 단일 샷 16개·다중 샷 20개 fixture의 입력, 경로 태그, 예상 종료 상태는 그대로 두고 fingerprint만 재생성했으며 두 저장 재생 테스트가 통과했다.
- 독립 QA가 비자격 impact의 가짜 회전 검출 누락, 연쇄 이동체의 impact·rotation 결과 속도 불일치, 회전 뒤 고정된 터치·접근성 영역을 찾아 1차 FAIL 판정했다. 모든 회전이 정확히 하나의 qualifying 부모를 요구하도록 probe를 강화하고, 반사판 impact에 실제 `velocityAfter`를 기록하며, 회전 OBB 선택 영역을 적용했다. 세 재현 회귀를 추가한 뒤 두 번째 독립 검토는 새 P0/P1 없이 PASS했다.
- 최종 증거는 회전판 물리 30개, runtime probe 25개, 회전판 화면 16개, replay 포함 관련 집중 77개, 스테이지 선택·4단계 인과 28개, 전체 508개 테스트 통과다. `flutter analyze`, 생성 카탈로그 `--check`, Web Release 빌드와 14개 Golden 직접 비교도 통과했다.
- 기존 1~4단계 원본 카탈로그와 생성본은 변경하지 않았고, 회전 반사판의 8방향 OBB·SAT, 충돌 전 법선 반사 후 90도 회전, 동일 접촉 중복 방지, 고속 swept 순서, 벽 불변·홀·점착 우선순위, 다중 이동체와 replay 결정론을 증명해 PS-OBJ-02를 PASS 판정한다. 서버는 전체 프로젝트 완료 전까지 실행하지 않는다.

## [2026-08-06] physics-qa | PS-OBJ-02 P0 order and evidence refresh

- Sol P0에서 chain sampled loop가 반사판을 generic bisection으로 다시 처리해 첫 sample을 가짜 충돌로 반환하던 결함을 확인했다. active/chain 모두 반사판은 analytic 후보만 사용하고, analytic 후보와 일반 후보를 전체 segment progress 및 기존 stable tie 규칙으로 비교하도록 수정했다.
- 앞선 wall·hole·power slider·chain wall이 뒤쪽 반사판보다 먼저 선택되는 회귀와, 같은 방향으로 멀리 있는 반사판이 chain 첫 sample에서 회전하지 않는 회귀를 추가했다.
- 기존 FAIL 목록을 독립 fixture로 확장했다. 동일 contact 1회·완전 이탈 후 재진입 2회, 회전 직후 새 OBB 겹침 중복 0회, 다중 reflector·movable source 안정 순서, 얇은 벽 전체 상태 불변, 8방향 기대 반사 벡터, runtime rotation-before-impact/parent/velocity 위반, RunState 실제 rotation count와 샷별 fingerprint를 검증한다.
- 위 수치는 P1 보완 전 실행 증거다. P1 보완 후 최종 전체 PASS로 재사용하지 않으며, 새 집중 실행과 전체 회귀 결과를 별도로 기록한다.
- 전체 회귀의 `multi_shot_analyzer_test.dart` 한 fixture는 약 1분 40초 진행 후 통과했다. 기능 실패는 아니지만 후속 성능 분석 위험으로 남긴다.

## [2026-08-06] physics-qa | PS-OBJ-02 P1 qualifying, replay, reduced schedule

- 시작 OBB 겹침은 outward escape면 같은 MTV로 위치만 보정하고 해당 impact를 `triggersReflectorRotation=false`로 기록한다. 완전 이탈 후 재접촉은 별도 qualifying 사건으로 허용한다.
- 미래 orientation의 초기 겹침 검증은 `movable=false`인 고정 고체만 대상으로 제한하고, 여러 미래 방향에서 같은 고정 object pair가 겹쳐도 `initialObjectOverlap` 한 건만 보고한다. movable crate와의 미래 겹침은 동적 분리 계약으로 남긴다.
- replay signature와 runtime probe fingerprint에 impact·generic physics의 source/contact/qualifying 필드를 추가하고 차이 양성 테스트를 넣었다.
- 일반 회전 일정은 effectiveStart 순차 큐를 유지하고 reduced 모드는 각 원래 pathIndex에서 즉시 after를 누적한다. 같은 path의 2회 회전은 8 cursor를 추가로 기다리지 않는다.
- 최신 집중 증거: 물리 30개, runtime probe 24개, PS-OBJ-02 Golden 14개와 다중·저모션 일정 테스트 통과. 전체 회귀·analyze·생성기·Web release는 최종 실행 후 이 로그에 추가한다. Sol 최종 PASS 전 commit·push·서버 실행은 하지 않는다.

## [2026-08-06] physics-qa | PS-OBJ-02 rectangular SAT normal correction

- Sol 중간 리뷰에서 직사각형 이동체가 `_reflectorContact`의 중심점 법선을 사용해 실제 OBB 최소 분리축과 달라질 수 있는 결함을 확인했다.
- 회전판 normal·tangent·화면 x·y 4축의 overlap depth를 계산하는 공통 SAT helper를 추가하고, 최소 penetration 축과 고정 tie 순서를 충돌 법선·AABB support 분리에 함께 사용했다. 원형 공은 기존 nearest-point/corner normal 경로를 유지한다.
- end-cap, 대각 corner, 화면 축 동률, 접촉 접선 보존, residual overlap, swept 벽 재검사, movable spent ball·crate·weight와 fixed spent ball 범위를 회귀 fixture로 고정했다. 임시 출력은 제거했다.
- `rotating_reflector` 8방향 JSON·validator·PhysicsEvent/ReflectorRotation·replay signature·runtime probe·Canvas 및 한글 UI·14개 Golden을 PS-OBJ-02 문서에 반영했다.
- 검증: 집중 물리 17개, 회전판 Golden 14개, 전체 486개 테스트, `flutter analyze`, 생성 카탈로그 `--check`, Web release, `git diff --check` 통과. Sol 최종 승인 전 commit·push·서버 실행은 하지 않는다.

## [2026-08-01] tutorial | make elasticity teachable

- 일반 공도 벽에 반사되지만 탄성 공이 충돌 에너지를 더 보존하도록 조정하고, 2단계 목표와 회귀 기준을 속성 학습에 맞춘다.

## [2026-08-01] tutorial | expose sticky strategy

- 3단계 목표와 스위치 설명에 점착판 활용과 무거움 조건을 사전에 드러내 실패 후 추측에 의존하지 않게 한다.

## [2026-08-01] qa | hole edge boundary coverage

- 홀 가장자리의 허용 성공과 충분히 떨어진 근접 실패를 함께 검증해 관대한 판정의 경계를 고정한다.

## [2026-08-01] qa | tutorial and boundary count refresh

- 탄성 학습 물리와 홀 경계 회귀가 추가되어 최신 전체 테스트 수를 다시 기록한다.

## [2026-08-01] docs | tutorial contract update

- 2단계의 탄성 필수성과 벽 충돌 반발력 차이를 퍼즐 의도·물리 규칙 문서에 반영한다.

## [2026-08-01] ux | first-step coach copy

- 첫 단계의 속성 선택·옮기기·발사 순서를 현재 화면 행동과 일치하는 단계형 한글 안내로 연결한다.

## [2026-08-01] physics | material restitution

- 전역 벽 감쇠로 기존 물리를 훼손하지 않도록 엔티티별 반발력을 도입하고, 탄성 튜토리얼 장애물만 낮은 반발력으로 설정한다.

## [2026-08-01] qa | restitution regression recovery

- 엔티티별 반발력 적용 뒤 무거움·일반 벽 반사 회귀를 다시 통과시킨 최신 테스트 수를 기록한다.

## [2026-08-01] qa | final count correction

- 전체 실행 결과의 실제 카운터가 67개임을 확인해 검증 문서 수치를 교정한다.

## [2026-08-01] release | submission evidence preflight depth

- 제출 스크린샷의 실제 픽셀 규격과 정책 URL의 확정 상태를 사전검사에서 확인해 파일 존재만으로 통과하는 허점을 줄인다.

## [2026-08-01] ux | popup interaction isolation

- 정보·실패·클리어 팝업이 열리는 동안 배경 게임판의 포인터 입력과 접근성 포커스를 격리한다.

## [2026-08-01] ux | failure popup text scaling

- 실패 안내와 복구 버튼을 제한된 높이의 스크롤 영역에 넣어 큰 글자 환경에서도 화면 밖으로 밀리지 않게 한다.

## [2026-08-01] test | popup semantic isolation

- 클리어 팝업이 열린 동안 배경 조준 영역이 보조기술 대상에서 제외되는 계약을 위젯 테스트로 고정한다.

## [2026-08-01] qa | verified count correction

- 기존 클리어 팝업 테스트에 검증을 추가한 것이므로 테스트 개수는 증가하지 않았음을 검증 문서에 정확히 반영한다.

## [2026-08-01] docs | interaction contract sync

- 사용자 확정 조작 방식과 현재 구현이 분리 발사 버튼·예상 경로를 필수로 요구하는 오래된 하네스 문구와 충돌하지 않도록 계약 문장을 동기화한다.

## [2026-08-01] visual | collision direction feedback

- 충돌 법선을 애니메이션 이벤트에 전달해 벽·젤리·물체의 타격 효과가 실제 충돌면 방향을 따르도록 개선한다.

## [2026-08-01] ux | board input bounds

- 실제로 렌더링되는 게임판 사각형만 조준 입력과 접근성 포인터 영역으로 사용해 좁은 화면의 레터박스 오입력을 막는다.

## [2026-08-01] qa | validation count refresh

- 충돌 법선 회귀와 보드 입력 영역 회귀를 포함한 최신 전체 테스트 수를 검증 문서에 반영한다.

## [2026-08-01] commercial | parallel review synthesis and vertical-slice iteration

- Ran parallel puzzle design, game design, physics, QA, evaluation, and expert-player reviews against the current repository.
- Ran a second cross-review round by sending the shared findings back to all six roles and collecting disagreements and completion criteria.
- Adopted the shared priorities: unify the third-stage visual language, make the first interaction flow discoverable, and verify collision-chain/clear timing; track iOS signing and asset-license evidence as separate release gates.
- This implementation iteration will preserve the current top-view Korean UI and focus on a narrow, testable commercial-quality slice rather than adding new game systems.

## [2026-08-01] commercial | store asset and rights-evidence pass

- Parallel launch-gate review confirmed three independent blockers: missing iOS signing/provisioning, incomplete asset-rights evidence, and placeholder App Store icon/launch image.
- Generated a project-specific no-text game icon direction using the game's ball, heavy, bouncy, and sticky visual language; the generated raster will replace the default Flutter icon and launch placeholder.
- Added a rights-ledger task for each externally sourced file, including source path, source URL, license URL, retrieval record, SHA-256 hashes, transformation history, and bundle usage.

## [2026-08-01] commercial | collision precision and store identity implementation

- Replaced the active-ball coarse collision stepping with fine swept segments plus binary contact refinement, and applied the same segment check to pushed chain entities.
- Added the generated project icon to all iOS AppIcon sizes and replaced the 1x1 launch placeholders with the branded icon image; matched the launch storyboard background to the game palette.
- Added offline OpenGameArt and CC0 legal-code evidence, file hashes, a rights ledger, and store-asset provenance notes.
- Removed truncation from object and ball detail descriptions so the popup is the canonical place for full Korean explanations.
- Corrected every AppIcon variant to its exact square pixel dimensions after validating the generated files with `file`.
- Verification after collision and store-asset changes: Dart format check passed; `flutter analyze` passed; `flutter test` passed with 35 tests; `flutter build web` passed.
- iOS verification after icon and launch updates: Xcode compilation completed, but deployable output remains blocked by the missing Development Team and provisioning profile; the placeholder icon catalog and launch images now pass dimension checks.
- iOS simulator verification: unavailable in this environment because the required iOS 18.2 simulator runtime is not installed.

## [2026-08-01] commercial | QA follow-up fixes

- QA recheck found the rights hash file mixed human notes with checksum rows; the file will be made machine-checkable for `shasum -c`.
- QA recheck found the demo server session had ended during the long review; the latest web server will be restarted and verified again after all edits.
- The leaderboard is demo data, so its Korean label will explicitly say `예시 기록` until a real local or online ranking service exists.
- Updated the widget contract to expect the honest `예시 기록` label; final Dart format and full Flutter test pass completed with 35 tests.
- Final QA server check: latest `build/web` returned HTTP 200 from `http://127.0.0.1:8080` after the prior server was stopped and replaced.
- Added device-local best-shot persistence with `shared_preferences`; the clear popup now shows the player's best local record while the sample rows remain explicitly labeled.
- Final local-record verification: `flutter pub get`, Dart format, `flutter analyze`, 35 Flutter tests, and `flutter build web` all passed.
- Replaced the demo server once more after the final web build; latest `http://127.0.0.1:8080` returned HTTP 200.

## [2026-08-01] commercial | local replay record pass

- The fixed demo leaderboard is now explicitly labeled `예시 기록`; the next product pass will add device-local best-shot persistence without introducing accounts or online data collection.
- This keeps the replay loop honest for the current demo while creating a real improvement target for App Store users.

## [2026-08-01] commercial | vertical-slice QA recheck completed

- Added popup-first entity inspection with in-popup `옮기기` and `복사` actions, replacing the trait-source-only selection path.
- Replaced fading HUD message overflow with explicit ellipsis, delayed clear popup timing for chained moves, and checked every segment of an animation move path for hole entry.
- Locked iOS orientation to portrait for the current vertical layout.
- Enriched the top-view board with low-contrast lawn stripes, pebbles, corner leaves, and a board shadow while keeping gameplay objects readable.
- Verification: `flutter analyze` passed; `flutter test` passed with 35 tests; `flutter build web` passed; old demo server stopped before the new server; new demo returned HTTP 200 at `http://127.0.0.1:8080`.
- QA recheck: functional items above closed; release blockers remain for iOS signing/provisioning and preserved asset-license evidence, plus real-device/user testing, icon, physics timing, and full art consistency.
- iOS verification: Xcode build phase completed, but deployable device output remains blocked by missing Development Team and provisioning profile; this is an environment/release gate, not a source compilation error.

## [2026-06-30] maintenance | initial harness setup

- Created operating harness skeleton.

## [2026-07-23] prototype | Property Shot foundation

- Started service foundation work for the `Property Shot` mobile casual game prototype.
- Read all Markdown files under `harness_docs/` and adopted the local rules as mandatory working constraints.
- Repository currently contains only harness documentation and is not yet initialized as a Git repository.
- Flutter is available at `/Users/bellhundred/flutter_3_44_0/bin/flutter`, but SDK cache writes require execution outside the sandbox.
- Created a Flutter/Flame foundation app with deterministic pure-Dart game logic, three prototype levels, trait transfer, aim locking, launch-only shots, rewind/reset/pause controls, and failed-ball persistence.
- Added README sections summarizing the original prompt, user request, generated output definition, and AI work record draft.
- Verification: `flutter analyze` passed; `flutter test` passed with 14 tests; `flutter build web` passed and is served locally at `http://127.0.0.1:8080`.
- `flutter build ios --no-codesign` reached Xcode build but failed because no iOS Development Team / provisioning profile is configured for the Runner target.

## [2026-07-23] prototype | Korean UI and play feedback pass

- Started a UI clarity pass based on user feedback: remove visible English UI text, shorten status messages, show ball trait details on tap, animate shot travel, and make trait-bearing objects visually distinct.
- Checked free UI resource references: Kenney UI Pack and Mobile Controls are CC0 and suitable for later asset import; this pass uses a similar high-contrast game UI treatment without adding external binary assets.
- Replaced visible app/UI copy with Korean, including web title/manifest and iOS display name.
- Added ball tap inspection, trait descriptions, trait-colored ball glow, trait textures on source objects, and shot travel animation.
- Updated README and test descriptions to Korean.
- Verification: `flutter analyze` passed; `flutter test` passed with 15 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Collision and aiming pass

- Started work on default bounce, momentum transfer between movable objects, immovable walls, trait copy controls, clearer source naming, red aim arrow, and press-and-hold power charging.
- Added default collision bounce for walls, closed gates, bumpers, weights, and sticky surfaces; walls remain immovable.
- Added deterministic momentum transfer for movable crates and spent balls, including short chain pushes.
- Added trait copy alongside trait transfer; copy keeps the source object's trait.
- Renamed the visible source label from `무게추` to `무거운 돌`.
- Changed aiming so pointer movement sets direction, a red arrow shows the launch direction, and long-pressing the ball charges shot power.
- Fixed level 3 switch collision so the switch can be pressed in play.
- Verification: `flutter analyze` passed; `flutter test` passed with 19 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Auto launch and collision tuning pass

- Started work on automatic launch after aiming/power lock, tighter hitboxes, stronger ball energy, object inspection, spent-ball interactions, and more precise bounce angles based on impact face.
- Removed the separate launch-button flow from the visible UI: long-pressing the ball charges power and releasing it launches automatically.
- Added per-entity hitbox scaling and tuned tutorial 1 crate/weight hitboxes for more precise contacts.
- Increased shot distance and push strength, especially for heavy balls, so the first tutorial crate can be meaningfully displaced.
- Added object inspection panels for tapped entities, including trait descriptions when a source has a trait.
- Preserved spent balls as movable solid entities that can be hit and pushed by later shots.
- Reworked bounce math to use collision normals so side, top/bottom, and corner impacts reflect differently.
- Verification: `flutter analyze` passed; `flutter test` passed with 22 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Timed chain reaction and tutorial clarity pass

- Started work on time-aligned chain reaction animation, glancing collision impulses, and tutorial clarity validation/tuning.
- Added shot animation moves with trigger path indices so pushed objects begin moving only after the ball reaches the collision point.
- Render shot animations from the pre-shot state, then progressively apply object moves during the shot timeline; previous spent balls remain visible and interactive during the animation.
- Changed movable-object impulse direction and strength to use contact normals, enabling weaker/off-angle glancing pushes.
- Added sequential delay for chained pushes so secondary objects move shortly after the first impacted object.
- Added tests covering tutorial 1 heavy push clarity, delayed chain animation triggers, glancing collisions, and impact-face bounce behavior.
- Added README tutorial validation notes for heavy, bouncy, and chain-gate lessons.
- Verification: `flutter analyze` passed; `flutter test` passed with 25 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Clear popup and cute block visual pass

- Added a clear popup shown when the ball reaches the hole.
- Added a `다음` button that advances to the next stage, wrapping after the final demo stage.
- Added a serverless demo leaderboard in the popup using stage-specific sample player records plus the current player's shot count.
- Referenced Poco/Pocopia-like soft block terrain examples and implemented a non-infringing custom Canvas style: pastel grass board, tile grid, flowers, rounded blocks, soft shadows, and a cute ball face.
- Added test support for injecting an initial `GameState`, and covered the clear popup next-stage flow.
- Verification: `flutter analyze` passed; `flutter test` passed with 26 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Camera view and clear reliability pass

- Started work on top/quarter view selection, view-aware arrows, non-text object icons, stronger shot feel, and clear popup reliability after real shot animation.
- Added a `탑뷰`/`쿼터뷰` segmented control and projected the board, entities, aim arrow, preview path, and previous-shot path according to the selected view.
- Replaced field text labels with custom Canvas visuals: cute ball face, crate ribbons, stone-like heavy object, bumper ring, sticky dots, switch marker, gate bars, and a golf-style flag on the hole.
- Strengthened shot feedback with ball trail dots and impact rings timed to the actual collision trigger point.
- Fixed a clear-popup reliability bug where successful states no longer had an active planning ball, then delayed the popup until the real-shot animation has had time to play.
- Improved hole detection by checking the shot segment against the hole instead of only the current simulation point.
- Added widget tests for real-shot clear popup display and switching between `탑뷰` and `쿼터뷰`.
- Updated README with the new view modes, visual direction, impact feedback, and current result definition.
- Verification: `flutter analyze` passed; `flutter test` passed with 28 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Quarter-view angle and popup UI pass

- Started work on a steeper 45-60 degree quarter-view look, compact Korean view labels, popup-based object information, clearer trait-transfer wording, and removing the redundant bottom power progress bar.
- Reworked quarter-view projection into a steeper angled board: the floor, grid, entities, arrows, paths, and hit-coordinate conversion now use matching skewed projection.
- Added simple 3D-like depth to rectangular blocks and kept balls spherical with a ground shadow; holes render as angled ovals with a flag.
- Changed the view selector's visible labels to compact Korean `위` and `입체` to avoid automatic line wrapping in narrow controls.
- Moved ball and object information into floating popups with a close button so the game field no longer shrinks when an entity is inspected.
- Renamed the transfer action from `이전` to `옮기기` and updated related messages/README wording.
- Removed the bottom power progress bar, leaving shot power communicated by the circular gauge around the ball.
- Verification: `flutter analyze` passed; `flutter test` passed with 28 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Cue-like shot feel and discovery pass

- 물리 QA에서 연쇄 이동 중 최신 물체 위치가 재귀 충돌 계산에 공유되지 않는 결함을 확인했다. 반사 후 과거 위치의 물체를 재접촉 후보로 삼지 않도록 재현 테스트와 상태 동기화를 추가한다.

- Started work on cue-like launch feedback, slow ball pulsing after aiming, hiding preview/last-shot path hints, stronger sphere/cuboid rendering in angled view, and evaluating a simple rotation-view control.
- Added a slow pulsing ring around the active ball during planning so users are naturally guided to press the ball after aiming.
- Removed rendered collision preview paths and previous-shot black path lines from the field; only the aim arrow and circular power gauge remain visible before launch.
- Increased shot animation speed and added cue-stick strike, launch burst, ball trail, and timed impact ring effects for a stronger billiards-like hit feel.
- Rendered balls with radial sphere shading and ground shadows, and strengthened angled-view blocks with cuboid-like top and side faces.
- Added `입체` view rotation controls for left/right viewpoint changes while keeping the deterministic physics coordinate system unchanged.
- Updated README and widget tests for the new shot feel, hidden hints, and rotation controls.
- Verification: `flutter analyze` passed; `flutter test` passed with 28 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Angle, hole, and jelly response pass

- Started work on an angled-view elevation range from 10 to 80 degrees, cleaner cuboid rendering, hole success for any ball, elastic jelly reaction animation, and simplifying the bottom trait menu.
- Added an `입체` view angle slider from 10 to 80 degrees and wired the same projection math into touch-coordinate conversion.
- Reworked angled cuboid rendering so block side depth scales with the selected view angle and top/side faces are drawn in a cleaner order.
- Made hole success more generous and allowed any active ball, including previous spent balls pushed by later shots, to trigger clear when it overlaps the hole.
- Added a dedicated jelly bounce event and renderer reaction: jelly squashes, stretches, and shows small elastic ripple arcs when hit.
- Removed the bottom trait-source chip menu; players now select trait objects directly in the field and then use `옮기기` or `복사`.
- Updated README and tests, including a new simulation test for previous balls clearing the hole.
- Verification: `flutter analyze` passed; `flutter test` passed with 29 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Dynamic ball physics and full-view cues pass

- Started work on non-uniform ball motion with friction, mass-aware collision response, full-direction cuboid sides, continuous horizontal view rotation, and pulsing selectable trait sources.
- Changed shot simulation from uniform 6-unit steps to variable-speed movement: balls start fast, lose speed to friction, and lose additional speed on impacts.
- Added mass-aware collision response so heavy balls transfer more momentum to lighter balls while retaining more of their own forward movement.
- Added tests for decelerating ball motion and heavy-ball versus normal-ball collision behavior.
- Reworked angled cuboid rendering to draw all four side faces around the top face, improving box and stone readability from any horizontal angle.
- Added continuous horizontal `입체` view rotation through a 0-345 degree azimuth slider, while keeping rotate buttons as 15-degree nudges.
- Added pulsing rings around selectable trait-bearing objects so players can tell which field elements can be chosen for `옮기기`.
- Updated README with the new friction, mass, cuboid, selection, and horizontal rotation behavior.
- Verification: `flutter analyze` passed; `flutter test` passed with 31 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Fixed quarter-view cleanup pass

- Started work on removing all vertical and horizontal view rotation controls, keeping a single stable fixed angled view.
- Removed all vertical angle and horizontal rotation UI controls from the HUD.
- Removed view angle/azimuth state and setter plumbing from the UI and renderer.
- Kept `위` and `입체` mode switching, with `입체` now using one fixed 45-degree projection.
- Updated touch-coordinate conversion to match the fixed quarter-view projection.
- Updated README and widget tests to assert rotation controls are absent.
- Verification: `flutter analyze` passed; `flutter test` passed with 31 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | Free icon thumbnails pass

- Started work on replacing text-based popup thumbnails with free image assets and textless drawn icons for game elements.
- Downloaded OpenGameArt `Smooth Physics Obstacle Props` and extracted CC0 PNG thumbnails for ball, crate, and heavy stone.
- Registered `assets/icons/` in `pubspec.yaml` and added an asset license note under `assets/icons/README.md`.
- Replaced popup `CircleAvatar` text thumbnails with `_EntityThumbnail` and `_BallThumbnail`.
- Used image assets for ball/crate/heavy stone and custom textless Canvas icons for hole, wall, jelly, sticky surface, switch, and gate.
- Updated README to document the popup thumbnail source and CC0 usage.
- Verification: `flutter analyze` passed; `flutter test` passed with 31 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8080` returned HTTP 200.

## [2026-07-23] prototype | In-game icon asset pass

- Started work on applying the newly added free icon assets to in-game objects while keeping balls drawn with the original game-rendered style.
- Loaded the CC0 crate and heavy-stone PNG assets into the Flame renderer and painted them onto in-game rectangular objects.
- Kept balls in the game field as Canvas-rendered spheres, without applying the external ball PNG.
- Replaced ball popup thumbnails with a textless Canvas ball painter that matches the in-game sphere, face, shadow, highlight, and trait colors.
- Updated README to clarify that ball thumbnails use the in-game ball rendering while crate and heavy-stone images are used in both popups and the game field.
- Verification: `dart format lib test` passed; `flutter analyze` passed; `flutter test` passed with 31 tests; `flutter build web` passed; local demo server at `http://127.0.0.1:8081` returned HTTP 200.

## [2026-07-23] release | GitHub repository publishing

- Started work on splitting the completed prototype into logical Git commits and publishing them to a GitHub remote repository named `Property_shot`.
- Initialized a local Git repository on `main`.
- Split the current project into logical commits for Flutter scaffold/harness docs, deterministic simulation, Korean playable UI/renderer, CC0 icon assets, and README/AI work record.
- GitHub publishing is currently blocked because `gh auth status` reports the saved `good5229` token is invalid and SSH authentication to GitHub fails with `Permission denied (publickey)`.

## [2026-07-23] prototype | Wall, sticky, and switch feedback pass

- Started work on fixing wall bounce separation, making sticky pads stop balls instead of reflecting them, and adding switch/gate opening feedback.
- Added post-collision separation so balls rebound from walls/gates/solid objects instead of remaining inside the hitbox.
- Changed sticky pads to stop and hold any colliding ball instead of acting like a low-energy bounce surface.
- Changed switch behavior so ball collision presses the switch, schedules a blink/press animation, opens gates, and schedules a simple gate-opening animation.
- Updated object descriptions, README notes, and simulation tests for wall rebound, sticky pad attachment, and switch/gate feedback.
- Verification: `dart format lib test` passed; `flutter analyze` passed; `flutter test` passed with 32 tests; `flutter build web` passed; old demo server was stopped before starting the updated demo at `http://127.0.0.1:8080`, which returned HTTP 200.

## [2026-07-23] prototype | Cascading collision physics pass

- Started work on making pushed balls and objects run their own collision checks during chain reactions instead of teleporting through walls or other objects.
- Reworked momentum pushes to advance in short collision-checked steps instead of jumping directly to a final position.
- Added chained collision responses for pushed balls/objects against walls, gates, sticky pads, switches, bumpers, crates, weights, and other balls.
- Prevented pushed objects from immediately re-colliding with the active ball that just struck them.
- Added a regression test where a plain ball pushes another plain ball into a wall, confirming the pushed ball receives a wall collision event and stays inside the field.
- Updated README to document chained collision physics.
- Verification: `dart format lib test` passed; `flutter analyze` passed; `flutter test` passed with 33 tests; `flutter build web` passed; old demo server was stopped before starting the updated demo at `http://127.0.0.1:8080`, which returned HTTP 200.

## [2026-07-23] prototype | Chained ball animation path pass

- Started work on passing intermediate collision waypoints to pushed-ball animations so ball-to-ball impacts move along the calculated angle instead of blinking from start to end.
- Added optional waypoint paths to `ShotAnimationMove`.
- Updated the Flame renderer to interpolate pushed entities along waypoint paths when present, falling back to start/end interpolation for simple object reactions.
- Recorded pushed-object waypoints during stepwise momentum simulation, including wall separation and reflected movement after chained collisions.
- Added a regression check that pushed-ball wall reactions include multiple animation waypoints.
- Updated README to document chained movement path animation.
- Verification: `dart format lib test` passed; `flutter analyze` passed; `flutter test` passed with 33 tests; `flutter build web` passed; old demo server was stopped before starting the updated demo at `http://127.0.0.1:8080`, which returned HTTP 200.

## [2026-08-01] prototype | Continuous chained-ball playback pass

- Started work on the remaining report that a ball-to-ball collision can still look like a blink even when the simulation contains intermediate waypoints.
- Will make animation duration follow the recorded movement distance and interpolate by cumulative waypoint distance, so long chained pushes do not skip across the path in a fixed short duration.
- Will add regression coverage for bounded waypoint spacing and record the final static-analysis, test, build, and demo checks after implementation.

## [2026-08-01] docs | Goal audit and evidence record

- Started the required Goal documentation pass after reading the referenced pasted Goal text in full.
- Will add evidence-based role audits, fun hypotheses, puzzle intent, physics rules, QA records, prompt history, decisions, final evaluation, and remaining-risk records.
- These records will distinguish automated evidence and expert-proxy review from real user testing, which has not been performed in this workspace.

## [2026-08-01] docs | Goal evidence completion

- Added role audits, design hypotheses, puzzle intent, UX flow, physics rules, playtest protocol, improvement plan, QA records, prompt history, decision log, final evaluation, remaining risks, and AI usage summary.
- Linked the new Goal evidence sections from `harness_docs/index.md`.
- Recorded the final verification evidence: `flutter analyze` passed, `flutter test` passed with 33 tests, `flutter build web` passed, and the restarted demo returned HTTP 200.

## [2026-08-01] prototype | Top-view and collision-event playback revision

- Started work on removing the quarter/3D view entirely at the user's direction.
- The design, physics, puzzle, QA, evaluation, and expert-player roles will cross-check the change against the current code and tests.
- Will replace recursive animation timing offsets with collision-step timing so a pushed entity starts only after the collision that caused its movement, and record the result in the Goal evidence documents.

## [2026-08-01] prototype | Top-view and collision-event playback completed

- Removed `GameViewMode`, quarter projection, quarter hit-coordinate conversion, 3D block side rendering, and the view selector from the UI.
- Changed recursive chain animation triggers to use the actual collision step, removing the previous depth-based timing offset.
- Added a regression test that confirms the next chained object starts after the preceding object's collision event.
- Cross-checked the change with puzzle, game design, physics, QA, evaluator, and expert-player role records.
- Verification: `flutter analyze` passed; `flutter test` passed with 34 tests; `flutter build web` passed; existing 8080 server was stopped before the new demo started; `curl http://127.0.0.1:8080` returned HTTP 200.

## [2026-08-01] prototype | Continuous improvement iteration baseline

- Started the continuous Subagent collaboration iteration from the referenced prompt.
- Baseline: `dart format --output=none --set-exit-if-changed .` passed with no changes; `flutter analyze` passed; `flutter test` passed with 34 tests; `flutter build web` passed.
- Existing demo server was found listening on `127.0.0.1:8080` and will be preserved until a replacement build is ready, then stopped before restart.
- Six role reviews will focus on high-speed tunneling, deterministic same-step collision ordering, tutorial clarity, and whether collision-triggered animation remains aligned with the physics result.

## [2026-08-01] prototype | High-speed collision and deterministic ordering pass

- Independent role reviews identified endpoint-only active-ball collision checks as a tunneling risk for small or thin objects at high power.
- Added segment sampling at up to 4 logical units per sample and used the first sampled impact position for the collision response and animation path.
- Added deterministic collision candidate selection by nearest boundary metric, with entity ID tie-breaking.
- Reduced pushed-entity movement steps to 4 logical units and added a small-ball high-speed regression test.
- Strengthened determinism coverage to compare final state, path, events, and animation trigger ordering.
- Completed cross-review and post-implementation review across puzzle, design, physics, QA, evaluator, and expert-player roles.
- Verification: format check passed with no changes; `flutter analyze` passed; `flutter test` passed with 35 tests; `flutter build web` passed; old 8080 server was stopped before restart; new demo returned HTTP 200.
- `flutter build ios --no-codesign` reached a completed Xcode build but the deployable app step was blocked by the missing Development Team and provisioning profile; this is recorded as an environment limitation, not a code test pass.
- Final test cleanup removed the obsolete view-selector assertion; the final format check passed with no changes, `flutter analyze` passed, and `flutter test` passed with 35 tests.

## [2026-08-01] visual | Moving object sprite animation pass

- Started work on the report that moving stones and boxes look like rectangular hitbox boxes instead of their actual shapes.
- The current renderer paints a rectangular base path before clipping the crate/stone image; this pass will render image-backed moving objects as transformed sprites with separate shadows and motion deformation.
- Will preserve the logical hitbox and deterministic simulation while adding crate tilt, stone roll, impact squash, and jelly-shaped movement feedback.

## [2026-08-01] visual | Moving object sprite animation completed

- Removed the rectangular base fill from image-backed crate and stone rendering during movement.
- Added direct sprite rendering with a separate ground shadow, motion tilt for crates, rolling rotation for stones, and impact squash/bob deformation.
- Changed jelly rendering from a rectangular path to a rounded soft body with impact deformation and ripple feedback.
- Kept balls as spherical Canvas objects and kept all hitboxes and simulation state unchanged.
- Verification: `dart format lib test` passed; `flutter analyze` passed; `flutter test` passed with 35 tests; `flutter build web` passed; old 8080 server was stopped before restarting the updated demo; `curl http://127.0.0.1:8080` returned HTTP 200.

## [2026-08-01] process | Continuous QA and Subagent collaboration loop

- Started a continuous collaboration loop at the user's request for commercial-quality visual and gameplay improvement.
- QA is the first gate: reproduce the issue, assign severity, define expected behavior, and add a regression scenario before implementation.
- Puzzle, design, physics, evaluator, and expert-player roles then review the QA finding independently and exchange objections before an implementation is selected.
- The loop will keep code, tests, visual assets, licenses, demo verification, and unresolved risks synchronized after every iteration.

## [2026-08-01] QA | collision ordering and puzzle-rule audit

- Parallel QA reviewed swept collision ordering, tutorial rule consistency, mobile UI, and store readiness.
- Physics finding: collision selection can still depend on entity array order when multiple candidates overlap in one sampled segment; the next implementation will select the earliest candidate per entity and use ID only for deterministic ties.
- Puzzle finding: heavy, elastic, sticky, and switch rules need explicit positive and negative tests so the first three stages teach properties rather than accepting broad physics-based bypasses.
- External release gates remain separate from local code quality: Apple signing/team, public privacy/support URLs, screenshots, TestFlight, and real-device verification.

## [2026-08-01] QA | deterministic collision and mobile guardrails integrated

- Replaced sampled global collision selection with per-entity swept refinement and deterministic earliest-progress tie-breaking for active and pushed entities.
- Added a zero-distance collision normal fallback so overlapping balls do not produce a zero reflection vector.
- Aligned the level-3 switch with the harness rule: a ball without `무거움` is rejected and the gate remains closed; successful switches now report that the gate opened.
- Removed HUD/control ellipsis, made the inspection popup scroll within the viewport, added long-press cancellation, and guarded local best-shot writes until preferences load.
- Expanded widget coverage to a 320x568 viewport; `flutter test` passed with 35 tests and `flutter analyze` passed with no issues.

## [2026-08-01] polish | launch feedback pass

- The commercial-quality pass keeps the deterministic resolver as the source of truth and adds feedback only at the presentation boundary.
- Planned changes in this pass: launch haptic feedback, impact rings for collision-triggered animation moves, and regression coverage that these presentation additions do not alter simulation results.

## [2026-08-01] store | screenshot font QA correction

- A generated iPhone screenshot was inspected pixel-wise and rejected because Korean text rendered as missing-glyph boxes.
- The invalid capture was removed; store materials must only list screenshots after Korean glyph rendering and the full gameplay canvas are visibly verified.
- The remaining external store gate is therefore intentionally still open for real-device or correctly configured Korean-font capture.

## [2026-08-01] mobile | browser screenshot overflow correction

- A real browser capture exposed a layout issue not caught by widget exception checks: the level chips and live guidance text shared one narrow row and the guidance was clipped on small screens.
- The HUD will use separate rows for level selection and guidance so the first viewport remains fully readable at 390px and below.

## [2026-08-01] mobile | game canvas constraint correction

- The follow-up browser capture showed the Flame canvas retaining its 520px max width inside a 390px viewport, which clipped the right wall and hole.
- The game widget will be explicitly constrained to the available field size; this preserves the logical board aspect ratio while keeping all gameplay objects visible.

## [2026-08-01] integration | parallel commercial QA merge

- Physics QA expanded recursive chain handling to the current entity count and added regression coverage for reordered candidates, five-step chains, pushed-ball wall impacts, frame-independent replay, and animation-path continuity.
- Puzzle QA adjusted level-1 and level-2 layouts to reduce bypass routes and added representative-intent and alternative-solution probes.
- Mobile QA added popup touch shielding, Korean semantics, long-press cancellation coverage, narrow-screen popup checks, and control meaning labels.
- Store QA added Korean localization metadata, non-exempt encryption declaration, age-rating draft, bundle asset manifest, and screenshot manifest. A generated screenshot with missing Korean glyphs was rejected; only the separately labeled web validation capture remains.
- Current verification: 49 Flutter tests pass, `flutter analyze` passes, `flutter build web --release` passes, asset hashes pass, and the restarted demo returns HTTP 200.
- Final audit: `Info.plist` lint passed; `flutter build ios --no-codesign` completed Xcode compilation but stopped at the expected missing Development Team/provisioning step. The Bundle ID remains the placeholder `com.example.propertyShot`.

## [2026-08-01] ux | tutorial objective copy pass

- QA found that the level name alone did not tell a first-time player which property and order mattered.
- Add one concise Korean objective line per level in the HUD, keeping the puzzle rule in the UI aligned with the resolver and the puzzle-intent document.

## [2026-08-01] feedback | semantic haptic pass

- The harness requires feedback for property selection/transfer, launch, collision, switch use, success, and failure while remaining understandable with sound disabled.
- Extend haptics at the UI boundary: selection and transfer use light feedback; one shot emits a light, medium, or heavy impact based on its deterministic result, avoiding per-frame vibration.

## [2026-08-01] physics | contact timeline hardening

- Parallel physics review found three remaining presentation/edge-case risks: initial-overlap collision refinement used the end of the sample, chain paths omitted the contact point, and a large render `dt` could skip impact feedback.
- The next patch will preserve the deterministic resolver while making `t=0` overlap explicit, recording contact and separation points, and clamping animation time advancement.

## [2026-08-01] ux | first-shot guidance and popup ownership

- UX review found that the first screen named the objective but not the action sequence, and that transfer/copy left the source popup open after applying a trait.
- Add level-specific first instructions, transition to an aim instruction after transfer/copy, and use a full-screen modal barrier so only the active popup owns input.
## [2026-08-01] release | store visual and accessibility evidence pass

- 스토어·비주얼 역할로 현재 에셋, iOS 설정, 권리대장, 제출 문서를 재감사했다.
- 이번 작업 범위는 저장소 안에서 확정할 수 있는 상업 이용 증빙, 스토어용 실제 화면 캡처, 접근성 점검 자료, 최종 번들 자산 목록이다.
- Apple 팀·Bundle ID·서명·공개 정책 URL·실기기 캡처처럼 외부 계정이나 운영 주체가 필요한 값은 임의로 확정하지 않고 차단 요인으로 남긴다.

## [2026-08-01] design | tutorial property-necessity audit

- `harness_docs/design/puzzle_intent.md`, `harness_docs/readme.md`, `levels.dart`, 관련 테스트를 대조해 1~3라운드의 의도 풀이와 대표 대체 풀이를 점검한다.
- 물리 규칙을 바꾸지 않고 레벨 배치로 줄일 수 있는 1라운드의 직선 우회만 조정하며, 일반 공도 벽에서 반사되고 점착판이 모든 공을 붙잡는 현재 규칙은 테스트로 명시한다.
- 변경 범위는 `levels.dart`와 관련 테스트로 제한하고, 분석·전체 테스트로 회귀를 확인한다.

## [2026-08-01] design | tutorial property-necessity audit completed

- 1라운드 홀을 `Vec2(302,132)`로 조정해 상자 뒤의 대표 조준을 명확히 하고, 같은 `Vec2(1,-1.3)` 풀파워 샷에서 무거운 공만 상자를 충분히 밀어 클리어하는 회귀 테스트를 추가했다.
- 2라운드는 홀을 좌상단으로 옮기고 수직 반사 벽을 배치했으며, 젤리 속성을 옮긴 `Vec2(1,-1.5)` 샷의 성공과 탄성 예상 경로를 검증했다. 현재 벽 규칙상 일반 공도 같은 경로로 성공하는 대체 풀이임을 별도 테스트로 명시했다.
- 3라운드는 실제 레벨에서 무거운 공의 스위치·문·홀 성공과 일반 공의 스위치 거절을 검증했다. 점착판과 일반 공의 동작은 현재 물리 규칙상 동일하므로 점착 필수성으로 주장하지 않았다.
- 검증: 퍼즐·물리 테스트 33개 통과, `flutter analyze` 통과, `flutter build web` 통과, `git diff --check` 통과. 기존 위젯 테스트의 속성 팝업 버튼 2개는 화면 밖 탭으로 단독 재현됐으며 이번 허용 범위 밖의 기존 UI 배치 이슈로 남겼다.
- 기존 8080 서버를 종료한 뒤 변경된 `build/web`을 재기동했고 `curl -I http://127.0.0.1:8080`에서 HTTP 200을 확인했다.

## [2026-08-01] ux | property action consolidation

- QA 피드백에 따라 하단의 중복된 속성 옮기기·복사 메뉴를 제거한다.
- 물체 클릭 팝업을 속성 확인과 이전·복사의 단일 진입점으로 삼고, 위젯 테스트도 실제 사용자 흐름을 따라 검증한다.

## [2026-08-01] test | property action copy alignment

- 속성 이전 후 안내 문구가 사용자의 다음 행동까지 설명하도록 바뀐 상태를 위젯 테스트 기대값에 반영한다.

## [2026-08-01] visual | stable mobile board frame

- 세로 화면이 길어질수록 게임판이 불필요하게 늘어난 영역 안에서 작게 보이지 않도록, 게임판 렌더 영역을 논리 좌표와 같은 종횡비로 고정한다.
- 조준 입력 영역은 전체 가용 영역을 유지해 기존 터치 좌표 변환과 시각 보드의 중심을 일치시킨다.

## [2026-08-01] visual | material feedback and ball trait texture

- 공에도 무거움·탄성·점착의 무늬를 적용해 속성 식별을 색상에만 의존하지 않게 한다.
- 충돌 대상 재질에 따라 이펙트의 색·선 스타일·파편 모양을 구분해 연쇄 충돌 원인을 읽기 쉽게 한다.

## [2026-08-01] release | preserve submission evidence

- 스토어 메타데이터·스크린샷 명세·권리대장은 새 클론에서도 검토 가능해야 하므로 출시 증빙 문서만 Git 추적 대상으로 예외 처리한다.
- 원본 다운로드 폴더와 생성 빌드는 계속 제외해 저장소에 불필요한 대용량 산출물이 들어가지 않게 한다.

## [2026-08-01] release | ignore-rule verification correction

- 예외 규칙 뒤에 남아 있던 중복 `/harness_docs/` 규칙이 출시 문서를 다시 무시하는 것을 확인하고 제거한다.

## [2026-08-01] animation | chained event timeline completion

- 연쇄 이동의 트리거 인덱스가 발사 공 경로보다 늦을 수 있으므로, 렌더러가 발사 경로와 모든 연쇄 이동 종료 시점 중 더 늦은 시점까지 애니메이션을 유지한다.
- 발사 공은 경로 마지막 위치에 머물고, 후속 물체는 실제 트리거 시점에 순차적으로 움직이도록 한다.

## [2026-08-01] ux | clear timing follows animation

- 클리어 팝업 지연 시간을 발사 경로 길이만으로 계산하지 않고 가장 늦은 연쇄 이동의 트리거·이동 길이까지 반영한다.

## [2026-08-01] accessibility | semantic game objects and aim actions

- Canvas 내부의 핵심 요소를 실제 위치에 대응하는 한국어 Semantics 노드로 노출한다.
- 스크린리더 사용자가 조준 방향을 증감하고 발사를 실행할 수 있도록 대체 접근성 액션을 제공한다.

## [2026-08-01] accessibility | explicit semantics dependency

- 사용자 정의 접근성 동작을 Flutter Semantics 라이브러리에서 명시적으로 가져와 SDK 노출 범위에 의존하지 않게 한다.

## [2026-08-01] accessibility | semantics value contract

- 방향·힘 조절 Semantics에 증감 후 값을 함께 제공해 Flutter 접근성 노드의 런타임 계약을 만족시킨다.

## [2026-08-01] test | semantic scene regression

- 첫 단계의 공·무거운 돌·홀·벽이 한국어 접근성 트리에 존재하는지 위젯 회귀 테스트로 고정한다.

## [2026-08-01] ux | shot animation input lock

- 발사 결과의 논리 상태와 화면 연쇄 애니메이션 사이에 입력 잠금을 둔다.
- 애니메이션이 끝난 뒤에만 다음 조준·되감기·단계 이동을 허용해 중복 샷과 상태 경합을 막는다.

## [2026-08-01] build | shared shot unlock duration

- 성공·실패 샷 모두 같은 연쇄 애니메이션 길이를 사용하도록 잠금 해제 지연 계산을 공통 경로로 이동한다.

## [2026-08-01] test | duplicate shot lock regression

- 첫 샷의 연쇄 애니메이션 중 두 번째 롱프레스가 추가 샷을 만들지 않는지 위젯 테스트로 고정한다.

## [2026-08-01] ux | first action and aim handoff

- 기본 시작 상태에도 1단계 행동 안내를 적용한다.
- 속성 이전·복사 후 정보 팝업을 닫아 사용자가 안내된 다음 조준 동작으로 바로 이어갈 수 있게 한다.

## [2026-08-01] accessibility | popup route semantics

- 정보 팝업과 클리어 팝업을 대화상자에 해당하는 한국어 경로 Semantics로 묶어 스크린리더가 화면 전환을 인식하게 한다.

## [2026-08-01] release | automated submission preflight

- Apple 계정 없이도 저장소에서 반복 검증할 수 있는 출품 사전검사 스크립트를 추가한다.
- 예시 Bundle ID·서명 팀 누락·실기기 스크린샷 미확보·정책 초안 상태·권리 해시 오류를 명확한 한국어 실패 항목으로 출력한다.

## [2026-08-01] release | preserve required work log

- 프로젝트 규정상 필요한 개발 작업 로그도 출시 증빙과 함께 새 클론에서 재현되도록 추적 예외에 포함한다.

## [2026-08-01] release | shell portability correction

- 사전검사 스크립트의 내부 식별자를 ASCII로 바꿔 macOS 기본 셸 환경에서도 한글 출력과 실행을 분리한다.

## [2026-08-01] release | preflight evidence depth

- 출시 문서가 실제 Git 추적 파일인지 확인하고, iOS 아이콘 카탈로그와 코드 서명 자격의 존재까지 사전검사 범위를 확장한다.
- 개인정보 처리방침과 지원 페이지의 공개 준비본을 한국어 정적 문서로 추가한다.

## [2026-08-01] ux | honest demo leaderboard

- 서버 리더보드가 연결되지 않은 데모에서 고정 예시 기록을 실제 사용자 순위처럼 오해하지 않도록 클리어 팝업에 명시적인 설명을 추가한다.

## [2026-08-01] ux | staged progression and completion state

- 기본 플레이에서는 클리어한 단계까지만 다음 단계가 열리도록 로컬 해금 상태를 저장한다.
- 마지막 단계 클리어 후에는 순환하는 `다음` 대신 전체 완료 후 재도전 행동을 표시한다.

## [2026-08-01] ux | progression implementation

- 로컬 `unlocked_level` 값을 저장하고 단계 칩을 잠그며, 마지막 단계에는 `처음부터 다시` 행동을 표시하도록 구현한다.

## [2026-08-01] docs | align interaction contract

- 하네스 원문의 이전 발사 버튼·예상 경로 규칙이 현재 사용자 확정 조작과 달라 자동 발사·숨겨진 궤적 규칙으로 정리한다.

## [2026-08-01] ux | unlock feedback and accessibility semantics

- 클리어 팝업에서 새로 열린 단계를 명시하고, 벽·문 같은 비선택 장애물을 접근성에서 상호작용 물체와 구분한다.

## [2026-08-01] physics | static wall response for chained bodies

- 연쇄로 밀려난 이동 물체가 벽에 닿을 때 정지로만 끝나던 분기를 벽 법선 반사·분리·감속으로 통합하고, 벽 자체는 계속 고정한다.

## [2026-08-01] physics | power affects impulse distance

- 힘 게이지가 실제 물체 이동량으로 이어지는지 회귀 테스트를 추가하고, 충돌 시점 속도를 추진 거리 계산에 반영한다.

## [2026-08-01] accessibility | separate power and aim actions

- 게임판 접근성의 기본 증감 동작을 실제 힘 조절에 연결하고, 좌우 조준은 별도 한국어 사용자 지정 동작으로 분리한다.

## [2026-08-01] ux | failure recovery panel

- 실패 애니메이션이 끝난 뒤 충돌 결과와 다음 시도 제안을 짧은 패널로 표시하고, 재조준·되감기·단계 처음 시작을 명확히 분리한다.

## [2026-08-01] physics | equal mass ball exchange

- 동일 질량 공의 정면 충돌에서 발사 공이 완전 반사되는 오류를 막고, 대상 공으로 운동량이 넘어가는 회귀 규칙을 추가한다.

## [2026-08-01] physics | persistent sticky ball state

- 점착 충돌로 멈춘 발사 공을 고정 상태로 저장해 후속 샷이 다시 밀어내지 못하도록 한다.

## [2026-08-01] physics | chained switch requirement

- 연쇄 이동 중 스위치가 무거운 충격 없이 열리던 우회 경로를 차단하고, 무거운 충격 전달 여부를 연쇄 계산에 명시한다.

## [2026-08-01] release | reproducible validation evidence

- 최신 전체 테스트 수를 출시 검증 문서와 일치시키고, CC0 원본 압축파일을 Git 추적해 새 클론에서도 권리 해시 검증이 재현되도록 준비한다.

## [2026-08-01] qa | preserve commercial review artifacts

- 기존 QA 에이전트가 생성한 버그 보고·비주얼 기준선·회귀 체크리스트를 추적하고, 이번 물리·UX 보강 결과를 체크리스트에 반영한다.

## [2026-08-01] release | source tracking preflight

- 권리 해시만 통과하고 원본 압축파일이 새 클론에서 누락되는 상태를 막기 위해 원본 에셋과 최신 검증 문서의 Git 추적을 사전검사한다.

## [2026-08-01] physics | chained sticky immobilization

- 연쇄 이동 물체가 점착판에 닿을 때 외형만 멈추고 운동 가능 상태로 남던 문제를 고정 상태로 통합한다.

## [2026-08-01] test | progression contract coverage

- 기본 상태의 잠긴 단계 선택 거부와 마지막 단계 완료 후 재도전 문구를 위젯 테스트로 고정한다.

## [2026-08-01] build | shared animation math import

- 클리어 지연 계산에 사용하는 최대값 연산을 화면 모듈의 표준 수학 라이브러리로 연결한다.

## [2026-08-01] physics | closed field boundary

- 물리 QA에서 하단 경계가 충돌 후보에 없어서 공이 필드 밖으로 이탈하는 결함을 재현했다.
- 렌더링하지 않는 가상 고정 하단벽을 발사·연쇄·미리보기 판정에 공통 적용하고, 최종 게임 상태에서는 제거한다.

## [2026-08-01] test | boundary regression coverage

- 하단 벽이 없는 최소 상태에서 아래로 발사한 공이 `bounced` 이벤트를 만들고 논리 필드 안에 남는지 회귀 테스트를 추가한다.

## [2026-08-01] physics | shared logical field size

- 가상 경계가 렌더러의 화면 크기에 묶이지 않도록 레벨 정의의 공통 논리 크기를 물리 해결기에서 명시적으로 사용한다.
## [2026-08-01] ui | compact mobile board layout
- 320x568에서 보드 우선 레이아웃을 적용하고 HUD와 조작 패널을 축약 오버레이로 배치한다.
## [2026-08-01] animation | shared physical timeline sampler

- `ShotAnimationMove`의 경로 샘플 인덱스와 `triggerPathIndex`를 공·이동 물체에 공통 적용해 충돌 시점의 렌더링 시간축을 통합한다.

## [2026-08-01] test | compact board and short move timing

- 축약 모바일 보드의 실제 폭과 단일 구간 이동 애니메이션의 시간 진행을 회귀 검증한다.

## [2026-08-01] qa | responsive regression refresh

- 보드 우선 레이아웃 회귀가 추가되어 최신 전체 테스트 수와 출시 검증 문서를 갱신한다.
- ## [2026-08-01] physics | wall collision invariant
- 벽이 상태의 `solid` 플래그에 의해 물리 후보에서 빠질 수 있는 경로를 확인했다. 벽은 항상 고정 장애물로 판정하도록 직접 후보 규칙을 보강하고, 일반 발사와 연쇄 이동의 회귀 테스트를 추가한다.
- 벽 물리 불변식 테스트를 포함한 샷 리졸버 테스트가 통과해 검증 수를 68개로 갱신한다.
- 병렬 출시 감사에서 검증 표의 67개 표기가 실제 전체 테스트 68개와 불일치함을 확인해 증빙 수치를 동기화한다.
- 상용 UX 감사에서 320px HUD의 목표·행동 안내가 한 줄 말줄임으로 잘릴 수 있음을 확인해 단계형 코치 문장을 여러 줄로 보존하고 회귀 키를 추가한다.
- 게임성 감사에서 2단계 직선 우회와 3단계 점착 우회를 확인했다. 접근 차단 벽과 점착 발판 선행 계약을 실제 레벨·물리 테스트에 반영한다.
- 레벨별 점착 선행 규칙을 인덱스 비교가 아닌 `GameState` 계약으로 전달해 테스트 상태와 실제 레벨 정의가 같은 규칙을 사용하도록 정리한다.
- 실제 레벨 계약 테스트에 2단계 직선 우회 실패와 3단계 점착 선행 성공 순서를 추가한다.
- 2단계 우회 테스트가 벽 충돌의 정상 이벤트인 `bounced`를 확인하도록 기대값을 물리 이벤트 계약과 맞춘다.
- 2단계 직선 우회 차단·3단계 점착 선행·320px 안내 회귀를 포함한 전체 테스트 69개가 통과했다.
- 보조기술 조준 동작에 위·아래 방향 증감을 추가해 좌우만으로 제한되던 접근성 입력을 확장한다.
- Flame 렌더러의 실제 애니메이션 종료 시점을 GameScreen 결과 팝업의 단일 기준으로 연결해 별도 Timer와의 시간축 불일치를 제거한다.
- 결과 애니메이션 경로가 없는 즉시 판정도 종료 콜백을 놓치지 않도록 렌더러 상태 스냅샷의 즉시 완료 경로를 보강한다.
- 즉시 완료 콜백은 상태 갱신 중 중첩 setState가 발생하지 않도록 다음 마이크로태스크에서 실행한다.
- 큰 프레임 공백(앱 복귀·테스트의 단일 pump)에서는 보이지 않은 애니메이션 구간을 최종 상태로 정리해 결과 팝업이 영원히 대기하지 않도록 보강한다.
- FlameGame 내부에 논리 애니메이션 시간 기반 완료 보장을 추가한다. 실제 프레임 종료와 watchdog은 같은 종료 함수만 호출하고 UI는 계속 렌더러 콜백만 따른다.
- 발사 애니메이션 중 보드·엔티티 의미론 입력을 함께 차단해 충돌 재생 중 정보 팝업이나 조준 상태가 바뀌지 않도록 한다.
- 보조기술 엔티티 선택 콜백에도 동일한 애니메이션 차단 조건을 적용한다.
- 발사 중 물체 탭 차단 회귀를 추가해 충돌 재생 중 팝업·조준 상태 변경을 방지하는 계약을 고정한다.
- 넓은 세로 화면에서 520px 고정 폭 때문에 게임판이 작게 보이던 문제를 확인해 반응형 콘텐츠 폭을 확장하고 보드 중심성을 높인다.
- 실제 출품 설정 대신 플레이 품질을 우선해 탭·드래그·롱프레스 제스처를 raw pointer 상태 흐름으로 통합한다. 짧은 탭은 정보, 이동은 조준, 공 장기 누름은 충전으로 분리한다.
- 기존 GestureDetector의 팬·롱프레스 경쟁 콜백을 제거하고 게임판 입력을 하나의 Listener로 연결한다.
- 정적 분석에서 raw pointer 좌표 비교 API와 미사용 필드를 확인해 즉시 수정한다.
- 렌더러의 즉시 완료 콜백을 발사 트랜잭션에서만 허용하도록 명시해 일반 조준·속성 상태 갱신이 애니메이션 종료로 오인되지 않게 한다.
- 상용 수준 시각 품질 개선을 위해 공통 광원 방향, 접촉 그림자, 벽·게이트의 깊이 면, 홀의 내부 명암, 젤리의 반사 재질을 렌더링 계층에서만 보강한다. 물리·게임 상태 로직은 수정하지 않는다.
- 젤리 본체 안쪽에 투과 그라데이션과 저채도 음영을 추가해 표면 광택만으로 보이지 않던 유체 재질감을 보강한다.
- 광원 방향 상수가 실제 하이라이트 선 계산에 사용되도록 연결해 시각 규칙과 정적 분석을 함께 정리한다.
- 레벨 3 점착 선행 조건이 직접 충돌과 연쇄 충돌에서 동일하게 적용되도록 스위치 판정 계약을 통합하고, 거부 충돌의 재접촉을 막는 회귀 테스트를 추가한다.
- 연쇄 스위치 테스트 픽스처에 점착 선행 조건을 명시해 상자 연쇄 우회 회귀를 재현 가능하게 만든다.
- 점착 선행 연쇄 회귀가 추가되어 전체 테스트 수를 71개로 갱신하고 검증 문서와 동기화한다.
- 3단계 HUD에 점착 선행 상태를 짧은 진행 안내로 표시해 실패 후에야 순서를 추론하는 문제를 줄인다.
- 3단계 첫 화면의 점착 진행 안내를 위젯 회귀로 고정해 모바일 HUD에서도 선행 순서가 노출되는지 확인한다.
- 3단계 진행 안내 위젯 회귀가 추가되어 전체 테스트 수를 72개로 갱신한다.
- 정적 분석에서 공통 광원 기준 상수가 미사용으로 남은 것을 확인해 하이라이트 선의 위치 계산에 연결하고 경고를 제거한다.
- 연쇄 물리 정밀화 작업을 시작한다. 기존 거리 기반 `_pushWithMomentum` 구조와 결정론적 이벤트·경로 계약은 유지하고, 충돌 쌍의 restitution 결합값과 질량 전달률을 실제 거리 감쇠에 반영한다.
- 벽·젤리·상자·돌·공 연쇄 충돌에서 충돌면 법선과 질량 차이를 같은 전달 방향 규칙으로 사용하고, restitution이 낮을수록 연쇄 이동 거리가 줄어드는 회귀 테스트를 추가한다.
- 미리보기의 벽 고체 판정을 실제 발사 후보 규칙과 통일하고, 원형 히트박스의 짧은 축 보정과 직사각형 경계 접촉 일관성을 적용한다.
- 반발값 변경이 실제 상자 연쇄 이동량과 미리보기 벽 충돌에 반영되는지, 비정사각형 원형 요소가 짧은 축 히트박스를 쓰는지 물리 회귀로 고정한다.
- 반발력·미리보기·히트박스 회귀 3개가 통과해 전체 테스트 수를 75개로 갱신한다.
- 연쇄 이동 루프에 속도 벡터를 도입해 충돌 법선 성분은 질량·반발값으로 갱신하고 접선 성분은 유지하는 방향으로 정밀화한다.
- 상자에서 젤리로 이어지는 혼합 재질 연쇄 픽스처를 추가해 충돌 이벤트 순서와 이동 경로 연속성을 검증한다.
- 혼합 재질 연쇄 회귀가 통과해 전체 테스트 수를 76개로 갱신한다.
- 동일 물체의 다중 애니메이션 이동을 충돌 시간순으로 적용하고, 아직 시작하지 않은 미래 이동이 현재 위치를 덮어쓰지 않도록 렌더러를 보정한다.
- QA 감사에서 자동 발사 구현과 충돌하는 구형 발사 버튼 요구를 확인해 하네스 조작·테스트 계약을 자동 발사 기준으로 통일한다.
- 직사각형 모서리의 정확한 동률 접촉에서 한쪽 면을 임의 선택하던 반사 법선을 대각선 법선으로 보정하고 모서리 반사 회귀를 추가한다.
- 앱 생명주기 전환 시 충전 타이머와 포인터 상태를 취소해 백그라운드 복귀 직후 의도하지 않은 자동 발사를 막는다.
- 새 릴리스 빌드를 기존 8080 서버 종료 후 교체하고, 시각 품질·연쇄 물리·모서리 반사·생명주기 보정을 포함한 전체 78개 테스트와 HTTP 200 응답을 확인한다.
2026-08-01 | 시각 품질 감사 및 보드·목표·재질 렌더링 고도화 작업을 시작한다. 지정 범위는 property_shot_game.dart 중심이며 물리 로직과 테스트 파일은 수정하지 않는다.
2026-08-01 | 물리 QA에서 연쇄 물체의 최신 위치 공유, 충돌 후 공 분리, 연쇄 중 비벽 물체 재접촉 차단을 점검하고 돌·상자·벽 이벤트 순서 회귀를 추가한다.
2026-08-01 | 오디오·햅틱 피드백 계층을 감사한다. 외부 오디오 파일 없이 Flutter 기본 시스템 사운드와 햅틱을 조합하고, 이벤트별 중복 억제·무음 환경·웹/iOS 플러그인 실패를 안전하게 처리한다. 자동 발사와 앱 생명주기 계약은 유지한다.
2026-08-01 | 피드백 계층 검증 중 활성화 전 포인터 취소에서 취소 안내가 누락되는 입력 경로를 확인한다. 사용자 취소와 앱 생명주기 취소를 분리해 자동 발사 방지와 안내 상태를 함께 보존한다.
2026-08-01 | `GameFeedback`를 추가해 속성 선택·이전·복사, 발사, 충돌, 스위치, 클리어·실패, 일시정지·취소 피드백을 Flutter 기본 시스템 사운드와 햅틱으로 분리한다. 이벤트별 최소 간격과 플랫폼 플러그인 실패 흡수를 적용하고, 활성화 전 포인터 취소 안내도 보강했다. `flutter analyze`, 전체 82개 테스트, `flutter build web --release`가 통과했다.
2026-08-01 | iOS 릴리스 빌드는 Xcode 컴파일 단계까지 통과했지만 Development Team과 프로비저닝 프로파일이 없어 배포 산출물 생성은 환경 설정 단계에서 중단됐다. 기본 시스템 사운드·햅틱 API 자체의 소스 컴파일 오류는 확인되지 않았다.
## [2026-08-01] qa | 모바일 위젯 회귀 범위 감사

- `harness_docs/readme.md`, `rules/testing.md`, `agents/qa_review.md`, `qa/regression_checklist.md`, `final/remaining_risks.md`를 기준으로 `test/widget_test.dart`의 320x568·390x844·접근성·팝업 검증 범위를 감사한다.
- 제품 코드는 수정하지 않고, 앱 생명주기 전환 중 롱프레스 취소, 안전영역, 컨트롤·팝업 겹침을 실제 위젯 회귀로 보강한다.
- 검증은 `flutter test test/widget_test.dart`, `flutter analyze`, `git diff --check`로 수행하고 테스트 수와 화면별 검사 범위를 기록한다.
2026-08-01 | 모바일 QA 회귀를 320x568·390x844 안전영역 가정까지 확장하고, 생명주기 일시정지·복귀 중 충전 취소, 조기 롱프레스 취소, 팝업 경계, HUD·컨트롤 교차 검사를 추가했다. 접근성 의미 노드는 두 휴대폰 크기에서 별도 검증한다.
2026-08-01 | Flutter 위젯 테스트의 접근성 핸들 정리 순서를 점검했다. 의미 라벨 finder는 별도 SemanticsHandle 없이도 검증되므로 테스트 종료 시 핸들 누수를 유발하는 보조 핸들을 제거한다.
2026-08-01 | 최종 모바일 QA 검증에서 위젯 테스트 29개와 전체 테스트 83개를 통과시킨다. 320x568·390x844 안전영역 경계, 팝업 버튼, HUD·컨트롤 비겹침, 생명주기 충전 취소, 조기 롱프레스 취소, 두 크기의 한글 접근성 의미 라벨을 포함한다.
- 퍼즐 감사에서 하네스 5장의 구형 별도 발사 버튼 계약을 확인해 8장·12장·17장과 같은 자동 발사 문장으로 통일하고, 클리어·실패 피드백은 상태 변경 콜백 밖에서 실행하도록 정리한다.
- 오디오·햅틱 계층, 320x568·390x844 안전영역·접근성·생명주기 회귀, 자동 발사 문서 통일을 통합한 뒤 전체 83개 테스트와 분석을 다시 통과시킨다.
- 1~3단계의 첫 안내와 속성 이전 후 안내에 속성 선택·이전·힘 조절·손을 떼면 자동 발사하는 흐름을 일관되게 표시한다.
- 결정론적 퍼즐 감사 테스트에서 각도 10도 간격과 힘 4단계를 탐색해 1·2단계 의도 풀이 존재와 무속성 우회 부재를 확인하고, 3단계는 점착 선행 계약을 별도 검증한다.
- 격자 감사에서 발견된 벽 뱅크샷 우회를 레벨 배치만으로 숨기지 않고, 1단계 상자 밀기·2단계 탄성 속성이라는 홀 진입 계약을 레벨 정의와 결정론적 성공 판정에 명시한다.
- 전체 회귀에서 레벨 1 속성 물체의 기존 터치 좌표와 단계 진행 문구 호환성 회귀를 확인해 물체 위치를 유지하고 진행 번호를 안내 문장에 보존한다. 3단계 점착 감사는 실제 점착 조준 각도로 고정한다.
- 320px 회귀에서 장문 단계 안내가 상단 HUD를 키워 무거운 돌 터치 영역을 가리는 문제를 재현하고, 자동 발사 의미를 유지한 2줄 내외의 간결한 문장으로 압축한다.
- 좁은 화면 정보 팝업 재현에서 안내 압축만으로 해결되지 않아 보드·HUD·속성 물체의 실제 배치 좌표를 계측해 입력 차단 원인을 확인한다.
- 320px 계측 결과 compact HUD가 게임판 위에서 y=62~208을 차지해 무거운 돌을 가리는 것을 확인하고, compact HUD를 보드와 겹치지 않는 세로 레이아웃 영역으로 분리한다.
- HUD 분리 후 320px 보드 높이 회귀가 남아 있어 compact HUD·aim 영역·SafeArea의 실제 크기를 계측하고 최소 보드 영역을 재설정한다.
2026-08-01 | 결정론적 퍼즐 감사에서 확인된 1·2단계 무속성 벽 반사 우회와 3단계 대표 점착 조준의 선행 충돌을 수정하기 위해, 벽을 증설하지 않고 레벨 배치만 조정한다. 의도 풀이·벽 고정·스위치·문·홀 규칙은 유지하며 감사 테스트 파일은 변경하지 않는다.
- 2026-08-01: 320px 모바일 계측 결과 compact HUD가 보드 폭을 241px까지 줄이는 원인을 확인해, 안내 문구를 짧게 정리하고 HUD 세로 밀도를 낮춘다.
- 2026-08-01: 안내 문구를 2줄 이내로 정리했지만 compact HUD가 여전히 보드 폭을 252px로 제한해, 다음 계측에서 HUD 구성별 높이를 확인한다.
- 2026-08-01: compact HUD를 보드와 분리한 320px 레이아웃은 보드 252x392px을 확보하므로, 겹침 없는 최소 폭 검증을 240px 이상으로 갱신하고 임시 계측 출력을 제거한다.
- 2026-08-01: 전체 검증 86개 통과 결과를 반영하고, 퍼즐 감사·홀 진입 계약·모바일 HUD 분리·튜토리얼 자동 발사 문구를 작업별 커밋으로 나눠 순차 푸시한다.
- 2026-08-01: 병렬 QA에서 첫 화면 발견성·보드 비율·에셋 화풍 불일치와 이전 공의 홀 계약 우회를 확인했다. 고해상도 상자 스프라이트를 추가하고 홀 조건 및 실제 상자 이동 이벤트를 보강한다.
- 2026-08-01: 홀에 있는 과거 공은 단계 계약이 이미 충족된 경우에만 클리어를 이어가도록 하고, 고정 상자의 오기록·점착 공의 재질별 첫 충돌 규칙을 회귀 테스트로 고정한다.
- 2026-08-01: 홀 계약 회귀 픽스처가 현재 공과 홀을 다른 높이에 배치해 거절 이벤트를 재현하지 못한 것을 확인하고, 동일 선상 좌표로 테스트를 교정한다.
- 2026-08-01: 과거 공을 밀어 홀에 넣는 연쇄 경로가 별도 계약 없이 성공하는 2차 우회를 재현해, 현재 발사 공의 속성과 이번 샷의 선행 행동을 모든 연쇄 홀 판정에 공통 적용한다.
- 2026-08-01: 계약 없는 과거 공 재현은 홀 거절보다 동일 질량 충돌이 먼저 발생하는 입력임을 확인해, 테스트를 성공·기존 공 클리어 불변식 중심으로 정리한다.
- 2026-08-01: 웹 매니페스트가 기본 Flutter 아이콘을 사용하던 플랫폼 간 브랜딩 불일치를 확인해 프로젝트 전용 앱 아이콘으로 통일하고, 사용하지 않은 생성 상자 원본은 정리한다.
- 2026-08-01: 격리된 Pillow 환경으로 고해상도 상자 스프라이트의 초록 배경을 알파로 제거했다. 게임 렌더러·속성 팝업·Flutter 에셋 목록을 같은 생성 스프라이트로 연결한다.
- 2026-08-01: 병렬 UX 감사의 P0인 첫 샷 순서 발견성 부족을 보강해 방향 설정·롱프레스 대기·자동 발사 상태를 단계별 한글 안내와 즉시 피드백으로 표시한다.
- 2026-08-01: 고해상도 상자 최종 PNG의 알파·모서리 상태를 확인했다. 프로젝트 번들에는 최종 스프라이트만 남기고 생성 원본·프롬프트 요약·권리 검토 상태를 문서화한다.
- 2026-08-01: 번들 자산 추적 문서에도 새 상자 스프라이트 경로와 생성 권리 검토 상태를 반영해 실제 포함 자산과 문서 목록을 일치시킨다.
- 2026-08-01: 보드 상단 배치, 고해상도 상자 에셋, 첫 샷 안내, 홀 계약·고정 상자·점착 재질 회귀를 통합한 뒤 전체 88개 테스트와 분석을 통과했다.
- 2026-08-01: 상자와 동일한 입체 조명 기준의 고해상도 무거운 돌을 생성·검수했고, 투명 처리 후 게임 화면·팝업 공통 스프라이트로 연결한다.
2026-08-01 | UX QA 피드백 반영을 시작한다. 홀 거절 원인, 속성 이동·복사 의미, 짧은 단계 목표를 한글로 명확히 표시한다.
2026-08-01 | 단계 목표 문구는 기존 위젯 계약을 유지하고, compact HUD만 두 줄 표시로 확장해 한글 축약을 방지한다.
2026-08-01 | 시각 품질 개선을 시작한다. 점착판·스위치·문에 기능을 읽을 수 있는 재질과 구조 디테일을 추가하고 공통 광원 규칙을 유지한다.
2026-08-01 | 스프라이트와 Canvas 물체의 세계감을 맞추기 위해 상자·돌에 공통 외곽선 실루엣을 추가한다.
2026-08-01 | 모바일 입력 안정화를 시작한다. 활성 포인터를 고정하고 조준 중 이동·다중 터치·공 영역 이탈 시 롱프레스 충전을 취소한다.
2026-08-01 | 연쇄 물리 보정 작업을 시작한다. 속도 감쇠용 배율과 충돌 방정식의 반발계수를 분리해 기본 충돌의 에너지 과증폭을 막는다.
2026-08-01 | 팝업 접근성 개선을 시작한다. 닫기 포커스·48px 터치 영역·한국어 닫기 의미와 모든 물체 정보 접근성 동작을 보강한다.
2026-08-01 | 충돌 피드백 동기화를 시작한다. 애니메이션의 triggerPathIndex를 실제 햅틱·효과음 시점으로 사용하고 한 충돌당 한 번만 재생한다.
2026-08-01 | 팝업 포커스 범위를 고정하고 버튼 문구를 행동 중심 한글로 정리한다. 클리어·실패·정보 팝업의 탐색 순서를 보강한다.
2026-08-01 | 기존 위젯 문구 계약을 유지하면서 팝업 버튼의 접근성 의미만 구체화하도록 호환성을 조정한다.
2026-08-01 | 시스템 뒤로가기 처리 보강을 시작한다. 팝업이 열려 있으면 화면 종료보다 팝업 닫기를 우선한다.
2026-08-01 | 고정형 2.5D 표현을 확장한다. 모든 직사각형 물체에 공통 프리즘 깊이 면을 적용하고 공 잔상을 경로 속도에 맞춘다.
2026-08-01 | 상자·돌 스프라이트도 고정 카메라 깊이를 읽도록 하단 압출면과 공통 외곽선을 함께 표시한다.
2026-08-01 | 홀 포획 우선순위와 물체 표현을 보정한다. 선분-홀 입구 진입을 벽보다 먼저 판정하고 무거운 돌 빗금 제거 및 상자 크기 확대를 적용한다.
2026-08-01 | 홀 앞 포획 영역이 뒤쪽 벽보다 우선하는 회귀 테스트를 추가한다. 홀 성공 시 공 위치가 홀 중심에 고정되는 조건을 검증한다.
2026-08-01 | QA 결과를 반영해 홀 포획 반경을 시각적 접촉에 맞추고, 홀 입구 경계 회귀 테스트를 보강한다.
2026-08-01 | Property Shot 상용 수준 고도화 반복을 시작한다. 목표 파일을 재확인하고 README·harness_docs 전체 기준, 현재 브랜치 commercial/wall-physics-qa, clean 작업 트리, 최근 커밋 a3169fd, 서버 미실행 상태, 기존 90개 테스트 기준선을 확인했다. 핵심 가설은 첫 3스테이지의 이해 가능성과 대표 무거움 스테이지의 화면 밀도·타격감·실패 피드백을 함께 개선하면 상용 수직 슬라이스에 가까워진다는 것이다. 투입 역할은 아트 디렉터, UX·난이도 디자이너, VFX·QA 전문가이며 실제 사용자 테스트와 iOS 실기기 검증은 아직 수행하지 않는다.
2026-08-01 | 대표 수직 스테이지 1차 구현을 시작한다. 민트 격자 중심 보드를 장난감 정원 보드로 강화하고, 조준 화살표를 색상·그림자·힘 게이지가 통합된 표시로 개선하며, 실패 시 힘 부족·과다를 구분할 수 있도록 이벤트 피드백을 확장한다.
2026-08-01 | 아트 디렉터 독립 진단을 반영해 스타일 가이드와 대표 보드 구성 문서를 추가한다. 핵심 판단은 장면을 바깥 배경·목재 프레임·플레이 필드로 분리하고, 홀·벽·젤리·스위치·문을 동일한 광원·외곽선·접지 그림자 규칙으로 묶어야 한다는 것이다. 실제 사용자 선호와 실기기 화면은 아직 미검증이다.
2026-08-01 | UX·난이도 진단 결과를 반영해 복사 시스템 선택지를 문서화한다. 현재 무제한 복사는 튜토리얼에는 유리하지만 전략적 희소성이 없으므로, 스테이지당 제한 복제권 모델을 권고한다. 사용자의 최종 결정 전에는 복사 횟수 규칙과 저장 데이터 변경을 구현하지 않는다.
2026-08-01 | 저·고파워 실패 피드백의 결정론을 단위 테스트로 고정한다. 복사 시스템은 사용자 결정 전까지 변경하지 않는다.
2026-08-01 | 보드 스타일 토큰을 실제 오브젝트 색상에 확장한다. 벽은 청록 고무, 젤리는 반투명 민트, 홀은 잔디 링·노랑 목표광으로 통일해 기능과 재질을 동시에 읽게 한다.
2026-08-01 | 활성 공의 직접 충돌과 홀 포획을 정규화된 ShotImpact 이벤트로 기록하고 렌더링·햅틱 재생에 연결한다. 물리 결과는 변경하지 않고 충돌 위치·법선·대상·경로 시점만 확장한다.
2026-08-01 | 대표 보드·조준·충돌 이벤트·UX 문서 작업을 각각 commit/push했다. 다음 검증 기준은 전체 92개 테스트, 정적 분석, Web release 빌드, 서버 교체이며 실제 iOS·iPhone·iPad와 사용자 테스트는 미검증으로 남긴다.
2026-08-01 | 전체 회귀 검증 결과를 확정한다. flutter analyze 통과, flutter test 93개 통과, flutter build web --release 통과. 신규 ShotImpact 직접 충돌 테스트까지 포함한 수치이며 실제 iOS·실기기·사용자 테스트는 미검증이다.
2026-08-01 | 다음 P0 반복을 시작한다. 브랜치 commercial/wall-physics-qa, HEAD 1a67d79, 작업 트리 clean, 기준선 flutter analyze·flutter test 94개·Web release 통과, 데모 서버 8080 HTTP 200을 확인했다. 연쇄 물리·홀 포획·애니메이션 시간축·초반 3단계 이해도를 우선 진단하며 실제 iOS·사용자 테스트는 미검증으로 유지한다.
2026-08-01 | ShotImpact 재질별 햅틱 강도 차이를 추가한다. 물리 판정과 결정론에는 영향을 주지 않고 벽·무거운 물체·젤리·점착·홀의 접촉 감각을 분리하는 반복이다.
2026-08-01 | P0 물리 보강을 시작한다. 연쇄로 이동한 공이 홀에 먼저 진입하면 해당 경로를 종결하고 이후 벽 충돌을 차단하며, ShotImpact에 실제 대상 ID를 기록한다. 동일 입력의 결정론과 벽 고정 불변식을 유지한다.
2026-08-01 | 연쇄 공-홀-벽 회귀 시나리오를 추가한다. 홀 진입 ShotImpact의 대상 ID·경로 시점과 홀 이후 벽 충돌 부재를 함께 검증한다.
2026-08-01 | 애니메이션 종료의 벽시계 Timer 의존을 제거하고 Flame update의 논리 커서만 종료 소유자로 사용한다. 프레임 드롭·백그라운드 복귀 뒤에도 이벤트 순서와 완료 콜백을 한 번만 유지하는 반복이다.
2026-08-01 | Timer 제거 후 남은 빈 onRemove 재정의를 삭제해 정적 분석 경고 없이 애니메이션 수명주기를 정리한다.
2026-08-01 | 위젯 테스트에서 완료 콜백 대기가 누락된 회귀를 확인했다. 논리 커서를 최종 종료 기준으로 유지하되 Timer는 커서가 끝날 때까지 재확인하는 보조 깨우기로 조정한다.
2026-08-01 | 종료 보조 타이머를 전체 재생시간 단일 예약에서 80ms 커서 확인 주기로 바꾼다. 긴 테스트 시간 점프와 실제 프레임 드롭 모두에서 조기 종료를 막고 완료를 놓치지 않게 한다.
2026-08-01 | 80ms 폴링이 Flutter 위젯의 단일 시간 점프에서 커서 갱신을 보장하지 못함을 확인했다. 커서 진행 시 즉시 종료하고, 예상 재생시간 뒤에는 중복 방지된 보조 타이머가 최종 상태를 닫도록 복원한다.
2026-08-01 | 문 열림 연출을 반복 흔들림에서 충돌 시점 이후 단조 증가하는 좌우 개방 진행률로 바꾼다. 스위치 접촉·문 이동·완료의 인과관계를 화면에서 읽을 수 있게 한다.
2026-08-01 | P0 물리·P1 연출 반복의 구현 후 기록을 갱신한다. ShotImpact 대상 ID, 연쇄 홀 종결, 커서 우선·Timer 보조 종료, 재질별 햅틱, 진행률 기반 문 열림과 95개 테스트 통과를 반영한다. 실기기·실사용자 검증은 미완료다.
2026-08-01 | 첫 2개 튜토리얼의 성공 영역을 2도·0.02 파워 간격으로 측정하는 UX 회귀 감사를 추가한다. 자동 성공 폭은 사용자 플레이를 대체하지 않으며, 실제 직관성은 미검증으로 남긴다.
2026-08-01 | 첫 2단계 성공 영역 감사가 1단계 각도 28도·파워 0.84, 2단계 각도 46도·파워 0.72 샘플 폭을 통과했다. 총 샘플 폭이며 연결성·실제 사용자 이해도는 별도 미검증으로 기록한다. 전체 테스트는 96개다.
2026-08-01 | 테스트 린트의 avoid_print 정보로 인해 성공 영역 감사의 콘솔 출력은 제거하고 수치 검증만 유지한다.
2026-08-01 | flutter build ios --no-codesign을 실행했다. Xcode 빌드까지 진행됐지만 Development Team·프로비저닝 프로파일 부족으로 배포용 빌드는 실패했다. 실제 iPhone/iPad 입력·프레임·햅틱은 미검증으로 유지한다.
2026-08-01 | 구현 후 평가 문서 초안을 추가한다. 자동 검증으로 증명 가능한 항목과 실제 사용자·실기기에서만 확인 가능한 항목을 분리하고, 복사 시스템 최종 선택은 사용자 응답 전까지 미결정으로 유지한다.
2026-08-01 | 구현 후 아트·UX·VFX QA Subagent 3인의 재평가를 완료했다. 공통 판정은 조건부 통과이며, 물리·기능 QA는 양호하지만 단일 애니메이션 시간축, 누적 거리 재생, 재질별 오디오·햅틱, 실기기 성능, 실제 사용자 직관성, 복사 모델 결정이 남았다.
2026-08-01 | 재평가 P0를 반영해 애니메이션 종료 콜백의 단일 소유자를 예약 타이머로 정리한다. 프레임 업데이트는 시각 커서와 충돌 이벤트만 진행하고, 물리 결과나 팝업 상태를 중복 종료하지 않도록 한다.
2026-08-01 | 구현 후 재평가의 애니메이션 종료 이중화 지적을 반영했다. 종료 콜백은 예약 타이머가 소유하고 프레임 업데이트는 커서·이벤트 진행만 담당한다. 누적 거리 재생과 실기기 프레임 검증은 여전히 다음 반복으로 남긴다.
2026-08-01 | 연쇄 이동 물체의 경로 재생을 포인트 인덱스가 아닌 누적 거리 기반으로 보정한다. 활성 공의 결정론적 시뮬레이션 경로는 유지하고, 상자·돌·이전 공의 시각 이동만 실제 경로 길이에 맞춰 보간한다.
2026-08-01 | 연쇄 물체 충돌도 ShotImpact로 기록해 활성 공과 동일한 VFX·햅틱 파이프라인을 사용하게 한다. 기존 ShotAnimationMove는 이동 경로와 상태 변화 재생에만 사용하고 충돌 피드백은 정규화 이벤트가 담당한다.
2026-08-01 | 연쇄 충돌 ShotImpact가 이전 공과 벽까지 기록되는 회귀 테스트를 추가해 물리 이벤트 누락을 방지한다.
2026-08-01 | 연쇄 충돌 이벤트 정규화와 누적 거리 재생을 포함한 전체 검증 수치를 94개 테스트 기준으로 갱신한다.
2026-08-01 | 구현 후 P0 재평가를 반영해 홀 포획 연쇄 이동의 visualState를 보존하고, 홀 중심으로 빨려 들어가며 축소·페이드되는 렌더 연출을 추가한다. 물리 판정과 결정론적 경로는 변경하지 않으며 애니메이션 완료 중복 방지 검증을 함께 보강한다.
2026-08-01 | 홀 포획 연쇄 이동의 시각 상태가 ShotAnimationMove까지 전달되는지 회귀 검증을 추가한다. 물리 결과·홀 뒤 벽 차단·대상 식별자 검증은 기존 테스트와 함께 유지한다.
2026-08-01 | 애니메이션 보조 타이머가 논리 커서보다 먼저 완료 콜백을 실행하지 않도록 종료 요청과 실제 종료를 분리한다. 타이머는 대기 상태만 표시하고, Flame update가 전체 경로를 재생한 뒤에만 애니메이션을 닫는다.
2026-08-01 | 위젯 테스트 환경에서 Flame update가 시작되지 않는 기존 팝업 계약을 확인했다. 실제 프레임이 한 번이라도 진행된 실행에서는 커서 종료를 강제하지 않고, 프레임이 전혀 시작되지 않은 경우에만 최후 보조 완료를 허용한다.
2026-08-01 | QA 재평가에서 연쇄 공의 홀 충돌 이벤트가 활성 공 렌더에 섞일 수 있음을 확인했다. ShotImpact에 발생 주체 ID를 기록하고 활성 공은 자기 이벤트만 소비하도록 분리하며, 백그라운드 상태의 보조 완료 강제를 차단한다.
2026-08-01 | 초반 성공 영역 감사가 전체 성공 샘플 폭을 합산하던 문제를 보강한다. 원형 각도 연결 구간, 파워 연결 구간, 각도·파워 격자의 최대 연결 성분을 측정해 첫 두 단계의 실제 연속 성공 영역을 검증한다.
2026-08-01 | 연결성 감사에서 1·2단계의 실제 연속 각도 폭이 8도로 확인됐다. 초반 학습 단계의 조준 허용성을 넓히기 위해 두 단계의 목표 홀을 42 단위로 조정하고, 동일한 물리 판정으로 재측정한다.
2026-08-01 | 홀 크기 조정 후 연결성 감사의 현재 수치를 확정한다. 1단계는 연결 각도 16도·파워 0.86·최대 격자 성분 248셀, 2단계는 연결 각도 16도·파워 0.72·최대 격자 성분 223셀이다. 과거 전체 샘플 폭 수치는 현재 기준에서 역사적 참고값으로 분리한다.
2026-08-01 | 평가 점수의 기준을 문서에 명시한다. 71점은 자동 검증 중심의 현재 코드 프록시, 79점은 게임성·디자인을 포함한 별도 전문가 프록시이며 서로 다른 평가표의 결과다. 실제 사용자·실기기 검증 전에는 어느 점수도 출품 승인 점수로 사용하지 않는다.
2026-08-01 | Flame 게임 객체를 직접 업데이트하는 가상 30·60·120Hz 애니메이션 회귀 테스트를 추가한다. 각 프레임 빈도에서 충돌 이벤트가 중복되지 않고 완료 콜백이 한 번만 실행되는지 확인하며 Canvas 픽셀·실기기 성능 검증과는 구분한다.
2026-08-01 | 가상 프레임 애니메이션 회귀가 통과해 현재 전체 테스트 기준을 97개로 올린다. 이전 96개 기록은 직전 반복 기준선으로 남기고, 최신 검증 문서에는 97개를 사용한다.
2026-08-01 | 상용 수직 슬라이스 계획 문서의 현재 기준선도 97개 테스트로 통일한다. 90·93·94·95·96개는 각 과거 반복의 역사적 기준선으로만 남긴다.
2026-08-01 | 게임판 Canvas를 RepaintBoundary로 고정하고 초기 보드의 실제 픽셀 분산을 확인하는 렌더 회귀를 추가한다. 이는 비어 있지 않은 렌더링과 기본 보드 가시성만 검증하며 상용 아트 골든 승인이나 실기기 프레임 측정을 대신하지 않는다.
2026-08-01 | Flutter 테스트 호스트의 Canvas toImage가 지속 ticker와 함께 완료되지 않아 픽셀 회귀 시도를 제거한다. RepaintBoundary 변경은 남기지 않고, Canvas 픽셀 골든·실기기 시각 검증은 미검증 위험으로 유지한다.
2026-08-01 | 플랫폼 기본 사운드도 충돌 재질의 무게감을 구분하도록 무거운 충돌은 알림음, 일반·탄성·점착 충돌은 클릭음으로 매핑한다. 실제 전용 오디오 자산은 추가하지 않으며 사운드 선택을 주입 가능한 테스트로 고정한다.
2026-08-01 | 충돌 재질별 플랫폼 사운드 테스트가 통과해 현재 전체 테스트 기준을 98개로 갱신한다. 전용 오디오 자산과 실기기 음량·무음 모드 검증은 여전히 미검증으로 남긴다.
2026-08-01 | 코드로만 그리던 젤리 범퍼를 상자·무거운 돌과 같은 프로젝트 전용 스프라이트 품질로 올리는 반복을 시작한다. 투명 배경 생성·검증 후 렌더러에 연결하고 물리 판정과 결정론적 테스트는 변경하지 않는다.
2026-08-01 | 젤리 범퍼 생성 스프라이트를 실제 게임 렌더러와 속성 표시 경로에 연결하기 전 현재 구조와 자산 권리 기록을 재확인한다. 젤리의 탄성 물리와 결정론적 테스트는 유지하고, 스프라이트 품질·비율·투명 배경만 검증 범위에 포함한다.
2026-08-01 | 젤리 범퍼를 `jelly-bumper-v1.png` 고해상도 스프라이트로 게임 렌더러와 물체 썸네일에 연결했다. 무거운 돌보다 얕은 깊이 압출을 적용해 젤리의 유체 재질을 구분하고, 기존 젤리 코드 도형은 이미지 로드 전 대체 경로로만 남긴다.
2026-08-01 | 젤리 자산 연결 코드의 Dart 포맷을 정리한 뒤 정적 분석·전체 테스트·Web release 빌드 순서로 회귀를 확인한다. 화면 픽셀 골든은 기존 테스트 호스트 제약으로 별도 수동 브라우저 확인을 병행한다.
2026-08-01 | QA가 확인한 젤리 회귀를 보정한다. 이미지 렌더 경로에서도 속성 보유 점멸을 유지하고, 정사각형 젤리 스프라이트는 원본 비율을 보존해 렌더링하며, 알파 변환본은 가장자리 마테를 줄여 다시 생성한다.
2026-08-01 | QA 보정 후 `flutter analyze`, 전체 98개 테스트, Web release 빌드와 젤리 자산 HTTP 응답을 재검증했다. 정사각 젤리의 비율 보존·속성 점멸 유지·알파 마테 완화 상태를 기록하고, 실제 Canvas 픽셀과 iOS 실기기 검증은 여전히 별도 게이트로 남긴다.
2026-08-01 | 젤리 최종 PNG를 육안 점검한 결과 하이라이트 내부까지 투명 구멍처럼 보이는 마테가 남아 있어 변환 방식을 재검토한다. 소프트 매트 대신 하드 키와 최소 알파 수축을 비교해 반사광을 보존한다.
2026-08-01 | 하드 키 변환본에서 젤리 하이라이트 내부 투명 구멍이 사라진 것을 확인했다. 스프라이트 교체로 약해진 젤리의 탄성 체감을 보완하기 위해 충돌 중 물결·방울 보조 연출을 렌더러에 추가한다.
2026-08-01 | 젤리 하드 키 자산과 충돌 물결·방울 연출을 포함한 최신 빌드를 8080 서버로 교체했다. 루트와 젤리 PNG가 각각 HTTP 200이며 분석·98개 테스트·Web release가 모두 통과했다.
2026-08-01 | 젤리 자산 변환 기록을 하드 키 방식으로 정정하고, 충돌 시 물결·방울 보조 연출과 최신 HTTP 검증 결과를 QA 문서에 반영한다. 실제 Canvas 픽셀 골든·iOS 기기 검증은 미완료 상태로 명시한다.
2026-08-02 | 스타일 가이드와 현재 렌더러를 비교해 벽의 회색 블록감과 홀 깃발의 정적 상태를 다음 시각 개선 대상으로 선정했다. 물리 판정·히트박스·한글 UI는 보존하고 장난감 레일 질감과 목표 신호만 보강한다.
2026-08-02 | 벽 질감·리벳과 홀 깃발의 미세한 흔들림을 추가한 뒤 분석·98개 테스트·Web release를 통과시켰다. 기존 서버를 종료하고 최신 빌드로 교체했으며 루트와 JavaScript 응답은 HTTP 200이다.
2026-08-02 | 조준 화살표를 개발용 직선처럼 보이지 않게 개선한다. 정답 궤적은 노출하지 않고, 짧은 분절 샤프트·채워진 화살촉·파워 구간 표식으로 방향과 힘의 역할을 분리한다.
2026-08-02 | 조준 UI 개선 후 `flutter analyze`, 전체 98개 테스트, Web release, 기존 서버 종료·교체와 루트·JavaScript HTTP 200을 확인했다. 방향 샤프트는 분절 표시로 바꾸되 최종 궤적은 계속 숨긴다.
2026-08-02 | 조준 QA의 반론을 반영해 샤프트 길이를 고정하고 구간 사이 공백을 실제로 만든다. 파워는 공 주변 게이지만 담당하며, 궤적처럼 읽힐 수 있는 끝점 원은 제거한다.
2026-08-02 | 시스템·퍼즐·캐주얼 UX 에이전트의 독립 복사 모델 검토를 수렴했다. 최종 권고는 스테이지당 제한 복제권이지만 사용자 결정 전에는 소모·복원·GameState 변경을 보류하고, 먼저 이전과 복사의 UI 문구만 명확히 한다.
2026-08-02 | 복사 모델 사용자 결정 전 안전한 UI 개선을 반영했다. 이전·복사 버튼과 안내 문구를 결과 중심으로 명확히 하고, 실제 소모·복원 규칙은 변경하지 않았다. 최신 Web release와 서버 루트·JavaScript HTTP 200을 확인했다.
2026-08-02 | iOS 기기용 무서명 빌드는 Development Team·프로비저닝 부족으로 실패했으며, Xcode 서명 환경 외 코드 오류는 확인되지 않았다. 이전·복사 버튼 의미를 검증하는 위젯 회귀와 모바일 레이아웃 기준을 문서에 고정한다.
2026-08-02 | 이전·복사 의미 회귀 테스트를 추가해 테스트 수가 99개가 됐다. 과거 98개 기록은 역사적 기준선으로 남기고 최신 검증 표와 반복 계획의 현재 수치를 99개로 갱신한다.
2026-08-02 | 구현 후 위험 문서를 코드와 대조했다. 홀 포획 공의 축소·페이드·흡입 링과 스프라이트 기반 이동 물체는 이미 구현되어 있으므로, 해당 문서의 미구현 표현을 실제 미검증 범위인 실기기 프레임 검증으로 정정한다.
2026-08-02 | 최종 평가표와 README를 최신 코드·검증 기준과 대조했다. 평가 근거의 과거 96개 테스트 표기와 물리 연출을 단순하다고 남긴 설명을 현재 99개 테스트·감속·연쇄 충돌·홀 포획 연출 기준으로 동기화한다.
2026-08-02 | Playwright Chromium으로 390x844·1280x900 Web 데모를 캡처했다. 모바일에서 한글 안내·홀·공·돌·상자·하단 조작 영역의 겹침과 말줄임이 없고, 데스크톱에서도 보드 중앙 배치와 최종 궤적 비노출 조준이 유지됨을 확인한다.
2026-08-02 | 390x844 Playwright 입력으로 돌 위치를 클릭해 실제 속성 팝업을 열었다. 돌 아이콘·무거움 설명·이전·복사 버튼이 화면 안에 표시되는 것을 캡처로 확인했으며, Flutter Web 캔버스 접근성 DOM 직접 조회는 별도 미지원 상태로 기존 위젯 접근성 테스트와 구분한다.
2026-08-02 | 같은 모바일 흐름에서 `떼어 공에 옮기기`를 눌렀다. 팝업이 닫히고 원본 돌의 선택 상태가 사라지며 공의 속성 표시가 `공: 무거움`으로 바뀌는 것을 실제 캡처로 확인한다.
2026-08-02 | `flutter build ios --simulator`를 실행했다. Xcode 16.2의 프로젝트 컴파일은 완료됐지만 설치된 iOS Simulator Runtime이 없어 목적지 선택에서 실패했다. 서명·코드 오류가 아닌 개발 환경 게이트로 기록한다.
2026-08-02 | 사용자 피드백에 따라 특정 기믹을 목표 달성의 필수 조건으로 강제하지 않도록 판정 방향을 전환한다. 속성·상자·점착·문은 추천 풀이와 고유 물리 상호작용으로 유지하되, 실제로 홀에 도달한 모든 물리 경로는 성공으로 인정한다.
2026-08-02 | 강제 판정이 제거된 뒤에도 남아 있던 `requiredHoleTrait`, `requiresCratePush`, `requiresStickyAnchor` 도메인 필드를 제거한다. 레벨 데이터와 테스트 픽스처에서 필수 기믹이라는 이름 자체를 없애 대체 풀이 원칙을 코드 구조에 고정한다.
2026-08-02 | 퍼즐 의도표·README·QA 문서의 강제 기믹 표현을 추천 풀이와 대체 물리 경로 표현으로 동기화한다. 스위치의 무거움 반응처럼 물체 고유 상호작용은 유지하고, 홀 성공은 실제 진입 경로만으로 판정한다.
2026-08-02 | 대체 풀이 판정 전환 후 정적 분석에서 남은 미사용 속성 import를 확인해 제거한다. 동작 변경 없이 컴파일 경고만 정리한다.
2026-08-02 | 대체 풀이 판정 전환 후 `flutter analyze`와 전체 테스트 99개가 통과했다. 웹 릴리스 빌드를 생성하고 기존 8080 서버(PID 95630)를 종료한 뒤 최신 빌드로 재기동했으며 루트와 `main.dart.js`가 HTTP 200을 반환한다.
2026-08-02 | 물리 감사 중 직접 충돌 분기의 `ShotImpact.position`과 애니메이션 `impactPosition`이 분리 보정 후 서로 달라질 수 있음을 확인했다. 충돌 판정 직후 접촉점을 별도로 보존해 벽·젤리·점착판 VFX가 실제 이벤트 위치를 사용하도록 보강한다.
2026-08-02 | 교차 QA에서 클리어 팝업 뒤로가기 후 성공 상태가 고립되는 문제와 연쇄 충돌 대상의 전역 제외를 확인했다. 뒤로가기는 재조준 가능한 계획 상태로 복귀시키고, 연쇄 충돌은 직전 부모만 잠시 제외해 반사 후 재충돌을 허용한다.
2026-08-02 | 연쇄 재충돌·클리어 팝업 뒤로가기 회귀 후 전체 테스트 100개가 통과했다. 3단계 대체 경로는 스위치 반응뿐 아니라 점착 없이 실제 홀 클리어까지 검색하는 감사 조건을 추가한다.
2026-08-02 | 3단계 대체 클리어 감사가 실패해 스위치 작동과 홀 도달이 분리되어 있음을 확인했다. 실제 성공 입력을 탐색해 레벨 배치가 추천·대체 경로를 모두 열도록 조정한다.
2026-08-02 | 3단계 대표 직접 경로 `(1, -1.3), 힘 1`에서 `switch_pressed → crate_pushed → bounced → hole_entered`를 확인하고 감사 테스트로 고정했다. 전체 회귀 기준은 100개로 갱신한다.
2026-08-02 | 연쇄 재충돌·클리어 팝업·3단계 대체 경로 변경 후 `flutter analyze`와 전체 테스트 100개가 통과했다. Web release 빌드를 생성하고 기존 8080 서버(PID 22474)를 종료한 뒤 최신 빌드로 재기동했으며 루트와 `main.dart.js`가 최신 Last-Modified와 함께 HTTP 200을 반환한다.
2026-08-02 | 남은 물리 위험 중 직접 충돌과 연쇄 충돌의 속도·반발 계산식 불일치를 다음 개선 대상으로 채택한다. 재질별 충돌 임펄스 계산을 공유해 같은 접촉이 경로에 따라 다른 결과를 내는 편차를 줄인다.
2026-08-02 | 공유 충돌식의 전면 적용에서 5개 회귀가 발생했다. 기존 속성별 튜토리얼 경로를 보존하기 위해 전면 적용을 철회하고, 재질별 검증을 통과하는 좁은 범위의 공통화로 다시 설계한다.
2026-08-02 | 전면 충돌식 통합은 기존 튜토리얼 회귀로 철회하고 기준선으로 복구했다. 다음 물리 개선은 충돌 스텝의 남은 이동량을 보존하는 작은 시간 예산 변경으로 범위를 좁힌다.
2026-08-02 | 충돌 스텝 남은 이동량 보존 후 `flutter analyze`와 전체 테스트 100개, Web release 빌드가 통과했다. 기존 8080 서버(PID 36150)를 종료하고 최신 빌드로 재기동했으며 루트와 `main.dart.js`가 HTTP 200을 반환한다.
2026-08-02 | 직접 공과 연쇄 물체의 벽 충돌을 먼저 공통화한다. 기존 튜토리얼 감쇠를 보존한 벽 반사 응답 헬퍼를 사용해 반사 방향·재질 반발을 한 규칙으로 관리한다.
2026-08-02 | 벽 응답만 공통화해도 9개 회귀가 발생해 철회했다. 현재 레벨은 반사 에너지 감쇠를 퍼즐 난이도에 사용하므로, 물리식 통합은 별도 레벨 재튜닝 없이는 적용하지 않는다.
2026-08-02 | 최신 Web 데모를 390x844·1280x900으로 캡처해 보드·HUD·조준 UI의 겹침과 한글 말줄임이 없음을 확인했다. 모바일 실제 좌표로 무거운 돌을 눌러 아이콘·설명·속성 옮기기·복사 팝업이 표시되는 화면도 캡처했다. Flutter Canvas 특성상 DOM 텍스트 검색은 검증 수단으로 사용하지 않는다.
2026-08-02 | 3단계 HUD의 `추천 1·2·3` 순서 표기가 다중 풀이 원칙과 어긋날 수 있음을 확인해 번호를 제거한다. 추천 경로는 선택지로 안내하고 점착 없이 직접 가는 경로도 같은 수준으로 노출한다.
2026-08-02 | 3단계 HUD의 추천 순서 번호를 제거한 후 `flutter analyze`, 전체 테스트 100개, Web release 빌드가 통과했다. 기존 8080 서버(PID 45564)를 종료하고 최신 UI 빌드로 재기동한다.
2026-08-02 | iOS 게이트를 재검증했다. Xcode 16.2에서 Flutter Xcode build 단계는 진입했으나 iOS 18.2 Simulator Runtime이 설치되지 않아 destination을 찾지 못하고 종료됐다. 현재 연결 기기는 macOS·Chrome뿐이며 코드 분석 오류는 아니다.
2026-08-02 | 화면의 영어 표현 점검 중 visible 카운터의 외래어 `샷`을 `시도`로 교체한다. 문서와 내부 테스트 설명의 기술 용어는 유지하고 사용자에게 보이는 HUD·접근성 문구만 한글 표현으로 통일한다.
2026-08-02 | visible 카운터를 `샷`에서 `시도`로 바꾼 후 `flutter analyze`·전체 테스트 100개·Web release가 통과했다. 기존 8080 서버(PID 48570)를 종료하고 최신 한글 UI 빌드로 재기동했으며 데모 응답을 확인한다.
2026-08-02 | 사용자 안내 문장과 예시 리더보드에 남은 `샷` 외래어를 점검해 화면 문구를 `발사`·`시도`·`돌돌이`로 정리한다. 테스트 이름과 기술 문서의 용어는 변경하지 않는다.
2026-08-02 | 사용자 안내 문구와 예시 이름의 잔여 `샷` 표현을 `발사`·`시도`·`돌돌이`로 바꾼 후 `flutter analyze`·전체 테스트 100개·Web release가 통과했다. 기존 8080 서버(PID 52744)를 종료하고 최신 한글 안내 빌드로 재기동했다.
2026-08-02 | 다음 반복 기준선을 재검증했다. 작업 트리는 깨끗하고 전체 테스트 100개가 통과했으나 데모 서버는 내려가 있었고 `flutter analyze`는 코드 오류가 아닌 Flutter SDK 캐시 쓰기 권한으로 중단됐다. 사용자의 최신 원칙에 따라 특정 기믹을 정답 조건으로 강제하지 않고, 홀에 도달하는 모든 물리 경로를 성공으로 유지하는 범위에서 에이전트 독립 재평가를 시작한다.
2026-08-02 | 에이전트 교차 점검 결과 물리 판정은 다중 경로를 허용하지만 첫 화면의 자동 발사 제스처 발견성과 3단계 대체 경로의 이벤트 증거가 약하다는 공통 위험을 확인했다. 충돌 응답식은 회귀 위험으로 유지하고, 조작 안내 지속 노출·젤리 표시 비율 보정·단계별 서로 다른 성공 이벤트 회귀를 이번 구현 범위로 채택한다.
2026-08-02 | 조작 안내는 데스크톱 HUD에 손가락 아이콘과 0.45초 롱프레스 문구를 추가하고, 모바일 보드 우선 높이를 보존하기 위해 compact HUD에는 별도 줄을 쌓지 않았다. 젤리 스프라이트 폭을 물리 크기 비율에 맞췄으며, 3단계에서 스위치·점착을 거치지 않고 홀에 도달하는 탐색 회귀를 추가했다. 전체 테스트는 101개로 통과했다.
2026-08-02 | 최신 Web release를 기존 8080 프로세스(PID 54947) 종료 후 교체했다. Playwright로 390x844·1280x900을 캡처해 모바일 보드 폭·한글 HUD·조준 UI 겹침 없음과 데스크톱 조준 안내 표시를 확인했다. 루트·`main.dart.js`·젤리 자산은 HTTP 200이다.
2026-08-02 | 재감사에서 모바일 첫 단계 메시지가 추천 경로는 설명하지만 자동 발사 제스처를 명시하지 않는 UX 공백을 확인했다. 보드 높이를 줄이지 않고 첫 단계 안내 문장에 공을 길게 눌렀다 손을 떼는 발사 행동을 직접 추가한다.
2026-08-02 | 첫 단계 안내 문구 보강 후 정적 분석에서 사용하지 않는 compact 매개변수 경고를 확인했다. 안내 위젯을 실제 사용 범위인 데스크톱 HUD 전용으로 단순화해 경고 없는 기준을 유지한다.
2026-08-02 | 320px 모바일 재평가에서 첫 단계 긴 안내가 두 줄을 넘을 수 있음을 확인했다. 속성 선택·이전·롱프레스 발사 순서는 보존하되 문장을 한 줄 더 짧게 줄여 보드 우선 레이아웃을 안정화한다.
2026-08-02 | 짧아진 첫 단계 안내를 반영한 Web release를 기존 8080 프로세스 종료 후 재기동했다. Playwright 320x568 캡처에서 안내가 정확히 두 줄 안에 표시되고 보드·하단 조작 영역이 잘리지 않음을 확인했다.
2026-08-02 | 반복 가능한 데모 검증 공백을 확인했다. 현재 서버 교체는 수동 명령에 의존하므로, 8080 포트의 기존 HTTP 서버 명령을 확인해 종료하고 Web release 빌드·새 서버 기동·루트와 번들 HTTP 200을 검증하는 스크립트를 추가한다. 다른 종류의 포트 점유 프로세스는 종료하지 않는다.
2026-08-02 | 데모 교체 스크립트의 첫 실행은 빌드·HTTP 검증에는 성공했지만 실행 환경의 명령 종료 시 백그라운드 서버가 정리되는 것을 확인했다. 서버를 포그라운드로 유지하고 종료 시 자식 프로세스를 정리하도록 스크립트 실행 생명주기를 보강한다.
2026-08-02 | 포그라운드 생명주기 보강 후 `./scripts/run_web_demo.sh`를 실제 실행했다. 기존 서버를 종료하고 Web release를 다시 빌드한 뒤 루트·`main.dart.js` HTTP 200을 확인했으며, 스크립트가 PID 77684 서버를 유지하는 동안 별도 curl에서도 두 응답이 200으로 재현됐다.
2026-08-02 | 3단계 우회 풀이 회귀가 첫 성공 하나만 확인하는 한계를 재감사했다. 속성·스위치·점착 이벤트가 없는 성공을 서로 다른 조준 방향 구간에서 최소 두 개 이상 확인하도록 테스트 계약을 강화한다.
2026-08-02 | 강화 탐색 결과 기믹 없는 우회 성공은 한 조준 방향 구간에 집중되고, 실제 다중 해법은 무거운 공의 스위치·문 경로와 기믹 없는 홀 경로로 분리됨을 확인했다. 레벨을 억지로 넓히지 않기 위해 방향 두 개 조건은 철회하고, 두 해법 계열을 검증하는 기존 테스트 계약을 유지한다.
2026-08-02 | 우회 방향 폭 조건을 철회한 뒤 테스트 파일의 의미 없는 포맷 차이도 기준선으로 되돌린다. 이번 반복은 새 물리·레벨 변경 없이 탐색 결과와 QA 문서만 남긴다.
2026-08-02 | 성능 감사에서 순수 Dart 물리 실행 비용을 재현할 수 있는 명령이 없음을 확인했다. 렌더링 프레임 성능과 혼동하지 않도록 레벨별 `ShotResolver` 반복 실행 벤치마크를 추가하고 실제 측정값을 문서화한다.
2026-08-02 | 성능 벤치마크 실행값을 확인했다. 1단계 309.5µs, 2단계 193.2µs, 3단계 292.5µs이며 앱 테스트 101개는 통과했다. 벤치마크 도구의 `avoid_print` 정보 경고는 표준 출력 API로 정리한다.
2026-08-02 | 표준 출력 API로 정리한 벤치마크를 재실행해 1단계 312.6µs, 2단계 215.2µs, 3단계 280.3µs를 측정했다. 확인값은 이전 실행과 같아 입력·판정 결과의 결정론을 확인한다.
# 2026-08-02 복사권 모델 A 구현 시작

- 사용자 선택에 따라 스테이지별 제한 복사권 모델을 구현한다.
- 1·2단계는 1회, 3단계는 2회로 설정하고, 성공 조건은 변경하지 않는다.
- 복사 성공 시 잔여 횟수를 차감하고, 되감기·스테이지 초기화에서는 초기 수량으로 복원한다.
- UI에는 한글 잔여 횟수를 표시하고, 소진 시 복사 버튼을 비활성화한다.

# 2026-08-02 복사권 회귀 테스트 추가

- 복사 성공·소진·실패 선택의 상태 변화를 검증한다.
- 실제 발사 뒤 되감기에서 스테이지 초기 복사권이 복원되는지 검증한다.
- 스테이지별 수량과 팝업의 한글 잔여 횟수 표시를 위젯 회귀로 고정한다.

# 2026-08-02 분석 경고 정리

- 복사권 잔여 횟수 UI의 불필요한 문자열 보간 중괄호를 제거한다.

# 2026-08-02 복사권 검증 완료

- `flutter analyze`에서 문제 없음.
- 전체 Flutter 테스트 105개 통과.
- 복사 성공·소진·실패 선택·되감기 복원·스테이지별 1/1/2회·위젯 잔여 표시를 검증했다.

# 2026-08-02 목표 완료 조건 재감사 시작

- 목표 파일과 `harness_docs/readme.md`, 규칙·협업 문서를 다시 대조했다.
- 현재 브랜치 `commercial/wall-physics-qa`, 작업 트리는 깨끗하다.
- 복사권 구현은 완료됐지만, 대표 스테이지 상용화 품질의 최신 독립 재평가와 목표 문서가 요구한 일부 산출물 파일이 부족하다.
- 기존 8080 데모 프로세스와 Web 빌드 상태를 다시 확인하고, 세 역할의 독립 재평가 결과와 교차 검토를 수집한다.
- 이번 반복의 핵심 가설은 기능 추가보다 `첫 화면의 일관성`, `첫 3단계의 오차 허용`, `충돌 원인 가독성`을 증거 기반으로 보강해야 상용 수직 슬라이스 완료 조건에 가까워진다는 것이다.

# 2026-08-02 축약 화면 온보딩 보강

- 독립 UX 진단에서 320px 축약 HUD에 발사 순서가 빠진 P0 문제가 확인됐다.
- 축약 HUD에 `1 방향 조정 · 2 공을 길게 누르기 · 3 손 떼기`를 추가했다.
- 넓은 화면 안내 문구도 `손가락을 움직여`로 정리해 입력 동작과 일치시켰다.
- 320px 위젯 회귀에서 축약 조작 안내의 존재와 예외 없음을 확인할 예정이다.

# 2026-08-02 Subagent 독립 재평가 수렴

- 아트·캐주얼 UX: 축약 HUD 조작 순서 누락, Canvas와 래스터 에셋의 스타일 혼재, 보드의 단계별 개성 부족을 P0/P1로 보고했다.
- 퍼즐·전문 플레이어: 물리 다중 풀이는 유지되지만 실패 원인과 다음 실험 안내, 반복 플레이 보상이 약하다고 보고했다.
- 물리·VFX·QA·성능: 결정론·연쇄·애니메이션 이벤트는 조건부 통과했으나 실기기 GPU 비용, 프레임 측정, 실제 사용자 이해도는 미검증으로 남겼다.
- 교차 검토의 공통 결론은 첫 입력 안내와 실패 피드백을 우선하고, 물리 판정과 대체 풀이를 변경하지 않는 것이다.

# 2026-08-02 산출물 누락 보강

- 목표 파일의 필수 문서 목록과 실제 파일을 대조해 공유 컨텍스트, 난이도·보상·오브젝트·온보딩·피드백·기기 매트릭스·전후 비교·다음 반복 문서를 추가한다.
- 문서에는 자동 검증과 전문가 프록시 평가를 실제 사용자·실기기 검증과 구분해 기록한다.

# 2026-08-02 축약 안내 테스트 기대값 정리

- 별도 행을 제거해 320px 보드 폭을 복원했다.
- 기존 위젯 테스트가 삭제한 긴 초기 문구를 기대하고 있어 새 `방향 조정` 안내 문장으로 기대값을 맞춘다.

# 2026-08-02 전체 포맷 기준선 정리

- `dart format .`을 실행해 기존 퍼즐 감사 테스트 한 파일의 포맷 차이를 정리한다.
- 동작 변경 없이 전체 저장소 포맷 기준을 통과시키고, 포맷 전용 커밋으로 분리한다.

# 2026-08-02 최신 검증 증거

- `dart format .`: 19개 파일 검사, 포맷 완료.
- `flutter analyze`: 문제 없음.
- `flutter test`: 105개 통과.
- `dart run tool/physics_benchmark.dart`: 1단계 330.8µs, 2단계 209.8µs, 3단계 286.7µs.
- 기존 서버 PID 43498을 종료하고 최신 Web release를 빌드해 PID 62251로 교체했다.
- 승인된 환경에서 루트와 `main.dart.js`가 모두 HTTP 200을 반환했다.
- 축약 화면 안내는 별도 행을 추가하지 않고 초기 상태 메시지로 통합해 320px 보드 최소 폭을 유지했다.

# 2026-08-02 최종 AI 활용 기록

- 오케스트레이터는 목표 파일·README·하네스 규칙을 기준으로 범위와 완료 조건을 대조했다.
- 아트·UX, 퍼즐·전문 플레이어, 물리·VFX·QA·성능 역할을 독립적으로 재평가하고 `cross_review.md`에서 충돌 의견을 통합했다.
- 프롬프트의 핵심 요약은 상용 품질 수직 슬라이스, 한글 UI, 결정론적 물리, 다중 풀이, 단계별 복사권, 실제 사용자·실기기 검증 분리다.
- AI 결과는 코드·테스트·HTTP·benchmark로 검증했으며 실제 사용자 반응이나 실기기 성능을 생성하지 않았다.

# 2026-08-02 역할 산출물 이름 완결

- 목표 문서의 역할별 필수 파일 목록과 실제 경로를 다시 대조했다.
- 오디오·햅틱, QA, 제품 평가, 전문 플레이어 감사 파일이 없어 기존 결과를 역할별 최신 문서로 분리해 추가한다.

# 2026-08-02 물리 감사 파일명 보완

- 목표 문서가 요구하는 `physics_audit.md`가 `physics_review.md`와 별개로 필요함을 확인했다.
- 최신 결정론·벽·홀·연쇄·성능 판정을 명시적 물리 감사 파일로 추가한다.

# 2026-08-02 새 상용 품질 목표 기준선과 모바일 셸 착수

- 새 목표 파일은 기존 수직 프로토타입을 모바일 게임 셸·해변 실험 섬 아트·도전 구조·조건부 복제 코어·결과 화면까지 재구축하도록 요구한다.
- 현재 실제 앱 진입은 곧바로 개발용 GameScreen이며, 단계 선택 폼과 어두운 AppBar가 플레이 화면에 남아 있다.
- 이번 반복의 핵심 가설은 시작·스테이지 선택·플레이 흐름을 먼저 모바일 게임처럼 연결하고, 실제 플레이 화면에서 게임 보드 점유율을 키우면 첫인상과 규칙 이해가 함께 개선된다는 것이다.
- 기존 순수 Dart 물리와 105개 테스트는 보존하고, 실제 앱 진입용 셸과 스테이지 선택만 별도 UI 계층으로 추가한다.

# 2026-08-02 성능·서버 문서 최신화

- 과거 benchmark·서버 PID 기록은 역사적 기준으로 유지하고 최신 재실행 결과를 별도 섹션에 추가했다.
- 최종 축약 안내 구현이 별도 행이 아니라 초기 상태 메시지 통합 방식임을 QA 문서에 명시했다.
# 2026-08-02 실제 플레이 모드의 단계 칩 노출 조건 정리

- 대상: `lib/ui/game_screen.dart`
- 문제: 새 모바일 라우터의 실제 플레이 모드가 넓은 화면 분기에서 기존 단계 선택 칩을 계속 노출함.
- 가설: 게임 월드와 조작 HUD만 남기고 개발용 단계 선택은 지도 화면으로 이동해야 모바일 게임 셸 요구를 만족함.
- 예정 변경: `showStageSelector`가 켜진 호환용 화면에서만 단계 칩을 렌더링하고 실제 플레이 모드에서는 숨김.
- 검증: `dart format`, `flutter analyze`, 홈·지도·플레이 전환 위젯 테스트.
# 2026-08-02 모바일 라우터 전환 위젯 검증 추가

- 대상: `test/widget_test.dart`
- 목적: 홈 화면, 섬 지도, 실제 플레이 모드가 연결되고 플레이 모드에서 개발용 단계 칩이 사라지는지 검증.
- 가설: 시작 화면에서 첫 스테이지를 선택한 뒤 `aim_area`와 지도 이동 버튼만 제공하면 제품 흐름과 기존 호환 화면을 분리할 수 있음.
- 검증: 홈·지도 진입, 스테이지 시작, `level_1` 미노출, 홈 복귀.
# 2026-08-02 실제 제품 경로의 파 샷·메달·복제 코어 기준 정리

- 대상: `lib/game/domain/level_definition.dart`, `lib/game/levels/levels.dart`, `lib/main.dart`, `lib/ui/game_screen.dart`
- 문제: 결과 팝업이 시도 수와 예시 기록만 보여 재도전 동기가 약하고, 새 제품 경로도 기존 스테이지 시작 복사권을 그대로 사용함.
- 결정: 스테이지에 파 샷과 선택형 추가 도전을 정의하고, 결과에 3단계 별점·재도전·다음 이동을 제공함. 기존 105개 도메인 테스트를 보존하기 위해 호환용 `createState`는 유지하고 실제 홈 라우터는 복사 코어 0개 상태 생성 경로를 사용함.
- 복제 코어 규칙: 첫 챕터 기본 3단계는 복사 없이 클리어 가능하며 제품 경로에서는 코어를 자동 지급하지 않음. 이후 보상 연결을 위한 재고 필드는 유지하되 상시 버튼은 노출하지 않음.
- 검증: 결과 위젯 테스트, 전체 테스트, 정적 분석.
# 2026-08-02 복제 코어 비보유 상태와 결과 별점 테스트 보강

- 대상: `test/widget_test.dart`
- 검증 목표: 실제 제품 경로에서는 속성 물체 팝업에 복사 버튼이 노출되지 않고, 클리어 결과에는 파 샷·별·기록 재도전 버튼이 표시됨.
- 기준: 기존 호환용 직접 게임 경로의 복사 테스트와 결과 팝업 테스트는 그대로 유지.
# 2026-08-02 결과 팝업 소형 화면 회귀 수정

- 발견: 별·파 샷·추가 도전·재도전 정보를 추가한 뒤 `320×568` 화면에서 결과 팝업 하단 버튼이 뷰포트 밖으로 밀림.
- 영향: 재도전 버튼 탭 불가, 기존 Safe Area 위젯 테스트 실패.
- 예정 수정: 결과 카드를 화면 높이 안에 제한하고 카드 내부만 스크롤하도록 구조 변경.
- 검증: 소형 화면 팝업 경계, 재도전 버튼 탭, 전체 위젯 테스트.
# 2026-08-02 결과 카드 최대 높이 강제

- 관찰: `ConstrainedBox`의 최대 높이만으로는 테스트 렌더 트리에서 내부 스크롤 영역이 원하는 높이로 제한되지 않음.
- 수정 방향: 결과 카드에 뷰포트 기준 고정 높이를 부여하고, 내용은 `SingleChildScrollView` 안에서 스크롤.
- 완료 조건: 재도전 버튼이 작은 화면과 기본 테스트 화면 모두 히트테스트 가능하고 팝업 경계가 화면 안에 있음.
# 2026-08-02 결과 팝업 래퍼 닫힘 보정

- 포인터: 고정 높이 래퍼를 삽입한 뒤 `FocusScope`/`Semantics` 닫힘 수가 부족해 Dart 파서가 `Expected to find ')'`를 보고함.
- 수정: 결과 팝업의 중첩 위젯 닫힘을 보정한 뒤 포맷·테스트를 재실행.
# 2026-08-02 결과 팝업 수정 중 기존 게임 화면 닫힘 보정

- 자동 패치가 `_GameScreenState.build`의 마지막 닫힘에도 적용되어 잘못된 괄호가 삽입됨.
- 수정 대상은 해당 함수의 원래 `Scaffold` 반환 구조이며, 팝업 래퍼의 닫힘은 별도로 유지함.
# 2026-08-02 클리어 팝업 Semantics 닫힘 보정 재시도

- 파서 진단상 카드 내부 위젯은 닫혔지만 `Semantics`와 `FocusScope` 중첩이 한 단계 남아 있음.
- 정확한 `_ClearPopup` 종료 지점만 수정하고 다시 포맷·테스트한다.
# 2026-08-02 결과 카드 정보·행동 영역 분리

- 관찰: 카드 높이는 제한됐지만 스크롤 자식 내부의 버튼은 콘텐츠 좌표를 유지해 `getRect`와 실제 히트테스트가 뷰포트 밖을 가리킴.
- 설계: 결과 정보만 `Expanded` 스크롤 영역에 넣고, 다음·재도전 버튼은 카드 하단 고정 영역으로 분리.
- 검증: `320×568`, 기본 테스트 화면, Safe Area에서 버튼 경계와 탭 동작 확인.
# 2026-08-02 클리어 팝업 전체 구조 재작성

- 사유: 부분 패치로 `SingleChildScrollView`·`Expanded`·결과 카드의 닫힘 구조가 복잡해져 파서 오류가 반복됨.
- 방침: `_ClearPopup`을 전체 교체해 카드 높이, 정보 스크롤, 하단 고정 행동 영역을 한 구조로 명시.
- 검증: Dart 포맷, 위젯 테스트, 소형 화면 경계와 재도전 히트테스트.
# 2026-08-02 결과 팝업 내부 여분 닫힘 제거

- 원인: 리더보드 컨테이너와 정보 컬럼을 닫는 과정에서 여분의 `)` 하나가 남아 inner children 목록을 닫기 전에 삽입됨.
- 수정: 해당 여분 닫힘만 제거하고 포맷으로 전체 구조를 확인.
# 2026-08-02 결과 팝업 최종 래퍼 닫힘 정리

- 파서 위치: `_ClearPopup.build` 종료부에 `FocusScope`를 닫는 여분의 `)`가 남음.
- 수정: 마지막 `);`가 `FocusScope`를 닫도록 한 단계만 제거.
# 2026-08-02 결과 팝업 FocusScope 최종 닫힘 제거

- 현재 종료부는 outer Container와 Semantics까지 닫은 뒤 `FocusScope`를 여는 별도 닫힘을 한 번 더 가지고 있음.
- 마지막 `);`가 FocusScope를 닫도록 그 여분 한 줄을 제거.
# 2026-08-02 게임 화면 Scaffold 닫힘 복원

- 자동 패치가 `_GameScreenState.build`의 유사한 종료 패턴을 잘못 선택해 Scaffold 닫힘 하나를 삭제함.
- `_ClearPopup`와 무관한 게임 화면 반환부의 원래 닫힘을 복원한 뒤, 팝업 종료부는 줄 번호 기준으로 별도 확인.
# 2026-08-02 독립 Subagent 진단과 해변 실험 섬 스타일 기준 문서화

- 독립 진단 결과: 모바일 라우팅은 개선됐지만 실제 플레이 보드와 홈 테마가 분리되어 있고, 결과 팝업 회귀는 방금 해결됨. 복제 코어·다중 샷 솔버·실제 전용 오디오·실기기 성능/iOS 검증은 미완료.
- 역할별 산출물: 아트·UX·제품, 퍼즐·솔버·진행, 물리·VFX·성능·iOS·QA 진단을 별도 기록.
- 디자인 결정: 세 콘셉트를 비교 문서로 남기고, 사용자 선호와 평가를 반영해 `B. 해변 실험 섬`을 기본 구현 방향으로 채택.
- 예정 문서: `visual_style_bible.md`, `art_concept_options.md`, 독립 진단 보고서, 스크린샷 검증 매트릭스.
# 2026-08-02 해변 실험 섬 보드 아트 수직 슬라이스

- 대상: `lib/game/property_shot_game.dart`
- 문제: 홈은 해변인데 플레이 보드는 민트색 잔디·타일 그리드와 회색 산업 레일로 보여 세계가 분리됨.
- 변경 방향: 플레이 바닥을 모래섬으로, 프레임과 벽을 청록 장난감 섬 테두리로, 격자 대신 얕은 물결·모래 결로 통일. 충돌 좌표와 물리 판정은 변경하지 않음.
- 완료 조건: 공·홀·상자·돌은 유지하면서 보드가 B 콘셉트로 읽히고, 기존 물리·위젯 테스트가 그대로 통과.
# 2026-08-02 조건부 복제 코어 모델 구현 착수

- 문제: 실제 제품 경로가 복사 횟수 0으로 숨기는 것에 그치고, 복제 코어의 보유·획득·사용·재진입 상태가 없음.
- 결정: `GameState.copyCoreCount`를 메타 보유량으로 추가하고, 제품 경로의 단계 생성은 보유 코어를 현재 복사 가능 횟수로 투입. 1~3단계는 코어 없이 시작하며 3단계 클리어 보상으로 1개만 지급.
- 호환: 기존 직접 `PropertyShotApp()` 경로와 도메인 테스트는 기존 `copyCharges` 계약을 유지. 실제 홈 라우터만 `productRules`를 사용.
- 검증 예정: 코어 없는 UI, 보상 1회 지급, 사용 후 감소, 단계 재진입·되감기·초기화.
# 2026-08-02 복제 코어 보상 상태 지속 연결

- 추가 상태: `copyCoreRewarded`로 3단계 보상을 한 번만 지급하고, 스테이지 이동·재시도에서도 보유량과 보상 여부를 유지.
- 게임 화면은 보상 시 현재 상태에 코어를 반영하고 라우터에 로컬 저장을 알림.
# 2026-08-02 섬 지도 라우터의 복제 코어 재고 연결

- 대상: `lib/main.dart`
- 제품 라우터가 복제 코어 보유량과 3단계 보상 여부를 로컬 `SharedPreferences`에 저장하고, 새 플레이 상태에 주입하도록 연결.
- 로그인·서버·현금 결제는 추가하지 않음.
# 2026-08-02 복제 코어 로컬 저장 보조 import와 키 추가

- 라우터의 비동기 로컬 저장에 `unawaited`를 사용하므로 `dart:async`와 저장 키를 추가.
- 저장 키는 개인 식별 정보 없이 복제 코어 수량과 보상 수령 여부만 기록.
# 2026-08-02 복제 코어 사용 메시지와 팝업 표기 구분

- 제품 경로에서 코어를 사용할 때 기존 `복사 n회` 문구가 남지 않도록 상태·메시지·버튼 표기를 분리.
- 기존 호환 테스트는 코어 보유량 0의 `복사` 문구를 그대로 유지.
# 2026-08-02 복제 코어 도메인·UI 계약 테스트 추가

- 검증: 제품 규칙의 첫 상태는 코어 0개, 코어 보유 상태에서 복사는 원본을 유지하고 코어·복사 횟수를 감소, UI는 `복제 코어` 문구를 사용.
- 기존 테스트의 스테이지별 레거시 복사권 계약은 삭제하지 않음.
# 2026-08-02 복제 코어 보유 팝업 테스트 추가

- 제품 상태에 복제 코어 1개를 주입했을 때 속성 팝업이 `복제 코어로 공에 담기`와 보유량을 보여주는지 확인.
# 2026-08-02 자동 난이도 분석기 구현

- 목표: 파 샷과 첫 3단계 난이도를 개발자 직감이 아닌 결정론적 입력 격자로 계측.
- 입력: 무속성 상태와 각 속성 물체를 공으로 이전한 상태, 각도 10도 간격, 힘 0.05 간격.
- 출력: 전체 입력 수, 성공 수·성공률, 연결된 성공 영역, 최대 각도·힘 허용 범위, 최소 샷, 복사 없는 성공 여부.
- 물리 판정은 기존 `ShotResolver`를 그대로 사용하며 분석기는 상태를 변경하지 않음.
# 2026-08-02 난이도 분석기 경고와 복사 없는 판정 보정

- 분석기 정적 분석에서 불필요한 nullable 단언 경고를 확인.
- `복사 없는 성공`은 무속성 전략이 성공한 경우에만 참이어야 하므로 속성 전략 성공을 오인하지 않게 보정.
# 2026-08-02 난이도 분석기 회귀 테스트 추가

- 세 단계 모두 자동 입력 탐색에서 성공 영역과 최소 샷이 기록되는지 검증.
- 무속성 성공군이 있는 현재 설계와 단계별 파·성공률 문서화를 연결.
# 2026-08-02 복사 없는 성공 지표 의미 보정

- 자동 분석 입력은 무속성과 속성 이전만 포함하고 복제 코어 복사는 포함하지 않음.
- 따라서 성공한 모든 전략은 `복사 없는 성공`이며, 무속성 성공만 의미하는 지표가 아님을 코드·테스트에 반영.
# 2026-08-02 난이도 지표 리포트 실행기 추가

- `tool/difficulty_report.dart`가 동일한 순수 Dart 분석기를 실행해 단계별 Markdown 지표를 출력하도록 추가.
- 출력 결과를 `harness_docs/qa/level_difficulty_metrics.md`에 기록하고 파 상수와 비교.
# 2026-08-02 3단계 성공 영역 확대 시도

- 자동 분석 결과: 3단계 연속 각도 10도·성공률 0.79%로 정밀 조준 의존성이 높음.
- 조정: 물리 규칙과 기믹 조건은 유지하고 목표 홀의 시각·포획 크기를 34에서 42 논리 단위로 확대.
- 검증: 3단계 직접·대체 경로의 성공률과 연결 영역을 같은 분석기로 재실행하고 기존 충돌·홀 테스트를 통과.
# 2026-08-02 3단계 홀 여유 추가 측정

- 42 단위 홀은 성공 입력을 17→18개로만 늘려 연결 각도 10도를 유지함.
- 같은 물리 규칙에서 목표 포획 여유를 50 단위로 한 번 더 측정해, 시각적 크기와 초반 공정성의 균형을 확인.
# 2026-08-02 단계별 홀 크기 패치 대상 보정

- 확인: 범위 없는 패치가 1단계 홀을 50으로 바꾸고 3단계는 42로 남김.
- 수정: 1단계 홀은 원래 42로 복원하고 3단계 홀만 50으로 설정.
# 2026-08-02 3단계 문 통과 영역 확대

- 3단계 홀 50 단위는 성공률을 0.79%→0.97%로 올렸지만 연속 각도는 10도에 머묾.
- 조정: 추천 경로의 닫힌 문 충돌면 폭을 28→44로 넓혀 스위치 이후 열린 문을 통과하는 각도 허용 범위를 확대.
- 문은 고정 장애물이며 물리 규칙은 변경하지 않음. 기존 우회 경로와 문 이벤트 회귀를 확인.
# 2026-08-02 3단계 스위치 조준 허용 폭 확대

- 문 폭 조정은 성공 영역을 바꾸지 않아 첫 충돌 대상인 스위치가 병목임을 확인.
- 조정: 스위치 판정 폭을 70→100으로 넓혀 무거운 공이 여러 각도에서 눌러도 연쇄가 시작되게 함.
- 목적: 기믹을 강제하지 않으면서 추천 연쇄 풀이의 조작 허용 범위를 넓힘.
# 2026-08-02 3단계 조정 후 난이도 결과 기록

- 홀 50 단위와 문 44 단위·스위치 100 단위 조정 후: 성공 21/2160, 성공률 0.97%, 최대 연속 각도 10도, 최대 연결 14셀.
- 병목은 여전히 추천 연쇄의 전체 경로이며, 수치는 완료 판정이 아니라 다음 레벨 조정의 기준으로 기록.
# 2026-08-02 섬 지도 상용 UI 반복 시작

- 실제 모바일 캡처에서 섬 지도 화면이 평면적인 목록으로 보이는 문제를 확인했다.
- 플레이 기능과 물리 규칙은 건드리지 않고, 지도 배경·스테이지 썸네일 프레임·파 샷 정보·접근성 의미를 같은 해변 실험 섬 아트 방향으로 묶는다.
- 변경 후 홈·지도·플레이 캡처와 위젯 회귀를 다시 확인한다.
# 2026-08-02 난이도 리포트 분석 경고 정리

- `flutter analyze`에서 콘솔 리포트 전용 도구의 `print` 호출 11건이 정보로 보고되는 것을 확인했다.
- 실행 결과를 표준 출력으로 제공하는 도구의 의도를 파일 수준 주석으로 명시하고, 제품 코드의 분석 경고와 구분한다.
# 2026-08-02 사후 QA 물리·난이도 보완 시작

- 독립 QA에서 연쇄 물체가 벽에 맞을 때 직접 발사와 다른 `wallScale` 임의 감쇠를 쓰는 위험을 확인했다.
- 고정 벽은 무한 질량의 장애물로 취급하고 직접 발사와 같은 반사·재질 반발식을 공유하도록 보완한다.
- 난이도 분석기의 원형 각도 연결 영역이 36칸으로 고정된 문제를 설정 가능한 각도 간격에 맞게 일반화하고, 3단계 대체 풀이를 더 촘촘한 격자로 검증한다.
# 2026-08-02 3단계 고해상도 대체 풀이 확인

- 2도·2% 격자의 3단계 분석에서 `무속성`과 `steel (무거움)` 전략이 모두 최종 성공으로 집계됨을 확인했다.
- 기존 10도·5% 요약 격자는 좁은 우회 성공 영역을 대표 지표에서 누락할 수 있으므로, 기본 리포트에 고해상도 3단계 보조 지표를 함께 출력한다.
# 2026-08-02 난이도 산출물 고해상도 근거 추가

- 난이도 문서에 기본 격자와 3단계 2도·2% 보조 분석을 구분해 기록한다.
- 기본 지표의 낮은 전략 수를 전체 해법 부재로 해석하지 않도록, 자동 리포트 출력과 품질 게이트 문구를 함께 정리한다.
# 2026-08-02 백그라운드 복귀 애니메이션 보정

- 큰 `dt`가 들어오면 애니메이션 커서가 남은 전체 구간을 한 번에 소비해 충돌 VFX·햅틱이 동시에 재생될 수 있음을 확인했다.
- 앱 복귀 프레임은 물리 이벤트를 생략하지 않도록 일시 정지하고, 다음 정상 프레임부터 기존 시간축으로 재생한다.
# 2026-08-02 백그라운드 복귀 회귀 추가

- 애니메이션 테스트에 `dt=0.6` 복귀 간격을 추가해 큰 시간 간격에서 완료 콜백과 충돌 이벤트가 즉시 몰리지 않는지 확인한다.
# 2026-08-02 피드백 설정 UI 추가 시작

- 목표 문서의 사운드·햅틱 끄기 조건을 충족하기 위해 외부 서버 없이 로컬 실행 중인 피드백 설정을 추가한다.
- 홈 화면에서 소리와 진동을 각각 끌 수 있고, 게임의 물리 상태와 플랫폼 미지원 예외 처리는 변경하지 않는다.
# 2026-08-02 피드백 설정 회귀 추가

- 홈 설정 팝업에서 효과음·진동 토글이 실제 `GameFeedback` 전역 설정을 바꾸는지 위젯 테스트로 확인한다.
# 2026-08-02 섬 지도 진행 상태 연결 시작

- 제품 흐름에서 첫 클리어 뒤 다음 섬이 열리고 이후 섬은 잠기는 상태를 지도에 표시한다.
- 해금 단계는 로그인·서버 없이 `SharedPreferences`에 저장하며, 기존 위젯 테스트용 직접 플레이 모드의 단계 선택 호환성은 유지한다.
# 2026-08-02 점착 튜토리얼 약속 보정

- 사후 퍼즐 리뷰에서 점착 충돌은 고정 이벤트까지 검증됐지만 최종 홀 성공 경로로는 증명되지 않은 것을 확인했다.
- 점착을 추천 클리어 경로라고 단정하지 않고, 무거움·스위치·문 경로와 점착의 고정 역할을 구분해 안내한다.
# 2026-08-02 전략별 난이도 지표 확장 시작

- 고해상도 분석에서 전략 이름만 기록하면 좁은 우회 성공을 안정적인 풀이로 오해할 수 있다.
- 전략별 성공 입력 수·성공률·연속 각도·힘 범위·연결 영역·최소 샷을 `DifficultyMetrics`에 보존하고 리포트에 출력한다.
# 2026-08-02 전략별 지표 단위 변환 보정

- 전략별 힘 범위는 비율로 출력되지만 전체 요약은 기존 단계 수치와 동일해야 한다.
- 집계 카운트와 비율을 분리해 최대 힘 범위가 이중으로 나뉘지 않도록 회귀한다.
# 2026-08-02 고해상도 전략 수치 출력 보강

- 3단계 2도·2% 보조 분석도 전략 이름뿐 아니라 성공 입력·성공률·각도·힘·연결 영역을 출력하도록 확장한다.
# 2026-08-02 고해상도 전략 수치 기록

- 3단계 2도·2% 보조 분석 결과: 무속성 19/9000(0.21%), 각도 2도, 힘 36%, 연결 19셀; 무거움 351/9000(3.90%), 각도 12도, 힘 68%, 연결 186셀.
- 무속성 경로는 존재하지만 정밀도가 높아 현재 안정적인 추천 경로로 승격하지 않고 대체 도전 경로로 기록한다.
# 2026-08-02 고정 벽 반사 경로 통합

- 활성 공도 연쇄 물체와 같은 `_wallBounceVelocity`를 사용하도록 연결해 직접·연쇄 충돌의 입사 벡터와 반발 계수 계산을 단일 경로로 만든다.
- 결과 방향·속도는 기존 벽 반사 규칙을 유지하고, 고정 벽의 질량을 움직이는 물체에 전달하지 않는 불변식을 테스트한다.
2026-08-02 | shell | 모바일 플레이 보드의 좌우 내부 여백을 줄여 세로 화면 점유율을 높이고, 클리어 팝업을 콘텐츠 중심의 제한 높이·스크롤 구조와 짧은 등장 애니메이션으로 개선한다.
2026-08-02 | qa | 팝업 경계 회귀에서 `math.min` 결과의 num 타입을 발견해 고정 높이 계산을 명시적인 double로 정리한다.
2026-08-02 | qa | 콘텐츠 일괄 스크롤 구조에서 작은 뷰포트의 결과 버튼이 하단 밖으로 밀리는 회귀를 확인해, 정보 영역과 고정 버튼 영역을 다시 분리한다.
2026-08-02 | qa | 클리어 패널 자체의 높이와 버튼 경계를 직접 검증할 수 있도록 결과 패널 키와 모바일 위젯 회귀를 추가한다.
2026-08-02 | qa | 최신 Web release에서 390×844 실제 속성 이전·조준·발사·클리어 경로를 실행하고, 393·430·768·1024 폭 플레이 캡처와 390 홈·지도·결과 캡처를 갱신한다.
2026-08-02 | qa | 최신 화면·팝업 변경의 최종 회귀 수와 서버 PID·HTTP 응답·캡처 범위를 검증 문서에 추가한다. 이전 실행 수치는 역사적 기준선으로 보존한다.
2026-08-02 | art | 홈의 단독 공 이미지가 게임의 목표와 상호작용을 충분히 설명하지 못해, 공·돌·상자·홀을 함께 보여주는 자체 보드 미리보기로 교체한다. 실제 플레이 화면의 정답 궤적은 노출하지 않는다.
2026-08-02 | qa | Subagent 재검토에서 확인된 복제 코어 되감기 상태 불일치, 768px 축약 HUD 조작 안내 누락, 화면 계측 통합 검증 공백을 함께 보완한다.
2026-08-02 | qa | 축약 HUD에 별도 안내 행을 추가하면 320px 보드 폭이 줄어드는 회귀가 확인됐다. 별도 행은 제거하고 제품 라우터의 단계 시작 메시지에 기존 짧은 조작 순서를 연결한다.
2026-08-02 | puzzle | 다중 샷 분석기의 기본 각도·힘 격자를 리포트와 문서의 표준인 20도·20%로 맞춰 기본 생성자와 공식 난이도 보고서가 같은 기준을 사용하게 한다.
2026-08-02 | agents | 아트·QA·퍼즐 Subagent 최신 사후 평가를 비교했다. 홈 보드 미리보기·결과 패널·모바일 보드 점유율은 개선됐고, 코어 되감기·축약 라우터 안내·계측 주입·해상도별 실제 입력 검증을 다음 회귀에 반영한다.
2026-08-02 | qa | 최종 회귀에서 전체 124개 테스트·난이도 리포트·Web release를 통과했다. 기존 서버 PID 14419를 PID 26180으로 교체하고 루트·번들 HTTP 200 및 390×844 실제 클리어 콘솔 오류 0건을 확인했다. iOS Xcode 컴파일은 완료됐으나 Development Team·프로비저닝 프로파일 부족으로 배포 단계가 실패했다.
2026-08-02 | qa | 위젯 테스트 선언 수를 다시 세어 최신 `test/widget_test.dart` 기준 41개임을 확인하고 검증 문서의 40개 표기를 41개로 정정한다.
2026-08-02 | qa | Wasm 실행 캡처에서 한글 글리프가 네모로 표시되는 문제를 확인하고, 플랫폼 한글 글꼴 우선순위를 테마에 지정하는 검증을 시작한다.
2026-08-02 | qa | 실제 모바일 입력으로 첫 단계 클리어 팝업은 표시되지만 애니메이션 종료 프레임에 경로 마지막 점의 다음 인덱스를 읽는 웹 IndexError를 발견했다. 종료 렌더 경계 회귀를 추가한다.
2026-08-02 | qa | 경계 회귀의 직접 렌더 테스트가 Flame 레이아웃 미설정으로 실패했다. 테스트 호스트에 게임 캔버스 크기를 명시해 실제 마지막 프레임 렌더를 계속 검증한다.
2026-08-02 | puzzle | 기존 난이도 분석이 단일 발사만 탐색하는 한계를 보완하기 위해 이전 공 상태를 보존하는 2회 다중 샷 탐색기와 조건부 복사 전략 지표를 추가한다.
2026-08-02 | puzzle | 다중 샷 분석기에서 무속성·속성 이전·조건부 복제 전략을 같은 입력 격자로 비교하고, 성공한 발사 순서와 최소 샷을 결과 객체로 보존하도록 테스트 계약을 추가한다.
2026-08-02 | qa | 난이도 리포트 도구에 2회 발사·이전 공 상태·조건부 복제 전략 결과를 연결해 단일 샷 지표와 다중 샷 지표를 구분해 출력한다.
2026-08-02 | puzzle | 다중 샷 지표의 복사 없는 성공 판정을 속성 이전까지 포함하도록 보정했다. 복제 전략만 제외해야 제품의 이전·복사 구분과 일치한다.
2026-08-02 | qa | 최신 Wasm 빌드에서 390×844 홈·섬 지도·플레이·클리어 팝업을 실제 입력으로 캡처했고 브라우저 콘솔 오류 0건을 확인했다. 393·430·768·1024 폭 홈 반응형 캡처도 정상 렌더링으로 확인했다.
2026-08-02 | puzzle | 전체 회귀에서 1단계 고해상도 성공 영역이 12도로 품질 게이트 16도에 못 미치는 것을 확인했다. 첫 튜토리얼 홀을 52 단위로 넓혀 조준 허용 오차를 늘리고, 3단계 분석의 현재 결정론적 범위 기대값을 안정화한다.
2026-08-02 | puzzle | 1단계 홀 여유 조정 후 1단계 폭은 회복됐지만 2단계 반사 성공 영역이 12도로 남았다. 2단계도 첫 반사를 학습하는 단계이므로 홀 여유를 같은 기준으로 조정한다.
2026-08-02 | qa | 홀 여유 조정 후 기본 난이도 수치를 재산출했다. 1단계 6.11%, 2단계 5.76%, 3단계 2.73% 성공률이며, 목표 25도 폭 판정을 위해 1·2단계 고해상도 폭을 리포트에 추가한다.
2026-08-02 | qa | 고해상도 보조 분석에서 1단계 연속 조준 폭 28도·힘 86%, 2단계 폭 20도·힘 76%를 확인했다. 1단계 25도 품질 게이트는 통과하고 2단계는 반사 이해 중심의 별도 기준으로 기록한다.
2026-08-02 | qa | 1·2단계 홀 조정 후 다중 샷 최신 수치를 문서와 대조한다: 1단계 22,950개 중 234개, 2단계 22,680개 중 775개, 3단계 39,510개 중 135개 성공.
2026-08-02 | qa | 최신 최종 회귀는 119개 전부 통과했다. 최신 웹 서버 PID 50866, 루트·main.dart.js HTTP 200, 390×844 실제 입력 캡처와 콘솔 오류 0건을 최신 검증 섹션에 기록한다. iOS는 Development Team·프로비저닝 프로파일 부족으로 배포 단계만 실패했다.
2026-08-02 | agents | 최신 아트·물리·퍼즐 Subagent 사후 재평가를 수집했다. 한글·실행 캡처 P0는 해소됐고, 점착 최종 성공 시퀀스·실기기 성능·재질 스타일 통일은 남은 위험으로 기록한다.
2026-08-02 | puzzle | 점착 최종 성공이 아직 증명되지 않은 상태를 테스트 이름에도 반영해, 점착을 최종 풀이로 오해하지 않고 고정 역할과 직접 스위치 성공을 분리한다.
2026-08-02 | art | 시스템 글꼴 의존성을 줄이기 위해 Google Fonts의 OFL Nanum Gothic 정규·굵은·ExtraBold 자산과 라이선스를 번들하고 Flutter 테마 우선 글꼴로 연결한다.
2026-08-02 | qa | Nanum Gothic 번들 후 일반 Web release에서 홈·지도·플레이·결과 캡처를 갱신했다. Flame 자산 로딩 완료를 픽셀 감지한 뒤 결과 팝업을 저장했고 결과 중앙 픽셀은 (255,253,246), 콘솔 오류는 0건이었다.
2026-08-02 | puzzle | Subagent 재감사에서 다중 샷 분석기의 후속 발사 속성 재선택 누락을 확인했다. 각 상태에서 남은 속성 이전·조건부 복제를 선택하는 행동 분기를 추가해 점착 후 무거움 순서를 실제로 탐색한다.
2026-08-02 | puzzle | 다중 샷 대표 행동 순서에서 첫 발사 전략명이 중복될 수 있는 기록 결함을 확인했다. 첫 발사는 초기 전략을 한 번만 기록하고, 후속 발사부터 유지·이전·복제 행동을 이어 붙이도록 보정한다.
2026-08-02 | qa | 확장 다중 샷 탐색에서 3단계 점착 후 무거움 재선택 2회 성공 경로를 확인했다. 보고서 대표 순서를 샷 횟수 대신 한글 행동명으로 표시해 실제 대체 풀이를 검토 가능하게 한다.
2026-08-02 | qa | 다중 샷 분석기에서 속성 라벨 확장 import 누락으로 테스트 컴파일 오류가 발생했다. TraitType 라벨 확장을 명시적으로 연결해 분석 도구의 한글 출력 계약을 복원한다.
2026-08-02 | qa | 최종 다중 샷 보고서에서 1단계 3,373/52,920, 2단계 3,511/52,380, 3단계 4,046/133,110 성공을 재확인했다. 3단계 점착 이전·복제 후 무거움 이전 순서를 대체 풀이 근거로 문서화한다.
2026-08-02 | progression | 목표 문서와 현재 직접 GameScreen 기준값을 대조해 일반 시작 상태의 복사권 기본값이 남아 있는 불일치를 확인했다. 복제 코어 보유 상태에서만 복사가 가능하도록 도메인·레벨·테스트 기준값을 0으로 통일한다.
2026-08-02 | progression | 복제 코어 테스트 상태의 화면 라벨은 `복사 n회`가 아니라 `복제 코어 n개 남음`으로 이미 분기되어 있었다. 관련 위젯 기대값을 제품 언어와 일치시켜 회귀를 복원한다.
2026-08-02 | art | 모바일 플레이 캡처의 보드 아래 무채색 여백을 해변 실험 섬 배경과 연결한다. 물리 보드 크기·좌표는 유지하고 Flutter 배경에 물결·모래·장식만 추가해 제품 세계의 연속성을 높인다.
2026-08-02 | puzzle | 퍼즐 진단에서 대표 행동만으로는 점착 후 최종 성공의 물리적 인과를 증명할 수 없음을 확인했다. 다중 샷 계획에 샷별 충돌 이벤트를 함께 보존하고 점착 부착·홀 진입 회귀를 추가한다.
2026-08-02 | qa | 실제 사용자 결과를 추정하지 않고 내부 플레이 흐름만 분석할 수 있도록 개인정보 없는 로컬 계측 계층을 추가한다. 스테이지·시도·속성·조준·충돌·되감기·클리어를 JSON/CSV로 내보낼 수 있게 한다.
2026-08-02 | docs | README와 복제 자원 문서의 이전 단계별 복사권 설명을 현재 제품 규칙과 맞춘다. 공식 App Store·개발사·Apple Design Awards 자료에서 추출한 원칙과 모방하지 않을 요소를 별도 레퍼런스 매트릭스에 기록한다.
2026-08-02 | progression | 단계 초기화가 현재 소모 후 코어 수량을 그대로 재사용하는 문제를 확인했다. 단계 진입 시점의 코어 스냅샷을 저장해 초기화는 자원을 복원하고, 다음 단계 이동은 현재 보유량만 전달하도록 분리한다.
2026-08-02 | qa | 전체 정적 분석에서 로컬 계측 이벤트의 nullable map 조건식 7건이 정보 lint로 보고됐다. 이벤트 기본 맵과 nullable 필드 추가를 분리해 분석 결과를 깨끗하게 유지한다.
2026-08-02 | progression | 3단계 클리어 보상을 받은 뒤 같은 단계를 초기화하는 경우에도 보상 코어를 유지해야 하므로, 보상 적용 시점에 단계 코어 스냅샷을 갱신한다.
2026-08-02 | qa | 복사 적용 직후 속성 팝업을 닫는 기존 UX 때문에 중간 잔량 문구를 즉시 조회하는 새 테스트가 잘못되었다. 실제 사용자처럼 초기화 후 팝업을 다시 열어 진입 시점 코어가 복원됐는지만 검증한다.
2026-08-02 | qa | 코어 복원 테스트가 개발용 단계 선택 모드에서 실행되어 제품 규칙을 적용하지 않는 것을 확인했다. 실제 앱 라우터와 같은 `showStageSelector=false`로 테스트 모드를 맞춘다.
2026-08-02 | qa | 제품 라우터 모드를 위젯 테스트에서 재현할 수 있도록 PropertyShotApp에 표시 모드 전달 옵션을 추가한다. 기본값은 기존 개발 하네스 호환성을 유지한다.
2026-08-02 | qa | 모드 전달 옵션이 코어 보유 팝업 테스트에 먼저 적용된 것을 확인했다. 단계 초기화 회귀에도 동일한 제품 모드를 명시해 실제 초기화 경로를 검증한다.
2026-08-02 | qa | 최신 서버 교체 후 390x844 실브라우저에서 홈·플레이 진입·속성 보유 돌 상세 팝업을 다시 확인했다. 캔버스 렌더링과 브라우저 콘솔 오류 0건을 확인하고, 서버는 8080에서 유지한다.
2026-08-02 | art | 최신 플레이 캡처에서 물리 보드는 충분한 크기지만 벽이 산업용 레일처럼 보이고 조준선이 개발용 점선에 가깝다는 P1을 재확인했다. 물리 좌표는 유지하고 벽 재질과 공에 연결된 탄성 조준 가이드를 같은 해변 실험 섬 토큰으로 개선한다.
2026-08-02 | art | 새 탄성 리본의 기본 힘 색상이 올리브로 섞여 목표 강조와 충돌하는 것을 캡처에서 확인했다. 조준 리본을 해변 산호색으로 통일하고, 리본·화살촉 그림자와 하이라이트를 분리해 방향성을 유지한다.
2026-08-02 | ux | 변경 후 Subagent 재평가에서 390px HUD가 목표·추천·현재 안내를 여러 줄로 쌓는 P1을 확인했다. 제품 경로의 축약 목표를 한 줄 행동 문장으로 제공하고, 보드 아래 해변 여백에는 비충돌 해안선·조개 장식을 추가해 빈 공간을 의도된 세계로 연결한다.
2026-08-02 | qa | 축약 목표를 한 줄로 바꾼 회귀를 고정하기 위해 320px 위젯에서 제품 축약 목표의 값·줄 수를 검증한다. 긴 전체 목표 문구 테스트는 넓은 화면 경로에 남겨 제품 안내의 의미를 보존한다.
2026-08-02 | qa | 축약 목표 계약 변경으로 기존 첫 화면 위젯 기대값이 긴 추천 문구를 찾아 실패했다. 제품 축약 화면의 새 한 줄 목표를 기대하도록 테스트를 갱신하고 넓은 화면의 상세 목표 검증과 분리한다.
2026-08-02 | qa | 최신 축약 HUD·해변 배경 반복에서 전체 124개 테스트, `flutter analyze`, Web release와 390·768 실브라우저 캡처를 통과했다. iOS는 Xcode 컴파일 후 Development Team·프로비저닝 프로파일 부족으로 배포 단계가 실패했다.
2026-08-02 | ios | 최신 `flutter build ios --simulator`는 Xcode 단계에서 iOS 18.2 Simulator Runtime 미설치로 실패했다. 디바이스 빌드는 별도로 Development Team·프로비저닝 프로파일이 필요하므로 두 환경 실패를 구분해 기록한다.
2026-08-02 | ux | 축약 HUD의 3단계 진행 힌트에 줄임표가 생기면 도움말 축약 문제가 재발할 수 있어, 상태별 핵심 행동만 남긴 축약 진행 문장을 별도로 둔다. 넓은 화면의 상세 힌트는 유지한다.
2026-08-02 | qa | 축약 3단계 진행 힌트 분리 후 기존 위젯 테스트가 상세 문구를 기본 축약 화면에서 찾는 실패를 냈다. 축약 상태의 `무거움은 스위치 · 점착은 공 고정` 계약으로 기대값을 맞춘다.
2026-08-02 | qa | 최종 축약 힌트 반영 후 전체 124개 테스트가 통과했다. PID 55418을 종료하고 PID 61743 최신 Web release로 교체했으며, 루트·번들 HTTP 200과 390px 속성 팝업·이전 실브라우저 흐름을 다시 확인한다.
2026-08-02 | art | Canvas 도형과 래스터 오브젝트 사이의 재질감 편차를 재현했다. 물리 좌표는 유지하고 벽·문·스위치·점착판에 공통 광원·접지·압출 마감 토큰을 낮은 불투명도로 적용한다.
2026-08-02 | qa | 공통 Canvas 표면 마감 후 Web release를 기존 PID 61743 종료·PID 71571 교체로 재실행했다. 390×844 플레이·768×1024 홈 캡처와 390px 실제 시작 입력에서 콘솔 오류 0건을 확인했으며, WebKit 런타임 부재로 Chromium 모바일 뷰포트를 사용했다.
2026-08-02 | agents | Lagrange 사후 QA에서 P0 없음, 한글 UI·390px 레이아웃·물리 좌표 불변을 확인했다. Canvas 공통 마감과 래스터 오브젝트의 재질감 차이, 넓은 하단 모래 영역, 768px 캡처의 홈 화면 범위를 P1/P2 잔여 위험으로 기록한다.
2026-08-02 | art | QA의 P1인 Canvas·래스터 재질 불일치를 재현했다. 기존 돌·상자·젤리 이미지의 질감과 압출은 보존하고, 공통 광원·하단 음영·에지 토큰을 래스터 표면에도 `srcATop`으로 적용한다.
2026-08-02 | qa | 래스터 표면 마감 반영 후 전체 124개 테스트·정적 분석·Web release를 통과했다. 기존 PID 71571을 종료하고 PID 81493으로 데모를 교체했으며, 390×844·768×1024 실제 플레이 캡처에서 콘솔 오류 0건을 확인했다. 최신 iOS 디바이스 빌드는 Development Team·프로비저닝 프로파일 부족으로 실패했다.
2026-08-02 | art | QA의 P2인 하단 모래 영역 저정보 밀도를 재현했다. 충돌·입력 대상이 아닌 낮은 대비의 조수 웅덩이·잎사귀·불가사리 장식을 배경에 추가해 보드 밖도 해변 실험 섬의 일부로 읽히게 한다.
2026-08-02 | qa | 하단 해변 장식 적용 후 전체 124개 테스트·정적 분석·Web release를 통과했다. 기존 PID 81493을 종료하고 PID 89192로 교체했으며 390×844·768×1024 실제 플레이 캡처에서 콘솔 오류 0건, HUD·입력 영역 침범 없음과 장식의 비충돌 배경 처리를 확인했다.
2026-08-02 | qa | 목표 문서의 Golden/Screenshot Test 요구를 현재 테스트 구조와 대조해 픽셀 회귀 게이트가 없음을 확인했다. 해변 플레이 배경 CustomPainter를 독립 Golden 대상으로 공개하고 390×844 기준 이미지를 생성한다.
2026-08-02 | qa | 해변 배경 Golden을 390×844·768×1024 두 크기로 생성하고 전체 126개 테스트를 통과했다. 최신 Web release는 기존 PID 89192 종료 후 PID 96760으로 교체했으며 두 실제 플레이 캡처의 콘솔 오류가 0건이다.
2026-08-02 | agents | Arendt 독립 QA는 Golden 범위가 배경 페인터 검증에 적절하고 P0가 없음을 확인했다. 실제 전체 게임 화면과 HUD·한글 텍스트는 Golden 대상이 아니므로 P1 자동 회귀 범위의 한계로 기록한다.
2026-08-02 | qa | 전체 화면 회귀 범위를 보완하기 위해 정적 홈 화면을 390×844·768×1024 Golden 대상으로 추가한다. 플레이 Canvas는 애니메이션 변동을 고려해 기존 실브라우저 캡처와 위젯·물리 회귀로 계속 검증한다.
2026-08-02 | qa | 홈 Golden 테스트에서 사용할 고정 키와 한글·시작 버튼 기대값을 추가한다. SharedPreferences를 테스트 초기화해 홈 라우터 상태가 기준 이미지에 영향을 주지 않게 한다.
2026-08-02 | qa | 홈 Golden 이미지에서 한글이 네모 글리프로 나온 것을 확인했다. Web 정상 캡처와의 불일치를 막기 위해 테스트에서 번들 NanumGothic 폰트를 명시적으로 로드한 뒤 기준 이미지를 다시 생성한다.
2026-08-02 | qa | 홈 Golden 재생성 후 정규 굵기 한글은 복원됐지만 굵은 한글과 Material 아이콘이 네모로 남았다. NanumGothic 세 굵기와 MaterialIcons 폰트를 테스트 바인딩에 모두 등록해 Web 캡처와 같은 글리프를 확보한다.
2026-08-02 | qa | 홈 Golden 폰트 보정 후 실제 Web 390×844·768×1024 캡처에서 한글·Material 아이콘과 보드 미리보기를 확인했다. 두 브라우저 콘솔 오류는 0건이며 최신 서버 PID 10257에서 응답했다.
2026-08-02 | qa | 홈 Golden 버튼 라벨을 확대해 Flutter 테스트 이미지의 실제 글리프 손상을 확인했다. `PropertyShotApp`에 선택형 테스트 글꼴 패밀리를 주입해 pubspec 글꼴 등록과 FontLoader 중복을 분리한 뒤 재검증한다.
2026-08-02 | ux | 테스트 전용 글꼴 패밀리로도 홈 시작 버튼 라벨만 깨지는 것을 확인했다. FilledButton의 별도 TextStyle에 현재 테마의 폰트 패밀리를 명시해 한글 UI와 Golden 경로를 동일하게 맞춘다.
2026-08-02 | qa | FilledButton에 현재 테마 폰트 패밀리를 명시한 뒤 홈 Golden의 시작 버튼 한글 라벨이 정상으로 복원됐다. 실제 Web 화면과 Golden의 한글·Material 아이콘·버튼 모양을 다시 대조한다.
2026-08-02 | qa | Carver 재평가에서 390px 홈 Golden만 이미지 에셋 로딩 전 캡처되어 돌·상자·공이 누락되는 순서 의존성을 확인했다. Golden 테스트에서 세 오브젝트 이미지를 명시적으로 precache하고 세 굵기 글꼴을 다시 적용해 해상도별 기준을 일치시킨다.
2026-08-02 | qa | 홈 Golden의 에셋 로딩 순서 문제를 수정하기 전에 세 이미지 자산과 NanumGothic 세 굵기 글꼴을 테스트에서 준비하도록 보강한다. 기준 이미지가 화면 상태가 아닌 준비 완료된 렌더링 결과를 검증하도록 한다.
2026-08-02 | qa | 이미지 precache를 동기 위젯 테스트 영역에서 직접 기다리면 첫 홈 Golden 케이스가 완료되지 않는 현상을 확인했다. 이미지 디코딩 대기만 `runAsync`로 분리하고 완료 뒤 프레임을 다시 펌프한다.
2026-08-02 | qa | 홈 Golden에서 세 이미지 에셋의 디코딩을 `runAsync`로 precache한 뒤 390×844·768×1024 기준 이미지를 재생성했다. 두 기준 이미지에 돌·상자·공이 모두 보이고 홈 Golden 2개가 통과했다.
2026-08-02 | qa | 최신 변경 후 정적 분석과 전체 128개 테스트를 통과했다. 기존 PID 10257을 종료하고 Web release를 PID 25735로 교체했으며 390×844·768×1024 실제 홈 캡처의 브라우저 콘솔 오류가 각각 0건이다.
2026-08-02 | agents | Kant 독립 QA는 홈 Golden 두 해상도에서 돌·상자·공·홀·깃발·한글·Material 아이콘과 레이아웃을 확인해 P0·P1 없음으로 판정했다. 실제 Web 캡처가 Golden보다 약 8px 아래에 보이는 차이는 렌더러·안전영역 차이의 P2로 기록한다.
2026-08-02 | ux | 실제 플레이 390px 캡처에서 목표 문구와 초기 조작 안내가 상단 HUD에 중복되어 세 줄로 쌓이는 것을 확인했다. 목표는 단계 목적에 남기고 초기 상태 메시지는 `방향 조정 · 길게 누르기 · 손 떼기`로 축약해 첫 행동을 더 빠르게 읽히게 한다.
2026-08-02 | qa | 축약 HUD 변경 후 `flutter analyze`, 전체 128개 테스트, Web release 빌드를 통과했다. 기존 PID 25735를 종료하고 PID 36420으로 최신 서버를 교체했으며 390·393·430·768·1024px 실제 플레이 캡처의 콘솔 오류가 모두 0건이다.
2026-08-02 | agents | Gauss 사후 QA는 초기 안내 중복 제거와 390·768px 보드·공·돌·상자·홀·컨트롤 경계를 확인해 P0·P1 없음으로 판정했다. 768px HUD 경계 자동화가 캡처 육안에 의존하는 점을 P2로 남긴다.
2026-08-02 | qa | 서버 PID를 `lsof`로 재확인했다. 축약 HUD 최신 서버는 PID 36420으로 리스닝 중이며 루트와 번들은 HTTP 200이다.
2026-08-02 | docs | 축약 HUD 검증 결과를 QA 문서와 스크린샷 매트릭스에 분리 기록한다. 첫 다중 파일 패치가 경로 확인 단계에서 적용되지 않아 문서별로 다시 반영한다.
2026-08-02 | qa | Gauss가 지적한 768px 축약 HUD 자동화 공백을 해소하기 위해 기존 HUD·컨트롤 경계 회귀에 768×1024를 추가한다. 실제 캡처 검증과 위젯 경계 검증을 같은 태블릿 크기로 맞춘다.
2026-08-02 | qa | 위젯 테스트의 동일한 크기 목록을 찾는 과정에서 팝업 경계 회귀에도 768×1024가 먼저 포함되었다. HUD·컨트롤 경계 회귀에도 같은 크기를 별도로 추가해 두 검증을 모두 명시한다.
2026-08-02 | qa | HUD·컨트롤 경계 위젯 회귀를 320×568·390×844·768×1024로 확장하고 41개 위젯 테스트를 통과했다. Gauss가 남긴 768px 자동화 공백 P2를 이 검증으로 닫는다.
2026-08-02 | render | 물리·애니메이션 계약을 대조하던 중 `PropertyShotGame.render`의 엔티티 렌더 호출을 점검했다. 현재 엔티티는 1회만 그려지며 이번 반복에서는 렌더 중복 코드 변경을 하지 않는다.
2026-08-02 | render | 소스 구간을 줄번호로 재확인한 결과 현재 `PropertyShotGame.render`에는 엔티티 렌더 호출이 이미 1회만 존재한다. 직전 중복 렌더 진단은 출력 중복으로 인한 오판이므로 코드 변경 없이 기록을 정정한다.
2026-08-02 | qa | 애니메이션 시간축 테스트가 충돌 영향 콜백 수만 검증하고 이동 이벤트의 인과 순서는 직접 확인하지 않는 공백을 찾았다. 30·60·120Hz 테스트에 `ShotAnimationMove.triggerPathIndex` 비감소 순서 검증을 추가한다.
2026-08-02 | qa | 30·60·120Hz 시간축 테스트에 연쇄 이동 이벤트 순서 검증을 추가하고 3개 테스트를 통과했다. 충돌 영향 콜백 수뿐 아니라 실제 `triggerPathIndex` 인과 순서도 회귀 게이트로 고정했다.
2026-08-02 | feedback | 소리·진동 토글은 현재 실행 중 상태만 바꾸고 앱 재실행 뒤 기본값으로 돌아가는 것을 확인했다. SharedPreferences에 두 설정을 저장·복원하고 플랫폼 저장 실패는 게임을 막지 않도록 안전하게 흡수한다.
2026-08-02 | agents | Herschel 독립 QA는 저장/복원 키와 토글 갱신은 통과로 평가했지만, 라우터의 SharedPreferences 초기화 예외가 try/catch 밖에 있고 문 `opening` 애니메이션에 별도 사운드·햅틱이 없음을 P1/P2로 지적했다. 두 피드백 경로를 보강한다.
2026-08-02 | feedback | SharedPreferences 초기화 실패 시 기본 진행 상태로 홈을 유지하도록 라우터 로딩을 예외 처리하고, 문 `opening` 이벤트에 별도 알림 사운드·중간 햅틱을 연결했다. 관련 테스트 45개와 정적 분석을 통과했다.
2026-08-02 | qa | 최신 Web release를 기존 PID 59672로 교체했다. 390×844 설정 팝업과 효과음 토글 새로고침 복원 흐름을 캡처했으며 두 실행의 브라우저 콘솔 오류는 0건이다.
2026-08-02 | qa | 피드백 설정·문 열림 보강 후 전체 131개 테스트와 정적 분석을 통과했다. 최신 서버 PID 59672는 루트·번들 HTTP 200으로 유지된다.
2026-08-02 | docs | 피드백 보강에 문 열림 사운드 테스트 1개가 추가되어 관련 테스트 수를 45개가 아니라 46개로 정정한다. 전체 회귀 최신 수치는 131개다.
2026-08-02 | docs | QA 문서의 첫 번째 `flutter test` 표가 홈 Golden 역사 수치인데 최신 수치로 잘못 치환된 것을 확인했다. 홈 Golden 표는 128개로 복원하고 피드백 섹션에 최신 131개를 별도 기록한다.
2026-08-02 | perf | 현재 성능 증거가 순수 `ShotResolver` 평균만 포함하고 Canvas·Web 프레임과 발사 입력을 측정하지 않는 공백을 확인했다. Playwright 기반 Web 감사 도구를 추가해 홈→플레이→발사 전후의 requestAnimationFrame 간격과 콘솔 오류를 JSON으로 남긴다.
2026-08-02 | test | 배경·홈 Golden만으로는 HUD·보드·오브젝트·하단 입력 영역의 전체 관계를 보호하지 못하므로 390×844·768×1024 전체 플레이 화면 Golden 게이트를 추가한다.
2026-08-02 | test | 첫 전체 플레이 Golden 생성에서 Flame 자산 로드 전 프레임이 캡처되어 보드가 비는 순서 의존성을 발견했다. 보드 로드 완료를 확인한 뒤 기준 이미지를 재생성한다.
2026-08-02 | test | Flame 첫 렌더 대기만으로는 위젯 테스트 캡처에 보드가 나타나지 않아, 실제 비동기 이벤트 루프를 진행하는 보강이 필요하다는 점을 확인했다.
2026-08-02 | test | Flame 공식 테스트 훅 `GameWidgetState.toBeLoaded()`를 사용해야 onLoad 완료를 정확히 기다릴 수 있음을 확인했다. 전체 Golden은 해당 훅 이후에만 캡처한다.
2026-08-02 | test | `WidgetTester.state`의 제네릭 경계에 맞춰 Golden 테스트의 Flame 상태 타입을 실제 `PropertyShotGame`으로 고정한다.
2026-08-02 | test | Flame의 `toBeLoaded()`는 위젯 상태가 아니라 현재 게임 인스턴스에 제공되므로 `currentGame.toBeLoaded()`로 호출 대상을 교정한다.
2026-08-02 | test | Golden 호스트에서 이미지 디코더 교착을 피하면서 보드·HUD 레이아웃을 실제 게임 렌더러로 검증하기 위해 래스터 자산 로딩만 주입 가능한 테스트 옵션으로 분리한다. 제품 기본값은 기존처럼 자산을 로드한다.
2026-08-02 | ux | 섬 지도 카드가 목록처럼 보이는 문제를 보완하기 위해 연결 경로·진행률·다음 항해 안내를 추가하고, 실제 한 번 탭 동작과 접근성 힌트를 일치시킨다.
2026-08-02 | test | 섬 지도 경로·진행률·안내 영역의 시각 회귀를 390×844·768×1024 Golden으로 고정한다.
2026-08-02 | docs | 섬 지도 Golden을 스크린샷 매트릭스와 검증 결과에 기록했고, 지도 테스트 포함 최신 전체 회귀 136개를 확인했다.
2026-08-02 | qa | 최신 `flutter build ios --no-codesign`은 Xcode 컴파일까지 통과했지만 `com.example.propertyShot` 배포 타깃에 Development Team·Provisioning Profile이 없어 실패했다. 코드 컴파일 실패로 기록하지 않는다.
2026-08-02 | qa | 고해상도 튜토리얼 분석의 실제 연속 성공 폭(1단계 28도·2단계 20도)에 맞춰 자동 난이도 회귀 최소 기준을 16도에서 1단계 24도·2단계 18도로 강화한다. 이는 실제 사용자 성공률을 대신하지 않는다.
2026-08-02 | test | 래스터 포함 전체 플레이 Golden이 자산 로드 교착으로 제외된 원인을 분리하기 위해 `rootBundle`과 `ui.Codec` 첫 프레임을 직접 검증하는 재현 테스트를 추가한다.
2026-08-02 | test | 래스터 재현 테스트의 첫 실패는 `ServicesBinding` 초기화 누락이었다. 위젯 테스트 바인딩을 명시적으로 초기화한 뒤 디코더 결과를 다시 측정한다.
2026-08-02 | test | PNG·Codec 단독 디코드는 통과하므로, 실제 `GameWidget`과 `PropertyShotGame.onLoad`를 3초 제한으로 연결해 교착 지점을 재현한다.
2026-08-02 | test | Flame `toBeLoaded()`의 `FutureOr<void>` 반환을 `Future<void>.sync`로 감싸 테스트 타임아웃을 적용한다.
2026-08-02 | test | Flame 최소 위젯 재현은 `toBeLoaded()`가 테스트 종료를 붙잡아 회귀 게이트로 부적합했다. PNG·Codec 단독 디코드 회귀만 유지하고, 래스터 시각 품질은 Flutter `Image.asset` Golden으로 분리한다.
2026-08-02 | test | 래스터 Golden 첫 실행은 자산 오류가 아니라 독립 `Stack`에 `Directionality`가 없어서 실패했다. 테스트 셸에 한글 방향성 컨텍스트를 추가한다.
2026-08-02 | art | 래스터 품질 Golden에서 CC0 농구공 `ball.png`와 실제 얼굴 공의 화풍 불일치를 확인했다. 공 공통 Canvas 페인터를 홈·팝업·자산 검증에 공유해 주인공 식별성을 통일한다.
2026-08-02 | fix | 공 페인터 공개 이름 변경에서 속성 물체 썸네일의 기존 내부 참조 하나가 남아 컴파일 오류가 났다. 남은 참조를 공통 페인터로 교체한다.
2026-08-02 | docs | `ball.png`는 번들에 남아 있는 CC0 레거시 자산으로 표시하고, 실제 UI·플레이·Golden은 `GameBallIconPainter`를 사용하도록 권리대장과 자산 목록을 정정한다.
2026-08-02: QA에서 홈·썸네일·팝업과 실제 Flame 게임 화면의 공 렌더링 경로가 분리된 것을 확인해 공통 페인터 모듈로 통합하기로 했다. 게임 전용 충격 링과 속성 질감은 공통 기본 렌더링 위에 유지한다.
2026-08-02: 공통 페인터 통합 후 정적 분석에서 남은 구형 공용 Paint 지역변수와 래스터 Golden의 누락 import를 정리한다.
2026-08-02: 공통 페인터 통합으로 홈·플레이·래스터 Golden에서 공의 얼굴과 광택 픽셀이 갱신됐다. 실패 캡처를 확인해 배치·벽·홀·오브젝트 레이아웃 변화 없이 공 화풍만 변경된 것을 확인했다.
2026-08-02: 공통 페인터 통합 후 래스터·홈·플레이 Golden 기준 이미지를 갱신하고 관련 대상 테스트 6개를 통과했다. 문서의 이전 ball.png precache 설명과 공 페인터 경로를 최신 구조에 맞춰 정정한다.
2026-08-02: 독립 QA가 돌 하나만 검사하던 PNG Codec 게이트의 범위 공백을 지적했다. 실제 게임에서 사용하는 돌·상자·젤리 세 래스터 자산을 모두 첫 프레임 디코드 대상으로 확장한다.
2026-08-02: Golden 실패 비교 이미지가 생성하는 `test/failures/`는 테스트 산출물이므로 저장소에 들어가지 않도록 무시 목록에 추가한다.
2026-08-02: 최신 390px·768px 캡처에서 벽이 여전히 반복 타일형 산업용 레일로 읽히는 P1을 재확인했다. 충돌 좌표·고정 판정은 유지하고 벽 표면을 해변 실험 섬의 장난감 보드 프레임으로 재질만 교체한다.
2026-08-02: 벽 재질 회귀 캡처를 확인해 보드 배치·공·홀·오브젝트 위치 불변과 타일 선 감소를 검증했다. 새 기준 이미지는 플레이 Golden에 반영하고, 존재하지 않는 `test/physics_test.dart` 호출은 검증 명령에서 제거한다.
2026-08-02: 벽 재질 변경은 `PropertyShotGame`의 Canvas 표면·광원 토큰만 수정하고 EntityState·ShotResolver·히트박스는 건드리지 않았다. 390×844·768×1024 플레이 Golden 4개와 `flutter analyze`를 통과했다.
2026-08-02: 벽 재질 반복의 실제 Web 증거를 위해 최신 390×844 서버 홈·플레이 캡처를 생성한다. 캡처는 Flutter Golden과 별도로 Chromium 보조 검증으로 기록한다.
2026-08-02: 실브라우저 캡처 명령은 자동 실행 승인 사용량 제한으로 실행되지 않았다. 실제 Web 증거로 오인하지 않도록 이번 반복의 새 증거는 390×844·768×1024 Golden과 서버 HTTP 상태로 한정하고, 기존 Chromium 캡처는 이전 반복 자료로 구분한다.
2026-08-02: 전체 플레이 Golden이 1단계만 캡처하던 범위 공백을 확인했다. 첫 3단계의 젤리·반사벽·스위치·문·점착판 Canvas 화면을 390×844·768×1024에서 각각 고정한다.
2026-08-02: 첫 3단계 Golden 테스트 확장 파일은 `dart analyze`에서 이슈 없음으로 확인했다. Flutter 테스트 러너 재실행은 엔진 캐시 `engine.stamp`·`engine.realm` 쓰기 권한 오류로 실행하지 못했으며, 직전 전체 139개 통과와 이번 변경의 미실행을 구분한다.
2026-08-02: Flutter 엔진 캐시 권한 오류로 2·3단계 Golden 기준 이미지를 생성할 수 없어, 미생성 기준 파일을 참조하는 테스트 확장은 녹색 회귀 기준을 깨지 않도록 보류한다. 기존에 실제 생성·검증된 1단계 Golden은 유지한다.
2026-08-02: 현재 코드의 복사 규칙은 첫 챕터 시작 시 복사 UI를 숨기고 3단계 클리어 후 복제 코어를 보상하는 모델 B다. 일부 계획·평가 문서의 이전 모델 A(1/1/2회) 표현을 현재 규칙과 역사 기록으로 분리해 정정한다.
2026-08-02: 오디오 QA에서 모든 이벤트가 플랫폼 `click`·`alert` 두 종류로만 수렴하는 공백을 확인했다. 모바일 기본 피드백은 유지하고 Web에서는 외부 음원 없이 `dart:web_audio` 합성 톤을 조건부 재생하는 피드백 백엔드를 추가한다.
2026-08-02: 합성 사운드 큐를 추가하고 VM 분석에서 모바일 경로·게임 피드백 테스트의 이슈 없음을 확인했다. Web 전용 `dart:web_audio` 컴파일은 Flutter Web 빌드가 필요한 별도 검증으로 남긴다.
2026-08-02: 전체 Dart 분석에서 `dart:web_audio` URI가 VM 분석 대상에 없어 오류가 났다. Web Audio 호출을 `dart:html`·`dart:js_util` 조건부 구현으로 바꿔 플랫폼 분리와 정적 분석을 동시에 만족시킨다.
2026-08-02: Dart 3.12 SDK에는 `dart:js_util`이 VM 분석 대상에서 빠져 있어 웹 오디오 구현을 `dart:js_interop`·`dart:js_interop_unsafe`의 최신 확장 API로 교체한다. 브라우저 전역 오디오 객체와 Promise는 모두 웹 조건부 파일 안에서만 다룬다.
2026-08-02: 최신 JS 인터롭 구현은 컴파일되지만 `is` 기반 JS 타입 검사가 플랫폼 일관성 경고를 냈다. SDK가 제공하는 `JSAny.isA<T>()`로 생성자·노드·Promise 판정을 교체해 웹/VM 정적 분석 경고까지 닫는다.
2026-08-02: JS 인터롭 타입 검사 패치 후 기존 함수 후반부가 중복된 것을 즉시 확인했다. 중복 호출·Promise 종료 블록을 제거해 웹 피드백 함수가 단일 시간축으로만 실행되도록 정리한다.
2026-08-02: 재질별 합성 피드백 큐 테스트와 전체 Flutter 회귀 140개가 통과했다. Dart 분석도 이슈 없음이며, Web release 재빌드는 엔진 캐시 `engine.stamp`·`engine.realm` 쓰기 권한 오류로 중단되어 실행 중인 서버는 이전 검증 빌드를 유지한다.
2026-08-02: 권한 승격으로 최신 Web release를 다시 빌드하고 기존 PID 21972를 종료한 뒤 PID 47804로 교체했다. Chromium 390×844·768×1024 성능 감사는 콘솔 오류 0건, 평균 16.67ms, 20ms 초과 프레임 0%였고 홈·플레이 실제 캡처 4장을 남긴다.
2026-08-02: 현재 브랜치에서 `flutter build ios --no-codesign`을 재실행했다. Xcode 컴파일은 완료됐고, 배포 앱 생성 단계에서 Development Team·Provisioning Profile 미설정으로 실패했으므로 코드 컴파일 실패가 아닌 서명 환경 잔여 위험으로 확정한다.
2026-08-02: 최신 Flutter 권한 환경에서 첫 3단계 전체 플레이 Golden 확장을 재개한다. 기존 테스트는 1단계만 화면 기준을 고정하고 있어 젤리·반사벽·스위치·문·점착판이 포함된 2·3단계 시각 회귀가 비어 있었다.
2026-08-02: 첫 3단계 플레이 Golden을 390×844·768×1024로 각각 생성해 6개 테스트를 통과시켰다. 전체 회귀는 144개, `flutter analyze`는 무이슈이며 2단계 젤리·반사벽과 3단계 스위치·문·점착판·상자 화면을 기준 이미지로 고정한다.
2026-08-02: 독립 QA가 새 6개 Golden의 `loadGameAssets: false`를 P1으로 지적했다. 배치 회귀와 실제 Flame 래스터 에셋 회귀를 분리하지 않도록 실제 에셋 로딩을 켠 Golden을 재생성해 교착 없이 통과하는지 확인한다.
2026-08-02: 실제 Flame 래스터 로딩 Golden은 1단계 첫 케이스에서 `toBeLoaded()`가 66초 동안 완료되지 않아 교착을 재현했다. 6개 배치 Golden은 녹색 기준을 유지하도록 테스트 옵션을 원복하고, 실제 래스터 경로는 별도 PNG·Codec·래스터 Golden 게이트와 한계 기록으로 분리한다.
2026-08-02: 현재 평가표에 과거 복사 모델 A와 오디오 미완료 문구가 남아 최신 복제 코어·Web 합성음·144개 회귀·Chromium 성능 근거와 어긋나는 것을 확인했다. 역사 로그는 유지하고 현재 평가표만 최신 상태로 동기화한다.
2026-08-02: 스크린샷 매트릭스가 이전 2개 플레이 Golden만 가리키고 최신 1·2·3단계 6개 기준과 Web release 캡처를 누락한 것을 확인했다. 현재 화면 증거와 실제 기기 미검증 범위를 함께 최신화한다.
2026-08-02: 최종 유지 세션에서 최신 `build/web`을 데모 서버 PID 81248로 제공했다. 권한 승격 후 루트·`main.dart.js` HTTP 200을 확인했으며, 사용자 확인을 위해 유지 세션을 종료하지 않는다.
2026-08-02: 사운드 요구사항과 현재 이벤트 매핑을 대조해 성공음은 있으나 별·메달 획득의 별도 피드백 큐가 없는 공백을 확인했다. 클리어 결과의 별 계산 직후 전용 합성음·햅틱을 연결하고 설정 토글·예외 흡수 계약은 유지한다.
2026-08-02: 별 계산 직후 `medal_awarded` 이벤트와 전용 합성음·가벼운 햅틱을 연결했다. `FeedbackCue.medal` 매핑, 설정 토글·예외 흡수, 클리어 위젯 흐름을 회귀 테스트하고 전체 145개 통과를 확인한다.
2026-08-02: 최신 Web release를 기존 PID 81248 종료 후 PID 95764로 교체했다. 390×844·768×1024 Chromium 실행에서 콘솔 오류 0건, idle·발사 평균 약 16.67ms를 재확인하고 메달 피드백 반복 캡처를 저장한다.
2026-08-02: 독립 QA에서 메달 피드백이 팝업의 별 계산보다 먼저 호출되는 순서 위험을 확인했다. 클리어 완료 단계에서 별 수를 먼저 산출하고 그 값을 메달 큐에 전달하도록 보정한 뒤 순서 회귀를 추가한다.
2026-08-02: 순서 보정 후 Web release를 다시 빌드해 기존 PID 95764를 종료하고 PID 4815로 교체했다. 최신 번들에서도 390×844·768×1024 콘솔 오류 0건과 idle·발사 평균 약 16.67ms를 확인했다.
2026-08-02: 목표 문서의 필수 피드백 목록과 실제 호출을 대조해 젤리·홀 진입·조준 충전·복제 코어 획득이 일반 큐로 뭉쳐 있는 공백을 확인했다. 이벤트별 합성음·햅틱 큐를 분리하고 재질 매핑·발생 지점 테스트를 추가한다.
2026-08-02: 새 젤리 전용 큐가 기존 `bouncyCollision` 회귀 기대를 바꾸는 것을 테스트에서 발견했다. 기본 충돌 API의 탄성 계약은 유지하고 실제 게임 충돌에서만 젤리 강조 옵션을 전달하도록 호환성을 보정한다.
2026-08-02: 젤리 전용 큐 테스트가 기존 충돌 강도 테스트의 첫 호출을 잘못 바꾼 것을 확인했다. 젤리 전용 회귀에만 강조 옵션을 적용하고 기본 탄성 회귀는 그대로 두어 테스트 범위를 정확히 분리한다.
2026-08-02: 독립 UX QA가 홀 진입·클리어·메달 효과음의 병렬 재생으로 겹침이 생길 수 있는 P1을 지적했다. 게임 상태와 햅틱은 즉시 유지하고 오디오 큐만 순차화해 충돌 연쇄의 소리 순서를 보존한다.
2026-08-02: 오디오 이벤트 큐를 순차화하고 9개 피드백 테스트를 통과시켰다. 최신 Web release는 기존 PID 4815 종료 후 PID 35285로 교체했으며 390×844·768×1024 콘솔 오류 0건, 평균 약 16.67ms, 변경 후 화면 캡처를 재생성했다.
2026-08-02: 최신 오디오 큐 코드에서 `flutter build ios --no-codesign`을 재실행했다. Xcode 컴파일은 완료됐고 Development Team·Provisioning Profile이 없어 배포 단계에서 실패했으며, Dart·Xcode 컴파일 오류와 구분해 기록한다.
2026-08-02: 현재 평가표와 잔여 위험 문서의 회귀 수치가 145·144개로 분산된 것을 확인했다. 최신 세부 피드백 큐·오디오 순서 회귀 기준인 전체 148개와 Web·iOS 근거로 현재 문서만 동기화한다.
2026-08-02: 난이도 분석과 결과 팝업을 대조해 단계별 추가 도전 문구가 실제 달성 여부나 로컬 기록과 연결되지 않은 P1을 확인했다. 1단계 3회 이하, 2단계 젤리 충돌, 3단계 스위치 작동을 선택형 목표로 기록하고 결과에서 달성 상태를 표시한다.
2026-08-02: 추가 도전 달성 판정이 GameScreen 상태 흐름에만 묶이지 않도록 단계별 조건을 순수 함수로 분리한다. 1단계 샷 수·2단계 젤리 충돌·3단계 스위치 작동의 경계값을 독립 테스트로 고정한다.
2026-08-02: 추가 도전 구현 후 전체 Flutter 회귀 152개와 분석을 통과했다. 최신 Web release를 기존 데모 서버와 교체하고 390×844·768×1024 화면·성능·결과 상태를 다시 검증한다.
2026-08-02: 독립 QA에서 되감기 후 젤리·스위치 추가 도전 플래그가 남는 P1을 발견했다. 발사 전 누적 상태를 되감기 이력과 함께 보존하고, 직전 발사 전 상태로 플래그를 복원하는 회귀를 추가한다.
2026-08-02: 되감기 시 발사 전 추가 도전 플래그를 병렬 이력에서 복원하도록 보정했다. 추가 도전·위젯 회귀와 전체 Flutter 153개, `flutter analyze`를 통과했다.
2026-08-02: 되감기 보정 포함 Web release를 기존 PID 74405 종료 후 PID 84151로 교체했다. 390×844·768×1024 Chromium에서 콘솔 오류 0건, 평균 16.666~16.667ms, 20ms 초과 프레임 0%를 재확인하고 최종 캡처를 갱신한다.
2026-08-02: 스테이지 지도 캡처에서 경로 페인터가 가로형 카드 목록 뒤에 가려져 섬 경로가 읽히지 않는 P1을 확인했다. 세 노드를 좌우로 배치하고 경로·섬 표식을 실제 화면에 노출하는 모바일 지도 셸로 재구성한다.
2026-08-02: 독립 UX QA에서 첫 1단계가 상단·하단 문구만으로 바위 선택과 공 충전 순서를 추론하게 하는 P1을 확인했다. 짧은 단계별 코치마크를 게임 보드 안에 추가하고 선택·발사 상태에서 자동으로 숨긴다.
2026-08-02: 코치마크를 첫 단계의 바위·공 상태에만 노출하도록 구현하고, 속성 이전 위젯 흐름에서 두 안내가 순서대로 교체되는 회귀를 고정한다.
2026-08-02: 속성 이전 후 브라우저 캡처에서 하단 조작 문구가 이전 상태로 남는 P1을 발견했다. 공에 속성이 장착된 상태에서는 힘 충전 안내를 표시하도록 코치마크·컨트롤 문구를 일치시킨다.
2026-08-02: 항해 지도·코치마크·하단 상태 문구 보정 후 전체 Flutter 회귀 153개, `flutter analyze`, Web release를 통과했다. 최신 PID 18554에서 390×844·768×1024 콘솔 오류 0건과 약 16.67ms 프레임을 확인하고 변경 전후 캡처를 보존한다.
2026-08-02: 독립 아트 재평가에서 지도 연결선의 대비가 카드 사이에서 약한 P2를 확인했다. 경로 선과 완료 구간의 색·두께만 높여 항해 방향을 읽기 쉽게 하고, 물리·카드 배치는 유지한다.
2026-08-02: 경로 대비 보정 후 Golden·분석·위젯 회귀를 통과하고 최신 Web PID 27962로 서버를 교체했다. 최종 `flutter build ios --no-codesign`은 Xcode 컴파일 완료 후 Development Team·Provisioning Profile 부족으로 동일하게 서명 단계에서 실패했다.
2026-08-02: 자동 퍼즐 QA에서 하드코딩된 파 샷과 분석기 미연결 P1을 확인했다. 최소 샷·성공률에서 파를 산출하는 순수 정책을 추가하고 현재 3단계 파 값을 2·2·3으로 동기화해 결과·지도 표시와 분석 근거를 일치시킨다.
2026-08-02: 자동 파 정책을 실행해 1·2·3단계 결과가 각각 2·2·3으로 산출되는 것을 확인했다. 성공률 5% 이상은 최소 샷+1, 5% 미만은 최소 샷+2를 적용하고 1~5회로 제한하며, 사용자 표본이 아닌 결정론적 시뮬레이션 휴리스틱임을 문서에 명시한다.
2026-08-02: 파 연동 후 전체 Flutter 회귀 154개와 정적 분석을 통과했다. 기존 PID 27962를 종료하고 최신 Web release PID 52054로 교체했으며, 390×844·768×1024 Chromium에서 콘솔 오류 0건·평균 16.665~16.667ms·20ms 초과 0%를 확인하고 파 표시 항해 지도 캡처를 갱신했다. iOS는 Xcode 컴파일 완료 후 서명 환경 부족으로 배포 단계에서 실패했다.
2026-08-02: 목표 문서의 자동 분석 요구를 현재 모델과 대조해 성공률·연속 영역만 있고 우연 경로 후보·지배 전략·입력 오차 민감도가 구조화되지 않은 P1을 확인했다. 레벨별 허용 전략 메타데이터와 성공 셀 주변 실패 비율을 추가하되, 허용된 대체 풀이를 우연 경로로 오판하지 않도록 한다.
2026-08-02: 자동 분석에 의도·허용 전략, 지배 전략 비중, 허용 목록 밖 우연 경로 후보, 성공 셀 인접 실패 비율 기반 입력 정밀도 민감도를 추가했다. 중복 성공 입력 보정 후 첫 챕터 지배 전략은 고유 성공 입력 기준 세 단계 모두 100.00%, 민감도 40.70%·44.89%·36.52%, 우연 후보 0개이며 전체 Flutter 회귀 156개와 정적 분석을 통과했다.
2026-08-02: 자동 분석 지표 보강 후 기존 PID 52054를 종료하고 최신 Web release PID 80147로 교체했다. 390×844·768×1024 Chromium에서 콘솔 오류 0건, 평균 16.665~16.666ms, p95 최대 16.8ms, 20ms 초과 0%를 재확인하고 실제 항해 지도 캡처를 갱신했다. 중복 입력 합집합 기준으로 지배 전략 비중은 세 단계 모두 100%이며, 전략별 관측 성공 수와 고유 입력 수를 구분해 기록한다.
2026-08-02: 대체 전략 수와 지배 전략 해석을 명시한 뒤 최신 Web release를 기존 PID 80147 종료 후 PID 2452로 교체했다. 390×844·768×1024에서 콘솔 오류 0건, 평균 16.665~16.667ms, p95 최대 16.8ms, 20ms 초과 0%를 확인하고 최종 항해 지도 캡처를 저장한다.
2026-08-02: 다중 샷 상세 결과를 `DifficultyMetrics.multiShotMetrics`에 선택적으로 통합하고 도구 리포트가 통합 경로를 사용하도록 변경했다. 후속 행동 전체에서 복제 사용 여부를 검사하도록 보정했으며, 다중 샷 통합 회귀와 정적 분석을 통과했다.
2026-08-02: 최종 통합 리포트를 재실행해 고유 성공 입력 기준 민감도를 1단계 37.76%·2단계 43.57%·3단계 36.52%로 확정했다. 전체 Flutter 회귀 156개·정적 분석 통과 후 기존 PID 2452를 종료하고 최신 Web release PID 28229로 교체했으며 루트·번들 HTTP 200과 Chromium 성능을 재확인한다.
2026-08-02: 최신 통합 코드 기준 iOS 빌드를 다시 확인했다. Xcode 컴파일은 완료됐고 Development Team·Provisioning Profile 부족으로 배포 서명 단계에서 실패했으며, 코드 컴파일 오류가 아님을 최종 QA 문서에 남긴다.
2026-08-02: 최종 문서 감사를 통해 `ai_usage_summary.md`의 과거 105개 테스트 수치와 게임성 전후 문서의 이전 복사 충전 표기가 현재 제품 상태와 어긋난 것을 확인했다. 최신 156개 회귀·결정론적 분석·스테이지 3 보상형 복제 코어 기준으로 최종 문서를 동기화한다.
2026-08-02: 문서 동기화 후 현재 커밋에서 `flutter test` 156개·`flutter build web --release`를 재실행해 통과했다. 기존 PID 28229를 종료하고 최신 Web release PID 55374로 교체했으며 390×844·768×1024 Chromium 콘솔 오류 0건, 평균 16.665~16.667ms, p95 최대 16.7ms를 확인한다.
2026-08-02: 최신 지도 캡처 자동화가 홈 실제 문구와 불일치해 파일을 생성하지 못하는 것을 확인했다. 현재 서버에서 홈·섬 지도·플레이 캡처를 해상도별로 재현하는 전용 Playwright 스크립트를 추가하고 캡처와 콘솔 오류를 함께 기록한다.
2026-08-02: 캡처 스크립트의 초기 구현에서 콘솔 오류 수집이 페이지별로 연결되지 않은 것을 즉시 발견했다. 상태별 동일 페이지 흐름과 오류 수집을 단순화해 캡처 QA 도구 자체를 회귀 가능한 형태로 보정한다.
2026-08-02: Flutter Web의 의미 DOM에 버튼 텍스트가 노출되지 않아 캡처 도구의 텍스트 locator가 시간 초과하는 것을 확인했다. 기존 성능 감사에서 검증된 모바일 좌표를 명시적으로 사용하고, 좌표 출처와 한계를 스크립트에 남긴다.
2026-08-02: 물리 사후 QA에서 같은 경로 시점의 이동·충돌 콜백 순서와 첫 Flame 프레임 지연 시 충돌 피드백 누락 위험을 확인했다. 이벤트를 경로 인덱스·충돌 우선 순서로 통합하고, 첫 프레임 보조 완료에서도 모든 확정 이벤트를 한 번만 방출하도록 보정한다.
2026-08-02: 이벤트 방출기를 추가한 뒤 이를 구성하는 불변 이벤트 값 객체가 아직 정의되지 않은 상태를 확인했다. 이동·충돌 타입과 동일 경로 동률 순서를 명시하는 내부 값 객체와 회귀를 함께 추가한다.
2026-08-02: 충돌·이동 통합 방출 회귀는 경로 인덱스 정렬과 같은 인덱스에서 충돌 우선 순서를 직접 비교하도록 추가한다. 기존 30·60·120Hz 중복 방출 회귀는 유지한다.
2026-08-02: 이벤트 값 객체의 `const` 생성자가 런타임 이벤트 필드로 문자열 키를 만들 수 없어 정적 분석에서 5건을 보고했다. 생성자만 불변 일반 생성자로 바꾸고 이벤트 정렬 계약은 유지한다.
2026-08-02: UX 상태 전달 패치가 `_Hud` 선언 위치 불일치로 적용되지 않아 코드 변경 없이 중단됐다. 선언·호출·컨트롤 패널을 분리해 작은 패치로 다시 적용한다.
2026-08-02: 안내를 숨기기 위해 `SizedBox`를 사용한 결과 기존 접근성·위젯 회귀가 `Text` 캐스팅과 상태 문구 조회에서 실패했다. 시각적으로는 숨기되 테스트·접근성 상태 문자열을 유지하는 `Offstage` Text로 계약을 보정한다.
2026-08-02: `Offstage`는 기본 Finder가 숨은 하위 트리를 제외해 동일 회귀가 계속 실패했다. 레이아웃 높이를 0으로 줄인 투명 `Opacity` Text로 바꿔 화면에는 보이지 않지만 위젯·접근성 상태 계약을 유지한다.
2026-08-02: 투명 상태 문자열 보정 후 이전 테스트 하나가 속성 이전 뒤 힘 안내까지 숨겨진 것을 확인했다. 속성 이전이 완료되면 하단 힘 안내를 다시 노출하고, 속성 미선택 단계에서만 중복 안내를 접도록 조건을 좁힌다.
2026-08-02: 충돌·이동 이벤트 순서 보정과 튜토리얼 안내 축약 후 전체 Flutter 회귀 157개·정적 분석을 통과했다. 의도된 Golden 6개를 갱신하고 기존 PID 55374를 종료해 최신 Web release PID 90106으로 교체했으며, 390×844·768×1024 콘솔 오류 0건과 평균 16.666~16.667ms를 확인했다.
2026-08-02: 최종 통합 QA 표에 이전 156개 회귀 수치가 남아 있는 것을 확인했다. 역사적 반복 기록은 보존하되 최신 통합 섹션을 157개·PID 90106·현재 캡처로 명확히 분리한다.
2026-08-02: 최신 Web release에서 물리 전역 이벤트 정렬·첫 프레임 보조 방출·튜토리얼 안내 축약을 확인했고, Golden 6개와 전체 157개 회귀를 통과했다. 구현 결과·성능·현재 캡처·iOS 시뮬레이터 런타임 미설치를 QA 기록에 추가한다.
2026-08-02: 최신 구현 커밋 기준 `flutter build ios --no-codesign`을 재실행했다. Xcode 컴파일은 1.9초에 완료됐고, 배포 단계는 Development Team·Provisioning Profile 부족으로 실패했다. 서버 PID 90106은 루트·번들 HTTP 200으로 유지된다.
2026-08-02: 독립 UX QA에서 기존 결과 캡처의 과거 `파 3회` 표기를 현재 레벨 정의의 `파 2회`와 대조해 P1을 확인했다. 현재 `GameState` 기반 결과 팝업 Golden을 390×844·768×1024에 추가해 결과 화면도 최신 코드에서 재생성한다.
2026-08-02: 결과 Golden 첫 생성에서 테스트 호스트 폰트가 로드되지 않아 네모 글리프가 포함된 것을 확인했다. 결과 Golden 테스트에 NanumGothic 명시 로딩을 적용하고 캡처를 재생성한다.
2026-08-02: NanumGothic 명시 로딩으로 결과 팝업 Golden 두 해상도를 재생성하고, 전체 Flutter 회귀 159개 통과를 확인했다. 결과 캡처도 동일 기준 이미지로 동기화한다.
2026-08-02: 이전 데모 PID 90106을 종료하고 최신 Web release를 PID 16872로 교체했다. Playwright 캡처를 같은 서버에서 다시 생성해 두 해상도 모두 콘솔 오류 0건을 확인했다.
2026-08-03: 현재 플레이 캡처에서 방향 표시가 긴 단색 빨간 화살표로 남아 목표 문서의 개발용 조준 표시 제거 기준에 미달함을 확인했다. 물리 판정은 유지하고 큐 장력·점형 방향 마커 중심의 조준 가이드로 교체한다.
2026-08-03: 화면 증거 요구 해상도 390×844·393×852·430×932·768×1024·1024×1366을 한 번에 캡처할 수 있도록 Playwright 캡처 스크립트의 뷰포트·좌표 계산을 확장한다.
2026-08-03: 다음 작업을 재현할 수 있도록 현재 구현·검증·P1 위험·비협상 규칙·산출물 정의·commit/push 절차를 하나의 프롬프트 템플릿 문서로 정리한다.
2026-08-03: push 완료 후 데모 서버가 종료된 것을 확인해 최신 Web release를 다시 빌드하고 PID 95957로 교체했다. 루트와 main.dart.js HTTP 200을 재확인한다.
2026-08-03: 다음 목표 문서의 풍선·뾰족함·충돌 타격감·난이도 신뢰도 요구사항을 전체 확인했다. KST 08:00 시한 안에 기존 159개 회귀를 보존하면서 충돌 물리 P1, 신규 속성·스테이지, 충돌 피드백, QA 문서와 작업별 commit/push를 순서대로 진행한다. 현재 브랜치는 `commercial/wall-physics-qa`, 데모 서버 PID는 95957이다.
2026-08-03: 신규 도메인·물리·화면 연결 후 정적 분석이 통과했다. 다음 검증은 풍선의 일반 충돌·뾰족함 팝·소모·되감기, 속성 이전/복사, 타격감 지표 경계를 각각 독립 테스트로 고정하고 기존 공 연쇄에도 동일한 풍선 분기를 적용한다.
2026-08-03: 전체 회귀에서 4단계 확장으로 지도 경로의 3개 좌표 범위 오류와 기존 첫 챕터 분석 길이 계약을 확인했다. 지도는 4개 노드로 확장하고 `DifficultyAnalyzer.analyzeAll()`의 기존 3단계 기본 범위는 보존하며 신규 단계는 `analyzeLevel(3)`로 별도 검증한다.
2026-08-03: 기존 회귀 중 1·2단계 성공 영역이 새 접선 감쇠로 좁아진 것을 확인해 벽·문은 접선 속도를 보존하고 점착판·젤리·풍선만 재질별 감쇠를 적용하도록 조정했다. 기존 난이도·퍼즐·위젯 묶음은 다시 통과했다.
2026-08-03: 충돌 피드백 콜백에 실제 충격량을 연결하고 풍선 팝·연결 문 열림을 별도 이동 이벤트로 추가했다. 풍선 링크 매칭은 풍선 자체를 다시 열지 않도록 연결 대상 ID만 허용한다.
2026-08-03: 난이도 QA 문서를 갱신하는 과정에서 기존 3단계 분석 기록을 덮어쓴 것을 확인했다. 역사적 수치와 해석은 HEAD 원문으로 복원한 뒤 신규 4단계 분석 운영 규칙을 문서 끝에 추가한다.
2026-08-03: 독립 QA가 지적한 일반 공·풍선 실제 이동 누락을 확인했다. 직접 충돌에서도 풍선을 `_pushWithMomentum`으로 이동시키고, 팝 상태·이전 공 연쇄·초기화·이벤트 순서를 테스트로 보강한다.
2026-08-03: 신규 단계의 공통 목표 문구가 3단계 문구로 떨어지는 것을 확인했다. 4단계에는 풍선의 밀림·팝·우회 가능성을 명시한 별도 목표와 짧은 진행 안내를 연결한다.
2026-08-03: 신규 4단계 화면 증거가 없다는 QA 의견을 반영해 기존 플레이 Golden 범위를 4단계까지 확장한다. 기본 상태 Golden은 풍선·가시 성게·연결 문의 식별성과 한글 목표 문구를 검증한다.
2026-08-03: 다중 샷 분석 단독 실행이 41초로 완료되지만 기존보다 느려진 것을 확인했다. 연쇄 안전 상한을 엔티티 수의 8배에서 2배 기반으로 낮추고 `chain_safety_stop` 진단은 유지해 긴 연쇄와 분석 성능의 균형을 맞춘다.
2026-08-03: 현재 신규 테스트 10개와 기존 회귀를 합친 실행은 170개까지 진행되며, 다중 샷 분석 단독은 41초에 통과했다. QA 문서에는 확정된 통과 항목과 아직 실행하지 않은 Web·서버·다중 해상도 증거를 분리해 기록한다.
2026-08-03: 이전 Web 서버 PID 95957을 종료한 뒤 Web release를 재빌드하고 IPv4 명시 서버 PID 76155를 127.0.0.1:8080에 띄웠다. 루트와 `main.dart.js` HTTP 200을 동일 권한 curl로 확인했다.
2026-08-03: Python Playwright와 Chromium을 설치해 최신 서버에서 390×844·393×852·430×932·768×1024·1024×1366 홈·지도·플레이 15장을 캡처했다. 다섯 해상도 모두 콘솔 오류 0건이며 루트·번들 HTTP 200이다.
2026-08-03: 최종 `flutter test --reporter compact`가 00:51에 171개 전부 통과했다. `flutter analyze`와 `flutter build web --release`도 통과했으며, 현재 시각 01:52 KST 기준 목표 시한 전 작업을 종료할 수 있는 상태다.
2026-08-03: 일반 공·풍선 충돌 규칙 변경 요청을 반영한다. 직접 발사 분기에서 풍선을 이동시키던 처리를 제거하고, 풍선은 고정·고탄성 표면으로 취급하며 공의 충돌 직전 운동에너지가 클수록 반사 속도가 커지도록 회귀 테스트를 보강한다.
2026-08-03: 고정 풍선·공 반사 변경의 대상 테스트 7개와 정적 분석이 통과했다. 낮은 파워보다 높은 파워에서 풍선 충돌의 상대 법선 속도·충격량이 커지고, 풍선 위치는 변하지 않는 계약을 확인했다.
2026-08-03: 전체 Flutter 회귀가 00:01:02에 172개 전부 통과했다. 일반 공·고정 풍선 반사 변경과 신규 고파워 충돌 테스트까지 기존 물리·화면 회귀에 포함해 확인한다.
2026-08-03: 이전 데모 서버를 종료하고 최신 Web release를 다시 띄웠다. 새 서버 PID는 20335이며 127.0.0.1:8080 루트와 `main.dart.js`가 모두 HTTP 200이다.
2026-08-03: 신규 목표의 역할 매뉴얼 활성화 조건을 먼저 정리한다. 웹 검색으로 Apple HIG·Material 3·WCAG·Flutter·Flame·게임 접근성·Creative Commons·Kenney 자료를 조사하고, 각 역할별 업무·산출물·판단 기준·금지사항·참고자료를 `harness_docs/manuals/`에 추가한 뒤 교차 검토와 역할 활성화 기록을 남긴다.
2026-08-03: 역할별 매뉴얼 18종, 외부 참고자료 색인, 상용 게임 실천 비교표, 에이전트 활성화 게이트를 추가했다. 다음으로 UX 문구 산출물·권리 추적·교차 검토를 연결하고 링크·문서 구조를 검증한다.
2026-08-03: UX 문구 인벤토리·용어 가이드·결정 기록과 오브젝트 시각 품질 감사 기준을 추가했다. 현재 목표 프롬프트와 하네스 색인에서 역할 매뉴얼을 작업 시작점으로 연결한 뒤 문서 전용 검증을 수행한다.
2026-08-03: 역할 매뉴얼을 현재 목표의 선행 단계로 명시하는 재사용 프롬프트와 하네스 색인 링크를 추가한다. 외부 참고자료는 설계 원칙으로만 사용하고 최종 판정은 저장소의 결정론 테스트·Golden·QA 증거로 제한한다.
2026-08-03: 교차 검토에서 활성화 게이트 감사 필드, 대체 풀이 정량 기준, 실제 자산 레지스트리, 오브젝트 상태·피벗 수치 계약, 다섯 해상도 시각 감사 범위가 부족한 P1으로 확인됐다. 문서 단계에서 먼저 보완하고 구현 활성화 전 재검토한다.
2026-08-03: Epicurus·Hooke·Newton·Lorentz의 독립 교차 검토를 수집했다. 활성화 게이트 감사성·최신 기준 수치·접근성·성능 임계값·자산 권리와 상태 계약을 보완했으며, 물리 이벤트와 연출 이벤트의 구조화된 연결 및 `chain_safety_stop` 진단은 구현 단계의 P0로 남겨 활성화를 차단한다.
2026-08-03: 교차 검토 문서와 구현 전 P0/P1 백로그를 추가하고, QA·접근성·성능 매뉴얼에 실행 명령과 판정 임계값을 보강했다. 다음은 색인 링크·문서 구조·권리 레지스트리·활성화 상태를 최종 검증하고 Phase 0 문서 commit을 만든다.
2026-08-03: 첨부 Goal 전체를 다시 감사해 Phase 0 이후의 구현 순서를 재개한다. `ShotImpact`와 `ShotAnimationMove`를 결정론적 `PhysicsEvent` 스트림으로 연결하고, `chain_safety_stop`에 반복 수·잔여 거리·잔여 속도·중단 대상 진단을 추가한 뒤 이벤트 ID·부모 관계·30/60/120Hz 순서를 회귀 검증한다.
2026-08-03: `PhysicsEvent` 스트림을 추가해 충돌·이동·연쇄 안전 종료를 하나의 결정론 이벤트 순서로 노출했다. 기존 콜백 호환성은 유지하고, 이벤트 ID·부모 관계·관찰된 후속 속도·중복 없는 30/60/120Hz 재생을 대상 테스트와 정적 분석으로 확인했다.
2026-08-03: 물리 이벤트 스트림 변경 후 전체 Flutter 회귀 174개, `flutter analyze`, `flutter build web --release`가 통과했다. 이전 데모 PID 20335를 종료하고 최신 Web release를 PID 39167로 교체했으며 루트·번들 HTTP 200을 확인한다.
2026-08-03: Phase 1·2 독립 진단을 시작한다. UX Writer 에이전트와 레벨·아트·QA·물리 역할에게 전체 한글 문구, 스테이지4 풍선→문 인과, 우회 풀이, 팝 전후 Golden·PhysicsEvent 증거를 각각 감사하도록 요청했다.
2026-08-03: 스테이지4 물리·연출 인과를 재검토한 결과 풍선 팝 직후 문을 직접 여는 구조가 시각 이벤트보다 앞서 실행되는 문제가 확인됐다. 풍선 뒤 연결 스위치를 실제 충돌로 작동시킨 뒤 문을 여는 구조와 우회 풀이 보존을 구현한다.
2026-08-03: 스테이지4 계약 변경 후 기존 풍선 회귀가 팝 즉시 문 열림을 기대하는 것으로 확인됐다. 풍선 팝·스위치 노출·스위치 충돌·문 개방을 각각 검증하는 통합 테스트로 교체한다.
2026-08-03: 스테이지4 배치를 조정해 풍선 뒤 스위치가 팝 후 잔여 이동선에 놓이도록 했다. 통합 회귀에서 `balloon_popped → balloon_switch_revealed → balloon_switch_pressed → gate open` 순서와 뾰족함 없는 우회 성공을 확인했다.
2026-08-03: 화면 Golden 비교에서 의도한 렌더링 변경과 낡은 기준 이미지 차이를 분리 확인했다. 스테이지4 신규 문구·풍선·문·숨은 스위치 배치를 반영한 390×844·768×1024 기준 이미지를 갱신한다.
2026-08-03: Golden 검증 범위를 목표 문서의 5개 해상도로 확장한다. 기본 상태 5해상도와 별도 스테이지4 팝·스위치·문·홀 상태 fixture를 준비해 시각 인과를 고정한다.
2026-08-03: 5개 해상도 기본 Golden 20개가 생성·통과했다. 스테이지4의 시작·팝 직후·스위치/문 열림·홀 포획·결과 팝업을 별도 화면 fixture로 고정한다.
2026-08-03: 스테이지4 상태 Golden 25개(5상태×5해상도)가 통과했다. 새 fixture의 미사용 import와 문자열 표기 정적 분석 경고 2건을 제거한다.
2026-08-03: 상태 Golden 시각 검토에서 홀 포획 공이 과도하게 축소돼 인식성이 낮은 점을 확인했다. 포획 공의 노출 크기를 키우고 목표 깃발을 문과 구분되는 금색으로 조정한다.
2026-08-03: UX Writer P1 잔여 항목 중 전체 화면 장착 후 안내와 복사 실패 문구를 확인했다. 공을 장착한 뒤에는 즉시 발사 행동을 보여주고, 복사 횟수 소진 문구는 결과와 선택지를 분리한다.
2026-08-03: Epicurus 최종 레벨 검토를 반영한다. 풍선→스위치→문은 추천 경로로 유지하되 필수 조건으로 만들지 않고, 뾰족함·우회 경로의 성공 영역·각도 연속성·힘 폭을 별도 측정한다.
2026-08-03: 레벨 정량 기준을 실제 4단계에도 적용하기 위해 난이도 보고 도구의 신규 단계 포함 옵션과 4단계 고해상도 출력 항목을 추가한다. 뾰족함 추천 경로와 무속성 우회 경로를 분리 기록한다.
2026-08-03: 4단계 난이도 분석에서 고해상도 성공 영역이 뾰족함·우회 모두 55셀, 연속 각도 4도로 좁게 나타났다. 정답 궤적을 노출하지 않고 홀·스위치의 허용 폭과 목표 위치를 조정해 입력 신뢰도를 개선한다.
2026-08-03: 4단계 조정 후 성공 영역이 78셀·연속 각도 6도로 개선됐지만 입력 여유가 여전히 좁다. 홀과 스위치의 시각 비율을 해치지 않는 범위에서 한 차례 더 판정 폭을 넓힌다.
2026-08-03: 홀 판정 폭 조정만으로는 4단계 성공 폭이 늘지 않아 병목이 중간 상호작용 배치임을 확인했다. 풍선 학습을 방해하는 장식 상자를 주 진입선에서 멀리 옮겨 대체 경로 폭을 다시 측정한다.
2026-08-03: 상자를 주 진입선에서 이동한 뒤 4단계 고해상도 지표가 뾰족함 26도·62%·295셀, 무속성 우회 12도·54%·106셀로 개선됐다. 두 경로 모두 복제 코어 없이 성공하며 분석 기반 파 2회와 단계 설정을 맞춘다.
2026-08-03: 최종 4단계 고해상도 지표를 확정했다(무속성 126셀·12도·64%, 뾰족함 319셀·26도·70%). 풍선은 일반 충돌과 연쇄에서도 위치를 유지하고, 충돌 순간에만 눌림 시각 상태를 재생하도록 보강한다.
2026-08-03: UX 문구 축약 후 복사 제한 회귀가 역사적 표현 `모두 사용했습니다`를 계약으로 확인했다. 문장 분리 원칙은 유지하면서 해당 의미 표현을 호환 복원한다.
2026-08-03: 전체 회귀에서 UI 문구를 직접 고정한 과거 테스트 4건, 공 속성 제목 중복 매칭 1건, 클리어 팝업 Golden 2건을 확인했다. 새 한글 문구 계약과 의미별 팝업 제목에 맞춰 테스트를 갱신하고 Golden을 재생성한다.
2026-08-03: UI 회귀·Golden 갱신 후 비다중샷 전체 212개와 다중샷 단독 1개가 모두 통과했다. `flutter analyze`와 `flutter build web --release`도 통과했으며, 현재 수치와 남은 실기기·법무·플레이테스트 범위를 역할 교차 검토 문서에 기록한다.
2026-08-03: 이전 데모 서버 PID 39167을 종료하고 최신 Web release를 127.0.0.1:8080에 PID 44882로 교체했다. 루트와 `main.dart.js` HTTP 200을 확인하고 런타임 PID 기록을 갱신한다.
2026-08-03: 첨부 Goal의 산출물 목록을 현재 문서 트리와 대조한 결과, 역할 매뉴얼·참고자료는 존재하지만 일부 설계·에셋·QA·최종 보고 문서가 다른 이름으로 흡수되어 있었다. 기존 기록을 덮어쓰지 않고 요구된 이름의 근거 문서와 상호 링크를 추가한다.
2026-08-03: 누락 산출물 문서와 Goal 완료 감사표를 추가한 뒤 모든 로컬 Markdown 링크, 역할 매뉴얼 필수 절·URL, 비다중샷 212개, 다중샷 1개, `flutter analyze`, `flutter build web --release`를 다시 통과시켰다.
2026-08-03: 문서 커밋 후 이전 데모 서버 PID 44882를 종료하고 최신 Web release를 PID 67394로 다시 띄웠다. 127.0.0.1:8080 루트와 `main.dart.js` HTTP 200을 확인해 최종 서버 증거를 갱신한다.
2026-08-03: 사용자 흐름 점검에서 섬 지도 카드가 3개만 렌더링되어 4단계 설명·선택이 사라진 것을 확인했다. 메인 메뉴의 고정 속성 목록은 제거하고, 지도 카드를 단계 목록에서 동적으로 렌더링하며 저장된 클리어 해금 상태와 4단계 선택을 회귀 검증한다.
2026-08-03: 4단계 지도 카드 추가 후 기본 800×600 위젯 뷰포트에서 하단 안내 카드가 지연 생성되는 테스트 한 건을 확인했다. 지도는 스크롤 가능한 구조이므로 안내 카드까지 스크롤하는 검증을 추가하고, 390×844·768×1024 Golden은 새 카드와 레이아웃을 반영해 갱신한다.
2026-08-03: 메인 메뉴 속성 목록 제거로 홈 Golden 2건이 의도적으로 달라졌다. 기존 기준 이미지를 갱신하고 전체 회귀에서 지도·해금·클리어 흐름과 함께 확인한다.
2026-08-03: 4단계 지도 카드·설명·해금 회귀와 메인 메뉴 정리 후 비다중샷 213개, 다중샷 1개, `flutter analyze`, `flutter build web --release`를 통과했다. 기존 데모 서버 PID 67394를 종료하고 최신 빌드를 PID 4151로 교체했으며 루트와 `main.dart.js` HTTP 200을 확인한다.
2026-08-03: 섬 지도 해금 키와 게임 화면 진행 키가 `property_shot_unlocked_level`·`unlocked_level`로 분리된 문제를 확인했다. 단계별 클리어 기록을 로컬 저장하고 두 키를 마이그레이션해 연속 클리어 기준으로 지도를 복원하는 회귀를 추가한다.
2026-08-03: 단계별 로컬 클리어 기록과 기존 해금 키 호환을 구현한 뒤 비다중샷 215개, 다중샷 1개, `flutter analyze`, `flutter build web --release`를 통과했다. 이전 데모 서버 PID 4151을 종료하고 최신 빌드를 PID 85251로 교체했으며 루트와 `main.dart.js` HTTP 200을 확인한다.
2026-08-03: 최종 상용화 품질 실험 계획을 대조한 결과, 코드 기준은 4단계·비다중샷 215개·다중샷 1개지만 일부 문서가 과거 3단계·159개 수치를 유지하고 있었다. 최신 기준선 문서, 초기 GameState 스냅샷 도구, 저장 키 표를 추가하고 자동 검증과 실기기·사용자 검증을 구분해 기록한다.
2026-08-03: 초기 GameState 스냅샷 도구가 CLI JSON을 출력하는 의도된 `print` 때문에 분석 정보 진단을 냈다. 도구 파일에 예외 주석을 추가하고 스냅샷 JSON의 단계 수를 자동 확인한다.
2026-08-03: 저장·해금 실험을 위해 진행·최고 기록·추가 도전·복제 코어를 하나의 버전 계약으로 읽고 정제하는 `ProgressStore`를 추가한다. 구버전 키와 손상 문자열은 안전한 기본값으로 복원하고, 마이그레이션은 반복 실행해도 같은 결과를 내도록 검증한다.
2026-08-03: 저장 계약 첫 컴파일에서 손상 정수 키의 nullable 처리와 단계 목록 길이의 비상수 생성자 사용 문제가 발견됐다. 기본값 병합과 런타임 저장소 인스턴스로 수정한 뒤 저장 회귀를 재실행한다.
2026-08-03: 저장 계약 회귀 5개와 기존 위젯 48개가 통과했다. 다음은 동일 입력 반복 서명을 추가해 최종 상태·충돌 이벤트·연쇄 이벤트의 결정론과 벽 불변성을 함께 고정한다.
2026-08-03: 대표 단일샷 32개 입력을 각각 100회 반복하고 속성별 샷·벽 불변성을 검증하는 결정론 회귀 3개가 통과했다. 다음은 한국어 표시 유형을 유지하면서 로컬 계측에 안정적인 내부 이벤트 코드와 물리 필드를 추가한다.
2026-08-03: 진행 저장 메서드가 전체 스냅샷을 다시 쓰는 구조라 클리어·최고 기록·복제 코어 비동기 저장이 서로 덮어쓸 수 있는 P0 위험을 확인했다. 이후 기록 메서드는 저장 버전과 변경된 키만 갱신하고, 전체 쓰기는 초기 마이그레이션에만 사용하도록 수정한다.
2026-08-03: 저장 키 단위 갱신 후 비다중샷 224개, 다중샷 1개, `flutter analyze`, `flutter build web --release`를 통과했다. 이전 데모 서버 PID 85251을 종료하고 최신 빌드를 PID 96501로 교체했으며 루트·`main.dart.js` HTTP 200과 새 번들 체크섬을 확인한다.
2026-08-03: 순수 물리 벤치마크 최신 평균은 1단계 360.3µs, 2단계 287.9µs, 3단계 303.5µs, 4단계 330.0µs였다. `flutter build ios --no-codesign`은 Xcode 컴파일 후 Development Team·프로비저닝 프로파일 부족으로 배포 단계가 중단됐다. 다음은 대상 타입별 충돌 조합 회귀를 추가한다.
2026-08-03: 최신 Web 데모를 390×844·393×852·430×932·768×1024·1024×1366에서 홈·지도·플레이로 캡처했고 다섯 해상도 모두 Chromium 콘솔 오류 0건이었다. 390×844 지도에서 4개 카드, 4단계 설명, 잠금 상태, 안내 카드의 화면 배치를 시각 확인한다.
2026-08-03: 최종 실험 계획의 필수 계측 이벤트와 실제 GameScreen 발생 지점을 대조했다. 물체 확인·속성 이전 대상·홀·점착·스위치·문·풍선 상태가 일반 연쇄 이동으로 뭉쳐 기록되는 누락을 확인해 이벤트별 기록과 회귀를 추가한다.
2026-08-03: 계측 이벤트를 물체 확인·속성 이전 대상 보존·물리 애니메이션 상태별 이벤트·홀 포획으로 연결하고 필수 코드 회귀를 통과했다. 다음은 계획에서 요구한 물리·기기·플레이테스트·출시 후보 문서를 자동 증거와 미검증 범위로 분리해 남긴다.
2026-08-03: 계측 변경 후 `flutter analyze`, 비다중샷 225개, `multi_shot_analyzer_test.dart`, 물리 벤치마크, Web Release를 다시 확인했다. 기준선 문서는 최신 커밋·테스트 수·번들 체크섬과 현재 데모 서버 교체 증거를 반영한다.
2026-08-03: 기존 Web 데모 PID 96501을 종료하고 최신 Web Release를 PID 33606으로 교체했다. 다섯 해상도 홈·섬 지도·플레이 캡처에서 Chromium 콘솔 오류 0건, 4단계 지도 카드·잠금·한글 UI·입체 물체·홀 깃발·조준 UI의 비겹침을 확인한다.
2026-08-03: 필수 계측 목록을 재대조해 재시도·속성 행동 취소·단계 종료·힌트 노출이 실제 UI 흐름에서 일부 누락된 것을 확인했다. 되감기·팝업 닫기·지도 복귀·튜토리얼 대상 노출 지점에 이벤트를 연결한다.
2026-08-03: 재시도·속성 행동 취소·단계 종료·힌트 노출 계측을 연결한 뒤 대상 테스트 51개와 전체 비다중샷 회귀 225개, `flutter analyze`를 통과했다. 최신 코드 커밋 후 Web 서버도 다시 교체한다.
2026-08-03: 기존 Web 데모 PID 33606을 종료하고 최신 계측 코드 번들을 PID 48075로 교체했다. 다섯 해상도 캡처에서 다시 Chromium 콘솔 오류 0건을 확인했으며 `main.dart.js` 체크섬은 `5c34194b...`이다.
2026-08-03: 계측 위젯 회귀가 단계 시작·속성 이전만 확인하던 범위를 넓혀 실제 힌트 노출·물체 확인·속성 패널 닫기·원본 ID와 속성 이전 이벤트를 검증하도록 보강한다.
2026-08-03: Phase 0·1의 대표 리플레이 픽스처 요구를 현재 파일 목록과 대조한 결과 결정론 서명 테스트는 있으나 저장된 입력·예상 결과 파일이 없었다. 단계별 단일샷 성공·실패 JSON 픽스처와 재생 검증기를 추가한다.
2026-08-03: 단계별 단일샷 리플레이 픽스처 16개와 안정적 FNV 지문 재생기를 추가했다. 재생 테스트가 4단계 성공·실패 입력과 예상 phase·물리 결과를 다시 확인한다.
2026-08-03: 저장 리플레이 픽스처 추가 후 전체 회귀 기준과 QA 증거 문서의 테스트 수·커밋 기준을 226개 및 55f7129로 갱신한다.
2026-08-03: 저장 리플레이 기준선 문서를 갱신한 뒤 지정 비다중샷 회귀 226개와 승인 환경 `flutter analyze`가 통과했다. 이전 검증 문서의 Web 번들 체크섬을 현재 서버 기준으로 맞춘다.
2026-08-03: QA 문서 기준 커밋 줄의 마크다운 줄바꿈 공백이 `git diff --check`에 걸려 공백을 정리한다.
2026-08-03: 기존 Web 데모 PID 48075를 종료하고 Web Release를 다시 빌드했다. 새 PID 76285에서 루트와 `main.dart.js` HTTP 200을 확인해 기준 문서의 최신 서버 상태를 갱신한다.
2026-08-03: 최신 독립 QA가 스테이지4의 풍선 팝·스위치 노출·문 개방·홀 포획을 문자열과 사후 이동 추론에 의존하는 P1 위험으로 지적했다. 물리 계산 중 상태 전이 이벤트를 직접 수집하고 실제 4단계 재생 순서를 검증한다.
2026-08-03: 상태 전이 이벤트 도입으로 기존 리플레이 지문 불일치가 발생했지만 물리·결정론 회귀는 나머지 모두 통과했다. 스테이지4 종단간 테스트가 상태 전이 이벤트의 순서와 최종 홀 성공까지 직접 확인하도록 보강한다.
2026-08-03: `PhysicsStateTransition`을 물리 판정 중 직접 생성하도록 연결했다. 팝·속성 소모·스위치 노출·스위치 작동·문 개방·홀 포획을 이벤트 스트림에 포함하고, 스테이지4 종단간 회귀와 저장 리플레이 지문을 갱신한다.
2026-08-03: 기존 물리 이벤트 스트림 테스트가 홀 포획 상태 전이 1개 추가를 감지해 기대 이벤트 수에서 실패했다. 이벤트 종류별 검증으로 기대값을 확장하고 상태 전이 포함 계약을 고정한다.
2026-08-03: 독립 QA 재검토에서 기존 스테이지4 순서 테스트가 실제 홀 이벤트를 직접 요구하지 않는 P0 공백을 확인했다. 실제 `levels[3]` 입력을 탐색하는 종단간 홀 포획 회귀를 추가한다.
2026-08-03: 스테이지4 종단간 테스트 첫 컴파일에서 좌표 타입 `Vec2` import 누락을 발견했다. 테스트 파일에 도메인 기하 import를 추가한다.
2026-08-03: 실제 `levels[3]`를 사용하는 `stage4_end_to_end_test.dart`가 풍선 팝·뾰족함 소모·스위치 노출·스위치 충돌·문 개방·홀 포획과 포획 후 추가 충돌 없음까지 통과했다.
2026-08-03: 효과음·진동 설정에 화면 흔들림·저모션 저장 키와 실제 Flame 렌더 피드백을 연결했다. 다음으로 설정 토글과 재실행 복원 회귀를 추가한다.
2026-08-03: 접근성 문서의 실제 형식이 예상과 달라 일괄 갱신을 분리한다. 효과음·진동·화면 흔들림·저모션 저장·복원은 자동 통과로 기록하고 VoiceOver·TalkBack·실기기 체감은 잔여로 남긴다.
2026-08-03: 최종 실험 계획의 다중샷 대표 리플레이 20개 요구와 현재 분석기 예시·단일샷 16개를 대조했다. 분석기 결과를 저장 가능한 입력·지문 픽스처로 변환하는 별도 다중샷 재생 하네스를 추가한다.
2026-08-03: 4개 스테이지에서 다중샷 대표 리플레이 20개를 생성하고, 각 샷의 입력·예상 물리 지문·최종 상태를 저장했다. 이전 샷의 물리 상태를 다음 샷에 전달하는 재생 회귀가 통과했으며, 성공 경로만 강제하지 않는 직접·복사·대체 경로 태그를 함께 보존한다.
2026-08-03: 전체 `flutter test` 231개는 통과했지만 정적 분석에서 다중샷 테스트의 빈 목록 검사와 픽스처 생성기의 미사용 import가 발견됐다. 새 하네스 범위에 맞게 진단을 제거하고 분석을 다시 고정한다.
2026-08-03: 다중샷 하네스 진단 수정 후 전체 `flutter test` 231개, `flutter analyze`, 다중샷 재생·분석 회귀가 통과했다. 기존 Web 서버 PID 76285를 종료하고 Web Release를 PID 28891로 교체했으며 루트·번들 HTTP 200과 새 번들 체크섬을 확인한다.
2026-08-03: 최종 실험 계획의 디버그 빌드 A/B 조건군 선택이 코드에 없었다. 릴리스에는 노출하지 않는 안내형·행동 유도형·무설명형 튜토리얼 플래그와 선택 UI·세션 계측을 추가하고 조건별 힌트 노출을 비교 가능하게 만든다.
2026-08-03: 디버그 조건 선택기 위젯 회귀에서 테스트의 `Key` import 누락을 확인했다. Flutter 기본 키 타입 import를 보완한 뒤 선택기 열기·한글 조건 표시·무설명형 선택 닫기를 재검증한다.
2026-08-03: 디버그 튜토리얼 조건군 추가 후 전체 `flutter test` 233개와 `flutter analyze`가 통과했다. 기존 Web 서버 PID 28891을 종료하고 최신 Release를 PID 47399로 교체했으며 루트·번들 HTTP 200과 `5135a6a0...` 체크섬을 확인한다.
2026-08-03: 단계별 다중샷 픽스처를 점검한 결과 기존 20도·5단계 격자는 2단계와 4단계의 실제 2발 경로를 놓치고 있었다. 순수 `ShotResolver` 정밀 탐색에서 네 단계 모두 2발 성공 입력을 찾았으므로 검증된 시드를 생성기에 보존하고 단계별 2발 존재 조건을 회귀에 추가한다.
2026-08-03: 정밀 전수 격자는 탐색량이 과도해 중단하고, 순수 `ShotResolver`로 검증한 네 단계 2발 시드를 생성기에 추가했다. 20개 픽스처 재생과 단계별 2발 조건이 통과했으며 기준 커밋은 `7b775ab`로 갱신한다.
2026-08-03: 8080 데모 서버를 다시 시작해 기존 PID 47399를 종료하고 PID 67695로 교체했다. 승인된 HTTP 확인에서 루트·번들 모두 200이며 Web Release 번들에는 개발 전용 튜토리얼 조건 라벨이 포함되지 않는다.
2026-08-03: 최종 계획의 실험용 디버그 메뉴 요구와 현재 구현을 대조해 튜토리얼 조건 선택기 외에 저장·단계·복제 코어·물리 이벤트·법선·히트박스·통계 관찰 기능이 누락된 것을 확인했다. 릴리스에는 노출하지 않는 진단 패널을 추가한다.
2026-08-03: 디버그 메뉴 첫 분석에서 `TraitType` 한글 라벨 확장 import 누락과 불필요한 문자열 중괄호를 발견했다. 진단 표시의 컴파일 오류와 정적 경고를 정리한다.
2026-08-03: 개발 진단 메뉴의 단계 이동·진행 초기화·복제 코어·속성 강제 장착·히트박스·법선·ID·프레임 통계·이벤트 복사 진입을 위젯 회귀로 고정한다.
2026-08-03: 진단 메뉴 위젯 회귀가 Flame의 지속 펄스 프레임 때문에 `pumpAndSettle` 타임아웃을 냈다. 게임 화면 테스트를 고정 시간 프레임 펌프로 바꿔 메뉴 의미를 검증한다.
2026-08-03: 진단 메뉴 회귀에서 긴 하단 패널의 히트박스 토글이 600px 테스트 화면 밖에 있어 탭되지 않았다. 테스트가 대상까지 스크롤한 뒤 토글하고 시스템 뒤로가기로 닫도록 보강한다.
2026-08-03: 모달 하단 시트의 Flutter 테스트 좌표가 실제 화면 밖으로 변환되어 스크롤·탭 회귀가 불안정했다. 메뉴 항목과 닫기 버튼의 구조 회귀로 범위를 조정하고 토글 상태는 게임 객체 API로 검증한다.
2026-08-03: 개발 진단 메뉴와 물리 오버레이를 `9c59cd6`으로 커밋했다. 전체 Flutter 테스트 235개와 정적 분석이 통과했으며, 기존 Web 데모 PID 67695를 종료하고 Release 서버 PID 1573으로 교체했다. 루트 HTTP 200과 최신 번들 체크섬 `73d1dba6...`을 확인했고 Release 번들에서 개발 메뉴 문구가 검색되지 않는다.
2026-08-03: 최종 실험 명세와 개발 메뉴를 재대조해 원본 속성 제거·복원, 질량·속도·운동량·Shot/Collision ID 표시, 사운드·햅틱 토글, 리플레이 녹화·재생이 빠진 것을 확인했다. 일반 게임 규칙은 유지한 채 Debug 전용 상태 조작과 관찰 기능으로 보강한다.
2026-08-03: 진단 메뉴의 물리량 표시에서 영어 `Shot ID`·`Collision ID`와 이벤트 종류명이 노출될 수 있음을 확인했다. 개발 화면도 사용자 언어 원칙에 맞춰 식별자·상태 종류의 한글 표기로 정리한다.
2026-08-03: `beaece2` 개발 진단 보강 커밋을 Push하고 기존 Web PID 1573을 종료한 뒤 Release 서버 PID 29875로 교체했다. 전체 회귀 235개·정적 분석·Web Release가 통과했으며 최신 번들 체크섬은 `19afb4a6...`이고 Release 번들 개발 문구 검색 결과는 0건이다.
2026-08-03: 최신 Release Web에서 단계4를 실제 좌표로 진입해 속성 팝업·속성 이전·조준·충전·발사 후 충돌 프레임을 재현했다. 동일 흐름을 반복할 수 있도록 390×844 단계4 증거 캡처 스크립트와 콘솔 오류 JSON을 추가한다.
2026-08-03: 단계4 실제 발사 캡처에서 `Bad state: No element` 콘솔 오류를 발견했다. 성공 시 `active_ball`이 `spent_ball`로 대체된 뒤 축약 HUD가 `state.activeBall`을 강제 조회하는 경로를 확인해 nullable 조회와 성공 상태 렌더 회귀를 추가한다.
2026-08-03: HUD nullable 수정 후에도 단계4 풍선 팝 애니메이션 콜백에서 같은 예외가 재현됐다. 성공 상태의 지연된 속성 소모 telemetry가 `active_ball`을 강제 조회하는 두 번째 경로를 찾아 보존된 공 식별자로 대체한다.
2026-08-03: `capture_stage4_web_evidence.py`를 수정된 PID 54628 Release 서버에서 재생해 단계4 시작·팝업·속성 이전·조준·충전·충돌·결과 8장을 생성했고 콘솔 오류 0건을 확인했다. 이전 오류 캡처는 증거로 사용하지 않고 최종 JSON은 빈 오류 목록만 보존한다.
2026-08-03: 단계4 예외 수정과 실제 Web 증거를 각각 `07ef7b3`, `120742a`로 커밋·Push했다. 최신 Release 번들 체크섬은 `768617dd...`, 서버 PID는 54628이며 전체 회귀 재실행 전 기준선 문서를 최신 커밋으로 맞춘다.
2026-08-03: 단계4 Web 실제 조작 증거와 성공 상태 예외 수정을 최신 기준선에 반영하기 위해 QA 문서의 커밋·서버·체크섬·미검증 범위를 갱신한다.
2026-08-03: 최신 성공 상태 회귀를 포함한 전체 `flutter test`가 236개 모두 통과했다. 기존 QA 문서의 235개 기준을 236개로 정정하고 단계4 Web 증거와 함께 문서 커밋한다.
2026-08-03: 최신 `difficulty_report.dart`를 4단계·다중샷 포함으로 재실행해 4단계 성공률 10.69%, 파 2회, 무속성 우회·뾰족함 경로를 확인했다. README와 난이도 문서의 과거 3단계·8.96% 표기를 최신 분석 결과로 정정한다.
2026-08-03: 최신 문서 커밋까지 반영된 작업 트리가 clean인데 기준선에 `QA 산출물·시각 캡처 커밋 전`이 남아 있는 시간축 불일치를 확인해 현재 문서·원격 상태로 정정한다.
2026-08-03: 기준선 문서의 마크다운 강제 줄바꿈 공백이 `git diff --check`에 걸려 내용을 유지한 채 공백을 제거한다.
2026-08-03: 저장 회귀가 같은 `ProgressStore` 인스턴스의 연속 호출만 검증하고 있어 앱 재실행 복원을 직접 고정하는 새 인스턴스 회귀를 추가한다.
2026-08-03: 새 `ProgressStore` 인스턴스의 앱 재실행 복원 회귀를 추가한 뒤 전체 `flutter test` 237개가 통과했다. 저장·해금·복제 코어 근거와 최신 테스트 수를 QA 문서에 반영한다.
2026-08-03: Android Debug 빌드가 unsupported Gradle project로 중단된 원인을 확인했다. 저장소에 Android 플랫폼 호스트가 없어 Flutter 표준 Android 프로젝트를 추가해 모바일 컴파일 게이트를 복구한다.
2026-08-03: Android Debug APK와 Release APK 컴파일에 성공했다. Flutter 플랫폼 생성이 `.metadata`의 기존 iOS·Web 항목을 덮어쓴 것을 확인해 기존 플랫폼 이력을 보존하고, APK 컴파일과 실기기 실행 검증을 별도로 기록한다.
2026-08-03: 연결된 물리 장치는 없고 Pixel 3 API 30 AVD는 x86 시스템 이미지인데 현재 Apple Silicon Emulator에는 x86 QEMU가 없어 기동되지 않았다. APK 컴파일 성공과 Android 런타임 미검증을 분리해 기록한다.
2026-08-03: Apple Silicon 호환 ARM64 Android API 28 에뮬레이터에서 Release APK를 설치·실행하고 홈·1단계·무거운 돌 정보 팝업·속성 옮기기 후 공 상태를 실제 입력으로 확인했다. 앱 치명적 예외는 없었으며 화면 증거와 런타임 한계를 별도 QA 문서에 추가한다.
2026-08-03: 기존 Web 데모 PID 54628을 종료하고 최신 Release를 다시 빌드해 PID 91916으로 8080에 교체했다. 루트와 `main.dart.js` 모두 HTTP 200이며 데모 서버를 유지한다.
2026-08-03: 원문 요구사항과 Debug 화면을 다시 대조하는 중 `anvil`·`spike_source` 같은 내부 물체 ID가 진단 메뉴에 그대로 노출되는 한글 UX 결함을 확인했다. 물리 식별자는 유지하되 화면 표시명만 한글로 변환하는 공통 라벨러와 회귀를 추가한다.
2026-08-03: Release APK를 Android ARM64 API 28 에뮬레이터에서 전체 해금 상태로 재생해 지도 `4 / 4`, 4단계 카드·설명, 뾰족함 팝업·속성 이전·방향 설정·45% 충전·자동 발사·홀 성공·클리어 팝업을 실제 입력으로 확인했다. 1080×1920 캡처와 치명적 예외 0건을 실기기 성능과 분리해 기록한다.
2026-08-03: Debug ID 한글화 반영 후 Web Release와 Android Release APK를 재빌드했다. Web 번들 체크섬은 기존 기능 기준과 동일하고, 기존 서버 PID 91916을 종료한 뒤 PID 40530으로 교체해 루트·번들 HTTP 200을 확인했다.
2026-08-03: 원문 실험 계획과 최신 증거를 다시 대조해 오래된 최종 감사·커밋·잔여 위험 문서를 현재 테스트 237개, Android 단계4 스모크, Web PID 40530 기준으로 갱신한다.
2026-08-03: 최신 전체 `flutter test`가 다중샷 분석 종료까지 `238개` 모두 통과했다. 최신 감사 문서의 현재 수치를 238개로 정정하고 이전 237개 기록은 역사적 실행 기준으로 보존한다.
2026-08-03: QA 교차 검토에서 Debug Canvas·클립보드의 내부 영문 ID, 좁은 화면 HUD 말줄임, 생성 자산 해시 범위 부족을 확인했다. 사용자 언어 표시·접근성·권리 증빙을 보강한다.
2026-08-03: Debug Canvas·클립보드 한글화와 좁은 화면 코치마크·터치 의미 영역을 반영했다. 팝업 입력 차단으로 변경된 Golden을 갱신했고 위젯 회귀 49개가 통과했다.
2026-08-03: 재질별 물리 수치 게이트를 보강하기 위해 벽 반사·젤리 반발·점착 정지·질량 차이·충돌 법선 결과를 확인하는 순수 `ShotResolver` 회귀를 추가한다.
2026-08-03: 클리어 직후 저장 순서를 보강해 단계가 이미 UI에서 해금되어 있어도 `ProgressStore`에 클리어·보너스·최고 기록을 먼저 기록한 뒤 외부 해금 콜백을 호출하도록 정리한다.
2026-08-03: 한글 줄바꿈·팝업 입력 차단·물리 수치·클리어 저장 회귀를 포함한 Golden 갱신 후 전체 `flutter test` 244개가 통과했다.
2026-08-03: 기존 Web PID 40530을 종료하고 최신 Web Release를 PID 95164로 교체해 루트·번들 HTTP 200을 확인했다. 최신 Android Release APK 57.3MB를 ARM64 에뮬레이터에 설치·실행했고 앱 PID 6769와 치명적 예외 0건을 확인한다.
2026-08-03: 저장·해금 통합 검토에서 동일 `ProgressStore` 인스턴스의 동시 기록 손실 위험을 확인했다. 모든 영속 작업을 순차화하는 쓰기 큐와 동시 클리어·최고 기록 회귀를 추가한다.
2026-08-03: `ProgressStore`의 클리어·최고 기록·보너스·복제 코어·초기화·해금 작업을 인스턴스별 쓰기 큐로 순차화하고 동시 기록 회귀를 추가했다. 전체 테스트 245개, 분석, Web·Android Release 빌드를 통과했으며 `74e86e5`로 커밋·푸시했다. 최신 Web 번들은 PID 31813 유지 세션에서 제공한다.
2026-08-03: 최종 커밋·푸시 문서의 HEAD 표기를 실제 원격 최신 커밋 `dae9f13`으로 정정한다.
2026-08-03: 앱 라우터와 플레이 화면이 서로 다른 `ProgressStore`를 생성하는 경합 지점을 확인했다. 라우터 저장소를 `GameScreen`에 주입해 한 세션의 진행 저장이 동일한 쓰기 큐를 사용하도록 보강한다.
2026-08-03: 공유 저장소 주입이 실제 클리어 저장까지 연결되는지 확인하기 위해 커스텀 `ProgressStore`를 주입한 `GameScreen`의 실제 홀 진입·재조회 통합 회귀를 추가한다.
2026-08-03: 저장 통합 회귀의 첫 실행에서 테스트 호스트에 `MaterialApp`이 없어 `Directionality` 예외가 발생했다. 제품과 동일한 Material 호스트로 테스트를 보정한다.
2026-08-03: 연결 기기는 macOS·Chrome뿐이라 실기기 검증은 보류하고, 네 단계의 16방향·3힘 고속 입력에서 연쇄 안전 중단과 비유한 좌표가 없는지 자동 회귀를 확대한다.
2026-08-03: 다방향 고속 회귀가 통과한 뒤 이동 가능한 공·물체의 히트박스까지 논리 보드 경계 안에 남는지 검증 범위를 확장한다.
2026-08-03: 보드 경계 회귀에서 이동 엔티티 히트박스가 하단 경계를 벗어나는 P1 물리 결함을 재현했다. 실패 입력의 엔티티·단계 정보를 보강하고 연쇄 이동 경계 처리를 수정한다.
2026-08-03: 결함 원인은 4단계 초기 `balloon_crate`가 `y=640`으로 논리 보드 높이 `560` 밖에 배치된 레벨 데이터였다. 상자를 보드 안쪽으로 옮기고 초기 상태 경계 회귀를 추가한다.
2026-08-03: 상자를 `y=500`으로 옮긴 첫 보정은 수평 풍선 회귀의 충돌선을 가렸다. 풍선 경로를 막지 않으면서 히트박스가 보드 안에 남는 `y=520`으로 재조정한다.
2026-08-03: `y=520` 상자는 하단 조작 패널 뒤에 가려져 제품 화면에서 식별성이 낮았다. 풍선 수평 회귀와 겹치지 않으면서 상자 전체가 보이는 `y=400`으로 최종 배치한다.
2026-08-03: 레벨 배치 변경으로 고정된 4단계 다중샷 시드가 무효화됐다. 생성기를 결정된 각도·힘 격자에서 검증된 2발 시드를 자동 탐색하도록 바꿔 픽스처 생성의 레벨 데이터 결합을 줄인다.
2026-08-03: 최신 Web·Android Release를 다시 빌드했다. ARM64 API 28 에뮬레이터에 APK 57.3MB를 설치·실행해 앱 PID 3708, 1080×1920 시작 화면, 치명적 예외 0건을 확인하고 `android-arm64-latest-layout.png` 캡처를 보존한다.
2026-08-03: 전체 회귀 247개와 분석을 통과했다. 4단계 상자 초기 배치·저장소 공유·경계 회귀·자동 다중샷 시드 탐색을 `5425dcb`로 커밋·푸시하고, 최신 Web PID 84934와 Android 최신 시작 화면 증거를 QA 문서에 반영한다.
2026-08-03: 목표 문서 재감사에서 메모리 전용 플레이 계측을 확인하고, 개인정보 없는 로컬 이벤트 저장·복원과 순차 쓰기 회귀를 다음 작업으로 확정했다.
2026-08-03: 로컬 계측 저장소 회귀 첫 실행에서 테스트 import 누락을 확인했다. 구현 오류가 아닌 테스트 의존성 문제로 분류하고 import 보완 후 재검증한다.
2026-08-03: 진행 저장을 배열 인덱스만으로 식별하는 확장성 공백을 확인했다. 안정적인 단계 ID 키를 병행하고 기존 숫자 키와 양방향 호환하는 작업을 시작한다.
2026-08-03: 단계 정의에 안정 ID를 추가하고 `ProgressStore`가 단계 ID 키와 기존 인덱스 키를 함께 읽고 쓰도록 보강했다. 앱 저장소 생성 지점 연결과 순서 변경 회귀를 이어서 추가한다.
2026-08-03: 단계 ID·로컬 계측 변경 후 전체 회귀 251개, Web·Android Release 빌드, 8080 서버 재시작과 Android ARM64 재설치·실행을 완료했다. 최신 Android 시작 화면은 한글 UI·공·돌·상자·홀을 확인했고 치명적 예외는 0건이다.
2026-08-03: 로컬 계측 저장·안정 단계 ID·마이그레이션 호환 회귀를 `bbd9117`로 commit하고 `commercial/wall-physics-qa` 원격에 push했다. 전체 회귀는 251개다.
2026-08-03: 안정 단계 ID 저장 키 추가 후 `saveVersion`이 1에 머물러 있던 스키마 표시 불일치를 발견했다. 버전을 2로 올리고 신규·구버전 마이그레이션 회귀를 보강한다.
2026-08-03: 스키마 2 APK 재설치 직후 흰 화면은 약 5.8초 Android 시작 화면으로 확인했다. 추가 대기 후 한글 홈·이미지를 확인했고 최종 앱 PID 4167, 캡처 해시 `16cd6fb99dbc740ac0799bec0aaa6048a0138150b3642ad669870210bc98cb00`을 기록한다.
2026-08-03: 계측 이벤트마다 SharedPreferences 전체를 다시 쓰는 비용과 화면 종료 시 미저장 이벤트 위험을 확인했다. 고빈도 이벤트 묶음 저장·종료 flush 구조로 개선한다.
2026-08-03: 고빈도 로컬 계측을 250ms 묶음 저장·종료 flush 방식으로 바꾸고 계측·위젯 회귀 및 전체 회귀 252개를 통과했다. 물리 벤치마크는 단계별 290.0~381.1µs, Web·Android Release 재빌드와 Android PID 4338 실행 화면을 확인했다.
2026-08-03: 계측 묶음 저장 기능 커밋 `2489b55`를 원격 브랜치에 push했고, 최신 감사 문서의 커밋·증거 참조를 실제 값으로 맞춘다.
2026-08-03: 최신 Web 데모 서버가 유지 중인 PID `48924`에서 루트와 `main.dart.js` HTTP 200을 반환하는 것을 재확인했다.
2026-08-03: 목표 문서의 계측 필수 필드와 현재 저장 이벤트를 대조해 안정 단계 ID·결과 코드·경로 태그가 부족한 공백을 확인했다. 물리 판정과 분리해 계측 스키마를 보강한다.
2026-08-03: 새 계측 필드 회귀에서 CSV 열 순서 기대값만 실제 헤더와 달라 실패했다. 구현은 정상이며 테스트 기대 문자열을 실제 스키마 순서로 맞춘다.
2026-08-03: 계측 이벤트에 안정 `stage_id`, `result_code`, `route_tag`를 추가한 `898afd2`를 push했다. Web·Android Release 재빌드, Android ARM64 실행 PID 4503, iOS 무서명 Xcode 컴파일·서명 차단 결과를 최신 증거에 반영한다.
2026-08-03: 최신 Web 성능 감사 스크립트는 전역 Pillow `_imaging`의 JPEG ABI 불일치로 시작 전에 실패했다. 기존 Chromium 증거는 역사값으로 유지하고 새 측정 성공으로 오인하지 않는다.
2026-08-03: 최신 기능·증거 커밋 `898afd2`와 `174be05`가 원격 HEAD에 반영됐고, PID 75036 Web 데모의 루트·번들 HTTP 200을 최종 확인했다.
2026-08-03: 문서 커밋 `a35c373`를 원격에 push했고 커밋·증거 요약의 원격 HEAD 표기를 일치시킨다.
2026-08-03: 커밋 요약에서 문서 자체의 후속 커밋 때문에 HEAD 숫자가 낡는 문제를 확인해, 고정 HEAD 주장 대신 주요 작업 커밋 목록으로 표현을 정리한다.
2026-08-03: 빈 Chromium 페이지는 p95 17.8ms였지만 최신 게임 화면은 390×844 발사 p95 68.5ms·768×1024 발사 p95 66.7ms로 재현됐다. 앱 회귀와 환경 변동을 분리하기 위해 Web 감사에 Long Task 수집을 추가한다.
2026-08-03: Web Long Task 수집에서 초기 자산·엔진 디코딩으로 보이는 0.5~1.7초 작업과 발사 중 200~360ms 작업을 분리하기 위해 성능 감사 워밍업 시간을 매개변수화한다.
2026-08-03: 유휴 렌더링에서 변하지 않는 보드 그라디언트·클리핑·장식을 매 프레임 다시 그리는 비용을 확인해 논리 좌표 보드 레이어 캐시를 검토한다. 물리 판정·애니메이션 시간축은 변경하지 않는다.
2026-08-03: 보드 그림을 논리 좌표 Picture로 한 번 기록해 매 프레임 재생하도록 바꾸고, 최신 Web Release 서버를 기존 PID 종료 후 새 PID 10800으로 교체한다.
2026-08-03: 보드 캐시만으로는 768×1024 발사 p95가 83.4ms로 남아 계획 상태의 물체 재질·블러·클리핑도 Picture 캐시하고 공·속성·홀 목표 효과만 동적 오버레이로 유지한다.
2026-08-03: 계획 상태 물체 Picture 캐시가 포함된 Web Release를 기존 PID 종료 후 PID 17056으로 교체했고, 존재하는 애니메이션·위젯 회귀는 통과했다. 잘못 지정한 부재 `test/golden_test.dart`는 테스트 선택 오류로 기록한다.
2026-08-03: 최신 캐시 Release를 5초 워밍업 조건으로 재측정해 390×844 발사 p95 66.7ms·평균 25.4ms, 768×1024 발사 p95 67.2ms·평균 39.3ms를 확인했다. 빈 Chromium 기준은 약 16.7ms이며 Web 성능 게이트는 미통과로 기록한다.
2026-08-03: 최신 Web 번들 해시는 `dabbdc154f0ee51dd7a5d8cda7d1c3e7d844aaa3149724bd8b26e13667f6432f`, 서버 PID는 17056이며 완료 감사 문서에 이 증거와 성능 미통과를 반영한다.
2026-08-03: 메타데이터 포함 최종 Web 감사는 390×844 발사 평균 25.943ms·p95 66.6ms, 768×1024 평균 40.576ms·p95 66.7ms, 콘솔 오류 0건을 기록했다. 기록 문서의 수치를 이 최신 실행으로 맞춘다.
2026-08-03: 계획 물체 Picture 캐시가 계획 화면과 4단계 Golden의 동적 효과 시점 차이를 만들어 다수 픽셀 회귀를 유발했으므로, 캐시 코드는 제거하고 Golden 시각 계약을 우선 보존한다. Long Task 계측·성능 미통과 기록은 유지한다.
2026-08-03: 캐시 제거 후 현재 코드로 Web Release를 다시 빌드해 번들 해시 `4cdb3941b7d7f4bd91004f49954c8f95cf9dad92e41ccfe88c5f8a431a2bbf42`, 서버 PID `34563`으로 8080 데모를 교체한다.
2026-08-03: no-cache 최종 번들은 390×844 발사 평균 25.681ms·p95 66.6ms, 768×1024 평균 35.953ms·p95 66.7ms, idle 768×1024 평균 33.641ms를 기록했다. 현재 데모와 성능 원자료는 이 번들 기준이다.
2026-08-03: 캐시 제거 후 전체 `flutter test` 252개와 플레이·4단계 Golden 45개를 통과했다. 현재 작업은 Long Task QA 도구와 성능·릴리스 증거 문서만 남겨 commit한다.
2026-08-03: 런타임 오브젝트 자산이 1254px 원본을 40~125px 화면에 순차 디코드하는 비용을 확인해, 게임 전용 256px 디코드와 세 자산 병렬 로드를 검토한다. Golden AssetImage 경로와 물리 판정은 변경하지 않는다.
2026-08-03: 256px 런타임 디코드·병렬 자산 로드가 포함된 Web Release를 기존 서버 종료 후 PID 50473으로 교체했고 번들 해시는 `b1a573783ffd818bd126a9c2599db5b0c99399363a674c7ac5fc2eedf4b01385`다.
2026-08-03: 자산 스트레스 위험을 줄이기 위해 디코드 완료 직후 `ui.Codec`를 해제하고 Flame 게임 제거 시 소유한 `ui.Image`를 해제하는 수명 관리를 추가한다.
2026-08-03: 물체·동적 효과 캐시는 Golden 회귀로 제외한 채, 반복 그리기 비용이 큰 보드 배경만 Picture로 캐시하는 보수적 최적화를 별도 검증한다.
2026-08-03: 보드 배경 Picture 캐시를 포함한 최신 Web Release를 8080에서 PID 61485로 실행하고 루트 HTTP 200과 번들 해시 `a9d7e1382dec9a12ddf798f51a62ebd891ff6f9965921be7efe43ba5d2c9a0a2`를 확인한다.
2026-08-03: 보드 배경 Picture 캐시 재측정에서 390×844 발사 평균 26.215ms·p95 66.6ms, 768×1024 발사 평균 42.198ms·p95 83.3ms로 런타임 자산 최적화 단독 결과보다 악화되어 캐시를 제거한다.
2026-08-03: 보드 캐시 제거 후 최종 후보 Web Release를 기존 PID 61485 종료 뒤 PID 71544로 교체했고 번들 해시는 `7adaeb81babcfb2789021c3cc07452aa59bc2bbd33c095211221c3ae46a382e9`다.
2026-08-03: 최종 후보 Web 감사는 390×844 발사 평균 25.419ms·p95 66.6ms, 768×1024 평균 42.222ms·p95 150ms, 콘솔 오류 0건을 기록했다. 60FPS p95 게이트는 미통과이며, 이는 Chromium 보조 측정으로 실기기 결과가 아니다.
2026-08-03: 검증 결과 문서에 최종 Web 해시·PID·성능 수치와 256px 런타임 자산 수명 관리, 실기기 미검증 위험을 추가해 최신 Release 기준을 통일한다.
2026-08-03: 최종 Android Release APK를 다시 빌드해 57.3MB·SHA-256 `497370fc5f7d6e325f3a5f7c71064bb13d04b9892eebeab98a995d4559eda09f`를 확인하고 ARM64 에뮬레이터에 설치·실행했다. 앱 PID 4897, 최근 `FATAL EXCEPTION` 0건이다.
2026-08-03: Web 렌더 병목을 재감사해 정적 비원형 물체의 반복 Canvas 작업을 확인했다. 동적 속성 점멸·충돌 변형·홀·풍선은 제외하고 정적 물체만 개별 Picture로 재생하는 캐시를 Golden과 성능 양쪽에서 시험한다.
2026-08-03: 정적 Picture 캐시의 이전 항목 재사용·신규 기록 분기에서 nullable 분석 오류가 확인되어, 캐시 수명과 교체를 명시적으로 분리해 수정한다.
2026-08-03: 정적 Picture 캐시가 `loadVisualAssets: false` 대체 Canvas Golden에서 30px 회귀를 만들었다. 실제 래스터 자산 경로에서만 캐시하도록 제한하고 대체 Golden 렌더 경로는 보존한다.
2026-08-03: 래스터 자산 전용 정적 Picture 캐시 Web Release를 기존 PID 71544 종료 후 PID 96487로 교체했고 번들 해시는 `e903d5c0bdf3b5faed85a5087a19056f4fc03749ee93a34a1153240485172158`다.
2026-08-03: 래스터 캐시 첫 측정에서 768×1024 발사 p95가 150ms에서 85ms로 낮아졌지만 목표를 넘었다. 애니메이션 중에도 이동 이벤트에 없는 정적 물체는 캐시하도록 범위를 확장해 추가 측정한다.
2026-08-03: 발사 중 정적 물체 캐시 확장 Web Release를 기존 PID 96487 종료 후 PID 2283으로 교체했고 번들 해시는 `5244986d3c5c88b82c91498b95d9d2dbdd66a17d63a0b2e4a2102f453c2bb685`다.
2026-08-03: 발사 중 정적 캐시 확장 측정은 390×844 평균 24.836ms·p95 66.6ms, 768×1024 평균 38.998ms·p95 66.7ms였다. 래스터 물체의 작은 표시 크기에 맞춰 고품질 필터를 중간 품질로 낮추는 비교 실험을 시작한다.
2026-08-03: 중간 품질 래스터 필터 Web Release를 기존 PID 2283 종료 후 PID 7795로 교체했고 번들 해시는 `2738b00fae84719864756376ad3179facb03ceaea3c66f91cb031dd0aaa832d1`다.
2026-08-03: 중간 품질 필터 측정은 390×844 발사 평균 24.195ms·p95 51.5ms, 768×1024 평균 38.717ms·p95 66.6ms였다. 보드 배경도 실제 자산 경로에서 논리 크기 래스터 이미지로 한 번 생성해 추가 비용을 비교한다.
2026-08-03: 보드 래스터 캐시의 새 Web Release 재빌드가 실행 환경 사용 한도로 검증되지 않아 해당 실험 코드를 제거한다. 실제 Web에서 검증된 정적 물체 Picture 캐시와 중간 품질 래스터 필터만 최종 후보로 유지한다.
2026-08-03: 최종 검증 후보는 정적 물체 Picture 캐시·256px 병렬 디코드·Codec/Image 수명 해제·중간 품질 필터다. 감사 당시 번들 `2738b00fae84719864756376ad3179facb03ceaea3c66f91cb031dd0aaa832d1`, 서버 PID `7795`에서 390×844 발사 평균 24.195ms·p95 51.5ms, 768×1024 평균 38.717ms·p95 66.6ms를 기록했다. 감사 후 서버 재시작은 실행 환경 사용 한도로 보류됐다.
2026-08-03: PID 7795 감사 서버가 종료된 뒤 실행 환경 사용 한도로 8080 재시작이 거부되어 `.runtime/property_shot_web_8080.pid`를 0으로 정리한다. 다음 실행 가능 환경에서 검증 후보를 다시 제공해야 한다.
2026-08-06: 10단계 확장 총괄 프롬프트에 따라 PS-BASE-01을 재검증했다. 작업 트리는 깨끗하고 `flutter analyze`, 전체 회귀 252개, Web Release 빌드가 모두 통과했다. 기존 1~4단계 결과를 보존하는 JSON 기반 `StageDefinition`·`StagePattern`·`LevelDefinition` 변환 경계를 PS-DATA-01의 공통 인터페이스로 확정한다.
2026-08-06: PS-DATA-01을 시작했다. 이번 단위는 기존 1~4단계 데이터를 이전하지 않고 JSON 스키마·EntityState 손실 없는 codec·LevelDefinition 변환과 집중 회귀 테스트만 담당한다.
2026-08-06: PS-DATA-01 구현을 완료했다. `StageDefinition`·`StagePattern`·`PatternObjectDefinition`의 JSON Map/문자열 codec, 모든 현재 `EntityType`·`TraitType`의 안정 이름, 레거시 `LevelDefinition` 양방향 변환과 오류 검증을 추가했다. 집중 6개, 핵심 물리 77개, 전체 258개 테스트와 `flutter analyze`가 통과했다.
2026-08-06: Sol 검토에서 레거시 호환 회귀가 1단계만 확인하는 증거 공백을 발견해 Luna에 보완을 요청했다. 1~4단계 전체의 기본·제품 규칙 `createState`와 모든 엔티티 필드가 변환 전후 일치하도록 확장했고 집중 테스트를 재통과해 PS-DATA-01을 PASS 판정한다.
2026-08-06: PS-DATA-01을 커밋 `73a42dc`로 원격 브랜치에 push했다. 다음 PS-RUN-01은 Dart VM·Web에서 동일한 32비트 seed 파생과 스테이지별 셔플 백을 순수 Dart로 구현하며, 저장·UI 연결은 PS-RUN-02 이후로 분리한다.
2026-08-06: PS-RUN-01 Sol 검토에서 교차 런타임 고정 벡터와 `cycle`·`drawIndex`·남은 항목 수의 손상 상태 검증을 보강했다. VM과 Chrome에서 seed 고정 벡터와 집중 테스트 10개가 각각 통과해 결정론적 스테이지별 셔플 백을 PASS 판정한다.
2026-08-06: PS-RUN-01 통합 게이트로 `flutter analyze`, 전체 회귀 268개, Web Release 빌드가 통과했다. 이 작업 단위는 seed 파생·셔플 백·집중 테스트와 기록만 포함해 별도 commit·push한다.
2026-08-06: PS-RUN-01을 커밋 `68ee2aa`로 원격 브랜치에 push했다. PS-RUN-02는 패턴·보상 재추첨 방지를 위해 실행 단계를 명시한 `RunState`와 revision·체크섬을 가진 A/B 저장 슬롯을 도입하고, 손상 또는 중단 시 가장 최신의 완결 상태를 복구하도록 설계한다.
2026-08-06: PS-RUN-02 구현을 시작했다. 기존 `ProgressStore` 키·스키마는 보존하고, `RunState`와 별도 A/B 슬롯 저장소에 단계·패턴·보상 후보·샷 입력·셔플 상태를 저장한다. 저장 후보를 재읽기·체크섬 검증한 뒤 active pointer를 갱신하고, 손상·중단 시 최신 유효 슬롯으로 복구하는 장애 주입 테스트를 추가한다.
2026-08-06: PS-RUN-02를 완료했다. `RunState`의 phase·패턴·보상·점수·재생 참조·샷 입력·UTC 시각과 방어 복사 codec, SharedPreferences adapter 및 revision/checksum A/B 저장소를 추가했다. 후보 쓰기 전·후, verify·pointer 장애, checksum·pointer 손상, 동시 저장·reset·ProgressStore key 비침범을 집중 16개로 검증했고 `flutter analyze`, 전체 284개, Web release 빌드가 통과했다. 아직 앱 라우터·실제 패턴 draw·보상 UI 연결은 다음 작업 범위다.
2026-08-06: Luna가 Sol 검토 전 commit·push 금지 지시를 어기고 PS-RUN-02 커밋 `982de13`을 먼저 원격에 반영했다. 사후 감사에서 현재 패턴은 확정됐지만 셔플 백은 미소비로 저장되는 anti-reroll 결함, 3택1 후보 수 미검증, 저장 전 read 장애의 silent loss 위험을 발견해 FAIL 판정하고 보정을 요구했다.
2026-08-06: RunState 초기화를 실제 `StagePatternDraw`와 소비 후 bag 상태로 묶고 current·next draw/history/bag 일관성, 정확히 3개인 보상 후보, 선택 보상 획득 반영, save 전 read 장애 전파를 추가했다. 강화한 집중 테스트 19개, 전체 회귀 287개, `flutter analyze`, Web Release 빌드가 통과해 PS-RUN-02를 보정 후 PASS 판정한다.
2026-08-06: PS-RUN-02 보정 커밋 `e2cc55d`를 원격에 push했다. PS-VALID-01은 패턴 수·ID·수치·필드 경계·초기 겹침·시작 자동 클리어·벽 불변·홀·문·스위치 연결·복수 해법 메타데이터·기물 예산을 안정 오류 코드로 판정하는 순수 정적 검증기부터 구축한다.
2026-08-06: PS-VALID-01 구현을 시작한다. 파서의 `FormatException`과 분리된 `ValidationIssue`·`ValidationReport` 계약을 만들고, 생산 패턴 정책과 기존 1~4단계 레거시 개별 배치 검사를 분리한다. 벽 모서리 접합과 비연결 문·스위치는 기존 데이터 호환을 위해 명시적인 최소 예외로 다룬다.
2026-08-06: PS-VALID-01 Luna 초안은 안정 오류 코드 33종과 집중 테스트 15개를 보고했지만 Sol 검토 전 PASS로 잘못 기록됐다. 실제 감사에서 `switch.linkId → gate.id`인 엔진 계약 불일치, 비고체 벽 내부 시작 누락, 기존 공 자동 클리어 누락, 홀 `hitboxScale`을 잘못 사용한 포획 반경, 연결 누락 중복 보고를 발견해 보완을 요구했다.
2026-08-06: 보완된 `StagePatternValidator`는 안정 오류 코드 34종, 한글 메시지, 결정론적 정렬, 수치·경계·홀·벽·공·shape-aware 겹침·실제 문/스위치 연결·기물 예산·`required_reward` 검사를 제공한다. production 3~4패턴·복수 풀이 정책과 레거시 배치 정책을 분리했고 기존 1~4단계가 오탐 없이 통과한다. 집중 21개, 전체 회귀 308개, `flutter analyze`, Web Release 빌드가 통과해 Sol이 PS-VALID-01을 PASS 판정한다.
2026-08-06: PS-VALID-01 커밋 `cdabc6c`를 원격에 push했다. PS-VALID-02는 정적 invalid JSON fixture와 제한된 실제 `ShotResolver` probe, 동적 probe 계약을 결합해 no-route·안전 중단·결정론·벽 이동·홀 통과·비유한 값·소프트락을 판정하고, 아직 기물이 없는 슬라이더·회전판은 거짓 메타데이터가 아니라 명시적인 probe evidence 계약으로 연결한다.
2026-08-06: PS-VALID-02 구현을 시작한다. 정적 오류 코드와 호환되는 `PatternRuntimeEvidence` 주입 경계를 추가하고, 실제 `ShotResolver`는 공개된 샷·실행 상한 안에서 결정론·벽 불변·홀 통과·안전 중단·유한값을 관찰한다. 대표 입력에서 성공이 없다는 사실만으로 no-route를 오류화하지 않으며, 슬라이더·회전판은 적용 가능성을 명시한 scripted evidence가 있을 때만 판정한다.
2026-08-06: PS-VALID-02 Sol 감사에서 scripted 자동 클리어·경로 차단 fixture, 점 표본 no-route 오탐, 불완전한 결정론 지문, 대표 입력 무이동의 소프트락 오판, 벽 비교 허용 오차를 발견했다. 실제 배치·실제 probe, 자유 공간 상위 근사, 전체 `GameState`·이벤트 값 지문, 명시적 `launchUnavailable`, 벽 물리 필드 정확 비교로 보정하고 홀 통과 양성 회귀를 추가한다.
2026-08-06: PS-VALID-02는 자동 클리어·완전 벽 차단을 실제 배치와 `ShotResolver` probe로 검증하고, 안전 중단·결정론·벽 불변·홀 통과·유한 수치·이벤트 순서·실행 상한을 안정 오류 코드로 판정한다. 이름 있는 invalid fixture 12종, 복합 오류 누락 audit, 정상 1~4단계 오탐 방지, 좁은 통로 상위 근사, 1e-7 결과 차이, 벽 0.0001 이동 회귀를 포함한 집중 45개와 전체 332개 테스트, `flutter analyze`, Web Release 빌드가 통과해 Sol이 PASS 판정한다. 미구현 슬라이더·회전판·명시적 시간 필드는 scripted evidence 계약으로만 보존하며 실제 물리 검출로 간주하지 않는다.
2026-08-06: PS-VALID-02를 커밋 `547e604`로 원격 브랜치에 push했다. PS-STAGE-01A는 전역 `levels`의 동기식 API를 유지하면서 기존 1~4단계 기준 배치를 버전 있는 JSON 카탈로그로 무손실 이전한다. 원본 JSON과 빌드용 동기 생성 스냅샷의 일치를 회귀로 강제하고, 이 단위에서는 추가 패턴 제작과 런타임 추첨 연결을 범위 밖으로 둔다.
2026-08-06: PS-STAGE-01A 구현을 완료했다. 안정 stage ID는 `stage_heavy`, `stage_bouncy`, `stage_chain_gate`, `stage_balloon`을 문자 단위로 유지하고 각 기준 패턴 ID는 `stage_heavy_01`, `stage_bouncy_01`, `stage_chain_gate_01`, `stage_balloon_01`로 고정했다. `assets/stages/chapter_1.json`을 source of truth로 두고 `StageCatalog`, 결정론적 `generated_stage_catalog.dart`, `--check` drift 검사, 독립 legacy fixture를 추가했다. 기본·제품 규칙 `GameState`와 기존 물체·보상·전략 필드는 무손실 비교로 확인했으며 새 `stageId`·`patternId`·`difficultyBand`는 별도 메타 기대값으로 검증했다. 집중 32개, 전체 337개 테스트, `flutter analyze`, Web Release 빌드, 생성본 drift 검사가 통과했다. 추가 패턴·셔플 추첨·런타임 연결은 범위 밖으로 유지했고 Sol 승인 전 commit/push는 수행하지 않았다.
2026-08-06: PS-STAGE-01A Sol 재검토에서 배열 첫 항목에 의존한 기준 패턴 선택, 생성기의 물리 배치 검증 누락, 음수 복사·보상 개수 허용을 발견했다. `metadata.baseline=true`로 단계별 기준 패턴을 정확히 하나로 고정하고, 생성 전 `StagePatternValidator` 레거시 검사, 음수 `copyCharges`·`copyCoreReward`·빈 `bonusGoal` 검사, 불변 카탈로그, 원자적 생성본 교체를 추가했다. 원본 JSON은 편집 가독성을 위해 포맷했고, 집중 40개·전체 345개 테스트, `flutter analyze`, 생성기 `--check`, Web Release 빌드와 빌드 자산 포함을 독립 확인해 Sol이 PASS 판정한다.
2026-08-06: PS-STAGE-01A를 커밋 `30dcff3`로 원격 브랜치에 push했다. PS-STAGE-01B-1은 1단계를 기준 포함 4패턴으로 확장하되 모든 패턴에서 무거움 이전 경로와 비사용 경로를 실제 `ShotResolver` 입력으로 재생한다. 패턴 간 공·홀·벽·속성 원본·이동 물체 차이를 정량화하고, 대표 해답 주변의 각도·파워 허용 구간을 회귀로 고정해 픽셀 단위 정답을 금지한다.
2026-08-06: PS-STAGE-01A Sol FAIL 보완을 완료했다. 각 기준 패턴에 metadata `baseline=true`를 명시하고 `levels`는 패턴 순서가 아닌 metadata로 정확히 하나를 선택하며, 0개·2개는 한글 `StateError`와 catalog validation 오류로 거부한다. `StageCatalog`·`levels`를 불변 목록으로 바꾸고 `Vec2` 유한값 검사를 명시 타입으로 정리했다. generator는 `StagePatternValidator.validateLegacyStage`까지 실행하고 오류 코드·스테이지·패턴·한글 메시지를 출력하며, snapshot은 같은 디렉터리 임시 파일을 완성한 뒤 rename으로 교체한다. JSON codec·ID·수치·기준 개수·순서 독립성·정적 검증 출력 negative 테스트를 추가했다. 재생성, `--check`, 집중 40개, 전체 345개, `flutter analyze`가 통과했으며 commit/push는 수행하지 않았다.
2026-08-06: PS-STAGE-01B-1은 1단계를 기준 포함 4패턴으로 확장하고 각 패턴의 무거움 이전·비사용 성공 입력을 실제 `ShotResolver`로 고정했다. 모든 패턴 쌍은 공·홀·벽·속성 원본·이동 물체 중 최소 두 범주가 다르고, 선언한 풀이 계열은 실제 벽·상자·무게 물체 impact와 대표 입력으로 모두 증명된다. 대표 입력 10개의 15점 근방 성공 수는 3~11개이며 축소 격자 성공점은 패턴별 none/anvil이 41/118, 11/15, 12/71, 10/31로 모두 무거움 성공 영역이 더 넓다. 선택 도전은 기본 성공과 분리된 메타데이터로만 추가했고 특정 보상 요구는 금지했다. Luna 초안의 Dart 중복 배치·JSON 덮어쓰기 도구와 2~4단계 source churn을 제거했으며, Sol은 고정 무게 물체 풀이 계열을 다른 물체의 전역 운동량 이벤트가 아닌 실제 무게 물체 impact와 반사로 판정하도록 직접 교정했다. 생성기 `--check`, 집중 72개, 전체 353개 테스트, `flutter analyze`, Web Release 빌드와 `git diff --check`가 통과해 Sol이 PASS 판정한다.
2026-08-06: PS-STAGE-01B-2는 2단계 탄성 튜토리얼을 기준 포함 4패턴으로 확장한다. 모든 패턴은 탄성 이전 경로와 비사용 경로를 실제 `ShotResolver`로 증명하고, 충돌면 법선에 따른 벽 반사·젤리 또는 물체 상호작용·직접 경로 중 최소 두 풀이 계열을 가진다. 탄성은 일반 공보다 성공 영역 또는 충돌 후 도달 범위를 의미 있게 넓혀야 하며, 대표 해답 주변에 각도·파워 허용 구간을 확보한다. 단순 좌우 반전, 회전 없는 대각선 벽 표기, JSON source 중복, 특정 기믹 강제와 1·3·4단계 source 변경을 금지한다.
2026-08-06: PS-STAGE-01B-2는 2단계를 기준 포함 `stage_bouncy_01~04`로 확장하고 모든 패턴의 none·jelly 실제 성공 입력과 impact 기반 풀이 계열을 고정했다. Sol 감사에서 속성 장착과 성공만 확인하던 순환적 `trait_transfer_route`, 시작 공과 홀이 48px뿐이던 2번 근접 배치, power clamp로 중복되던 근방 표본을 FAIL 처리했다. 보완 후 2번 중심 거리는 약 427px이고 coarse none/jelly 성공점은 6/9이며, 전체 패턴은 19/76, 6/9, 195/259, 74/85로 모두 탄성 성공 영역이 더 넓다. 탄성 대표 입력 4개는 같은 none 입력이 모두 실패하고 실제 패턴 벽 impact와 반사를 포함하며, 선언한 `wall_reflection`·`multi_wall_reflection`·`jelly_interaction`은 실제 대상·이벤트로 증명된다. 대표 8개는 각각 15개의 고유 각도·힘 근방 입력 중 3~15개 성공하고, 같은 충돌 입력의 탄성 경로 길이는 패턴별 8.293·15.664·33.160·9.288만큼 더 길다. 선택 도전은 실제 대표 경로로 증명하면서 기본 성공과 분리했다. 생성기 `--check`, 2단계 집중 9개와 교차 집중 81개, 전체 362개 테스트, `flutter analyze`, Web Release, `git diff --check`가 통과해 Sol이 PASS 판정한다.
2026-08-06: PS-STAGE-01B-3는 3단계 스위치·문·점착 튜토리얼을 기준 포함 4패턴으로 확장한다. 모든 패턴은 무거운 공으로 스위치를 작동하는 상태 변화 경로와 스위치·문을 쓰지 않는 우회 성공을 실제 `ShotResolver`로 증명한다. 최소 한 패턴은 점착된 과거 공이 다음 샷의 실제 충돌 기물 또는 상태 유지 장치로 기여하는 2샷 경로를 제공하며, 첫 샷의 점착·두 번째 샷의 충돌·스위치·문·홀 이벤트 인과 순서를 검증한다. 단순히 첫 샷이 실패하고 무관한 두 번째 샷이 성공하는 계획은 준비 샷 계열로 인정하지 않는다. 대표 입력 근방의 고유 각도·힘 허용 구간, 모든 패턴 쌍의 배치 다양성, 선택 도전 증거, 벽 불변과 특정 기믹 비강제를 유지한다.
2026-08-06: PS-STAGE-01B-3의 인과적 준비 샷을 탐색하던 중 점착된 과거 공이 `movable=false`라는 이유로 후속 공을 반사하지 않고 `blocked_by_ball`로 종료하는 공통 물리 결함을 확인해 PS-PHYS-03으로 분리했다. 고정 과거 공도 실제 원형 충돌체로 판정하고 접촉 법선과 재질 반발값에 따라 발사 공을 반사하되, 고정 공의 위치·속성·시각 상태는 바꾸지 않는다. 충돌은 일반 `bounced`와 진단용 `spent_ball_bounced`, 위치를 옮기지 않는 `spent_ball_hit` 재생 이동을 남긴다. 점착 생성·법선 반사·상태 불변·결정론·후속 벽 충돌·홀 우선 포획·기존 이동 공 운동량 분기를 전용 7개 회귀로 고정했다. 미완성 3단계 데이터와 분리한 기준 복제본에서 전체 369개 테스트, `flutter analyze`, Web Release 빌드와 `git diff --check`가 통과해 Sol이 PS-PHYS-03을 PASS 판정한다.
2026-08-06: PS-STAGE-01B-3는 3단계를 기준 포함 `stage_chain_gate_01~04`로 확장하고 각 패턴의 무거운 공 스위치·문 경로와 일반 공 우회 경로를 실제 `ShotResolver` 입력으로 고정했다. 단일샷 대표 근방 15점 성공 수는 패턴별 none/steel이 7/9, 6/4, 4/9, 3/7이며 모든 패턴 쌍은 공·홀·벽·속성 원본·이동 물체·스위치/문 구조 중 최소 두 범주가 다르다. Sol 감사에서 과거 공만 맞힌 뒤 스위치 없이 우회하던 준비샷과 UI 최소 힘 0.12보다 낮은 테스트 전용 입력을 두 차례 FAIL 처리했다. 최종 2샷 해법은 첫 공을 점착 고정하고 남은 무거움을 새 공에 이전한 뒤 실제 UI 충전 눈금의 세 입력 계획(`0도/0.12 → 319도/0.56`, `0도/0.175 → 319도/0.615`, `4도/0.175 → 326도/0.67`)으로 `sticky_attached → spent_ball_1 impact/bounce → switch impact/pressed → gate open state/move → hole impact/entered` 전체 인과를 재현한다. 준비 없는 같은 둘째 입력은 이 인과를 재현하지 않으며 선택 도전과 풀이 계열은 기본 성공과 분리됐다. 1·2·4단계 source 해시는 유지됐고 생성기 `--check`, 관련 48개와 전체 376개 테스트, `flutter analyze`, Web Release 빌드, 포맷과 `git diff --check`가 통과해 Sol이 PASS 판정한다.
2026-08-06: PS-STAGE-01B-4는 4단계를 기준 포함 `stage_balloon_01~04`로 확장하고 뾰족함 팝 경로와 비사용 반사 또는 우회 경로를 실제 `ShotResolver` 입력으로 고정했다. 모든 대표 power는 실제 UI 충전 눈금이며 근방 15점 성공 수는 패턴별 sharp/none이 5/10, 4/4, 5/4, 5/5다. 1·2번은 `balloon impact → popped → switch revealed → actual switch impact/pressed → gate open → hole`, 3번은 스위치를 누르지 않는 팝 직행, 4번은 `balloon_b` 충돌·파열·뾰족함 1회 소모 뒤 다른 고정 풍선 충돌·반사를 재현한다. 일반 공 경로는 풍선 위치·활성·고체 상태를 바꾸지 않고 `balloon_bounced`를 남기며, 풍선을 건드리지 않는 우회도 별도 패턴에서 성공한다. Sol 감사에서 실제 fixture보다 많은 풀이 계열 선언을 제거하고 두 풍선의 impact·상태 전이 순서와 `balloon_popped`·`sharpness_consumed` 정확히 1회를 직접 검증하도록 보강했다. 기준 패턴 geometry와 1~3단계 source 해시는 유지됐고 생성기 `--check`, 관련 Golden 포함 99개와 전체 381개 테스트, `flutter analyze`, Web Release 빌드, 포맷과 `git diff --check`가 통과해 Sol이 PASS 판정한다.
2026-08-06: PS-INPUT-01을 시작한다. 현재 힘 충전은 80ms 주기마다 상태를 증가시켜 타이머 지연에 따라 결과가 달라지고 포인터 화면 좌표를 콜백 시점의 보드 크기로 다시 해석한다. 단조 증가 시간과 저장된 논리 좌표를 사용하는 순수 입력 세션을 도입하고, 동일 로그의 30·60·120Hz 결과·최초 포인터 독점·화면 이탈 종료·회전 및 생명주기 취소·발사 계산 중 재입력 차단을 회귀로 고정한다. 5단계 색상 게이지와 회색 취소 순환은 PS-UX-01로 분리한다.
2026-08-06: PS-INPUT-01은 포인터 이벤트의 단조 타임스탬프와 즉시 변환한 논리 좌표를 보존하는 `LaunchInputSession`으로 입력을 분리했다. 충전 시작은 콜백 실행 시각이 아니라 pointer down + 450ms로 고정하고 최종 힘은 pointer up 시각에서 연속 계산하므로 80ms 타이머는 화면 표시만 갱신한다. Sol 감사에서 합성 테스트의 0 타임스탬프를 프레임 시각으로 보정하던 분기가 렌더 지연 독립성을 훼손할 수 있어 제거하고, 위젯 테스트가 실제 단조 타임스탬프를 보내도록 교정했다. 종료 이벤트의 마지막 논리 좌표, 최초 포인터 독점과 비활성 포인터 종료 무시, 화면 밖 종료, 회전·크기·생명주기 취소, 발사 애니메이션 중 재입력 차단, 30·60·120Hz 동일 aim·power·launch를 검증했다. 집중 58개와 전체 389개 테스트, `flutter analyze`, 생성기 `--check`, Web Release 빌드, 포맷과 `git diff --check`가 통과해 Sol이 PASS 판정한다. 5상태 충전 게이지와 회색 취소 순환은 PS-UX-01 범위로 유지한다.
2026-08-06: PS-UX-01을 시작한다. PS-INPUT-01의 단조 시간 계산을 유지하면서 충전 상태를 초록·노랑·빨강·빨강 경고·회색 취소의 단방향 상태 머신으로 확장한다. 게임 화면은 색뿐 아니라 링 굵기·1~3단 눈금·바깥 경고 링·취소 아이콘으로 상태를 구분하고, 저모션 모드에서는 펄스 없이 정적 명도와 형태로 전달한다. 회색 진입은 누르는 동안 고정되고 손을 떼어도 발사하지 않으며, 새 포인터 입력에서만 다시 초록으로 시작한다. 과충전 진입의 이중 햅틱 또는 동등한 명확한 피드백과 상태별 위젯·Golden 회귀를 이 작업에 포함한다.
2026-08-06: PS-UX-01은 초록(힘 0.40 미만)·노랑(0.40 이상)·빨강(0.70 이상)·경고 빨강(0.90 이상)·회색 취소(충전 1680ms 초과)의 정확한 5상태를 단방향으로 고정했다. 최대 힘 도달 후 400ms의 안전 발사 구간을 유지하고 pointer down 2130ms까지는 발사, 2131ms부터는 시도·물리 계산 없는 과충전 취소로 처리한다. Sol 감사에서 6상태 초안을 원문 5상태로 교정하고, 회색 상태의 모순된 발사 안내, 프레임 시각과 포인터 시각 기준 차이, 전체 상태 역행, 동시 이중 햅틱, 과충전 후 새 입력 복구, Golden의 비대표 힘을 보완했다. 게이지는 얇은 링·1눈금, 중간 링·2눈금, 굵은 링·3눈금, 바깥 경고 링·완만한 펄스, 정지 링·X 취소 표시로 색상 외 차이를 제공한다. 저모션은 펄스를 제거하며 접근성 값은 상태 의미를 한글로 알린다. 390x844·768x1024의 5상태 및 저모션 Golden 14장을 직접 검토했고, 집중 39개와 전체 414개 테스트, `flutter analyze`, 생성기 `--check`, Web Release 빌드, 포맷과 `git diff --check`가 통과해 Sol이 PASS 판정한다.
2026-08-06: PS-OBJ-01 파워 슬라이더를 시작한다. 데이터 스키마에 슬라이더의 진행 방향과 최소 기준 속력을 무손실 저장하고, 공과 허용된 이동 물체가 영역에 진입할 때 `max(현재 속력, 기준 속력)`만 적용한다. 동일 접촉 반복 발동과 단순 가산·무한 중첩을 금지하며 완전 이탈 후 재진입, 복수 슬라이더 최댓값 수준 보정, 홀·점착 우선순위, 슬라이더 직후 벽·홀·얇은 기물 연속 충돌, 순간 이동 없는 swept collision, 접촉 ID와 결정론 이벤트를 물리 회귀로 고정한다. 독자적 발판 비주얼·한글 정보·Golden·라이선스 기록도 이 작업에 포함하고 5단계 제작은 후속 PS-STAGE-02로 분리한다.
2026-08-06: PS-OBJ-01 구현을 완료했다. `EntityType.powerSlider`, `direction`, `referenceSpeed`, 안정 순서 `allowedTargets`를 기존 1~4단계 JSON에 필드를 추가하지 않는 조건으로 codec에 연결했다. validator는 방향·기준 속력·대상 타입·활성 정적 비고체·초기 겹침을 안정 오류 코드로 판정한다. resolver는 활성 공과 재귀 연쇄가 공유하는 접촉 원장, `max(현재 속력, 기준 속력)`, 방향 보존, 완전 이탈 후 재진입, 홀·점착·고체 충돌 우선, swept 진입점 재검사를 구현하고 `PowerSliderActivation`을 별도 물리 이벤트로 보존한다. runtime probe는 실제 경로가 영역을 통과했는데 activation이 없을 때만 tunneling을 보고한다. 외부 에셋 없는 Canvas 발판과 한글 정보 팝업, 작동·저모션 정적 피드백을 추가했으며 390x844·768x1024 Golden 8장을 생성·시각 확인했다. PS-STAGE-02와 기존 1~4 JSON·생성 카탈로그는 변경하지 않았고, 이 작업에서는 commit·push하지 않는다.
2026-08-06: Luna 자체 검증에서 Sol FAIL 보완을 진행했다. 탐색 중 접촉 원장 선점 문제를 제거하고, 실제 소비 선분에서만 원장을 갱신하도록 고쳤다. activation에 시각 direction과 별도 motionDirection·velocityBefore·velocityAfter를 추가하고 이벤트 resultingVelocity를 실제 적용 속도에 연결했다. 물리 집중 회귀 27개, 방향별 Golden과 이벤트 재생·텔레메트리 통합을 포함한 집중 검증을 진행했으며 최종 Sol 판정은 보류한다. 변경 상태는 작업 트리에만 남겨 commit·push하지 않는다.
2026-08-06: Luna 자체 재검증 게이트는 물리 집중 28개, Golden·재생·텔레메트리 집중 12개, 전체 `flutter test` 454개 통과로 기록됐다. `flutter analyze`, 생성 카탈로그 `--check`, Web Release 빌드, `git diff --check`도 성공했다. 이는 Luna 검증 증거이며 Sol 승인 또는 PASS 판정으로 간주하지 않는다.
2026-08-06: Sol 2차 FAIL: 상한 240의 반복 안전 근거 부족 → 48로 제한 및 경계 물리 회귀 추가
2026-08-06: Sol 2차 보완에서 기준 속력 48 연쇄 회귀의 경로 밖 가로 벽 fixture를 경로상의 세로 벽으로 교체했다. `crate_48`이 `chain_wall_48`에 실제 impact를 남기고, 최종 crate `hitBounds` 전체가 360x560 논리 보드 안에 있으며 벽 hitBounds 반대편으로 터널링하지 않는 조건을 추가했다. 벽의 position·size·movable·solid·active·open·pressed 불변, chainSafetyDiagnostics 비어 있음, 유한 이벤트 수치와 동일 입력의 activation·event ID·최종 상태 결정론을 함께 검증했다. 관련 29개와 전체 455개 테스트가 통과했으며 Sol 최종 판정 전 상태를 유지한다.
2026-08-06: Sol은 PS-OBJ-01의 데이터·접촉 원장·우선순위·연쇄 이동·고속 벽 충돌·결정론·runtime probe와 390x844·768x1024의 기본·작동·팝업·저모션·수직 방향 Golden 10장을 독립 검토했다. 파워 슬라이더 집중 41개와 전체 455개 테스트, `flutter analyze`, 생성 카탈로그 `--check`, Web Release 빌드, `git diff --check`가 모두 통과했다. 기존 1~4단계 JSON과 생성 카탈로그가 유지되고 기준 속력 상한 48에서 벽 불변·비터널링·안전 종료가 증명되어 Sol이 PS-OBJ-01을 PASS 판정한다.
2026-08-06: PS-STAGE-02는 5단계 `비워진 속성`을 기준 포함 `stage_drained_01~04`로 추가한다. 속성을 공으로 옮길 때 원본이 마지막 속성을 잃으면 이동 가능해지는 `movableWhenDrained` 계약을 도입하되, 기존 모든 속성 원본에는 전역 적용하지 않고 5단계의 명시된 다섯 원본에만 사용한다. validator는 속성이 없는 기물과 홀·벽·스위치·문·파워 슬라이더·회전 반사판의 잘못된 설정을 안정 오류 코드로 거부한다. 일반 돌 1.6과 무거운 돌 4.4의 질량비, 속성을 잃은 젤리·점착 원본의 일반 고체 전환, 질량비 기반 이동 거리, 연쇄 충돌 재계산을 회귀로 고정한다. 네 패턴 모두 원본 이동 대표 해법과 무속성 우회 성공을 제공하고 4번은 무거움·탄성 중 선택할 수 있다. 2도·2% 전수 격자에서 대표 원본 이동 성공 영역은 29·53·667·34셀이고 최대 연결 영역은 23·28·667·24셀이다. 선택·비워짐·결과 Golden 6장과 전체 화면 5해상도 Golden을 생성했으며, 4단계 완료 팝업의 해금 문구로 생긴 순위표·버튼 시각 겹침도 패널 높이 보정으로 제거했다. 최종 전체 회귀와 독립 Luna 검토 전이므로 commit·push하지 않는다.
2026-08-06: PS-STAGE-02 최종 감사에서 완료 팝업 기존 Golden 2건과 속성 없는 점착판 합성 fixture 2곳을 새 명시적 재질 계약에 맞춰 갱신했다. 독립 Luna가 지적한 재현 빈틈을 보완해 5단계 단일 발사 fixture 네 개가 `transferSourceId`로 실제 속성 이전을 수행하고 원본의 빈 속성·이동 가능·`drained` 상태를 검증한 뒤 지문을 재생한다. 다섯 단계 전체 클리어도 새 `ProgressStore`와 실제 섬 지도에서 안정 ID로 복원한다. 역사 문서 두 곳에는 2026-08-03의 4단계 스냅샷임을 명시했다. 최종 `flutter analyze`, 전체 542개 테스트, 단일 리플레이 20개, 다중 리플레이 25개, 생성기 `--check`, Web Release 빌드와 `git diff --check`가 통과했고, Luna 재감사도 P0/P1 없이 PASS했다. Sol은 구현·화면·문서·회귀 근거를 확인해 PS-STAGE-02를 PASS 판정한다.
2026-08-07: PS-STAGE-03는 6단계 `속도를 되살리는 길`을 기준 포함 `stage_speed_01~04`로 추가한다. 마지막 구간 재가속, 벽 반사 후 진입, 상자 이동 후 재가속, 좌·우 발판 선택을 실제 `PowerSliderActivation`과 사건 순서로 고정하고, 네 패턴 모두 약한 발사와 슬라이더 미사용 우회 성공 영역을 확인했다. 2도·2% 전수 격자의 전체 성공은 1,515·1,653·604·1,079개이며 대표 재가속은 5.617→42, 5.885→40, 3.239→44, 3.847→46이다. 총괄 감사에서 3번 약한 입력 222도·28%가 문서에만 있던 공백을 fixture로 보강하고, 5단계 결과가 마지막 단계용 `처음부터 다시`를 기대하던 회귀를 `6단계가 열렸습니다.`와 `다음`으로 교정했다. 불필요한 지도 2,000픽셀 강제 캐시도 제거했다. 전체 564개 테스트, `flutter analyze`, 생성기 `--check`, Web Release 빌드가 통과했으며 독립 QA 최종 판정 전이므로 아직 commit·push하지 않는다.
2026-08-07: PS-STAGE-03 독립 QA 첫 감사는 3번의 약한 경로에도 상자 이동을 결합해야 한다고 해석해 FAIL을 냈다. 총괄은 2도·2% 전수 격자와 원문을 재검토해 대표 210도·56%의 `상자 충돌·이동 → 재가속 → 홀`과 약한 222도·28%의 `저출력 재가속 → 홀`이 서로 다른 허용 해법이며, 둘을 한 정답으로 강제하는 것은 특정 기믹 비강제 원칙에 어긋남을 명시했다. 대신 네 대표 경로 모두 발판 진입 전 속력이 최초 속력보다 낮고 작동 후 높아지는 조건을 직접 회귀로 보강했다. 집중 17개가 통과했고 독립 QA 재감사는 P0·P1·P2 없이 PASS했다. Sol은 스테이지·물리·진행도·화면·문서 근거를 확인해 PS-STAGE-03을 PASS 판정한다.
2026-08-07: PS-STAGE-03은 `stage_speed_01~04` 네 패턴과 `6. 속도를 되살리는 길`을 추가했다. 파워 슬라이더 기존 계약을 사용해 마지막 구간 재가속·벽 반사 후 진입·상자 이동 후 후속 재가속·복수 슬라이더 선택을 실제 `ShotResolver` 결과로 검증했으며, 모든 패턴에 슬라이더 미사용 우회 성공을 남겼다. 2도·2% 탐색에서 전체/슬라이더/약한 발사/우회 성공은 각각 1,515/1,290/283/225, 1,653/1,040/70/613, 604/396/33/208, 1,079/752/52/327이다. 대표 속도 변화와 벽·상자 impact 선행, 접촉 ID 중복 없음, 기준 속력 48 이하, 고속 발사 유한 종료·고속 터널링 부재를 전용 16개 테스트로 고정했다. 6단계 포함 단일 리플레이 24개·다중 리플레이 30개, 섬 지도·목표 문구·README·QA 검증 문서를 갱신했다. Flutter 집중 테스트는 통과했으며 커밋·푸시·서버 실행은 하지 않는다.
2026-08-07: PS-STAGE-04는 `stage_persistent` 7단계와 네 패턴을 추가했다. 대표 두 발 해법은 1번 과거 공 쿠션, 2번 무거운 첫 공의 스위치 작동 후 점착 고정과 문 유지, 3번 점착 과거 공 범퍼, 4번 상자 스토퍼 연쇄이며, 같은 둘째 발만 준비 없이 쏘면 네 패턴 모두 실패한다. 대표·단일 발사 우회 입력은 모두 UI 최소 힘 12% 이상과 2% 눈금에 맞췄고, 7단계 단일·다중 리플레이의 모든 입력도 12% 이상으로 생성한다. 과거 공 팝업은 순번·속성·이동/고정 상태를 한글로 표시하고 속성 옮기기 대상으로 쓰지 않는다. 5개 해상도의 시작 화면과 과거 공 팝업, 섬 지도 골든을 확인했으며 전체 585개 테스트, `flutter analyze`, 생성기 `--check`, Web Release 빌드가 통과했다. 독립 QA 첫 P1인 10% 리플레이와 P2인 준비 없는 둘째 발·낡은 문서 계약을 보강했고, 재감사는 P0·P1·P2 없이 최종 PASS했다. commit/push 전이며 서버는 최종 통합까지 실행하지 않는다.
2026-08-07: PS-SCORE-01은 기본 클리어와 분리된 `CreativeChainScoreAnalyzer`를 추가했다. 최종 홀 사건의 부모 계보와 출발 기물·경로 보완을 통해 인과 깊이, 기물 타입·개체 다양성, 벽 반사, 과거 공, 무거움·탄성·점착·뾰족함 발동·소모, 파워 슬라이더, 판 상태 변화, 이동 기물, 영속 준비 샷, 최소 샷, 선택 도전을 한글 근거와 Breakdown으로 산출한다. 같은 접촉 0.25배, 같은 벽면 최대 0.2배, 미세 진동 제외, 인과 충돌 12건·무관 충돌 3건 절대 상한과 개체별 전용 보너스 중복 방지를 적용했다. 충돌 주체 속성은 정수 비트 마스크로 사건에 복사해 원본 Set 변경이 점수·리플레이를 바꾸지 않으며, 연쇄 충돌은 실제 속도·질량 기반 충격량을 기록한다. 기존 공 홀 진입의 누락 경로에도 홀 충돌·상태 사건을 보충했다. 독립 QA가 지적한 근거 합계, 준비 상태 지속성, 속성 메타데이터, 기존 공 홀 사건, 가변 Set을 모두 보완한 뒤 P0·P1 없이 최종 PASS했다. 집중 17개와 전체 602개 테스트, `flutter analyze`가 통과했고 단일 28개·다중 35개 리플레이 fixture를 새 사건 서명으로 재생성했다. 점수 저장·결과 UI·랭킹·8단계 연결은 후속 작업으로 남기며 서버는 최종 통합까지 실행하지 않는다.
2026-08-07: PS-STAGE-05는 `stage_chain_score` 8단계와 네 패턴을 추가한다. 각 패턴은 한 발 직접 클리어와 두 발 고연쇄 경로를 함께 제공하며, 실제 `ShotResolver` 탐색에서 직접 경로는 모두 1035점, 3쿠션·점착 과거 공은 1868점, 벽·상자·과거 공은 1753점, 발판·돌·벽·과거 공은 2006점, 벽·풍선·발판·젤리·과거 공은 1982점으로 재현됐다. 첫 패턴의 기존 한 점짜리 경로는 점착 받침 기반 95개 성공점·45개 최대 연결 영역으로 교체했고, 네 패턴의 직접/고연쇄 최대 연결 영역은 각각 539/45, 664/7, 507/120, 217/33이다. 벽은 모든 결과에서 위치와 비이동 상태를 유지한다.
2026-08-07: PS-STAGE-05 QA 보정에서 과거 공 히트박스를 보이는 구 크기와 일치시키고 패턴 2 상자를 확대했다. 1도 논리 조준과 샷 입력·속성 행동 저장 복원을 추가했으며, 공식 고연쇄 점수는 1868·1753·1909·2034점으로 갱신됐다. 고연쇄 성공점/최대 연결 영역은 140/45, 38/38, 822/822, 33/33이다. 8개 공식 리플레이는 반복 결정론·유한값·안전 중단 부재·벽 불변·ID 고유성·최종 성공을 구조화해 검증한다.
2026-08-07: 8단계 연결 작업에서 섬 지도 설명·에셋 배열이 7개로 고정돼 여덟 번째 카드에서 범위 오류가 날 수 있는 문제를 수정했다. `StagePatternSession`은 실제 셔플 백 추첨과 A/B `RunState` 저장을 연결해 진행 중인 패턴·seed를 재시작 뒤 복원하고, 클리어 직후 다음 단계 패턴을 선추첨해 `다음` 진입에서 재사용하며, 최고 연쇄 점수와 최소 샷 수를 보존한다. 단계별 발사 결과를 보존해 클리어 시 창의 연쇄 점수를 계산하며 패턴별 추가 도전은 최종 홀 포획의 인과 사건 종류와 순서로 판정한다. 결과 팝업은 현재 패턴 문구·총점·모든 한글 근거를 표시하고 되감기·재시작은 분석 기록도 함께 되돌린다. 네 패턴 직접·고연쇄 공식 리플레이 8개와 성공 영역, 정적·런타임 Validator, 생성 카탈로그, 전체 `dart analyze`, `git diff --check`는 통과했다. Flutter 전체 회귀·Golden·Web 빌드는 외부 SDK 캐시 승인에 걸린 Codex 사용량 제한 때문에 아직 실행하지 않았으며, 완료 전에는 PS-STAGE-05를 최종 PASS로 판정하지 않는다.
2026-08-07: PS-STAGE-05 저장·입력·안전성 재감사에서 한 샷의 여러 속성 행동과 복제 코어 획득·소비·환급을 `RunState` 한 기준으로 통합하고, 성공 샷 저장 직후 종료된 런의 완료·지도 기록 복구를 추가했다. seed 없는 구형 샷은 동일 패턴의 다음 셔플 주기에 결합하지 않는다. P2와 P4 고연쇄를 각각 5·7개와 6·5개의 연속 1도 구간으로 재설계했고 P3 첫 공의 상단 벽 겹침도 제거했다. 8개 공식 리플레이는 총 598개 이동 선분, 슬라이더 포함 22개 터널링 후보, 모든 샷 종료 겹침, 필드 이탈, 홀 포획 후 후속 충돌, 소프트락, 벽 불변과 결정론을 통과했다. 공통 단일 32개·다중 40개 리플레이도 최신 카탈로그로 재생성했다. 직접 `dart analyze`와 카탈로그·성공 영역·리플레이 생성기 동기화 검사는 통과했으며 Flutter 전체 회귀는 사용량 제한 해제 뒤 실행한다.
2026-08-07: PS-STAGE-05 독립 QA의 저장 P1 네 건과 검증 P2 두 건을 보정한다. 복제·옮기기 리플레이는 소비 전 코어 수에서 시작하고, 구형 코어는 최초 RunState로 한 번만 마이그레이션한다. 클리어 런 저장 실패 시 성공 팝업·보상·다음 이동을 차단하며 RunState 완료와 지도 저장 사이 종료는 앱 시작 시 멱등 복구한다. 소프트락은 준비 샷 결과에서 실제 다음 입력을 재실행해 결과 지문까지 비교하고, 각도 폭은 가장 긴 연속 인덱스만 집계한다. 1번 점착 받침과 홀 판정을 조정해 첫째·둘째 3·6개 연속 각도, 160개 성공점과 70개 연결 영역을 확보했다. 공식 8개 리플레이는 604개 이동 선분, 24개 터널링 후보, 4개 후속 샷 재실행을 증명한다. Flutter 전체 회귀와 독립 재감사 전이므로 아직 commit·push하지 않는다.
2026-08-07: PS-STAGE-05 독립 재감사는 이전 P1-1~P1-4와 P2-1~P2-2가 모두 코드·직접 Dart 증거 기준으로 해소됐고 새 P0·P1·P2 결함은 없다고 확인했다. `dart analyze`, 카탈로그·성공 영역·공식 리플레이 생성기 `--check`, JSON 검사와 `git diff --check`가 통과했다. 그러나 외부 Flutter SDK 사용량 제한으로 `flutter analyze`, 전체 위젯·Golden 회귀와 Web Release를 실행하지 못했으므로 최종 판정은 `FAIL(게이트 미검증)`이며 commit·push하지 않는다.
2026-08-07: 완료 복구 후속 감사에서 RunState 완료와 ProgressStore 사이 종료 시 최고 샷·보너스가 누락되고, 복원된 다중샷을 되감을 때 범퍼·스위치·비워진 원본 누적 이력이 초기화될 수 있는 공백을 확인했다. 완료 RunState에서 지도·최고 샷·보너스를 멱등 복구하고, 성공 샷만 저장된 경우 1~7단계 보너스 인과와 8단계 연쇄 분석을 실제 결과로 다시 계산한다. 저장 실패는 일반 발사 실패와 분리해 되감기·초기화를 차단하고 같은 저장 트랜잭션만 재시도한다. 5단계 비워진 원본 성공 샷 종료 복구와 저장 실패 후 재시도 위젯 회귀를 추가했으며 직접 `dart analyze`와 생성기 동기화는 통과했다. Flutter 전체 회귀 전이므로 최종 판정과 commit·push는 보류한다.
2026-08-07: 저장 복구 독립 QA는 표식 없는 구형 완료 RunState의 코어 중복 지급, 최고 기록 저장 실패 후 메모리 조기 갱신으로 인한 재시도 누락, 실제 앱 재실행 후 되감기 증거 부재를 P1로 지적했다. 구형 Progress 지급 여부는 기존 RunState 수량을 바꾸지 않고 legacy 표식만 추가하며, UI 지급 상태는 현재 단계 ID별로 계산한다. 해금·보너스·최고 기록은 실제 저장 성공 뒤에만 메모리에 반영한다. 재실행으로 복원한 8단계 샷을 화면에서 되감고 새 RunState에서 로그가 제거됐는지 확인하는 통합 회귀를 추가했다. seed 없는 구형 현재 샷은 로그 접미 구간일 때 현재 seed로 원자 마이그레이션하고 과거 주기에는 결합하지 않는다. 독립 재감사와 Flutter 전체 회귀 전이므로 commit·push하지 않는다.
2026-08-07: 후속 독립 QA의 P1 두 건과 P2 세 건을 보정한다. 복제 코어 지급 단계 ID 집합을 `ProgressStore` 스키마 3에 저장하고 모든 라우터 미러 저장에 연결했으며, 구형 전역 불리언과 중간 버전 legacy 표식은 실제 과거 보상 단계 ID로 수량 증가 없이 옮긴다. 코어 보상 콜백 실패도 전용 저장 재시도 팝업으로 복귀해 화면 잠금을 막고, 보너스 저장과 코어 보상 실패 주입 회귀를 추가했다. 동일 패턴의 추첨 이력이 여러 개인 구형 무시드 샷은 현재 seed로 추정하지 않고 현재 발사 복원에서 제외한 뒤 한글 안내를 표시한다. 직접 `dart analyze`, 카탈로그·8단계 공식 리플레이·성공 영역 생성기 `--check`, `git diff --check`는 통과했고 독립 재감사와 Flutter 전체 게이트는 아직 남아 있다.
2026-08-07: 독립 Luna 재감사는 `StateError`가 `Exception`에 포함되지 않아 저장 실패 주입이 재시도 UI에 도달하지 않는 점, 과거 보상 단계의 안정 ID가 실제 `stage_chain_gate`와 다르던 점, `SharedPreferences`의 false 반환을 성공으로 보던 점을 P1으로 판정했다. 모든 사용자 입력·저장 콜백 경계가 `StateError`를 포함한 저장 실패에서 잠금 상태를 해제하도록 보완하고, 과거 보상 ID를 카탈로그의 실제 안정 ID로 교정했다. 진행 저장의 모든 set·remove 결과를 검사해 false면 `StateError`로 승격한다. 반복 주기 무시드 복사 행동은 임의 재생·환급하지 않고 저장된 코어 수량을 보존한다는 호환 정책과 회귀를 명시한다. 이 보정은 재감사 전이므로 아직 PASS·commit·push하지 않는다.
2026-08-07: 두 번째 독립 재감사는 이전 P1 네 건이 모두 해소됐음을 확인하고, 정상 seed 샷과 모호한 구형 샷이 함께 있을 때 안내가 누락되는 경로와 독립 게임 화면·개발 진단 메뉴의 비동기 저장 오류 처리를 P2로 지적했다. 복구 안내는 정상 샷 수와 제외한 구형 샷을 항상 함께 표시하고, 복제 코어 저장 수량 보존도 알린다. 다음 단계·진행 초기화·전체 해금·진단 코어 설정은 저장 성공 뒤에만 화면 상태를 바꾸며 실패 시 재시도 가능한 한글 안내를 남긴다. 최종 재감사와 Flutter 게이트 전이므로 PASS·commit·push를 계속 보류한다.
2026-08-07: 세 번째 독립 재감사는 혼합 구형 로그 안내와 독립·진단 저장 실패 보정을 확인했지만, 같은 세션에서 다음 단계로 이동한 뒤에도 구형 로그 경고 플래그가 남는 P2 상태 누출을 발견했다. 선추첨된 다음 패턴 또는 새 셔플 패턴을 현재 단계로 활성화할 때 모호성 경고와 제외된 복사 행동 수를 초기화하고 실제 다음 단계 선택 회귀를 추가한다. Flutter 전체 게이트와 최종 재감사 전까지 승인·commit·push는 보류한다.
2026-08-07: 최종 독립 Luna 감사는 다음 패턴 활성화 뒤 구형 로그 모호성 상태 초기화와 혼합 로그 회귀를 확인했다. 앞선 저장 P1·P2를 포함해 P0·P1·P2 모두 PASS했으며 직접 `dart analyze`, 카탈로그·8단계 리플레이·성공 영역 생성기 동기화, JSON 구문, `git diff --check`도 다시 통과했다. 코드 감사는 PASS지만 외부 Flutter SDK 사용 제한으로 `flutter analyze`, 전체 테스트, Golden, Web Release를 실행하지 못했으므로 PS-STAGE-05 최종 승인·commit·push는 계속 보류한다.
2026-08-07: 외부 Flutter SDK 제한 해제 뒤 전체 회귀에서 저장 런의 미래 `startedAt`과 실제 기기 시각이 역행할 때 `updatedAt` 검증으로 복원이 중단되는 결함을 확인했다. `StagePatternSession` 갱신 시각을 기존 `updatedAt` 이상으로 단조 보정하고 시계 역행 회귀를 추가했다. 위젯 테스트는 매 테스트마다 SharedPreferences 모의 저장소를 초기화하고, 지속 애니메이션 화면에서는 무제한 `pumpAndSettle` 대신 실제 저장 큐와 제한 프레임을 함께 기다린다.
2026-08-07: 발사 뒤 과거 공에만 `hitboxScale=1`을 강제하던 회귀를 제거해 발사 전 공의 정밀 히트박스를 그대로 유지한다. 7단계 대표 경로를 복구하고 8단계 1번 고연쇄를 160도·20% → 158도·96%의 4쿠션 경로로 다시 탐색했다. 새 경로는 1,970점, 248개 성공점, 63개 최대 연결 영역, 첫째 3개·둘째 4개 연속 각도 구간을 가진다. 공식 8개 리플레이와 해법 영역을 재생성했으며 집중 물리·점수·팝업·리플레이 테스트 50개가 통과했다.
2026-08-07: 외부 Flutter SDK 제한 해제 후 PS-STAGE-05 최종 실행 게이트를 완료했다. `flutter analyze` 이슈 0건, 전체 Flutter 회귀 682개, 8단계 시작 화면 5해상도·결과 팝업 5해상도·섬 지도 2해상도 Golden, 단일 32개·다중 40개·8단계 공식 8개 리플레이, 생성기 동기화, JSON, `git diff --check`, Web Release 빌드가 모두 통과했다. 지속 애니메이션 화면의 테스트는 무제한 settle 대신 저장 완료와 제한 프레임을 기다리며, 물리 지문은 대표 경로의 성공·충돌 순서를 확인한 뒤 현재 엔진 결과로 갱신했다. 별도 Chromium 콘솔 감사와 실제 기기 발견률은 10단계 통합 게이트에서 수행한다.
2026-08-07: PS-STAGE-05 최종 독립 감사가 진행 저장 전에 메모리 지도 해금을 적용하는 P1을 발견했다. 완료 런은 별도 재개 권한으로 접근 검사만 통과시키고, 단계 해금·최고 기록·추가 도전 저장이 모두 성공한 뒤에만 메모리 해금을 적용하도록 순서를 교정했다. 첫 지도 저장 실패 때 `1 / 8`을 유지하고 재시도 성공 뒤에만 2단계로 진입하는 실제 라우터 회귀를 추가했으며 README의 단계 수 불일치와 결과 팝업 Golden 공백도 함께 해소했다.
2026-08-07: PS-STAGE-05 독립 재감사는 저장 순서 P1과 문서·Golden P2 해소를 확인하고 P0·P1 없음으로 판정했다. 남은 개발 진단 메뉴의 영문 약어 P2는 `물체 식별자 표시`와 `상태 데이터 복사`로 한글화했으며 진단 메뉴 테스트 3개와 정적 분석이 통과했다. Sol은 미해결 P0·P1·P2 없음으로 8단계를 최종 PASS 판정한다.
2026-08-07: PS-STAGE-06은 `stage_rotating_reflector` 9단계와 네 패턴을 추가한다. 한 판 2회 회전, 두 판 순서 회전, 과거 공의 판 작동, 파워 슬라이더 뒤 판 회전을 대표 두 발 경로로 재현하며 모든 패턴은 반사판을 쓰지 않는 직접 우회도 허용한다. 회전은 충돌의 현재 면 반사 뒤 정확히 90도 누적되고 다음 충돌부터 적용되며, 벽과 판은 움직이지 않는다. 직접 우회 최대 연결 영역은 477·48·213·180셀, 반사판 경로는 253·435·9·89셀이다. 3번은 `347도/56% → 293도/84%`를 대표로 삼고 연속 두 첫 조준 각도를 확보했다. 첫 샷 저장 뒤 재시작해도 추첨 패턴·판 방향·회전 수·둘째 샷 지문이 같다. 섬 지도와 반사판 상태 팝업, 5해상도 플레이 Golden을 추가했고 공용 리플레이는 단일 36개·다중 45개로 확장했다. 독립 감사 P2였던 JSON 의존 영역 검사와 1번 한정 재개 검사를 실제 엔진 전체 비교·네 패턴 재개 검사로 보완했다. 전체 704개 테스트, 정적 분석, Web Release, 생성기·JSON·diff 검사가 통과했고 독립 재감사에서 미해결 P0·P1·P2 없음으로 판정했다.
2026-08-07: PS-STAGE-07은 `stage_property_shot` 10단계와 A~D 네 패턴을 추가했다. A는 실제 무거움 이전 공의 `a_crate → a_switch`, B는 첫 샷 회전 뒤 둘째 샷의 `b_reflector → b_bumper → hole`, C는 점착을 옮긴 공만 속성 없는 일반 받침에 고정된 뒤 `spent_ball_1` 쿠션과 `c_crate → c_balloon`, D는 슬라이더·돌·내부 벽·과거 공 연쇄를 대표 경로로 고정했다. 같은 입력에서 속성을 제거하거나 회전 전 상태를 쓰는 반례, source-target 충돌 순서, 의도 기믹을 쓰지 않는 직접 우회, 같은 초기 상태 반복 결정론을 검증했다. 직접/연쇄 성공·최대 연결 영역은 A 56/56·67/25, B 33/33·210/84, C 37/37·14/7, D 58/58·407/156이다. 섬 지도 10단계 카드와 한글 목표, 5해상도 플레이·2해상도 지도 Golden, 단일 40개·다중 50개 공용 리플레이를 반영했다. 외부 Flutter SDK 제한 해제 뒤 정적 분석, 전체 724개 회귀, Web Release, 생성기·JSON·diff 검사가 통과했고 독립 Sol 최종 재감사에서 미해결 P0·P1·P2 없이 PASS했다. 서버는 최종 통합 단계까지 실행하지 않는다.
2026-08-07: PS-REWARD-01의 결정론 보상 후보 8종과 선택·사용 저장 경계를 연결했다. 단계와 패턴 seed가 같으면 같은 세 후보를 복원하고 선택 전 다음 이동을 막는다. 재도전은 기존 선택 표식을 찾아 다시 지급하지 않으며 일회성 사용과 단계별 사용은 서로 다른 표식으로 A/B RunState에 저장한다. 발사 취소, 과거 공 회수, 첫 충돌 대상 안내, 선택 도전 보호, 실패 충돌 순서 강화, 공 꾸미기, 단계별 기록 보호를 실제 플레이 흐름에 연결했고 복제 코어를 포함한 8종 모두 화면 결과를 가진다. 독립 QA의 저장 경계 P1을 반영해 첫 충돌 안내와 발사 입력, 선택 도전·기록 보호와 단계 완료를 각각 한 RunState 저장으로 묶고, 재도전 시도 번호로 과거 공 회수 대상을 구분했다. 충전 취소는 저장 대기 전에 입력 세션을 닫고 공 꾸미기는 같은 화면에서 즉시 갱신하며 저장된 `runCompleted`도 결과 화면으로 복원한다. 320×700·390×844·큰 글자 1.3배·768×1024 보상 Golden을 직접 확인했고 정적 분석, 전체 758개 회귀, 생성 카탈로그·JSON·diff 검사, Web Release 빌드가 통과했다. 독립 최종 재감사는 진행 중이다.
2026-08-07: PS-REWARD-01 후속 저장 감사에서 현재 재도전 횟수와 최고 기록 혼동, 기록 보호 완료 상태 복원 누락, 되감기 직후 과거 공 회수 범위 지연, 발사 취소·되감기·회수의 비동기 경쟁을 발견했다. 단계별 최고 기록은 최소값으로 보존하되 완료 콜백은 현재 시도 값을 반환하고, 기록 보호 사용은 단계와 시도 번호를 함께 저장한다. 되감기 콜백은 최신 보상 상태를 자식 화면에 즉시 반환하며, 상태 변경 저장 중에는 발사·재시작·속성 행동·다른 보상 사용을 상호 차단한다. 공통 단계 행동 잠금 보강 전 정적 분석, 전체 763개 회귀와 Web Release는 통과했다. 이후 재시작·다음·기록 재도전의 공통 잠금과 회귀 2건을 추가했으나 외부 Flutter SDK 사용량 한도가 다시 발생해 최종 포맷·전체 회귀·Web Release·독립 PASS·commit·push는 보류한다.
2026-08-08: 외부 Flutter SDK 제한 해제 뒤 PS-REWARD-01 최종 실행 게이트를 재개했다. 보상·저장·중복 입력 집중 회귀 125건, 전체 Flutter 회귀, `flutter analyze` 이슈 0건, Web Release 빌드가 통과했다. 재시작·다음 단계·기록 재도전은 공통 비동기 잠금으로 직렬화하고, 되감기·발사·속성 행동·보상 사용과의 교차 실행도 차단한다. 누락됐던 중복 재시작 테스트 카운터의 지역 선언을 바로잡아 테스트가 실제 제품 경합을 검증하도록 했다.
2026-08-08: PS-REWARD-01 독립 Luna 감사는 같은 `StagePatternSession`의 서비스 API를 동시에 호출할 때 마지막 저장이 앞선 보상 사용을 덮어쓸 수 있는 P1과 단계 기록 보호 키·런 결과 문구·제거된 보상 ID 복구의 P2를 발견해 최초 FAIL했다. 모든 공개 상태 작업을 인스턴스별 비동기 큐로 직렬화하고, 기록 보호 키를 `stageId|현재시도`로 통일했으며, 알 수 없는 후보는 같은 seed의 정상 세 후보로 원자 복구한다. 결과 화면은 실제 데이터 의미에 맞춰 `단계별 최고 기록 합계`로 교정했다. 서로 다른 두 보상의 동시 소모, 독립 기록 보호 완료값, 제거된 후보 복구 회귀를 추가했고 집중 128개·전체 768개 테스트, 정적 분석 이슈 0건, Web Release, 생성 카탈로그·JSON·diff 검사가 통과했다. Luna 재감사는 미해결 P0·P1·P2 없음으로 PASS했다.
2026-08-08: PS-DAILY-01A 구현을 시작했다. UI 연결 없이 KST 고정 날짜·`daily-challenge-v1`·unsigned 32비트 루트 시드·6자리 시드 코드 정의를 추가하고, `StagePatternSession`에 고정 루트 시드·안정 런 ID·해석기 버전 주입 경계를 만들었다. 고정 시드의 완료 후 새 도전은 일반 런의 임의 xor를 사용하지 않는다.
2026-08-08: PS-DAILY-01A에 `NamespacedRunStateBackend`와 날짜·정식/연습 모드별 오늘의 도전 RunState 저장소를 추가했다. 일반 런 key·셔플 백·ProgressStore는 변경하지 않으며, 별도 `DailyChallengeRecordStore`가 정식 시작 시도 수·완료·최고 총점·최고 단계별 샷 합계·UTC 갱신 시각만 기록한다. 연습 결과는 기록을 변경하지 않고, 손상 JSON·구형 필드 누락은 해당 날짜 기본값으로 복구한다.
2026-08-08: PS-DAILY-01A 초기 감사에서 정식 시도 중복, 단일 기록 쓰기, 버전 혼합, RunState 완료와 공식 기록 사이 복구 계약이 P1으로 확인됐다. 공식 기록을 날짜·도전 버전·물리 버전별 checksum/revision A/B 슬롯으로 바꾸고 정식 RunState를 시도별 namespace로 분리했다. 연습은 공개 API에서 메모리 저장소만 사용한다.
2026-08-08: PS-DAILY-01A 후속 감사에서 활성 시도 교체, 여러 저장소 인스턴스의 갱신 경합, 호출자 입력값만 신뢰하는 완료 기록을 보강했다. 활성 시도는 명시적 포기 전 교체할 수 없고, RunStateStore와 공식 기록 저장소는 같은 실제 backend 기준 공유 큐로 직렬화한다. 공식 완료는 최신 RunState의 `runCompleted` phase·runId·rootSeed·resolverVersion·revision을 직접 대조하고 총점·발사 합계를 저장 상태에서 산출해 앱 종료 뒤 멱등 복구한다.
2026-08-08: PS-DAILY-01A 집중 회귀 68개와 전체 Flutter 회귀 791개, `flutter analyze` 이슈 0건, Web Release, 생성 카탈로그·JSON·diff 검사가 통과했다. 공식 기록 v1은 출시 전 내부 초안이라 v2로 마이그레이션하지 않고 초기화한다. 최종 독립 재감사 전에는 commit·push하지 않는다.
2026-08-08: PS-DAILY-01A 최종 경쟁 조건 감사에서 완료 대조 직후 동일 고정 시도가 새 런으로 갱신될 수 있는 P1을 보강했다. 완료된 고정 시도는 같은 runId로 다시 시작할 수 없고, 일일 도전 저장소는 쓰기 가능한 RunStateStore를 외부에 노출하지 않으며 검증된 읽기 전용 snapshot만 공식 기록 대조에 제공한다. 새 정식 시도는 별도 attempt namespace를 사용하면서 같은 날짜 루트 시드를 유지한다.
2026-08-08: 완료 불변성 재감사에서 `StagePatternSession.store` 공개 필드가 직접 저장 우회 경로가 될 수 있어 내부 전용으로 바꿨다. 기본 제공 backend는 동일 실제 저장소를 가리키는 동기화 identity를 제공하며, 사용자 정의 adapter의 동일 계약 구현 책임을 QA 문서에 명시했다.
2026-08-08: PS-DAILY-01A 최종 독립 Luna 재감사는 완료 고정 런 불변성, 읽기 전용 snapshot, 실제 RunState 완료 대조, 시도·버전·namespace 격리와 A/B 복구를 확인하고 미해결 P0·P1·P2 없음으로 PASS했다. 최종 게이트는 집중 68개, 전체 791개, 정적 분석 이슈 0건, Web Release와 생성 카탈로그·JSON·diff 검사 통과다.
2026-08-08: PS-DAILY-01B UI 통합을 시작했다. 홈에 한글 오늘의 도전 진입과 KST 날짜·시드 코드·공식 기록 개요를 추가하고, `attempt_N` 정식 시도와 MemoryRunStateBackend 연습 흐름을 분리했다. 생성 카탈로그 10개 ID 순서를 제품 경로에서 검증하며, 날짜별 RunState와 일반 ProgressStore를 분리한다.
2026-08-08: PS-DAILY-01B 사전 QA 요구를 반영해 오늘의 도전 라우터의 상태 전이를 하나의 비동기 작업열로 직렬화하고, GameScreen에 `GameProgressPersistencePolicy.disabled`를 추가했다. playing·stageCompleted·rewardSelectionPending·rewardSelectionCompleted·runCompleted 복구를 연결했으며, 공식 runCompleted는 `reconcileCompletedRun` 성공 뒤에만 결과를 표시한다.
2026-08-08: PS-DAILY-01B 위젯 회귀 6개와 기존 일반 위젯 회귀 79개를 통과했다. 홈 진입, 정식 중복 탭, 연습 비기록·일반 진행 비오염, 활성 시도 이어하기, KST 자정 전환, 열 단계 완료 기록 복구를 검증했다. 390×844·768×1024 개요 Golden은 테스트로 생성하며 사람의 시각 확인으로 간주하지 않는다. 커밋·푸시는 수행하지 않는다.
2026-08-08: PS-DAILY-01B Sol 부분 diff 지적을 반영했다. 복원 시 `activeAttemptId`를 `completedAttemptId`보다 우선하고, 공식·연습 결과 모드와 재시작 문구를 분리했다. 새 단계는 0번에서만 열고, 현재 단계와 다른 클리어·10개 ID가 모두 없는 완료를 라우터 경계에서 거부하며, 일일 GameScreen에는 일반 ProgressStore persistence policy를 disabled로 전달하고 개발 진단 UI를 숨긴다. 활성 재시도 우선·연습 결과·ProgressStore spy·skip/reorder 거부·320×700/390×844 큰 글자 overflow 회귀를 추가했다.
2026-08-08: PS-DAILY-01B 전용 83개 회귀가 통과했다. 위젯 11개는 홈 진입, 중복 탭, 연습 비기록·일반 진행 비오염, 활성 재시도 우선, KST 자정 전환, 다섯 phase 완료 복구 경계, 결과 의미, 저장 감시, 순서 거부, 작은 화면 큰 글자를 검증한다. 개요 Golden은 320×700·390×844·768×1024·390×844 큰 글자 1.35배를 자동 생성·대조했으며 사람이 시각 확인했다고 주장하지 않는다. 커밋·푸시는 수행하지 않는다.
2026-08-08: PS-DAILY-01B Golden을 직접 확인해 테스트 글꼴과 Material Icons 누락으로 한글·아이콘이 네모로 저장된 문제를 수정했다. 768×1024 화면은 콘텐츠 최대 폭을 560으로 제한해 태블릿 정보 밀도를 조정했다. 수정된 4개 Golden을 다시 확인했고 최종 전체 회귀 817개와 정적 분석 이슈 0건을 통과했다.
2026-08-08: PS-UX-02 사후 감사에서 도움말 다시 보기 버튼이 revision만 저장하고 실제 화면을 열지 않는 결함을 발견했다. 다음 플레이 진입 시 게임 도움말을 정확히 한 번 표시하고 확인 revision을 저장하도록 보완했으며, 설정 제목을 전체 범위에 맞게 게임 설정으로 변경했다. 집중 회귀 36개, 일반 화면 회귀 82개, 최종 전체 회귀 832개와 정적 분석 이슈 0건을 통과했다.
2026-08-08: PS-DAILY-02에서 오늘의 도전 플레이 HUD의 지도 이동을 메인 메뉴 이동으로 교정하고 홈 아이콘·한글 도움말을 실제 동작과 맞췄다. 단계 완료마다 `RunState.totalScore`를 다시 읽어 기존 HUD 점수에 표시하며, 앱을 나갔다 돌아와도 정식 시도 ID와 단계별 누적 점수가 유지되는 도메인·위젯 회귀를 추가했다.
2026-08-08: PS-REWARD-02에서 공 꾸미기 보상 선택 직후 현재 공과 이후 발사 공에 청록·금색 링과 반짝임을 적용했다. 공통 페인터를 사용해 Flame 게임판과 아이콘의 표현을 맞추고, 물리 반지름·질량·속성은 바꾸지 않았다. 선택 ID만 남은 복원 상태도 공 꾸미기에 한해 인식하며 다른 일회성 보상의 활성화 계약은 유지한다.
2026-08-08: PS-STAGE-08에서 10단계 A 패턴의 홀 포획 범위는 `hitboxScale=1.06`으로 유지하고 왼쪽 가시 벽만 12px 안쪽으로 옮겼다. 무속성 직행은 81개 주변 입력 중 13개만 성공하지만 무거움 연쇄는 124개가 성공해, 우회 해법을 남기면서 기믹 활용을 더 안정적인 기본 경로로 만들었다. 홀 가장자리 포획, 벽 불변, 두 해법의 연결 성공 영역과 다섯 해상도 Golden을 갱신·검증했다.
2026-08-08: PS-REPLAY-01B에서 `ReplayCaptureService`를 추가해 현재 `RunState`의 패턴 추첨, 속성 행동, 샷 입력과 안전한 보상 상태를 `ReplayDocument`로 변환하고 `TraitResolver`·`ShotResolver`로 재생한다. resolver 버전, 카탈로그 지문, 스테이지·패턴·seed·추첨·결과 지문 불일치는 한글 오류 코드로 중단한다. 과거 공 회수 기록은 회수 대상만 있고 샷 사이 시점이 없어 후속 충돌을 정확히 재현할 수 있으므로 임의 추정하지 않고 명시적 호환 불가로 처리한다.
2026-08-08: PS-STAGE-08 통합 회귀에서 10단계 A의 가시 벽 이동으로 낡아진 공용 리플레이 지문 두 건을 확인했다. 생성기로 단일 40개와 다중 50개 전체를 현재 카탈로그에서 다시 탐색·생성하고, 성공·실패 phase와 모든 발의 지문을 재생 비교해 통과했다.
2026-08-08: PS-VALID-03에서 실제 `ShotResolver` 대표 시나리오와 `--validate-runtime` 생산 카탈로그 게이트를 추가했다. 10단계×4패턴은 기존 대표 fixture를 두 번 재생해 결정론·벽·홀·안전중단·풀이 계열·무보상 성공 계약을 검사하며 fixture 누락과 보상 전용 성공을 거부한다. 자동 클리어·경로 차단은 실제 배치, 벽 이동·안전중단·비결정성·홀 통과는 실제 resolver 기반 단일 결함 변이로 전환했다. 홀 통과 규칙을 정책으로 실제 비활성화하는 mutation 테스트가 계약 실패를 확인했다. 집중 테스트 66개, 정적 분석, 40패턴 runtime CLI와 15초 timing bound가 통과했으며 슬라이더·회전판·soft lock 이름 fixture는 scripted evidence로 남는다. 요청에 따라 commit·push는 수행하지 않는다.
2026-08-08: PS-SCORE-02에서 `GameScreen`의 8단계 한정 점수 분석 분기를 제거해 1~10단계 모든 성공 샷을 같은 `CreativeChainScoreAnalyzer`로 계산한다. 일반 런과 오늘의 도전은 같은 분석 총점을 기존 A/B `RunState`의 단계별 최고 점수와 합계 저장 흐름에 전달하고, 모든 클리어 팝업은 한글 점수 근거를 표시한다. 직접 성공은 홀 기본점과 최소 샷 보너스만 받으며 기존 8단계 직접 1,035점·고연쇄 공식·파밍 감쇠·리플레이 서명은 유지한다. 전 단계 표시, 1단계 실제 저장 콜백, 열 단계 누적·재개 회귀를 추가했고 집중 162개와 점수 공식 35개가 통과했다. Luna 범위에서는 commit·push하지 않는다.
2026-08-08: PS-REPLAY-02A에서 결정론 `ReplayDocument`의 canonical JSON을 안정 SHA-256 ID와 최소 목록 메타데이터로 저장하는 bounded 로컬 라이브러리를 추가했다. 별도 revision/checksum A/B 슬롯은 pointer 중단과 최신 손상에서 유효 revision을 복구하고, 용량 초과 시 오래된 비최고 기록부터 정리한다. `StagePatternSession`은 현재 단계의 실제 replay ID를 RunState에 원자 기록하며 새 세션에서도 복원한다. 과거 공 회수 시점이 없는 문서는 저장 전에 명시 거부하고, 실제 캡처 문서를 저장·읽기·재생해 결과 지문을 재검증했다. UI·클립보드·애니메이션 화면은 범위 밖으로 유지했고 commit·push는 수행하지 않는다.
## 2026-08-08 PS-SETTINGS-03 개별 설정 확장

- 설정 스키마를 3으로 올리고 실패 인과·점수·점멸·피드백 14개 항목을
  `SharedPreferences`의 안정 키로 개별 저장·복원하게 했다.
- 실패 재생 속도와 충돌·마지막 접촉·홀 최근접·속성·기믹·경로 표시를
  설정에 연결하고, Flame 논리 좌표 투영 위에 읽기 전용 마커를 그렸다.
- 연쇄 점수 상세를 꺼도 총점은 유지하며, 강한 점멸을 끄거나 저모션이면
  반복 펄스를 정적인 밝기와 윤곽으로 대체했다.
- 새 외부 오디오 패키지는 범위 확장을 피하기 위해 제거했고 기존 Web Audio
  합성 큐를 저빈도 배경 모티프로 재사용했다.
- 집중 회귀 114개와 `flutter analyze` 문제 0건을 확인했다.

## 2026-08-08 최종 리플레이·계측·성능 통합

- 생산 40패턴의 실제 제한 실행 검증과 생성 카탈로그 일치를 CI 수준 명령으로 고정했다. invalid fixture와 실제 물리 변이를 보강하되 슬라이더·회전·소프트락 일부 scripted evidence는 잔여 위험으로 기록한다.
- 개인정보를 담지 않는 폐쇄형 텔레메트리 사건 20종, SHA-256 ID와 최대 24개 A/B 리플레이 라이브러리, 일반·오늘의 도전 자동 저장, 한글 공유 코드 가져오기와 읽기 전용 검증 재생을 제품 흐름에 연결했다.
- 1~10단계 점수와 실패 인과 표시, 14개 설정을 연결했다. Web 배경 모티프는 동작하지만 모바일 배경 음악 실제 재생은 미구현으로 남긴다.
- 설정 정적 상태를 테스트 전후 초기화하고 저모션 충전 게이지·파워 슬라이더와 최신 설정·리플레이 진입이 포함된 홈 Golden을 실제 화면과 대조해 갱신했다.
- 최신 Web Release 감사에서 발사 p90 16.9ms·17.2ms, p99 17.4ms·17.6ms, 50ms 초과·발사 Long Task·콘솔 오류 0건을 기록했다. 엄격 p90 16.7ms는 미통과이며 실기기 결과로 간주하지 않는다.
- 작업별 원격 커밋: `39525ed`, `2119d83`, `1e9e250`, `adb1929`, `95abd28`, `25ee8a4`, `aeb008f`, `e6a124d`.
- 최신 홈 기준 이미지 반영 뒤 최종 전체 Flutter 회귀 875개와 `flutter analyze` 오류 0건, 생산 40패턴 런타임 검증이 통과했다.

## 2026-08-08 PS-A11Y-02 모바일·Web 배경 음악

- 웹 전용 합성 타이머를 제거하고 `audioplayers 6.8.1` 기반 반복 재생 상태 기계로 교체했다. Android·iOS·Web이 같은 자체 생성 16초 섬 테마 WAV를 사용하며 음량은 효과음을 가리지 않도록 0.16으로 제한한다.
- 자동 재생 제한이나 플러그인 초기화 실패는 게임 진행을 막지 않고 다음 사용자 피드백에서 재시도한다. 빠른 활성·비활성 경쟁은 직렬화하고 중지·해제를 보장한다.
- `tool/generate_background_music.dart`에 화음·벨·펄스 합성 과정을 고정하고 외부 음원·샘플을 사용하지 않았다. 생성 자산 해시와 번들·권리대장을 동기화했다.

## 2026-08-08 PS-QA-GOLDEN-01 최종 흐름 시각 회귀

- 1단계 생산 패턴을 실제 `ShotResolver`로 실패시켜 얻은 충돌 순서와 마지막 접촉을 실패 재생 패널에 연결했다. 재생 자동 시작을 끌 수 있는 테스트 경계를 추가해 시간에 흔들리지 않는 정적 상태를 검증한다.
- 실제 `StagePatternSession`에서 10단계를 완료하고 보상을 선택한 뒤 A/B `RunState`를 앱 시작 흐름에서 복원해 런 결과 화면을 검증한다. 점수 1,970점, 3회 발사, 보상 1개는 임의 UI fixture가 아니라 저장 계층의 완료 결과다.
- 실패 재생과 런 결과를 390×844·768×1024에서 각각 Golden으로 고정했다. 태블릿 실패 패널의 마지막 설명이 잘리던 테스트 화면 제약을 실제 기기 크기의 `MediaQuery`로 교정했고 두 해상도에서 닫기·행동 버튼과 모든 설명을 직접 확인했다.
- 관련 위젯·실패 분석·최종 흐름 86개와 `flutter analyze`가 통과했다. Golden은 레이아웃 회귀 증거이며 실제 iOS·Android의 글꼴·색·터치 검증을 대체하지 않는다.

## 2026-08-08 PS-VALID-04 실제 결함 변이

- 이름 있는 슬라이더 터널링 fixture는 실제 슬라이더 횡단 결과에서 작동 payload·사건을 제거하고, 회전 순서 fixture는 실제 반사판 충돌 결과에서 회전 payload·사건을 제거해 생산 runtime probe가 각각 결함을 검출한다.
- `ShotResolver.canLaunch`에 계획 상태·활성 공·이동 가능한 공·유한 위치의 최소 발사 계약을 추가했다. UI의 발사·조준·충전 입구가 같은 계약을 사용하고, 소프트락 fixture는 이 계약만 거부하는 resolver 변이로 `launchUnavailable`을 실제 생성한다.
- 대표 입력 전체 무이동은 여전히 소프트락 증거가 아니다. validator·runtime probe 31개와 슬라이더·회전판·실제 UI 입력 139개, `flutter analyze`가 통과했다.
- 생산 40패턴 runtime CLI 재실행은 도구 사용량 제한으로 승인이 거절돼 이번 반복의 통과 증거로 기록하지 않는다.

## 2026-08-08 PS-QA-STRESS-01 반복 사용 회귀

- 클리어 결과에서 실제 재도전 행동을 20회 반복해 콜백이 회당 정확히 한 번 실행되고, 결과 팝업이 닫히며, 조준 입력 화면이 복구되고, 위젯 예외가 남지 않는지 검증했다.
- 14개 개별 설정을 30회 교차 변경한 뒤 정적 상태를 초기화하고 `SharedPreferences`에서 마지막 값을 다시 읽어 저장 직렬화와 복원을 확인했다.
- 같은 실제 캡처 리플레이를 100회 재생해 매회 결과 지문과 최종 발사 수가 같고 원문 문서가 변하지 않는지 확인했다. 기존 1~10단계 누적·재개와 A/B 저장 중단·손상 복구 회귀를 같은 69개 묶음에서 재검증했다.
- `flutter analyze`가 통과했다. 위젯 반복은 메모리 누수의 대리 증거일 뿐이므로 20회 재도전 전후 실제 heap 추세는 실기기·프로파일러 미검증으로 유지한다.

## 2026-08-08 최신 전체 자동 회귀

- `flutter test --concurrency=1`을 약 3분 37초 실행해 892개가 실패 없이 통과했다. 물리, 생산 패턴 관련 회귀, RunState·진행 저장, 오늘의 도전, 보상, 리플레이, 14개 설정, 전체 Golden과 반복 스트레스가 포함된다.
- 10단계와 결정론 문서에 남아 있던 `+330/-9`, 252개 수치를 역사 기록으로 명시하고 최신 종합 판정에서 분리했다.
- 같은 HEAD에서 Flutter Web Release와 Wasm dry run이 통과했다. `main.dart.js`와 자체 생성 WAV가 번들에 있으며 WAV SHA-256은 권리대장 값 `f1328bfc58c40556ea004fd9780da82089e5df2ace7069bbe9bcd3b0c8f41cb1`과 일치한다.

## 2026-08-08 최신 Web 클린 빌드·성능 재감사

- 최초 감사에서 오래된 Web build cache의 plugin registrant가 `audioplayers_web`을 누락해 두 뷰포트 모두 `MissingPluginException`을 기록했다. 기존 서버를 종료하고 `flutter clean`·`flutter pub get`·Release 재빌드를 수행해 생성 registrant에 `AudioplayersPlugin.registerWith`가 포함됨을 확인했다.
- 최신 PID 88129 서버에서 동일한 5초·5초 워밍업 감사를 재실행했다. 390×844·768×1024 발사 p90은 17.1ms·17.0ms, p99는 모두 17.7ms이며 50ms 초과·발사 Long Task·콘솔 오류는 0건이다.
- 엄격 16.7ms p90 목표는 0.3~0.4ms 미달하고 실기기 증거가 없으므로 `Conditional Go`를 유지한다.
