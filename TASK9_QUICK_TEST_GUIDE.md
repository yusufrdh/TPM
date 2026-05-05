# 🧪 QUICK TEST GUIDE - TASK 9: ACCELEROMETER

> **Panduan Cepat Testing Shake-to-Snooze**  
> **Estimasi Waktu:** 15-20 menit  
> **Device:** Infinix X6871 (Physical Device Required)

---

## 🎯 TUJUAN TEST

Memastikan fitur **shake-to-snooze** berfungsi dengan baik:
- ✅ Shake detection (goyangkan HP untuk snooze)
- ✅ Max 3x snooze per notifikasi
- ✅ Snooze duration 10 menit
- ✅ Button snooze juga berfungsi
- ✅ Stop detector saat "Sudah Minum"

---

## 📱 PERSIAPAN (5 MENIT)

### 1. Build & Install App
```bash
# Di root project
flutter clean
flutter pub get
flutter run --release
```

### 2. Setup Test Schedule
**Buat jadwal obat dengan waktu 2-3 menit dari sekarang:**

1. Buka app → Tap "+" (Tambah Jadwal)
2. Isi form:
   - **Nama Obat:** `Test Shake`
   - **Jenis Obat:** `Tablet`
   - **Stok:** `10`
   - **Waktu:** **[SEKARANG + 2 MENIT]** ⏰
     - Contoh: Sekarang jam 14:30 → Set jam 14:32
   - **Dosis:** `1`
   - **Satuan:** `tablet`
   - **Frekuensi:** `Setiap Hari`
3. Tap "Simpan Jadwal"

### 3. Verifikasi Notifikasi Terjadwal
```
✅ Lihat console log:
   "✅ Notification scheduled for Test Shake at 14:32"
   "🔔 Starting shake detector for schedule X"
```

### 4. Tunggu Notifikasi Muncul
- Jangan force stop app
- Boleh minimize app (background)
- Tunggu 2-3 menit

---

## 🧪 TEST SCENARIOS (10 MENIT)

### ✅ TEST 1: SHAKE TO SNOOZE (FIRST TIME)
**Waktu:** 2 menit

1. **Tunggu notifikasi muncul** ⏰
2. **Shake device dengan kuat** (seperti mengocok botol)
3. **Observe:**
   - ✅ Notifikasi hilang
   - ✅ Console log: "Shake detected! Magnitude: X.XX m/s²"
   - ✅ Console log: "Triggering snooze (count: 1/3)"
4. **Tunggu 10 menit** → Notifikasi muncul lagi

**PASS:** [ ] YES [ ] NO

---

### ✅ TEST 2: SHAKE TO SNOOZE (SECOND TIME)
**Waktu:** 2 menit

1. **Notifikasi muncul lagi** (setelah 10 menit)
2. **Shake device lagi**
3. **Observe:**
   - ✅ Console log: "Shake #2 detected"
   - ✅ Console log: "Triggering snooze (count: 2/3)"
4. **Tunggu 10 menit** → Notifikasi muncul lagi

**PASS:** [ ] YES [ ] NO

---

### ✅ TEST 3: SHAKE TO SNOOZE (THIRD TIME - MAX)
**Waktu:** 2 menit

1. **Notifikasi muncul lagi** (setelah 10 menit)
2. **Shake device lagi** (ketiga kalinya)
3. **Observe:**
   - ✅ Console log: "Shake #3 detected"
   - ✅ Console log: "Max snooze count reached (3/3)"
   - ✅ Console log: "Shake detection stopped"
4. **Try shake lagi** → Tidak ada efek (detector sudah stop)

**PASS:** [ ] YES [ ] NO

---

### ✅ TEST 4: BUTTON SNOOZE
**Waktu:** 2 menit

**Setup:** Buat jadwal baru (waktu +2 menit dari sekarang)

1. **Tunggu notifikasi muncul**
2. **Tap button "Snooze 10 menit"** pada notifikasi
3. **Observe:**
   - ✅ Notifikasi hilang
   - ✅ Console log: "Snooze button tapped"
   - ✅ Notifikasi muncul lagi setelah 10 menit

**PASS:** [ ] YES [ ] NO

---

### ✅ TEST 5: SUDAH MINUM (STOP DETECTOR)
**Waktu:** 1 menit

**Setup:** Buat jadwal baru (waktu +2 menit dari sekarang)

1. **Tunggu notifikasi muncul**
2. **Tap button "Sudah Minum"** pada notifikasi
3. **Observe:**
   - ✅ Notifikasi hilang
   - ✅ Console log: "Sudah Minum button tapped"
   - ✅ Console log: "Stopping shake detector"
4. **Try shake device** → Tidak ada efek (detector sudah stop)

**PASS:** [ ] YES [ ] NO

---

### ✅ TEST 6: WEAK SHAKE (SHOULD NOT TRIGGER)
**Waktu:** 1 menit

**Setup:** Buat jadwal baru (waktu +2 menit dari sekarang)

1. **Tunggu notifikasi muncul**
2. **Goyangkan device pelan-pelan** (tidak kuat)
3. **Observe:**
   - ✅ Notifikasi TIDAK hilang
   - ✅ Tidak ada console log shake detection
   - ✅ Snooze TIDAK triggered

**PASS:** [ ] YES [ ] NO

---

## 📊 HASIL TEST

### Summary
- **Total Tests:** 6
- **Passed:** ___
- **Failed:** ___
- **Pass Rate:** ___%

### Status
- [ ] ✅ **SEMUA PASS** → Task 9 SELESAI!
- [ ] ⚠️ **ADA YANG FAIL** → Catat bug di bawah

---

## 🐛 BUG REPORT (Jika Ada)

### Bug #1
**Test:** _______________  
**Expected:** _______________  
**Actual:** _______________  
**Severity:** [ ] Critical [ ] High [ ] Medium [ ] Low

### Bug #2
**Test:** _______________  
**Expected:** _______________  
**Actual:** _______________  
**Severity:** [ ] Critical [ ] High [ ] Medium [ ] Low

---

## 💡 TIPS TESTING

### ✅ DO's
- ✅ Gunakan physical device (bukan emulator)
- ✅ Shake dengan kuat (≥ 15 m/s²)
- ✅ Jangan force stop app saat testing
- ✅ Lihat console log untuk debug
- ✅ Tunggu 10 menit penuh untuk snooze

### ❌ DON'Ts
- ❌ Jangan test di emulator (tidak ada accelerometer)
- ❌ Jangan force stop app (shake detector akan mati)
- ❌ Jangan shake terlalu pelan (threshold 15 m/s²)
- ❌ Jangan skip waiting time (harus tunggu 10 menit)

---

## 🔍 CARA LIHAT CONSOLE LOG

### Android Studio
1. Buka Android Studio
2. Tab "Run" di bawah
3. Filter: `ShakeDetector` atau `NotificationService`

### VS Code
1. Terminal → Debug Console
2. Filter: `ShakeDetector` atau `NotificationService`

### Command Line
```bash
# Real-time log
flutter logs | grep -E "ShakeDetector|NotificationService"

# atau
adb logcat | grep -E "ShakeDetector|NotificationService"
```

---

## 📝 CHECKLIST SEBELUM TEST

- [ ] App sudah di-build & install
- [ ] Device fisik (bukan emulator)
- [ ] Battery optimization disabled (Settings > Apps > PillPal > Battery > Unrestricted)
- [ ] Notification permission granted
- [ ] Console log visible
- [ ] Punya waktu 20 menit untuk test

---

## 🎯 ACCEPTANCE CRITERIA

Task 9 dianggap **PASS** jika:

- [x] Shake detection works (threshold ≥ 15 m/s²)
- [x] Max 3x snooze per notification
- [x] Snooze duration = 10 menit
- [x] Button snooze works
- [x] "Sudah Minum" stops detector
- [x] Weak shake does NOT trigger snooze

**Minimal 5/6 tests PASS** → Task 9 APPROVED ✅

---

## 📞 BANTUAN

Jika ada masalah:
1. Cek console log untuk error
2. Restart app (jangan force stop)
3. Cek battery optimization settings
4. Tanya Kiro AI Assistant

---

**Good luck testing! 🚀**

*Created: 5 Mei 2026*
