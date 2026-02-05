# GitHub Actions Workflows

این پروژه شامل چند workflow برای CI/CD است:

## Workflows

### 1. `ci.yml` - Continuous Integration
- **زمان اجرا**: Push به main/master/develop یا Pull Request
- **عملکرد**: تست و بررسی کد
- **پلتفرم‌ها**: Windows, macOS, Linux

### 2. `build-release.yml` - Build و Release (Matrix)
- **زمان اجرا**: Push tag با فرمت `v*` (مثل v1.0.0)
- **عملکرد**: ساخت برای همه پلتفرم‌ها با استفاده از matrix strategy
- **مزایا**: سریع‌تر، استفاده از cache بهتر
- **معایب**: اگر یک پلتفرم fail شود، بقیه ادامه می‌دهند

### 3. `build-release-simple.yml` - Build و Release (Simple)
- **زمان اجرا**: Push tag با فرمت `v*`
- **عملکرد**: ساخت برای همه پلتفرم‌ها به صورت جداگانه
- **مزایا**: پایدارتر، هر job مستقل است
- **معایب**: کمی کندتر

## توصیه

اگر مشکل timeout یا cancel شدن دارید:
1. از `build-release-simple.yml` استفاده کنید (پایدارتر)
2. یا `build-release.yml` را با timeout بیشتر استفاده کنید

## تغییر Workflow فعال

برای تغییر workflow فعال:
1. فایل `build-release.yml` را rename کنید به `build-release.yml.bak`
2. فایل `build-release-simple.yml` را rename کنید به `build-release.yml`

یا برعکس.

## تنظیمات Timeout

اگر هنوز مشکل timeout دارید:
- timeout-minutes را در workflow افزایش دهید
- یا از runner بزرگ‌تر استفاده کنید (در صورت نیاز)

