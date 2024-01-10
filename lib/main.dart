import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const GpsMapApp(),
    );
  }
}

class GpsMapApp extends StatefulWidget {
  const GpsMapApp({super.key});

  @override
  State<GpsMapApp> createState() => GpsMapAppState();
}

class GpsMapAppState extends State<GpsMapApp> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();

  CameraPosition? _initialCameraPosition;

  @override
  void initState() {
    super.initState();

    init();
  }

  Future init() async {
    final position = await _determinePosition();

    // 초기화
    _initialCameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 17,
    );

    // 화면 그리기
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // initialCameraPosition이 처음 null인 동안에는 loading
      body: _initialCameraPosition == null
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _initialCameraPosition!,
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _goToTheCurrent,
        label: const Text('현위치'),
        icon: const Icon(Icons.directions_boat),
      ),
    );
  }

  Future<void> _goToTheCurrent() async {
    final GoogleMapController controller = await _controller.future;
    final position = await Geolocator.getCurrentPosition();
    final cameraPosition = CameraPosition(
      target: LatLng(position.latitude, position.longitude),
      zoom: 15,
    );
    await controller
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    return await Geolocator.getCurrentPosition();
  }
}
