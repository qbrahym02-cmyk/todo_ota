/// إعدادات الاتصال بالمستودع (مصدر التحديثات عن بعد).
class AppConfig {
  static const String githubOwner = 'qbrahym02-cmyk';
  static const String githubRepo = 'todo_ota';
  static const String branch = 'main';

  /// ملف الإعدادات عن بعد – عدّله على GitHub ويتغيّر التطبيق فوراً بدون أي تحديث.
  static String get remoteConfigUrl =>
      'https://raw.githubusercontent.com/$githubOwner/$githubRepo/$branch/remote/config.json';

  /// آخر إصدار (APK) – يُنشأ تلقائياً بواسطة GitHub Actions.
  static String get latestReleaseApi =>
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest';

  /// نسخة الويب (تتحدث تلقائياً مع كل push).
  static String get webAppUrl =>
      'https://$githubOwner.github.io/$githubRepo/';
}
