import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

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

class NxDownloader {
  void getBestIP() {}

  Future<String> getCanUserHost() async {
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

  Future<bool> headRequest(final String host) async {
    Logger log = Logger('NxDownloader');
    log.fine('message');
    try {
      final request = http.Request(
        'HEAD',
        Uri.parse('http://$host'),
      );
      request.headers.addAll({'Host': 'download2.nexon.net'});
      final response = await request.send().timeout(Duration(seconds: 2));
      log.fine('code：${response.statusCode}');
    } catch (e) {
      log.fine('Request failed: $e');
      return false;
    }
    return true;
  }
}
