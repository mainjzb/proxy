import 'package:logging/logging.dart';
import 'package:test/test.dart';
import 'package:proxy/nx_download.dart';

void main() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.level.name}: ${record.time}: ${record.message}');
  });

  test('Counter value should be incremented', () async {
    final nxd = NxDownloader();
    final result = await nxd.headRequest(downloadCDN);
    expect(result, true);
  });
}
