import 'dart:io';
import 'dart:typed_data';

Future<String?> persistReactAudioClip(String name, Uint8List bytes) async {
  final directory = Directory('${Directory.systemTemp.path}${Platform.pathSeparator}react_audio');
  if (!await directory.exists()) {
    await directory.create(recursive: true);
  }

  final file = File('${directory.path}${Platform.pathSeparator}$name.wav');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
