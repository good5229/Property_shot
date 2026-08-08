import 'dart:io';

final bool automatedFlutterTest =
    Platform.environment['FLUTTER_TEST']?.toLowerCase() != 'false' &&
    Platform.environment.containsKey('FLUTTER_TEST');
