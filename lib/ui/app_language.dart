import 'package:shared_preferences/shared_preferences.dart';

typedef AppLanguageReader = Future<String?> Function();
typedef AppLanguageWriter = Future<bool> Function(String value);

enum AppLanguage { korean, english }

extension AppLanguageText on AppLanguage {
  bool get isEnglish => this == AppLanguage.english;

  String get code => isEnglish ? 'en' : 'ko';

  String pick(String korean, String english) => isEnglish ? english : korean;
}

class AppLanguageStore {
  const AppLanguageStore({this.reader, this.writer});

  static const key = 'property_shot_app_language_v1';

  final AppLanguageReader? reader;
  final AppLanguageWriter? writer;

  Future<AppLanguage> load({AppLanguage fallback = AppLanguage.korean}) async {
    try {
      final stored = reader != null
          ? await reader!()
          : (await SharedPreferences.getInstance()).getString(key);
      return switch (stored) {
        'ko' => AppLanguage.korean,
        'en' => AppLanguage.english,
        _ => fallback,
      };
    } on Object {
      return fallback;
    }
  }

  Future<void> save(AppLanguage language) async {
    try {
      final saved = writer != null
          ? await writer!(language.code)
          : await (await SharedPreferences.getInstance()).setString(
              key,
              language.code,
            );
      if (!saved) throw StateError('언어 설정을 저장하지 못했습니다.');
    } on StateError {
      rethrow;
    } on Object {
      throw StateError('언어 설정을 저장하지 못했습니다.');
    }
  }
}
