# 📚 TASK 9 TESTING FILES - OVERVIEW

> **Panduan lengkap semua file testing untuk Task 9**  
> **Pilih file yang sesuai dengan kebutuhan Anda**

---

## 📁 FILE STRUCTURE

```
TPM/
├── TESTING_REMINDER.md              ⚠️ URGENT REMINDER
├── TASK9_QUICK_TEST_GUIDE.md        ⭐ RECOMMENDED (Quick)
├── TASK9_TEST_HELPER.md             🛠️ Helper & Troubleshooting
├── TASK9_TESTING_FILES.md           📚 This file (Overview)
└── docs/
    └── 03-testing/
        └── MANUAL_TESTING_TASK9_ACCELEROMETER.md  📋 Full Manual
```

---

## 📄 FILE DESCRIPTIONS

### 1. ⚠️ TESTING_REMINDER.md
**Location:** Root folder  
**Purpose:** Urgent reminder untuk testing Task 9  
**Audience:** Semua orang (quick overview)  
**Duration:** 2 menit baca

**Isi:**
- ⚠️ Urgent reminder (Task 9 belum di-test)
- 📋 Quick checklist (3 fase)
- 📚 Link ke dokumentasi lain
- ⚙️ Persiapan device
- 🔍 Cara lihat console log
- ✅ Acceptance criteria

**Kapan Baca:**
- Pertama kali mau test Task 9
- Butuh overview cepat
- Lupa apa yang harus di-test

---

### 2. ⭐ TASK9_QUICK_TEST_GUIDE.md (RECOMMENDED)
**Location:** Root folder  
**Purpose:** Panduan cepat testing (6 scenarios)  
**Audience:** Tester yang ingin cepat selesai  
**Duration:** 15-20 menit testing

**Isi:**
- 🎯 Tujuan test (6 fitur)
- 📱 Persiapan (5 menit)
- 🧪 6 Test scenarios (10 menit)
- 📊 Hasil test template
- 🐛 Bug report template
- 💡 Tips testing

**Kapan Pakai:**
- ✅ **RECOMMENDED** untuk testing pertama kali
- ✅ Ingin cepat selesai (20 menit)
- ✅ Sudah paham cara kerja fitur
- ✅ Butuh panduan step-by-step

**Kelebihan:**
- ✅ Cepat (20 menit vs 35 menit)
- ✅ Fokus ke fitur utama
- ✅ Step-by-step jelas
- ✅ Ada template hasil

---

### 3. 🛠️ TASK9_TEST_HELPER.md
**Location:** Root folder  
**Purpose:** Helper untuk troubleshooting & tips  
**Audience:** Tester yang mengalami masalah  
**Duration:** Reference (baca saat butuh)

**Isi:**
- ⚡ Quick start (3 langkah)
- 🕐 Waktu testing calculator
- 🎯 Parallel testing guide
- 🔍 Console log cheat sheet
- 🐛 Troubleshooting (4 problems)
- 📱 Device settings checklist
- 🎮 Test scenarios quick reference
- 💡 Pro tips

**Kapan Pakai:**
- ❌ Notifikasi tidak muncul
- ❌ Shake tidak terdeteksi
- ❌ Console log tidak muncul
- ❌ App force stopped
- 💡 Ingin test lebih efisien (parallel testing)
- 💡 Butuh cheat sheet

**Kelebihan:**
- ✅ Troubleshooting lengkap
- ✅ Parallel testing guide (hemat waktu)
- ✅ Console log cheat sheet
- ✅ Pro tips

---

### 4. 📋 MANUAL_TESTING_TASK9_ACCELEROMETER.md
**Location:** `docs/03-testing/`  
**Purpose:** Full testing manual (15 test cases)  
**Audience:** Tester yang ingin test lengkap  
**Duration:** 25-30 menit testing

**Isi:**
- 📋 Test overview
- 🧪 15 Test cases (6 fase)
  - FASE 1: Shake Detection (3 tests)
  - FASE 2: Snooze Count (4 tests)
  - FASE 3: Button Snooze (2 tests)
  - FASE 4: Confirm Taken (2 tests)
  - FASE 5: Error Handling (2 tests)
  - FASE 6: Timing (2 tests)
- 📊 Test summary table
- 🎯 Acceptance criteria (SKPL S-01)
- 🐛 Bug report form
- 💡 Improvement suggestions
- ✅ Sign-off form

**Kapan Pakai:**
- ✅ Ingin test lengkap & detail
- ✅ Butuh dokumentasi formal
- ✅ Testing untuk QA/client
- ✅ Punya waktu 30 menit

**Kelebihan:**
- ✅ Lengkap (15 test cases)
- ✅ Formal (ada sign-off)
- ✅ Detail (setiap edge case)
- ✅ Dokumentasi lengkap

---

## 🎯 WHICH FILE TO USE?

### Scenario 1: Pertama Kali Test Task 9
**Recommended:** `TASK9_QUICK_TEST_GUIDE.md`  
**Why:** Cepat, jelas, step-by-step

**Flow:**
1. Baca `TESTING_REMINDER.md` (2 min) - Overview
2. Ikuti `TASK9_QUICK_TEST_GUIDE.md` (20 min) - Testing
3. Jika ada masalah → Buka `TASK9_TEST_HELPER.md` - Troubleshooting

---

### Scenario 2: Ingin Test Cepat (< 20 menit)
**Recommended:** `TASK9_QUICK_TEST_GUIDE.md`  
**Why:** Hanya 6 test scenarios, fokus ke fitur utama

**Tips:**
- Gunakan parallel testing (buat 3 jadwal sekaligus)
- Skip waiting time (buat jadwal baru untuk setiap test)
- Lihat `TASK9_TEST_HELPER.md` → Parallel Testing section

---

### Scenario 3: Ingin Test Lengkap (30 menit)
**Recommended:** `MANUAL_TESTING_TASK9_ACCELEROMETER.md`  
**Why:** 15 test cases, cover semua edge cases

**Flow:**
1. Baca `TESTING_REMINDER.md` (2 min) - Overview
2. Ikuti `MANUAL_TESTING_TASK9_ACCELEROMETER.md` (30 min) - Full testing
3. Jika ada masalah → Buka `TASK9_TEST_HELPER.md` - Troubleshooting

---

### Scenario 4: Mengalami Masalah Saat Testing
**Recommended:** `TASK9_TEST_HELPER.md`  
**Why:** Troubleshooting lengkap untuk 4 masalah umum

**Common Problems:**
- Notifikasi tidak muncul → Section "Problem 1"
- Shake tidak terdeteksi → Section "Problem 2"
- App force stopped → Section "Problem 3"
- Console log tidak muncul → Section "Problem 4"

---

### Scenario 5: Ingin Test Efisien (Parallel)
**Recommended:** `TASK9_TEST_HELPER.md` → Parallel Testing  
**Why:** Hemat waktu dari 35 menit → 20 menit

**How:**
1. Buat 3 jadwal sekaligus (interval 2 menit)
2. Test semua scenarios dalam 20 menit
3. Lihat section "Parallel Testing" di helper

---

## 📊 COMPARISON TABLE

| File | Duration | Test Cases | Detail Level | Audience |
|------|----------|------------|--------------|----------|
| TESTING_REMINDER.md | 2 min | - | Overview | Everyone |
| TASK9_QUICK_TEST_GUIDE.md ⭐ | 20 min | 6 | Medium | Tester (Quick) |
| TASK9_TEST_HELPER.md | Reference | - | Helper | Troubleshooter |
| MANUAL_TESTING_TASK9_ACCELEROMETER.md | 30 min | 15 | High | Tester (Full) |

---

## 🚀 RECOMMENDED WORKFLOW

### For First-Time Tester:

```
1. Read: TESTING_REMINDER.md (2 min)
   ↓
2. Follow: TASK9_QUICK_TEST_GUIDE.md (20 min)
   ↓
3. If problem → Check: TASK9_TEST_HELPER.md
   ↓
4. Report hasil ke Kiro
```

### For Experienced Tester:

```
1. Follow: TASK9_QUICK_TEST_GUIDE.md (20 min)
   ↓ (if need more detail)
2. Follow: MANUAL_TESTING_TASK9_ACCELEROMETER.md (30 min)
   ↓
3. Report hasil ke Kiro
```

### For Troubleshooting:

```
1. Check: TASK9_TEST_HELPER.md → Troubleshooting section
   ↓
2. If not solved → Ask Kiro
```

---

## 💡 PRO TIPS

### Tip 1: Start with Quick Guide
Mulai dengan `TASK9_QUICK_TEST_GUIDE.md` untuk test cepat. Jika butuh lebih detail, lanjut ke full manual.

### Tip 2: Keep Helper Open
Buka `TASK9_TEST_HELPER.md` di tab terpisah untuk troubleshooting cepat.

### Tip 3: Use Parallel Testing
Lihat section "Parallel Testing" di helper untuk hemat waktu.

### Tip 4: Save Console Log
```bash
flutter logs > task9_test_log.txt
```
Simpan log untuk dokumentasi.

### Tip 5: Test Bareng Teman
Satu orang test, satu orang catat hasil.

---

## 📞 NEED HELP?

### Tanya Kiro:
```
"File mana yang harus saya baca untuk test Task 9?"
"Saya ingin test cepat, pakai file apa?"
"Saya mengalami masalah [X], bagaimana solusinya?"
"Bagaimana cara parallel testing?"
```

### Check Files:
- Overview → `TESTING_REMINDER.md`
- Quick Test → `TASK9_QUICK_TEST_GUIDE.md` ⭐
- Troubleshooting → `TASK9_TEST_HELPER.md`
- Full Test → `MANUAL_TESTING_TASK9_ACCELEROMETER.md`

---

## ✅ QUICK DECISION TREE

```
Pertama kali test?
├─ YES → TASK9_QUICK_TEST_GUIDE.md ⭐
└─ NO
   ├─ Punya waktu < 20 min?
   │  ├─ YES → TASK9_QUICK_TEST_GUIDE.md (parallel testing)
   │  └─ NO → MANUAL_TESTING_TASK9_ACCELEROMETER.md
   └─ Ada masalah?
      └─ YES → TASK9_TEST_HELPER.md
```

---

**Happy Testing! 🚀**

*Created: 5 Mei 2026*  
*For: Task 9 - Accelerometer Sensor (S-01)*
