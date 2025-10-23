import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bản đồ rạp phim'),
      ),
      body: FlutterMap(
        options: const MapOptions(
          initialCenter: LatLng(10.8000, 106.6267),
          initialZoom: 13.0,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
          ),
          const MarkerLayer(
            markers: [
              Marker(
                width: 80.0,
                height: 80.0,
                point: LatLng(10.8000, 106.6267),
                child: Icon(Icons.location_on, color: Colors.red, size: 40.0),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
