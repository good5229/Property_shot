import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { korean, english }

extension AppLanguageText on AppLanguage {
  bool get isEnglish => this == AppLanguage.english;

  String get code => isEnglish ? 'en' : 'ko';

  String pick(String korean, String english) => isEnglish ? english : korean;
}

class AppLanguageStore {
  const AppLanguageStore();

  static const key = 'property_shot_app_language_v1';

  Future<AppLanguage> load({AppLanguage fallback = AppLanguage.korean}) async {
    final preferences = await SharedPreferences.getInstance();
    return switch (preferences.getString(key)) {
      'ko' => AppLanguage.korean,
      'en' => AppLanguage.english,
      _ => fallback,
    };
  }

  Future<void> save(AppLanguage language) async {
    final preferences = await SharedPreferences.getInstance();
    final saved = await preferences.setString(key, language.code);
    if (!saved) throw StateError('언어 설정을 저장하지 못했습니다.');
  }
}
