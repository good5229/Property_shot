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
