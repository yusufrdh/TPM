# 🚀 MULAI TESTING TASK 9 - START HERE!

> **Panduan untuk memulai testing Task 9 (Accelerometer)**  
> **Baca file ini terlebih dahulu sebelum testing**

---

## ✅ PERSIAPAN SELESAI!

Saya sudah menyiapkan **4 file lengkap** untuk membantu testing Task 9:

### 📁 File yang Tersedia:

1. **TESTING_REMINDER.md** ⚠️
   - Urgent reminder & overview
   - Baca ini dulu (2 menit)

2. **TASK9_QUICK_TEST_GUIDE.md** ⭐ RECOMMENDED
   - Panduan cepat (6 test scenarios)
   - Estimasi: 20 menit
   - **MULAI DARI SINI!**

3. **TASK9_TEST_HELPER.md** 🛠️
   - Troubleshooting & tips
   - Parallel testing guide
   - Console log cheat sheet

4. **TASK9_TESTING_FILES.md** 📚
   - Overview semua file
   - Comparison table
   - Decision tree

---

## 🎯 LANGKAH CEPAT (3 STEPS)

### Step 1: Baca Overview (2 menit)
```bash
# Buka file ini di VS Code
code TESTING_REMINDER.md
```

**Isi:**
- Apa yang harus di-test?
- Kenapa penting?
- Acceptance criteria

---

### Step 2: Ikuti Quick Guide (20 menit) ⭐
```bash
# Buka quick guide
code TASK9_QUICK_TEST_GUIDE.md
```

**Isi:**
- 📱 Persiapan (5 menit)
  - Build app
  - Buat jadwal test
  - Tunggu notifikasi
- 🧪 6 Test scenarios (15 menit)
  - Test 1: Shake #1
  - Test 2: Shake #2
  - Test 3: Shake #3 (max)
  - Test 4: Button snooze
  - Test 5: Sudah minum
  - Test 6: Weak shake
- 📊 Template hasil test

---

### Step 3: Troubleshooting (Jika Perlu)
```bash
# Jika ada masalah, buka helper
code TASK9_TEST_HELPER.md
```

**Isi:**
- 🐛 Problem 1: Notifikasi tidak muncul
- 🐛 Problem 2: Shake tidak terdeteksi
- 🐛 Problem 3: App force stopped
- 🐛 Problem 4: Console log tidak muncul
- 💡 Pro tips

---

## 🚀 QUICK START (COPY-PASTE INI)

### 1. Build App
```bash
cd "D:\Kuliah\Semester 6\Mobile\TPM"
flutter clean
flutter pub get
flutter run --release
```

### 2. Buat Jadwal Test
1. Buka app → Tap "+" (floating button)
2. Isi form:
   - Nama: `Test Shake`
   - Jenis: `Tablet`
   - Stok: `10`
   - Waktu: **[JAM SEKARANG + 2 MENIT]** ⏰
   - Dosis: `1`
   - Satuan: `tablet`
   - Frekuensi: `Setiap Hari`
3. Tap "Simpan Jadwal"

### 3. Tunggu & Test
- Tunggu 2 menit
- Notifikasi muncul
- **Shake device dengan kuat**
- Observe hasil

---

## 📊 ESTIMASI WAKTU

| Activity | Duration |
|----------|----------|
| Baca overview | 2 min |
| Build app | 3 min |
| Buat jadwal | 2 min |
| Test 6 scenarios | 15 min |
| **TOTAL** | **22 min** |

**Tips:** Gunakan parallel testing untuk lebih cepat (lihat `TASK9_TEST_HELPER.md`)

---

## 🎯 ACCEPTANCE CRITERIA

Task 9 dianggap **PASS** jika:

- [x] Shake detection works (≥ 15 m/s²)
- [x] Max 3x snooze per notification
- [x] Snooze duration = 10 menit
- [x] Button snooze works
- [x] "Sudah Minum" stops detector
- [x] Weak shake does NOT trigger

**Minimal 5/6 criteria PASS** → Task 9 APPROVED ✅

---

## 📱 DEVICE REQUIREMENTS

### ✅ MUST HAVE:
- **Physical device** (Infinix X6871)
- **NOT emulator** (no accelerometer)
- **Battery optimization:** Unrestricted
- **Notification permission:** Allowed

### ⚙️ Settings:
```
Settings > Apps > PillPal-AI > Battery > Unrestricted
Settings > Apps > PillPal-AI > Permissions > Notifications > Allow
```

---

## 🔍 CONSOLE LOG

### Cara Lihat:

#### Android Studio:
```
Tab "Run" → Filter: "ShakeDetector"
```

#### VS Code:
```
Debug Console → Filter: "ShakeDetector"
```

#### Command Line:
```bash
flutter logs | grep -E "ShakeDetector|NotificationService"
```

### Expected Log:
```
✅ Notification scheduled for Test Shake at 14:32
🔔 Starting shake detector for schedule 1
[ShakeDetector] Shake detected! Magnitude: 18.45 m/s²
[ShakeDetector] Triggering snooze (count: 1/3)
⏰ Snoozing notification for schedule 1
```

---

## 💡 PRO TIPS

### Tip 1: Parallel Testing (Hemat Waktu)
Buat 3 jadwal sekaligus dengan interval 2 menit:
- Jadwal 1: Sekarang + 2 min (Test 1-3)
- Jadwal 2: Sekarang + 4 min (Test 4)
- Jadwal 3: Sekarang + 6 min (Test 5-6)

**Total waktu:** 20 menit (vs 35 menit)

### Tip 2: Save Console Log
```bash
flutter logs > task9_test_log.txt
```

### Tip 3: Test Sambil Ngerjain Hal Lain
Karena ada waiting time 10 menit, test sambil ngerjain hal lain.

### Tip 4: Use Timer
Set timer 10 menit untuk reminder saat snooze.

---

## 🐛 TROUBLESHOOTING CEPAT

### Notifikasi Tidak Muncul?
1. Cek permission: `Settings > Apps > PillPal > Notifications`
2. Cek battery: `Settings > Apps > PillPal > Battery > Unrestricted`
3. Restart app: `flutter run --release`

### Shake Tidak Terdeteksi?
1. Shake lebih kuat (≥ 15 m/s²)
2. Cek console log: `"Shake detected! Magnitude: X.XX"`
3. Jika magnitude < 15 → Shake lebih kuat

### Console Log Tidak Muncul?
1. Restart flutter logs: `flutter logs`
2. Check device: `flutter devices`
3. Use adb: `adb logcat | grep ShakeDetector`

**Lebih lengkap:** Lihat `TASK9_TEST_HELPER.md`

---

## 📞 NEED HELP?

### Tanya Kiro:
```
"Bagaimana cara mulai testing Task 9?"
"File mana yang harus saya baca?"
"Saya mengalami masalah [X], bagaimana solusinya?"
"Console log tidak muncul, kenapa?"
```

### Check Files:
- Overview → `TESTING_REMINDER.md`
- Quick Test → `TASK9_QUICK_TEST_GUIDE.md` ⭐
- Troubleshooting → `TASK9_TEST_HELPER.md`
- File Overview → `TASK9_TESTING_FILES.md`

---

## ✅ CHECKLIST SEBELUM MULAI

- [ ] Sudah baca `TESTING_REMINDER.md`
- [ ] Sudah buka `TASK9_QUICK_TEST_GUIDE.md`
- [ ] Device fisik ready (Infinix X6871)
- [ ] Battery optimization disabled
- [ ] Notification permission granted
- [ ] Console log visible
- [ ] Punya waktu 20-25 menit

---

## 🎯 NEXT STEPS

### Setelah Testing:

#### Jika PASS (≥5/6 tests):
1. ✅ Catat hasil di `TASK9_QUICK_TEST_GUIDE.md`
2. ✅ Report ke Kiro: "Task 9 testing PASS (X/6)"
3. ✅ Lanjut ke Task 10 (Biometric Login)

#### Jika FAIL:
1. ❌ Catat bug di `TASK9_QUICK_TEST_GUIDE.md`
2. ❌ Report ke Kiro: "Task 9 testing FAIL: [bug description]"
3. ❌ Tunggu fix dari Kiro
4. ❌ Re-test setelah fix

---

## 📊 SUMMARY

```
┌─────────────────────────────────────────┐
│  TASK 9 TESTING - QUICK START           │
├─────────────────────────────────────────┤
│  1. Baca: TESTING_REMINDER.md (2 min)   │
│  2. Ikuti: TASK9_QUICK_TEST_GUIDE.md    │
│     (20 min) ⭐                          │
│  3. Jika masalah: TASK9_TEST_HELPER.md  │
│                                          │
│  Total: 22 menit                         │
│  Device: Infinix X6871 (physical)       │
│  Pass criteria: ≥5/6 tests               │
└─────────────────────────────────────────┘
```

---

**MULAI TESTING SEKARANG! 🚀**

**Step 1:** Buka `TASK9_QUICK_TEST_GUIDE.md`  
**Step 2:** Follow 6 test scenarios  
**Step 3:** Report hasil ke Kiro

---

*Created: 5 Mei 2026*  
*For: Task 9 - Accelerometer Sensor (S-01)*  
*Status: Ready for Testing ✅*
