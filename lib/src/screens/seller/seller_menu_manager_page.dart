import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/sample_data.dart';
import '../../data/vendor_location_repository.dart';
import '../../data/vendor_media_repository.dart';
import '../../data/vendor_profile_repository.dart';
import '../../models/app_models.dart';
import '../../state/seller_menu_controller.dart';
import '../../theme/app_theme.dart';
import '../../widgets/seller_property_switcher_card.dart';

class SellerMenuManagerPage extends StatefulWidget {
  const SellerMenuManagerPage({super.key});

  @override
  State<SellerMenuManagerPage> createState() => _SellerMenuManagerPageState();
}

class _SellerMenuManagerPageState extends State<SellerMenuManagerPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _itemsController = TextEditingController();
  final TextEditingController _locationLabelController = TextEditingController();
  final TextEditingController _storeNameController = TextEditingController();
  final TextEditingController _storeDescriptionController =
      TextEditingController();
  final TextEditingController _contactController = TextEditingController();
  final TextEditingController _minimumOrderController = TextEditingController();
  final TextEditingController _serviceAreaController = TextEditingController();
  final TextEditingController _addressDetailController = TextEditingController();
  final SellerMenuController _controller = SellerMenuController.instance;
  final ImagePicker _imagePicker = ImagePicker();
  SellerEntryType _type = SellerEntryType.paket;
  String _category = 'Paket';
  String _selectedArea = 'Sawangan';
  bool _isLoading = true;
  bool _isStoreOpen = true;
  String? _editingEntryId;
  List<StoreMedia> _gallery = <StoreMedia>[];
  LatLng? _pickedPosition;

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    await _controller.ensureLoaded();
    await VendorLocationRepository.ensureLoaded();
    await VendorProfileRepository.ensureLoaded();
    _gallery = await VendorMediaRepository.galleryForVendor(
      _controller.activeVendorId,
      sampleVendors
          .firstWhere(
            (Vendor vendor) => vendor.id == _controller.activeVendorId,
            orElse: () => sampleVendors.first,
          )
          .gallery,
    );
    _loadLocationForActiveVendor();
    _loadProfileForActiveVendor();
    if (!mounted) {
      return;
    }
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _switchActiveVendor(String vendorId) async {
    await _controller.setActiveVendor(vendorId);
    await _loadGalleryForActiveVendor();
    _loadLocationForActiveVendor();
    _loadProfileForActiveVendor();
    _resetForm();
    if (!mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _itemsController.dispose();
    _locationLabelController.dispose();
    _storeNameController.dispose();
    _storeDescriptionController.dispose();
    _contactController.dispose();
    _minimumOrderController.dispose();
    _serviceAreaController.dispose();
    _addressDetailController.dispose();
    super.dispose();
  }

  Future<void> _addEntry() async {
    final String name = _nameController.text.trim();
    final int? price = int.tryParse(_priceController.text.trim());
    final List<String> items =
        _itemsController.text
            .split(',')
            .map((String item) => item.trim())
            .where((String item) => item.isNotEmpty)
            .toList();

    if (name.isEmpty || price == null || items.isEmpty) {
      return;
    }

    if (_editingEntryId == null) {
      await _controller.addEntry(
        vendorId: _controller.activeVendorId,
        name: name,
        price: price,
        category: _category,
        type: _type,
        items: items,
      );
    } else {
      await _controller.updateEntry(
        id: _editingEntryId!,
        vendorId: _controller.activeVendorId,
        name: name,
        price: price,
        category: _category,
        type: _type,
        items: items,
      );
    }
    _resetForm();
  }

  void _startEditing(SellerMenuEntry entry) {
    setState(() {
      _editingEntryId = entry.id;
      _nameController.text = entry.name;
      _priceController.text = entry.price.toString();
      _itemsController.text = entry.items.join(', ');
      _type = entry.type;
      _category = entry.category;
    });
  }

  void _resetForm() {
    setState(() {
      _editingEntryId = null;
      _type = SellerEntryType.paket;
      _category = 'Paket';
      _nameController.clear();
      _priceController.clear();
      _itemsController.clear();
    });
  }

  Future<void> _loadGalleryForActiveVendor() async {
    final Vendor fallbackVendor = sampleVendors.firstWhere(
      (Vendor vendor) => vendor.id == _controller.activeVendorId,
      orElse: () => sampleVendors.first,
    );
    final List<StoreMedia> gallery = await VendorMediaRepository.galleryForVendor(
      _controller.activeVendorId,
      fallbackVendor.gallery,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _gallery = gallery;
    });
  }

  void _loadLocationForActiveVendor() {
    final Vendor fallbackVendor = sampleVendors.firstWhere(
      (Vendor vendor) => vendor.id == _controller.activeVendorId,
      orElse: () => sampleVendors.first,
    );
    final VendorLocationOverride? override = VendorLocationRepository.localOverride(
      _controller.activeVendorId,
    );
    _pickedPosition = override?.position ?? fallbackVendor.position;
    _selectedArea = override?.areaGroup ?? fallbackVendor.areaGroup;
    _locationLabelController.text =
        override?.locationLabel ?? fallbackVendor.locationLabel;
  }

  void _loadProfileForActiveVendor() {
    final Vendor fallbackVendor = sampleVendors.firstWhere(
      (Vendor vendor) => vendor.id == _controller.activeVendorId,
      orElse: () => sampleVendors.first,
    );
    final VendorProfileOverride? override = VendorProfileRepository.localOverride(
      _controller.activeVendorId,
    );
    _storeNameController.text =
        override?.name.isNotEmpty == true ? override!.name : fallbackVendor.name;
    _storeDescriptionController.text =
        override?.description.isNotEmpty == true
            ? override!.description
            : fallbackVendor.description;
    _contactController.text =
        override?.contactLabel.isNotEmpty == true
            ? override!.contactLabel
            : fallbackVendor.contactLabel;
    _minimumOrderController.text =
        override?.minimumOrderLabel.isNotEmpty == true
            ? override!.minimumOrderLabel
            : fallbackVendor.minimumOrderLabel;
    _serviceAreaController.text =
        override?.serviceAreaSummary.isNotEmpty == true
            ? override!.serviceAreaSummary
            : fallbackVendor.serviceAreaSummary;
    _addressDetailController.text =
        override?.addressDetail.isNotEmpty == true
            ? override!.addressDetail
            : fallbackVendor.addressDetail;
    _isStoreOpen = override?.isOpen ?? fallbackVendor.isOpen;
  }

  Future<void> _pickGalleryImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 82,
    );
    if (image == null) {
      return;
    }
    if (!mounted) {
      return;
    }
    final bool? shouldSave = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return _SellerPickedImagePreviewSheet(
          imagePath: image.path,
          willBecomeCover: _gallery.isEmpty,
        );
      },
    );
    if (shouldSave != true) {
      return;
    }
    await VendorMediaRepository.addMedia(
      vendorId: _controller.activeVendorId,
      media: StoreMedia(
        title: _gallery.isEmpty ? 'Foto cover properti' : 'Foto properti & kamar',
        subtitle: _gallery.isEmpty
            ? 'Foto pertama akan jadi cover properti'
            : 'Dokumentasi properti atau kamar terbaru',
        color: const Color(0xFFD7F3E2),
        icon: Icons.image_rounded,
        imagePath: image.path,
      ),
    );
    await _loadGalleryForActiveVendor();
  }

  Future<void> _removeMedia(int index) async {
    await VendorMediaRepository.removeMedia(
      vendorId: _controller.activeVendorId,
      index: index,
    );
    await _loadGalleryForActiveVendor();
  }

  Future<void> _setCover(int index) async {
    await VendorMediaRepository.setCover(
      vendorId: _controller.activeVendorId,
      index: index,
    );
    await _loadGalleryForActiveVendor();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Foto cover properti berhasil diperbarui.'),
      ),
    );
  }

  Future<void> _moveMedia(int fromIndex, int toIndex) async {
    await VendorMediaRepository.moveMedia(
      vendorId: _controller.activeVendorId,
      fromIndex: fromIndex,
      toIndex: toIndex,
    );
    await _loadGalleryForActiveVendor();
  }

  Future<void> _editMedia(int index) async {
    final StoreMedia media = _gallery[index];
    final _SellerMediaEditResult? result =
        await showDialog<_SellerMediaEditResult>(
      context: context,
      builder: (BuildContext context) => _SellerMediaEditDialog(
        initialTitle: media.title,
        initialSubtitle: media.subtitle,
      ),
    );
    if (result == null) {
      return;
    }
    await VendorMediaRepository.updateMedia(
      vendorId: _controller.activeVendorId,
      index: index,
      title: result.title,
      subtitle: result.subtitle,
    );
    await _loadGalleryForActiveVendor();
  }

  Future<void> _saveLocation() async {
    if (_pickedPosition == null) {
      return;
    }
    await VendorLocationRepository.saveOverride(
      vendorId: _controller.activeVendorId,
      value: VendorLocationOverride(
        locationLabel: _locationLabelController.text.trim().isEmpty
            ? 'Depok, $_selectedArea'
            : _locationLabelController.text.trim(),
        areaGroup: _selectedArea,
        position: _pickedPosition!,
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Lokasi properti berhasil disimpan untuk peta pencari kos.'),
      ),
    );
    setState(() {});
  }

  Future<void> _saveProfile() async {
    final Vendor fallbackVendor = sampleVendors.firstWhere(
      (Vendor vendor) => vendor.id == _controller.activeVendorId,
      orElse: () => sampleVendors.first,
    );
    await VendorProfileRepository.saveOverride(
      vendorId: _controller.activeVendorId,
      value: VendorProfileOverride(
        name: _storeNameController.text.trim().isEmpty
            ? fallbackVendor.name
            : _storeNameController.text.trim(),
        description: _storeDescriptionController.text.trim().isEmpty
            ? fallbackVendor.description
            : _storeDescriptionController.text.trim(),
        contactLabel: _contactController.text.trim().isEmpty
            ? fallbackVendor.contactLabel
            : _contactController.text.trim(),
        minimumOrderLabel: _minimumOrderController.text.trim().isEmpty
            ? fallbackVendor.minimumOrderLabel
            : _minimumOrderController.text.trim(),
        serviceAreaSummary: _serviceAreaController.text.trim().isEmpty
            ? fallbackVendor.serviceAreaSummary
            : _serviceAreaController.text.trim(),
        addressDetail: _addressDetailController.text.trim().isEmpty
            ? fallbackVendor.addressDetail
            : _addressDetailController.text.trim(),
        isOpen: _isStoreOpen,
      ),
    );
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profil properti berhasil disimpan untuk tampilan pencari kos.'),
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, _) {
        final List<Vendor> ownedVendors = _controller.ownedVendors(sampleVendors);
        final List<SellerMenuEntry> activeEntries = _controller.entriesForVendor(
          _controller.activeVendorId,
        );
        final Vendor activeVendor = ownedVendors.firstWhere(
          (Vendor vendor) => vendor.id == _controller.activeVendorId,
          orElse: () => ownedVendors.first,
        );
        final LatLng currentPosition = _pickedPosition ?? activeVendor.position;
        final String previewName = _storeNameController.text.trim().isEmpty
            ? activeVendor.name
            : _storeNameController.text.trim();
        final String previewDescription =
            _storeDescriptionController.text.trim().isEmpty
                ? activeVendor.description
                : _storeDescriptionController.text.trim();
        final String previewMinimumOrder =
            _minimumOrderController.text.trim().isEmpty
                ? activeVendor.minimumOrderLabel
                : _minimumOrderController.text.trim();
        final String previewAddress =
            _addressDetailController.text.trim().isEmpty
                ? activeVendor.addressDetail
                : _addressDetailController.text.trim();
        final StoreMedia? previewBanner = _gallery.isNotEmpty ? _gallery.first : null;
        if (_isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          children: <Widget>[
            Text(
              'Kelola Properti',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            if (ownedVendors.length > 1) ...<Widget>[
              SellerPropertySwitcherCard(
                activeVendor: activeVendor,
                ownedVendors: ownedVendors,
                subtitle:
                    'Pilih lokasi kos yang ingin diatur. Setiap properti bisa punya profil, peta, dan tipe kamar sendiri.',
                onChanged: (String? value) async {
                  if (value == null) {
                    return;
                  }
                  await _switchActiveVendor(value);
                },
              ),
              const SizedBox(height: 18),
            ],
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6FAF7),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: kBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: kPrimarySoft,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(
                          Icons.storefront_rounded,
                          color: kPrimaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              activeVendor.brandName,
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${activeVendor.name} • ${activeVendor.locationLabel}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: <Widget>[
                                _SellerMiniChip(
                                  label: _isStoreOpen ? 'Buka' : 'Tutup',
                                  color: _isStoreOpen
                                      ? const Color(0xFFDFF7E7)
                                      : const Color(0xFFFEE2E2),
                                  textColor: _isStoreOpen
                                      ? const Color(0xFF166534)
                                      : const Color(0xFFB91C1C),
                                ),
                                _SellerMiniChip(
                                  label: activeVendor.minimumOrderLabel,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Profil properti',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _saveProfile,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Simpan profil'),
                        style: FilledButton.styleFrom(backgroundColor: kPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kBorder),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                _isStoreOpen
                                    ? 'Properti sedang aktif'
                                    : 'Properti sedang nonaktif',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isStoreOpen
                                    ? 'Pencari kos bisa melihat dan menghubungi properti ini.'
                                    : 'Properti tetap terlihat, tapi diberi status nonaktif.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _isStoreOpen,
                          onChanged: (bool value) {
                            setState(() {
                              _isStoreOpen = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _storeNameController,
                    decoration: const InputDecoration(labelText: 'Nama kos / properti'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _storeDescriptionController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Deskripsi properti'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _contactController,
                    decoration: const InputDecoration(
                      labelText: 'Kontak pengelola',
                      hintText: 'Contoh: 0812-3456-7890',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _minimumOrderController,
                    decoration: const InputDecoration(
                      labelText: 'Aturan sewa singkat',
                      hintText: 'Contoh: Mulai sewa 1 bulan',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serviceAreaController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Area layanan',
                      hintText: 'Contoh: Sawangan, Bojongsari, Cinangka',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _addressDetailController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Alamat lengkap properti',
                      hintText:
                          'Contoh: Jl. Raya Sawangan No. 15, dekat pertigaan Bojongsari',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Preview tampilan pencari kos',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 132,
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: previewBanner == null
                                ? const LinearGradient(
                                    colors: <Color>[
                                      Color(0xFFD7F3E2),
                                      Color(0xFFE7F4FD),
                                    ],
                                  )
                                : null,
                            color: previewBanner?.color,
                          ),
                          child: previewBanner?.imagePath != null
                              ? Image.file(
                                  File(previewBanner!.imagePath!),
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Center(
                                    child: Icon(
                                      Icons.storefront_rounded,
                                      color: kPrimaryDark,
                                      size: 40,
                                    ),
                                  ),
                                )
                              : Center(
                                  child: Icon(
                                    previewBanner?.icon ??
                                        Icons.storefront_rounded,
                                    color: kPrimaryDark,
                                    size: 40,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: kPrimarySoft,
                                borderRadius: BorderRadius.circular(18),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _storeInitials(previewName),
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(
                                      color: kPrimaryDark,
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: Text(
                                          previewName,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _isStoreOpen
                                              ? kPrimarySoft
                                              : const Color(0xFFFEE2E2),
                                          borderRadius:
                                              BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          _isStoreOpen ? 'Buka' : 'Tutup',
                                          style: TextStyle(
                                            color: _isStoreOpen
                                                ? kPrimaryDark
                                                : const Color(0xFF991B1B),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    previewDescription,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    previewMinimumOrder,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: kPrimaryDark,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    previewAddress,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Lokasi properti di peta',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _saveLocation,
                        icon: const Icon(Icons.save_rounded),
                        label: const Text('Simpan lokasi'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox(
                      height: 220,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: currentPosition,
                          zoom: 14,
                        ),
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        onTap: (LatLng point) {
                          setState(() {
                            _pickedPosition = point;
                          });
                        },
                        markers: <Marker>{
                          Marker(
                            markerId: MarkerId(_controller.activeVendorId),
                            position: currentPosition,
                          ),
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _locationLabelController,
                    decoration: const InputDecoration(
                      labelText: 'Label lokasi properti',
                      hintText: 'Contoh: Depok, Sawangan',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedArea,
                    items: sampleVendors
                        .map((Vendor vendor) => vendor.areaGroup)
                        .toSet()
                        .map(
                          (String area) => DropdownMenuItem<String>(
                            value: area,
                            child: Text(area),
                          ),
                        )
                        .toList(),
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _selectedArea = value;
                      });
                    },
                    decoration: const InputDecoration(
                      labelText: 'Area properti',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: kBorder),
                    ),
                    child: Text(
                      'Lat: ${currentPosition.latitude.toStringAsFixed(5)} • Lng: ${currentPosition.longitude.toStringAsFixed(5)}',
                      style: Theme.of(context).textTheme.bodyMedium,
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
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: Text(
                          'Foto properti & kamar',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      FilledButton.icon(
                        onPressed: _pickGalleryImage,
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        label: const Text('Upload'),
                        style: FilledButton.styleFrom(
                          backgroundColor: kPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Atur cover dan urutan foto dengan lebih fleksibel. Foto cover akan tampil di preview penjual dan halaman pencari kos.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 14),
                  if (_gallery.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: kBorder),
                      ),
                      child: Text(
                        'Belum ada foto. Upload foto properti atau kamar supaya tampilan pencari kos lebih hidup.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  if (_gallery.isNotEmpty)
                  SizedBox(
                    height: 212,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _gallery.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (BuildContext context, int index) {
                        final StoreMedia media = _gallery[index];
                        return Container(
                          width: 214,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: media.imagePath != null
                                      ? Image.file(
                                          File(media.imagePath!),
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: media.color,
                                            alignment: Alignment.center,
                                            child: Icon(
                                              media.icon,
                                              color: kPrimaryDark,
                                              size: 34,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: media.color,
                                          ),
                                          alignment: Alignment.center,
                                          child: Icon(
                                            media.icon,
                                            color: kPrimaryDark,
                                            size: 34,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: <Widget>[
                                        Text(
                                          media.title,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          media.subtitle,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: Theme.of(context).textTheme.bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (index == 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: kPrimarySoft,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        'Cover',
                                        style: TextStyle(
                                          color: kPrimaryDark,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 2,
                                runSpacing: 2,
                                alignment: WrapAlignment.start,
                                children: <Widget>[
                                  if (index != 0)
                                    TextButton(
                                      onPressed: () => _setCover(index),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Jadikan cover'),
                                    ),
                                  IconButton(
                                    onPressed: () => _editMedia(index),
                                    tooltip: 'Edit teks foto',
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 18,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: index > 0
                                        ? () => _moveMedia(index, index - 1)
                                        : null,
                                    tooltip: 'Geser ke kiri',
                                    icon: const Icon(
                                      Icons.chevron_left_rounded,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: index < _gallery.length - 1
                                        ? () => _moveMedia(index, index + 1)
                                        : null,
                                    tooltip: 'Geser ke kanan',
                                    icon: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 20,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => _removeMedia(index),
                                    tooltip: 'Hapus foto',
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 18,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
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
                    _editingEntryId == null
                        ? 'Tambah tipe kamar baru'
                        : 'Edit tipe kamar',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama kamar / item',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Harga'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<SellerEntryType>(
                    initialValue: _type,
                    items: const <DropdownMenuItem<SellerEntryType>>[
                      DropdownMenuItem(
                        value: SellerEntryType.paket,
                        child: Text('Tipe kamar'),
                      ),
                      DropdownMenuItem(
                        value: SellerEntryType.item,
                        child: Text('Item terpisah'),
                      ),
                    ],
                    onChanged: (SellerEntryType? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _type = value;
                        if (value == SellerEntryType.paket) {
                          _category = 'Tipe kamar';
                        }
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Tipe'),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                        value: 'Tipe kamar',
                        child: Text('Tipe kamar'),
                      ),
                      DropdownMenuItem(
                        value: 'Fasilitas kamar',
                        child: Text('Fasilitas kamar'),
                      ),
                      DropdownMenuItem(
                        value: 'Fasilitas bersama',
                        child: Text('Fasilitas bersama'),
                      ),
                      DropdownMenuItem(
                        value: 'Biaya lain',
                        child: Text('Biaya lain'),
                      ),
                    ],
                    onChanged: (String? value) {
                      if (value == null) {
                        return;
                      }
                      setState(() {
                        _category = value;
                      });
                    },
                    decoration: const InputDecoration(labelText: 'Kategori'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _itemsController,
                    minLines: 2,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Isi item (pisahkan dengan koma)',
                      hintText: 'Contoh: Kasur, Lemari, AC, Meja belajar',
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _addEntry,
                    icon: Icon(
                      _editingEntryId == null
                          ? Icons.add_rounded
                          : Icons.save_rounded,
                    ),
                    label: Text(
                      _editingEntryId == null ? 'Tambah ke daftar' : 'Simpan perubahan',
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D4ED8),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 18,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  if (_editingEntryId != null) ...<Widget>[
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.close_rounded),
                      label: const Text('Batal edit'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Daftar kamar & item properti',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            if (activeEntries.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kBorder),
                ),
                child: Text(
                  'Belum ada data kamar untuk properti ini. Tambah tipe kamar atau item dulu ya.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ...activeEntries.map(
              (SellerMenuEntry entry) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SellerMenuEntryCard(
                  entry: entry,
                  onEdit: () => _startEditing(entry),
                  onDelete: () => _controller.deleteEntry(entry.id),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _storeInitials(String value) {
    final List<String> parts = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((String part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'AC';
    }
    if (parts.length == 1) {
      return parts.first.characters.take(2).toString().toUpperCase();
    }
    return '${parts.first.characters.first}${parts[1].characters.first}'
        .toUpperCase();
  }
}

class _SellerMiniChip extends StatelessWidget {
  const _SellerMiniChip({
    required this.label,
    this.color = const Color(0xFFF1F5F9),
    this.textColor = kText,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _SellerPickedImagePreviewSheet extends StatelessWidget {
  const _SellerPickedImagePreviewSheet({
    required this.imagePath,
    required this.willBecomeCover,
  });

  final String imagePath;
  final bool willBecomeCover;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Preview foto',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            willBecomeCover
                ? 'Foto ini akan jadi cover properti pertamamu.'
                : 'Cek dulu hasilnya sebelum ditambahkan ke galeri properti.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: Image.file(
                File(imagePath),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Batal'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: FilledButton.styleFrom(backgroundColor: kPrimary),
                  child: const Text('Gunakan foto ini'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SellerMediaEditResult {
  const _SellerMediaEditResult({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;
}

class _SellerMediaEditDialog extends StatefulWidget {
  const _SellerMediaEditDialog({
    required this.initialTitle,
    required this.initialSubtitle,
  });

  final String initialTitle;
  final String initialSubtitle;

  @override
  State<_SellerMediaEditDialog> createState() => _SellerMediaEditDialogState();
}

class _SellerMediaEditDialogState extends State<_SellerMediaEditDialog> {
  late final TextEditingController _titleController = TextEditingController(
    text: widget.initialTitle,
  );
  late final TextEditingController _subtitleController = TextEditingController(
    text: widget.initialSubtitle,
  );

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit teks foto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Judul foto'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _subtitleController,
            minLines: 2,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Keterangan singkat'),
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _SellerMediaEditResult(
                title: _titleController.text.trim().isEmpty
                    ? 'Foto properti'
                    : _titleController.text.trim(),
                subtitle: _subtitleController.text.trim().isEmpty
                    ? 'Dokumentasi properti atau kamar'
                    : _subtitleController.text.trim(),
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class SellerMenuEntryCard extends StatelessWidget {
  const SellerMenuEntryCard({
    super.key,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  final SellerMenuEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
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
                  entry.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Text(
                _formatRupiah(entry.price),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: const Color(0xFF1D4ED8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              _LabelPill(
                label: entry.type == SellerEntryType.paket ? 'Tipe kamar' : 'Item',
                color: const Color(0xFFE8EEFF),
                textColor: const Color(0xFF1D4ED8),
              ),
              const SizedBox(width: 8),
              _LabelPill(
                label: entry.category,
                color: kPrimarySoft,
                textColor: kPrimaryDark,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children:
                entry.items
                    .map(
                      (String item) => Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          item,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    )
                    .toList(),
          ),
        ],
      ),
    );
  }
}

class _LabelPill extends StatelessWidget {
  const _LabelPill({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

String _formatRupiah(int value) {
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
