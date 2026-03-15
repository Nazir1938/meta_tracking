import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/domain/entities/user_entity.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/login_screen.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';
import 'package:meta_tracking/features/herds/presentation/screens/create_herd_sheet.dart';
import 'package:meta_tracking/features/herds/presentation/screens/herds_screen.dart';
import 'package:meta_tracking/features/notifications/presentation/bloc/notification_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      child: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, s) => s is AuthProfileUpdated,
        listener: (ctx, state) {
          if (state is AuthProfileUpdated) {
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
              content: const Text('Profil yenilendi'),
              backgroundColor: const Color(0xFF1D9E75),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ));
          }
        },
        child: Scaffold(
          backgroundColor: const Color(0xFFF4F6F9),
          body: BlocBuilder<AuthBloc, AuthState>(
            builder: (ctx, authState) {
              final user =
                  authState is AuthAuthenticated ? authState.user : null;
              return CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(child: _ProfileHeader(user: user)),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 16, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _StatsRow(),
                        const SizedBox(height: 20),
                        _sectionLabel(user?.herdGroupLabel ?? 'Naxir'),
                        const SizedBox(height: 8),
                        _MenuItem(
                          icon: Iconsax.people,
                          label: '${user?.herdGroupLabel ?? 'Naxir'}larim',
                          subtitle: 'Heyvan qruplarini idare et',
                          color: const Color(0xFF1D9E75),
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => const HerdsScreen()),
                          ),
                        ),
                        const SizedBox(height: 8),
                        _GroupLabelTile(user: user),
                        const SizedBox(height: 20),
                        _sectionLabel('Hesab'),
                        const SizedBox(height: 8),
                        _MenuItem(
                          icon: Iconsax.user_edit,
                          label: 'Profili redakte et',
                          subtitle: 'Ad, email melumatları',
                          color: const Color(0xFF185FA5),
                          onTap: () => _showEditProfile(context, user),
                        ),
                        const SizedBox(height: 8),
                        _MenuItem(
                          icon: Iconsax.notification,
                          label: 'Bildiriş tenzimlemeleri',
                          subtitle: 'Alert, ses, vibrasiya',
                          color: const Color(0xFFBA7517),
                          onTap: () => _showNotifSettings(context),
                        ),
                        const SizedBox(height: 20),
                        _sectionLabel('Tetbiq'),
                        const SizedBox(height: 8),
                        _MenuItem(
                          icon: Iconsax.shield_tick,
                          label: 'Mexfilik siyaseti',
                          color: Colors.grey,
                          onTap: () {},
                        ),
                        const SizedBox(height: 8),
                        _MenuItem(
                          icon: Iconsax.info_circle,
                          label: 'Haqqinda',
                          subtitle: 'v1.0.0',
                          color: Colors.grey,
                          onTap: () => _showAbout(context),
                        ),
                        const SizedBox(height: 24),
                        _LogoutButton(),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
          floatingActionButton: BlocBuilder<AuthBloc, AuthState>(
            builder: (ctx, auth) {
              final label = auth is AuthAuthenticated
                  ? auth.user.herdGroupLabel
                  : 'Naxir';
              return FloatingActionButton.extended(
                heroTag: 'fab_profile_herd',
                onPressed: () => _showCreateHerd(context, auth),
                backgroundColor: const Color(0xFF1D9E75),
                elevation: 4,
                icon: const Icon(Iconsax.people, color: Colors.white, size: 20),
                label: Text('$label Yarat',
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              );
            },
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey[500],
            letterSpacing: 0.6),
      );

  void _showCreateHerd(BuildContext context, AuthState auth) {
    if (auth is! AuthAuthenticated) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<HerdBloc>(),
        child: BlocProvider.value(
          value: context.read<AnimalBloc>(),
          child: CreateHerdSheet(ownerId: auth.user.id),
        ),
      ),
    );
  }

  void _showEditProfile(BuildContext context, UserEntity? user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: _EditProfileSheet(user: user),
      ),
    );
  }

  void _showNotifSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<NotificationBloc>(),
        child: const _NotificationSettingsSheet(),
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75),
              borderRadius: BorderRadius.circular(18),
            ),
            child:
                const Center(child: Text('🐄', style: TextStyle(fontSize: 32))),
          ),
          const SizedBox(height: 14),
          const Text('Meta Tracking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('Versiya 1.0.0', style: TextStyle(color: Colors.grey[500])),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Bagla', style: TextStyle(color: Color(0xFF1D9E75))),
          ),
        ],
      ),
    );
  }
}

// ─── Profile Header ───────────────────────────────────────────────────────────

class _ProfileHeader extends StatefulWidget {
  final UserEntity? user;
  const _ProfileHeader({this.user});

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  bool _uploading = false;

  Future<void> _pickPhoto() async {
    final auth = context.read<AuthBloc>().state;
    if (auth is! AuthAuthenticated) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Foto elave et',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _srcBtn('Kamera', Iconsax.camera, const Color(0xFF1D9E75),
              () => Navigator.pop(context, ImageSource.camera)),
          const SizedBox(height: 10),
          _srcBtn('Qalereyadan sec', Iconsax.gallery, const Color(0xFF185FA5),
              () => Navigator.pop(context, ImageSource.gallery)),
        ]),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
        source: source, imageQuality: 75, maxWidth: 512, maxHeight: 512);
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final ref = FirebaseStorage.instance.ref('avatars/${auth.user.id}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      if (mounted) {
        context.read<AuthBloc>().add(UpdateProfileEvent(avatarUrl: url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Yukleme xetasi: $e'),
          backgroundColor: const Color(0xFFE24B4A),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _srcBtn(
          String label, IconData icon, Color color, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5),
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

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final user = widget.user;
    final name = user?.name ?? 'Istifadeci';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarUrl = user?.avatarUrl;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(top: top + 16, left: 20, right: 20, bottom: 20),
      child: Row(children: [
        GestureDetector(
          onTap: _pickPhoto,
          child: Stack(children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
              ),
              clipBehavior: Clip.antiAlias,
              child: _uploading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF1D9E75), strokeWidth: 2))
                  : avatarUrl != null && avatarUrl.isNotEmpty
                      ? Image.network(avatarUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _initW(initial))
                      : _initW(initial),
            ),
            if (!_uploading)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child:
                      const Icon(Iconsax.camera, size: 12, color: Colors.white),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E))),
            const SizedBox(height: 3),
            Text(email,
                style: TextStyle(fontSize: 13, color: Colors.grey[500])),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1D9E75).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                user?.herdGroupLabel ?? 'Naxir',
                style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF1D9E75),
                    fontWeight: FontWeight.w600),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _initW(String i) => Center(
        child: Text(i,
            style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D9E75))),
      );
}

// ─── Group Label Tile ─────────────────────────────────────────────────────────

class _GroupLabelTile extends StatelessWidget {
  final UserEntity? user;
  const _GroupLabelTile({this.user});

  static const _presets = [
    'Naxir',
    'Suru',
    'Otlaq',
    'Qrup',
    'Inekler',
    'Qoyunlar',
    'Atlar',
    'Keciler',
  ];

  @override
  Widget build(BuildContext context) {
    final current = user?.herdGroupLabel ?? 'Naxir';
    return GestureDetector(
      onTap: () => _showPicker(context, current),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.25),
              width: 0.5),
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF1D9E75).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                const Icon(Iconsax.edit_2, color: Color(0xFF1D9E75), size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Qrup adini deyis',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              Text('Hazirda: "$current"',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          ),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
        ]),
      ),
    );
  }

  void _showPicker(BuildContext context, String current) {
    final customCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<AuthBloc>(),
        child: StatefulBuilder(
          builder: (ctx, set) => Container(
            margin: EdgeInsets.only(
                left: 12,
                right: 12,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 12),
            decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(24)),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Column(children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 14),
                  Row(children: [
                    const Expanded(
                      child: Text('Qrup adini sec',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w800)),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Iconsax.close_circle,
                          color: Colors.grey[400], size: 22),
                    ),
                  ]),
                  const SizedBox(height: 14),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _presets.map((label) {
                    final isSelected = label == current;
                    return GestureDetector(
                      onTap: () {
                        ctx
                            .read<AuthBloc>()
                            .add(UpdateProfileEvent(herdGroupLabel: label));
                        Navigator.pop(ctx);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 160),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF1D9E75)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFF1D9E75)
                                : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.grey[700])),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(children: [
                  Expanded(
                    child: TextField(
                      controller: customCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ozel ad yazin...',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14)),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                              color: Color(0xFF1D9E75), width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: () {
                      final val = customCtrl.text.trim();
                      if (val.isEmpty) return;
                      ctx
                          .read<AuthBloc>()
                          .add(UpdateProfileEvent(herdGroupLabel: val));
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1D9E75),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                    child: const Text('Saxla',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ]),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─── Stats Row ────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final animalCount = context.watch<AnimalBloc>().state is AnimalLoaded
        ? (context.watch<AnimalBloc>().state as AnimalLoaded).animals.length
        : 0;
    final zoneCount = context.watch<ZoneBloc>().state is ZonesLoaded
        ? (context.watch<ZoneBloc>().state as ZonesLoaded).zones.length
        : 0;
    final herdCount = context.watch<HerdBloc>().state is HerdsLoaded
        ? (context.watch<HerdBloc>().state as HerdsLoaded).herds.length
        : 0;
    final label = context.watch<AuthBloc>().state is AuthAuthenticated
        ? (context.watch<AuthBloc>().state as AuthAuthenticated)
            .user
            .herdGroupLabel
        : 'Naxir';

    return Row(children: [
      _stat('$animalCount', 'Heyvan', const Color(0xFF185FA5)),
      const SizedBox(width: 10),
      _stat('$zoneCount', 'Zona', const Color(0xFF1D9E75)),
      const SizedBox(width: 10),
      _stat('$herdCount', label, const Color(0xFFBA7517)),
    ]);
  }

  Widget _stat(String val, String lbl, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Column(children: [
            Text(val,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: c)),
            const SizedBox(height: 3),
            Text(lbl, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
        ),
      );
}

// ─── Edit Profile Sheet ───────────────────────────────────────────────────────

class _EditProfileSheet extends StatefulWidget {
  final UserEntity? user;
  const _EditProfileSheet({this.user});

  @override
  State<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<_EditProfileSheet> {
  late final TextEditingController _nameCtrl;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.user?.name ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() => _loading = true);
    context.read<AuthBloc>().add(UpdateProfileEvent(name: name));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(
          left: 12,
          right: 12,
          bottom: MediaQuery.of(context).viewInsets.bottom + 12),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[200], borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Profili Redakte Et',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Ad Soyad',
            prefixIcon: const Icon(Iconsax.user, size: 18),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF1D9E75), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: _loading ? null : _save,
            icon: _loading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Iconsax.tick_circle, size: 18),
            label: Text(_loading ? 'Saxlanilir...' : 'Yadda Saxla'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1D9E75),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Notification Settings Sheet ─────────────────────────────────────────────

class _NotificationSettingsSheet extends StatefulWidget {
  const _NotificationSettingsSheet();

  @override
  State<_NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<_NotificationSettingsSheet> {
  bool _zoneAlerts = true;
  bool _separationAlerts = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: Column(children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Bildiriş Tenzimlemeleri',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Hansi alertlar gonderilsin?',
                  style: TextStyle(fontSize: 12, color: Colors.grey[500])),
            ),
            const SizedBox(height: 16),
          ]),
        ),
        _sw(
            Iconsax.location,
            'Zona alertlari',
            'Heyvan zona xaricine cixanda',
            const Color(0xFF1D9E75),
            _zoneAlerts,
            (v) => setState(() => _zoneAlerts = v)),
        Divider(
            height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
        _sw(
            Iconsax.warning_2,
            'Suru ayrilma alertlari',
            'Heyvan surudan uzaqlaşanda',
            const Color(0xFFE24B4A),
            _separationAlerts,
            (v) => setState(() => _separationAlerts = v)),
        Divider(
            height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
        _sw(Iconsax.volume_high, 'Ses', 'Alert sesi', const Color(0xFF185FA5),
            _soundEnabled, (v) => setState(() => _soundEnabled = v)),
        Divider(
            height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16),
        _sw(
            Iconsax.mobile,
            'Vibrasiya',
            'Telefonun vibrasiyasi',
            const Color(0xFFBA7517),
            _vibrationEnabled,
            (v) => setState(() => _vibrationEnabled = v)),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1D9E75),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Yadda Saxla',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _sw(IconData icon, String label, String sub, Color color, bool val,
          ValueChanged<bool> onChange) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E))),
              Text(sub,
                  style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ]),
          ),
          Switch.adaptive(
              value: val,
              onChanged: onChange,
              activeColor: const Color(0xFF1D9E75)),
        ]),
      );
}

// ─── Menu Item ────────────────────────────────────────────────────────────────

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A2E))),
                    if (subtitle != null)
                      Text(subtitle!,
                          style:
                              TextStyle(fontSize: 11, color: Colors.grey[500])),
                  ]),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ]),
        ),
      );
}

// ─── Logout Button ────────────────────────────────────────────────────────────

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () => _confirm(context),
          icon: const Icon(Iconsax.logout, size: 18, color: Color(0xFFE24B4A)),
          label: const Text('Cixis',
              style: TextStyle(
                  color: Color(0xFFE24B4A), fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE24B4A), width: 0.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Cixis', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Hesabdan cixmaq istediyinizdən eminsiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Imtina', style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE24B4A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child:
                const Text('Cixis et', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
