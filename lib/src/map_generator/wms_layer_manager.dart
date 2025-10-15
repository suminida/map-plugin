import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'models/map_bbox.dart';
import 'models/wms_layer.dart';

/// WMS 레이어를 관리하는 클래스
class WmsLayerManager {
  /// GeoServer URL
  final String geoserverUrl;

  /// Workspace 이름 (기본값: lios)
  final String workspace;

  WmsLayerManager({
    required this.geoserverUrl,
    this.workspace = 'lios',
  });

  /// 여러 WMS 레이어를 생성
  ///
  /// [layerNames] - 레이어 이름 목록 (예: ['hazard_2023', 'flowacc_daum'])
  /// [bbox] - 지도 경계 영역
  /// [width] - 이미지 너비 (기본값: 2024)
  /// [height] - 이미지 높이 (기본값: 2024)
  ///
  /// 반환값: WmsLayer 객체 목록
  Future<List<WmsLayer>> createLayers(
    List<String> layerNames,
    MapBBox bbox, {
    int width = 2024,
    int height = 2024,
  }) async {
    final layers = <WmsLayer>[];

    for (final layerName in layerNames) {
      try {
        final layer = await _createLayer(
          layerName: layerName,
          bbox: bbox,
          width: width,
          height: height,
        );
        layers.add(layer);
      } catch (e) {
        // 개별 레이어 실패 시 로그만 남기고 계속 진행
        print('Failed to create WMS layer "$layerName": $e');
      }
    }

    return layers;
  }

  /// 단일 WMS 레이어 생성
  Future<WmsLayer> _createLayer({
    required String layerName,
    required MapBBox bbox,
    required int width,
    required int height,
  }) async {
    // WMS GetMap 요청 URL 생성
    final url = Uri.parse('$geoserverUrl/wms').replace(queryParameters: {
      'service': 'WMS',
      'version': '1.1.0',
      'request': 'GetMap',
      'layers': '$workspace:$layerName',
      'styles': '$workspace:$layerName',
      'bbox': bbox.toBBoxString(),
      'width': width.toString(),
      'height': height.toString(),
      'srs': 'EPSG:4326',
      'format': 'image/png',
      'transparent': 'true',
    });

    final response = await http.get(url);

    print(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to download WMS layer "$layerName": ${response.statusCode}');
    }

    // PNG 이미지 검증
    final image = img.decodePng(response.bodyBytes);
    if (image == null) {
      throw Exception('Failed to decode WMS layer "$layerName" image');
    }

    // Base64로 인코딩
    final base64Image = base64Encode(img.encodePng(image));

    return WmsLayer(
      layerName: layerName,
      base64Image: base64Image,
      bbox: bbox,
    );
  }

  /// 단일 레이어를 즉시 생성 (편의 메서드)
  Future<WmsLayer> createLayer({
    required String layerName,
    required MapBBox bbox,
    int width = 2024,
    int height = 2024,
  }) async {
    return _createLayer(
      layerName: layerName,
      bbox: bbox,
      width: width,
      height: height,
    );
  }
}