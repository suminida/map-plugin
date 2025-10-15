/// 타일 좌표를 나타내는 모델 클래스
class TileCoord {
  /// 경도 (X 좌표)
  final double x;

  /// 위도 (Y 좌표)
  final double y;

  const TileCoord({
    required this.x,
    required this.y,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
  };

  /// JSON에서 생성
  factory TileCoord.fromJson(Map<String, dynamic> json) => TileCoord(
    x: json['x'] as double,
    y: json['y'] as double,
  );

  @override
  String toString() => 'TileCoord(x: $x, y: $y)';
}