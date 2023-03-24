import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';
import 'package:shelf/shelf.dart';

const downloadCDN = "resdownload.nx.askycn.com";

const ips = [
  "23.54.60.182", // 欧洲
  "23.77.214.153", // 香港 牛逼
  "104.74.20.210", // 香港
  "23.78.216.224", // 香港
  "23.57.113.125", // 香港
  "184.51.240.175", // 香港

  "173.222.181.7", // 台湾
  "23.210.236.128", // 台湾
  "96.7.253.7", // 台湾
  "104.115.209.161", // 台湾
  "23.193.24.187", // 台湾

  "23.206.201.132", // 日本
  "23.60.108.179", // 日本
  "23.35.193.26", // 日本
  "104.76.16.157", // 日本
  "23.41.20.48", // 日本
  "72.247.136.196", // 日本
  "23.44.52.200", // 日本
  "23.45.56.200", // 日本
  "104.92.144.170", // 日本
];

var logger = Logger(
  printer: PrettyPrinter(),
);

var loggerNoStack = Logger(
  printer: PrettyPrinter(methodCount: 0),
);

class NxDownloader {
  static String _bestIP = "";
  static bool _calculating = false;
  static final Completer<String> _completer = Completer();

  static Future<String> calc() async {
    // 如果已经有缓存结果，直接返回
    if (_bestIP != "") {
      return _bestIP;
    }

    // 如果正在计算中，返回等待的Future
    if (_calculating) {
      return await _completer.future;
    }

    // 开始计算，并将结果缓存起来
    _calculating = true;
    _bestIP = await getBestIP();
    _completer.complete(_bestIP);
    _calculating = false;

    return _bestIP;
  }

  static Future<Response> download(String ip, Request oldRequest, Duration time) async {
    // 向远程服务器发出请求
    final client = HttpClient();
    client.autoUncompress = false;
    final uri = Uri.parse('http://$ip${oldRequest.requestedUri.path}');
    HttpClientRequest request;
    if (time.isNegative) {
      request = await client.getUrl(uri);
    } else {
      request = await client.getUrl(uri).timeout(time);
    }
    if (ip != downloadCDN) {
      oldRequest.headers.forEach((name, value) => request.headers.set(name, value));
    }
    final response = await request.close();

    // 从原始响应中获取响应头（headers）
    final headers = <String, Object>{};
    response.headers.forEach((key, values) {
      headers.addAll({key: values.join(',')});
    });

    // 以字节流的方式返回响应内容
    final byteStream = response.transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
      sink.add(data);
    }));
    final newResponse = Response(response.statusCode,
        headers: headers, context: {'content-length': response.contentLength}, body: byteStream);

    return newResponse;
  }

  static Future<String> getCanUserHost() async {
    if (await headRequest(downloadCDN)) {
      return downloadCDN;
    }
    for (final ip in ips) {
      if (await headRequest(ip)) {
        return ip;
      }
    }
    return downloadCDN;
  }

  static Future<bool> headRequest(final String host) async {
    try {
      final request = http.Request('HEAD', Uri.parse('http://$host'));
      request.headers.addAll({'Host': 'download2.nexon.net'});
      final response = await request.send().timeout(Duration(seconds: 2));
    } catch (e) {
      return false;
    }
    return true;
  }

  // test all ips in 2 isolate
  static Future<String> getBestIP() async {
    final p1 = ReceivePort();
    final p2 = ReceivePort();

    // Divide the IP Addresses into two equal parts
    int numIPAddressesPerThread = ips.length ~/ 2;
    List<List<String>> ipAddressesForThreads = [
      ips.sublist(0, numIPAddressesPerThread),
      ips.sublist(numIPAddressesPerThread)
    ];

    // Start two threads to test IP addresses in parallel
    Isolate.spawn(isolateDetectIPsDownloadSpeed, {'sendPort': p1.sendPort, 'data': ipAddressesForThreads[0]});
    Isolate.spawn(isolateDetectIPsDownloadSpeed, {'sendPort': p2.sendPort, 'data': ipAddressesForThreads[1]});
    final result1 = await p1.first as List<MapEntry<String, double>>;
    final result = (await p2.first as List<MapEntry<String, double>>) + result1;
    //final result = await Future.wait([p1.first, p2.first]);

    String bestIP = result[0].key;
    double bestSpeed = 0;
    for (var r in result) {
      if (r.value > bestSpeed) {
        bestIP = r.key;
        bestSpeed = r.value;
      }
      print("IP address: ${r.key}\t\tDownload speed:${r.value.toString()} Mbps");
    }
    if (bestSpeed < 180) {
      return downloadCDN;
    }
    return bestIP;
  }

  // Function to test download speed of a list of IP addresses
  static void isolateDetectIPsDownloadSpeed(Map<String, dynamic> message) async {
    final port = message['sendPort'] as SendPort;
    final ipAddresses = message['data'] as List<String>;

    List<MapEntry<String, double>> results = [];

    // Loop through each IP address for speed testing
    for (String ip in ipAddresses) {
      print("Testing IP address: $ip");
      double downloadSpeed = await detectDownloadSpeed(ip);
      results.add(MapEntry(ip, downloadSpeed));
    }
    Isolate.exit(port, results);
  }

  // Function to test download speed of a given IP address
  static Future<double> detectDownloadSpeed(String host) async {
    final url = Uri.parse("http://$host/Game/nxl/games/10100/10100/06/063b0db4672c3a769fbf889e653d738bb12dc5a2");
    final headers = {
      'Host': 'download2.nexon.net',
      'Range': 'bytes=0-102400',
    };

    // Start the download timer
    Stopwatch stopwatch = Stopwatch()..start();

    var contentSize = 0;
    try {
      final response = await http.get(url, headers: headers).timeout(Duration(seconds: 3));
      contentSize = response.body.length;
    } catch (e) {
      print("Error downloading file: $e");
      return 0;
    }

    // Stop the download timer and calculate the download speed in Mbps
    stopwatch.stop();

    double downloadTimeInMs = stopwatch.elapsedMilliseconds.toDouble();
    double downloadSpeedInKbps = (contentSize / downloadTimeInMs) * 1000 / 1000;

    return downloadSpeedInKbps;
  }
}
