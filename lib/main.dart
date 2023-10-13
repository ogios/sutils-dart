import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ogios_sutils/buffer.dart';
import 'package:ogios_sutils/in.dart';
import 'package:ogios_sutils/out.dart';

Future<void> test() async {
  Socket s = await Socket.connect("localhost", 15002);
  SocketBuffer buffer = SocketBuffer();
  s.write("shit");
  s.listen((event) {
    print(event.length);
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
      // print("getbs");
    }
  } catch (err) {
    print("ERROR: $err");
  }
  print("done");
}

void test1() {
  Uint8List a = Uint8List(1);
  print(a.sublist(0, 0));
}

Future test2_server() async {
  ServerSocket serverSocket = await ServerSocket.bind("localhost", 15002);
  await for (var socket in serverSocket) {
    print("received new conn: ${socket.remoteAddress}");
    SocketOut so = SocketOut();
    so.addBytes(Uint8List.fromList("hi from server".codeUnits));
    await so.writeTo(socket);
    // socket.close();
    break;
  }
  print("server done.");
}

Future test2_client() async {
  Socket s = await Socket.connect("localhost", 15002);
  SocketIn si = SocketIn(conn: s);
  int len = await si.next();
  print("sec length: $len");
  Uint8List sec = await si.getSec();
  print("sec: $sec");
  s.close();
  print("client done");
}

void test2() async {
  test2_server();
  test2_client();
}

void main() {
  // test();
  // test1();
  test2();
}
