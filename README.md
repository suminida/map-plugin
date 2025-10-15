# itsi_map

Flutter 지도 플러그인 - VWorld API + OpenLayers 기반

## 주요 기능

- VWorld API 직접 연동 (OpenLayers 사용)
- WebView 기반 지도 렌더링
- GPS 좌표 이동 (줌 레벨 유지)
- 지도 제어 (이동, 줌 인/아웃)
- 마커 추가/제거
- 지도 이벤트 (탭, 이동)

## 아키텍처

```
Flutter (Dart)
    ↕ JavaScript Channel
WebView (HTML + OpenLayers)
    ↕ REST API
VWorld Map Service
```

## 설치

```yaml
dependencies:
  itsi_map:
    path: ../itsi_map
```

## 환경 설정

### 1. API Key 발급

[VWorld 오픈API](https://www.vworld.kr/dev/v4dv_2ddataguide2_s001.do)에서 API Key 발급:
1. 회원가입 및 로그인
2. API 신청 → 인증키 발급

### 2. 환경변수 설정

**보안을 위해 API Key는 반드시 환경변수로 관리하세요.**

```bash
# example/.env.example을 example/.env로 복사
cd example
cp .env.example .env
```

`.env` 파일에 발급받은 API Key 입력:
```
VWORLD_API_KEY=YOUR_API_KEY_HERE
```

### 3. Dependencies 설치

```yaml
# example/pubspec.yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

```bash
flutter pub get
```

## 사용 예제

```dart
import 'package:flutter/material.dart';
import 'package:itsi_map/itsi_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = ItsiMapController();

    return MaterialApp(
      home: Scaffold(
        body: ItsiMapWidget(
          controller: controller,
          apiKey: dotenv.env['VWORLD_API_KEY'] ?? '',
          initialCenter: const LatLng(37.5665, 126.9780),
          initialZoom: 13.0,
          onPositionChanged: (center, zoom) {
            print('지도 이동: $center, 줌: $zoom');
          },
          onTap: (position) {
            print('지도 탭: $position');
          },
        ),
      ),
    );
  }
}
```

## API 문서

### ItsiMapController

```dart
// 지도 이동 (좌표 + 줌)
await controller.move(LatLng(37.5665, 126.9780), 15.0);

// GPS 좌표 이동 (줌 레벨 유지)
await controller.setCenter(35.1796, 129.0756);

// 줌 인/아웃
await controller.zoomIn();
await controller.zoomOut();

// 마커 추가
await controller.addMarker('marker1', LatLng(37.5665, 126.9780));

// 마커 제거
await controller.removeMarker('marker1');

// 모든 마커 제거
await controller.clearMarkers();

// 현재 상태 조회
LatLng? center = controller.center;
double zoom = controller.zoom;
```

### ItsiMapWidget 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| controller | ItsiMapController | ✓ | 지도 컨트롤러 |
| apiKey | String | ✓ | VWorld API Key |
| initialCenter | LatLng | ✓ | 초기 중심 좌표 |
| initialZoom | double | | 초기 줌 레벨 (기본: 13.0) |
| onPositionChanged | Function | | 지도 이동 이벤트 |
| onTap | Function | | 지도 탭 이벤트 |
| onLongPress | Function | | 지도 롱프레스 (미구현) |

## 보안 주의사항

- `.env` 파일은 `.gitignore`에 등록되어 Git 커밋에서 제외됩니다
- `.env.example` 파일은 템플릿으로 제공되며 실제 키는 포함하지 않습니다
- 절대 API Key를 코드에 직접 하드코딩하지 마세요

## 예제 앱 실행

```bash
cd example

# .env 파일 생성 (최초 1회)
cp .env.example .env
# .env 파일을 열어 VWORLD_API_KEY 값 입력

# 의존성 설치
flutter pub get

# 앱 실행
flutter run
```

### 주요 기능 데모
- 줌 인/아웃 버튼
- 서울시청 이동 (좌표 + 줌)
- 부산 이동 (GPS 좌표만, 줌 유지)
- 지도 탭 좌표 표시
- 오프라인 지도 생성 (2km x 2km 영역)

## 기술 스택

- **Flutter**: 3.0.0+
- **WebView**: webview_flutter ^4.4.2
- **OpenLayers**: 8.2.0 (CDN)
- **VWorld API**: WMTS 1.0.0

## 변경 이력

### v1.0.0 (2025-01-13)
- VWorld API 직접 연동 (flutter_map 제거)
- WebView + OpenLayers 아키텍처
- GPS 좌표 이동 기능 (`setCenter`)
- API Key 외부 주입 방식

## 라이선스

MIT
