import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/seller_verification_repository.dart';
import '../../theme/app_theme.dart';

class SellerVerificationPage extends StatefulWidget {
  const SellerVerificationPage({super.key});

  @override
  State<SellerVerificationPage> createState() => _SellerVerificationPageState();
}

class _SellerVerificationPageState extends State<SellerVerificationPage> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _businessAddressController =
      TextEditingController();
  final TextEditingController _bankAccountNameController =
      TextEditingController();
  final TextEditingController _bankAccountNumberController =
      TextEditingController();
  final TextEditingController _nikController = TextEditingController();
  bool _isSaving = false;
  String _ktpImagePath = '';
  SellerVerificationData _profile = SellerVerificationRepository.fallback;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _storeNameController.dispose();
    _businessAddressController.dispose();
    _bankAccountNameController.dispose();
    _bankAccountNumberController.dispose();
    _nikController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await SellerVerificationRepository.ensureLoaded();
    final SellerVerificationData profile = SellerVerificationRepository.current();
    if (!mounted) {
      return;
    }
    setState(() {
      _profile = profile;
      _ktpImagePath = profile.ktpImagePath;
      _storeNameController.text = profile.storeName;
      _businessAddressController.text = profile.businessAddress;
      _bankAccountNameController.text = profile.bankAccountName;
      _bankAccountNumberController.text = profile.bankAccountNumber;
      _nikController.text = profile.nik;
    });
  }

  Future<void> _pickKtpImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null || !mounted) {
      return;
    }
    setState(() {
      _ktpImagePath = image.path;
    });
  }

  Future<void> _submit() async {
    if (_storeNameController.text.trim().isEmpty ||
        _businessAddressController.text.trim().isEmpty ||
        _bankAccountNameController.text.trim().isEmpty ||
        _bankAccountNumberController.text.trim().isEmpty ||
        _nikController.text.trim().isEmpty ||
        _ktpImagePath.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi data verifikasi dulu ya.'),
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });
    await SellerVerificationRepository.saveVerification(
      _profile.copyWith(
        storeName: _storeNameController.text.trim(),
        businessAddress: _businessAddressController.text.trim(),
        bankAccountName: _bankAccountNameController.text.trim(),
        bankAccountNumber: _bankAccountNumberController.text.trim(),
        nik: _nikController.text.trim(),
        ktpImagePath: _ktpImagePath.trim(),
      ),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _isSaving = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Data verifikasi tersimpan. Properti bisa lanjut dilengkapi sebelum mulai ditayangkan.',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        title: const Text('Verifikasi Pemilik Kos'),
        backgroundColor: kBackground,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Text(
                'Lengkapi verifikasi agar properti bisa benar-benar dipakai mulai ditayangkan. Informasi ini tidak ditampilkan ke pencari kos.',
                style: TextStyle(
                  color: Color(0xFF92400E),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 18),
            _VerificationField(
              label: 'Nama pemilik',
              value: _profile.ownerName,
            ),
            const SizedBox(height: 12),
            _VerificationField(
              label: 'Email akun',
              value: _profile.ownerEmail,
            ),
            const SizedBox(height: 12),
            _VerificationField(
              label: 'Nomor WhatsApp',
              value: _profile.ownerPhone,
            ),
            const SizedBox(height: 18),
            TextField(
              controller: _storeNameController,
              decoration: const InputDecoration(
                labelText: 'Nama brand kos / usaha',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _businessAddressController,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Alamat usaha',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nikController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'NIK KTP',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bankAccountNameController,
              decoration: const InputDecoration(
                labelText: 'Nama pemilik rekening',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _bankAccountNumberController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nomor rekening',
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Foto KTP',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickKtpImage,
              borderRadius: BorderRadius.circular(22),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kBorder),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: kPrimarySoft,
                        borderRadius: BorderRadius.circular(18),
                        image: _ktpImagePath.isEmpty
                            ? null
                            : DecorationImage(
                                image: FileImage(File(_ktpImagePath)),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: _ktpImagePath.isEmpty
                          ? const Icon(
                              Icons.badge_rounded,
                              color: kPrimaryDark,
                              size: 34,
                            )
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        _ktpImagePath.isEmpty
                            ? 'Upload foto KTP'
                            : 'Foto KTP siap dipakai',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _isSaving ? null : _submit,
              icon: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.verified_user_rounded),
              label: Text(
                _isSaving ? 'Menyimpan...' : 'Simpan verifikasi penjual',
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
  }
}

class _VerificationField extends StatelessWidget {
  const _VerificationField({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
