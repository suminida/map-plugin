/// 지도 경계 영역을 나타내는 모델 클래스
class MapBBox {
  /// 최소 경도
  final double minX;

  /// 최소 위도
  final double minY;

  /// 최대 경도
  final double maxX;

  /// 최대 위도
  final double maxY;

  const MapBBox({
    required this.minX,
    required this.minY,
    required this.maxX,
    required this.maxY,
  });

  /// BBOX 문자열로 변환 (minX,minY,maxX,maxY)
  String toBBoxString() => '$minX,$minY,$maxX,$maxY';

  /// 배열로 변환 [minX, minY, maxX, maxY]
  List<double> toArray() => [minX, minY, maxX, maxY];

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
    'minX': minX,
    'minY': minY,
    'maxX': maxX,
    'maxY': maxY,
  };

  /// JSON에서 생성
  factory MapBBox.fromJson(Map<String, dynamic> json) => MapBBox(
    minX: json['minX'] as double,
    minY: json['minY'] as double,
    maxX: json['maxX'] as double,
    maxY: json['maxY'] as double,
  );

  @override
  String toString() => 'MapBBox(minX: $minX, minY: $minY, maxX: $maxX, maxY: $maxY)';
}