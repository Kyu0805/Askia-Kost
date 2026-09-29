import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_visibility_flags.dart';
import '../../data/buyer_profile_repository.dart';
import '../../data/kos_recommendation_repository.dart';
import '../../theme/app_theme.dart';

class BuyerShell extends StatefulWidget {
  const BuyerShell({
    super.key,
    required this.onSwitchMode,
    required this.onLogout,
    required this.statusMessage,
    required this.isCloudReady,
  });

  final VoidCallback onSwitchMode;
  final VoidCallback onLogout;
  final String statusMessage;
  final bool isCloudReady;

  @override
  State<BuyerShell> createState() => _BuyerShellState();
}

class _BuyerShellState extends State<BuyerShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final List<Widget> tabs = <Widget>[
      const BuyerHomePage(),
      BuyerProfilePage(
        onSwitchMode: widget.onSwitchMode,
        onLogout: widget.onLogout,
        statusMessage: widget.statusMessage,
        isCloudReady: widget.isCloudReady,
      ),
    ];

    return Scaffold(
      body: SafeArea(child: IndexedStack(index: _index, children: tabs)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        backgroundColor: Colors.white,
        indicatorColor: kPrimarySoft,
        onDestinationSelected: (int value) {
          setState(() {
            _index = value;
          });
        },
        destinations: const <NavigationDestination>[
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            label: 'Beranda',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}

class BuyerHomePage extends StatefulWidget {
  const BuyerHomePage({super.key});

  @override
  State<BuyerHomePage> createState() => _BuyerHomePageState();
}

class _BuyerHomePageState extends State<BuyerHomePage> {
  Future<List<KosRecommendation>> _recommendationsFuture =
      Future<List<KosRecommendation>>.value(const <KosRecommendation>[]);
  // Membedakan tampilan awal dengan kondisi setelah user melakukan pencarian
  // tetapi tidak menemukan kos yang sesuai.
  bool _hasSearchedRecommendations = false;

  Future<void> _openPreferenceForm() async {
    final KosSearchPreferences? preferences =
        await showModalBottomSheet<KosSearchPreferences>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          builder: (BuildContext context) => const _PreferenceFormSheet(),
        );
    if (preferences == null || !mounted) {
      return;
    }
    setState(() {
      _hasSearchedRecommendations = true;
      _recommendationsFuture = _searchWithFallback(preferences);
    });
  }

  Future<List<KosRecommendation>> _searchWithFallback(
    KosSearchPreferences preferences,
  ) async {
    try {
      final List<KosRecommendation> results =
          await KosRecommendationRepository.searchRecommendations(preferences);
      if (mounted) {
        if (results.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Rekomendasi ditemukan sesuai preferensimu.'),
            ),
          );
        }
      }
      return results;
    } on KosRecommendationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
      return KosRecommendationRepository.demoRecommendations;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 28),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: <Widget>[
              const AppLogo(size: 42),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'askia kos',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kPrimaryDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Cari kos jadi lebih mudah',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: _openPreferenceForm,
            child: Ink(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: <Color>[kPrimary, kPrimaryDark],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0x26FFFFFF),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.tune_rounded, color: Colors.white),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Cari Rekomendasi Sesuai Preferensimu',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Isi kota, budget, tipe kos, dan fasilitas favoritmu.',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFFE2E8F0),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        FutureBuilder<List<KosRecommendation>>(
          future: _recommendationsFuture,
          builder: (
            BuildContext context,
            AsyncSnapshot<List<KosRecommendation>> snapshot,
          ) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final List<KosRecommendation> recommendations =
                snapshot.data ?? const <KosRecommendation>[];
            if (recommendations.isEmpty) {
              if (_hasSearchedRecommendations) {
                return _RecommendationEmptyState(
                  onChangePreferences: _openPreferenceForm,
                );
              }
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: _RecommendationPromptCard(onTap: _openPreferenceForm),
              );
            }
            return _KosRecommendationSection(recommendations: recommendations);
          },
        ),
      ],
    );
  }
}

class _RecommendationEmptyState extends StatelessWidget {
  const _RecommendationEmptyState({required this.onChangePreferences});

  final VoidCallback onChangePreferences;

  @override
  Widget build(BuildContext context) {
    // Tinggi tetap membuat konten terlihat berada di tengah area hasil
    // rekomendasi, bukan menempel di bagian atas halaman.
    return SizedBox(
      height: 390,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 104,
                height: 104,
                decoration: const BoxDecoration(
                  color: kPrimarySoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: kPrimary,
                  size: 52,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum ada kos yang cocok',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: kPrimaryDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Coba ubah preferensi pencarianmu, seperti menaikkan budget, memilih kota lain, atau mengurangi fasilitas yang dipilih.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: kMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onChangePreferences,
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Ubah preferensi'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecommendationPromptCard extends StatelessWidget {
  const _RecommendationPromptCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: kPrimarySoft,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: kPrimary,
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Belum ada rekomendasi',
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Isi preferensimu untuk melihat rekomendasi kos yang cocok.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.tune_rounded),
            label: const Text('Isi preferensi'),
            style: FilledButton.styleFrom(
              backgroundColor: kPrimary,
              padding: const EdgeInsets.symmetric(
                vertical: 14,
                horizontal: 20,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KosRecommendationSection extends StatelessWidget {
  const _KosRecommendationSection({required this.recommendations});

  final List<KosRecommendation> recommendations;

  String _formatPrice(KosRecommendation item) {
    if (item.currency == 'IDR') {
      return '${formatRupiah(item.monthlyPrice)}/bulan';
    }
    final String amount = item.monthlyPrice.toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (_) => '.',
    );
    return '${item.currency} $amount/bulan';
  }

  String _primaryReason(KosRecommendation item) {
    if (item.reasons.isEmpty) {
      return 'Cocok dengan profil pencarianmu';
    }
    return item.reasons.first;
  }

  void _openDetail(BuildContext context, KosRecommendation item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (BuildContext context) =>
          _KosRecommendationDetailSheet(item: item, formatPrice: _formatPrice),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Rekomendasi untukmu',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendations.every(
                              (KosRecommendation item) => item.isDemo,
                            )
                            ? 'Data demo • isi preferensimu untuk hasil yang lebih sesuai'
                            : 'Diurutkan berdasarkan kecocokan dengan preferensimu',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.auto_awesome_rounded, color: kPrimary),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 224,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: recommendations.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (BuildContext context, int index) {
                final KosRecommendation item = recommendations[index];
                final int matchPercent = (item.cosineSimilarity * 100)
                    .clamp(0, 100)
                    .round();
                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _openDetail(context, item),
                  child: Ink(
                    width: 270,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: kPrimarySoft,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '#${item.rank}',
                                style: const TextStyle(
                                  color: kPrimaryDark,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F7EE),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '$matchPercent% cocok',
                                style: const TextStyle(
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          item.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _formatPrice(item),
                          style: Theme.of(
                            context,
                          ).textTheme.titleSmall?.copyWith(color: kPrimaryDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _primaryReason(item),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _KosRecommendationDetailSheet extends StatelessWidget {
  const _KosRecommendationDetailSheet({
    required this.item,
    required this.formatPrice,
  });

  final KosRecommendation item;
  final String Function(KosRecommendation item) formatPrice;

  @override
  Widget build(BuildContext context) {
    final int matchPercent = (item.cosineSimilarity * 100).clamp(0, 100).round();
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F7EE),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$matchPercent% cocok',
                      style: const TextStyle(
                        color: Color(0xFF15803D),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.location,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              Text(
                formatPrice(item),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: kPrimaryDark),
              ),
              const SizedBox(height: 4),
              Text(
                'Tipe kos: ${item.roomType}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (item.facilities.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                Text('Fasilitas', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: item.facilities
                      .map(
                        (String facility) => Chip(
                          label: Text(facility),
                          backgroundColor: const Color(0xFFF6FAF7),
                          side: BorderSide(color: kBorder),
                        ),
                      )
                      .toList(),
                ),
              ],
              if (item.reasons.isNotEmpty) ...<Widget>[
                const SizedBox(height: 18),
                Text(
                  'Kenapa direkomendasikan',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                ...item.reasons.map(
                  (String reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(
                            Icons.check_circle_rounded,
                            size: 16,
                            color: Color(0xFF15803D),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reason,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: kBorder),
                ),
                child: Text(
                  item.isDemo
                      ? 'Ini data demo. Isi form preferensi untuk mendapatkan rekomendasi dari data kos sesungguhnya.'
                      : 'Hasil dari sistem rekomendasi. Hubungi admin properti untuk info lebih lanjut atau jadwal kunjungan.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuyerProfilePage extends StatefulWidget {
  const BuyerProfilePage({
    super.key,
    required this.onSwitchMode,
    required this.onLogout,
    required this.statusMessage,
    required this.isCloudReady,
  });

  final VoidCallback onSwitchMode;
  final VoidCallback onLogout;
  final String statusMessage;
  final bool isCloudReady;

  @override
  State<BuyerProfilePage> createState() => _BuyerProfilePageState();
}

class _BuyerProfilePageState extends State<BuyerProfilePage> {
  BuyerProfileData _profile = BuyerProfileRepository.fallback;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    BuyerProfileRepository.updates.addListener(_loadProfile);
    _loadProfile();
  }

  @override
  void dispose() {
    BuyerProfileRepository.updates.removeListener(_loadProfile);
    super.dispose();
  }

  Future<void> _loadProfile() async {
    await BuyerProfileRepository.ensureLoaded();
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = BuyerProfileRepository.current();
      _isLoadingProfile = false;
    });
  }

  Future<void> _openEditProfileSheet() async {
    final BuyerProfileData? updated =
        await showModalBottomSheet<BuyerProfileData>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          builder: (BuildContext context) {
            return _BuyerProfileSheet(initialProfile: _profile);
          },
        );
    if (updated == null) {
      return;
    }
    await BuyerProfileRepository.save(updated);
  }

  Future<void> _openHelpSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return const _BuyerHelpSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      children: <Widget>[
        Text(
          'Profil Pembeli',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        if (kShowInternalStatusBanners) ...<Widget>[
          const SizedBox(height: 18),
          DemoModeBanner(
            title: widget.isCloudReady ? 'Akun Terhubung' : 'Akun Demo',
            message:
                widget.isCloudReady
                    ? widget.statusMessage
                    : 'Data profil pembeli akan tetap tersimpan meski belum login produksi penuh.',
          ),
        ],
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: kPrimarySoft,
                    child: Text(
                      _profile.name.characters.take(1).toString().toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: kPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _profile.name,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          _profile.email,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _profile.phone,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (_isLoadingProfile)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(minHeight: 3),
                ),
              FilledButton.icon(
                onPressed: _openEditProfileSheet,
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Ubah profil pembeli'),
                style: FilledButton.styleFrom(
                  backgroundColor: kPrimary,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _openHelpSheet,
                icon: const Icon(Icons.support_agent_rounded),
                label: const Text('Pusat bantuan'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout_rounded),
                label: const Text('Keluar'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 18,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Data Diri',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Alamat dan preferensi ini dipakai sebagai acuan saat mencari kos.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              _InvoiceRow(
                label: 'Alamat utama',
                value: _profile.primaryAddress,
              ),
              const SizedBox(height: 10),
              _InvoiceRow(
                label: 'Alamat cadangan',
                value:
                    _profile.secondaryAddress.isEmpty
                        ? 'Belum ditambahkan'
                        : _profile.secondaryAddress,
              ),
              const SizedBox(height: 10),
              _InvoiceRow(
                label: 'Preferensi pesanan',
                value: _profile.preferenceSummary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BuyerProfileSheet extends StatefulWidget {
  const _BuyerProfileSheet({required this.initialProfile});

  final BuyerProfileData initialProfile;

  @override
  State<_BuyerProfileSheet> createState() => _BuyerProfileSheetState();
}

class _BuyerProfileSheetState extends State<_BuyerProfileSheet> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.initialProfile.name,
  );
  late final TextEditingController _emailController = TextEditingController(
    text: widget.initialProfile.email,
  );
  late final TextEditingController _phoneController = TextEditingController(
    text: widget.initialProfile.phone,
  );
  late final TextEditingController _primaryAddressController =
      TextEditingController(text: widget.initialProfile.primaryAddress);
  late final TextEditingController _secondaryAddressController =
      TextEditingController(text: widget.initialProfile.secondaryAddress);
  late final TextEditingController _preferenceController =
      TextEditingController(text: widget.initialProfile.preferenceSummary);

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _primaryAddressController.dispose();
    _secondaryAddressController.dispose();
    _preferenceController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _primaryAddressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nama, nomor HP, dan alamat utama perlu diisi dulu ya.',
          ),
        ),
      );
      return;
    }
    Navigator.of(context).pop(
      BuyerProfileData(
        name: _nameController.text.trim(),
        email:
            _emailController.text.trim().isEmpty
                ? BuyerProfileRepository.fallback.email
                : _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        primaryAddress: _primaryAddressController.text.trim(),
        secondaryAddress: _secondaryAddressController.text.trim(),
        preferenceSummary:
            _preferenceController.text.trim().isEmpty
                ? BuyerProfileRepository.fallback.preferenceSummary
                : _preferenceController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Ubah profil pembeli',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Data ini akan dipakai untuk profil, order, dan alamat pengantaran default.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nama lengkap'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Nomor HP / WhatsApp',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _primaryAddressController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Alamat utama'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _secondaryAddressController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Alamat cadangan',
                hintText: 'Opsional, misalnya kantor atau kampus',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _preferenceController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Preferensi pesanan',
                hintText: 'Contoh: tidak terlalu pedas, lebih suka air mineral',
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Simpan profil'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerHelpSheet extends StatelessWidget {
  const _BuyerHelpSheet();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Pusat bantuan', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Kalau ada kendala pengajuan sewa atau butuh info kos, kamu bisa hubungi customer service.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          _HelpActionTile(
            icon: Icons.phone_in_talk_rounded,
            title: 'WhatsApp CS',
            subtitle: '0812-9000-ASKIA',
            onTap: () async {
              await Clipboard.setData(
                const ClipboardData(text: '0812-9000-ASKIA'),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Nomor WhatsApp CS berhasil disalin.'),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 10),
          _HelpActionTile(
            icon: Icons.mail_outline_rounded,
            title: 'Email bantuan',
            subtitle: 'cs@askiakost.app',
            onTap: () async {
              await Clipboard.setData(
                const ClipboardData(text: 'cs@askiakost.app'),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Email bantuan berhasil disalin.'),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

class _HelpActionTile extends StatelessWidget {
  const _HelpActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: kPrimarySoft,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: kPrimaryDark),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.copy_rounded, color: kMuted),
          ],
        ),
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: kPrimarySoft,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Icon(Icons.apartment_rounded, color: kPrimaryDark, size: size * 0.46),
          Positioned(
            bottom: size * 0.14,
            right: size * 0.14,
            child: Container(
              width: size * 0.22,
              height: size * 0.22,
              decoration: const BoxDecoration(
                color: kPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DemoModeBanner extends StatelessWidget {
  const DemoModeBanner({super.key, required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFFF3FBF6), Color(0xFFFFFFFF)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kPrimarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.rocket_launch_rounded, color: kPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(message, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreferenceFormSheet extends StatefulWidget {
  const _PreferenceFormSheet();

  @override
  State<_PreferenceFormSheet> createState() => _PreferenceFormSheetState();
}

class _PreferenceFormSheetState extends State<_PreferenceFormSheet> {
  final TextEditingController _budgetMinController = TextEditingController(
    text: '1500000',
  );
  final TextEditingController _budgetMaxController = TextEditingController(
    text: '3000000',
  );
  String? _jenisKos;
  String? _kecamatan;
  final Set<String> _selectedFacilities = <String>{};
  String? _errorText;

  @override
  void dispose() {
    _budgetMinController.dispose();
    _budgetMaxController.dispose();
    super.dispose();
  }

  void _submit() {
    final int? budgetMin = int.tryParse(_budgetMinController.text.trim());
    final int? budgetMax = int.tryParse(_budgetMaxController.text.trim());

    if (budgetMin == null || budgetMax == null) {
      setState(() => _errorText = 'Isi rentang budget dengan angka yang valid.');
      return;
    }
    if (budgetMin > budgetMax) {
      setState(() => _errorText = 'Budget minimum tidak boleh lebih besar dari maksimum.');
      return;
    }

    Navigator.of(context).pop(
      KosSearchPreferences(
        kecamatan: _kecamatan,
        budgetMin: budgetMin,
        budgetMax: budgetMax,
        jenisKos: _jenisKos,
        fasilitas: _selectedFacilities.toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Preferensi Pencarian Kos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 6),
            Text(
              'Rekomendasi dihitung dengan Content-Based Filtering berdasarkan lokasi, budget, tipe kos, dan fasilitas yang kamu pilih. Dataset saat ini mencakup kos di ${KosRecommendationRepository.defaultKota}.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            Text('Kecamatan', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Semua Kecamatan'),
                  selected: _kecamatan == null,
                  onSelected: (_) => setState(() => _kecamatan = null),
                ),
                ...KosRecommendationRepository.kecamatanOptions.map(
                  (String kecamatan) => ChoiceChip(
                    label: Text(kecamatan),
                    selected: _kecamatan == kecamatan,
                    onSelected: (_) => setState(() => _kecamatan = kecamatan),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _budgetMinController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(labelText: 'Budget minimum'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _budgetMaxController,
                    keyboardType: TextInputType.number,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    decoration: const InputDecoration(labelText: 'Budget maksimum'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Tipe kos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                ChoiceChip(
                  label: const Text('Semua'),
                  selected: _jenisKos == null,
                  onSelected: (_) => setState(() => _jenisKos = null),
                ),
                ...KosRecommendationRepository.roomTypeOptions.map(
                  (String type) => ChoiceChip(
                    label: Text(type),
                    selected: _jenisKos == type,
                    onSelected: (_) => setState(() => _jenisKos = type),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text('Fasilitas favorit', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: KosRecommendationRepository.facilityOptions.map((
                String facility,
              ) {
                final bool selected = _selectedFacilities.contains(facility);
                return FilterChip(
                  label: Text(
                    KosRecommendationRepository.facilityLabels[facility] ??
                        facility,
                  ),
                  selected: selected,
                  onSelected: (bool value) {
                    setState(() {
                      if (value) {
                        _selectedFacilities.add(facility);
                      } else {
                        _selectedFacilities.remove(facility);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            if (_errorText != null) ...<Widget>[
              const SizedBox(height: 12),
              Text(
                _errorText!,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: const Color(0xFFB91C1C)),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.search_rounded),
              label: const Text('Cari Rekomendasi'),
              style: FilledButton.styleFrom(
                backgroundColor: kPrimary,
                minimumSize: const Size.fromHeight(52),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }
}

String formatRupiah(int value) {
  final String raw = value.toString();
  final StringBuffer buffer = StringBuffer();
  for (int i = 0; i < raw.length; i++) {
    final int reverseIndex = raw.length - i;
    buffer.write(raw[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }
  return 'Rp$buffer';
}
