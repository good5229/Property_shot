# Track 1 썸네일 생성 기록

## 최종 파일

- 경로: `submission/openai_game_builders_track1/track1_thumbnail_1920x1080.png`
- 규격: 1920×1080, PNG RGB, 16:9
- 크기: 약 2.8MB
- SHA-256: `fd7fd2c1038e96820cc2e4e83937c7fd94f804522d2ef35cb1fed34098b68e55`
- 생성 방식: Codex 내장 `image_gen` 생성 후 `image_gen` 정밀 편집, 최종 1920×1080 리사이즈
- 입력 역할: 프로젝트 자체 섬 세계 이미지는 색·재질 참고, 실제 플레이 캡처는 구도·기물 참고로만 사용

## 최초 생성 프롬프트

```text
Use case: stylized-concept
Asset type: 16:9 game competition submission thumbnail
Input images: Image 1 is the visual style and island-world reference; Image 2 is the gameplay composition and object reference, not an edit target.
Primary request: create a polished wide key art image for the casual physics puzzle game Property Shot. Show the distinctive mechanic at a glance: a cute white ball pulls a glowing heavy property out of a stone, the stone becomes visibly lighter and displaced, and the powered ball travels through a small crate-and-wall puzzle toward a dark circular goal hole. A previously missed ball remains on the board as a useful bumper. In the background, the island observatory, lighthouse, and bridge are being restored by glowing connected paths.
Scene/backdrop: bright turquoise island sea and warm golden wooden puzzle platform integrated into the island world.
Style/medium: high-polish casual mobile game illustration, painterly 3D-like sprites, same teal, warm gold, coral, cream palette and friendly proportions as the references.
Composition/framing: landscape 16:9; central puzzle action must read clearly at small thumbnail size; ball and property transfer are the main focal point; restoration landmarks form a readable secondary silhouette; leave calm sky space near the upper left for optional external title overlay, but render no text.
Lighting/mood: optimistic golden-hour sunlight, crisp silhouettes, gentle magical glow, adventurous and playful.
Constraints: no text, no letters, no logos, no watermark, no people, no extra UI chrome, no photorealism; preserve a clean causal visual sequence from stone to powered ball to obstacle to goal; do not make the ball already inside the hole.
```

## 정밀 편집 프롬프트

```text
Use case: precise-object-edit
Asset type: 16:9 game competition submission thumbnail
Input images: Image 1 is the edit target.
Primary request: change only the property-transfer action in the foreground. Replace the small glowing wooden cube emerging from the cracked stone with a clearly non-crate, dark slate-gray round weight-property orb marked by three simple horizontal weight bands. Show the golden energy stream carrying that orb into the main happy white ball, and give the lower third of that main ball a subtle dark stone texture so the acquired heavy property is visually clear. The cracked source stone should look lighter and slightly shifted after losing the property. Keep the separate neutral missed ball on the board unchanged.
Invariants: preserve the exact 16:9 composition, island sea, lighthouse, observatory, bridge, wooden puzzle board, walls, crates, hole, camera, lighting, palette, and all other objects from Image 1.
Constraints: no text, no letters, no logos, no watermark, no people, no extra UI; the property orb must not resemble a box, crate, gem, or coin; do not place any ball inside the hole.
```
