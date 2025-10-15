import 'dart:math';

/// 좌표 변환 유틸리티
class CoordTransform {
  static const double earthRadius = 6378137.0; // 지구 반지름 (미터)
  static const double originShift = pi * earthRadius; // 20037508.342789244

  /// EPSG:3857 (Web Mercator) → EPSG:4326 (WGS84 경위도) 변환
  ///
  /// [x] - EPSG:3857 X 좌표 (미터)
  /// [y] - EPSG:3857 Y 좌표 (미터)
  ///
  /// 반환값: [경도(lon), 위도(lat)]
  static List<double> epsg3857ToEpsg4326(double x, double y) {
    final lon = (x / originShift) * 180.0;
    var lat = (y / originShift) * 180.0;
    lat = 180.0 / pi * (2.0 * atan(exp(lat * pi / 180.0)) - pi / 2.0);

    return [lon, lat];
  }

  /// EPSG:4326 (WGS84 경위도) → EPSG:3857 (Web Mercator) 변환
  ///
  /// [lon] - 경도
  /// [lat] - 위도
  ///
  /// 반환값: [x, y] (미터 단위)
  static List<double> epsg4326ToEpsg3857(double lon, double lat) {
    final x = lon * originShift / 180.0;
    var y = log(tan((90.0 + lat) * pi / 360.0)) / (pi / 180.0);
    y = y * originShift / 180.0;

    return [x, y];
  }

  /// EPSG:3857 좌표에서 offset(미터) 만큼 이동 후 EPSG:4326으로 변환
  ///
  /// [centerX3857] - 중심점 X (EPSG:3857)
  /// [centerY3857] - 중심점 Y (EPSG:3857)
  /// [offsetMeters] - 이동 거리 (미터)
  ///
  /// 반환값: EPSG:4326 BBox [minLon, minLat, maxLon, maxLat]
  static List<double> calculateBBox3857To4326({
    required double centerX3857,
    required double centerY3857,
    required double offsetMeters,
  }) {
    // 3857 좌표계에서 BBox 계산
    final minX3857 = centerX3857 - offsetMeters;
    final minY3857 = centerY3857 - offsetMeters;
    final maxX3857 = centerX3857 + offsetMeters;
    final maxY3857 = centerY3857 + offsetMeters;

    // 각 꼭지점을 4326으로 변환
    final minCoord = epsg3857ToEpsg4326(minX3857, minY3857);
    final maxCoord = epsg3857ToEpsg4326(maxX3857, maxY3857);

    return [
      minCoord[0], // minLon
      minCoord[1], // minLat
      maxCoord[0], // maxLon
      maxCoord[1], // maxLat
    ];
  }

  /// EPSG:4326 좌표에서 미터 단위 offset으로 BBox 계산
  ///
  /// [centerX4326] - 중심점 경도 (EPSG:4326)
  /// [centerY4326] - 중심점 위도 (EPSG:4326)
  /// [halfWidthMeters] - 너비의 절반 (미터)
  /// [halfHeightMeters] - 높이의 절반 (미터)
  ///
  /// 반환값: EPSG:4326 BBox [minLon, minLat, maxLon, maxLat]
  static List<double> calculateBBox4326({
    required double centerX4326,
    required double centerY4326,
    required double halfWidthMeters,
    required double halfHeightMeters,
  }) {
    // 위도에서 1도당 미터 (약 111km)
    const metersPerDegreeLat = 111320.0;

    // 경도에서 1도당 미터 (위도에 따라 변함)
    final metersPerDegreeLon = 111320.0 * cos(centerY4326 * pi / 180.0);

    // 미터를 도(degree)로 변환
    final deltaLon = halfWidthMeters / metersPerDegreeLon;
    final deltaLat = halfHeightMeters / metersPerDegreeLat;

    return [
      centerX4326 - deltaLon, // minLon
      centerY4326 - deltaLat, // minLat
      centerX4326 + deltaLon, // maxLon
      centerY4326 + deltaLat, // maxLat
    ];
  }
}