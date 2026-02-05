# حل مشکل GitHub Actions - Cancel شدن

## مشکل
اگر workflow شما در مرحله Setup Flutter cancel می‌شود، این راهنما را دنبال کنید.

## راه حل‌های پیشنهادی

### راه حل 1: استفاده از Workflow ساده‌تر (توصیه می‌شود)

1. فایل `build-release.yml` را rename کنید:
   ```bash
   mv .github/workflows/build-release.yml .github/workflows/build-release-matrix.yml
   ```

2. فایل `build-release-simple.yml` را rename کنید:
   ```bash
   mv .github/workflows/build-release-simple.yml .github/workflows/build-release.yml
   ```

3. Commit و push کنید:
   ```bash
   git add .github/workflows/
   git commit -m "Switch to simple build workflow"
   git push
   ```

### راه حل 2: افزایش Timeout

اگر می‌خواهید از workflow اصلی استفاده کنید:

1. فایل `.github/workflows/build-release.yml` را باز کنید
2. خط `timeout-minutes: 60` را به `timeout-minutes: 120` تغییر دهید
3. برای هر step هم timeout اضافه کنید

### راه حل 3: استفاده از Flutter Version جدیدتر

در workflow، `flutter-version` را به آخرین نسخه stable تغییر دهید:

```yaml
flutter-version: 'latest'  # یا نسخه جدیدتر مثل '3.27.0'
```

### راه حل 4: غیرفعال کردن Cache موقتاً

برای تست، cache را موقتاً غیرفعال کنید:

```yaml
cache: false
```

## بررسی مشکل

1. **بررسی Logs:**
   - به Actions tab در GitHub بروید
   - روی workflow failed کلیک کنید
   - مرحله Setup Flutter را بررسی کنید

2. **بررسی Timeout:**
   - اگر "The operation was canceled" می‌بینید، احتمالاً timeout است
   - timeout را افزایش دهید

3. **بررسی Network:**
   - اگر دانلود Flutter کند است، از runner دیگری استفاده کنید
   - یا از cache استفاده کنید

## تست Workflow

برای تست workflow بدون ایجاد release:

1. به Actions tab بروید
2. روی workflow کلیک کنید
3. "Run workflow" را بزنید
4. ورژن را وارد کنید (مثل v1.0.0-test)
5. Run را بزنید

## نکات مهم

- **اولین اجرا**: دانلود Flutter ممکن است 5-10 دقیقه طول بکشد
- **Cache**: بعد از اولین اجرا، cache باعث سریع‌تر شدن می‌شود
- **Matrix vs Simple**: Simple workflow پایدارتر اما کندتر است

## اگر هنوز مشکل دارید

1. از workflow ساده‌تر استفاده کنید (`build-release-simple.yml`)
2. Timeout را به 120 دقیقه افزایش دهید
3. Cache را غیرفعال کنید و دوباره تست کنید
4. Issue در GitHub ایجاد کنید با جزئیات خطا

