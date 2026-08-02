# Dev-Wiki Log

Append-only chronology.

Use consistent headings so entries are easy to grep.

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
