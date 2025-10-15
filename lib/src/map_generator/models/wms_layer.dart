import 'map_bbox.dart';

/// WMS 레이어 데이터를 나타내는 모델 클래스
class WmsLayer {
  /// 레이어 이름
  final String layerName;

  /// 레이어 이미지 (Base64 인코딩)
  final String base64Image;

  /// 레이어 경계 영역
  final MapBBox bbox;

  const WmsLayer({
    required this.layerName,
    required this.base64Image,
    required this.bbox,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
    'layerName': layerName,
    'base64': base64Image,
    'box': bbox.toArray(),
  };

  /// JSON에서 생성
  factory WmsLayer.fromJson(Map<String, dynamic> json) => WmsLayer(
    layerName: json['layerName'] as String,
    base64Image: json['base64'] as String,
    bbox: MapBBox(
      minX: (json['box'] as List)[0] as double,
      minY: (json['box'] as List)[1] as double,
      maxX: (json['box'] as List)[2] as double,
      maxY: (json['box'] as List)[3] as double,
    ),
  );

  @override
  String toString() => 'WmsLayer(layerName: $layerName, bbox: $bbox, base64Length: ${base64Image.length})';
}