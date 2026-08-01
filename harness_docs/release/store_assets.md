# 스토어 자산 기록

## 앱 아이콘

- 목적: iOS 홈 화면과 앱스토어 아이콘
- 파일: `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- 원본: `assets/icons/property_shot_app_icon_source.png`
- 스타일: 공·무거움·탄성·점착을 글자 없이 보여주는 프로젝트 전용 귀여운 물리 장난감 아이콘
- 생성 방식: Codex 기본 이미지 생성 도구
- 생성 프롬프트 요약: 흰색 얼굴 공을 중심에 두고 회색 돌, 초록 탄성 고리, 보라 점착 젤리를 함께 배치한 정사각형 앱 아이콘. 글자·로고·워터마크 없음.
- 변환: iOS AppIcon 규격별 PNG 리사이즈

## 런치 화면

- 파일: `ios/Runner/Assets.xcassets/LaunchImage.imageset/`
- 앱 아이콘 원본을 중심 이미지로 사용하며, `LaunchScreen.storyboard`의 배경색과 연결한다.
- 실제 기기에서 안전 영역과 초기 표시 시간을 확인해야 한다.

## 화면 캡처

스토어 제출용 캡처는 실제 게임 화면에서 생성하며, 장식용 합성 이미지를 사용하지 않는다. 파일명·해상도·검수 항목은 [`store_screenshot_manifest.md`](store_screenshot_manifest.md)에 고정한다.

## 앱스토어 제출 전 미완료 자료

- 웹 검증 캡처는 존재하지만 제출용 실기기 캡처가 아니다.
- 실제 Bundle ID와 Development Team
- 개인정보 처리방침 URL
- 지원 URL
- 실제 기기 스크린샷 최종 확인
- 연령 등급 답변
- 실제 기기 테스트 목록
