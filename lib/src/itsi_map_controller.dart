import 'dart:convert';
import 'package:webview_flutter/webview_flutter.dart';
import 'models/lat_lng.dart';

/// 지도 컨트롤러
class ItsiMapController {
  WebViewController? _webViewController;
  LatLng? _center;
  double _zoom = 13.0;

  /// WebView 컨트롤러 연결
  void attachWebView(WebViewController controller) {
    _webViewController = controller;
  }

  /// 현재 중심 좌표
  LatLng? get center => _center;

  /// 현재 줌 레벨
  double get zoom => _zoom;

  /// 내부 상태 업데이트 (WebView 이벤트로부터)
  void updateState(LatLng center, double zoom) {
    _center = center;
    _zoom = zoom;
  }

  /// 지도 이동
  Future<void> move(LatLng center, double zoom) async {
    _center = center;
    _zoom = zoom;
    await _runJavaScript(
        'setCenter(${center.latitude}, ${center.longitude}); setZoom($zoom);');
  }

  /// 현재 줌 레벨 유지하면서 센터 좌표만 이동 (GPS 좌표 이동용)
  Future<void> setCenter(double lat, double lng) async {
    _center = LatLng(lat, lng);
    await _runJavaScript('setCenter($lat, $lng);');
  }

  /// 줌 인
  Future<void> zoomIn() async {
    _zoom++;
    await _runJavaScript('zoomIn();');
  }

  /// 줌 아웃
  Future<void> zoomOut() async {
    _zoom--;
    await _runJavaScript('zoomOut();');
  }

  /// 마커 추가
  Future<void> addMarker(String id, LatLng position) async {
    await _runJavaScript(
        'addMarker("$id", ${position.latitude}, ${position.longitude});');
  }

  /// 마커 제거
  Future<void> removeMarker(String id) async {
    await _runJavaScript('removeMarker("$id");');
  }

  /// 모든 마커 제거
  Future<void> clearMarkers() async {
    await _runJavaScript('clearMarkers();');
  }

  /// GeoJSON 레이어 추가
  Future<void> addGeoJsonLayer(String layerId, String geoJsonData) async {
    await _runJavaScript('addGeoJsonLayer("$layerId", $geoJsonData);');
  }

  /// WMS 레이어 추가
  // Future<void> addWmsLayer(String layerId, String wmsUrl, String layerName) async {
  //   await _runJavaScript('addWmsLayer("$layerId", "$wmsUrl", "$layerName");');
  // }

  /// WMS 레이어 추가/갱신 (원래 JS 기능과 동일하게 동작하도록 확장)
  Future<void> addWmsLayer(
      String layerId,
      String wmsUrl,
      String layerName, {
        int zIndex = 500,
        Map<String, dynamic>? extraParams, // 필요 시 덮어쓸/추가할 파라미터
      }) async {
    // 기본값: JS에서 쓰던 값들 반영 (1.1.1 + EPSG:5179 + STYLES = tableNm)
    final params = <String, dynamic>{
      'SERVICE': 'WMS',
      'VERSION': '1.1.1',
      'REQUEST': 'GetMap',
      'FORMAT': 'image/png',
      'TRANSPARENT': true,
      'LAYERS': layerName,
      'STYLES': layerName,
      'SRS': 'EPSG:5179',
      'exceptions': 'application/vnd.ogc.se_inimage',
      // 필요시 덮어쓰기
      if (extraParams != null) ...extraParams,
    };

    // JS: addWmsLayer(layerId, wmsUrl, params, zIndex)
    final js = '''
    addWmsLayer(
      "${layerId.replaceAll('"', '\\"')}",
      "${wmsUrl.replaceAll('"', '\\"')}",
      ${jsonEncode(params)},
      $zIndex
    );
  ''';
    await _runJavaScript(js);
  }

  /// WMS 레이어 제거 (이름으로)
  Future<void> removeWmsLayer(String layerId) async {
    await _runJavaScript('removeWmsLayer("$layerId");');
  }

  /// 가시성/불투명도/순서 제어(옵션)
  Future<void> setWmsLayerVisibility(String layerId, bool visible) async {
    await _runJavaScript('setWmsLayerVisibility("$layerId", ${visible ? 'true' : 'false'});');
  }
  Future<void> setWmsLayerOpacity(String layerId, double opacity) async {
    await _runJavaScript('setWmsLayerOpacity("$layerId", $opacity);'); // 0.0~1.0
  }
  Future<void> setWmsLayerZIndex(String layerId, int zIndex) async {
    await _runJavaScript('setWmsLayerZIndex("$layerId", $zIndex);');
  }

  /// XYZ 타일 레이어 추가
  Future<void> addXyzLayer(String layerId, String tileUrl) async {
    await _runJavaScript('addXyzLayer("$layerId", "$tileUrl");');
  }

  /// 레이어 표시/숨김 토글
  Future<void> toggleLayer(String layerId, bool visible) async {
    await _runJavaScript('toggleLayer("$layerId", $visible);');
  }

  /// 레이어 제거
  Future<void> removeLayer(String layerId) async {
    await _runJavaScript('removeLayer("$layerId");');
  }

  /// 레이어 투명도 설정
  Future<void> setLayerOpacity(String layerId, double opacity) async {
    await _runJavaScript('setLayerOpacity("$layerId", $opacity);');
  }

  /// 모든 커스텀 레이어 제거
  Future<void> clearAllLayers() async {
    await _runJavaScript('clearAllLayers();');
  }

  /// JavaScript 실행 헬퍼
  Future<void> _runJavaScript(String script) async {
    if (_webViewController != null) {
      try {
        await _webViewController!.runJavaScript(script);
      } catch (e) {
        print('JavaScript 실행 오류: $e, script: $script');
      }
    } else {
      print('WebViewController가 아직 연결되지 않았습니다.');
    }
  }

  /// 폐기
  void dispose() {
    _webViewController = null;
  }
}
