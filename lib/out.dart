import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class SocketOut {
  SocketOut();
  static const int OUT_TYPE_BYTES = 1;
  static const int OUT_TYPE_READER = 2;

  List<Object> raw = [];
  List<int> types = [];

  void _add(Object raw, int t, Uint8List lenb) {
    this.raw.add(lenb);
    this.raw.add(raw);
    this.types.add(t);
  }

  static Uint8List _main(int last, int index) {
    Uint8List bytes;
    if (last >= 255) {
      int current = last % 255;
      bytes = _main((last / 255).toInt(), index + 1);
      bytes[index] = current;
    } else {
      bytes = Uint8List(index + 2);
      bytes[index] = last;
      bytes[index + 1] = 255;
    }
    return bytes;
  }

  static Uint8List getLength(int length) {
    return _main(length, 0);
  }

  void addBytes(Uint8List raw) {
    int length = raw.length;
    Uint8List content_length = getLength(length);
    this._add(raw, OUT_TYPE_BYTES, content_length);
  }

  void addReader(Stream raw, int length) {
    Uint8List content_length = getLength(length);
    this._add(raw, OUT_TYPE_READER, content_length);
  }

  Future writeTo(Socket writer) async {
    for (int i=0; i< this.raw.length; i++) {
      Object input = this.raw[i];
      if (i%2 == 0) {
        writer.add(input as Uint8List);
      } else {
        int t = this.types[((i-1)/2).toInt()];
        switch (t) {
          case OUT_TYPE_BYTES:
            writer.add(input as Uint8List);
            break;
          case OUT_TYPE_READER:
            Stream reader = input as Stream;
            Completer completer = Completer();
            reader.listen((event) {
              writer.add(event);
            }, onError: (err){
              throw err;
            }, onDone: (){
              completer.complete();
            });
            await completer.future;
            break;
          default:
            break;
        }
      }
    }
  }
}
