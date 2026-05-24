# UangApp — Financial Tracker (Flutter + Google Sheets + Groq AI)

Real-time personal finance tracker using **Google Sheets** as the database, **Google Sign-In** for user OAuth, and **Groq AI** (Llama 3.3) for voice/text transaction parsing and monthly insights.

## Features

- Google Sign-In with Sheets + Drive scopes
- Auto-find or create `Flutter_Finance_Tracker` spreadsheet
- Offline cache (`shared_preferences`) + sync queue
- AI voice/text input (`speech_to_text` + Groq)
- AI monthly report in Indonesian
- BLoC state management, clean folder structure

## Setup

### 1. Dependencies

```bash
flutter pub get
```

### 2. Environment (`.env`)

Copy `.env.example` to `.env` and set:

```
GROQ_API_KEY=your_actual_key
GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com
```

`GOOGLE_SERVER_CLIENT_ID` harus **OAuth Client ID tipe Web application** (Credentials → Create credentials → OAuth client ID → Web application). Tanpa ini, login Google di Android gagal dengan error `serverClientId must be provided`.

> Model di-hardcode: `llama-3.3-70b-versatile` di `ai_service.dart` (hanya API key dari `.env`).

`GOOGLE_SERVER_CLIENT_ID` harus **OAuth Client ID tipe Web application** (Credentials → Create credentials → OAuth client ID  → Web application). **Jangan** pakai Client ID tipe Desktop/Android/iOS — itu penyebab login gagal setelah memilih akun.

### 3. Google Cloud Console

1. Create a project at [Google Cloud Console](https://console.cloud.google.com/).
2. Enable **Google Sheets API** and **Google Drive API**.
3. Configure **OAuth consent screen** (External) and add test users if in testing mode.
4. Create **OAuth 2.0 Client IDs**:
   - **Android**: package `com.uangapp.uangapp`, SHA-1 from your keystore (`keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android`)
   - **iOS**: bundle ID `com.uangapp.uangapp`
   - **Web** (required for Android): copy Client ID ke `GOOGLE_SERVER_CLIENT_ID` di `.env`

### 4. Android — `android/app/src/main/AndroidManifest.xml`

Already added:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
```

### 5. iOS — `ios/Runner/Info.plist`

Already added:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Aplikasi membutuhkan mikrofon untuk input suara transaksi keuangan.</string>
<key>NSSpeechRecognitionUsageDescription</key>
<string>Aplikasi membutuhkan pengenalan suara untuk mengubah ucapan menjadi transaksi.</string>
```

### 6. Run

```bash
flutter run
```

### Build gagal: `different roots` (C: vs E:)

Jika proyek ada di drive lain dari Pub cache (`C:\Users\...\Pub\Cache`), Kotlin incremental bisa gagal. Sudah dinonaktifkan di `android/gradle.properties`. Bersihkan lalu build ulang:

```bash
flutter clean
cd android
./gradlew --stop
cd ..
flutter pub get
flutter run
```

Alternatif: pindahkan proyek ke `C:` atau set `PUB_CACHE` ke drive yang sama dengan proyek.

### Login Google gagal setelah pindah laptop / error 28444

Setiap komputer punya **debug keystore** berbeda → SHA-1 berbeda. Google menolak login jika SHA-1 laptop baru belum didaftarkan.

1. Cek SHA-1 laptop ini:
   ```bash
   cd android
   gradlew signingReport
   ```
   Salin baris **SHA1** di variant `debug`.

2. [Google Cloud Console → Credentials](https://console.cloud.google.com/apis/credentials):
   - Edit **OAuth client Android** (`com.uangapp.uangapp`) → tambahkan SHA-1 dari langkah 1 (bisa beberapa SHA-1).
   - Pastikan ada **OAuth client Web** → salin Client ID ke `GOOGLE_SERVER_CLIENT_ID` di `.env`.

3. **OAuth consent screen** → tambahkan email Google Anda sebagai **Test user** (jika app masih Testing).

4. Tunggu 5–10 menit, lalu uninstall app di HP dan `flutter run` lagi.

Contoh SHA-1 laptop dev saat ini: `F2:CB:E6:87:EE:25:C1:87:2B:30:94:AD:17:B4:FF:AA:EF:F3:28:10` (ganti dengan hasil `signingReport` Anda).

## Google Sheet structure

Spreadsheet: `Flutter_Finance_Tracker`  
Tab: `Transactions`

| id | date | amount | category | description | type | created_at |
|----|------|--------|----------|-------------|------|------------|

Dates are stored as `YYYY-MM-DD` / ISO datetime strings to avoid regional formatting issues.

## Project structure

```
lib/
  core/          # constants, theme, utils
  models/        # Transaction, ParsedTransaction
  services/      # auth, sheets, ai (Groq), cache, sync, connectivity
  features/
    auth/        # BLoC + login screen
    transactions/# BLoC + home + AI input
    insights/    # BLoC + AI monthly report
  app.dart
  main.dart
```

## Architecture notes

- **401/403**: `AuthenticatedApiRunner` re-authenticates once and retries.
- **Offline**: reads cache; new rows go to sync queue and flush when online.
- **AI parse failure**: falls back to manual entry in the bottom sheet.
- **Google OAuth** and **Groq API** are fully separate — never mix credentials.

## Groq rate limits

Jika muncul error kuota/rate limit, tunggu sebentar atau gunakan **input manual**. Cek usage di [Groq Console](https://console.groq.com/).
