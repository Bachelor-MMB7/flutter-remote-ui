import 'dart:io';

import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:rfw/formats.dart';
 
// Configure routes.
final _router = Router()
  ..get('/tenants/<tenantId>/workflows/<workflowId>.rfw', _rfwHandler);

Future<Response> _rfwHandler(Request request) async {
  final tenantId = request.params['tenantId'];
  final workflowId = request.params['workflowId'];

  final filePath = 'definitions/$tenantId/workflows/$workflowId.rfwtxt';

  // creates disc connection
  final file = File(filePath);

  if (!(await file.exists())) {
    return Response.notFound('Workflow not found: $tenantId/$workflowId');
  }
  final content = await file.readAsString();

  try {
    final library = parseLibraryFile(content);
    final binary = encodeLibraryBlob(library);
    return Response.ok(
      binary,
      headers: {'content-type': 'application/octet-stream'},
    );
  } on Exception catch (e) {
    return Response.internalServerError(
      body: 'Failed to process $tenantId/$workflowId: $e',
    );
  }
}

void main(List<String> args) async {
  // Use any available host or container IP (usually `0.0.0.0`).
  final ip = InternetAddress.anyIPv4;

  // Configure a pipeline that logs requests.
  final handler = Pipeline()
      .addMiddleware(logRequests())
      .addHandler(_router.call);

  // For running in containers, we respect the PORT environment variable.
  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, ip, port);
  print('Server listening on port ${server.port}');
}
