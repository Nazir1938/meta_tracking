import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:meta_tracking/features/animals/presentation/bloc/animal_bloc.dart';
import 'package:meta_tracking/features/auth/domain/entities/user_entity.dart';
import 'package:meta_tracking/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:meta_tracking/features/auth/presentation/screens/login_screen.dart';
import 'package:meta_tracking/features/herds/domain/entities/herd_entity.dart';
import 'package:meta_tracking/features/herds/presentation/bloc/herd_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/bloc/zone_bloc.dart';
import 'package:meta_tracking/features/zones/presentation/state/zone_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ProfileHeader — avatar + ad + email
// ─────────────────────────────────────────────────────────────────────────────

class ProfileHeader extends StatefulWidget {
  final UserEntity? user;
  const ProfileHeader({super.key, this.user});

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
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
            color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          const Text('Foto əlavə et',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          _srcBtn('Kamera', Iconsax.camera, const Color(0xFF1D9E75),
              () => Navigator.pop(context, ImageSource.camera)),
          const SizedBox(height: 10),
          _srcBtn('Qalereyadan seç', Iconsax.gallery,
              const Color(0xFF185FA5),
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
      final ref =
          FirebaseStorage.instance.ref('avatars/${auth.user.id}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      if (mounted) {
        context.read<AuthBloc>().add(UpdateProfileEvent(avatarUrl: url));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Yükləmə xətası: $e'),
          backgroundColor: const Color(0xFFE24B4A),
        ));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Widget _srcBtn(
          String label, IconData icon, Color color, VoidCallback fn) =>
      GestureDetector(
        onTap: fn,
        child: Container(
          width: double.infinity,
          padding:
              const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: color.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Row(children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ]),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final user = widget.user;
    final name = user?.name ?? 'İstifadəçi';
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final avatarUrl = user?.avatarUrl;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
          top: top + 16, left: 20, right: 20, bottom: 20),
      child: Row(children: [
        GestureDetector(
          onTap: _pickPhoto,
          child: Stack(children: [
            Container(
              width: 72, height: 72,
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
                bottom: 0, right: 0,
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: const Icon(Iconsax.camera,
                      size: 12, color: Colors.white),
                ),
              ),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 3),
                Text(email,
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey[500])),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D9E75)
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(user?.herdGroupLabel ?? 'Sürü',
                      style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF1D9E75),
                          fontWeight: FontWeight.w600)),
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

// ─────────────────────────────────────────────────────────────────────────────
// ProfileStatsRow
// ─────────────────────────────────────────────────────────────────────────────

class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({super.key});

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
    final label =
        context.watch<AuthBloc>().state is AuthAuthenticated
            ? (context.watch<AuthBloc>().state as AuthAuthenticated)
                .user
                .herdGroupLabel
            : 'Sürü';

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
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: c)),
            const SizedBox(height: 3),
            Text(lbl,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[500])),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileHerdListSection — sürü siyahısı + adını dəyiş
// ─────────────────────────────────────────────────────────────────────────────

class ProfileHerdListSection extends StatelessWidget {
  final String groupLabel;
  const ProfileHerdListSection({super.key, required this.groupLabel});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HerdBloc, HerdState>(
      builder: (_, state) {
        final herds =
            state is HerdsLoaded ? state.herds : <HerdEntity>[];
        if (herds.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8, top: 4),
              child: Text(
                'Mövcud ${groupLabel}lər'.toUpperCase(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey[500],
                    letterSpacing: 0.5),
              ),
            ),
            ...herds.map((h) => ProfileHerdRenameTile(herd: h)),
          ],
        );
      },
    );
  }
}

class ProfileHerdRenameTile extends StatelessWidget {
  final HerdEntity herd;
  const ProfileHerdRenameTile({super.key, required this.herd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200, width: 0.5),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: const Color(0xFF1D9E75).withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Iconsax.people,
              color: Color(0xFF1D9E75), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(herd.name,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                Text('${herd.animalCount} heyvan',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
              ]),
        ),
        GestureDetector(
          onTap: () => _showRenameDialog(context),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF185FA5).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Iconsax.edit_2, size: 13, color: Color(0xFF185FA5)),
              SizedBox(width: 4),
              Text('Adını dəyiş',
                  style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF185FA5),
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
      ]),
    );
  }

  void _showRenameDialog(BuildContext context) {
    final ctrl = TextEditingController(text: herd.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Sürü adını dəyiş',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Yeni ad',
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF1D9E75), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina',
                  style: TextStyle(color: Colors.grey[500]))),
          TextButton(
            onPressed: () {
              final name = ctrl.text.trim();
              if (name.isEmpty) return;
              Navigator.pop(context);
              context
                  .read<HerdBloc>()
                  .add(UpdateHerdEvent(herd.copyWith(name: name)));
            },
            child: const Text('Yadda Saxla',
                style: TextStyle(
                    color: Color(0xFF1D9E75),
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileMenuItem
// ─────────────────────────────────────────────────────────────────────────────

class ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const ProfileMenuItem({
    super.key,
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
            border:
                Border.all(color: Colors.grey.shade200, width: 0.5),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
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
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey[500])),
                  ]),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.grey[400], size: 20),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// EditProfileSheet
// ─────────────────────────────────────────────────────────────────────────────

class EditProfileSheet extends StatefulWidget {
  final UserEntity? user;
  const EditProfileSheet({super.key, this.user});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late final TextEditingController _nameCtrl;

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
          width: 36, height: 4,
          decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Profili Redaktə Et',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: InputDecoration(
            labelText: 'Ad Soyad',
            prefixIcon: const Icon(Iconsax.user, size: 18),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                  color: Color(0xFF1D9E75), width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              context
                  .read<AuthBloc>()
                  .add(UpdateProfileEvent(name: name));
              Navigator.pop(context);
            },
            icon: const Icon(Iconsax.tick_circle, size: 18),
            label: const Text('Yadda Saxla'),
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

// ─────────────────────────────────────────────────────────────────────────────
// NotificationSettingsSheet
// ─────────────────────────────────────────────────────────────────────────────

class NotificationSettingsSheet extends StatefulWidget {
  const NotificationSettingsSheet({super.key});

  @override
  State<NotificationSettingsSheet> createState() =>
      _NotificationSettingsSheetState();
}

class _NotificationSettingsSheetState
    extends State<NotificationSettingsSheet> {
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
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 14),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Bildiriş Tənzimləmələri',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1A1A2E))),
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: Text('Hansı alertlar göndərilsin?',
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
            ),
            const SizedBox(height: 16),
          ]),
        ),
        _sw(Iconsax.location, 'Zona alertları',
            'Heyvan zona xaricinə çıxanda', const Color(0xFF1D9E75),
            _zoneAlerts, (v) => setState(() => _zoneAlerts = v)),
        _divider(),
        _sw(Iconsax.warning_2, 'Sürü ayrılma alertları',
            'Heyvan sürüdən uzaqlaşanda', const Color(0xFFE24B4A),
            _separationAlerts,
            (v) => setState(() => _separationAlerts = v)),
        _divider(),
        _sw(Iconsax.volume_high, 'Səs', 'Alert səsi',
            const Color(0xFF185FA5), _soundEnabled,
            (v) => setState(() => _soundEnabled = v)),
        _divider(),
        _sw(Iconsax.mobile, 'Vibrasiya', 'Telefonun vibrasiyası',
            const Color(0xFFBA7517), _vibrationEnabled,
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

  Widget _divider() => Divider(
      height: 1, color: Colors.grey.shade100, indent: 16, endIndent: 16);

  Widget _sw(IconData icon, String label, String sub, Color color,
          bool val, ValueChanged<bool> onChange) =>
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A2E))),
                  Text(sub,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey[500])),
                ]),
          ),
          Switch.adaptive(
              value: val,
              onChanged: onChange,
              activeColor: const Color(0xFF1D9E75)),
        ]),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// ProfileLogoutButton
// ─────────────────────────────────────────────────────────────────────────────

class ProfileLogoutButton extends StatelessWidget {
  const ProfileLogoutButton({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        height: 50,
        child: OutlinedButton.icon(
          onPressed: () => _confirm(context),
          icon: const Icon(Iconsax.logout,
              size: 18, color: Color(0xFFE24B4A)),
          label: const Text('Çıxış',
              style: TextStyle(
                  color: Color(0xFFE24B4A),
                  fontWeight: FontWeight.w700)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(
                color: Color(0xFFE24B4A), width: 0.5),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  void _confirm(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Çıxış',
            style: TextStyle(fontWeight: FontWeight.w700)),
        content:
            const Text('Hesabdan çıxmaq istədiyinizdən əminsiniz?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('İmtina',
                  style: TextStyle(color: Colors.grey[500]))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthBloc>().add(const LogoutEvent());
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE24B4A),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: const Text('Çıxış et',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}