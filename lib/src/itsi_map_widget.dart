import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'itsi_map_controller.dart';
import 'models/lat_lng.dart';

/// 지도 위젯
class ItsiMapWidget extends StatefulWidget {
  final ItsiMapController controller;
  final LatLng initialCenter;
  final double initialZoom;
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
    // HTML 로드
    final htmlContent = await rootBundle.loadString('packages/itsi_map/assets/html/map.html');

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleMapEvent(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            _onMapReady();
          },
        ),
      )
      ..loadHtmlString(htmlContent);

    widget.controller.attachWebView(_webViewController);
  }

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

  double _asDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

}
