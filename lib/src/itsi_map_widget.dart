import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'itsi_map_controller.dart';
import 'models/lat_lng.dart';

/// 지도 위젯
class ItsiMapWidget extends StatefulWidget {
  final ItsiMapController controller;
  final LatLng initialCenter; // 위도, 경도
  final double initialZoom; // 줌 레벨
  final String apiKey; // VWorld API Key
  final Function(LatLng center, double zoom)? onPositionChanged;
  final Function(LatLng position)? onTap;
  final Function(LatLng position)? onLongPress;

  const ItsiMapWidget({
    Key? key,
    required this.controller,
    required this.initialCenter,
    this.initialZoom = 13.0,
    required this.apiKey,
    this.onPositionChanged,
    this.onTap,
    this.onLongPress,
  }) : super(key: key);

  @override
  State<ItsiMapWidget> createState() => _ItsiMapWidgetState();
}

class _ItsiMapWidgetState extends State<ItsiMapWidget> {
  late WebViewController _webViewController;
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    // HTML 로드 (패키지 assets 경로로 수정)
    final htmlContent = await rootBundle.loadString('packages/itsi_map/assets/html/map.html');

    // webview에 HTML을 띄움
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // HTML 안의 JavaScript 실행 허용
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(                         // flutter와 통신할 채널 생성, JS → Flutter 로 메시지를 보낼 통로 생성
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMapEvent(message.message);
        },
      )
      ..setNavigationDelegate(                       // HTML 페이지가 다 로드되었을 때(onPageFinished) 실행할 콜백
        NavigationDelegate(
          onPageFinished: (String url) {
            _onMapReady();
          },
        ),
      )
      ..loadFlutterAsset('packages/itsi_map/assets/html/map.html');
      // ..loadHtmlString(htmlContent);                // 실제 HTML 문자열을 WebView에 띄움

    widget.controller.attachWebView(_webViewController);
  }

  /// js의 initMap 함수 호출
  void _onMapReady() {
    if (_isMapReady) return; // 중복 호출 방지

    setState(() {
      _isMapReady = true;
    });

    // 초기 지도 설정 (약간의 지연 후 실행)
    Future.delayed(const Duration(milliseconds: 100), () {
      _webViewController.runJavaScript(
        'initMap(${widget.initialCenter.latitude}, ${widget.initialCenter.longitude}, ${widget.initialZoom}, "${widget.apiKey}");',
      );
      widget.controller.updateState(widget.initialCenter, widget.initialZoom);
    });
  }

  /// 지도 이벤트 수신
  /// js에서 전달받은 메시지 flutter에 세팅하는 함수
  void _handleMapEvent(String message) {
    try {
      final data = jsonDecode(message);
      final event = data['event'] as String;
      final eventData = data['data'] as Map<String, dynamic>;

      switch (event) {
        case 'onMapReady':
          _onMapReady();
          break;
        case 'onPositionChanged':
          final center = LatLng(
            _asDouble(eventData['lat']),
            _asDouble(eventData['lng']),
          );
          final zoom = _asDouble(eventData['zoom']);
          widget.controller.updateState(center, zoom);
          widget.onPositionChanged?.call(center, zoom);
          break;
        case 'onTap':
          final position = LatLng(
            _asDouble(eventData['lat']),
            _asDouble(eventData['lng']),
          );
          widget.onTap?.call(position);
          break;
        case 'onMarkerTap':
        // 마커 탭 이벤트 처리
          break;
      }
    } catch (e) {
      debugPrint('Map event error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _webViewController);
  }

  @override
  void dispose() {
    widget.controller.dispose();
    super.dispose();
  }

  /// double 타입으로 형변환
  /// - [v]: 변환할 값
  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

}
