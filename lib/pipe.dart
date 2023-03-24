import 'dart:io';

Future<void> monitorParent(String pid) async {
  const pipeName = r'\\.\pipe\kdjsq';

  while (true) {
    try {
      final pipe = await File(pipeName).open(mode: FileMode.write);
      pipe.writeStringSync('pid\n');
      // List<int> result = [];
      // while (true) {
      //   try {
      //     final c = await pipe.readByte().timeout(Duration(seconds: 1));
      //     if (c == '\n'.codeUnitAt(0)) {
      //       break;
      //     }
      //     result.add(c);
      //   } catch (e) {
      //     break;
      //   }
      // }
      final result = await pipe.read(100).timeout(Duration(seconds: 1));

      pipe.closeSync();

      if (String.fromCharCodes(result) != pid) {
        exit(0);
      }
    } catch (e) {
      exit(0);
    }

    Future.delayed(Duration(seconds: 3), () {});
  }
}
