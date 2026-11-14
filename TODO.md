# TODO List - Exatuy Expansion for Bimbingan Belajar (UMKM)

**Target Pengguna:** Owner, Pengajar, Orang Tua/Siswa  
**Jenjang:** SD - SMP  
**Teknologi:** Java 11 + JSP/Servlet + MySQL 8 + Tomcat 10

---

## Fase 1: MVP Inti (Billing, Kuota, Presensi)

### Priority P1 - Sistem Tagihan & Kuota
- [ ] **Paket Sesi Belajar**
  - [ ] Buat model `SessionPackage` (id, nama_paket, jumlah_sesi, harga, durasi_bulan)
  - [ ] Admin bisa buat/edit/hapus paket (contoh: Paket 12 pertemuan)
  - [ ] Siswa bisa "beli" paket → buat record di `student_packages`

- [ ] **Invoice & Tagihan**
  - [ ] Model `Invoice` (id, student_id, package_id, total, status: [belum_lunas, menunggu_verifikasi, lunas], tanggal_jatuh_tempo)
  - [ ] CRUD Invoice untuk setiap siswa
  - [ ] Status badge dengan warna (kuning=belum, biru=menunggu, hijau=lunas)

- [ ] **Notifikasi Tagihan**
  - [ ] Trigger email otomatis 3 hari sebelum jatuh tempo
  - [ ] Trigger email saat kuota sisa ≤ 2 sesi
  - [ ] Notification queue sudah ada, tinggal integrasi

### Priority P2 - Presensi & Kuota Tracker
- [ ] **Absensi Per Pertemuan**
  - [ ] Extend `attendance_sessions` dengan `package_session_id`
  - [ ] Pengajar tandai: Hadir / Izin / Sakit / Alpa
  - [ ] Auto-potong kuota siswa saat absen hadir

- [ ] **Pemotongan Kuota Otomatis**
  - [ ] Model `quota_tracker` (student_id, session_id, remaining_quota, total_quota, status)
  - [ ] Trigger decrement saat presensi dicatat
  - [ ] Warning visual: kuota ≤ 2 sisa (badge merah/kuning)

- [ ] **Dashboard Ringkasan Kuota**
  - [ ] Tampilkan sisa sesi untuk setiap siswa
  - [ ] Progress bar: used/total
  - [ ] Sortir berdasarkan sisa terdekat

---

## Fase 2: Sistem Evaluasi (CBT)

### Priority P1 - Pre-Test & Post-Test
- [ ] **Quizzes khusus Pre/Post**
  - [ ] Tambah field `quiz_type` pada table `quiz`: [regular, pre_test, post_test]
  - [ ] Filter quiz di dashboard admin
  - [ ] Label badge untuk Pre/Post

- [ ] **Rapor Nilai Siswa**
  - [ ] Halaman `/TranscriptServlet?action=report`
  - [ ] Rekap nilai per subject (Matematika, IPA, dll)
  - [ ] Chart perbandingan Pre-Test vs Post-Test
  - [ ] Export PDF rapor

### Priority P2 - Bank Soal
- [ ] **Kategori Soal**
  - [ ] Table `question_categories`: id, name, subject, grade_level (SD1-6, SMP1-3)
  - [ ] Import soal via CSV dengan kolom subject + grade
  - [ ] Filter bank soal berdasarkan mata pelajaran

- [ ] **Auto-Grading Esai**
  - [ ] Support tipe soal esai singkat (keyword matching)
  - [ ] Score parcial berdasarkan keywords

---

## Fase 3: Portal & Pembukuan

### Priority P1 - Parent Portal
- [ ] **Akun Orang Tua**
  - [ ] Model `parent_accounts` linked ke `users`
  - [ ] One parent = many children (students)
  - [ ] Login terpisah atau via single account dengan filter role

- [ ] **Dashboard Orang Tua**
  - [ ] Sisa kuota anak (real-time)
  - [ ] Riwayat presensi anak (hadir/izin/sakit/alpa)
  - [ ] Nilai ujian anak (Pre/Post test)
  - [ ] Jadwal kelas minggu ini

### Priority P2 - Keuangan Sederhana
- [ ] **Pencatatan Pemasukan**
  - [ ] Auto dari invoice yang sudah dibayar (status=lunas)
  - [ ] Manual entry untuk tunai

- [ ] **Pencatatan Pengeluaran**
  - [ ] Model `expenses` (id, kategori, nominal, tanggal, deskripsi, bukti)
  - [ ] Kategori: Gaji Guru, Modul/ATK, Sewa Tempat, dll
  - [ ] Form tambah pengeluaran

- [ ] **Laporan Laba/Rugi Bulanan**
  - [ ] Ringkasan pemasukan vs pengeluaran
  - [ ] Chart bulanan (6 bulan terakhir)
  - [ ] Export PDF/CSV

### Priority P2 - Kalender & Materi
- [ ] **Kalender Jadwal Kelas**
  - [ ] View calendar per kelompok belajar
  - [ ] Color code berdasarkan hari/mata pelajaran
  - [ ] Export kalender

- [x] **Repo Materi & Silabus (BARU!)**
  - [x] Model `materials` + `material_categories`
  - [x] Admin: CRUD kategori silabus (nama, deskripsi, jenjang)
  - [x] Admin: Upload materi (PDF/DOC/Link) per kategori + tag target
  - [x] Admin: Generate/Auto-generate materi silabus dari template
  - [x] User: Browse materi sesuai tag mereka
  - [x] Halaman `/MateriServlet` untuk admin & user

---

## UI/UX Refresh - Educational Platform Theme

- [ ] **Color Palette Baru**
  - Primary: Soft Blue (#4A90D9) - trust, calm
  - Secondary: Warm Orange (#F5A623) - energy, creativity
  - Accent: Green (#7BC67E) - growth, success
  - Background: Off-white (#F7F9FC) - clean, readable
  - Card: White with soft shadow

- [ ] **Typography**
  - Font: Nunito atau Poppins (rounded, friendly)
  - Larger text size untuk readability
  - Icon-heavy navigation

- [ ] **Components Baru**
  - [ ] `CardKuota` - widget sisa sesi + progress bar
  - [ ] `InvoiceCard` - tampilan tagihan dengan status
  - [ ] `PresensiCard` - tombol absensi quick-touch
  - [ ] `ParentWidget` - ringkasan anak di dashboard

- [ ] **Halaman Baru**
  - [ ] `/BillingServlet` - manajemen invoice & pembayaran
  - [ ] `/QuotaServlet` - tracker kuota siswa
  - [ ] `/RaporServlet` - rapor nilai siswa
  - [ ] `/KeuanganServlet` - pencatatan pemasukan/pengeluaran
  - [ ] `/ParentDashboard.jsp` - portal orang tua

---

## Database Migration Plan

```sql
-- Fase 1
CREATE TABLE session_packages (...);
CREATE TABLE student_packages (...);
CREATE TABLE invoices (...);
CREATE TABLE quota_tracker (...);

-- Fase 2
ALTER TABLE quizzes ADD COLUMN quiz_type ENUM(...);
CREATE TABLE question_categories (...);
CREATE TABLE rapor_rekap (...);

|-- Fase 3
CREATE TABLE parent_accounts (...);
CREATE TABLE expenses (...);
CREATE TABLE class_schedule (...);
CREATE TABLE material_categories (id, nama, deskripsi, jenjang, created_by);
CREATE TABLE materials (id, category_id, title, content, file_path, file_type, target_tags, generated_by, generated_at);
```

---

## Estimated Timeline

| Fase | Duration | Focus |
|------|----------|-------|
| Fase 1 | 2-3 minggu | Billing, Kuota, Presensi |
| Fase 2 | 1-2 minggu | CBT, Bank Soal, Rapor |
| Fase 3 | 2 minggu | Parent Portal, Keuangan |
| UI Refresh | paralel | CSS + component library |

**Total estimasi:** 5-7 minggu

---

## Notes

- Reuse existing `attendance_sessions` table (sudah ada)
- Reuse existing notification system untuk reminder
- Reuse existing auth & rate limiting
- Chart.js sudah terinstall untuk grafik
- Bootstrap 5 sudah ada
