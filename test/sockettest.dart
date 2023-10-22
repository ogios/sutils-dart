import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:ogios_sutils/buffer.dart';

Future<void> test() async {
  Socket s = await Socket.connect("localhost", 15002);
  SocketBuffer buffer = SocketBuffer();
  s.write("shit");
  s.listen((event) {
    log("${event.length}");
    buffer.add(event);
  }, onDone: () {
    buffer.done();
    s.destroy();
  }, onError: (err, stack) {
    buffer.err(err);
    s.close();
  });
  try {
    while (true) {
      Uint8List bs = await buffer.readN(1024);
      log("$bs");
    }
  } catch (err) {
    log("ERROR: $err");
  }
  log("done");
}