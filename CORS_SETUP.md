# إعداد CORS لتطوير Flutter Web

## المشكلة

عند تشغيل التطبيق على Chrome Web، قد تواجه أخطاء CORS عند محاولة الوصول إلى API:

```
Access to XMLHttpRequest at 'https://bridgecore.geniura.com/api/v1/auth/tenant/login' 
from origin 'http://localhost:58206' has been blocked by CORS policy
```

## الحلول

### الحل 1: تشغيل Chrome مع CORS معطل (للتطوير فقط)

**⚠️ تحذير:** هذا الحل للتطوير فقط ولا يجب استخدامه في الإنتاج.

#### Windows:
```powershell
# إغلاق جميع نوافذ Chrome أولاً
# ثم تشغيل Chrome مع CORS معطل:
& "C:\Program Files\Google\Chrome\Application\chrome.exe" --user-data-dir="C:/ChromeDevSession" --disable-web-security --disable-features=VizDisplayCompositor
```

#### macOS:
```bash
open -na Google\ Chrome --args --user-data-dir="/tmp/chrome_dev_test" --disable-web-security
```

#### Linux:
```bash
google-chrome --user-data-dir="/tmp/chrome_dev_test" --disable-web-security
```

### الحل 2: استخدام Proxy Server

يمكنك استخدام proxy server لتجاوز مشاكل CORS:

#### استخدام `flutter run` مع proxy:
```bash
flutter run -d chrome --web-port=8080
```

ثم إعداد proxy في `web/index.html` أو استخدام أداة مثل `http-proxy-middleware`.

### الحل 3: إصلاح الخادم (الحل المثالي)

الحل الأفضل على المدى الطويل هو إصلاح الخادم لإرسال CORS headers الصحيحة:

```python
# في Odoo/BridgeCore server
@http.route('/api/v1/auth/tenant/login', type='http', auth='none', cors='*', methods=['POST', 'OPTIONS'], csrf=False)
def login(self):
    # إضافة CORS headers
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'POST, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type, Authorization'
    response.headers['Access-Control-Allow-Credentials'] = 'true'
    # ... باقي الكود
```

### الحل 4: استخدام Firefox للتطوير

Firefox لديه إعدادات CORS أقل صرامة من Chrome. يمكنك استخدامه للتطوير:

1. افتح `about:config` في Firefox
2. ابحث عن `security.fileuri.strict_origin_policy`
3. اضبطه على `false`

## ملاحظات مهمة

1. **CORS هو آلية أمان**: CORS موجود لحماية المستخدمين من المواقع الخبيثة. لا يجب تعطيله في الإنتاج.

2. **الحل الأفضل**: إصلاح الخادم لإرسال CORS headers الصحيحة هو الحل الأفضل والأكثر أماناً.

3. **للتطوير فقط**: جميع الحلول المذكورة أعلاه للتطوير فقط. في الإنتاج، يجب أن يكون الخادم مُعد بشكل صحيح.

## التحقق من الإعداد

بعد تطبيق أي حل، تحقق من:
1. فتح Developer Tools (F12)
2. الانتقال إلى Network tab
3. محاولة تسجيل الدخول
4. التحقق من أن الطلبات تمر بنجاح

## روابط مفيدة

- [MDN CORS Documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)
- [Flutter Web CORS Issues](https://flutter.dev/docs/development/platform-integration/web)
- [Chrome CORS Extension](https://chrome.google.com/webstore/detail/cors-unblock/lfhmikememgdcahcdlaciloancbhjino) (للتطوير فقط)
