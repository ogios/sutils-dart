import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ogios_sutils/buffer.dart';

Future<void> test() async {
  Socket s = await Socket.connect("localhost", 15002);
  SocketBuffer buffer = SocketBuffer();
  s.write("shit");
  s.listen((event) {
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
      Uint8List bs = await buffer.readN(1);
      print(bs);
    }
  } catch (err) {
    print("ERROR: $err");
  }
  s.destroy();
}

void test1() {
  Uint8List a = Uint8List(1);
  print(a.sublist(0, 0));
}

void main() {
  test();
  // test1();
}
