import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:iconsax/iconsax.dart';
import 'package:meta_tracking/core/logger/app_logger.dart';
import 'package:meta_tracking/features/animals/domain/entities/animal_entity.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/animal_filter_bar.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/animal_list_card.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/tracking_app_bar.dart';
import 'package:meta_tracking/features/animals/presentation/widgets/tracking_summary_cards.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => TrackingScreenState();
}

class TrackingScreenState extends State<TrackingScreen> {
  String _filterStatus = 'all';
  final Set<String> _selectedIds = {};
  bool _selectMode = false;
  StreamSubscription<Position>? _locationSub;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Tracking Screen');
    _requestLocationPermission();
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    AppLogger.ekranBaglandi('Tracking Screen');
    super.dispose();
  }

  // ── Refresh ───────────────────────────────────────────────────────────────

  Future<void> refreshAnimals() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      context.read<AnimalBloc>().add(WatchAnimalsEvent(authState.user.id));
      AppLogger.melumat(
          'TRACKING', 'Heyvanlar yenilənir: ${authState.user.id}');
    }
  }

  // ── GPS icazə + izləmə ────────────────────────────────────────────────────

  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        AppLogger.melumat('GPS', 'İcazə sorğusu göndərildi');
      }
      if (permission == LocationPermission.deniedForever) {
        AppLogger.xeberdarliq('GPS', 'İcazə həmişəlik rədd edildi');
        if (mounted) _showPermissionDialog();
        return;
      }
      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        AppLogger.ugur('GPS', 'GPS icazəsi verildi');
        _startLocationTracking();
      }
    } catch (e) {
      AppLogger.xeta('GPS', 'İcazə xətası', xetaObyekti: e);
    }
  }

  void _startLocationTracking() {
    const settings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    );
    _locationSub =
        Geolocator.getPositionStream(locationSettings: settings).listen(
      (position) {
        AppLogger.melumat(
            'GPS', 'Mövqe alındı: ${position.latitude}, ${position.longitude}');
        if (!mounted) return;
        setState(() => _currentPosition = position);

        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          final animalState = context.read<AnimalBloc>().state;
          if (animalState is AnimalLoaded) {
            for (final animal
                in animalState.animals.where((a) => a.isTracking)) {
              context.read<AnimalBloc>().add(UpdateLocationEvent(
                    animalId: animal.id,
                    lat: position.latitude,
                    lng: position.longitude,
                    speed: position.speed,
                    battery: 1.0,
                  ));
            }
          }
        }
      },
      onError: (e) => AppLogger.xeta('GPS', 'Mövqe xətası', xetaObyekti: e),
    );
    AppLogger.ugur('GPS', 'GPS izləmə başladı');
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Iconsax.location, color: Color(0xFF2ECC71)),
          SizedBox(width: 8),
          Text('GPS İcazəsi', style: TextStyle(fontWeight: FontWeight.w700)),
        ]),
        content: const Text(
          'Heyvanları izləmək üçün GPS icazəsi lazımdır.',
          style: TextStyle(height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Ləğv et', style: TextStyle(color: Colors.grey[500])),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Geolocator.openAppSettings();
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2ECC71)),
            child: const Text('Tənzimləmələr',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Filter ────────────────────────────────────────────────────────────────

  List<AnimalEntity> _applyFilter(List<AnimalEntity> animals) {
    switch (_filterStatus) {
      case 'active':
        return animals.where((a) => a.isTracking).toList();
      case 'alert':
        return animals
            .where((a) => a.zoneStatus == AnimalZoneStatus.alert)
            .toList();
      default:
        return animals;
    }
  }

  // ── Group actions ─────────────────────────────────────────────────────────

  void _showGroupActions(List<AnimalEntity> animals) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('${_selectedIds.length} heyvan seçildi',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 16),
          _actionBtn(Iconsax.map, 'Xəritədə göstər', const Color(0xFF3498DB),
              () {
            Navigator.pop(context);
            final selected =
                animals.where((a) => _selectedIds.contains(a.id)).toList();
            Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => MapScreen(
                highlightedAnimalIds: _selectedIds.toList(),
                animalEntities: selected,
              ),
            ));
          }),
          const SizedBox(height: 10),
          _actionBtn(Iconsax.close_circle, 'Seçimi təmizlə', Colors.grey, () {
            setState(() {
              _selectedIds.clear();
              _selectMode = false;
            });
            Navigator.pop(context);
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _actionBtn(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w600, fontSize: 14)),
        ]),
      ),
    );
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AnimalBloc, AnimalState>(
      builder: (context, state) {
        final animals =
            state is AnimalLoaded ? state.animals : <AnimalEntity>[];
        final filtered = _applyFilter(animals);
        final alertCount =
            animals.where((a) => a.zoneStatus == AnimalZoneStatus.alert).length;
        final activeCount = animals.where((a) => a.isTracking).length;
        final insideCount = animals
            .where((a) => a.zoneStatus == AnimalZoneStatus.inside)
            .length;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F7FA),
          body: Column(children: [
            TrackingAppBar(
              animalCount: animals.length,
              alertCount: alertCount,
              isSelectMode: _selectMode,
              onToggleSelectMode: () => setState(() {
                _selectMode = !_selectMode;
                if (!_selectMode) _selectedIds.clear();
              }),
              onFilterTap: () {},
            ),
            TrackingSummaryCards(
              total: animals.length,
              active: activeCount,
              inside: insideCount,
              alert: alertCount,
            ),
            if (_currentPosition != null)
              Container(
                margin: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF2ECC71).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFF2ECC71).withValues(alpha: 0.2)),
                ),
                child: Row(children: [
                  const Icon(Iconsax.location,
                      color: Color(0xFF2ECC71), size: 14),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'GPS aktiv — ${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF2ECC71),
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Color(0xFF2ECC71), shape: BoxShape.circle),
                  ),
                ]),
              ),
            AnimalFilterBar(
              activeFilter: _filterStatus,
              onFilterChanged: (v) => setState(() => _filterStatus = v),
            ),
            Expanded(
              child: state is AnimalLoading
                  ? const Center(
                      child:
                          CircularProgressIndicator(color: Color(0xFF2ECC71)))
                  : RefreshIndicator(
                      color: const Color(0xFF2ECC71),
                      onRefresh: refreshAnimals,
                      child: filtered.isEmpty
                          ? _buildEmpty(state)
                          : ListView.builder(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding:
                                  const EdgeInsets.fromLTRB(20, 0, 20, 100),
                              itemCount: filtered.length,
                              itemBuilder: (_, i) {
                                final animal = filtered[i];
                                return AnimalListCard(
                                  animal: animal,
                                  isSelected: _selectedIds.contains(animal.id),
                                  selectMode: _selectMode,
                                  onLongPress: () => setState(() {
                                    _selectMode = true;
                                    _selectedIds.add(animal.id);
                                  }),
                                  onTap: () {
                                    if (_selectMode) {
                                      setState(() {
                                        if (_selectedIds.contains(animal.id)) {
                                          _selectedIds.remove(animal.id);
                                        } else {
                                          _selectedIds.add(animal.id);
                                        }
                                      });
                                    }
                                    // select deyilsə AnimalListCard özü map açır
                                  },
                                );
                              },
                            ),
                    ),
            ),
          ]),
          // ── Yalnız group seçim rejimində FAB göstər ──────────────────────
          floatingActionButton: _selectedIds.isNotEmpty
              ? FloatingActionButton.extended(
                  heroTag: 'fab_group',
                  onPressed: () => _showGroupActions(animals),
                  backgroundColor: const Color(0xFF2ECC71),
                  icon: const Icon(Iconsax.location, color: Colors.white),
                  label: Text('${_selectedIds.length} seçildi',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                )
              : null, // ← HomePage FAB-ı idarə edir
        );
      },
    );
  }

  Widget _buildEmpty(AnimalState state) {
    if (state is AnimalError) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 300,
            child:
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Iconsax.warning_2, size: 48, color: Color(0xFFFF4444)),
              const SizedBox(height: 12),
              Text(state.message, style: const TextStyle(color: Colors.grey)),
            ]),
          ),
        ],
      );
    }
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: 300,
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: Colors.grey.shade100, shape: BoxShape.circle),
              child: const Icon(Iconsax.pet, size: 48, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text('Heyvan tapılmadı',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
            const SizedBox(height: 8),
            Text('+ düyməsindən yeni heyvan əlavə edin',
                style: TextStyle(fontSize: 13, color: Colors.grey[400])),
          ]),
        ),
      ],
    );
  }
}
