import 'package:flutter/material.dart';

import '../models/app_models.dart';
import '../theme/app_theme.dart';

class SellerPropertySwitcherCard extends StatelessWidget {
  const SellerPropertySwitcherCard({
    super.key,
    required this.activeVendor,
    required this.ownedVendors,
    required this.onChanged,
    this.title = 'Pilih properti aktif',
    this.subtitle =
        'Satu akun bisa mengelola beberapa lokasi kos dalam satu brand.',
  });

  final Vendor activeVendor;
  final List<Vendor> ownedVendors;
  final ValueChanged<String?> onChanged;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    if (ownedVendors.length <= 1) {
      return const SizedBox.shrink();
    }

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
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        activeVendor.brandName,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: kPrimaryDark,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${ownedVendors.length} properti terhubung',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    initialValue: activeVendor.id,
                    items: ownedVendors
                        .map(
                          (Vendor vendor) => DropdownMenuItem<String>(
                            value: vendor.id,
                            child: Text('${vendor.name} • ${vendor.areaGroup}'),
                          ),
                        )
                        .toList(),
                    onChanged: onChanged,
                    decoration: const InputDecoration(
                      labelText: 'Properti aktif',
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
