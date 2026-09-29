"""Membuat dataset kos fiktif tetapi realistis untuk penelitian skripsi.

Jalankan file ini setiap kali ingin membuat ulang dataset:
    python generate_dataset.py
"""

# Library bawaan Python untuk memilih data secara acak dan mengatur lokasi file.
import random
from pathlib import Path

# Pandas digunakan untuk menyimpan kumpulan data ke CSV dan Excel.
import pandas as pd


# Seed membuat hasil acak tetap sama agar penelitian mudah direplikasi.
RANDOM_SEED = 42

# Jumlah data yang akan dibuat sesuai kebutuhan project.
JUMLAH_DATA = 5000

# Lokasi folder project dan folder output dataset.
BASE_DIR = Path(__file__).resolve().parent
DATASET_DIR = BASE_DIR / "dataset"

# Konfigurasi kota di Pulau Jawa.
# Nilai "jumlah" dibuat tidak sama agar distribusinya lebih realistis.
# Catatan: "provinsi" hanya metadata internal untuk pengelompokan kota di file
# ini, tidak ikut ditulis sebagai kolom dataset (lihat buat_satu_data).
KONFIGURASI_KOTA = [
    {
        "provinsi": "DKI Jakarta",
        "kota": "Jakarta",
        "kecamatan": ["Kebayoran Baru", "Tebet", "Setiabudi", "Kembangan", "Pasar Minggu"],
        "harga_min": 1_500_000,
        "harga_max": 4_000_000,
        "jumlah": 900,
        "peluang_ac": 0.68,
        "peluang_transportasi": 0.85,
    },
    {
        "provinsi": "Jawa Barat",
        "kota": "Depok",
        "kecamatan": ["Beji", "Pancoran Mas", "Sukmajaya", "Cimanggis", "Sawangan"],
        "harga_min": 700_000,
        "harga_max": 2_500_000,
        "jumlah": 560,
        "peluang_ac": 0.52,
        "peluang_transportasi": 0.70,
    },
    {
        "provinsi": "Jawa Barat",
        "kota": "Bekasi",
        "kecamatan": ["Bekasi Selatan", "Bekasi Timur", "Jatiasih", "Pondok Gede", "Rawalumbu"],
        "harga_min": 700_000,
        "harga_max": 2_500_000,
        "jumlah": 430,
        "peluang_ac": 0.54,
        "peluang_transportasi": 0.68,
    },
    {
        "provinsi": "Jawa Barat",
        "kota": "Bogor",
        "kecamatan": ["Bogor Tengah", "Bogor Utara", "Tanah Sareal", "Dramaga", "Cibinong"],
        "harga_min": 600_000,
        "harga_max": 2_000_000,
        "jumlah": 330,
        "peluang_ac": 0.42,
        "peluang_transportasi": 0.55,
    },
    {
        "provinsi": "Jawa Barat",
        "kota": "Bandung",
        "kecamatan": ["Coblong", "Sukajadi", "Lengkong", "Cicendo", "Buahbatu"],
        "harga_min": 700_000,
        "harga_max": 2_500_000,
        "jumlah": 600,
        "peluang_ac": 0.48,
        "peluang_transportasi": 0.68,
    },
    {
        "provinsi": "DI Yogyakarta",
        "kota": "Yogyakarta",
        "kecamatan": ["Depok", "Mlati", "Gondokusuman", "Umbulharjo", "Kasihan"],
        "harga_min": 500_000,
        "harga_max": 1_800_000,
        "jumlah": 640,
        "peluang_ac": 0.42,
        "peluang_transportasi": 0.58,
    },
    {
        "provinsi": "Jawa Tengah",
        "kota": "Semarang",
        "kecamatan": ["Tembalang", "Banyumanik", "Candisari", "Pedurungan", "Gajahmungkur"],
        "harga_min": 600_000,
        "harga_max": 2_000_000,
        "jumlah": 330,
        "peluang_ac": 0.47,
        "peluang_transportasi": 0.62,
    },
    {
        "provinsi": "Jawa Timur",
        "kota": "Surabaya",
        "kecamatan": ["Sukolilo", "Wonokromo", "Rungkut", "Tegalsari", "Mulyorejo"],
        "harga_min": 700_000,
        "harga_max": 2_500_000,
        "jumlah": 480,
        "peluang_ac": 0.60,
        "peluang_transportasi": 0.73,
    },
    {
        "provinsi": "Jawa Timur",
        "kota": "Malang",
        "kecamatan": ["Lowokwaru", "Klojen", "Blimbing", "Sukun", "Kedungkandang"],
        "harga_min": 500_000,
        "harga_max": 1_800_000,
        "jumlah": 420,
        "peluang_ac": 0.40,
        "peluang_transportasi": 0.55,
    },
    {
        "provinsi": "Jawa Tengah",
        "kota": "Solo",
        "kecamatan": ["Jebres", "Banjarsari", "Laweyan", "Serengan", "Pasar Kliwon"],
        "harga_min": 500_000,
        "harga_max": 1_500_000,
        "jumlah": 310,
        "peluang_ac": 0.35,
        "peluang_transportasi": 0.50,
    },
]

# Pilihan nama dasar agar nama kos terdengar lebih alami.
NAMA_KOS = [
    "Mawar", "Melati", "Sakura", "Harmoni", "Kenanga", "Anggrek",
    "Wijaya", "Amanah", "Cendana", "Puspa", "Permata", "Nusantara",
]


def pilih_ya_tidak(peluang_ya):
    """Mengubah probabilitas menjadi nilai fasilitas Ya atau Tidak."""
    return "Ya" if random.random() < peluang_ya else "Tidak"


def buat_harga(config_kota):
    """Membuat harga bulanan dengan kelipatan Rp50.000 di rentang kota."""
    harga_min = config_kota["harga_min"] // 50_000
    harga_max = config_kota["harga_max"] // 50_000
    return random.randint(harga_min, harga_max) * 50_000


def buat_satu_data(id_kos, config_kota):
    """Membuat satu baris data kos berdasarkan konfigurasi sebuah kota."""
    # Fasilitas penting dibuat dengan peluang yang mendekati kondisi kos pada umumnya.
    fasilitas = {
        "wifi": pilih_ya_tidak(0.91),
        "ac": pilih_ya_tidak(config_kota["peluang_ac"]),
        "kipas": pilih_ya_tidak(0.48),
        "kasur": "Ya",  # Kasur selalu tersedia sesuai kebutuhan project.
        "lemari": pilih_ya_tidak(0.94),
        "meja": pilih_ya_tidak(0.72),
        "kamar_mandi_dalam": pilih_ya_tidak(0.63),
        "parkir_motor": pilih_ya_tidak(0.92),
        "parkir_mobil": pilih_ya_tidak(0.24),
        "dapur": pilih_ya_tidak(0.50),
        "cctv": pilih_ya_tidak(0.46),
        "keamanan": pilih_ya_tidak(0.72),
        "dekat_transportasi": pilih_ya_tidak(config_kota["peluang_transportasi"]),
    }

    # Data umum dan fasilitas digabung menjadi satu dictionary/baris dataset.
    return {
        "id": id_kos,
        "nama_kos": f"Kos {random.choice(NAMA_KOS)} {config_kota['kota']} {id_kos:04d}",
        "kota": config_kota["kota"],
        "kecamatan": random.choice(config_kota["kecamatan"]),
        "harga": buat_harga(config_kota),
        "jenis_kos": random.choices(["Putra", "Putri", "Campur"], weights=[35, 40, 25])[0],
        **fasilitas,
    }


def buat_dataset():
    """Membuat tepat 5.000 data dengan jumlah data per kota yang telah ditentukan."""
    semua_data = []
    id_kos = 1

    # Setiap kota mengisi data sesuai jumlahnya agar distribusi kota tetap terkontrol.
    for config_kota in KONFIGURASI_KOTA:
        for _ in range(config_kota["jumlah"]):
            semua_data.append(buat_satu_data(id_kos, config_kota))
            id_kos += 1

    # Pemeriksaan sederhana untuk mencegah perubahan konfigurasi menghasilkan jumlah yang salah.
    if len(semua_data) != JUMLAH_DATA:
        raise ValueError("Jumlah konfigurasi kota harus sama dengan JUMLAH_DATA.")

    return pd.DataFrame(semua_data)


def simpan_dataset(dataframe):
    """Menyimpan dataframe yang sama menjadi CSV dan Excel."""
    DATASET_DIR.mkdir(exist_ok=True)

    file_csv = DATASET_DIR / "dataset_kos.csv"
    file_excel = DATASET_DIR / "dataset_kos.xlsx"

    # utf-8-sig membuat karakter Indonesia lebih aman saat dibuka di Microsoft Excel.
    dataframe.to_csv(file_csv, index=False, encoding="utf-8-sig")

    # openpyxl digunakan oleh Pandas untuk menulis file Excel .xlsx.
    dataframe.to_excel(file_excel, index=False, engine="openpyxl")

    print(f"Dataset CSV berhasil dibuat: {file_csv}")
    print(f"Dataset Excel berhasil dibuat: {file_excel}")
    print(f"Total data: {len(dataframe)} kos")


def main():
    """Menjalankan seluruh proses pembuatan dataset."""
    random.seed(RANDOM_SEED)
    dataset_kos = buat_dataset()
    simpan_dataset(dataset_kos)


# Kondisi ini membuat main() hanya berjalan saat file dipanggil langsung.
if __name__ == "__main__":
    main()
