import 'package:logging/logging.dart';

final Logger logger = Logger('ScreenShare');

void setupLogging() {
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('[${record.loggerName}] ${record.level.name}: ${record.message}');
    if (record.error != null) {
      // ignore: avoid_print
      print('  Error: ${record.error}');
    }
  });
}
