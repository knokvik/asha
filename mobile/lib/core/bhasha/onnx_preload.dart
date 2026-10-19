import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';

/// Sherpa looks up ONNX Runtime's `OrtGetApiBase` when its library loads.
/// Dart otherwise opens that runtime with local visibility, so Android cannot
/// see the symbol. Open it for the whole process first.
void preloadOnnxRuntime() {
  if (!Platform.isAndroid) return;
  final process = DynamicLibrary.process();
  final dlopen = process.lookupFunction<
    Pointer<Void> Function(Pointer<Utf8>, Int32),
    Pointer<Void> Function(Pointer<Utf8>, int)
  >('dlopen');
  final dlerror = process.lookupFunction<
    Pointer<Utf8> Function(),
    Pointer<Utf8> Function()
  >('dlerror');
  dlerror();
  final name = 'libonnxruntime.so'.toNativeUtf8();
  try {
    // RTLD_NOW | RTLD_GLOBAL. Android uses the Linux flag values.
    final handle = dlopen(name, 2 | 0x00100);
    if (handle == nullptr) {
      final error = dlerror();
      final message = error.address == 0
          ? 'dlopen returned no error'
          : error.toDartString();
      throw StateError('Could not load the on-phone runtime. $message');
    }
  } finally {
    malloc.free(name);
  }
}
