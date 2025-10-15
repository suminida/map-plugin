import 'map_bbox.dart';

/// V월드 지도 데이터를 나타내는 모델 클래스
class VWorldMap {
  /// 지도 이미지 (Base64 인코딩)
  final String base64Image;

  /// 지도 경계 영역
  final MapBBox bbox;

  const VWorldMap({
    required this.base64Image,
    required this.bbox,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
    'base64': base64Image,
    'box': bbox.toArray(),
  };

  /// JSON에서 생성
  factory VWorldMap.fromJson(Map<String, dynamic> json) => VWorldMap(
    base64Image: json['base64'] as String,
    bbox: MapBBox(
      minX: (json['box'] as List)[0] as double,
      minY: (json['box'] as List)[1] as double,
      maxX: (json['box'] as List)[2] as double,
      maxY: (json['box'] as List)[3] as double,
    ),
  );

  @override
  String toString() => 'VWorldMap(bbox: $bbox, base64Length: ${base64Image.length})';
}