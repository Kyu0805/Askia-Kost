# Google Maps Setup

Ikuti langkah ini supaya tab peta buyer dan pemilih lokasi seller tampil penuh di Android.

## 1. Buat API key

1. Buka Google Cloud Console.
2. Pilih atau buat project.
3. Aktifkan billing untuk project itu.
4. Aktifkan `Maps SDK for Android`.
5. Buka menu `APIs & Services` -> `Credentials`.
6. Klik `Create credentials` -> `API key`.

## 2. Restrict key untuk Android

Restriksi yang dipakai app ini:

- Package name: `com.example.askia_catering_flutter`
- Tambahkan SHA-1 debug untuk emulator/device development

Contoh ambil SHA-1 debug:

```bash
keytool -list -v \
  -keystore ~/.android/debug.keystore \
  -alias androiddebugkey \
  -storepass android \
  -keypass android
```

## 3. Simpan key ke local.properties

Isi file `android/local.properties`:

```properties
MAPS_API_KEY=AIzaSyISI_KEY_ASLI_KAMU
```

## 4. Jalankan ulang app

```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
flutter run
```

## Catatan

- Kalau `MAPS_API_KEY` belum diisi, widget peta bisa blank.
- Seller location picker dan buyer map memakai key yang sama.
- Konfigurasi Android manifest sudah otomatis membaca `MAPS_API_KEY` dari `local.properties`.
