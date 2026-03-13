import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import '../../domain/entities/zone.dart';

class MapScreen extends StatefulWidget {
  final List<ZoneEntity>? initialZones;
  final VoidCallback? onZoneCreated;

  const MapScreen({super.key, this.initialZones, this.onZoneCreated});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Circle> _circles = {};
  final Set<Marker> _markers = {};
  LatLng? _selectedLocation;
  double _radius = 500;
  bool _isCreatingZone = false;

  final LatLng _defaultLocation = const LatLng(40.3686, 49.8671);

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Xəritə Ekranı (MapScreen)');
    _loadInitialZones();
  }

  @override
  void dispose() {
    AppLogger.ekranBaglandi('Xəritə Ekranı (MapScreen)');
    super.dispose();
  }

  void _loadInitialZones() {
    if (widget.initialZones != null && widget.initialZones!.isNotEmpty) {
      AppLogger.xeriteEmeliyyati(
          'İlkin zonalar yüklənir. Say: ${widget.initialZones!.length}');
      for (final zone in widget.initialZones!) {
        _addZoneToMap(zone);
      }
      AppLogger.ugur('XƏRİTƏ', 'İlkin zonalar xəritəyə əlavə edildi');
    } else {
      AppLogger.debug('XƏRİTƏ', 'İlkin zona yoxdur');
    }
  }

  void _addZoneToMap(ZoneEntity zone) {
    AppLogger.xeriteEmeliyyati(
        '"${zone.name}" zonası xəritəyə əlavə edilir',
        data: 'Lat: ${zone.latitude}, Lon: ${zone.longitude}, R: ${zone.radiusInMeters}m');

    final location = LatLng(zone.latitude, zone.longitude);

    _markers.add(
      Marker(
        markerId: MarkerId(zone.id),
        position: location,
        infoWindow: InfoWindow(
          title: zone.name,
          snippet: 'Radius: ${(zone.radiusInMeters / 1000).toStringAsFixed(2)} km',
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          zone.isActive ? BitmapDescriptor.hueBlue : BitmapDescriptor.hueGreen,
        ),
      ),
    );

    _circles.add(
      Circle(
        circleId: CircleId(zone.id),
        center: location,
        radius: zone.radiusInMeters,
        fillColor: Colors.blue.withValues(alpha: 0.1),
        strokeColor: Colors.blue.withValues(alpha: 0.5),
        strokeWidth: 2,
      ),
    );

    setState(() {});
    AppLogger.ugur('XƏRİTƏ', '"${zone.name}" xəritəyə əlavə edildi');
  }

  void _onMapTap(LatLng location) {
    if (!_isCreatingZone) {
      AppLogger.debug('XƏRİTƏ', 'Xəritəyə toxunuldu (zona yaratma rejimi aktiv deyil)');
      return;
    }

    AppLogger.xeriteEmeliyyati(
        'Zona üçün mövqe seçildi',
        data: 'Lat: ${location.latitude.toStringAsFixed(4)}, Lon: ${location.longitude.toStringAsFixed(4)}');

    setState(() {
      _selectedLocation = location;
    });

    _markers.clear();
    _circles.clear();

    _markers.add(
      Marker(
        markerId: const MarkerId('selected'),
        position: location,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    );

    _circles.add(
      Circle(
        circleId: const CircleId('preview'),
        center: location,
        radius: _radius,
        fillColor: Colors.red.withValues(alpha: 0.1),
        strokeColor: Colors.red.withValues(alpha: 0.5),
        strokeWidth: 2,
      ),
    );
  }

  void _createZone() {
    if (_selectedLocation == null) {
      AppLogger.xeberdarliq('XƏRİTƏ',
          'Zona yaratma cəhdi: mövqe seçilməyib');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfən xəritə üzərində əraziyi seçin')),
      );
      return;
    }

    AppLogger.zonaEmeliyyati(
        'Yeni zona təsdiqləndi',
        'Seçilmiş mövqe',
        data: 'Lat: ${_selectedLocation!.latitude.toStringAsFixed(4)}, '
            'Lon: ${_selectedLocation!.longitude.toStringAsFixed(4)}, '
            'Radius: ${(_radius / 1000).toStringAsFixed(2)}km');

    widget.onZoneCreated?.call();
    AppLogger.ugur('XƏRİTƏ', 'Zona yaratma callback çağırıldı');

    setState(() {
      _selectedLocation = null;
      _isCreatingZone = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Həyvan İzləmə Xəritəsi'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultLocation,
              zoom: 12,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              AppLogger.ugur('XƏRİTƏ', 'Google Maps kontroler hazır');
            },
            circles: _circles,
            markers: _markers,
            onTap: _onMapTap,
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
          ),
          if (_isCreatingZone)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Xəritə üzərində əraziyi seçin',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text('Radius:'),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Slider(
                            value: _radius,
                            min: 100,
                            max: 5000,
                            divisions: 49,
                            label: '${(_radius / 1000).toStringAsFixed(2)} km',
                            onChanged: (value) {
                              setState(() => _radius = value);
                              AppLogger.debug('XƏRİTƏ',
                                  'Radius dəyişdirildi: ${(value / 1000).toStringAsFixed(2)}km');
                              if (_selectedLocation != null) {
                                _circles.clear();
                                _circles.add(
                                  Circle(
                                    circleId: const CircleId('preview'),
                                    center: _selectedLocation!,
                                    radius: value,
                                    fillColor: Colors.red.withValues(alpha: 0.1),
                                    strokeColor: Colors.red.withValues(alpha: 0.5),
                                    strokeWidth: 2,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              AppLogger.melumat('XƏRİTƏ',
                                  'Zona yaratma ləğv edildi');
                              setState(() => _isCreatingZone = false);
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('İmtina'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _createZone,
                            icon: const Icon(Icons.check),
                            label: const Text('Təsdiq Et'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          Positioned(
            bottom: _isCreatingZone ? 220 : 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                final yeniRejiim = !_isCreatingZone;
                AppLogger.melumat('XƏRİTƏ',
                    yeniRejiim ? 'Zona yaratma rejimi aktivləşdi' : 'Zona yaratma rejimi söndürüldü');
                setState(() => _isCreatingZone = yeniRejiim);
              },
              backgroundColor: _isCreatingZone ? Colors.red : Colors.green,
              foregroundColor: Colors.white,
              child: Icon(_isCreatingZone ? Icons.close : Icons.add),
            ),
          ),
        ],
      ),
    );
  }
}