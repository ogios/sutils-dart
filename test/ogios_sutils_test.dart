import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:ogios_sutils/ogios_sutils.dart';

void main() {
  test('adds one to input values', () async {
    var f = () async {
      print("start");
      ConnectionTask<Socket> so = await Socket.startConnect("localhost", 15002);
      Socket s = await so.socket;
      // s.add("shit".codeUnits);
      s.write("shit".codeUnits);
      s.flush();
      s.listen((event) {
        print(event);
        s.destroy();
      }, onError: (error) {
        print("Error");
        s.destroy();
      }, onDone: () {
        print("Done");
      });
      print("wait for fone");
      await s.done;
      print("done");
    }();
    await f;
  });
}
