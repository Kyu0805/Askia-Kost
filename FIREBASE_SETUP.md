# Firebase Setup

Project ini sudah siap untuk:
- `firebase_core`
- `firebase_auth`
- `cloud_firestore`

Yang belum ada sekarang:
- [android/app/google-services.json](/Users/halip/AndroidStudioProjects/AskiaCatering/android/app/google-services.json)

Jadi saat ini app masih jalan di mode demo lokal. Supaya buyer, seller, chat, request custom, dan order benar-benar sinkron antar device, lakukan langkah berikut.

## 1. Buat Project Firebase

1. Buka Firebase Console.
2. Klik `Create a project`.
3. Isi nama project, misalnya `Askia Catering`.
4. Boleh matikan Google Analytics kalau belum perlu.
5. Selesaikan sampai project terbentuk.

## 2. Tambahkan App Android

1. Di halaman project Firebase, klik `Add app` lalu pilih `Android`.
2. Isi `Android package name` dengan:
   `com.example.askia_catering_flutter`
3. Nama app bebas, misalnya `Askia Catering Android`.
4. Klik lanjut sampai Firebase memberi file konfigurasi.
5. Download `google-services.json`.
6. Simpan file itu ke:
   `android/app/google-services.json`

Catatan:
- Project ini memang sudah otomatis aktifkan plugin Google Services kalau file itu ada.
- Jadi kamu tidak perlu ubah Gradle lagi untuk langkah dasar Android.

## 3. Aktifkan Authentication

Supaya login buyer/seller/admin benar-benar online:

1. Masuk ke menu `Authentication`.
2. Klik `Get started`.
3. Pilih tab `Sign-in method`.
4. Aktifkan `Email/Password`.

Project ini sekarang login lewat email/password Firebase kalau Firebase sudah aktif.

## 4. Aktifkan Firestore Database

1. Masuk ke menu `Firestore Database`.
2. Klik `Create database`.
3. Pilih mode awal `Start in test mode` kalau baru setup.
4. Pilih region terdekat yang kamu mau.

Kalau nanti mau lebih aman, deploy rules dari file:
[firestore.rules](/Users/halip/AndroidStudioProjects/AskiaCatering/firestore.rules)

## 5. Struktur Data yang Dipakai App

Project ini sekarang memakai koleksi berikut:

- `users/{uid}`
- `users/{uid}/sellerMenus/{menuId}`
- `vendors/{vendorId}`
- `vendors/{vendorId}/menus/{menuId}`
- `vendorChats/{vendorId}/messages/{messageId}`
- `customMenuRequests/{requestId}`
- `orders/{orderId}`
- `orders/{orderId}/payments/{paymentId}`

Ringkasnya:
- buyer, seller, admin tersimpan di `users`
- profil toko, lokasi, media, dan katalog publik di `vendors`
- chat per toko di `vendorChats`
- request menu custom di `customMenuRequests`
- pesanan di `orders`
- riwayat DP/pelunasan di `orders/{orderId}/payments`

## 6. Rules Demo yang Sudah Disiapkan

Saya sudah tambahkan file:
- [firestore.rules](/Users/halip/AndroidStudioProjects/AskiaCatering/firestore.rules)
- [firebase.json](/Users/halip/AndroidStudioProjects/AskiaCatering/firebase.json)

Rules ini cocok untuk tahap demo dan pengembangan, tapi belum production-grade.

Yang diizinkan:
- vendor dan menu publik bisa dibaca siapa saja
- data lain butuh user login
- `users/{uid}` hanya bisa dibaca/ditulis oleh user itu sendiri

## 7. Cara Deploy Rules

Kalau nanti kamu sudah install Firebase CLI dan login, dari folder project jalankan:

```bash
firebase deploy --only firestore:rules
```

Kalau belum mau deploy rules sekarang, sementara kamu bisa pakai `test mode` dulu untuk uji coba awal.

## 8. Jalankan App

Setelah `google-services.json` sudah ada:

```bash
flutter run
```

Kalau mau paling aman di mesin ini:

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
flutter run
```

## 9. Tanda Firebase Sudah Aktif

Kalau Firebase berhasil aktif:
- login tidak lagi cuma mode demo
- data buyer dan seller mulai sinkron antar device
- chat, request custom, order, dan status bayar akan hidup lintas device

## 10. Urutan Uji Coba yang Saya Sarankan

Setelah Firebase aktif, tes urutan ini:

1. Login buyer di device/emulator A.
2. Login seller di device/emulator B.
3. Buyer kirim request custom.
4. Seller kirim penawaran.
5. Buyer terima penawaran lalu checkout DP.
6. Seller ubah status order.
7. Buyer cek perubahan status secara online.

## 11. Kondisi Project Saat Ini

Yang sudah siap di kode:
- login Firebase
- sinkron vendor
- sinkron menu seller
- sinkron order
- sinkron chat
- sinkron request custom
- sinkron payment history

Yang masih perlu kamu isi manual:
- project Firebase di console
- file `google-services.json`
- deploy rules kalau mau lebih rapi

## 12. Catatan Penting

Rules di [firestore.rules](/Users/halip/AndroidStudioProjects/AskiaCatering/firestore.rules) sengaja dibuat mudah dulu supaya app cepat hidup saat demo. Nanti kalau aplikasi makin matang, rules-nya perlu diketatkan lagi berdasarkan:
- role user
- owner vendor
- ownership order
- akses chat per buyer/seller yang benar
