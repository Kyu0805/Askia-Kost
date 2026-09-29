import 'dart:async';

import 'package:flutter/material.dart';

import 'src/config/app_visibility_flags.dart';
import 'src/data/sample_data.dart';
import 'src/data/seller_verification_repository.dart';
import 'src/data/seller_notes_repository.dart';
import 'src/models/app_models.dart';
import 'src/screens/buyer/buyer_experience.dart';
import 'src/screens/root/role_login_page.dart';
import 'src/screens/seller/seller_menu_manager_page.dart';
import 'src/screens/seller/seller_verification_page.dart';
import 'src/state/app_session_controller.dart';
import 'src/state/seller_menu_controller.dart';
import 'src/theme/app_theme.dart';
import 'src/widgets/seller_property_switcher_card.dart';

void main() {
  runApp(const AskiaKostApp());
}

class AskiaKostApp extends StatelessWidget {
  const AskiaKostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Askia Kos',
      theme: buildAppTheme(),
      home: const SplashFlow(),
    );
  }
}

class SplashFlow extends StatefulWidget {
  const SplashFlow({super.key});

  @override
  State<SplashFlow> createState() => _SplashFlowState();
}

class _SplashFlowState extends State<SplashFlow> {
  int _step = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _scheduleNext();
  }

  void _scheduleNext() {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: _step == 0 ? 1400 : 1700), () {
      if (!mounted) return;
      if (_step < 2) {
        setState(() {
          _step += 1;
        });
        _scheduleNext();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_step == 0) {
      return const SplashLogoScreen();
    }
    if (_step == 1) {
      return const SplashTaglineScreen();
    }
    return const RootModeHost();
  }
}

class SplashLogoScreen extends StatelessWidget {
  const SplashLogoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFF1FCF4), Color(0xFFFFFFFF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const AppLogo(size: 86),
              const SizedBox(height: 18),
              Text(
                'Askia Kos',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Temukan kos yang pas untuk lokasi dan budgetmu.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SplashTaglineScreen extends StatelessWidget {
  const SplashTaglineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF3FBF6)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const AppLogo(size: 72),
            const SizedBox(height: 22),
            Text(
              'Askia Kos',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(color: kPrimaryDark),
            ),
            const SizedBox(height: 12),
            Text(
              'Aplikasi pencarian kos yang membantu kamu menemukan hunian di lokasi yang tepat.',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              'Isi preferensimu dan dapatkan rekomendasi kos yang paling cocok.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class RootModeHost extends StatefulWidget {
  const RootModeHost({super.key});

  @override
  State<RootModeHost> createState() => _RootModeHostState();
}

class _RootModeHostState extends State<RootModeHost> {
  final AppSessionController _sessionController = AppSessionController();

  @override
  void initState() {
    super.initState();
    _sessionController.initializeFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _sessionController,
      builder: (BuildContext context, _) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child:
              !_sessionController.isAuthenticated
                  ? RoleLoginPage(
                    key: const ValueKey<String>('role-login-initial'),
                    sessionController: _sessionController,
                  )
                  : _sessionController.activeMode == AppMode.seller
                  ? SellerShell(
                    key: const ValueKey<String>('seller-shell'),
                    onLogout: () {
                      _sessionController.logout();
                    },
                    statusMessage: _sessionController.authStatus,
                    isCloudReady: _sessionController.firebaseReady,
                  )
                  : _sessionController.activeMode == AppMode.admin
                  ? AdminShell(
                    key: const ValueKey<String>('admin-shell'),
                    onLogout: () {
                      _sessionController.logout();
                    },
                    statusMessage: _sessionController.authStatus,
                    isCloudReady: _sessionController.firebaseReady,
                  )
                  : BuyerShell(
                    key: const ValueKey<String>('buyer-shell'),
                    onSwitchMode: () {
                      if (_sessionController.activeMode == AppMode.buyer) {
                        _sessionController.switchMode(AppMode.seller);
                        return;
                      }
                      _openRoleLogin(context, preferredMode: AppMode.seller);
                    },
                    onLogout: () {
                      _sessionController.logout();
                    },
                    statusMessage: _sessionController.authStatus,
                    isCloudReady: _sessionController.firebaseReady,
                  ),
        );
      },
    );
  }

  Future<void> _openRoleLogin(
    BuildContext context, {
    AppMode? preferredMode,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => RoleLoginPage(
          sessionController: _sessionController,
          preferredMode: preferredMode,
          onClose: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }
}

class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.onLogout,
    required this.statusMessage,
    required this.isCloudReady,
  });

  final VoidCallback onLogout;
  final String statusMessage;
  final bool isCloudReady;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      AdminDashboardPage(
        onLogout: widget.onLogout,
        statusMessage: widget.statusMessage,
        isCloudReady: widget.isCloudReady,
      ),
      AdminVendorPage(
        statusMessage: widget.statusMessage,
        isCloudReady: widget.isCloudReady,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: tabs)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFF1E6),
        onDestinationSelected: (int value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.store_mall_directory_outlined),
            label: 'Properti',
          ),
        ],
      ),
    );
  }
}

class SellerShell extends StatefulWidget {
  const SellerShell({
    super.key,
    required this.onLogout,
    required this.statusMessage,
    required this.isCloudReady,
  });

  final VoidCallback onLogout;
  final String statusMessage;
  final bool isCloudReady;

  @override
  State<SellerShell> createState() => _SellerShellState();
}

class _SellerShellState extends State<SellerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      SellerDashboardPage(
        onOpenMenu: () {
          setState(() {
            _index = 1;
          });
        },
        onOpenVerification: () async {
          await Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => const SellerVerificationPage(),
            ),
          );
          if (mounted) {
            setState(() {});
          }
        },
        onLogout: widget.onLogout,
        statusMessage: widget.statusMessage,
        isCloudReady: widget.isCloudReady,
      ),
      const SellerMenuManagerPage(),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: tabs)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFE8EEFF),
        onDestinationSelected: (int value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.dashboard_customize_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.apartment_rounded),
            label: 'Properti',
          ),
        ],
      ),
    );
  }
}

class SellerDashboardPage extends StatefulWidget {
  const SellerDashboardPage({
    super.key,
    required this.onOpenMenu,
    required this.onOpenVerification,
    required this.onLogout,
    required this.statusMessage,
    required this.isCloudReady,
  });

  final VoidCallback onOpenMenu;
  final VoidCallback onOpenVerification;
  final VoidCallback onLogout;
  final String statusMessage;
  final bool isCloudReady;

  @override
  State<SellerDashboardPage> createState() => _SellerDashboardPageState();
}

class _SellerDashboardPageState extends State<SellerDashboardPage> {
  final SellerMenuController _menuController = SellerMenuController.instance;
  List<String> _notes = <String>[];
  SellerVerificationData _verificationData = SellerVerificationRepository.fallback;

  @override
  void initState() {
    super.initState();
    _menuController.addListener(_reloadNotes);
    SellerVerificationRepository.updates.addListener(_reloadVerification);
    _reloadNotes();
    _reloadVerification();
  }

  @override
  void dispose() {
    _menuController.removeListener(_reloadNotes);
    SellerVerificationRepository.updates.removeListener(_reloadVerification);
    super.dispose();
  }

  Future<void> _reloadNotes() async {
    await SellerNotesRepository.ensureLoaded();
    if (!mounted) {
      return;
    }
    setState(() {
      _notes = SellerNotesRepository.notesForVendor(_menuController.activeVendorId);
    });
  }

  Future<void> _reloadVerification() async {
    await SellerVerificationRepository.ensureLoaded();
    if (!mounted) {
      return;
    }
    setState(() {
      _verificationData = SellerVerificationRepository.current();
    });
  }

  Future<void> _openNoteEditor({int? index}) async {
    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) => _SellerNoteDialog(
        initialText: index == null ? '' : _notes[index],
        isEditing: index != null,
      ),
    );
    if (value == null || value.isEmpty) {
      return;
    }
    final List<String> updated = List<String>.from(_notes);
    if (index == null) {
      updated.add(value);
    } else {
      updated[index] = value;
    }
    await SellerNotesRepository.saveNotes(_menuController.activeVendorId, updated);
    await _reloadNotes();
  }

  Future<void> _removeNote(int index) async {
    final List<String> updated = List<String>.from(_notes)..removeAt(index);
    await SellerNotesRepository.saveNotes(_menuController.activeVendorId, updated);
    await _reloadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final List<Vendor> ownedVendors = _menuController.ownedVendors(sampleVendors);
    final Vendor activeVendor = ownedVendors.firstWhere(
      (Vendor vendor) => vendor.id == _menuController.activeVendorId,
      orElse: () => ownedVendors.first,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Dashboard Pemilik',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            TextButton.icon(
              onPressed: widget.onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
            ),
          ],
        ),
        if (kShowInternalStatusBanners) ...<Widget>[
          const SizedBox(height: 18),
          DemoModeBanner(
            title: widget.isCloudReady ? 'Seller Cloud Aktif' : 'Seller Demo Aktif',
            message: widget.statusMessage,
          ),
        ],
        const SizedBox(height: 18),
        if (!_verificationData.hasSubmittedVerification) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFFCD34D)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(
                  Icons.verified_user_outlined,
                  color: Color(0xFF92400E),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lengkapi verifikasi pemilik agar properti siap ditayangkan.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: widget.onOpenVerification,
                  child: const Text('Verifikasi'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
        ],
        if (ownedVendors.length > 1) ...<Widget>[
          SellerPropertySwitcherCard(
            activeVendor: activeVendor,
            ownedVendors: ownedVendors,
            title: 'Pilih properti yang ingin dikelola',
            subtitle:
                'Akun ${activeVendor.brandName} bisa berpindah antar lokasi tanpa membuat akun baru.',
            onChanged: (String? value) async {
              if (value == null) {
                return;
              }
              await _menuController.setActiveVendor(value);
            },
          ),
          const SizedBox(height: 18),
        ],
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF0F172A), Color(0xFF1E293B)],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                activeVendor.brandName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${activeVendor.name} • ${activeVendor.locationLabel}',
                style: const TextStyle(
                  color: Color(0xFFE2E8F0),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  _SellerInfoChip(
                    label: activeVendor.isOpen ? 'Buka' : 'Tutup',
                    icon: activeVendor.isOpen
                        ? Icons.check_circle_rounded
                        : Icons.pause_circle_rounded,
                  ),
                  _SellerInfoChip(
                    label: activeVendor.areaGroup,
                    icon: Icons.place_rounded,
                  ),
                  _SellerInfoChip(
                    label: '${ownedVendors.length} properti',
                    icon: Icons.apartment_rounded,
                  ),
                  _SellerInfoChip(
                    label: activeVendor.minimumOrderLabel,
                    icon: Icons.payments_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SellerStatsRow(onOpenMenu: widget.onOpenMenu),
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Catatan penjual',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              onPressed: () => _openNoteEditor(),
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Tambah catatan',
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_notes.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorder),
            ),
            child: Text(
              'Belum ada catatan. Tekan tombol + untuk menambahkan note penjual.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ...List<Widget>.generate(
          _notes.length,
          (int index) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: SellerTaskCard(
              text: _notes[index],
              onEdit: () => _openNoteEditor(index: index),
              onDelete: () => _removeNote(index),
            ),
          ),
        ),
      ],
    );
  }
}

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({
    super.key,
    required this.onLogout,
    required this.statusMessage,
    required this.isCloudReady,
  });

  final VoidCallback onLogout;
  final String statusMessage;
  final bool isCloudReady;

  @override
  Widget build(BuildContext context) {
    final int vendorCount = sampleVendors.length;
    final int openVendors = sampleVendors.where((Vendor vendor) => vendor.isOpen).length;
    final int closedVendors = vendorCount - openVendors;
    final int totalMenu = sampleVendors.fold<int>(
      0,
      (int total, Vendor vendor) =>
          total +
          vendor.packages.length +
          vendor.foods.length +
          vendor.drinks.length +
          vendor.others.length,
    );
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                'Dashboard Admin',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            TextButton.icon(
              onPressed: onLogout,
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Keluar'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Pantau properti dan kamar dari satu panel admin.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (kShowInternalStatusBanners) ...<Widget>[
          const SizedBox(height: 18),
          DemoModeBanner(
            title: isCloudReady ? 'Admin Cloud Aktif' : 'Admin Demo Aktif',
            message: statusMessage,
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(
              child: SellerStatCard(
                label: 'Vendor buka',
                value: '$openVendors',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SellerStatCard(label: 'Vendor tutup', value: '$closedVendors'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: SellerStatCard(label: 'Kamar & fasilitas tercatat', value: '$totalMenu'),
            ),
          ],
        ),
      ],
    );
  }
}

class AdminVendorPage extends StatelessWidget {
  const AdminVendorPage({
    super.key,
    required this.statusMessage,
    required this.isCloudReady,
  });

  final String statusMessage;
  final bool isCloudReady;

  @override
  Widget build(BuildContext context) {
    final int openCount = sampleVendors.where((Vendor vendor) => vendor.isOpen).length;
    final int closedCount = sampleVendors.length - openCount;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        Text('Properti Terdaftar', style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          'Ringkasan properti yang tampil ke pencari kos dan pemilik.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        if (kShowInternalStatusBanners) ...<Widget>[
          const SizedBox(height: 18),
          DemoModeBanner(
            title: isCloudReady ? 'Sinkron Vendor Aktif' : 'Vendor Demo Tersedia',
            message: statusMessage,
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: <Widget>[
            Expanded(child: SellerStatCard(label: 'Toko buka', value: '$openCount')),
            const SizedBox(width: 10),
            Expanded(child: SellerStatCard(label: 'Toko tutup', value: '$closedCount')),
          ],
        ),
        const SizedBox(height: 18),
        ...sampleVendors.map(
          (Vendor vendor) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          vendor.name,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: vendor.isOpen
                              ? const Color(0xFFE8F7EE)
                              : const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          vendor.isOpen ? 'Buka' : 'Tutup',
                          style: TextStyle(
                            color: vendor.isOpen
                                ? const Color(0xFF15803D)
                                : const Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendor.locationLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vendor.serviceAreaSummary,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${vendor.packages.length + vendor.foods.length + vendor.drinks.length + vendor.others.length} menu tercatat',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class SellerStatsRow extends StatelessWidget {
  const SellerStatsRow({super.key, required this.onOpenMenu});

  final VoidCallback onOpenMenu;

  @override
  Widget build(BuildContext context) {
    final SellerMenuController controller = SellerMenuController.instance;
    final Vendor activeVendor = sampleVendors.firstWhere(
      (Vendor vendor) => vendor.id == controller.activeVendorId,
      orElse: () => sampleVendors.first,
    );
    final int baseMenuCount = activeVendor.packages.length +
        activeVendor.foods.length +
        activeVendor.drinks.length +
        activeVendor.others.length;
    final int customMenuCount = controller.entriesForVendor(controller.activeVendorId).length;
    return Row(
      children: <Widget>[
        Expanded(
          child: SellerStatCard(
            label: 'Menu aktif',
            value: '${baseMenuCount + customMenuCount}',
            onTap: onOpenMenu,
          ),
        ),
      ],
    );
  }
}

class SellerStatCard extends StatelessWidget {
  const SellerStatCard({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D4ED8),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _SellerInfoChip extends StatelessWidget {
  const _SellerInfoChip({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0x14FFFFFF),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0x26FFFFFF)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}


class SellerTaskCard extends StatelessWidget {
  const SellerTaskCard({
    super.key,
    required this.text,
    this.onEdit,
    this.onDelete,
  });

  final String text;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Color(0xFF1D4ED8),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyLarge),
          ),
          if (onEdit != null)
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined, size: 18),
            ),
          if (onDelete != null)
            IconButton(
              onPressed: onDelete,
              icon: const Icon(Icons.remove_circle_outline_rounded, size: 18),
            ),
        ],
      ),
    );
  }
}

class _SellerNoteDialog extends StatefulWidget {
  const _SellerNoteDialog({
    required this.initialText,
    required this.isEditing,
  });

  final String initialText;
  final bool isEditing;

  @override
  State<_SellerNoteDialog> createState() => _SellerNoteDialogState();
}

class _SellerNoteDialogState extends State<_SellerNoteDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initialText,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.isEditing ? 'Edit catatan' : 'Tambah catatan'),
      content: TextField(
        controller: _controller,
        maxLines: 4,
        decoration: const InputDecoration(
          hintText: 'Tulis catatan penting untuk operasional toko',
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text.trim()),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

