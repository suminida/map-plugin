import 'package:flutter/material.dart';
import 'package:itsi_map/itsi_map.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'offline_map_test_page.dart';

Future<void> main() async {
  await dotenv.load(fileName: ".env");
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
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('itsi_map 예제'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.map, color: Colors.blue),
              title: const Text('지도 위젯'),
              subtitle: const Text('기본 지도 기능 테스트'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MapPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_download, color: Colors.green),
              title: const Text('오프라인 지도 생성'),
              subtitle: const Text('2km x 2km 영역 지도 생성 테스트'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const OfflineMapTestPage()),
                );
              },
            ),
          ),
        ],
      ),
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
        apiKey: dotenv.env['VWORLD_API_KEY'] ?? '',
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
