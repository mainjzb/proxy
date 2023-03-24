import 'package:logging/logging.dart';
import 'package:proxy/nx_download.dart';
import 'package:test/test.dart';

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  Stopwatch stopwatch = Stopwatch()..start();
  await NxDownloader.getBestIP();
  stopwatch.stop();
  print(stopwatch.elapsedMilliseconds.toDouble());

  test('Counter value should be incremented', () async {
    final result = await NxDownloader.headRequest(downloadCDN);
    expect(result, true);
  });
}
