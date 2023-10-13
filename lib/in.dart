library ogios_sutils;

import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:ogios_sutils/buffer.dart';

class SocketIn {
  SocketIn({required this.conn}) {
    this.raw = SocketBuffer();
    this.conn.listen((event) {
      this.raw.add(event);
    }, onDone: () {
      this.raw.done();
    }, onError: (err) {
      this.raw.err(err);
    });
  }
  Socket conn;
  late SocketBuffer raw;
  int readed = 0;
  int CurrSecLength = 0;

  Future<int> _main({required int index, required int t}) async {
    Uint8List b = await this.raw.readN(1);
    if (b.length != 1) {
      throw Exception("readNBytes fails to work: ${b}");
    }
    int current = b[0];
    if (current != 255) {
      t = await this._main(index: index + 1, t: t);
      num feat = pow(255, index);
      int addon = current * feat.toInt();
      t += addon;
    }
    return t;
  }

  Future<int> next() async {
    if (this.CurrSecLength < this.readed) {
    throw new Exception("please read all of current section");
    }
    int total = await this._main(index: 0, t: 0);
    this.CurrSecLength = total;
    this.readed = 0;
    return total;
  }

  Future<Uint8List> getSec() async {
    if (this.readed < this.CurrSecLength) {
      Uint8List bs = Uint8List(this.CurrSecLength-this.readed);
      int readed = await this.raw.read(bs);
      this.readed += readed;
      return bs;
    } else {
      int length = await this.next();
      Uint8List temp = Uint8List(length);
      int readlength = await this.raw.read(temp);
      if (readlength != length) {
      }
      return temp;
    }
  }

  Future<int> read(Uint8List buf) async {
    if (this.CurrSecLength == this.readed) {
      throw new Exception("no more bytes for current section");
    }
    if (buf.length <= this.CurrSecLength-this.readed) {
      int i = await this.raw.read(buf);
      this.readed += i;
      return i;
    } else {
      Uint8List temp = Uint8List(this.CurrSecLength-this.readed);
      int length = await this.raw.read(temp);
      this.readed += length;
      buf.setRange(0, temp.length, temp);
      return length;
    }
  }
}
