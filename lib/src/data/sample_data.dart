import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/app_models.dart';

final List<Vendor> sampleVendors = <Vendor>[
  Vendor(
    id: 'vendor-1',
    brandId: 'brand-askia',
    brandName: 'Askia Kos',
    name: 'Askia Kos Sawangan',
    locationLabel: 'Depok, Sawangan',
    rating: 4.9,
    reviewCount: 320,
    chatHint: 'Chat untuk tanya kamar, survey, atau ketersediaan unit',
    description:
        'Kos modern campur dekat akses Bojongsari dengan kamar AC, parkir luas, dan area bersama yang rapi.',
    areaGroup: 'Sawangan',
    addressDetail: 'Jl. Raya Sawangan No. 15, Depok, dekat pertigaan Bojongsari.',
    position: const LatLng(-6.3976, 106.7586),
    gallery: const <StoreMedia>[
      StoreMedia(
        title: 'Kamar Standard AC',
        subtitle: 'Pilihan kamar favorit untuk pekerja dan mahasiswa',
        color: Color(0xFFD7F3E2),
        icon: Icons.bed_rounded,
      ),
      StoreMedia(
        title: 'Area Parkir',
        subtitle: 'Parkir motor luas dan aman',
        color: Color(0xFFE7F4FD),
        icon: Icons.local_parking_rounded,
      ),
      StoreMedia(
        title: 'Dapur Bersama',
        subtitle: 'Fasilitas masak ringan untuk penghuni',
        color: Color(0xFFFFE8D6),
        icon: Icons.kitchen_rounded,
      ),
    ],
    packages: <MenuItemData>[
      MenuItemData(
        name: 'Kamar Standard AC',
        price: 1400000,
        description: 'Kamar nyaman untuk 1 orang dengan kamar mandi dalam.',
        components: <String>[
          'Kasur',
          'Lemari',
          'Meja belajar',
          'AC',
          'Kamar mandi dalam',
        ],
      ),
      MenuItemData(
        name: 'Kamar Deluxe AC',
        price: 1800000,
        description: 'Ukuran lebih lega dengan jendela besar dan air panas.',
        components: <String>[
          'Kasur queen',
          'Lemari besar',
          'Meja belajar',
          'AC',
          'Water heater',
        ],
      ),
    ],
    foods: <MenuItemData>[
      MenuItemData(
        name: 'Wi-Fi',
        price: 0,
        description: 'Internet bersama untuk penghuni.',
      ),
      MenuItemData(
        name: 'Listrik',
        price: 0,
        description: 'Sudah termasuk listrik bulanan.',
      ),
    ],
    drinks: <MenuItemData>[
      MenuItemData(
        name: 'Laundry',
        price: 150000,
        description: 'Opsional per bulan.',
      ),
      MenuItemData(
        name: 'Cleaning kamar',
        price: 100000,
        description: 'Opsional mingguan.',
      ),
    ],
    others: <MenuItemData>[
      MenuItemData(
        name: 'Deposit kunci',
        price: 200000,
        description: 'Dibayar sekali saat check-in.',
      ),
    ],
    minimumOrderLabel: 'Mulai Rp1,4 jt/bulan',
    serviceAreaSummary: 'Sawangan, Bojongsari, dan sekitarnya',
  ),
  Vendor(
    id: 'vendor-2',
    brandId: 'brand-farhan',
    brandName: 'Farhan Kos',
    name: 'Farhan Kos Margonda',
    locationLabel: 'Depok, Margonda',
    rating: 4.8,
    reviewCount: 218,
    chatHint: 'Chat untuk tanya kamar putra, harga, atau jadwal survey',
    description:
        'Kos putra dekat kampus dan halte dengan suasana tenang, cocok untuk mahasiswa dan karyawan.',
    areaGroup: 'Margonda',
    addressDetail: 'Jl. Margonda Raya No. 88, dekat area kampus dan stasiun.',
    position: const LatLng(-6.3727, 106.8329),
    gallery: const <StoreMedia>[
      StoreMedia(
        title: 'Kamar Furnished',
        subtitle: 'Kamar siap huni dekat kampus',
        color: Color(0xFFFFF1CC),
        icon: Icons.weekend_rounded,
      ),
      StoreMedia(
        title: 'Ruang Santai',
        subtitle: 'Area bersama untuk belajar dan istirahat',
        color: Color(0xFFE4E7FF),
        icon: Icons.chair_alt_rounded,
      ),
    ],
    packages: <MenuItemData>[
      MenuItemData(
        name: 'Kamar Putra AC',
        price: 1650000,
        description: 'Kamar 1 orang dengan furnitur lengkap.',
        components: <String>[
          'Kasur',
          'Lemari',
          'Meja',
          'AC',
          'Kamar mandi luar',
        ],
      ),
    ],
    foods: <MenuItemData>[
      MenuItemData(
        name: 'Wi-Fi',
        price: 0,
        description: 'Internet penghuni tanpa biaya tambahan.',
      ),
      MenuItemData(
        name: 'Dapur bersama',
        price: 0,
        description: 'Dapur ringan dan dispenser bersama.',
      ),
    ],
    drinks: <MenuItemData>[
      MenuItemData(
        name: 'Parkir motor',
        price: 0,
        description: 'Sudah termasuk sewa bulanan.',
      ),
    ],
    others: <MenuItemData>[
      MenuItemData(
        name: 'Biaya kebersihan',
        price: 75000,
        description: 'Biaya bulanan untuk area bersama.',
      ),
    ],
    minimumOrderLabel: 'Mulai Rp1,65 jt/bulan',
    serviceAreaSummary: 'Margonda, Beji, dan area kampus',
  ),
  Vendor(
    id: 'vendor-3',
    brandId: 'brand-rafly',
    brandName: 'Rafly Kos',
    name: 'Rafly Kos Kukusan',
    locationLabel: 'Depok, Kukusan',
    rating: 4.7,
    reviewCount: 180,
    chatHint: 'Chat untuk tanya kamar putri dan jadwal lihat unit',
    description:
        'Kos putri dengan akses mudah ke kampus, lingkungan tenang, dan peraturan rumah yang jelas.',
    areaGroup: 'Kukusan',
    addressDetail: 'Jl. Kukusan Teknik No. 21, Depok, dekat area Universitas Indonesia.',
    position: const LatLng(-6.3620, 106.8243),
    gallery: const <StoreMedia>[
      StoreMedia(
        title: 'Kamar Putri',
        subtitle: 'Kamar bersih dan terang',
        color: Color(0xFFEAFBF1),
        icon: Icons.king_bed_rounded,
      ),
      StoreMedia(
        title: 'Teras & Akses',
        subtitle: 'Akses masuk rapi dan aman',
        color: Color(0xFFE7F4FD),
        icon: Icons.home_rounded,
      ),
    ],
    packages: <MenuItemData>[
      MenuItemData(
        name: 'Kamar Putri Standar',
        price: 1250000,
        description: 'Pilihan hemat dekat kampus.',
        components: <String>[
          'Kasur',
          'Lemari',
          'Kipas angin',
          'Kamar mandi luar',
        ],
      ),
      MenuItemData(
        name: 'Kamar Putri AC',
        price: 1550000,
        description: 'Pilihan lebih nyaman dengan AC.',
        components: <String>[
          'Kasur',
          'Lemari',
          'AC',
          'Meja belajar',
          'Kamar mandi luar',
        ],
      ),
    ],
    foods: <MenuItemData>[
      MenuItemData(
        name: 'Wi-Fi',
        price: 0,
        description: 'Internet penghuni.',
      ),
      MenuItemData(
        name: 'CCTV',
        price: 0,
        description: 'Area depan dan lorong utama.',
      ),
    ],
    drinks: <MenuItemData>[
      MenuItemData(
        name: 'Parkir motor',
        price: 50000,
        description: 'Tambahan per bulan jika dibutuhkan.',
      ),
    ],
    others: <MenuItemData>[
      MenuItemData(
        name: 'Deposit',
        price: 250000,
        description: 'Dibayar sekali saat awal sewa.',
      ),
    ],
    minimumOrderLabel: 'Mulai Rp1,25 jt/bulan',
    serviceAreaSummary: 'Kukusan, Beji, dan sekitar UI',
  ),
  Vendor(
    id: 'vendor-4',
    brandId: 'brand-askia',
    brandName: 'Askia Kos',
    name: 'Askia Kos Tebet',
    locationLabel: 'Jakarta, Tebet',
    rating: 4.8,
    reviewCount: 264,
    chatHint: 'Chat untuk tanya unit yang dekat stasiun atau akses kantor',
    description:
        'Kos modern di Tebet untuk pekerja dengan akses cepat ke stasiun dan area perkantoran.',
    areaGroup: 'Tebet',
    addressDetail: 'Jl. Tebet Timur Dalam IX No. 12, Jakarta Selatan.',
    position: const LatLng(-6.2264, 106.8549),
    gallery: const <StoreMedia>[
      StoreMedia(
        title: 'Kamar Executive',
        subtitle: 'Kamar lega untuk pekerja urban',
        color: Color(0xFFD7F3E2),
        icon: Icons.apartment_rounded,
      ),
      StoreMedia(
        title: 'Area Laundry',
        subtitle: 'Laundry dan setrika bersama',
        color: Color(0xFFE7F4FD),
        icon: Icons.local_laundry_service_rounded,
      ),
    ],
    packages: <MenuItemData>[
      MenuItemData(
        name: 'Kamar Executive AC',
        price: 2350000,
        description: 'Kamar premium dengan kamar mandi dalam.',
        components: <String>[
          'Kasur queen',
          'AC',
          'Meja kerja',
          'Kamar mandi dalam',
          'Wi-Fi',
        ],
      ),
    ],
    foods: <MenuItemData>[
      MenuItemData(
        name: 'Wi-Fi',
        price: 0,
        description: 'Sudah termasuk sewa.',
      ),
      MenuItemData(
        name: 'Akses 24 jam',
        price: 0,
        description: 'Masuk dengan akses kartu.',
      ),
    ],
    drinks: <MenuItemData>[
      MenuItemData(
        name: 'Parkir mobil',
        price: 250000,
        description: 'Opsional per bulan.',
      ),
    ],
    others: <MenuItemData>[
      MenuItemData(
        name: 'Deposit',
        price: 500000,
        description: 'Sekali di awal sewa.',
      ),
    ],
    minimumOrderLabel: 'Mulai Rp2,35 jt/bulan',
    serviceAreaSummary: 'Tebet, Manggarai, dan sekitarnya',
  ),
  Vendor(
    id: 'vendor-5',
    brandId: 'brand-askia',
    brandName: 'Askia Kos',
    name: 'Askia Kos Baranangsiang',
    locationLabel: 'Bogor, Baranangsiang',
    rating: 4.8,
    reviewCount: 211,
    chatHint: 'Chat untuk tanya ketersediaan kamar dan survey akhir pekan',
    description:
        'Kos campur di Bogor dengan suasana tenang, cocok untuk mahasiswa dan pekerja muda.',
    areaGroup: 'Baranangsiang',
    addressDetail: 'Jl. Raya Pajajaran No. 72, Bogor, dekat akses tol Baranangsiang.',
    position: const LatLng(-6.5966, 106.8060),
    gallery: const <StoreMedia>[
      StoreMedia(
        title: 'Kamar Compact',
        subtitle: 'Kamar efisien untuk hunian praktis',
        color: Color(0xFFFFF1CC),
        icon: Icons.single_bed_rounded,
      ),
      StoreMedia(
        title: 'Ruang Jemur',
        subtitle: 'Area bersama di lantai atas',
        color: Color(0xFFE4E7FF),
        icon: Icons.wb_sunny_rounded,
      ),
    ],
    packages: <MenuItemData>[
      MenuItemData(
        name: 'Kamar Compact AC',
        price: 1350000,
        description: 'Kamar ringkas dan nyaman untuk 1 penghuni.',
        components: <String>[
          'Kasur',
          'Lemari',
          'AC',
          'Kamar mandi luar',
        ],
      ),
    ],
    foods: <MenuItemData>[
      MenuItemData(
        name: 'Wi-Fi',
        price: 0,
        description: 'Internet bersama penghuni.',
      ),
    ],
    drinks: <MenuItemData>[
      MenuItemData(
        name: 'Dapur bersama',
        price: 0,
        description: 'Area masak ringan dan kulkas bersama.',
      ),
    ],
    others: <MenuItemData>[
      MenuItemData(
        name: 'Biaya kartu akses',
        price: 100000,
        description: 'Sekali di awal sewa.',
      ),
    ],
    minimumOrderLabel: 'Mulai Rp1,35 jt/bulan',
    serviceAreaSummary: 'Bogor kota dan sekitarnya',
  ),
];
