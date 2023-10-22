import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ogios_sutils/in.dart';
import 'package:ogios_sutils/out.dart';

Future test3() async {
  Socket s = await Socket.connect("localhost", 15001);
  SocketOut so = SocketOut();
  so.addBytes(Uint8List.fromList("fetch".codeUnits));
  so.addBytes(Uint8List.fromList([0]));
  so.addBytes(Uint8List.fromList([10]));
  await so.writeTo(s);
  SocketIn si = SocketIn(conn: s);
  int len = await si.next();
  // print("sec length: $len");
  Uint8List sec = await si.getSec();
  // print("sec: $sec");
  // print("sec to string: ${String.fromCharCodes(sec)}");
  if (len == 1 && sec[0] == 200) {
    len = await si.next();
    // print("sec length: $len");
    sec = await si.getSec();
    // print("sec: $sec");
    // print("sec to string: ${String.fromCharCodes(sec)}");
  }
}