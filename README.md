# مهامي – تطبيق To-Do بـ Flutter مع تحديث عن بعد

## 3 طرق تصل بها التحديثات للمستخدم

| ماذا تريد أن تغيّر؟ | ماذا تفعل؟ | كيف يصل للمستخدم؟ |
|---|---|---|
| العنوان، اللون، رسالة الإعلان، تشغيل/إيقاف الميزات | عدّل `remote/config.json` على GitHub | **فوراً** عند فتح التطبيق (بدون أي تحميل) |
| كود التطبيق (Android) | `git push` على `main` | يظهر للمستخدم "تحديث جديد" ← زر **تحديث الآن** ← ينزل ويثبّت من داخل التطبيق |
| نسخة الويب | `git push` على `main` | **تلقائياً** عند فتح الرابط |

### remote/config.json
```json
{
  "app_title": "مهامي",
  "primary_color": "#6750A4",
  "announcement": { "enabled": true, "text": "...", "color": "#FFF3CD" },
  "features": { "priorities": true, "search": true, "stats": true, "due_dates": true },
  "min_build": 0
}
```
- `min_build`: إذا رقم بناء التطبيق عند المستخدم أقل منه ← التحديث يصير **إجباري**.

### كيف يعمل الإصدار التلقائي
`.github/workflows/release.yml`:
1. يبني APK موقّع برقم بناء = رقم تشغيل الـ workflow.
2. ينشئ GitHub Release (`v1.0.N`) ويرفق الـ APK، ورسالة الـ commit تصير "ما الجديد".
3. التطبيق يفحص `releases/latest` عند التشغيل، ولو الرقم أكبر يعرض نافذة التحديث.
4. يبني نسخة الويب وينشرها على GitHub Pages.

### Secrets المطلوبة (مضبوطة مسبقاً)
`KEYSTORE_BASE64`, `KEYSTORE_PASSWORD`, `KEY_ALIAS`
> ⚠️ احتفظ بنسخة من مفتاح التوقيع. لو ضاع، لن تستطيع تثبيت التحديثات فوق النسخة الحالية.

### تشغيل محلي
```bash
flutter pub get
flutter run
```
