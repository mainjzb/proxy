import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shelf_router/shelf_router.dart';


void main() async {
  var app = Router();
  app.get('/*', (Request request) {
   // if(request.headers['host']=="download2.nexon.net")
      switch (request.headers['host']){
        case 'download2.nexon.net':
          downloadHandler(request);
          break;
        case 'nxcache.nexon.net':
      }
    return Response.ok('hello-world');
  });

  var handler = const Pipeline().addMiddleware(logRequests()).addHandler(app);
  var server = await io.serve(handler, 'localhost', 0);


  // 打印服务器端口号
  print('Server listening on port ${server.port}');
}

void downloadHandler(Request request){

}

