import 'vworld_map.dart';
import 'wms_layer.dart';

/// 오프라인 지도 생성 결과를 나타내는 모델 클래스
class OfflineMapResult {
  /// V월드 배경 지도
  final VWorldMap vworldMap;

  /// WMS 레이어 목록
  final List<WmsLayer> wmsLayers;

  /// 데이터 버전
  final String version;

  const OfflineMapResult({
    required this.vworldMap,
    required this.wmsLayers,
    required this.version,
  });

  /// JSON으로 변환
  Map<String, dynamic> toJson() => {
    'vworldMap': vworldMap.toJson(),
    'wmsLayers': wmsLayers.map((layer) => layer.toJson()).toList(),
    'version': version,
  };

  /// JSON에서 생성
  factory OfflineMapResult.fromJson(Map<String, dynamic> json) => OfflineMapResult(
    vworldMap: VWorldMap.fromJson(json['vworldMap'] as Map<String, dynamic>),
    wmsLayers: (json['wmsLayers'] as List)
        .map((layer) => WmsLayer.fromJson(layer as Map<String, dynamic>))
        .toList(),
    version: json['version'] as String,
  );

  @override
  String toString() => 'OfflineMapResult(version: $version, wmsLayers: ${wmsLayers.length})';
}