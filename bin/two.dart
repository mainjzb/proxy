import 'dart:async';
import 'dart:isolate';
import 'dart:math';

void main() async {
  final receivePort1 = ReceivePort();
  final receivePort2 = ReceivePort();

  await Isolate.spawn(subIsolate, receivePort1.sendPort);
  await Isolate.spawn(subIsolate, receivePort2.sendPort);

  final data = List.generate(10, (index) => index);

  final sendPort1 = await receivePort1.first;
  final sendPort2 = await receivePort2.first;

  // int i = 0;
  // receivePort1.listen((message) {
  //   if (i < 10) {
  //     message.send(data[i]);
  //     i++;
  //   }
  // });
  // receivePort2.listen((message) {
  //   if (i < 10) {
  //     message.send(data[i]);
  //     i++;
  //   }
  // });
  //

  // 创建待处理异步任务流
  final inputStream = Stream<int>.fromIterable(data);

  // 创建异步任务分配方法
  Stream<int> distribute(Stream<int> stream) async* {
    final filling = <int>[];

    await for (final val in stream) {
      filling.add(val);
      yield val;
      if (filling.length > 1 && filling.length % 2 == 0) {
        // 寻找最快的通信通道
        var sendPort = sendPort1.sendPort;
        if (await receivePort2.first is int) {
          sendPort = sendPort2.sendPort;
        }
        // 取出被竞争线程处理完的数据
        final busyPort = sendPort == sendPort1.sendPort ? sendPort2 : sendPort1;
        while (busyPort.isNotEmpty) {
          final busy = busyPort.first;
          if (busy is int) {
            filling.add(busy);
            // 不再等另一线程就位，立即执行当前填充的数据
            await sendPort.send(filling.removeAt(0));
            break;
          } else {
            busyPort.remove(busy);
            continue;
          }
        }
      }
    }
  }

  // 调用分配方法，分配要处理的任务
  final results1 = distribute(inputStream).toList();
  final results2 = distribute(inputStream).toList();

  // 等待所有线程完成
  await Future.wait([results1, results2]);

  print('Results 1: $results1');
  print('Results 2: $results2');
}

void subIsolate(SendPort sendPort) {
  final receivePort = ReceivePort();
  sendPort.send(receivePort.sendPort);
  receivePort.listen((message) async {
    final int value = message as int;
    // 随机生成[1, 1000]时间来模拟任务处理时间
    final duration = Duration(milliseconds: Random().nextInt(1000) + 1);
    await Future.delayed(duration);
    final result = value;
    sendPort.send(result);
  });
}
