"""Sistem rekomendasi kos sederhana dengan Content-Based Filtering.

Program membandingkan fasilitas yang diinginkan pengguna dengan fasilitas
setiap kos menggunakan TF-IDF dan Cosine Similarity.
"""

# Path dipakai agar file dataset dapat ditemukan walaupun terminal dibuka dari lokasi lain.
from pathlib import Path

# NumPy digunakan untuk mengurutkan skor similarity dengan mudah.
import numpy as np

# Pandas digunakan untuk membaca dan memfilter dataset.
import pandas as pd

# TF-IDF mengubah teks fasilitas menjadi angka, sedangkan cosine_similarity menghitung kemiripan.
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity


# Lokasi file CSV yang dibuat oleh generate_dataset.py.
BASE_DIR = Path(__file__).resolve().parent
FILE_DATASET = BASE_DIR / "dataset" / "dataset_kos.csv"

# Kolom fasilitas dan nama tampilannya. Satu sumber ini menghindari penulisan berulang.
FASILITAS = {
    "wifi": "Wifi",
    "ac": "AC",
    "kipas": "Kipas",
    "kasur": "Kasur",
    "lemari": "Lemari",
    "meja": "Meja",
    "kamar_mandi_dalam": "Kamar mandi dalam",
    "parkir_motor": "Parkir motor",
    "parkir_mobil": "Parkir mobil",
    "dapur": "Dapur",
    "cctv": "CCTV",
    "keamanan": "Keamanan",
    "dekat_transportasi": "Dekat transportasi",
}


def load_dataset():
    """Membaca dataset CSV dan memberi pesan jelas bila dataset belum dibuat."""
    if not FILE_DATASET.exists():
        raise FileNotFoundError(
            "Dataset belum ditemukan. Jalankan 'python generate_dataset.py' terlebih dahulu."
        )

    return pd.read_csv(FILE_DATASET)


def format_rupiah(nilai):
    """Mengubah angka harga menjadi format Rupiah yang mudah dibaca."""
    return f"Rp{int(nilai):,}".replace(",", ".")


def input_budget():
    """Menerima budget dengan format 1500000 atau 1.500.000."""
    while True:
        teks_budget = input("Budget maksimum per bulan (contoh: 1500000): ").strip()
        angka_budget = teks_budget.replace(".", "").replace(",", "").replace(" ", "")

        if angka_budget.isdigit() and int(angka_budget) > 0:
            return int(angka_budget)

        print("Budget harus berupa angka lebih dari 0.")


def input_jenis_kos():
    """Meminta jenis kos dan memastikan nilai input sesuai dengan isi dataset."""
    pilihan = {"putra": "Putra", "putri": "Putri", "campur": "Campur"}

    while True:
        jenis = input("Jenis kos (Putra/Putri/Campur): ").strip().lower()
        if jenis in pilihan:
            return pilihan[jenis]

        print("Pilih salah satu: Putra, Putri, atau Campur.")


def input_fasilitas():
    """Meminta beberapa fasilitas melalui nomor yang dipisahkan dengan koma."""
    daftar_kolom = list(FASILITAS.keys())

    print("\nPilih fasilitas yang diinginkan (pisahkan dengan koma, misalnya: 1,2,8):")
    for nomor, kolom in enumerate(daftar_kolom, start=1):
        print(f"{nomor}. {FASILITAS[kolom]}")

    while True:
        jawaban = input("Nomor fasilitas: ").strip()

        try:
            nomor_terpilih = [int(nomor.strip()) for nomor in jawaban.split(",")]
            if not nomor_terpilih:
                raise ValueError

            # set() menghapus nomor yang dipilih dua kali oleh pengguna.
            fasilitas_terpilih = [
                daftar_kolom[nomor - 1]
                for nomor in dict.fromkeys(nomor_terpilih)
                if 1 <= nomor <= len(daftar_kolom)
            ]

            if fasilitas_terpilih:
                return fasilitas_terpilih
        except ValueError:
            pass

        print("Masukkan minimal satu nomor fasilitas yang valid.")


def filter_kos(dataset, kota, budget, jenis_kos):
    """Menyaring kos berdasarkan kota, budget, dan jenis kos sebelum menghitung similarity."""
    # Filtering dilakukan lebih dulu agar rekomendasi hanya berasal dari kos yang benar-benar mungkin dipilih.
    # Langkah ini juga mengurangi jumlah data yang perlu dihitung sehingga proses lebih efisien.
    hasil_filter = dataset[
        (dataset["kota"].str.lower() == kota.lower())
        & (dataset["harga"] <= budget)
        & (dataset["jenis_kos"] == jenis_kos)
    ].copy()

    return hasil_filter


def buat_teks_fasilitas(baris):
    """Menggabungkan nama fasilitas yang bernilai Ya menjadi satu teks."""
    return " ".join(kolom for kolom in FASILITAS if baris[kolom] == "Ya")


def rekomendasikan(kos_terfilter, fasilitas_user, jumlah_rekomendasi=5):
    """Menghitung similarity fasilitas user terhadap seluruh kos hasil filter."""
    # Setiap kos diubah dari kolom Ya/Tidak menjadi teks, misalnya: "wifi ac kasur lemari".
    teks_fasilitas_kos = kos_terfilter.apply(buat_teks_fasilitas, axis=1).tolist()

    # Preferensi user juga menjadi teks dengan format yang sama agar dapat dibandingkan secara adil.
    teks_preferensi_user = " ".join(fasilitas_user)

    # TF-IDF mengubah kata fasilitas menjadi vektor angka.
    # Kata fasilitas yang relevan mendapat bobot, sehingga perbandingan tidak hanya sekadar menghitung jumlah kata.
    # Vectorizer di-fit HANYA dari dokumen kos (bukan preferensi user), supaya bobot IDF
    # murni mencerminkan seberapa langka suatu fasilitas di antara kos yang dibandingkan.
    # Preferensi user lalu diproyeksikan ke ruang vektor yang sama lewat transform(), bukan
    # ikut fit_transform() — ini juga yang dipakai backend/main.py agar keduanya konsisten.
    vectorizer = TfidfVectorizer(vocabulary=list(FASILITAS.keys()))
    vektor_kos = vectorizer.fit_transform(teks_fasilitas_kos)
    vektor_user = vectorizer.transform([teks_preferensi_user])

    # Cosine Similarity mengukur sudut antara dua vektor.
    # Nilai mendekati 1 berarti fasilitas kos makin mirip dengan preferensi user.
    skor_similarity = cosine_similarity(vektor_user, vektor_kos).flatten()

    # NumPy mengurutkan indeks dari skor terbesar ke terkecil, lalu mengambil maksimal lima data.
    indeks_terbaik = np.argsort(-skor_similarity)[:jumlah_rekomendasi]
    hasil_rekomendasi = kos_terfilter.iloc[indeks_terbaik].copy()
    hasil_rekomendasi["similarity_score"] = skor_similarity[indeks_terbaik]

    return hasil_rekomendasi


def tampilkan_rekomendasi(hasil_rekomendasi):
    """Mencetak detail Top 5 rekomendasi di terminal."""
    print("\n" + "=" * 65)
    print("TOP REKOMENDASI KOS")
    print("=" * 65)

    for peringkat, (_, kos) in enumerate(hasil_rekomendasi.iterrows(), start=1):
        fasilitas_tersedia = [
            nama_tampil for kolom, nama_tampil in FASILITAS.items() if kos[kolom] == "Ya"
        ]

        print(f"\n{peringkat}. {kos['nama_kos']}")
        print(f"   Kota              : {kos['kota']}")
        print(f"   Harga             : {format_rupiah(kos['harga'])} / bulan")
        print(f"   Jenis kos         : {kos['jenis_kos']}")
        print(f"   Similarity score  : {kos['similarity_score']:.4f}")
        print(f"   Fasilitas         : {', '.join(fasilitas_tersedia)}")


def main():
    """Menjalankan alur input, filtering, perhitungan, dan tampilan rekomendasi."""
    try:
        dataset = load_dataset()
    except FileNotFoundError as error:
        print(error)
        return

    print("=" * 65)
    print("SISTEM REKOMENDASI KOS")
    print("=" * 65)
    print("Kota tersedia:", ", ".join(sorted(dataset["kota"].unique())))

    kota = input("Kota yang diinginkan: ").strip()
    budget = input_budget()
    jenis_kos = input_jenis_kos()
    fasilitas_user = input_fasilitas()

    kos_terfilter = filter_kos(dataset, kota, budget, jenis_kos)

    # Bila filter awal kosong, perhitungan similarity tidak dapat dilakukan dan user diberi arahan jelas.
    if kos_terfilter.empty:
        print("\nTidak ada kos yang cocok dengan kota, budget, dan jenis kos tersebut.")
        print("Coba naikkan budget atau pilih kota/jenis kos lain.")
        return

    hasil_rekomendasi = rekomendasikan(kos_terfilter, fasilitas_user)
    tampilkan_rekomendasi(hasil_rekomendasi)


# Kondisi ini membuat main() hanya berjalan saat file dipanggil langsung.
if __name__ == "__main__":
    main()
