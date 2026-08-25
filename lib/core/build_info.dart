/// מידע-בילד סטטי של האפליקציה.
///
/// [buildLabel] מוזרק בזמן הקומפילציה דרך `--dart-define`:
///
/// ```
/// flutter build windows --release --dart-define=OTZARIA_BUILD_LABEL=portable-dev
/// ```
///
/// בילד רגיל בלי define — [buildLabel] ריק ושום דבר לא משתנה ב-UI. כשהוא
/// מוגדר (למשל "portable-dev", "PR-test" וכו'), הוא מוצג בכותרת החלון/
/// משימות ונרשם ב-log באתחול, כדי שבזמן בדיקות ידניות של כמה בילדים
/// אפשר יהיה לדעת בדיוק מול איזה בילד מסתכלים.
class BuildInfo {
  /// תווית הבילד מ-`--dart-define=OTZARIA_BUILD_LABEL=...`. ריקה בבילד רגיל.
  static const String buildLabel = String.fromEnvironment(
    'OTZARIA_BUILD_LABEL',
  );

  /// שם האפליקציה הבסיסי.
  static const String appName = 'Otzaria';

  /// כותרת החלון/משימות: שם האפליקציה + תווית הבילד כשקיימת.
  static String get windowTitle =>
      buildLabel.isEmpty ? appName : '$appName — $buildLabel';
}
