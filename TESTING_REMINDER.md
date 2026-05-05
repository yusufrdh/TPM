# ⚠️ TESTING REMINDER - TASK 9: ACCELEROMETER

> **URGENT:** Task 9 sudah diimplementasi tapi **BELUM DI-TEST!**  
> **Estimasi:** 25 menit  
> **Device:** Infinix X6871 (Physical Device)

---

## 🎯 APA YANG HARUS DI-TEST?

**Feature:** Shake-to-Snooze Notification  
**Implementation:** Accelerometer Sensor (S-01)

### Fitur yang Harus Diverifikasi:
1. ✅ **Shake Detection** - Goyangkan HP untuk snooze notifikasi
2. ✅ **Max 3x Snooze** - Maksimal 3x snooze per notifikasi
3. ✅ **Snooze Duration** - Snooze selama 10 menit
4. ✅ **Button Snooze** - Button "Snooze 10 menit" juga berfungsi
5. ✅ **Stop Detector** - Detector stop saat "Sudah Minum"
6. ✅ **Weak Shake** - Goyangan pelan tidak trigger snooze

---

## 📋 QUICK TEST CHECKLIST (15 MENIT)

### FASE 1: PERSIAPAN (5 menit)
- [ ] Build & install app: `flutter run --release`
- [ ] Buat jadwal test (waktu +2 menit dari sekarang)
- [ ] Verifikasi notifikasi terjadwal (lihat console log)
- [ ] Tunggu notifikasi muncul

### FASE 2: SHAKE TEST (5 menit)
- [ ] **Test 1:** Shake pertama → Notifikasi hilang, muncul lagi 10 menit
- [ ] **Test 2:** Shake kedua → Notifikasi hilang, muncul lagi 10 menit
- [ ] **Test 3:** Shake ketiga → Max snooze, detector stop
- [ ] **Test 4:** Shake keempat → Tidak ada efek (expected)

### FASE 3: BUTTON & EDGE CASES (5 menit)
- [ ] **Test 5:** Button "Snooze 10 menit" → Berfungsi
- [ ] **Test 6:** Button "Sudah Minum" → Detector stop
- [ ] **Test 7:** Weak shake → Tidak trigger snooze (expected)

---

## 📚 DOKUMENTASI TESTING

### 1. Quick Guide (Recommended)
**File:** `TASK9_QUICK_TEST_GUIDE.md` (root folder)  
**Isi:** Panduan cepat 6 test scenarios (15-20 menit)

### 2. Full Testing Manual
**File:** `docs/03-testing/MANUAL_TESTING_TASK9_ACCELEROMETER.md`  
**Isi:** 15 test cases lengkap dengan form (25-30 menit)

---

## 🚀 CARA MULAI TESTING

### Option 1: Quick Test (Recommended)
```bash
# 1. Buka quick guide
code TASK9_QUICK_TEST_GUIDE.md

# 2. Build app
flutter clean && flutter pub get && flutter run --release

# 3. Follow 6 test scenarios di quick guide
```

### Option 2: Full Test
```bash
# 1. Buka full manual
code docs/03-testing/MANUAL_TESTING_TASK9_ACCELEROMETER.md

# 2. Build app
flutter clean && flutter pub get && flutter run --release

# 3. Follow 15 test cases di manual
```

---

## ⚙️ PERSIAPAN DEVICE

### 1. Battery Optimization (PENTING!)
```
Settings > Apps > PillPal-AI > Battery > Unrestricted
```
**Kenapa?** Agar shake detector tetap jalan saat app di background

### 2. Notification Permission
```
Settings > Apps > PillPal-AI > Permissions > Notifications > Allow
```

### 3. Exact Alarm Permission (Android 12+)
```
Settings > Apps > PillPal-AI > Alarms & reminders > Allow
```

---

## 🔍 CARA LIHAT CONSOLE LOG

### Android Studio
```
Tab "Run" → Filter: "ShakeDetector"
```

### VS Code
```
Debug Console → Filter: "ShakeDetector"
```

### Command Line
```bash
flutter logs | grep -E "ShakeDetector|NotificationService"
```

---

## 📊 EXPECTED CONSOLE LOGS

### Saat Notifikasi Dijadwalkan:
```
✅ Notification scheduled for Test Shake at 14:32 (ID: 1)
🔔 Starting shake detector for schedule 1
[ShakeDetector] Starting shake detection for schedule 1
[ShakeDetector] Shake detection started (threshold: 15.0 m/s²)
```

### Saat Shake Detected:
```
[ShakeDetector] Shake detected! Magnitude: 18.45 m/s²
[ShakeDetector] Shake #1 detected for schedule 1
[ShakeDetector] Triggering snooze (count: 1/3)
⏰ Snoozing notification for schedule 1
✅ Notification snoozed until 2026-05-05 14:42:00.000
```

### Saat Max Snooze:
```
[ShakeDetector] Shake #3 detected for schedule 1
[ShakeDetector] Max snooze count reached (3/3)
[ShakeDetector] Notification will be marked as "missed"
[ShakeDetector] Stopping shake detection for schedule 1
[ShakeDetector] Shake detection stopped
```

---

## ✅ ACCEPTANCE CRITERIA

Task 9 dianggap **PASS** jika:

- [x] Shake detection works (≥ 15 m/s²)
- [x] Max 3x snooze per notification
- [x] Snooze duration = 10 menit
- [x] Button snooze works
- [x] "Sudah Minum" stops detector
- [x] Weak shake does NOT trigger

**Minimal 5/6 criteria PASS** → Task 9 APPROVED ✅

---

## 🐛 JIKA ADA BUG

### 1. Catat Bug
- Test mana yang fail?
- Expected behavior?
- Actual behavior?
- Console log error?

### 2. Report ke Kiro
```
"Saya menemukan bug di Task 9:
- Test: [nama test]
- Expected: [...]
- Actual: [...]
- Console log: [...]"
```

### 3. Kiro akan Fix
- Analisis root cause
- Fix implementation
- Re-test

---

## 💡 TIPS TESTING

### ✅ DO's
- ✅ Gunakan physical device (Infinix X6871)
- ✅ Shake dengan kuat (≥ 15 m/s²)
- ✅ Jangan force stop app
- ✅ Lihat console log
- ✅ Tunggu 10 menit penuh

### ❌ DON'Ts
- ❌ Jangan test di emulator
- ❌ Jangan force stop app
- ❌ Jangan shake terlalu pelan
- ❌ Jangan skip waiting time

---

## 📞 NEED HELP?

Tanya Kiro AI Assistant:
- "Bagaimana cara test Task 9?"
- "Console log tidak muncul, kenapa?"
- "Shake detection tidak jalan, kenapa?"
- "Saya menemukan bug di Task 9: [...]"

---

## 🎯 NEXT STEPS AFTER TESTING

### Jika PASS (5/6 tests):
1. ✅ Update `CHECKLIST_PROGRESS.md` → Task 9 = TESTED
2. ✅ Commit hasil testing
3. ✅ Lanjut ke Task 10 (Biometric Login)

### Jika FAIL:
1. ❌ Report bug ke Kiro
2. ❌ Tunggu fix dari Kiro
3. ❌ Re-test setelah fix

---

## 📅 DEADLINE

**Target:** Selesai testing hari ini (5 Mei 2026)  
**Estimasi:** 25 menit  
**Priority:** 🔴 HIGH (blocking Task 10)

---

**MULAI TESTING SEKARANG! 🚀**

*Created: 5 Mei 2026*  
*For: Task 9 - Accelerometer Sensor (S-01)*
