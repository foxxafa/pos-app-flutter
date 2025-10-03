# Google Play Store Yayınlama Bilgileri

## ⚠️ ÇOK ÖNEMLİ - BU BİLGİLERİ GÜVENLİ BİR YERDE SAKLAYIN

### Uygulama Bilgileri
- **Package Name**: `com.rowhub.sales`
- **Uygulama Adı**: Rowhub Sales

### Keystore Bilgileri
Bu bilgiler uygulama güncellemeleri için gereklidir. Kaybederseniz uygulamanızı güncelleyemezsiniz!

- **Keystore Dosyası**: `android/app/upload-keystore.jks`
- **Keystore Şifresi**: `MyApp2025`
- **Key Alias**: `upload`
- **Key Şifresi**: `MyApp2025` (keystore şifresiyle aynı)

### Önemli Dosyalar
1. **android/app/upload-keystore.jks** - Uygulama imzalama anahtarı (BU DOSYAYI YEDEKLEYİN!)
2. **android/keystore.properties** - Şifreleri içeren dosya (GIT'E EKLEMEYİN!)

### Build Komutu
Google Play için AAB dosyası oluşturmak için:
```bash
flutter build appbundle
```

Oluşturulan dosya: `build/app/outputs/bundle/release/app-release.aab`

### Güvenlik Notları
- ⚠️ `upload-keystore.jks` dosyasını mutlaka yedekleyin (USB, cloud vb.)
- ⚠️ `keystore.properties` dosyasını asla Git'e commit etmeyin
- ⚠️ Şifreyi güvenli bir şifre yöneticisinde saklayın
- ⚠️ Bu anahtarı kaybederseniz, uygulamayı güncelleyemezsiniz!

### İlk Yayın Bilgileri
- **Release Name**: 1.0.0
- **Release Notes**: Initial release of Rowhub Sales POS application
- **İlk Yayın Tarihi**: 2 Ekim 2025

---
**Not**: Her uygulama güncellemesinde aynı keystore dosyası ve şifrelerle imzalamalısınız.