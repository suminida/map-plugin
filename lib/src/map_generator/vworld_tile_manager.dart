import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'models/tile_coord.dart';
import 'models/map_bbox.dart';
import 'models/vworld_map.dart';
import 'coord_transform.dart';

/// V월드 타일을 관리하고 병합하는 클래스
class VWorldTileManager {
  /// V월드 API 키
  final String apiKey;

  /// V월드 WMS API Base URL
  static const String _wmsBaseUrl = 'https://api.vworld.kr/req/wms';

  /// V월드 Static Map API Base URL (대안)
  static const String _staticMapBaseUrl = 'https://api.vworld.kr/req/image';

  VWorldTileManager({required this.apiKey});

  /// 4개의 타일(2x2)을 다운로드하고 병합하여 2048x2048 이미지 생성
  ///
  /// [tiles] - topLeft, topRight, bottomLeft, bottomRight 좌표
  /// [zoom] - 줌 레벨 (기본값: 17)
  /// [tileSize] - 각 타일의 크기 (기본값: 1024)
  ///
  /// 반환값: VWorldMap 객체 (base64 이미지 + bbox)
  Future<VWorldMap> create2x2Map(
    Map<String, TileCoord> tiles, {
    int zoom = 17,
    int tileSize = 1024,
  }) async {
    // 1. 4개의 타일 이미지 다운로드
    final topLeftImage = await _downloadTile(tiles['topLeft']!, zoom, tileSize);
    final topRightImage = await _downloadTile(tiles['topRight']!, zoom, tileSize);
    final bottomLeftImage = await _downloadTile(tiles['bottomLeft']!, zoom, tileSize);
    final bottomRightImage = await _downloadTile(tiles['bottomRight']!, zoom, tileSize);

    // 2. 4개의 이미지를 2x2로 병합
    final mergedImage = _merge2x2Images(
      topLeft: topLeftImage,
      topRight: topRightImage,
      bottomLeft: bottomLeftImage,
      bottomRight: bottomRightImage,
    );

    // 3. Base64로 인코딩
    final base64Image = base64Encode(img.encodeJpg(mergedImage, quality: 85));

    // 4. BBox 계산 (중심점 기준 ±1km)
    // 타일 중심점 = topLeft + offset (서버와 동일한 방식)
    final centerX = tiles['topLeft']!.x + 0.005493032672390541;
    final centerY = tiles['topLeft']!.y - 0.004453252112625705;

    // 서버는 BBox 계산 시 줌16 사용 (이미지는 줌17)
    final bbox = _calculateBBox(
      centerX: centerX,
      centerY: centerY,
      zoom: 16, // 서버와 동일하게 줌16 사용
      width: tileSize,
      height: tileSize,
    );

    return VWorldMap(
      base64Image: base64Image,
      bbox: bbox,
    );
  }

  /// V월드 API로부터 단일 타일 이미지 다운로드
  Future<img.Image> _downloadTile(TileCoord coord, int zoom, int size) async {
    // V월드 Static Map API 사용 (WMS 대신)

    final url = Uri.https('api.vworld.kr', '/req/image', {
      'service': 'image',
      'request': 'getmap',              // 소문자
      'key': 'BF520773-A08A-3701-840F-1FC3F15181EC',                    // 하드코딩 대신 주입 권장
      'format': 'jpeg',                  // 'png' 또는 'jpeg'
      'basemap': 'PHOTO_HYBRID',
      // 'basemap': 'Satellite',           // 레이어 없는 위성사진 (Satellite, base, gray, midnight 중 선택)
      'center': '${coord.x},${coord.y}',// 자바와 같은 좌표계 사용
      'crs': 'EPSG:4326',               // 서버와 동일
      'zoom': '$zoom',
      'size': '$size,$size',            // width,height 형식
    });

    // final url = Uri.parse(_staticMapBaseUrl).replace(queryParameters: {
    //   'service': 'image',
    //   'request': 'GetMap',
    //   'version': '2.0.0',
    //   'crs': 'EPSG:4326',
    //   'center': '${coord.x},${coord.y}',
    //   'width': size.toString(),
    //   'height': size.toString(),
    //   'format': 'image/png',
    //   'size': '1',
    //   'key': 'BF520773-A08A-3701-840F-1FC3F15181EC',
    //   'domain': 'http://localhost', // 필요시 실제 도메인으로 변경
    // });


    // print(url);

    final response = await http.get(url);

    if (response.statusCode != 200) {
      throw Exception('Failed to download VWorld tile: ${response.statusCode}');
    }

    // 디버깅: 응답 헤더와 바디 정보 출력
    print('Response headers: ${response.headers}');
    print('Response body length: ${response.bodyBytes.length}');
    print('Response content-type: ${response.headers['content-type']}');

    // 응답이 이미지가 아닌 경우 (예: 에러 메시지) 텍스트로 출력
    final contentType = response.headers['content-type'] ?? '';
    if (contentType.contains('text') || contentType.contains('xml')) {
      print('Response body (text): ${response.body}');
      print('Request URL: $url');
      throw Exception('VWorld API returned error: ${response.body}');
    }

    final image = img.decodeImage(response.bodyBytes);
    if (image == null) {
      // 디버깅: 바이트 데이터의 시작 부분 출력
      final preview = response.bodyBytes.take(100).toList();
      print('First 100 bytes: $preview');
      print('Request URL: $url');
      throw Exception('Failed to decode VWorld tile image');
    }

    return image;
  }

  /// 4개의 이미지를 2x2 그리드로 병합
  img.Image _merge2x2Images({
    required img.Image topLeft,
    required img.Image topRight,
    required img.Image bottomLeft,
    required img.Image bottomRight,
  }) {
    final width = topLeft.width + topRight.width;
    final height = topLeft.height + bottomLeft.height;

    final merged = img.Image(width: width, height: height);

    // Top Left
    img.compositeImage(merged, topLeft, dstX: 0, dstY: 0);

    // Top Right
    img.compositeImage(merged, topRight, dstX: topLeft.width, dstY: 0);

    // Bottom Left
    img.compositeImage(merged, bottomLeft, dstX: 0, dstY: topLeft.height);

    // Bottom Right
    img.compositeImage(merged, bottomRight, dstX: topLeft.width, dstY: topLeft.height);

    return merged;
  }

  /// 중심점과 줌 레벨을 기준으로 BBox 계산 (EPSG:3857 → EPSG:4326 변환)
  MapBBox _calculateBBox({
    required double centerX,
    required double centerY,
    required int zoom,
    required int width,
    required int height,
  }) {
    // 중심점은 EPSG:4326 좌표계 (경위도)
    // BBox는 EPSG:4326 (WGS84 경위도)로 반환

    // 줌 레벨과 이미지 크기를 기반으로 offset 계산
    // 해상도(m/px) = 156543.03392 / (2^zoom)
    final resolution = 156543.03392 / (1 << zoom);  // 2^zoom
    final halfWidthMeters = (width / 2.0) * resolution;
    final halfHeightMeters = (height / 2.0) * resolution;

    // EPSG:4326 중심점에서 계산된 offset으로 BBox 생성
    final bboxArray = CoordTransform.calculateBBox4326(
      centerX4326: centerX,
      centerY4326: centerY,
      halfWidthMeters: halfWidthMeters,
      halfHeightMeters: halfHeightMeters,
    );

    return MapBBox(
      minX: bboxArray[0], // minLon
      minY: bboxArray[1], // minLat
      maxX: bboxArray[2], // maxLon
      maxY: bboxArray[3], // maxLat
    );
  }
}