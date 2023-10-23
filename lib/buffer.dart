library ogios_sutils;

import 'dart:developer';
import 'dart:typed_data';
import 'package:synchronized/synchronized.dart';

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
  final Lock lock = Lock();

  /// Current count of bytes written to buffer.
  int _available = 0;
  int get length => _available;
  bool get isEmpty => _available == 0;
  bool get isNotEmpty => _available != 0;

  /// Current read index.
  int _readIndex = 0;

  /// Current save index
  int _saveIndex = 0;

  /// Internal buffer accumulating bytes.
  ///
  /// Will grow as necessary
  Uint8List _buffer;

  SocketBuffer() : _buffer = _emptyList;

  void add(List<int> bytes) async {
    // sync lock with read and clear
    await lock.synchronized(() async {
      int byteCount = bytes.length;
      if (byteCount == 0) return;
      // how long the list should be to contain all bytes
      int required = _saveIndex + byteCount;
      // expand buffer list if space is not enough
      if (_buffer.length < required) {
        _grow(required);
      }
      assert(_buffer.length >= required);
      // add to buffer
      if (bytes is Uint8List) {
        _buffer.setRange(_saveIndex, required, bytes);
      } else {
        for (int i = 0; i < byteCount; i++) {
          _buffer[_saveIndex + i] = bytes[i];
        }
      }
      // update available bytes
      _saveIndex = required;
      _available += byteCount;

      // debug
      if (debug) log("Buffer add: $byteCount | Buffer available: $_available | save_index: $_saveIndex | Buffer capacity: ${_buffer.length}");
    });
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

  void clear() async {
    // if not pass the threshold, do nothing.
    if (_readIndex < _threshold) return;
    // else, clear data before read index. (sync lock with add and read)
    await lock.synchronized(() async {
      var length = _buffer.length - (_readIndex + 1);
      var newBuffer = Uint8List(length);
      newBuffer.setRange(0, length, Uint8List.view(_buffer.buffer, _readIndex));
      _buffer = newBuffer;
      _saveIndex -= _readIndex;
      _readIndex = 0;
    });
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

  Future<Uint8List> _readN(int length) async {
    if (this._done && _available == 0) throw Exception("EOF");
    checkErr();
    if (length == 0) return _emptyList;
    Uint8List buffer = Uint8List(length);
    int read = await this._read(buffer);
    if (read == 0) throw Exception("EOF");
    return buffer.sublist(0, read);
  }

  Future<Uint8List> readN(int length) async {
    return await this._readN(length);
  }

  Future<int> read(Uint8List emptybs) async {
    return await this._read(emptybs);
  }

  Future<int> _read(Uint8List emptybs) async {
    if (this._done && _available == 0) throw Exception("EOF");
    if (emptybs.length == 0) return 0;
    int inputIndex = 0;
    int total_read = 0;
    int left = emptybs.length;

    while (left > 0 && (!this._done || _available != 0)) {
      checkErr();
      bool wait_flag = false;

      // sync with add and done
      await lock.synchronized(() async {
        if (_available == 0) {
          // if no data, wait for 10ms
          wait_flag = true;
        } else {
          // else
          if (_available <= left) {
            // if available data is not enough
            if (debug) log("(NOT ENOUGH) | left: $left | ava_before: ${_available} | ava_after: ${0} | readInd_before: ${_readIndex} | readInd_after: ${_readIndex + _available}");
            emptybs.setRange(inputIndex, inputIndex + _available,
                _buffer.sublist(_readIndex, _readIndex + _available));
            total_read += _available;
            left -= _available;
            inputIndex += _available;
            _readIndex += _available;
            _available = 0;
          } else {
            // else fill up empty list
            if(debug) log("(FILL LEFT) | left: $left | ava_before: ${_available} | ava_after: ${_available - left} | readInd_before: ${_readIndex} | readInd_after: ${_readIndex + left}");
            emptybs.setRange(inputIndex, emptybs.length,
                Uint8List.view(_buffer.buffer, _readIndex, left));
            total_read += left;
            inputIndex += left;
            _readIndex += left;
            _available -= left;
            left = 0;
          }
        }
      });
      // wait for data
      if (wait_flag) await Future.delayed(const Duration(milliseconds: 10));
    }

    // debug
    if (debug) log("return total_read: $total_read");
    return total_read;
  }

  //debug
  bool debug = false;

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
