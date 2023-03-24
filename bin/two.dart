import 'dart:isolate';

void main() async {
  final ReceivePort mainToIsolateStream = ReceivePort();
  final ReceivePort isolateToMainStream = ReceivePort();

  final Isolate isolate = await Isolate.spawn(
    entryPoint,
    mainToIsolateStream.sendPort,
  );

  mainToIsolateStream.listen((data) {
    if (data is SendPort) {
      final SendPort sendPort = data;
      sendPort.send(isolateToMainStream.sendPort);
    } else {
      print('Data from isolate: $data');
    }
  });

  isolateToMainStream.listen((data) {
    print('Data from main: $data');
  });

  print('Sending data to isolate...');
  isolateToMainStream.sendPort.send('Hello from main!');
}

void entryPoint(SendPort mainToIsolatePort) {
  final ReceivePort isolateToMainStream = ReceivePort();

  mainToIsolatePort.send(isolateToMainStream.sendPort);

  isolateToMainStream.listen((data) {
    print('Data from main: $data');
  });

  print('Sending data to main...');
  isolateToMainStream.sendPort.send('Hello from isolate!');
}
