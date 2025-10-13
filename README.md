# itsi_map

Flutter 지도 플러그인 - vWorld 타일 지원

## 주요 기능

- 지도 표시 (Flutter 위젯 기반)
- vWorld 타일 레이어 지원 (위성, 하이브리드, 일반 지도)
- 마커 표시 및 상호작용
- 데이터 레이어 (폴리라인, 폴리곤, 원)
- 지도 이동 제어 (이동, 줌, 회전)
- 탭/롱탭 이벤트 처리

## 설치

```yaml
dependencies:
  itsi_map:
    path: ../suuu/itsi_map
```

## 사용 예제

```dart
import 'package:itsi_map/itsi_map.dart';

// 컨트롤러 생성
final controller = ItsiMapController();

// vWorld 타일 프로바이더 생성
final vWorldProvider = VWorldTileProvider(
  apiKey: 'YOUR_VWORLD_API_KEY',
);

// 지도 위젯
ItsiMapWidget(
  controller: controller,
  initialCenter: LatLng(37.5665, 126.9780),
  initialZoom: 13.0,
  tileLayer: vWorldProvider.satelliteLayer,
  layers: [
    vWorldProvider.hybridLayer,
    ItsiMarkerLayer(markers: markers),
    ItsiDataLayer(data: dataLayers),
  ],
)
```

## API 문서

### ItsiMapController

```dart
// 지도 이동
controller.move(LatLng(lat, lng), zoom);

// 줌 인/아웃
controller.zoomIn();
controller.zoomOut();

// 회전
controller.rotate(degree);

// 영역 맞춤
controller.fitBounds(bounds);
```

### VWorldTileProvider

```dart
// 위성 영상
vWorldProvider.satelliteLayer

// 하이브리드 (위성 + 도로)
vWorldProvider.hybridLayer

// 일반 지도
vWorldProvider.baseLayer
```

### 마커

```dart
ItsiMarker(
  id: 'marker1',
  position: LatLng(37.5665, 126.9780),
  child: Icon(Icons.location_on),
  onTap: () => print('마커 클릭'),
)
```

### 데이터 레이어

```dart
// 폴리라인
ItsiPolylineData(
  id: 'line1',
  points: [LatLng(...), LatLng(...)],
  color: Colors.blue,
  strokeWidth: 4.0,
)

// 폴리곤
ItsiPolygonData(
  id: 'polygon1',
  points: [LatLng(...), LatLng(...)],
  color: Colors.green,
  isFilled: true,
)

// 원
ItsiCircleData(
  id: 'circle1',
  center: LatLng(37.5665, 126.9780),
  radius: 500,
  useRadiusInMeter: true,
)
```

## 라이선스

MIT