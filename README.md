# Remoview Mobile 📱🎬 (BLM4537 Project)
Video Linki: https://www.youtube.com/watch?v=l58Ix7Cl2M8
PDF Linki: https://drive.google.com/file/d/1M1VUgzXDOGuvRVCYbn5Xlnu-8cntssG9/view?usp=sharing

Remoview Mobile; Remoview backend (ASP.NET Core Web API) ile haberleşen, kullanıcıların mobil cihaz üzerinden film keşfetmesini, film detaylarını görmesini, puan vermesini, yorum yapmasını ve favorilerini yönetmesini sağlayan mobil uygulamadır.

Mobil uygulama, backend’de bulunan **moderasyon sistemine** uyumludur:
- Kullanıcı film/yorum eklediğinde içerik **Pending** olarak backend’e gider.
- **Approved** olan filmler ana listede görünür.
- **Approved** olan yorumlar film detayında görünür.

---

## Özellikler

- ✅ Kayıt ol / giriş yap (JWT)
- ✅ Film listesi (yalnızca Approved)
- ✅ Film detay sayfası (yalnızca Approved + yorumlarda Approved)
- ✅ Film ekleme (Pending olarak gönderir)
- ✅ Yorum ekleme (Pending olarak gönderir)
- ✅ Puan verme (Approved film için)
- ✅ Favori ekleme/çıkarma
- ✅ Profil ekranında favorileri görüntüleme
- ✅ Token saklama (persist)

---

## Kullanılan Teknolojiler

> **Flutter tabanlı mobil uygulama şablonu**

- Flutter (Dart)
- HTTP API entegrasyonu (REST)
- JWT Authentication
- Local storage (token saklama)
  - SharedPreferences / SecureStorage (projede hangisi kullanıldıysa)

---

## Backend Bağımlılığı

Mobil uygulama tek başına çalışmaz; Remoview backend’in çalışıyor olması gerekir.

Backend örnek:
- API Base URL: `https://localhost:xxxx` veya `http://10.0.2.2:xxxx` (Android emulator için)

> Android Emulator’da `localhost` backend’i görmez.  
> Local backend’e bağlanmak için genelde:
- Android Emulator: `http://10.0.2.2:PORT`
- iOS Simulator: `http://localhost:PORT`
- Fiziksel cihaz: aynı Wi-Fi’da PC’nin IP’si: `http://192.168.x.x:PORT`

---

## Kurulum ve Çalıştırma

### 1) Gereksinimler
- Flutter SDK
- Android Studio (SDK + Emulator) veya Xcode (iOS için)
- Remoview Backend (çalışır durumda)
- Git

### 2) Paketleri yükle
Proje klasöründe:

```bash
flutter pub get
