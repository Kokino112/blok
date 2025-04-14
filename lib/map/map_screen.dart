import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class MapScreen extends StatefulWidget {
  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final List<Marker> _markers = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadMarkers();
  }

  // Učitavanje markera sa Firebase-a
  void _loadMarkers() {
    _firestore.collection('protests').snapshots().listen((snapshot) {
      setState(() {
        _markers.clear();
        for (var doc in snapshot.docs) {
          var data = doc.data();
          _markers.add(
            Marker(
              width: 40,
              height: 40,
              point: LatLng(data['latitude'], data['longitude']),
              child: GestureDetector(
                onTap: () {
                  _mapController.move(
                    LatLng(data['latitude'], data['longitude']),
                    15.0, // Zoom nivo pri kliku na marker
                  );
                  _showMarkerInfo(doc.id, data);
                },
                child: Icon(
                  Icons.location_on,
                  color: Colors.red,
                  size: 40,
                ),
              ),
            ),
          );
        }
      });
    });
  }

  // Prikazivanje informacija kada se klikne na marker
  void _showMarkerInfo(String docId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(data['title'] ?? 'Bez naslova'),
          content: Text(data['description'] ?? 'Bez opisa'),
          actions: <Widget>[
            TextButton(
              child: Text('Zatvori'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.only(
        topLeft: Radius.circular(25),
        topRight: Radius.circular(25),
      ),
      child: Container(
        color: Colors.white, // Dodaj pozadinu ako treba
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: LatLng(44.0165, 21.0059),
            initialZoom: 7.0,
            minZoom: 3.0,
            maxZoom: 18.0,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png",
              subdomains: ['a', 'b', 'c'],
            ),
            MarkerLayer(
              markers: _markers,
            ),
          ],
        ),
      ),
    );
  }

}
