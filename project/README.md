# Sistem Rekomendasi Kos dengan Content-Based Filtering

Project Python sederhana untuk skripsi sistem rekomendasi kos. Project ini membuat 5.000 data kos fiktif tetapi realistis di Pulau Jawa, kemudian memberikan rekomendasi berdasarkan kota, budget, jenis kos, dan fasilitas yang diinginkan pengguna.

Metode yang digunakan adalah **Content-Based Filtering** dengan **TF-IDF** dan **Cosine Similarity**. Struktur kode dibuat sederhana agar mudah dijelaskan saat sidang dan mudah dipindahkan ke aplikasi Flutter pada tahap berikutnya.

## Struktur Project

```text
project/
├── generate_dataset.py       # Membuat data kos CSV dan Excel
├── recommendation.py         # Program rekomendasi interaktif
├── requirements.txt          # Daftar library Python
├── README.md                 # Panduan penggunaan project
└── dataset/
    ├── dataset_kos.csv       # Dataset untuk program rekomendasi
    └── dataset_kos.xlsx      # Dataset yang mudah dibuka di Excel
```

## Instalasi

Pastikan Python versi 3.10 atau lebih baru sudah terpasang. Dari terminal, masuk ke folder `project`, lalu jalankan:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

Jika PowerShell menolak aktivasi virtual environment, jalankan perintah berikut sekali saja di PowerShell biasa:

```powershell
Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
```

## Cara Menjalankan

1. Buat dataset terlebih dahulu. Perintah ini membuat tepat 5.000 data dan menyimpannya menjadi CSV dan Excel.

```powershell
python generate_dataset.py
```

2. Jalankan sistem rekomendasi.

```powershell
python recommendation.py
```

3. Masukkan kota, budget maksimum, jenis kos, dan nomor fasilitas yang diinginkan. Contoh input fasilitas `1,2,8` berarti Wifi, AC, dan Parkir Motor.

## Struktur Dataset

Dataset hanya berisi kota di Pulau Jawa: Jakarta, Depok, Bekasi, Bogor, Bandung, Yogyakarta, Semarang, Surabaya, Malang, dan Solo. Jumlah kos setiap kota dibuat berbeda agar mendekati kondisi nyata; Jakarta, Yogyakarta, Bandung, dan Surabaya memiliki data lebih banyak daripada kota yang lebih kecil.

| Kelompok | Kolom |
| --- | --- |
| Identitas dan lokasi | `id`, `nama_kos`, `kota`, `kecamatan` |
| Informasi utama | `harga`, `jenis_kos` |
| Fasilitas | `wifi`, `ac`, `kipas`, `kasur`, `lemari`, `meja`, `kamar_mandi_dalam`, `parkir_motor`, `parkir_mobil`, `dapur`, `cctv`, `keamanan`, `dekat_transportasi` |

Kolom fasilitas berisi `Ya` atau `Tidak`. Harga adalah harga sewa per bulan dalam Rupiah.

## Cara Kerja Sistem

1. Program membaca `dataset/dataset_kos.csv`.
2. Program menerima kota, budget maksimal, jenis kos, dan fasilitas yang diinginkan pengguna.
3. Dataset difilter berdasarkan kota, harga yang tidak melebihi budget, serta jenis kos.
4. Untuk setiap kos hasil filter, seluruh fasilitas bernilai `Ya` digabung menjadi teks, misalnya `wifi ac kasur lemari parkir_motor cctv`.
5. Preferensi user juga digabung menjadi teks, misalnya `wifi ac parkir_motor kamar_mandi_dalam`.
6. TF-IDF mengubah kedua teks tersebut menjadi vektor angka.
7. Cosine Similarity menghitung kemiripan antara preferensi user dan setiap kos.
8. Kos diurutkan dari skor terbesar ke terkecil, lalu lima kos teratas ditampilkan.

## Mengapa Dilakukan Filtering Terlebih Dahulu?

Filtering dilakukan sebelum menghitung similarity supaya hasil rekomendasi tidak menampilkan kos yang pasti tidak sesuai, misalnya berada di kota lain, melebihi budget, atau jenis kosnya berbeda. Selain membuat hasil lebih relevan, jumlah data yang dibandingkan juga lebih sedikit sehingga proses menjadi lebih efisien.

## Mengapa Menggunakan TF-IDF?

TF-IDF (*Term Frequency-Inverse Document Frequency*) mengubah kata fasilitas menjadi angka yang dapat diproses oleh algoritma. Dalam project ini, kata seperti `wifi`, `ac`, atau `laundry` adalah fitur dari sebuah kos. Metode ini mudah dijelaskan, umum dipakai pada sistem rekomendasi berbasis konten, dan tidak memerlukan riwayat penilaian dari banyak pengguna.

## Penjelasan Cosine Similarity

Cosine Similarity mengukur kemiripan arah dua vektor. Nilainya berada pada rentang 0 sampai 1 untuk data non-negatif pada project ini:

- Nilai mendekati **1**: fasilitas kos sangat mirip dengan fasilitas yang dipilih user.
- Nilai mendekati **0**: sedikit atau tidak ada fasilitas yang sama.

Karena yang dibandingkan adalah arah vektor, metode ini cocok untuk membandingkan kumpulan fitur fasilitas tanpa terlalu dipengaruhi banyaknya fasilitas tambahan yang dimiliki sebuah kos.

## Pengembangan ke Flutter

Kode dipisahkan menjadi tiga bagian sederhana: data (`dataset_kos.csv`), input/filter, dan perhitungan rekomendasi. Saat diintegrasikan ke Flutter, dataset dapat disimpan di database atau API, input dapat berasal dari form Flutter, dan fungsi filtering serta perhitungan similarity dapat dipindahkan bertahap ke backend atau ditulis ulang dalam Dart dengan alur yang sama.
