import 'dart:io';
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
    print("received new conn: ${socket.remoteAddress} - ${socket.remotePort}");
    var bs = Uint8List.fromList("hi from server".codeUnits);
    SocketOut so = SocketOut();
    so.addBytes(bs);
    File f = File("/home/ogios/work/andorid/ogios_sutils/test/test.txt");
    int size = (await f.stat()).size;
    print("file size: $size - ${size == f.lengthSync()}");
    so.addReader(f.openRead(), (await f.stat()).size);
    await so.writeTo(socket);
    print("closing...");
    await serverSocket.close();
    await socket.close();
    break;
  }
  await serverSocket.close();
  print("server done.");
}

Future test2_client() async {
  Socket s = await Socket.connect("localhost", 15002);
  SocketIn si = SocketIn(conn: s);
  int len = await si.next();
  print("sec length: $len");
  Uint8List sec = await si.getSec();
  print("sec: $sec");

  len = await si.next();
  print("sec length: $len");
  sec = await si.getSec();
  print("sec: $sec");
  s.destroy();
  // await s.close();
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
