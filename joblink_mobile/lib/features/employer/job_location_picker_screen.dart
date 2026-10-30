import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class JobLocationResult {
  final double latitude;
  final double longitude;

  const JobLocationResult({
    required this.latitude,
    required this.longitude,
  });
}

class JobLocationPickerScreen extends StatefulWidget {
  const JobLocationPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  final double? initialLatitude;
  final double? initialLongitude;

  @override
  State<JobLocationPickerScreen> createState() =>
      _JobLocationPickerScreenState();
}

class _JobLocationPickerScreenState extends State<JobLocationPickerScreen> {
  static const Color _primary = Color(0xFF2563EB);

  // Mặc định tọa độ trung tâm Thủ Dầu Một, Bình Dương
  static const LatLng _defaultLocation = LatLng(10.9804, 106.6519);

  late LatLng _selectedLocation;
  late final MapController _mapController;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      _selectedLocation =
          LatLng(widget.initialLatitude!, widget.initialLongitude!);
    } else {
      _selectedLocation = _defaultLocation;
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Chọn vị trí trên bản đồ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(
                context,
                JobLocationResult(
                  latitude: _selectedLocation.latitude,
                  longitude: _selectedLocation.longitude,
                ),
              );
            },
            child: const Text(
              'Xong',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: _primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _selectedLocation,
              initialZoom: 15.0,
              onPositionChanged: (camera, hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _selectedLocation = camera.center;
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.joblink.joblink_mobile',
              ),
            ],
          ),

          // Ghim đỏ cố định tại tâm màn hình khi người dùng rê bản đồ
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 38.0),
              child: Icon(
                Icons.location_on_rounded,
                size: 46,
                color: Colors.red.shade600,
              ),
            ),
          ),

          // Bảng hiển thị tọa độ góc dưới
          Positioned(
            left: 16,
            right: 16,
            bottom: 24,
            child: Card(
              elevation: 4,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.my_location_rounded, color: _primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Tọa độ: ${_selectedLocation.latitude.toStringAsFixed(5)}, ${_selectedLocation.longitude.toStringAsFixed(5)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                            JobLocationResult(
                              latitude: _selectedLocation.latitude,
                              longitude: _selectedLocation.longitude,
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: _primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Xác nhận vị trí này'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}