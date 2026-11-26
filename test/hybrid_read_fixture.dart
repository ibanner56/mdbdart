// Runs on the VM for web_test.dart and sends a fixture's bytes to the
// browser. Not ported.

import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

void hybridMain(StreamChannel<Object?> channel, Object? message) {
  channel.sink.add(File('test/data/$message').readAsBytesSync());
  channel.sink.close();
}
