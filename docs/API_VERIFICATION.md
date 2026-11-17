# گزارش بررسی قرارداد API و باگ پخش Pink Floyd

تاریخ بررسی: ۲۰۲۶-۱۱-۱۷  
سرور: `https://soundify.easyfound.ir/api/v1`

---

## ۱) نتیجهٔ بررسی همهٔ اندپوینت‌های درس

همهٔ درخواست‌ها با حساب نمایشی و توکن واقعی اجرا شدند. خروجی خام در
`%TEMP%\soundify_api_audit\results.csv` ذخیره شده است.

| # | متد | اندپوینت | کد پاسخ | نتیجه |
|---|---|---|---|---|
| ۱ | POST | `/auth/login/` | ۲۰۰ | توکن access و refresh و user دریافت شد |
| ۲ | GET | `/users/me/` | ۲۰۰ | پروفایل کامل |
| ۳ | GET | `/tracks/?q=pink%20floyd` | ۲۰۰ | ۶۴ نتیجه، ساختار `count/results` |
| ۴ | GET | `/tracks/featured/` | ۲۰۰ | ۹ آهنگ منتخب |
| ۵ | GET | `/tracks/{id}/stream/` با `Range` | ۲۰۶ | `Content-Range` و `audio/mpeg` |
| ۶ | POST | `/auth/otp/request/` | ۲۰۰ | `expires_in` و `resend_after` |
| ۷ | POST | `/auth/password/reset/request/` | ۲۰۰ | کد بازیابی ارسال شد |
| ۸ | GET | `/playlists/` | ۲۰۰ | صفحه‌بندی‌شده |
| ۹ | POST | `/playlists/` | ۲۰۱ | پلی‌لیست ساخته شد |
| ۱۰ | GET | `/playlists/{id}/` | ۲۰۰ | جزئیات + آرایهٔ tracks |
| ۱۱ | PATCH | `/playlists/{id}/` | ۲۰۰ | ویرایش نام/توضیحات |
| ۱۲ | POST | `/playlists/{id}/tracks/` | ۲۰۱ | افزودن ترک |
| ۱۳ | DELETE | `/playlists/{id}/tracks/{trackId}/` | ۲۰۴ | حذف ترک |
| ۱۴ | DELETE | `/playlists/{id}/` | ۲۰۴ | حذف پلی‌لیست |
| ۱۵ | GET | `/favorites/` | ۲۰۰ | لیست ترک‌های لایک‌شده |
| ۱۶ | POST | `/favorites/` | ۲۰۱ | افزودن علاقه‌مندی |
| ۱۷ | DELETE | `/favorites/{trackId}/` | ۲۰۴ | حذف علاقه‌مندی |
| ۱۸ | POST | `/auth/token/refresh/` | ۲۰۰ | access/refresh جدید |

موارد تکمیلی که قبلاً روی سرور تست شدند:

- `POST /auth/register/` → ۲۰۱
- `POST /auth/otp/verify/` با کد واقعی → ۲۰۰ و `verified: true`
- `POST /auth/password/reset/confirm/` → فیلد `new_password` پذیرفته می‌شود؛ با کد منقضی پاسخ `400 otp_expired` می‌دهد (قرارداد درست است).
- درخواست پیاپی OTP/Reset → `429 rate_limited` (رفتار درست ضداسپم)

نتیجه: **همهٔ اندپوینت‌های فهرست درس در کلاینت پیاده‌سازی و روی سرور واقعی تأیید شدند.**

---

## ۲) باگ گزارش‌شده: «آهنگ Pink Floyd می‌زنم، Coldplay پخش می‌شود»

### علت ریشه‌ای: پاسخ اشتباه سرور در `/tracks/:id/stream`

این باگ در اپ نیست؛ **سرور برای بعضی شناسه‌های Pink Floyd بایت‌های یک آهنگ دیگر
(از جمله Coldplay) را برمی‌گرداند.** اپ دقیقاً همان `stream_url`ی را باز می‌کند که
API در پاسخ `GET /tracks` می‌دهد.

مدرک مستقیم برای قطعهٔ *Poles Apart* از Pink Floyd:

```
GET /api/v1/tracks/ULFM7UTEOCLICM7RFAW6JJNN6MM6IWVY/
→ {"title":"Poles Apart","artist":"Pink Floyd","duration":424, ...}

GET /api/v1/tracks/ULFM7UTEOCLICM7RFAW6JJNN6MM6IWVY/stream/
→ 200 audio/mpeg, 6,504,567 bytes
```

بررسی ID3 فایل دریافتی با `mutagen`:

```
TPE1 = Coldplay
TIT2 = Paradise
مدت واقعی فایل ≈ 260 ثانیه (در حالی که API برای Pink Floyd مدت 424 ثانیه اعلام کرده)
```

مدرک دوم: اولین ۱ مگابایت استریم *Comfortably Numb* (Pink Floyd) با اولین ۱ مگابایت
استریم آهنگ `MLHIUJCABPR4EREK2ZH4K3WSP5RUPMTI` (Ye Chizi Begoo) **بایت‌به‌بایت
یکسان** است:

```
SHA-256 (1 MiB) = BDAFA233E5852EF003679570E37085F024613BCAF3AB05B186881369ABCB2717
```

یعنی سرور برای چند شناسهٔ مختلف، فایل صوتی یکسانی را برمی‌گرداند. همچنین برای
*Careful with That Axe, Eugene* مدت اعلام‌شده ۳۶۳ ثانیه است اما فایل واقعی ۲۴۲
ثانیه است.

### چرا کد اپ مقصر نیست؟

- `Track.fromJson` مقدار `stream_url` همان آهنگ را می‌خواند.
- `PlayerProvider` صف را با index درست می‌سازد و در صورت فیلترشدن لینک نامعتبر،
  ترک انتخاب‌شده را بر اساس `id` دوباره پیدا می‌کند.
- تست‌های جست‌وجو نشان می‌دهند نتایج Pink Floyd هیچ ترک Coldplayای در صف ندارند.
- حتی درخواست مستقیم `curl` (بدون اپ) هم برای همان ID فایل Coldplay را برمی‌گرداند.

پس تا زمانی که سرور فایل درست را برای این شناسه‌ها سرو نکند، از سمت کلاینت امکان
پخش آهنگ اصلی وجود ندارد.

### اقدام اصلاحی انجام‌شده در اپ

برای اینکه اپ دیگر **بی‌سروصدا آهنگ اشتباه را پخش نکند**، گارد یکپارچگی استریم اضافه شد:

- فایل `lib/core/utils/stream_integrity.dart`
- بعد از load شدن استریم، مدت واقعی فایل با مدت متادیتای API مقایسه می‌شود.
- اختلاف بیش از ۲۵٪ (و بیش از ۳۰ ثانیه) به‌عنوان «فایل اشتباه» تشخیص داده می‌شود.
- پخش بلافاصله متوقف و پیام فارسی نمایش داده می‌شود:
  «فایل صوتی این آهنگ با اطلاعات آن در سرور هم‌خوانی ندارد…»
- کاربر می‌تواند قطعهٔ بعدی را انتخاب کند؛ پخش دوبارهٔ همان فایل اشتباه مسدود است.
- همهٔ خطاهای پخش از طریق `MainShell` یک‌بار به‌صورت SnackBar نمایش داده می‌شوند.

نتیجه: رفتار «زدن Pink Floyd و شنیدن Coldplay» دیگر رخ نمی‌دهد؛ به‌جای آن پیام
شفاف خطای دادهٔ سرور نمایش داده می‌شود.

### راه‌حل نهایی (نیازمند مدیر سرور)

مدیر سرور باید نقشهٔ `track_id → audio_file` را برای رکوردهای خراب (حداقل
Pink Floydهای ایمپورت‌شده) اصلاح کند. فایل درست باید مدت و تگ‌های هم‌خوان با
متادیتای `GET /tracks` داشته باشد. پس از اصلاح سرور، گارد جدید اجازهٔ پخش می‌دهد.

---

## ۳) بازتولید سریع

```bash
# ۱) متادیتای Pink Floyd
curl "https://soundify.easyfound.ir/api/v1/tracks/?q=pink%20floyd&page_size=50"

# ۲) استریم همان ID (نمونه)
curl -L "https://soundify.easyfound.ir/api/v1/tracks/ULFM7UTEOCLICM7RFAW6JJNN6MM6IWVY/stream/" -o wrong.mp3

# ۳) خواندن تگ‌ها
python -c "from mutagen import File; f=File('wrong.mp3', easy=True); print(dict(f), f.info.length)"
# → {'artist': ['Coldplay'], 'title': ['Paradise']} 260.15
```
