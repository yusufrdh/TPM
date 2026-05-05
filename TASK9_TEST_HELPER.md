# 🛠️ TASK 9 TEST HELPER

> **Helper untuk mempermudah testing Task 9**  
> **Berisi:** Cara cepat buat jadwal test, troubleshooting, cheat sheet

---

## ⚡ QUICK START (3 LANGKAH)

### 1. Build & Run App
```bash
cd "D:\Kuliah\Semester 6\Mobile\TPM"
flutter clean
flutter pub get
flutter run --release
```

### 2. Buat Jadwal Test
**Cara Cepat:**
1. Buka app → Tap "+" (floating button)
2. Isi form:
   ```
   Nama Obat: Test Shake
   Jenis: Tablet
   Stok: 10
   Waktu: [JAM SEKARANG + 2 MENIT]
   Dosis: 1
   Satuan: tablet
   Frekuensi: Setiap Hari
   ```
3. Tap "Simpan Jadwal"

**Contoh:**
- Sekarang: 14:30 → Set waktu: 14:32
- Sekarang: 09:15 → Set waktu: 09:17
- Sekarang: 20:45 → Set waktu: 20:47

### 3. Tunggu & Test
- Tunggu 2 menit
- Notifikasi muncul
- Shake device
- Observe hasil

---

## 🕐 WAKTU TESTING CALCULATOR

### Berapa Lama Testing?

| Scenario | Waktu | Total |
|----------|-------|-------|
| Setup (build + jadwal) | 5 min | 5 min |
| Test 1: Shake #1 | 2 min | 7 min |
| Wait snooze (10 min) | 10 min | 17 min |
| Test 2: Shake #2 | 2 min | 19 min |
| Wait snooze (10 min) | 10 min | 29 min |
| Test 3: Shake #3 | 2 min | 31 min |
| Test 4-6: Button & edge | 5 min | 36 min |

**Total:** ~35 menit (full test)

### Cara Percepat Testing:
1. **Skip waiting** → Buat jadwal baru untuk setiap test (15 menit)
2. **Parallel testing** → Buat 3 jadwal sekaligus (20 menit)

---

## 🎯 PARALLEL TESTING (RECOMMENDED)

**Cara:** Buat 3 jadwal sekaligus dengan interval 2 menit

### Setup (5 menit):
1. **Jadwal 1:** Waktu = Sekarang + 2 menit (untuk Test 1-3)
2. **Jadwal 2:** Waktu = Sekarang + 4 menit (untuk Test 4)
3. **Jadwal 3:** Waktu = Sekarang + 6 menit (untuk Test 5-6)

### Execution (15 menit):
- **Menit 2:** Notif 1 muncul → Test shake #1, #2, #3
- **Menit 4:** Notif 2 muncul → Test button snooze
- **Menit 6:** Notif 3 muncul → Test "Sudah Minum" & weak shake

**Total:** 20 menit (vs 35 menit)

---

## 🔍 CONSOLE LOG CHEAT SHEET

### Cara Lihat Log:

#### Android Studio:
```
1. Tab "Run" (bawah)
2. Klik filter icon (funnel)
3. Ketik: ShakeDetector
```

#### VS Code:
```
1. View > Debug Console
2. Ctrl+F → Search: ShakeDetector
```

#### Command Line:
```bash
# Real-time
flutter logs | grep -E "ShakeDetector|NotificationService"

# Save to file
flutter logs > test_log.txt
```

### Log yang Harus Muncul:

#### ✅ GOOD (Expected):
```
✅ Notification scheduled for Test Shake at 14:32
🔔 Starting shake detector for schedule 1
[ShakeDetector] Shake detected! Magnitude: 18.45 m/s²
[ShakeDetector] Triggering snooze (count: 1/3)
⏰ Snoozing notification for schedule 1
```

#### ❌ BAD (Error):
```
❌ Error scheduling notification: [error]
⚠️ NotificationService not initialized
⚠️ Sensor not available
❌ Schedule not found: 1
```

---

## 🐛 TROUBLESHOOTING

### Problem 1: Notifikasi Tidak Muncul

**Symptoms:**
- Jadwal sudah dibuat
- Waktu sudah lewat
- Notifikasi tidak muncul

**Solutions:**
1. **Cek permission:**
   ```
   Settings > Apps > PillPal > Notifications > Allow
   ```

2. **Cek battery optimization:**
   ```
   Settings > Apps > PillPal > Battery > Unrestricted
   ```

3. **Cek console log:**
   ```
   Cari: "Error scheduling notification"
   ```

4. **Restart app:**
   ```bash
   flutter run --release
   ```

---

### Problem 2: Shake Tidak Terdeteksi

**Symptoms:**
- Notifikasi muncul
- Shake device
- Tidak ada efek

**Solutions:**
1. **Shake lebih kuat:**
   - Threshold: ≥ 15 m/s²
   - Seperti mengocok botol

2. **Cek console log:**
   ```
   Cari: "Shake detected! Magnitude: X.XX"
   ```
   - Jika magnitude < 15 → Shake lebih kuat
   - Jika tidak ada log → Sensor issue

3. **Cek sensor availability:**
   ```dart
   // Di console log, cari:
   "Sensor not available"
   ```

4. **Restart shake detector:**
   - Tap "Sudah Minum"
   - Buat jadwal baru

---

### Problem 3: App Force Stopped

**Symptoms:**
- App tidak jalan di background
- Notifikasi muncul tapi shake tidak jalan

**Solutions:**
1. **Jangan force stop app:**
   ```
   Settings > Apps > PillPal > Force Stop ❌
   ```

2. **Minimize app (OK):**
   - Home button ✅
   - Recent apps ✅

3. **Battery optimization:**
   ```
   Settings > Apps > PillPal > Battery > Unrestricted
   ```

---

### Problem 4: Console Log Tidak Muncul

**Symptoms:**
- App jalan
- Tidak ada log di console

**Solutions:**
1. **Restart flutter logs:**
   ```bash
   flutter logs
   ```

2. **Check device connection:**
   ```bash
   flutter devices
   adb devices
   ```

3. **Use adb logcat:**
   ```bash
   adb logcat | grep -E "ShakeDetector|NotificationService"
   ```

---

## 📱 DEVICE SETTINGS CHECKLIST

### Before Testing:
- [ ] **Notification Permission:** Allowed
- [ ] **Exact Alarm Permission:** Allowed (Android 12+)
- [ ] **Battery Optimization:** Unrestricted
- [ ] **Do Not Disturb:** OFF
- [ ] **App Running:** Foreground or Background (NOT force-stopped)
- [ ] **Console Log:** Visible

### Cara Cek:
```
Settings > Apps > PillPal-AI > Permissions
Settings > Apps > PillPal-AI > Battery
Settings > Apps > PillPal-AI > Notifications
```

---

## 🎮 TEST SCENARIOS QUICK REFERENCE

### Test 1: Shake #1
```
Setup: Buat jadwal (waktu +2 min)
Action: Shake device
Expected: Notif hilang, muncul lagi 10 min
Log: "Triggering snooze (count: 1/3)"
```

### Test 2: Shake #2
```
Setup: Lanjut dari Test 1 (tunggu 10 min)
Action: Shake device
Expected: Notif hilang, muncul lagi 10 min
Log: "Triggering snooze (count: 2/3)"
```

### Test 3: Shake #3 (Max)
```
Setup: Lanjut dari Test 2 (tunggu 10 min)
Action: Shake device
Expected: Detector stop, no more snooze
Log: "Max snooze count reached (3/3)"
```

### Test 4: Button Snooze
```
Setup: Buat jadwal baru (waktu +2 min)
Action: Tap "Snooze 10 menit" button
Expected: Notif hilang, muncul lagi 10 min
Log: "Snooze button tapped"
```

### Test 5: Sudah Minum
```
Setup: Buat jadwal baru (waktu +2 min)
Action: Tap "Sudah Minum" button
Expected: Notif hilang, detector stop
Log: "Stopping shake detector"
```

### Test 6: Weak Shake
```
Setup: Buat jadwal baru (waktu +2 min)
Action: Goyangkan pelan-pelan
Expected: Notif TIDAK hilang
Log: No "Shake detected" log
```

---

## 📊 TEST RESULT TEMPLATE

### Copy-paste ini untuk report hasil:

```markdown
## TASK 9 TEST RESULTS

**Date:** 5 Mei 2026
**Tester:** [Nama]
**Device:** Infinix X6871
**Duration:** ___ menit

### Results:
- [ ] Test 1: Shake #1 → PASS / FAIL
- [ ] Test 2: Shake #2 → PASS / FAIL
- [ ] Test 3: Shake #3 → PASS / FAIL
- [ ] Test 4: Button Snooze → PASS / FAIL
- [ ] Test 5: Sudah Minum → PASS / FAIL
- [ ] Test 6: Weak Shake → PASS / FAIL

**Pass Rate:** ___/6 (___%)

### Bugs Found:
1. [Bug description]
2. [Bug description]

### Notes:
[Additional notes]

### Status:
[ ] APPROVED (≥5/6 pass)
[ ] REJECTED (need fix)
```

---

## 💡 PRO TIPS

### Tip 1: Use Multiple Schedules
Buat 3-5 jadwal sekaligus dengan interval 2 menit untuk test lebih cepat.

### Tip 2: Save Console Log
```bash
flutter logs > task9_test_log.txt
```
Simpan log untuk dokumentasi.

### Tip 3: Test di Waktu Senggang
Karena ada waiting time 10 menit, test sambil ngerjain hal lain.

### Tip 4: Use Timer
Set timer 10 menit untuk reminder saat snooze.

### Tip 5: Test Bareng Teman
Satu orang test, satu orang catat hasil.

---

## 📞 NEED HELP?

### Tanya Kiro:
```
"Console log tidak muncul, kenapa?"
"Shake detection tidak jalan, kenapa?"
"Notifikasi tidak muncul, kenapa?"
"Saya menemukan bug: [...]"
```

### Check Documentation:
- `TASK9_QUICK_TEST_GUIDE.md` - Quick guide
- `docs/03-testing/MANUAL_TESTING_TASK9_ACCELEROMETER.md` - Full manual
- `TESTING_REMINDER.md` - Reminder & checklist

---

**Happy Testing! 🚀**

*Created: 5 Mei 2026*
