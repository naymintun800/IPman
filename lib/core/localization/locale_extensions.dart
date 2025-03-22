import 'dart:io';

import 'package:hiddify/gen/fonts.gen.dart';
import 'package:hiddify/gen/translations.g.dart';

extension AppLocaleX on AppLocale {
  // Always use Z11-MyanSans font regardless of locale
  //String get preferredFontFamily => 'Z11-MyanSans';

  // If you still want a special case for Windows emoji, use this instead:
  String get preferredFontFamily => Platform.isWindows ? FontFamily.emoji : 'Z11-MyanSans';

  String get localeName => switch (flutterLocale.toString()) {
        "en" => "English",
        "my" => "Myanmar",
        _ => "Unknown",
      };
}
