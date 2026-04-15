# Flutter FFI SO库加载指南 - 鸿蒙平台

本文档详细说明如何在Flutter鸿蒙项目中加载和使用原生SO库。

## 目录结构

```
loadso/
├── lib/
│   ├── main.dart                      # Flutter应用入口
│   └── native/
│       └── native_add.dart            # FFI绑定代码
└── ohos/
    └── entry/
        └── src/
            └── main/
                ├── cpp/                        # 原生代码目录
                │   ├── CMakeLists.txt
                │   └── native_add.c
                └── module.json5
```

## 一、原生SO库配置

### 1.1 创建原生C代码

**文件**: `ohos/entry/src/main/cpp/native_add.c`

```c
#include <stdint.h>

int32_t add_int(int32_t a, int32_t b) {
    return a + b;
}

int32_t subtract_int(int32_t a, int32_t b) {
    return a - b;
}

int32_t multiply_int(int32_t a, int32_t b) {
    return a * b;
}

int32_t divide_int(int32_t a, int32_t b) {
    if (b == 0) {
        return 0;
    }
    return a / b;
}
```

### 1.2 创建CMake配置

**文件**: `ohos/entry/src/main/cpp/CMakeLists.txt`

```cmake
cmake_minimum_required(VERSION 3.4.1)
project(native_add)

add_library(native_add SHARED native_add.c)
```

### 1.3 配置模块构建选项

**文件**: `ohos/entry/build-profile.json5`

```json
{
  "apiType": 'stageMode',
  "buildOption": {
    "externalNativeOptions": {
      "path": "./src/main/cpp/CMakeLists.txt",
      "arguments": ""
    }
  },
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS"
    },
    {
      "name": "ohosTest"
    }
  ]
}
```

**关键配置说明**:
- `externalNativeOptions.path`: 指向CMakeLists.txt的路径
- `runtimeOS`: 必须设置为 "HarmonyOS"

---

## 二、Dart FFI绑定代码

### 2.1 添加FFI依赖

**文件**: `pubspec.yaml`

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0
  ffigen: ^15.0.0
```

### 2.2 FFI绑定实现

**文件**: `lib/native/native_add.dart`

```dart
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:developer' as developer;

void debugLog(String message) {
  developer.log(message, name: 'NativeAdd');
}

// 函数指针类型定义 - Native签名
typedef AddIntNative = Int32 Function(Int32 a, Int32 b);
// Dart签名
typedef AddIntDart = int Function(int a, int b);

// 为其他函数重复上述模式...

class NativeAdd {
  static NativeAdd? _instance;
  DynamicLibrary? _lib;

  late final AddIntDart addInt;
  // 其他函数指针...

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
        '/data/app/el2/100/base/com.example.loadso/lib/arm64/libnative_add.so',
        '/data/app/com.example.loadso/lib/arm64/libnative_add.so',
        '/data/storage/el2/base/haps/com.example.loadso/lib/arm64/libnative_add.so',
      ];

      bool libraryLoaded = false;

      // 关键: 鸿蒙平台使用 'ohos' 而非 'android'
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

      // 查找并绑定函数
      addInt = _lib!
          .lookup<NativeFunction<AddIntNative>>('add_int')
          .asFunction<AddIntDart>();
      // 其他函数...

      debugLog('All functions loaded successfully');
      return true;
    } catch (e) {
      _lastError = e.toString();
      debugLog('Exception: $e');
      return false;
    }
  }
}
```

---

## 三、使用示例

### 3.1 在应用中使用

```dart
import 'package:flutter/material.dart';
import 'native/native_add.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FFI Demo',
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initialized = NativeAdd.instance.initialize();
    if (!_initialized) {
      debugPrint('Failed to load: ${NativeAdd.lastError}');
    }
  }

  void _testAdd() {
    if (_initialized) {
      final result = NativeAdd.instance.addInt(10, 5);
      debugPrint('10 + 5 = $result');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(_initialized ? 'SO库已加载' : 'SO库加载失败'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _testAdd,
        child: const Text('测试'),
      ),
    );
  }
}
```

---

## 四、关键知识点

### 4.1 平台识别

Flutter鸿蒙平台上:
- `io.Platform.operatingSystem` 返回 `'ohos'`
- `io.Platform.isAndroid` 返回 `false`

这与标准Android平台不同，必须正确处理。

### 4.2 SO库加载方式

| 平台 | 推荐加载方式 | 说明 |
|------|-------------|------|
| 鸿蒙 (ohos) | `DynamicLibrary.open('libxxx.so')` | 需要显式打开 |
| Android | `DynamicLibrary.open('libxxx.so')` | 优先尝试 |
| iOS | `DynamicLibrary.process()` | 加载主进程 |

### 4.3 FFI函数签名映射

| C类型 | Dart FFI类型 |
|-------|-------------|
| int32_t | Int32 |
| int64_t | Int64 |
| float | Float |
| double | Double |
| void* | Pointer |
| int* | Pointer<Int32> |

### 4.4 函数指针定义规则

```dart
// 1. Native签名: C函数的实际签名
typedef NativeFunc = ReturnType Function(ParamTypes);

// 2. Dart签名: Dart中使用的签名
typedef DartFunc = ReturnType Function(ParamTypes);

// 3. 绑定
dynamicFunc = library
    .lookup<NativeFunction<NativeFunc>>('symbol_name')
    .asFunction<DartFunc>();
```

---

## 五、加载第三方SO库

如果使用第三方SO库:

### 5.1 替换原生代码目录

将第三方SO库的配置替换现有的 `cpp` 目录内容:
- 将SO库的C头文件对应的stub.c放入cpp目录
- 或直接使用库提供的头文件

### 5.2 修改CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.4.1)
project(third_party_lib)

# 假设第三方库的头文件在当前目录
add_library(third_party SHARED third_party_stub.c)

# 链接第三方预编译库(如果需要)
target_link_libraries(third_party PUBLIC /path/to/libthird_party.so)
```

### 5.3 修改FFI绑定

根据第三方库的头文件，修改Dart端的函数签名定义。

### 5.4 SO库打包确认

确保SO库被正确打包到HAP中:
- 检查 `ohos/entry/build/default/intermediates/libs/default/arm64-v8a/` 目录
- SO库文件应该存在于该目录

---

## 六、构建与验证

### 6.1 构建命令

```bash
cd loadso
flutter build ohos --debug
```

### 6.2 验证SO库是否打包

```bash
find . -name "*.so" -path "*/arm64-v8a/*"
```

### 6.3 运行应用

```bash
flutter run -d <设备ID>
```

### 6.4 查看日志

运行应用后，在IDE的日志控制台查看 `NativeAdd` 标签的输出。

---

## 七、常见问题

### Q1: `DynamicLibrary.open()` 失败

**错误**: `Invalid argument(s): Failed to open library`

**解决**:
1. 确认SO库已正确打包到HAP中
2. 尝试使用完整路径
3. 检查SO库的ABI架构是否与设备匹配

### Q2: 函数符号找不到

**错误**: `Symbol not found: xxx`

**解决**:
1. 使用 `nm -D libxxx.so` 检查SO库导出的符号
2. 确认函数名拼写正确
3. 确认使用正确的C++名字修饰规则(mangled name)

### Q3: 平台识别错误

**问题**: `Platform.isAndroid` 在鸿蒙上返回 `false`

**解决**:
```dart
if (io.Platform.isAndroid || io.Platform.operatingSystem == 'ohos') {
  // 鸿蒙或安卓处理
}
```

### Q4: 运行时崩溃

**可能原因**:
1. SO库依赖的其他库缺失
2. ABI架构不匹配
3. 权限问题

**解决**:
1. 使用 `ldd libxxx.so` 检查依赖
2. 确认编译时使用正确的 toolchain
3. 检查设备架构 (arm64-v8a / armeabi-v7a)

---

## 八、最佳实践

1. **始终添加错误处理**: SO库加载和函数查找都可能失败
2. **使用单例模式**: 避免重复加载
3. **添加调试日志**: 方便定位问题
4. **验证平台类型**: 鸿蒙需要特殊处理
5. **测试多路径**: 不同设备SO库位置可能不同
6. **使用ffigen自动生成绑定**: 对于大型库，建议使用ffigen工具自动生成FFI绑定代码
