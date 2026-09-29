import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/app_models.dart';
import '../../state/app_session_controller.dart';
import '../../theme/app_theme.dart';

class RoleLoginPage extends StatelessWidget {
  const RoleLoginPage({
    super.key,
    required this.sessionController,
    this.onClose,
    this.preferredMode,
  });

  final AppSessionController sessionController;
  final VoidCallback? onClose;
  final AppMode? preferredMode;

  Future<void> _openAuthFlow(BuildContext context, AppMode mode) async {
    final bool? success = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => _RoleAuthFormPage(
          sessionController: sessionController,
          mode: mode,
        ),
      ),
    );
    if (success == true && context.mounted) {
      onClose?.call();
    }
  }

  void _openSupportSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      builder: (BuildContext context) {
        return const _CustomerSupportSheet();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool preferSeller = preferredMode == AppMode.seller;
    return AnimatedBuilder(
      animation: sessionController,
      builder: (BuildContext context, _) {
        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: <Widget>[
                if (onClose != null) ...<Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: onClose,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Kembali',
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: kPrimarySoft,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.apartment_rounded,
                    color: kPrimaryDark,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Masuk ke Askia Kos',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: kPrimaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Saya ingin masuk sebagai',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 26),
                _ModeEntryButton(
                  label: 'Pembeli',
                  isBusy: sessionController.isBusy,
                  isPrimary: !preferSeller,
                  onTap: () => _openAuthFlow(context, AppMode.buyer),
                ),
                const SizedBox(height: 14),
                _ModeEntryButton(
                  label: 'Penjual',
                  isBusy: sessionController.isBusy,
                  isPrimary: preferSeller,
                  onTap: () => _openAuthFlow(context, AppMode.seller),
                ),
                const SizedBox(height: 26),
                Center(
                  child: TextButton(
                    onPressed: () => _openSupportSheet(context),
                    child: const Text('Butuh bantuan? Klik di sini'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RoleAuthFormPage extends StatefulWidget {
  const _RoleAuthFormPage({
    required this.sessionController,
    required this.mode,
  });

  final AppSessionController sessionController;
  final AppMode mode;

  @override
  State<_RoleAuthFormPage> createState() => _RoleAuthFormPageState();
}

class _RoleAuthFormPageState extends State<_RoleAuthFormPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isRegister = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Isi email dan password dulu ya.')),
      );
      return;
    }
    if (_isRegister &&
        (_nameController.text.trim().isEmpty || _phoneController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lengkapi nama dan nomor HP dulu ya.')),
      );
      return;
    }

    if (_isRegister) {
      await widget.sessionController.registerAccount(
        mode: widget.mode,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } else {
      await widget.sessionController.loginAs(
        mode: widget.mode,
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    }
    if (!mounted) {
      return;
    }
    final String? syncError = widget.sessionController.lastProfileSyncError;
    if (syncError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(syncError), duration: const Duration(seconds: 6)),
      );
    }
    if (widget.sessionController.isAuthenticated) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isSeller = widget.mode == AppMode.seller;
    return AnimatedBuilder(
      animation: widget.sessionController,
      builder: (BuildContext context, _) {
        return Scaffold(
          backgroundColor: kBackground,
          appBar: AppBar(
            backgroundColor: kBackground,
            title: Text(isSeller ? 'Akun Penjual' : 'Akun Pembeli'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: <Widget>[
                Text(
                  isSeller
                      ? 'Kelola akun pemilik kos dan siapkan properti kamu.'
                      : 'Masuk atau buat akun pencari kos untuk mulai cari hunian.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: kBorder),
                  ),
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _AuthModeButton(
                          label: 'Masuk',
                          isSelected: !_isRegister,
                          onTap: () {
                            setState(() {
                              _isRegister = false;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _AuthModeButton(
                          label: 'Daftar',
                          isSelected: _isRegister,
                          onTap: () {
                            setState(() {
                              _isRegister = true;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (_isRegister) ...<Widget>[
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: isSeller ? 'Nama pemilik akun' : 'Nama lengkap',
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP / WhatsApp',
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
                if (_isRegister && isSeller) ...<Widget>[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: const Text(
                      'Verifikasi pemilik dan upload KTP dilakukan setelah akun berhasil dibuat. Informasi ini hanya muncul di dashboard penjual, tidak ditampilkan ke pencari kos.',
                      style: TextStyle(
                        color: Color(0xFF92400E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                if (widget.sessionController.authStatus.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kBorder),
                    ),
                    child: Text(widget.sessionController.authStatus),
                  ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: widget.sessionController.isBusy ? null : _submit,
                  icon: widget.sessionController.isBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          _isRegister
                              ? Icons.person_add_alt_1_rounded
                              : Icons.login_rounded,
                        ),
                  label: Text(
                    _isRegister
                        ? (isSeller ? 'Daftar akun penjual' : 'Daftar akun pembeli')
                        : (isSeller ? 'Masuk sebagai penjual' : 'Masuk sebagai pembeli'),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    minimumSize: const Size.fromHeight(54),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AuthModeButton extends StatelessWidget {
  const _AuthModeButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Ink(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? kPrimary : Colors.white,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isSelected ? Colors.white : kText,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}

class _ModeEntryButton extends StatelessWidget {
  const _ModeEntryButton({
    required this.label,
    required this.isBusy,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final bool isBusy;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy ? null : onTap,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: isPrimary ? kPrimary : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: isPrimary ? kPrimary : kBorder),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 24,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: isPrimary ? Colors.white : kText,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
              if (isBusy)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: isPrimary ? Colors.white : kPrimary,
                  ),
                )
              else
                Icon(
                  Icons.chevron_right_rounded,
                  color: isPrimary ? Colors.white : kText,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerSupportSheet extends StatelessWidget {
  const _CustomerSupportSheet();

  Future<void> _copy(BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label disalin. Tinggal paste untuk menghubungi CS.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Customer Service Askia Kos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Untuk kebutuhan skripsi dan pengujian aplikasi, pola terbaik adalah bantuan di dalam aplikasi plus kontak WhatsApp sebagai jalur cepat.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 18),
            _SupportCard(
              title: 'Pusat bantuan di aplikasi',
              subtitle:
                  'Baca panduan singkat login, pencarian kos, booking, dan alur pemilik kos.',
              icon: Icons.support_agent_rounded,
              actionLabel: 'Lihat panduan',
              onTap: () {
                showDialog<void>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Panduan Singkat'),
                      content: const Text(
                        'Pencari kos bisa lihat properti dan peta dulu. Saat ingin chat, favorit, atau booking, sistem akan meminta login. Pemilik kos masuk dari menu ini lalu mengelola properti, booking, dan melengkapi verifikasi.',
                      ),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Tutup'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 12),
            _SupportCard(
              title: 'WhatsApp Customer Service',
              subtitle: 'Kontak cepat untuk bantuan akun, booking, atau kendala aplikasi.',
              icon: Icons.phone_in_talk_rounded,
              actionLabel: 'Salin nomor',
              onTap: () => _copy(context, '0812-3456-7890', 'Nomor WhatsApp CS'),
            ),
            const SizedBox(height: 12),
            _SupportCard(
              title: 'Email support',
              subtitle: 'Alternatif resmi untuk kebutuhan bantuan administrasi.',
              icon: Icons.mail_outline_rounded,
              actionLabel: 'Salin email',
              onTap: () => _copy(context, 'support@askiakost.app', 'Email support'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
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
                const SizedBox(height: 10),
                TextButton(
                  onPressed: onTap,
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
