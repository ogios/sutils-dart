import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ogios_sutils/in.dart';
import 'package:ogios_sutils/out.dart';

Future test2_server() async {
  ServerSocket serverSocket = await ServerSocket.bind("localhost", 15002);
  await for (var socket in serverSocket) {
    log("received new conn: ${socket.remoteAddress} - ${socket.remotePort}");
    var bs = Uint8List.fromList("hi from server".codeUnits);
    SocketOut so = SocketOut();
    so.addBytes(bs);
    File f = File("/home/ogios/work/andorid/ogios_sutils/test/test.txt");
    int size = (await f.stat()).size;
    log("file size: $size - ${size == f.lengthSync()}");
    so.addReader(f.openRead(), (await f.stat()).size);
    await so.writeTo(socket);
    log("closing...");
    await serverSocket.close();
    await socket.close();
    break;
  }
  await serverSocket.close();
  log("server done.");
}

Future test2_client() async {
  Socket s = await Socket.connect("localhost", 15002);
  SocketIn si = SocketIn(conn: s);
  int len = await si.next();
  log("sec length: $len");
  Uint8List sec = await si.getSec();
  log("sec: $sec");

  len = await si.next();
  log("sec length: $len");
  sec = await si.getSec();
  log("sec: $sec");
  s.destroy();
  // await s.close();
  log("client done");
}

void test2() async {
  test2_server();
  test2_client();
}