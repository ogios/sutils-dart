<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->

Socket tools for easier and faster use.


## Features
- `SocketBuffer` allows to read bytes with the given length: `readNBytes(int len)`&`read(byte[])`.
- Byte tools `SocketIn` & `SocketOut` easy to build and read socket body with the given structure.

## Getting started

## Usage

### Customize Socket Buffer
provide functions like java(`readNBytes(int len)`&`read(byte[])`) / go(`read(byte[])`)
```dart
  Socket s = await Socket.connect("localhost", 15002);
  SocketBuffer buffer = SocketBuffer();
  s.write("shit");
  s.listen((event) {
    log("${event.length}");
    buffer.add(event);
  }, onDone: () {
    buffer.done();
    s.destroy();
  }, onError: (err, stack) {
    buffer.err(err);
    s.close();
  });
  Uint8List bs = await buffer.readN(1);
  print(bs);
`````

### Byte tools

base*255 with the last byte of `255` ends the length block

- section
```
section_content_length (base-255) + section_content
```
- body:
```
section + section + ...
```


<!--
## Additional information
-->
