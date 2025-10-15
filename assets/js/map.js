var _vworldKey = null; // Flutter에서 주입
var map;
var markerLayer;
var markerSource;

// API Key 설정 (Flutter에서 호출)
function setApiKey(key) {
    _vworldKey = key;
}

// VWorld 타일 레이어 생성
function createVWorldLayer(layerType) {
    if (!_vworldKey) {
        console.error('VWorld API Key가 설정되지 않았습니다.');
        return null;
    }
    return new ol.layer.Tile({
        source: new ol.source.XYZ({
            crossOrigin: 'anonymous',
            url: 'https://api.vworld.kr/req/wmts/1.0.0/' + _vworldKey + '/' + layerType + '/{z}/{y}/{x}.' + (layerType === 'Satellite' ? 'jpeg' : 'png')
        })
    });
}

// 지도 초기화
window.initMap = function initMap(lat, lng, zoom, apiKey) {
    if (apiKey) setApiKey(apiKey);
    var satelliteLayer = createVWorldLayer('Satellite');
    var hybridLayer = createVWorldLayer('Hybrid');
    var baseLayer = createVWorldLayer('Base');

    markerSource = new ol.source.Vector();
    markerLayer = new ol.layer.Vector({
        source: markerSource,
        zIndex: 1000
    });

    map = new ol.Map({
        target: 'map',
        layers: [satelliteLayer, hybridLayer, markerLayer],
        view: new ol.View({
            center: ol.proj.fromLonLat([lng, lat]),
            zoom: zoom
        })
    });

    // 지도 클릭 이벤트
    map.on('click', function(evt) {
        var coord = ol.proj.toLonLat(evt.coordinate);
        sendToFlutter('onTap', { lat: coord[1], lng: coord[0] });
    });

    // 지도 이동 이벤트
    map.on('moveend', function() {
        var view = map.getView();
        var center = ol.proj.toLonLat(view.getCenter());
        sendToFlutter('onPositionChanged', {
            lat: center[1],
            lng: center[0],
            zoom: view.getZoom()
        });
    });
}

// 센터 이동
function setCenter(lat, lng) {
    var view = map.getView();
    view.setCenter(ol.proj.fromLonLat([lng, lat]));
}

// 줌 레벨 설정
function setZoom(zoom) {
    map.getView().setZoom(zoom);
}

// 줌 인
function zoomIn() {
    var view = map.getView();
    view.setZoom(view.getZoom() + 1);
}

// 줌 아웃
function zoomOut() {
    var view = map.getView();
    view.setZoom(view.getZoom() - 1);
}

// 마커 추가
function addMarker(id, lat, lng) {
    var iconFeature = new ol.Feature({
        geometry: new ol.geom.Point(ol.proj.fromLonLat([lng, lat])),
        markerId: id
    });

    iconFeature.setStyle(new ol.style.Style({
        image: new ol.style.Circle({
            radius: 8,
            fill: new ol.style.Fill({ color: '#ff0000' }),
            stroke: new ol.style.Stroke({ color: '#ffffff', width: 2 })
        })
    }));

    markerSource.addFeature(iconFeature);

    // 마커 클릭 이벤트
    map.on('click', function(evt) {
        map.forEachFeatureAtPixel(evt.pixel, function(feature) {
            var markerId = feature.get('markerId');
            if (markerId === id) {
                sendToFlutter('onMarkerTap', { id: markerId });
            }
        });
    });
}

// 마커 제거
function removeMarker(id) {
    var features = markerSource.getFeatures();
    for (var i = 0; i < features.length; i++) {
        if (features[i].get('markerId') === id) {
            markerSource.removeFeature(features[i]);
            break;
        }
    }
}

// 모든 마커 제거
function clearMarkers() {
    markerSource.clear();
}

// 레이어 관리용 맵
var customLayers = {};

// GeoJSON 레이어 추가
function addGeoJsonLayer(layerId, geoJsonData) {
    var geoJson = typeof geoJsonData === 'string' ? JSON.parse(geoJsonData) : geoJsonData;

    var vectorSource = new ol.source.Vector({
        features: new ol.format.GeoJSON().readFeatures(geoJson, {
            featureProjection: 'EPSG:3857'
        })
    });

    var vectorLayer = new ol.layer.Vector({
        source: vectorSource,
        zIndex: 100,
        style: new ol.style.Style({
            stroke: new ol.style.Stroke({
                color: '#3399CC',
                width: 2
            }),
            fill: new ol.style.Fill({
                color: 'rgba(51, 153, 204, 0.3)'
            }),
            image: new ol.style.Circle({
                radius: 5,
                fill: new ol.style.Fill({ color: '#3399CC' }),
                stroke: new ol.style.Stroke({ color: '#ffffff', width: 1 })
            })
        })
    });

    map.addLayer(vectorLayer);
    customLayers[layerId] = vectorLayer;
}

// WMS 레이어 추가
function addWmsLayer(layerId, wmsUrl, params, zIndex) {
    if (!map) return;
    if (!window.customLayers) window.customLayers = {};

    // 기본 파라미터 보강 (호출 쪽에서 넘어온 값이 우선)
    var baseParams = Object.assign({
        SERVICE: 'WMS',
        VERSION: '1.1.1',
        REQUEST: 'GetMap',
        FORMAT: 'image/png',
        TRANSPARENT: true,
        exceptions: 'application/vnd.ogc.se_inimage',
        SRS: 'EPSG:5179'
    }, params || {});

    // 이미 있으면 갱신만
    if (customLayers[layerId]) {
        var lyr = customLayers[layerId];
        var src = lyr.getSource();
        if (src && src.updateParams) src.updateParams(baseParams);
        if (typeof zIndex === 'number') lyr.setZIndex(zIndex);
        lyr.setVisible(true);
        return;
    }

    // 새로 생성
    var source = new ol.source.TileWMS({
        url: wmsUrl,
        params: baseParams,
        serverType: 'geoserver',
        crossOrigin: 'anonymous'
    });

    var layer = new ol.layer.Tile({
        source: source,
        zIndex: (typeof zIndex === 'number') ? zIndex : 500,
        minZoom: 12 // 최소 zoom 크기 12
    });

    // 디버깅/제거용 메타
    layer.set('name', layerId);

    map.addLayer(layer);
    customLayers[layerId] = layer;
}

/** 제거 */
function removeWmsLayer(layerId) {
    if (!customLayers || !customLayers[layerId]) return;
    var layer = customLayers[layerId];
    if (map) map.removeLayer(layer);
    delete customLayers[layerId];
}

/** 가시성 */
function setWmsLayerVisibility(layerId, visible) {
    var layer = customLayers && customLayers[layerId];
    if (layer) layer.setVisible(!!visible);
}

/** 투명도(0~1) */
function setWmsLayerOpacity(layerId, opacity) {
    var layer = customLayers && customLayers[layerId];
    if (layer && typeof opacity === 'number') layer.setOpacity(Math.max(0, Math.min(1, opacity)));
}

/** 순서 */
function setWmsLayerZIndex(layerId, zIndex) {
    var layer = customLayers && customLayers[layerId];
    if (layer && typeof zIndex === 'number') layer.setZIndex(zIndex);
}

/** 로딩 여부 확인(필요시) */
function isWmsLayerLoaded(layerId) {
    return !!(customLayers && customLayers[layerId]);
}

// XYZ 타일 레이어 추가
function addXyzLayer(layerId, tileUrl) {
    var xyzLayer = new ol.layer.Tile({
        source: new ol.source.XYZ({
            url: tileUrl,
            crossOrigin: 'anonymous'
        }),
        zIndex: 100
    });

    map.addLayer(xyzLayer);
    customLayers[layerId] = xyzLayer;
}

// 레이어 표시/숨김
function toggleLayer(layerId, visible) {
    if (customLayers[layerId]) {
        customLayers[layerId].setVisible(visible);
    }
}

// 레이어 제거
function removeLayer(layerId) {
    if (customLayers[layerId]) {
        map.removeLayer(customLayers[layerId]);
        delete customLayers[layerId];
    }
}

// 레이어 투명도 설정
function setLayerOpacity(layerId, opacity) {
    if (customLayers[layerId]) {
        customLayers[layerId].setOpacity(opacity);
    }
}

// 모든 커스텀 레이어 제거
function clearAllLayers() {
    for (var layerId in customLayers) {
        map.removeLayer(customLayers[layerId]);
    }
    customLayers = {};
}

// Flutter로 메시지 전송
function sendToFlutter(event, data) {
    var message = { event: event, data: data };
    if (window.flutter_inappwebview) {
        window.flutter_inappwebview.callHandler('mapEvent', message);
    } else if (window.FlutterChannel) {
        window.FlutterChannel.postMessage(JSON.stringify(message));
    }
}

// 초기화 완료 알림
window.addEventListener('load', function() {
    sendToFlutter('onMapReady', {});
});