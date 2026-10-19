# Campus Room Booking

Aplikasi Flutter (Dart) untuk memesan ruangan kampus secara **standalone** (tanpa backend/API). Data tersimpan di perangkat, tetap ada setelah aplikasi ditutup, dan dapat dipakai offline.

Dibuat untuk tugas UTS Pemrograman Multiplatform.

## Fitur utama

- Dashboard: sapaan nama pengguna, jumlah booking aktif, booking terdekat, pintasan ke daftar ruangan
- Daftar & detail ruangan (termasuk badge ruangan nonaktif)
- Filter gedung dan kapasitas minimum (disimpan di Shared Preferences)
- Form pemesanan dengan validasi, pemilih tanggal/jam, dan cek bentrok jadwal
- Jadwal ruangan per tanggal (hanya status BOOKED)
- Riwayat booking: filter status, detail, ubah, batalkan, dan hapus
- Pengaturan: tema (terang/gelap/sistem), nama pengguna, hapus semua riwayat

## Teknologi dan package

| Package | Fungsi |
| --- | --- |
| Flutter / Dart | UI Material 3 dan logika aplikasi |
| `sqflite` | Persistensi terstruktur (tabel `rooms` dan `bookings`) |
| `path` | Menyusun path file database SQLite |
| `shared_preferences` | Persistensi key-value (tema, nama, filter terakhir) |
| `intl` | Format tanggal/waktu Bahasa Indonesia |

Tidak ada backend. Dua teknik persistensi saja: SQLite dan Shared Preferences.

## Struktur folder

```
lib/
  main.dart
  app.dart
  core/theme/          # tema light & dark Material 3
  core/constants/      # konstanta aplikasi
  core/utils/          # tanggal, overlap, validasi
  models/              # Room, Booking (fromMap/toMap)
  data/database/       # DatabaseHelper (singleton, seed, FK)
  data/repositories/   # RoomRepository, BookingRepository
  services/            # PreferenceService
  features/            # dashboard, rooms, booking, schedule, history, settings
  widgets/             # loading, empty, error, status badge
test/                  # unit test overlap, validasi, model
docs/                  # rencana uji manual + folder screenshot
```

## Langkah menjalankan

```bash
flutter pub get
flutter run
flutter test
```

Analisis statis:

```bash
flutter analyze
```

Aplikasi diuji di emulator atau perangkat fisik. Mode pesawat didukung karena tidak ada panggilan jaringan.
