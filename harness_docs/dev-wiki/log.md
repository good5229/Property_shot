# Dev-Wiki Log

Append-only chronology.

Use consistent headings so entries are easy to grep.

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
