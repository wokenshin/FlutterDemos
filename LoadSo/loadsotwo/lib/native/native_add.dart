import 'dart:ffi';
import 'dart:io' as io;
import 'dart:developer' as developer;

void debugLog(String message) {
  developer.log(message, name: 'NativeAdd');
}

typedef AddIntNative = Int32 Function(Int32 a, Int32 b);
typedef AddIntDart = int Function(int a, int b);

typedef SubtractIntNative = Int32 Function(Int32 a, Int32 b);
typedef SubtractIntDart = int Function(int a, int b);

typedef MultiplyIntNative = Int32 Function(Int32 a, Int32 b);
typedef MultiplyIntDart = int Function(int a, int b);

typedef DivideIntNative = Int32 Function(Int32 a, Int32 b);
typedef DivideIntDart = int Function(int a, int b);

class NativeAdd {
  static NativeAdd? _instance;
  DynamicLibrary? _lib;

  late final AddIntDart addInt;
  late final SubtractIntDart subtractInt;
  late final MultiplyIntDart multiplyInt;
  late final DivideIntDart divideInt;

  static String _lastError = '';

  static String get lastError => _lastError;

  NativeAdd._();

  static NativeAdd get instance {
    _instance ??= NativeAdd._();
    return _instance!;
  }

  bool initialize() {
    _lastError = '';
    debugLog('Platform: ${io.Platform.operatingSystem}');
    debugLog('Is Android: ${io.Platform.isAndroid}');

    try {
      final List<String> searchPaths = [
        'libnative_add.so',
        '/system/lib64/libnative_add.so',
        '/system/lib/libnative_add.so',
        '/data/app/el2/100/base/com.example.loadsotwo/lib/arm64/libnative_add.so',
        '/data/app/com.example.loadsotwo/lib/arm64/libnative_add.so',
        '/data/storage/el2/base/haps/com.example.loadsotwo/lib/arm64/libnative_add.so',
      ];

      bool libraryLoaded = false;

      if (io.Platform.isAndroid || io.Platform.operatingSystem == 'ohos') {
        for (final path in searchPaths) {
          try {
            debugLog('Trying: $path');
            _lib = DynamicLibrary.open(path);
            debugLog('Opened: $path');
            libraryLoaded = true;
            break;
          } catch (e) {
            debugLog('Failed: $path');
          }
        }

        if (!libraryLoaded) {
          try {
            debugLog('Trying process()...');
            _lib = DynamicLibrary.process();
            debugLog('Using process()');
            libraryLoaded = true;
          } catch (e) {
            debugLog('process() failed: $e');
          }
        }
      } else {
        _lib = DynamicLibrary.process();
        libraryLoaded = true;
      }

      if (_lib == null || !libraryLoaded) {
        _lastError = 'Failed to load library';
        return false;
      }

      addInt = _lib!
          .lookup<NativeFunction<AddIntNative>>('add_int')
          .asFunction<AddIntDart>();

      subtractInt = _lib!
          .lookup<NativeFunction<SubtractIntNative>>('subtract_int')
          .asFunction<SubtractIntDart>();

      multiplyInt = _lib!
          .lookup<NativeFunction<MultiplyIntNative>>('multiply_int')
          .asFunction<MultiplyIntDart>();

      divideInt = _lib!
          .lookup<NativeFunction<DivideIntNative>>('divide_int')
          .asFunction<DivideIntDart>();

      debugLog('All functions loaded successfully');
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugLog('Exception: $e');
      return false;
    }
  }
}