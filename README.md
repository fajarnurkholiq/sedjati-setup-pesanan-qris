# Kavelo Order — Sedjati Coffee

Versi client baru dari sistem Kavelo Order (self-order via QR meja) untuk:

- **Nama:** Sedjati Coffee
- **Kategori:** Kedai Kopi
- **Kota:** Majalengka
- **Alamat:** Jl. Raya K.H. Abdul Halim No.165, Majalengka Kulon
- **WhatsApp:** +62 857-2121-6000
- **Website:** sedjaticoffee.id

Arsitektur, alur, dan fitur mengikuti persis template Kavelo Order yang sudah
terbukti bekerja: scan QR meja → menu → cart → catatan → submit order →
admin menerima & memproses order → status New → Accepted → Completed →
update realtime. Tidak ada fitur di luar itu (tanpa payment/QRIS, inventory,
loyalty, atau printer).

## Struktur Project

```
kavelo-sedjati/
├── index.html          # App utama: customer menu + admin dashboard
├── qr-generator.html    # Tool cetak QR untuk 10 meja demo
├── supabase/setup.sql   # Schema, RLS, function create_order, realtime
├── assets/
│   ├── logo/            # taruh logo.png
│   ├── favicon/         # taruh favicon.ico
│   └── products/        # taruh foto produk (lihat README di dalamnya)
└── README.md
```

## Langkah Setup

### 1. Buat Project Supabase Baru
Buat project Supabase baru khusus Sedjati Coffee (jangan pakai project
client sebelumnya).

### 2. Jalankan Schema Database
Buka **SQL Editor** di Supabase, copy-paste isi `supabase/setup.sql`, lalu Run.
Ini akan membuat tabel `orders`, RLS policy, function `create_order`, dan
mengaktifkan realtime.

### 3. Isi Credential Supabase
Buka `index.html`, cari bagian:

```js
const SUPABASE_URL = "SUPABASE_URL";
const SUPABASE_ANON_KEY = "SUPABASE_ANON_KEY";
```

Ganti dengan **Project URL** dan **anon public key** dari
Project Settings → API di dashboard Supabase Sedjati Coffee.
**Jangan pernah** memasukkan `service_role` key atau password database ke frontend.

### 4. Tambahkan Asset
- Logo → `assets/logo/logo.png`
- Favicon → `assets/favicon/favicon.ico`
- Foto produk → `assets/products/` (daftar nama file lengkap ada di
  `assets/products/README.md`)

Jika asset belum tersedia, aplikasi tetap jalan normal dengan fallback ikon
(tidak error, tidak rusak tampilan).

### 5. Ganti PIN Admin
Di `index.html`, cari:

```js
const ADMIN_PIN = "SEDJATI2024";
```

Ganti dengan PIN rahasia milik Sedjati Coffee sebelum go-live. PIN ini hanya
proteksi UI sederhana (bukan login sungguhan), sama seperti template asal.

### 6. Deploy
Upload folder ini ke static hosting apa pun (Netlify, Vercel, GitHub Pages,
cPanel, dsb). Tidak perlu build step — murni file statis (HTML/CSS/JS).

### 7. Generate QR Meja
Buka `qr-generator.html` di browser (boleh lokal atau setelah deploy),
isi alamat website yang sudah live, lalu klik **Buat QR**. QR akan mengarah ke:

```
https://domain-anda.com/index.html?table=01
https://domain-anda.com/index.html?table=02
...sampai table=10
```

Klik **Cetak Semua** untuk mencetak QR siap tempel di setiap meja.

### 8. Akses Admin
Buka `index.html?admin=true`, masukkan PIN admin untuk melihat dashboard
pesanan real-time.

## Menu

Menu lengkap (36 item, 9 kategori: Espresso, Tambahan, Signature, Manual
Brew, Matcha, Non Coffee, Bigger Size 1 Liter, Dessert, Pastry) sudah
dimasukkan langsung ke `menuData` di dalam `index.html`. Untuk mengubah
harga/nama/menambah item baru, edit array `menuData` di bagian
`MENU DATA - SEDJATI COFFEE`.

## Catatan Keamanan

Dashboard admin memakai proteksi PIN di sisi frontend (bukan autentikasi
server). Ini konsisten dengan template Kavelo Order sebelumnya yang sudah
terbukti bekerja untuk skala warung kopi. Untuk kebutuhan keamanan lebih
tinggi di masa depan (login staff, role, dsb), itu di luar scope versi ini.
