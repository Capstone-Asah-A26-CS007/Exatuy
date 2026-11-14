# EXATUY - Adu Pintar Tanpa Ribet

> **Exatuy** — *Adu Pintar Tanpa Ribet*
> 
> Solusi all-in-one untuk bimbingan belajar, sekolah, dan pelatihan: manajemen siswa, sistem tagihan otomatis, presensi digital, bank soal, rapor, hingga portal orang tua.

---

## Tentang Exatuy

**Exatuy** adalah platform asesmen online modern yang digunakan dalam program **IDS Cyber Security Academy** untuk mengukur, memvalidasi, dan mendokumentasikan kompetensi peserta secara terstruktur melalui sistem quiz teori dan arena battle.

Platform ini membantu pengelola les menyelesaikan masalah operasional sehari-hari:
- **Penagihan SPP** yang selama ini manual dan melelahkan
- **Pelacakan kuota pertemuan** yang sering terlupa
- **Komunikasi berulang** dengan orang tua via WhatsApp
- **Pembuatan ujian** yang memakan waktu tiap ganti materi

Dukungan untuk berbagai jenjang: SD, SMP, SMA, dan pelatihan umum.

---

## Fitur Utama

### 📚 Manajemen Pembelajaran
- Buat dan kelola quiz dengan multiple choice dan esai singkat
- Atur durasi dan timer countdown dengan auto-submit
- Deadline per quiz dengan timezone WIB
- Gambar pada soal dan opsi jawaban
- Target quiz berdasarkan kelas/kelompok
- Shuffle urutan soal
- Show/hide pembahasan setelah selesai

### 💳 Sistem Tagihan & Kuota (Baru!)
- **Paket Sesi Belajar**: beli berbasis kuota (12, 24, atau kustom pertemuan)
- **Invoice Otomatis**: tagihan digital per periode dengan status
- **Pengingat Tagihan**: notifikasi sebelum jatuh tempo
- **Riwayat Pembayaran**: tunai atau transfer
- **Sisa Kuota Real-time**: indikator visual di dashboard

### ✅ Presensi Digital
- Absensi per pertemuan dengan kode unik
- Pengajar tandai: Hadir / Izin / Sakit / Alpa
- **Auto-potong kuota** saat siswa hadir
- Peringatan kuota menipis (sisa ≤ 2 sesi)
- Export rekap kehadiran ke PDF dan CSV

### 📝 Bank Soal & Evaluasi
- Pre-test dan post-test per topik
- Kategori soal per mata pelajaran
- Koreksi otomatis instan
- Rapor nilai per siswa (ringkasan per periode)

### 👨‍👩‍👧 Portal Orang Tua (Baru!)
- Cek jadwal kelas anak
- Pantau sisa kuota secara transparan
- Lihat riwayat presensi anak
- Akses rapor nilai anak
- Notifikasi perkembangan anak

### 💰 Pencatatan Keuangan (Baru!)
- Pemasukan otomatis dari pembayaran SPP
- Pencatatan pengeluaran operasional
- Ringkasan laba/rugi bulanan
- Export laporan keuangan

### 🏆 Gamification
- Sistem badge dan poin
- Leaderboard antar siswa
- Achievement: Perfect Score, Quick Thinker, dll

### 💬 Chat Support
- Komunikasi real-time antara orang tua/peserta dan admin
- Admin bisa membalas pesan
- Export chat ke TXT

### 🔒 Keamanan Enterprise
- Rate limiting per endpoint
- Login protection (5 gagal → lockout 15 menit)
- CSRF token di semua form
- BCrypt password hashing
- Session fixation protection
- Security headers lengkap

---

## Peran Pengguna

| Peran | Akses |
|-------|-------|
| **Owner/Admin** | Dashboard lengkap, kelola siswa, tagihan, presensi, soal, laporan keuangan, setelan |
| **Pengajar** | Input presensi, buat quiz, lihat hasil siswa, chat |
| **Siswa** | Kerjakan quiz, lihat nilai, chat admin, profil |
| **Orang Tua** | Pantau jadwal, sisa kuota, presensi, dan nilai anak |

---

## Technology Stack

| Komponen | Teknologi |
|----------|-----------|
| Backend | Java 11+, JSP, Servlet |
| Server | Apache Tomcat 10 |
| Database | MySQL 8.0 |
| Connection Pool | HikariCP |
| Frontend | HTML5, CSS3, Bootstrap 5 |
| Charts | Chart.js |
| Export PDF | iText + html2pdf.js |
| Build Tool | Maven |
| Container | Docker & Docker Compose |

---

## Quick Start

```bash
cd /root/documents/tools/Exatuy/Exatuy-main
docker compose up -d
```

Akses: http://localhost:8888

---

## Default Accounts

| Role | Email | Password |
|------|-------|----------|
| Owner | owner@belajarku.id | Admin123! |
| Pengajar | pengajar@belajarku.id | Guru123! |
| Siswa Demo | siswa@belajarku.id | Siswa123! |

---

## License

MIT License — dibuat oleh [Re-xist](https://github.com/Re-xist)

---

**Exatuy** — Adu Pintar Tanpa Ribet
