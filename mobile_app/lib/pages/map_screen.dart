import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:google_place/google_place.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../signalement_page.dart';

class MapScreen extends StatefulWidget {
  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  GoogleMapController? _controller;
  LatLng? _currentPosition;
  Set<Marker> _markers = {};
  Set<Polyline> _polylines = {};

  late GooglePlace _googlePlace;
  List<AutocompletePrediction> _predictions = [];
  final TextEditingController _searchController = TextEditingController();
  final String _apiKey = "AIzaSyC46bvErDVSv_G-GBT9HluboE5uJ_zqtcQ";

  @override
  void initState() {
    super.initState();
    _initLocation();
    _googlePlace = GooglePlace(_apiKey);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    var status = await Permission.location.request();
    if (status.isGranted) {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  void _onSearchChanged() async {
    if (_searchController.text.isNotEmpty) {
      var result = await _googlePlace.autocomplete.get(_searchController.text);
      if (result != null && result.predictions != null) {
        setState(() {
          _predictions = result.predictions!;
        });
      }
    } else {
      setState(() {
        _predictions = [];
      });
    }
  }

  void _selectPrediction(AutocompletePrediction prediction) async {
    final placeId = prediction.placeId;
    if (placeId != null) {
      final details = await _googlePlace.details.get(placeId);
      final location = details?.result?.geometry?.location;

      if (location != null) {
        final latLng = LatLng(location.lat!, location.lng!);
        _controller?.animateCamera(CameraUpdate.newLatLng(latLng));
        _searchController.text = prediction.description ?? '';
        setState(() {
          _predictions = [];
        });

        await _showRoute(latLng);
      }
    }
  }

  Future<void> _showRoute(LatLng destination) async {
    if (_currentPosition == null) return;

    final origin =
        '${_currentPosition!.latitude},${_currentPosition!.longitude}';
    final dest = '${destination.latitude},${destination.longitude}';
    final url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=$origin&destination=$dest&alternatives=true&key=$_apiKey';

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final routes = data['routes'];

      if (routes != null && routes.isNotEmpty) {
        setState(() {
          _polylines.clear();
          _markers.removeWhere((m) => m.markerId.value.startsWith("duration_"));
        });

        for (int i = 0; i < routes.length; i++) {
          final route = routes[i];
          final points = route['overview_polyline']['points'];
          final decodedPoints = _decodePolyline(points);
          final duration = route['legs'][0]['duration']['text'];

          final color = (i == 0) ? Colors.blue : Colors.purple;

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: PolylineId("route_$i"),
                points: decodedPoints,
                color: color,
                width: 6,
                onTap: () async {
                  await _showRoute(destination);
                },
              ),
            );

            _markers.add(
              Marker(
                markerId: MarkerId("duration_$i"),
                position: decodedPoints.last,
                icon: BitmapDescriptor.defaultMarkerWithHue(
                  (i == 0)
                      ? BitmapDescriptor.hueAzure
                      : BitmapDescriptor.hueViolet,
                ),
                infoWindow: InfoWindow(
                  title: "Itinéraire ${i + 1}",
                  snippet: "Durée : $duration",
                ),
              ),
            );
          });
        }
      }
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> polyline = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0) ? ~(result >> 1) : (result >> 1);
      lng += dlng;

      polyline.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polyline;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentPosition == null) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition!,
              zoom: 16,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            markers: _markers,
            polylines: _polylines,
          ),
          Positioned(
            top: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: "Où va-t-on ?",
                      border: InputBorder.none,
                      icon: Icon(Icons.search, color: Colors.grey),
                    ),
                  ),
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: EdgeInsets.only(top: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListView.builder(
                      itemCount: _predictions.length,
                      shrinkWrap: true,
                      itemBuilder: (context, index) {
                        final p = _predictions[index];
                        return ListTile(
                          title: Text(p.description ?? ''),
                          onTap: () => _selectPrediction(p),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SignalementPage(
                latitude: _currentPosition!.latitude,
                longitude: _currentPosition!.longitude,
              ),
            ),
          );
        },
        backgroundColor: Colors.amber,
        child: Icon(Icons.report_problem, color: Colors.white),
        tooltip: "Signaler un incident",
      ),
    );
  }
}
