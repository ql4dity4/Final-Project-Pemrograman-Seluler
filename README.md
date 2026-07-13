# ReconX Mobile - Passive Recon & OSINT Aggregator

ReconX Mobile adalah aplikasi mobile cross-platform (Flutter) yang berfungsi sebagai agregator layanan intelijen pasif (passive reconnaissance) dan OSINT (Open Source Intelligence). Proyek ini dirancang untuk mahasiswa cybersecurity, bug hunter, dan analis IT security untuk mempermudah pencarian informasi awal target tanpa berinteraksi langsung (passive footprinting).

---

## 📐 Arsitektur Sistem & Alur Data (Flowchart)

Berikut adalah diagram alir sistem mulai dari input domain oleh pengguna di aplikasi mobile hingga pengambilan data dari API eksternal secara pasif oleh backend server:

```mermaid
graph TD
    %% Define Nodes
    User([User / Analis]) -->|1. Input Domain & Run Scan| App[Flutter Mobile App]
    
    subgraph Frontend [ReconX Mobile - Client]
        App -->|Cek Status Koneksi| Health[API Health Checker]
        App -->|Simpan Target| Bookmarks[(Local Bookmarks)]
        App -->|Simpan Riwayat| History[(Local History)]
    end

    App -->|2. HTTP request /api/recon/:domain| Backend[Node.js Express Server]

    subgraph Server [ReconX Backend - API Gateway]
        Backend -->|Query A, AAAA, MX, TXT, NS, SOA| DNS[DNS Lookup Service]
        Backend -->|Fetch Whois Data| WHOIS[WHOIS Query Client]
        Backend -->|Query Cert Transparency logs| Subdomains[crt.sh Scraper]
        Backend -->|Analyze Headers & HTML| Tech[Technology Detector]
        Backend -->|Get ISP & Geolocation| Geo[IP-API Geolocation]
        Backend -->|Query Passive Host Records| Ports[Shodan InternetDB API]
    end

    %% External APIs
    DNS -->|DNS Query| DNS_Server((Public DNS Servers))
    WHOIS -->|TCP Port 43| WHOIS_Server((WHOIS Registry))
    Subdomains -->|HTTPS request| CRT_API((Crt.sh Database))
    Tech -->|HTTP GET Request| Target((Target Web Server))
    Geo -->|HTTP Request| IP_API((IP-API Service))
    Ports -->|HTTP Request| Shodan_API((Shodan InternetDB))

    %% Formatting
    style App fill:#6366F1,stroke:#312E81,stroke-width:2px,color:#fff
    style Backend fill:#10B981,stroke:#065F46,stroke-width:2px,color:#fff
    style User fill:#0F172A,stroke:#1E293B,color:#fff
```

---

## 🛠️ Cara Menjalankan Project

### 1. Prasyarat (Prerequisites)
Pastikan sistem Anda sudah terpasang perkakas berikut:
*   [Node.js](https://nodejs.org/) (versi 16 atau lebih baru)
*   [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.0 atau lebih baru)
*   Google Chrome (untuk web preview) atau Emulator Android (untuk mobile preview).

---

### 2. Konfigurasi & Jalankan Backend
Backend bertindak sebagai proxy API server untuk menghindari masalah CORS pada perangkat seluler dan melakukan lookup secara efisien.

1.  Buka terminal baru dan masuk ke direktori backend:
    ```bash
    cd reconx_backend
    ```
2.  Pasang dependensi Node.js:
    ```bash
    npm install
    ```
3.  Pastikan konfigurasi port di file `.env` sudah benar (secara bawaan port `3000`):
    ```env
    PORT=3000
    ```
4.  Jalankan server API:
    ```bash
    node server.js
    ```
    Jika berhasil, Anda akan melihat output:
    `🚀 ReconX Backend running on port 3000`

---

### 3. Jalankan Aplikasi Mobile (Flutter)
Aplikasi seluler secara dinamis mendeteksi platform target. Jika Anda menjalankannya pada Android Emulator, aplikasi akan mengarahkan request ke `http://10.0.2.2:3000` secara otomatis. Jika dijalankan di desktop/web Chrome, aplikasi menggunakan `http://localhost:3000`.

1.  Buka terminal baru lagi dan masuk ke direktori frontend:
    ```bash
    cd reconx_mobile
    ```
2.  Ambil paket dependensi Flutter:
    ```bash
    flutter pub get
    ```
3.  Jalankan aplikasi di browser Chrome (Paling Direkomendasikan & Tercepat):
    ```bash
    flutter run -d chrome
    ```
    Atau jika Anda memiliki emulator Android aktif:
    ```bash
    flutter run -d android
    ```
    Atau jalankan sebagai aplikasi Linux native (membutuhkan perkakas `ninja-build` terpasang di distro Anda):
    ```bash
    flutter run -d linux
    ```

---

## ⚙️ Fitur-Fitur Utama di UI/UX Baru
*   **API Connection Status**: Status online/offline backend secara realtime yang terletak di pojok kanan atas beranda.
*   **Search Filters**: Kotak pencarian tambahan pada fitur Subdomain Finder dan Cheatsheet Payload untuk menyaring ribuan baris data secara instan.
*   **Category Sidebar**: Tampilan vertikal sidebar yang memudahkan pergantian kategori payload cheatsheet.
*   **Left-border Color Coding**: Identifikasi tipe rekaman data menggunakan garis warna vertikal minimalis di sisi kiri kartu hasil scan (layaknya standar dashboard modern).
