import 'package:flutter/material.dart';
import 'package:itsi_map/itsi_map.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'itsi_map 예제',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MapPage(),
    );
  }
}

class MapPage extends StatefulWidget {
  const MapPage({Key? key}) : super(key: key);

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  late final ItsiMapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = ItsiMapController();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('itsi_map 예제'),
      ),
      body: ItsiMapWidget(
        controller: _mapController,
        apiKey: '848E8D3A-D942-3606-A929-B8F4455B96DF', // 실제 운영시 환경변수 사용
        initialCenter: const LatLng(37.5665, 126.9780),
        initialZoom: 13.0,
        onPositionChanged: (center, zoom) {
          // 지도 이동 시 처리
        },
        onTap: (position) {
          _showMessage('지도 탭: ${position.latitude.toStringAsFixed(4)}, ${position.longitude.toStringAsFixed(4)}');
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'zoomIn',
            onPressed: () => _mapController.zoomIn(),
            child: const Icon(Icons.add),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'zoomOut',
            onPressed: () => _mapController.zoomOut(),
            child: const Icon(Icons.remove),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'myLocation',
            onPressed: () {
              _mapController.move(const LatLng(37.5665, 126.9780), 15.0);
              _showMessage('서울시청으로 이동');
            },
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'busan',
            onPressed: () {
              _mapController.setCenter(35.1796, 129.0756);
              _showMessage('부산으로 이동 (GPS)');
            },
            child: const Icon(Icons.gps_fixed),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

}
