import 'package:proxy/nx_download.dart';
import 'package:proxy/nxcache.dart';
import 'package:proxy/pipe.dart';
import 'package:proxy/string_util.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    return;
  }
  var parentPid = arguments[0];
  if (parentPid != "0") {
    monitorParent(parentPid);
  }

  var app = Router();
  app.get('/<ignored|.*>', (Request request) async {
    downloadHandler(request);
    // if(request.headers['host']=="download2.nexon.net")
    switch (request.headers['host']) {
      case 'download2.nexon.net':
        return await downloadHandler(request);
      case 'nxcache.nexon.net':
        return await nxcacheHandler(request);
    }
    return Response.ok('hello-world');
  });

  var handler = const Pipeline().addMiddleware(logRequests()).addHandler(app);
  var server = await io.serve(handler, '127.0.0.1', 80);

  // 打印服务器端口号
  print('Server listening on port ${server.port}');
}

Future<Response> downloadHandler(Request request) async {
  final path = request.requestedUri.path;

  if (!path.hasPrefix('/Game/nxl/games/10100/10100/')) {
    final ip = await NxDownloader.getCanUserHost();
    print('$ip$path');
    return NxDownloader.download(ip, request, Duration(seconds: 3));
  }

  final bestIP = await NxDownloader.calc();
  return NxDownloader.download(bestIP, request, Duration(seconds: 30));
}

Future<Response> nxcacheHandler(Request request) async {
  return Nxcache.getImage(request);
}
