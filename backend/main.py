"""FastAPI backend for Askia Kost recommendations.

Algoritma: filter dataset berdasarkan kota + rentang budget + jenis kos,
lalu Content-Based Filtering (TF-IDF atas kolom fasilitas) + Cosine
Similarity antara vektor preferensi user dan setiap kos hasil filter.
"""

from pathlib import Path
from typing import List, Optional

import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity

DATA_PATH = Path(__file__).parent / "data" / "kos_dataset.csv"

REQUIRED_COLUMNS = [
    "id",
    "nama_kos",
    "kota",
    "kecamatan",
    "harga",
    "jenis_kos",
]

FACILITY_COLUMNS = [
    "wifi",
    "ac",
    "kipas",
    "kasur",
    "lemari",
    "meja",
    "kamar_mandi_dalam",
    "parkir_motor",
    "parkir_mobil",
    "dapur",
    "cctv",
    "keamanan",
    "dekat_transportasi",
]

FACILITY_LABELS = {
    "wifi": "WiFi",
    "ac": "AC",
    "kipas": "Kipas Angin",
    "kasur": "Kasur",
    "lemari": "Lemari",
    "meja": "Meja",
    "kamar_mandi_dalam": "Kamar Mandi Dalam",
    "parkir_motor": "Parkir Motor",
    "parkir_mobil": "Parkir Mobil",
    "dapur": "Dapur",
    "cctv": "CCTV",
    "keamanan": "Keamanan 24 Jam",
    "dekat_transportasi": "Dekat Transportasi Umum",
}

TRUTHY_VALUES = {"1", "yes", "ya", "true", "y"}

app = FastAPI(title="Askia Kost Recommendation API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_dataset_cache: Optional[pd.DataFrame] = None


def _to_binary(series: pd.Series) -> pd.Series:
    def convert(value):
        if pd.isna(value):
            return 0
        if isinstance(value, (int, float)):
            return 1 if value else 0
        return 1 if str(value).strip().lower() in TRUTHY_VALUES else 0

    return series.apply(convert)


def load_dataset() -> pd.DataFrame:
    global _dataset_cache
    if _dataset_cache is not None:
        return _dataset_cache

    if not DATA_PATH.exists():
        raise FileNotFoundError(
            f"Dataset tidak ditemukan di {DATA_PATH}. "
            "Taruh file kos_dataset.csv di folder backend/data/."
        )

    df = pd.read_csv(DATA_PATH)

    missing = [col for col in REQUIRED_COLUMNS if col not in df.columns]
    if missing:
        raise ValueError(f"Kolom wajib hilang dari dataset: {', '.join(missing)}")

    for col in FACILITY_COLUMNS:
        df[col] = _to_binary(df[col]) if col in df.columns else 0

    df["harga"] = pd.to_numeric(df["harga"], errors="coerce").fillna(0)
    df["kota"] = df["kota"].astype(str)
    df["jenis_kos"] = df["jenis_kos"].astype(str)

    _dataset_cache = df
    return df


def facility_document(row: pd.Series) -> str:
    tokens = [col for col in FACILITY_COLUMNS if row.get(col, 0) == 1]
    return " ".join(tokens)


class RecommendationRequest(BaseModel):
    kota: str
    kecamatan: Optional[str] = None
    budget_min: float = Field(ge=0)
    budget_max: float = Field(ge=0)
    jenis_kos: Optional[str] = None
    fasilitas: List[str] = Field(default_factory=list)


class RecommendationItem(BaseModel):
    rank: int
    kosId: str
    namaKos: str
    lokasi: str
    kota: str
    hargaSewa: float
    mataUang: str = "IDR"
    tipeKos: str
    fasilitas: List[str]
    cosineSimilarity: float
    reasons: List[str]


class RecommendationResponse(BaseModel):
    count: int
    results: List[RecommendationItem]


@app.get("/health")
def health():
    return {"status": "ok"}


@app.post("/recommendations", response_model=RecommendationResponse)
def get_recommendations(payload: RecommendationRequest) -> RecommendationResponse:
    if payload.budget_min > payload.budget_max:
        raise HTTPException(
            status_code=400,
            detail="budget_min tidak boleh lebih besar dari budget_max",
        )

    unknown_facilities = [f for f in payload.fasilitas if f not in FACILITY_COLUMNS]
    if unknown_facilities:
        raise HTTPException(
            status_code=400,
            detail=(
                f"Fasilitas tidak dikenal: {', '.join(unknown_facilities)}. "
                f"Pilihan valid: {', '.join(FACILITY_COLUMNS)}"
            ),
        )

    try:
        df = load_dataset()
    except (FileNotFoundError, ValueError) as exc:
        raise HTTPException(status_code=500, detail=str(exc)) from exc

    filtered = df[
        (df["kota"].str.strip().str.lower() == payload.kota.strip().lower())
        & (df["harga"] >= payload.budget_min)
        & (df["harga"] <= payload.budget_max)
    ]

    if payload.jenis_kos:
        filtered = filtered[
            filtered["jenis_kos"].str.strip().str.lower()
            == payload.jenis_kos.strip().lower()
        ]

    if payload.kecamatan:
        filtered = filtered[
            filtered["kecamatan"].str.strip().str.lower()
            == payload.kecamatan.strip().lower()
        ]

    if filtered.empty:
        return RecommendationResponse(count=0, results=[])

    filtered = filtered.reset_index(drop=True)

    facility_docs = filtered.apply(facility_document, axis=1).tolist()

    user_tokens = [f for f in payload.fasilitas if f in FACILITY_COLUMNS]
    user_doc = " ".join(user_tokens)

    vectorizer = TfidfVectorizer(vocabulary=FACILITY_COLUMNS)
    tfidf_matrix = vectorizer.fit_transform(facility_docs)
    user_vector = vectorizer.transform([user_doc])

    similarities = cosine_similarity(user_vector, tfidf_matrix).flatten()
    filtered = filtered.assign(cosine_similarity=similarities)

    ranked = filtered.sort_values("cosine_similarity", ascending=False).head(5)

    results: List[RecommendationItem] = []
    for rank, (_, row) in enumerate(ranked.iterrows(), start=1):
        row_facilities = [
            FACILITY_LABELS[col] for col in FACILITY_COLUMNS if row.get(col, 0) == 1
        ]
        matched_facilities = [
            FACILITY_LABELS[col] for col in user_tokens if row.get(col, 0) == 1
        ]

        reasons: List[str] = []
        if matched_facilities:
            reasons.append(f"Cocok dengan fasilitas: {', '.join(matched_facilities)}")
        if payload.jenis_kos:
            reasons.append(f"Tipe kos sesuai: {row['jenis_kos']}")
        if payload.kecamatan:
            reasons.append(f"Kecamatan sesuai: {row['kecamatan']}")
        harga_label = f"{int(row['harga']):,}".replace(",", ".")
        reasons.append(f"Harga Rp{harga_label} sesuai rentang anggaran")

        kecamatan = str(row.get("kecamatan", "")).strip()
        kota = str(row["kota"]).strip()
        lokasi = f"{kecamatan}, {kota}" if kecamatan else kota

        results.append(
            RecommendationItem(
                rank=rank,
                kosId=str(row["id"]),
                namaKos=str(row["nama_kos"]),
                lokasi=lokasi,
                kota=kota,
                hargaSewa=float(row["harga"]),
                tipeKos=str(row["jenis_kos"]),
                fasilitas=row_facilities,
                cosineSimilarity=round(float(row["cosine_similarity"]), 4),
                reasons=reasons,
            )
        )

    return RecommendationResponse(count=len(results), results=results)
