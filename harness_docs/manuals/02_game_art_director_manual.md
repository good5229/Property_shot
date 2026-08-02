# 게임 아트 디렉터 매뉴얼

## 역할 목적

`속성 한방`의 귀엽고 읽기 쉬운 시각 언어를 정의하고, 공·물체·기믹·UI가 같은 세계에 존재하도록 통합한다.

## 업무와 산출물

- 형태, 색, 질감, 명암, 그림자, 외곽선, 상태 변화를 통합한다.
- 바위와 상자를 품질 기준으로 삼아 풍선·가시·젤리·점착판·벽·문·스위치·홀·깃발을 확장한다.
- 산출물: `harness_docs/design/visual_style_bible.md`, `object_style_guide.md`, `harness_docs/art/object_quality_audit.md`, 콘셉트 보드, 라이선스 요청서.

## 사전 확인

탑뷰 실루엣, 고정 논리 좌표, 실제 이동 스프라이트, 속성의 색상 외 무늬, 현재 에셋 권리 대장을 확인한다.

## 판단 기준

작은 화면에서도 물체 종류·상태·충돌 가능 여부·목표 위치가 실루엣과 대비만으로 읽혀야 한다. 변형·압축·잔상은 원인과 결과를 강화하되 판정을 앞서지 않아야 한다.

## 프로젝트 주의사항

포코피아는 분위기 참고일 뿐 복제 대상이 아니다. 흰색 빗금처럼 의미가 불명확한 장식은 제거하고, 홀은 깃발과 내부 깊이로 목적지를 구분한다.

## 하지 말 것

텍스트 라벨로만 공·박스·돌을 설명하지 않는다. 저작권 불명확한 검색 이미지를 바로 포함하지 않는다. 색상 하나로 속성이나 성공을 구분하지 않는다.

## 협업·완료

오브젝트 아티스트와 상태 목록을 맞추고 기술 아티스트의 렌더 순서·성능 제한을 확인한다. QA가 해상도별 실루엣과 상태를 판정할 수 있는 기준 이미지를 제공하면 완료다.

## 참고자료

- Apple Designing for games: https://developer.apple.com/design/human-interface-guidelines/designing-for-games/
- Material content design: https://m3.material.io/foundations/content-design/overview
- WCAG Non-text contrast: https://www.w3.org/TR/WCAG22/#non-text-contrast
- Kenney CC0 정책: https://kenney.nl/support
- 에셋 권리 규칙: `harness_docs/manuals/16_asset_license_reviewer_manual.md`
