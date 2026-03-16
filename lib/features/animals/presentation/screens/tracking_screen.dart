import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

// FIX: GPS listener buradan silindi.
// TrackingService (HomePage-də başladılır) artıq bütün isTracking=true
// heyvanlar üçün GPS mövqeyini Firestore-a yazır.
// Bu ekranda dublikat listener saxlamaq → hər GPS yeniləməsini 2x yazırdı.

class TrackingScreen extends StatefulWidget {
  const TrackingScreen({super.key});

  @override
  State<TrackingScreen> createState() => TrackingScreenState();
}

class TrackingScreenState extends State<TrackingScreen> {
  String _filterStatus = 'all';
  final Set<String> _selectedIds = {};
  bool _selectMode = false;

  final GlobalKey _headerKey = GlobalKey();
  double _headerHeight = 0;

  @override
  void initState() {
    super.initState();
    AppLogger.ekranAcildi('Tracking Screen');
    WidgetsBinding.instance.addPostFrameCallback((_) => _measureHeader());
  }

  @override
  void dispose() {
    AppLogger.ekranBaglandi('Tracking Screen');
    super.dispose();
  }

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

  Future<void> refreshAnimals() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is AuthAuthenticated) {
      context.read<AnimalBloc>().add(WatchAnimalsEvent(auth.user.id));
      AppLogger.melumat('TRACKING', 'Manual refresh: ${auth.user.id}');
    }
  }

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

          final headerWidget = RepaintBoundary(
            key: _headerKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TrackingAppBar(
                  animalCount: animals.length,
                  alertCount: alertCount,
                ),
                TrackingSummaryCards(
                  total: animals.length,
                  active: activeCount,
                  inside: insideCount,
                  alert: alertCount,
                ),
                AnimalFilterBar(
                  activeFilter: _filterStatus,
                  isSelectMode: _selectMode,
                  onFilterChanged: (v) {
                    setState(() => _filterStatus = v);
                    WidgetsBinding.instance
                        .addPostFrameCallback((_) => _measureHeader());
                  },
                  onToggleSelectMode: () => setState(() {
                    _selectMode = !_selectMode;
                    if (!_selectMode) _selectedIds.clear();
                  }),
                ),
                Container(height: 0.5, color: Colors.grey.shade200),
              ],
            ),
          );

          return Scaffold(
            backgroundColor: const Color(0xFFF4F6F9),
            body: RefreshIndicator(
              color: const Color(0xFF1D9E75),
              displacement: MediaQuery.of(context).padding.top + 8,
              edgeOffset: 0,
              onRefresh: refreshAnimals,
              child: _headerHeight == 0
                  ? Stack(children: [
                      Positioned(
                          top: -9999, left: 0, right: 0, child: headerWidget),
                      const Center(
                          child: CircularProgressIndicator(
                              color: Color(0xFF1D9E75))),
                    ])
                  : CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverPersistentHeader(
                          pinned: true,
                          delegate: _StickyHeaderDelegate(
                            child: headerWidget,
                            height: _headerHeight,
                          ),
                        ),
                        if (filtered.isEmpty)
                          SliverFillRemaining(
                            child: _EmptyState(
                              message:
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
                                        setState(() {
                                          _selectedIds.contains(animal.id)
                                              ? _selectedIds.remove(animal.id)
                                              : _selectedIds.add(animal.id);
                                        });
                                      } else {
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
            floatingActionButton: _selectedIds.isNotEmpty
                ? FloatingActionButton.extended(
                    heroTag: 'fab_group_action',
                    onPressed: () => _showGroupActions(animals),
                    backgroundColor: const Color(0xFF185FA5),
                    icon: const Icon(Iconsax.people,
                        color: Colors.white, size: 20),
                    label: Text(
                      '${_selectedIds.length} seçildi',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w700),
                    ),
                  )
                : null,
            floatingActionButtonLocation:
                FloatingActionButtonLocation.centerFloat,
          );
        },
      ),
    );
  }
}

// ── Sticky Header Delegate ────────────────────────────────────────────────────

class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  final double height;
  const _StickyHeaderDelegate({required this.child, required this.height});

  @override
  Widget build(
          BuildContext context, double shrinkOffset, bool overlapsContent) =>
      child;

  @override
  double get maxExtent => height;
  @override
  double get minExtent => height;
  @override
  bool shouldRebuild(_StickyHeaderDelegate old) =>
      old.height != height || old.child != child;
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String? message;
  final bool filterActive;
  final VoidCallback onClearFilter;

  const _EmptyState({
    this.message,
    required this.filterActive,
    required this.onClearFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(
            filterActive ? Iconsax.filter_search : Iconsax.pet,
            size: 52,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            message ??
                (filterActive
                    ? 'Bu filterlə heyvan tapılmadı'
                    : 'Hələ heç bir heyvan yoxdur.\n+ düyməsindən əlavə edin.'),
            textAlign: TextAlign.center,
            style:
                TextStyle(fontSize: 14, color: Colors.grey[500], height: 1.5),
          ),
          if (filterActive) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: onClearFilter,
              child: const Text('Filteri Sil',
                  style: TextStyle(color: Color(0xFF1D9E75))),
            ),
          ],
        ]),
      ),
    );
  }
}
