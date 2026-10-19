# Rencana Pengujian Manual — Campus Room Booking

Isi kolom **Hasil Pengujian** saat menjalankan uji (misalnya: Lulus / Gagal + catatan).

| No | Fitur yang Diuji | Langkah Pengujian | Hasil yang Diharapkan | Hasil Pengujian |
| --- | --- | --- | --- | --- |
| 1 | Fungsi utama: buat booking | Buka form Pesan Ruangan, pilih ruangan aktif, tanggal ≥ hari ini, jam valid, isi nama kegiatan & tujuan, simpan | Booking tersimpan, snackbar sukses, data muncul di Riwayat berstatus Dipesan |  |
| 2 | Proses async (loading lalu data) | Buka Dashboard atau Daftar Ruangan saat data dimuat | LoadingWidget tampil sebentar, kemudian data muncul (bukan layar kosong permanen) |  |
| 3 | Penyimpanan SQLite (simpan lalu baca) | Buat booking baru, buka Riwayat dan Detail booking | Data yang baru disimpan tampil kembali dengan ruangan, tanggal, jam, kegiatan, dan tujuan yang sama |  |
| 4 | Penyimpanan SharedPreferences (tema) | Pengaturan → pilih tema Gelap, lalu buka ulang halaman lain | Tema gelap langsung diterapkan ke MaterialApp |  |
| 5 | Penyimpanan SharedPreferences (nama) | Pengaturan → ubah nama pengguna → simpan → buka Dashboard | Sapaan menampilkan nama yang baru disimpan |  |
| 6 | Persistensi setelah tutup aplikasi | Ubah tema & nama, buat 1 booking, tutup aplikasi sepenuhnya, buka lagi | Tema, nama, filter (jika diubah), dan booking masih ada |  |
| 7 | Mode offline / pesawat | Aktifkan mode pesawat, buat booking, buka jadwal & riwayat | Aplikasi tetap berfungsi; data tersimpan lokal |  |
| 8 | Cek bentrok jadwal | Buat booking A (mis. 08:00–10:00). Buat booking B di ruangan & tanggal sama dengan jam 09:00–11:00 | Booking B ditolak, pesan error bentrok dalam Bahasa Indonesia |  |
| 9 | Booking dibatalkan tidak memblokir | Batalkan booking A, lalu pesan ulang jam yang sebelumnya bentrok | Booking baru berhasil karena status CANCELLED tidak memblokir |  |
| 10 | Ruangan nonaktif tidak bisa dipesan | Buka Lab Multimedia C-201 (nonaktif), coba pesan | Tombol pesan tidak tersedia / validasi menolak ruangan nonaktif |  |
| 11 | Validasi form: field wajib | Kirim form tanpa mengisi kegiatan atau tujuan | Pesan error Bahasa Indonesia, data tidak tersimpan |  |
| 12 | Validasi form: jam selesai > jam mulai | Isi jam mulai 12:00 dan jam selesai 11:00 | Pesan “Jam selesai harus lebih besar dari jam mulai.” |  |
| 13 | Validasi form: tanggal & jam hari ini | Pilih tanggal hari ini dan jam mulai yang sudah lewat | Pesan jam mulai tidak boleh sudah lewat |  |
| 14 | Batalkan booking | Buka detail booking aktif → Batalkan → konfirmasi | Status menjadi Dibatalkan; slot jadwal kosong |  |
| 15 | Hapus booking | Buka detail → Hapus → konfirmasi | Data hilang dari riwayat dan SQLite |  |
| 16 | Hapus semua riwayat | Pengaturan → Hapus semua riwayat booking → konfirmasi | Semua booking terhapus; daftar ruangan tetap ada |  |
| 17 | Filter ruangan tersimpan | Filter gedung dan kapasitas min. di Daftar Ruangan, tutup app, buka lagi | Filter terakhir dipulihkan |  |
| 18 | Jadwal per ruangan & tanggal | Halaman Jadwal: pilih ruangan dan tanggal yang punya booking BOOKED | Hanya booking aktif hari itu yang tampil, diurutkan jam mulai |  |
| 19 | Tema light/dark/system | Ganti ketiga opsi tema di Pengaturan | Tampilan berubah sesuai pilihan, termasuk NavigationBar |  |
| 20 | Back-to-back tidak bentrok | Booking 08:00–10:00 lalu 10:00–12:00 ruangan & tanggal sama | Kedua booking berhasil (tidak dianggap overlap) |  |
