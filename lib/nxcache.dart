import 'dart:async';
import 'dart:io';

import 'package:shelf/shelf.dart';

const nxcacheCDN = "rescache.nx.askycn.com";

class Nxcache {
  static final _completedDownloads = <String, Response>{};
  static final imageCache = <String, Completer<Response>>{};

  static Future<Response> getImage(Request oldRequest) async {
    final url = oldRequest.requestedUri.path;
    if (imageCache.containsKey(url)) {
      final completer = imageCache[url]!;
      return completer.future;
    } else if (_completedDownloads.containsKey(url)) {
      // Use cached image if download has already completed
      return _completedDownloads[url]!;
    } else {
      // Start a new download and store it in cache
      try {
        return download(oldRequest);
      } catch (error) {
        // If there was an error, remove the download from cache and reject the completer's future
        imageCache[url]?.completeError(error);
        imageCache.remove(url);

        return Response(500);
        // rethrow;
      }
    }
    return Response(500);
  }

  static Future<Response> download(Request oldRequest) async {
    // 向远程服务器发出请求
    final client = HttpClient();
    client.autoUncompress = false;
    final uri = Uri.parse('https://$nxcacheCDN${oldRequest.requestedUri.path}');

    final request = await client.getUrl(uri);
    final response = await request.close();

    // 从原始响应中获取响应头（headers）
    final headers = <String, Object>{};
    response.headers.forEach((key, values) {
      headers.addAll({key: values.join(',')});
    });

    // final byteStream = response.transform(StreamTransformer.fromHandlers(handleData: (data, sink) {
    //   sink.add(data);
    // }));

    final completer = Completer<Response>();
    imageCache[oldRequest.requestedUri.path] = completer;
    final buffer = <int>[];
    response.listen((data) {
      buffer.addAll(data);
    }, onDone: () {
      completer.complete(Response(response.statusCode,
          headers: headers, context: {'content-length': response.contentLength}, body: buffer));
      _completedDownloads[oldRequest.requestedUri.path] = Response(response.statusCode,
          headers: headers, context: {'content-length': response.contentLength}, body: buffer);
    }, onError: (error) {
      completer.completeError(error);
    });

    await completer.future;

    final newResponse = Response(response.statusCode,
        headers: headers, context: {'content-length': response.contentLength}, body: buffer);
    return newResponse;
  }
}
