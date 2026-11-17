# Soundify 🎧

اپلیکیشن استریم موسیقی **Soundify** با Flutter؛ ساخته‌شده برای پروژهٔ میان‌ترم درس برنامه‌نویسی موبایل. این پروژه سه بخش اصلی را یکپارچه می‌کند: **احراز هویت امن**، **ارتباط با API سرور** و **پخش موسیقی در پس‌زمینه** با رابط کاربری فارسی و راست‌چین.

> API سرور: `https://soundify.easyfound.ir/api/v1`  
> مستندات: `https://soundify.easyfound.ir/docs`

---

## ✨ امکانات

### ۱) احراز هویت و امنیت
- ثبت‌نام و ورود با اعتبارسنجی کامل ایمیل، نام کاربری و رمز عبور
- ورود/تأیید با کد یک‌بارمصرف (OTP) و شمارش معکوس ارسال مجدد
- فراموشی رمز عبور در دو مرحله (دریافت کد و ثبت رمز جدید)
- ذخیرهٔ Access/Refresh Token فقط در **Android Keystore** با `flutter_secure_storage` (نه SharedPreferences)
- تمدید خودکار توکن با Interceptor و صف‌بندی درخواست‌ها؛ خروج ناخواسته رخ نمی‌دهد
- فعال‌سازی و ورود بیومتریک (اثر انگشت/چهره) با `local_auth`
- بررسی روت و شبیه‌ساز با کانال بومی Kotlin و نمایش وضعیت در پروفایل

### ۲) شبکه و API
- کلاینت `dio` با Base URL، تایم‌اوت، مدیریت خطاهای فارسی و پیام‌های Retry
- دریافت آهنگ‌های منتخب و کاتالوگ کامل (۳۳۱ قطعه) همراه کاور، خواننده، آلبوم و مدت
- جست‌وجوی زنده با Debounce روی نام اثر/خواننده
- CRUD کامل پلی‌لیست: ساخت، ویرایش نام/توضیحات، حذف، افزودن و حذف آهنگ
- علاقه‌مندی‌ها با به‌روزرسانی خوش‌بینانه (Optimistic UI) و همگام‌سازی فوری با سرور
- حالت‌های Loading، Empty، Error و Retry در همهٔ صفحات

### ۳) پخش صدا
- استریم آنلاین با پشتیبانی HTTP 206 (Range) از `just_audio`
- کنترل Play/Pause/Next/Previous، اسلایدر Seek، زمان سپری‌شده/کل و پخش خودکار قطعهٔ بعد
- مینی‌پلیر شناور بالای نوار پایین در تمام صفحات
- پخش در پس‌زمینه و با صفحهٔ خاموش (`just_audio_background` + `audio_service`)
- اعلان رسانهٔ اندروید با کاور، عنوان، خواننده و کنترل‌های پخش/جابه‌جایی؛ صفحهٔ قفل
- پلیر تمام‌صفحه با کاور بزرگ، پس‌زمینهٔ بلور، اکولایزر متحرک و صف پخش

### ۴) رابط کاربری
- اسپلش برنددار با لوگوی اختصاصی و انیمیشن
- آنبوردینگ سه‌مرحله‌ای فقط در اولین اجرا (ذخیرهٔ وضعیت در SharedPreferences)
- صفحات خانه، جست‌وجو، کتابخانه (تب پلی‌لیست/علاقه‌مندی)، جزئیات پلی‌لیست، پروفایل و تنظیمات
- طراحی Dark-first، پشتیبانی از Light Mode، فونت وزیرمتن، RTL کامل و اعداد فارسی

---

## 🧱 معماری

```
lib/
├── app.dart                     # MaterialApp، تم، AppRoot (Splash/Onboarding/Auth/Main/Biometric)
├── main.dart                    # راه‌اندازی JustAudioBackground، سرویس‌ها، Providerها
├── core/
│   ├── config/                  # آدرس API، تایم‌اوت‌ها، کانال اعلان
│   ├── network/                 # ApiClient (Dio + AuthInterceptor + Refresh) و ApiException
│   ├── services/                # DeviceSecurityService
│   ├── storage/                 # SecureStore (Keystore) و PreferencesService
│   ├── theme/                   # رنگ‌ها و تم روشن/تاریک
│   └── utils/                   # اعتبارسنجی، فرمت‌دهنده، JSON helpers
├── models/                      # Track, Playlist, User, TokenPair, ApiPage, ...
├── state/                       # AuthProvider, PlayerProvider, CatalogProvider,
│                                # SearchProvider, LibraryProvider, SettingsProvider
├── screens/
│   ├── auth/                    # ورود، ثبت‌نام، OTP، فراموشی رمز + AuthFlow
│   ├── home/ search/ library/ profile/ player/
│   ├── onboarding_screen.dart, splash_screen.dart, biometric_lock_screen.dart
├── widgets/                     # MainShell, MiniPlayer, CoverArt, دکمه/فیلد/وضعیت‌ها
└── android/                     # Manifest، سرویس پخش، کانال امنیت، آیکون‌ها، اسپلش
```

**مدیریت وضعیت:** `provider` + `ChangeNotifier`؛ هر دامنه Provider مستقل دارد و `LibraryProvider` با تغییر وضعیت احراز هویت همگام می‌شود.

**جریان نشست:** `SecureStore → ApiClient(interceptor) → AuthProvider → AppRoot`  
در خطای 401، توکن Refresh به‌صورت خودکار چرخانده می‌شود؛ در صورت شکست، کاربر با پیام روشن به ورود هدایت می‌شود.

---

## 📚 کتابخانه‌ها

| کتابخانه | کاربرد |
|---|---|
| `dio` | کلاینت HTTP، Interceptor و مدیریت خطا |
| `provider` | مدیریت وضعیت |
| `flutter_secure_storage` | ذخیرهٔ امن توکن‌ها (Keystore) |
| `shared_preferences` | تنظیمات غیرحساس (تم، آنبوردینگ، جستجوهای اخیر) |
| `just_audio` | پخش/استریم صدا |
| `just_audio_background` | پخش پس‌زمینه و اعلان رسانه |
| `audio_session` | پیکربندی نشست صوتی |
| `local_auth` | بیومتریک |
| `device_info_plus` | اطلاعات دستگاه (شبیه‌ساز/مدل) |
| `cached_network_image` | کش کاور آلبوم |
| `intl` | قالب‌بندی تاریخ/عدد فارسی |
| `material_ui` | ویجت‌های Material در Flutter 3.50 |

---

## 👤 حساب نمایشی برای تست

برای تست سریع جریان اصلی (بدون نیاز به ایمیل واقعی و OTP) می‌توانید از حساب نمایشی زیر استفاده کنید:

| فیلد | مقدار |
|---|---|
| ایمیل | `soundifyqa74615@euploading.com` |
| رمز عبور | `TestPass123!` |

> این حساب آزمایشی است و ممکن است توسط سایر تست‌کنندگان تغییر کند. برای تست کامل OTP، یک حساب با ایمیل واقعی بسازید.

---

## 🚀 اجرا

### پیش‌نیازها
- Flutter **3.50+** (Dart 3.14+)
- JDK **17**
- Android SDK 36، Build Tools 36.0.0
- دستگاه/شبیه‌ساز Android (minSdk 24، هدف arm64-v8a)

### نصب و اجرا
```bash
git clone <repository-url>
cd soundify
flutter pub get
flutter run
```

اگر شبکهٔ شما به `pub.dev` یا مخازن Google دسترسی ندارد، از میرورها استفاده کنید:
```powershell
$env:PUB_HOSTED_URL='https://pub.flutter-io.cn'
$env:FLUTTER_STORAGE_BASE_URL='https://storage.flutter-io.cn'
```
پروژه از پیش برای مخازن Maven گوگل، میرور Aliyun را در `android/settings.gradle.kts` و `android/build.gradle.kts` تنظیم کرده است.

### ساخت APK ریلیز
```bash
flutter build apk --release --target-platform android-arm64
```
خروجی:
```
build/app/outputs/flutter-apk/app-release.apk          # کامل (چند ABI)
build/app/outputs/flutter-apk/app-arm64-v8a-release.apk # مخصوص arm64-v8a
```
نسخهٔ آمادهٔ تحویل در پوشهٔ `dist/` نیز کپی شده است:
```
dist/Soundify-1.0.0-arm64-v8a.apk
dist/Soundify-1.0.0-universal.apk
```
> نسخهٔ فعلی با کلید دیباگ امضا شده تا بدون تنظیم Keystore روی دستگاه نصب شود. برای انتشار در Google Play کلید ریلیز اختصاصی بسازید.

### تست
```bash
flutter test
flutter analyze
```

---

## 🔐 نکات امنیتی
- توکن‌ها هرگز در `SharedPreferences` نوشته نمی‌شوند؛ فقط `flutter_secure_storage` با پشتوانهٔ Keystore.
- خروجی لاگ‌ها فاقد توکن/رمز است.
- Refresh Token هنگام خروج و در صورت رد شدن، از حافظه امن پاک می‌شود.
- بیومتریک فقط برای بازگشایی نشست ذخیره‌شده استفاده می‌شود و در صورت نبود سخت‌افزار، خودکار غیرفعال می‌شود.
- بررسی روت/شبیه‌ساز سمت بومی (Kotlin MethodChannel) انجام می‌شود و صرفاً نمایشی/هشدار است.
- `INTERNET`، `WAKE_LOCK`، `FOREGROUND_SERVICE_MEDIA_PLAYBACK`، `USE_BIOMETRIC` و اعلان‌ها در Manifest اعلام شده‌اند.

---

## 🎵 جریان پخش و اعلان
`PlayerProvider` یک `AudioPlayer` واحد را مدیریت می‌کند. برای هر آهنگ یک `AudioSource.uri` با تگ `MediaItem` (عنوان، خواننده، آلبوم، کاور و مدت) ساخته می‌شود و `setAudioSources` صف را در اختیار سرویس پس‌زمینه قرار می‌دهد. در نتیجه:
- پخش با خاموش شدن صفحه/خروج از اپ ادامه دارد.
- اعلان رسانه با کاور و کنترل‌ها نمایش داده می‌شود.
- Next/Previous و پایان خودکار قطعه توسط صف مدیریت می‌شود.

سرویس‌های Android:
- `com.ryanheise.audioservice.AudioService`
- `com.ryanheise.audioservice.MediaButtonReceiver`
- `MainActivity` از `AudioServiceFragmentActivity` ارث می‌برد تا هم پخش پس‌زمینه و هم بیومتریک کار کند.

---

## 🧪 چک‌لیست تست دستی
1. ثبت‌نام با ایمیل واقعی → دریافت کد → تأیید → ورود
2. ورود با OTP و شمارش معکوس ارسال مجدد
3. فراموشی رمز → کد → رمز جدید → ورود
4. خروج و ورود مجدد؛ بررسی بیومتریک در پروفایل و صفحهٔ قفل
5. پخش آهنگ، Seek، بعدی/قبلی و پخش خودکار
6. خاموش کردن صفحه و بررسی ادامهٔ پخش + اعلان
7. ساخت/ویرایش/حذف پلی‌لیست و افزودن/حذف آهنگ
8. لایک/آنلایک و همگام‌سازی با وب‌سرویس
9. جست‌وجوی زنده و حالت‌های خطا/خالی/تلاش مجدد
10. اجرای اول آنبوردینگ و اجرای دوم (عدم نمایش مجدد)

---

## 📦 تحویل
- سورس کامل همین مخزن (بدون `build/`)
- APK امضاشده در `dist/Soundify-1.0.0-arm64-v8a.apk` (و نسخهٔ universal)
- همین `README.md`
- فایل متنی لینک‌ها: `SUBMISSION.txt`
- ۲۶ تست واحد موفق: `flutter test`
- تست دستی روی دستگاه/شبیه‌ساز توسط تحویل‌دهنده (به دلیل نبود دستگاه فیزیکی در محیط ساخت، ویدئو ضبط نشده است)

---

## ⚠️ محدودیت‌ها
- برای دریافت کد OTP به ایمیل واقعی نیاز است؛ سرور کد را در پاسخ API برنمی‌گرداند.
- پخش صدا به دسترسی اینترنت و در دسترس بودن آدرس استریم سرور وابسته است.
- کاورها از CDN گوگل بارگذاری می‌شوند؛ در شبکه‌های محدود ممکن است با تصویر جایگزین نمایش داده شوند.
- این پروژه برای Android هدف‌گذاری شده است (پلتفرم اصلی درس)؛ پیکربندی iOS انجام نشده است.
