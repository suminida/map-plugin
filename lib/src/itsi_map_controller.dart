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
