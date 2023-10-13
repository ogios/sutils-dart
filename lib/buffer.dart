library ogios_sutils;

import 'dart:typed_data';
import 'package:mutex/mutex.dart';

class SocketBuffer {
  /// Initial size of internal buffer.
  static const int _initSize = 1024;

  /// Free space threshold
  static const int _threshold = 1024 * 4;

  /// Reusable empty [Uint8List].
  ///
  /// Safe for reuse because a fixed-length empty list is immutable.
  static final _emptyList = Uint8List(0);

  /// lock
  final Mutex m = Mutex();

  /// Current count of bytes written to buffer.
  int _length = 0;

  /// Current readed index.
  int _readIndex = 0;

  /// Internal buffer accumulating bytes.
  ///
  /// Will grow as necessary
  Uint8List _buffer;

  SocketBuffer() : _buffer = _emptyList;

  void add(List<int> bytes) {
    m.acquire();
    Object? e;
    try {
      int byteCount = bytes.length;
      if (byteCount == 0) return;
      int required = _length + byteCount;
      if (_buffer.length < required) {
        _grow(required);
      }
      assert(_buffer.length >= required);
      if (bytes is Uint8List) {
        _buffer.setRange(_length, required, bytes);
      } else {
        for (int i = 0; i < byteCount; i++) {
          _buffer[_length + i] = bytes[i];
        }
      }
      _length = required;
    } catch (err) {
      e = err;
    } finally {
      m.release();
    }
    if (e != null) throw e;
  }

  void _grow(int required) {
    // We will create a list in the range of 2-4 times larger than
    // required.
    int newSize = required * 2;
    if (newSize < _initSize) {
      newSize = _initSize;
    } else {
      newSize = _pow2roundup(newSize);
    }
    var newBuffer = Uint8List(newSize);
    newBuffer.setRange(0, _buffer.length, _buffer);
    _buffer = newBuffer;
  }

  void _decrease() {
    if (_readIndex < _threshold) return;
    var length = _buffer.length - (_readIndex + 1);
    var newBuffer = Uint8List(length);
    newBuffer.setRange(0, length, Uint8List.view(_buffer.buffer, _readIndex));
    _readIndex = 0;
    _buffer = newBuffer;
  }

  int get length => _length;

  bool get isEmpty => _length == 0;

  bool get isNotEmpty => _length != 0;

  void clear() {
    _clear();
  }

  void _clear() {
    _length = 0;
    _readIndex = 0;
    _buffer = _emptyList;
  }

  /// Rounds numbers <= 2^32 up to the nearest power of 2.
  static int _pow2roundup(int x) {
    assert(x > 0);
    --x;
    x |= x >> 1;
    x |= x >> 2;
    x |= x >> 4;
    x |= x >> 8;
    x |= x >> 16;
    return x + 1;
  }

  Future<Uint8List> readN(int length) async {
    if (this._done) throw Exception("EOF");
    checkErr();
    if (length == 0) return _emptyList;
    Uint8List buffer = Uint8List(1);
    int read = await this.read(buffer);
    if (read == 0) throw Exception("EOF");
    return buffer.sublist(0, read);
  }

  Future<int> read(Uint8List emptybs) async {
    if (this._done) throw Exception("EOF");
    if (emptybs.length == 0) return 0;
    int inputIndex = 0;
    int total = 0;
    int left = emptybs.length;

    m.acquire();
    Object? e;
    try {
      while (left > 0 && (!this._done || _length != 0)) {
        checkErr();
        while (_length == 0) {
          checkErr();
          if (this._done && _length == 0){
            break;
          }
          await Future.delayed(Duration(milliseconds: 10));
        }
        if (_length <= left) {
          emptybs.setRange(inputIndex, _length, _buffer);
          total += _length;
          left -= _length;
          inputIndex += _length;
          _clear();
        } else {
          emptybs.setRange(inputIndex, emptybs.length,
              Uint8List.view(_buffer.buffer, _readIndex, left));
          total += left;
          inputIndex += left;
          _readIndex += left;
          _length -= left;
          left = 0;
          _decrease();
        }
      }
      return total;
    } catch (err) {
      e = err;
    } finally {
      m.release();
    }
    throw e;
  }

  bool _done = false;
  Exception? _err;

  void done() {
    this._done = true;
  }

  void err(Exception err) {
    if (!err.toString().toLowerCase().contains("connection reset by peer")) {
      this._err = err;
    }
    this._done = true;
  }

  bool isDone() {
    checkErr();
    return this._done;
  }

  void checkErr() {
    if (this._err != null) throw _err!;
  }
}
