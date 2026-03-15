import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import 'package:meta_tracking/features/home/presentation/screens/animal_detail_screen.dart';
import 'package:meta_tracking/features/map/presentation/screens/map_screen.dart';

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => TrackingScreenState();
}

class TrackingScreenState extends State<TrackingScreen> {
  // ── Filter & select state ─────────────────────────────────────────────────
  String _filterStatus = 'all';
  final Set<String> _selectedIds = {};
  bool _selectMode = false;

  // ── GPS ───────────────────────────────────────────────────────────────────
  StreamSubscription<Position>? _locationSub;

  // ── Sticky header ölçümü ──────────────────────────────────────────────────
  // SliverPersistentHeader sabit hündürlük tələb edir.
  // GlobalKey ilə ilk frame-dən sonra real hündürlüyü ölçürük,
  // sonra CustomScrollView-ı render edirik. Bu yolla heç vaxt overflow olmur.
  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Tracking Screen');
    _requestLocationPermission();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void dispose() {
    _locationSub?.cancel();
    AppLogger.ekranBaglandi('Tracking Screen');
    super.dispose();
  }

  // ── Header hündürlüyünü ölç ───────────────────────────────────────────────
  void _measureHeader() {
    final ctx = _headerKey.currentContext;
    if (ctx == null) return;
    final box = ctx.findRenderObject() as RenderBox?;
    if (box == null) return;
    final h = box.size.height;
    if (h > 0 && h != _headerHeight) {
      setState(() => _headerHeight = h);
    }
  }

  // ── Pull-to-refresh ───────────────────────────────────────────────────────
  Future<void> refreshAnimals() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<AnimalBloc>().add(WatchAnimalsEvent(auth.user.id));
      AppLogger.melumat('TRACKING', 'Manual refresh: ${auth.user.id}');
    }
  }

  // ── GPS icazə + izləmə ────────────────────────────────────────────────────
  Future<void> _requestLocationPermission() async {
    try {
      LocationPermission p = await Geolocator.checkPermission();
      if (p == LocationPermission.denied) {
        p = await Geolocator.requestPermission();
        AppLogger.melumat('GPS', 'İcazə sorğusu göndərildi');
      }
      if (p == LocationPermission.deniedForever) {
        AppLogger.xeberdarliq('GPS', 'İcazə həmişəlik rədd edildi');
        if (mounted) _showPermissionDialog();
        return;
      }
      if (p == LocationPermission.whileInUse ||
          p == LocationPermission.always) {
        AppLogger.ugur('GPS', 'İcazə verildi');
        _startLocationTracking();
      }
    } catch (e) {
      AppLogger.xeta('GPS', 'İcazə xətası', xetaObyekti: e);
    }
  }

  void _startLocationTracking() {
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10,
      ),
    ).listen(
      (pos) {
        if (!mounted) return;
        final auth = context.read<AuthBloc>().state;
        if (auth is! AuthAuthenticated) return;

        final animalState = context.read<AnimalBloc>().state;
        if (animalState is! AnimalLoaded) return;

        // Yalnız aktiv izlənən heyvanların mövqeyini yenilə
        for (final animal in animalState.animals.where((a) => a.isTracking)) {
          context.read<AnimalBloc>().add(UpdateLocationEvent(
                animalId: animal.id,
                lat: pos.latitude,
                lng: pos.longitude,
                speed: pos.speed,
                battery: 1.0,
              ));
        }
        AppLogger.melumat(
            'GPS', 'Mövqe yeniləndi: ${pos.latitude}, ${pos.longitude}');
      },
      onError: (e) => AppLogger.xeta('GPS', 'Stream xətası', xetaObyekti: e),
    );
    AppLogger.ugur('GPS', 'GPS stream başladı');
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [
          Icon(Iconsax.location, color: Color(0xFF1D9E75)),
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
                backgroundColor: const Color(0xFF1D9E75)),
            child: const Text('Tənzimləmələr',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ── Filter tətbiq et ──────────────────────────────────────────────────────
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

  // ── Qrup əməliyyatları ────────────────────────────────────────────────────
  void _showGroupActions(List<AnimalEntity> allAnimals) {
    final selected =
        allAnimals.where((a) => _selectedIds.contains(a.id)).toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
            color: Colors.white, borderRadius: BorderRadius.circular(24)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // Handle
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 14),
          Text(
            '${_selectedIds.length} heyvan seçildi',
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 16),
          // Xəritədə göstər
          _groupActionTile(
            icon: Iconsax.map,
            label: 'Xəritədə göstər',
            color: const Color(0xFF185FA5),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => MapScreen(
                  highlightedAnimalIds: _selectedIds.toList(),
                  animalEntities: selected,
                ),
              ));
            },
          ),
          const SizedBox(height: 10),
          // Seçimi təmizlə
          _groupActionTile(
            icon: Iconsax.close_circle,
            label: 'Seçimi təmizlə',
            color: Colors.grey,
            onTap: () {
              setState(() {
                _selectedIds.clear();
                _selectMode = false;
              });
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 4),
        ]),
      ),
    );
  }

  Widget _groupActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: BlocBuilder<AnimalBloc, AnimalState>(
        builder: (context, state) {
          final animals =
              state is AnimalLoaded ? state.animals : <AnimalEntity>[];

          final filtered = _applyFilter(animals);

          final alertCount = animals
              .where((a) => a.zoneStatus == AnimalZoneStatus.alert)
              .length;
          final activeCount = animals.where((a) => a.isTracking).length;
          final insideCount = animals
              .where((a) => a.zoneStatus == AnimalZoneStatus.inside)
              .length;

          // Header widget — GlobalKey ilə ölçülür
          final headerWidget = RepaintBoundary(
            key: _headerKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // AppBar: avatar + ad + alert badge + bildiriş
                TrackingAppBar(
                  animalCount: animals.length,
                  alertCount: alertCount,
                ),
                // 4 summary kart
                TrackingSummaryCards(
                  total: animals.length,
                  active: activeCount,
                  inside: insideCount,
                  alert: alertCount,
                ),
                // Filter chipləri + seç düyməsi
                AnimalFilterBar(
                  activeFilter: _filterStatus,
                  isSelectMode: _selectMode,
                  onFilterChanged: (v) {
                    setState(() => _filterStatus = v);
                    // Filter dəyişdikdə header hündürlüyünü yenidən ölç
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _measureHeader());
                  },
                  onToggleSelectMode: () => setState(() {
                    _selectMode = !_selectMode;
                    if (!_selectMode) _selectedIds.clear();
                  }),
                ),
                // Alt ayırıcı xətt
                Container(height: 0.5, color: Colors.grey.shade200),
              ],
            ),
          );

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),
            body: RefreshIndicator(
              color: const Color(0xFF1D9E75),
              // pull indicator status bar-ın altından başlasın
              displacement: MediaQuery.of(context).padding.top + 8,
              edgeOffset: 0,
              onRefresh: refreshAnimals,
              child: _headerHeight == 0
                  // ── İlk frame: header-i ölçmək üçün gizli render ──────
                  ? Stack(children: [
                      Positioned(
                        top: -9999,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width,
                          child: headerWidget,
                        ),
                      ),
                      const Center(
                        child:
                            CircularProgressIndicator(color: Color(0xFF1D9E75)),
                      ),
                    ])
                  // ── Normal render ─────────────────────────────────────
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        // ── Sticky header ──────────────────────────────
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _StickyHeaderDelegate(
                            height: _headerHeight,
                            child: headerWidget,
                          ),
                        ),

                        // ── Məzmun ─────────────────────────────────────
                        if (state is AnimalLoading)
                          const SliverFillRemaining(
                            child: Center(
                              child: CircularProgressIndicator(
                                  color: Color(0xFF1D9E75)),
                            ),
                          )
                        else if (filtered.isEmpty)
                          SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyState(
                              isError: state is AnimalError,
                              errorMsg:
                                  state is AnimalError ? state.message : null,
                              filterActive: _filterStatus != 'all',
                              onClearFilter: () =>
                                  setState(() => _filterStatus = 'all'),
                            ),
                          )
                        else
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (_, i) {
                                  final animal = filtered[i];
                                  return AnimalListCard(
                                    animal: animal,
                                    isSelected:
                                        _selectedIds.contains(animal.id),
                                    selectMode: _selectMode,
                                    onLongPress: () => setState(() {
                                      _selectMode = true;
                                      _selectedIds.add(animal.id);
                                    }),
                                    onTap: () {
                                      if (_selectMode) {
                                        // Seçim rejimi: checkbox toggle
                                        setState(() {
                                          _selectedIds.contains(animal.id)
                                              ? _selectedIds.remove(animal.id)
                                              : _selectedIds.add(animal.id);
                                        });
                                      } else {
                                        // Normal: detal ekranı aç
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => AnimalDetailScreen(
                                                animal: animal),
                                          ),
                                        );
                                      }
                                    },
                                  );
                                },
                                childCount: filtered.length,
                              ),
                            ),
                          ),
                      ],
                    ),
            ),

            // ── Qrup seçim FAB-ı ──────────────────────────────────────
            floatingActionButton: _selectedIds.isNotEmpty
                ? FloatingActionButton.extended(
                    heroTag: 'fab_group_tracking',
                    onPressed: () => _showGroupActions(animals),
                    backgroundColor: const Color(0xFF1D9E75),
                    elevation: 4,
                    icon: const Icon(Iconsax.location,
                        color: Colors.white, size: 18),
                    label: Text(
                      '${_selectedIds.length} seçildi',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  )
                : null,
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sticky Header Delegate
// maxExtent == minExtent == ölçülmüş real hündürlük → heç vaxt overflow yoxdur
// ─────────────────────────────────────────────────────────────────────────────

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  const _StickyHeaderDelegate({
    required this.height,
    required this.child,
  });

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      SizedBox(height: height, child: child);

  @override
  double get maxExtent => height;

  @override
  double get minExtent => height;

  @override
  bool shouldRebuild(_StickyHeaderDelegate old) =>
      old.height != height || old.child != child;
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty State Widget
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isError;
  final String? errorMsg;
  final bool filterActive;
  final VoidCallback onClearFilter;

  const _EmptyState({
    required this.isError,
    this.errorMsg,
    required this.filterActive,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    if (isError) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFE24B4A).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Iconsax.warning_2,
                size: 44, color: Color(0xFFE24B4A)),
          ),
          const SizedBox(height: 16),
          const Text('Xəta baş verdi',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          if (errorMsg != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                errorMsg!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ]),
      );
    }

    if (filterActive) {
      // Filter aktiv amma nəticə yoxdur
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: Colors.grey.shade100, shape: BoxShape.circle),
            child: Icon(Iconsax.filter, size: 44, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          const Text('Nəticə tapılmadı',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E))),
          const SizedBox(height: 6),
          Text('Bu filterlə heyvan yoxdur',
              style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          const SizedBox(height: 16),
          TextButton(
            onPressed: onClearFilter,
            child: const Text('Filtri təmizlə',
                style: TextStyle(
                    color: Color(0xFF1D9E75), fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    // Heç bir heyvan yoxdur
    return Center(
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
                fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey)),
        const SizedBox(height: 6),
        Text('+ düyməsindən yeni heyvan əlavə edin',
            style: TextStyle(fontSize: 12, color: Colors.grey[400])),
      ]),
    );
  }
}
