import 'vworld_tile_manager.dart';
import 'wms_layer_manager.dart';
import 'version_manager.dart';
import 'models/tile_coord.dart';
import 'models/offline_map_result.dart';

/// 오프라인 지도를 생성하는 메인 클래스
///
/// 2km x 2km 영역에 대한 2048px x 2048px 오프라인 지도 생성
/// - V월드 배경지도: 4개 타일(1024x1024)을 2x2로 병합
/// - WMS 레이어: hazard_2023, flowacc_daum 등
class OfflineMapGenerator {
  /// V월드 타일 관리자
  final VWorldTileManager vworldManager;

  /// WMS 레이어 관리자
  final WmsLayerManager wmsManager;

  /// 버전 관리자
  final VersionManager versionManager;

  /// 타일 중심 offset (서버 코드와 동일)
  /// 서버는 EPSG:4326 단위 offset을 EPSG:3857 좌표에 더함
  /// 이는 의도된 것일 수 있음 (약 611m offset)
  static const double offsetX = 0.005493032672390541; // 서버와 동일
  static const double offsetY = 0.004453252112625705; // 서버와 동일

  OfflineMapGenerator({
    required this.vworldManager,
    required this.wmsManager,
    required this.versionManager,
  });

  /// 팩토리 생성자 - 기본 설정으로 생성
  factory OfflineMapGenerator.create({
    required String vworldApiKey,
    required String geoserverUrl,
    String workspace = 'lios',
  }) {
    return OfflineMapGenerator(
      vworldManager: VWorldTileManager(apiKey: vworldApiKey),
      wmsManager: WmsLayerManager(
        geoserverUrl: geoserverUrl,
        workspace: workspace,
      ),
      versionManager: VersionManager(),
    );
  }

  /// 2km x 2km 영역에 대한 2048px x 2048px 오프라인 지도 생성
  ///
  /// [centerX] - 중심점 경도
  /// [centerY] - 중심점 위도
  /// [wmsLayerNames] - WMS 레이어 이름 목록 (예: ['hazard_2023', 'flowacc_daum'])
  /// [currentVersion] - 현재 데이터 버전 (없으면 null)
  /// [zoom] - 줌 레벨 (기본값: 17)
  /// [tileSize] - 각 타일 크기 (기본값: 1024)
  /// [wmsImageSize] - WMS 이미지 크기 (기본값: 2024)
  ///
  /// 반환값: OfflineMapResult (V월드 지도 + WMS 레이어 + 버전)
  Future<OfflineMapResult> createMapWith2kmAnd2048px({
    required double centerX,
    required double centerY,
    required List<String> wmsLayerNames,
    String? currentVersion,
    int zoom = 17,
    int tileSize = 1024,
    int wmsImageSize = 2024,
  }) async {
    // 1. 4개 타일 좌표 계산 (2x2 그리드)
    final tiles = _calculate2x2Tiles(centerX, centerY);

    // 2. V월드 배경지도 생성 (4개 타일 병합 → 2048x2048)
    final vworldMap = await vworldManager.create2x2Map(
      tiles,
      zoom: zoom,
      tileSize: tileSize,
    );

    // 3. WMS 레이어 생성
    final wmsLayers = await wmsManager.createLayers(
      wmsLayerNames,
      vworldMap.bbox,
      width: wmsImageSize,
      height: wmsImageSize,
    );

    // 4. 버전 생성
    final version = versionManager.generateVersion(currentVersion);

    return OfflineMapResult(
      vworldMap: vworldMap,
      wmsLayers: wmsLayers,
      version: version,
    );
  }

  /// 중심점 기준으로 2x2 타일 좌표 계산 (서버와 동일한 방식)
  ///
  /// [centerX] - 중심점 X (EPSG:3857 미터)
  /// [centerY] - 중심점 Y (EPSG:3857 미터)
  ///
  /// 반환값: {'topLeft', 'topRight', 'bottomLeft', 'bottomRight'} 좌표 맵
  Map<String, TileCoord> _calculate2x2Tiles(double centerX, double centerY) {
    // 서버 코드와 동일: EPSG:3857 좌표에 작은 offset 값을 더함
    // 이 값은 약 611m offset으로 동작함
    return {
      'topLeft': TileCoord(
        x: centerX - offsetX,
        y: centerY + offsetY,
      ),
      'topRight': TileCoord(
        x: centerX + offsetX,
        y: centerY + offsetY,
      ),
      'bottomLeft': TileCoord(
        x: centerX - offsetX,
        y: centerY - offsetY,
      ),
      'bottomRight': TileCoord(
        x: centerX + offsetX,
        y: centerY - offsetY,
      ),
    };
  }

  /// 타일 좌표 계산 (공개 메서드 - 테스트용)
  Map<String, TileCoord> calculate2x2Tiles(double centerX, double centerY) {
    return _calculate2x2Tiles(centerX, centerY);
  }
}