# Askia Kost Recommendation Backend

Backend rekomendasi kos berbasis **Content-Based Filtering** (TF-IDF atas
kolom fasilitas) + **Cosine Similarity**, dibangun dengan FastAPI.

## Setup

1. Buat virtual environment (opsional tapi disarankan):

   ```bash
   python -m venv venv
   venv\Scripts\activate
   ```

2. Install dependencies:

   ```bash
   pip install -r requirements.txt
   ```

3. Taruh dataset CSV di `backend/data/kos_dataset.csv` dengan kolom:

   ```
   id, nama_kos, kota, kecamatan, harga, jenis_kos, wifi, ac,
   kipas, kasur, lemari, meja, kamar_mandi_dalam, parkir_motor,
   parkir_mobil, dapur, cctv, keamanan, dekat_transportasi
   ```

   Kolom fasilitas (wifi, ac, kipas, dst.) boleh berisi `0/1`, `ya/tidak`,
   atau `true/false` — akan dinormalisasi otomatis jadi biner.

## Menjalankan server

```bash
uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Server berjalan di `http://localhost:8000`. Dokumentasi interaktif
tersedia di `http://localhost:8000/docs`.

## Endpoint

### `GET /health`

Cek status server.

### `POST /recommendations`

Request body:

```json
{
  "kota": "Depok",
  "kecamatan": "Beji",
  "budget_min": 500000,
  "budget_max": 1500000,
  "jenis_kos": "Putri",
  "fasilitas": ["wifi", "ac", "kamar_mandi_dalam"]
}
```

- `kota` (wajib) — nama kota, dicocokkan case-insensitive.
- `kecamatan` (opsional) — filter kecamatan (mis. "Beji"/"Cimanggis"/"Tapos"/
  "Pancoran Mas"/"Sukmajaya" untuk dataset Depok saat ini), case-insensitive.
- `budget_min`, `budget_max` (wajib) — rentang harga sewa.
- `jenis_kos` (opsional) — filter tipe kos (mis. "Putra"/"Putri"/"Campur").
- `fasilitas` (opsional) — daftar fasilitas yang diinginkan, dari:
  `wifi, ac, kipas, kasur, lemari, meja, kamar_mandi_dalam, parkir_motor,
  parkir_mobil, dapur, cctv, keamanan, dekat_transportasi`.

Alur algoritma:

1. **Filter** dataset berdasarkan `kota` + `kecamatan` (kalau diisi) + rentang `harga` + `jenis_kos`.
2. **TF-IDF** dihitung atas kolom fasilitas dari hasil filter (tiap kos
   direpresentasikan sebagai dokumen berisi token fasilitas yang
   dimilikinya).
3. **Cosine Similarity** dihitung antara vektor preferensi user (dari
   `fasilitas` yang diminta) dan vektor TF-IDF tiap kos hasil filter.
4. Mengembalikan **top 5** kos dengan similarity tertinggi.

Response:

```json
{
  "count": 5,
  "results": [
    {
      "rank": 1,
      "kosId": "K001",
      "namaKos": "Kos Melati Asri",
      "lokasi": "Lowokwaru, Malang",
      "kota": "Malang",
      "hargaSewa": 850000,
      "mataUang": "IDR",
      "tipeKos": "Putri",
      "fasilitas": ["WiFi", "AC", "Kamar Mandi Dalam"],
      "cosineSimilarity": 0.8942,
      "reasons": [
        "Cocok dengan fasilitas: WiFi, AC, Kamar Mandi Dalam",
        "Tipe kos sesuai: Putri",
        "Harga Rp850.000 sesuai rentang anggaran"
      ]
    }
  ]
}
```

Jika tidak ada kos yang cocok dengan filter, response berisi
`{"count": 0, "results": []}`.
