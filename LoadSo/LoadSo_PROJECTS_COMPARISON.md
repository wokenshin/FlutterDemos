# Flutter FFI SO库加载方案对比文档

## 概述

本文档详细对比两种在Flutter鸿蒙项目中加载SO库的方式：

| 方案 | 项目 | SO库来源 |
|------|------|----------|
| 方案一 | `loadso` | 项目内部通过CMake构建生成 |
| 方案二 | `loadsotwo` | 使用其他项目生成的现成SO库 |

---

## 目录结构对比

### loadso 项目结构

```
loadso/
├── lib/
│   ├── main.dart
│   └── native/
│       └── native_add.dart          # FFI绑定代码
└── ohos/
    └── entry/
        └── src/
            └── main/
                ├── cpp/                      # 原生代码目录
                │   ├── CMakeLists.txt
                │   └── native_add.c
                ├── module.json5
                └── resources/
```

### loadsotwo 项目结构

```
loadsotwo/
├── lib/
│   ├── main.dart
│   └── native/
│       └── native_add.dart              # FFI绑定代码(复用)
└── ohos/
    └── entry/
        └── src/
            └── main/
                ├── cpp/                          # 原生代码目录
                │   ├── CMakeLists.txt
                │   └── native_add.c              # 同样包含C源码
                ├── module.json5
                └── resources/
```

---

## 方案一：项目内CMake构建（loadso）

### 1.1 配置文件差异

| 文件 | loadso | loadsotwo |
|------|--------|-----------|
| `build-profile.json5` | ✅ 包含 `externalNativeOptions` | ✅ 包含 `externalNativeOptions` |
| `CMakeLists.txt` | ✅ 存在 | ✅ 存在 |
| `native_add.c` | ✅ 存在 | ✅ 存在 |

**结论**：两个项目的配置文件完全相同，因为 loadsotwo 也包含了完整的C源码。

### 1.2 核心配置

#### build-profile.json5

两个项目都使用相同的配置：

```json
{
  "apiType": "stageMode",
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
    }
  ]
}
```

#### CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.4.1)
project(native_add)

add_library(native_add SHARED native_add.c)
```

#### native_add.c

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

---

## 方案二：使用现成SO库（loadsotwo）

### 2.1 如果只使用现成SO库（不包含源码）

如果你的 loadsotwo 项目只需要使用 loadso 生成的 SO 库，而不包含C源码，那么配置会有所不同：

#### 不包含C源码时的目录结构

```
loadsotwo/
├── lib/
│   ├── main.dart
│   └── native/
│       └── native_add.dart
└── ohos/
    └── entry/
        └── src/
            └── main/
                └── module.json5
```

#### build-profile.json5（不包含externalNativeOptions）

```json
{
  "apiType": "stageMode",
  "buildOption": {
  },
  "targets": [
    {
      "name": "default",
      "runtimeOS": "HarmonyOS"
    }
  ]
}
```

#### SO库打包配置

你需要将 loadso 生成的 SO 库文件复制到 loadsotwo 的以下位置：

```bash
# 从 loadso 项目复制 SO 库
cp loadso/ohos/entry/build/default/intermediates/libs/default/arm64-v8a/libnative_add.so \
   loadsotwo/ohos/entry/src/main/cpp/
```

并修改 CMakeLists.txt：

```cmake
cmake_minimum_required(VERSION 3.4.1)
project(native_add)

# 导入预编译的SO库
add_library(native_add SHARED IMPORTED)
set_target_properties(native_add PROPERTIES
    IMPORTED_LOCATION ${CMAKE_CURRENT_SOURCE_DIR}/libnative_add.so
)
```

---

## FFI绑定代码对比

### 两个项目的FFI代码完全相同

| 文件 | loadso | loadsotwo | 差异 |
|------|--------|-----------|------|
| `native_add.dart` | ✅ | ✅ | 仅搜索路径中的包名不同 |

### native_add.dart 核心代码

```dart
import 'dart:ffi';
import 'dart:io' as io;
import 'dart:developer' as developer;

void debugLog(String message) {
  developer.log(message, name: 'NativeAdd');
}

// 函数指针类型定义
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
      // 搜索路径列表 - 关键差异点
      final List<String> searchPaths = [
        'libnative_add.so',
        '/system/lib64/libnative_add.so',
        '/system/lib/libnative_add.so',
        '/data/app/el2/100/base/com.example.loadso/lib/arm64/libnative_add.so',      // loadso项目
        '/data/app/com.example.loadso/lib/arm64/libnative_add.so',
        '/data/storage/el2/base/haps/com.example.loadso/lib/arm64/libnative_add.so',
        '/data/app/el2/100/base/com.example.loadsotwo/lib/arm64/libnative_add.so',    // loadsotwo项目
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

      // 查找并绑定函数
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
```

---

## 关键差异总结

| 方面 | loadso（自建SO） | loadsotwo（使用现成SO） |
|------|------------------|------------------------|
| C源码 | 必须包含 | 可以不包含 |
| CMake构建配置 | 必须包含 | 可以不包含 |
| SO库 | 编译时生成 | 手动复制 |
| FFI绑定 | 完全相同 | 完全相同 |
| 搜索路径 | 需要包含自身包名 | 需要包含SO来源项目包名 |

---

## SO库加载流程

```
┌─────────────────────────────────────────────────────────────────┐
│                      Flutter应用启动                              │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 NativeAdd.instance.initialize()                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│            平台识别 (Platform.isAndroid / operatingSystem)        │
│                                                                  │
│    • 鸿蒙: operatingSystem = 'ohos', isAndroid = false          │
│    • 安卓: operatingSystem = 'android', isAndroid = true         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    遍历搜索路径列表                                │
│                                                                  │
│  1. 'libnative_add.so'                                          │
│  2. '/system/lib64/libnative_add.so'                             │
│  3. '/data/app/el2/100/base/com.example.xxx/lib/arm64/...'      │
│  4. ...                                                         │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              DynamicLibrary.open(path) 尝试打开                   │
│                                                                  │
│  成功 ──────────► 继续下一步                                      │
│  失败 ──────────► 尝试下一个路径                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                 查找并绑定函数符号                                │
│                                                                  │
│  _lib.lookup<NativeFunction<AddIntNative>>('add_int')             │
│      .asFunction<AddIntDart>()                                   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                    加载成功/失败                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 鸿蒙平台特殊处理

### 平台识别

```dart
// 鸿蒙平台上
io.Platform.operatingSystem  // 返回 'ohos'
io.Platform.isAndroid        // 返回 false

// 标准安卓平台上
io.Platform.operatingSystem  // 返回 'android'
io.Platform.isAndroid        // 返回 true
```

### 关键代码

```dart
// 必须同时判断 isAndroid 和 operatingSystem == 'ohos'
if (io.Platform.isAndroid || io.Platform.operatingSystem == 'ohos') {
  // 使用 DynamicLibrary.open() 加载
} else {
  // 使用 DynamicLibrary.process() 加载
}
```

---

## SO库打包位置

构建后在以下位置生成 SO 库：

```
ohos/entry/build/default/intermediates/
├── libs/
│   └── default/
│       └── arm64-v8a/
│           ├── libnative_add.so        # 目标SO库
│           ├── libflutter.so
│           └── libc++_shared.so
└── stripped_native_libs/
    └── default/
        └── arm64-v8a/
            └── libnative_add.so        # Strip后的版本
```

---

## 使用第三方SO库的完整流程

### 步骤1：准备SO库

将第三方SO库及其头文件准备好。

### 步骤2：创建C wrapper（如需要）

如果第三方库是C++编写或需要特定接口，创建C wrapper：

```c
// third_party_wrapper.c
#include <stdint.h>
#include "third_party.h"

int32_t wrapper_add(int32_t a, int32_t b) {
    return third_party_add(a, b);
}
```

### 步骤3：配置CMakeLists.txt

```cmake
cmake_minimum_required(VERSION 3.4.1)
project(third_party_wrapper)

add_library(third_party_wrapper SHARED third_party_wrapper.c)

# 链接第三方库
target_link_libraries(third_party_wrapper PUBLIC /path/to/libthird_party.so)
```

### 步骤4：配置build-profile.json5

```json
{
  "apiType": "stageMode",
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
    }
  ]
}
```

### 步骤5：编写FFI绑定

根据第三方库的头文件，编写对应的Dart FFI绑定代码。

### 步骤6：验证打包

构建后检查SO库是否正确打包：

```bash
find . -name "*.so" -path "*/arm64-v8a/*"
```

---

## 常见问题

### Q1: SO库加载失败

**检查项**：
1. 搜索路径是否包含正确的包名
2. SO库是否正确打包到HAP中
3. ABI架构是否匹配

### Q2: 函数符号找不到

**检查项**：
1. 函数名拼写是否正确
2. 是否使用了C++名字修饰规则
3. 使用 `nm -D libxxx.so` 检查导出的符号

### Q3: 运行时崩溃

**检查项**：
1. SO库依赖的其他库是否存在
2. 是否有多线程安全问题
3. 内存管理是否正确

---

## 附录：文件清单

### loadso 项目文件

| 文件路径 | 说明 |
|----------|------|
| `lib/main.dart` | Flutter UI |
| `lib/native/native_add.dart` | FFI绑定 |
| `ohos/entry/src/main/cpp/native_add.c` | C源码 |
| `ohos/entry/src/main/cpp/CMakeLists.txt` | CMake配置 |
| `ohos/entry/build-profile.json5` | 构建配置 |

### loadsotwo 项目文件

| 文件路径 | 说明 |
|----------|------|
| `lib/main.dart` | Flutter UI |
| `lib/native/native_add.dart` | FFI绑定（复用） |
| `ohos/entry/src/main/cpp/native_add.c` | C源码（与loadso相同） |
| `ohos/entry/src/main/cpp/CMakeLists.txt` | CMake配置（与loadso相同） |
| `ohos/entry/build-profile.json5` | 构建配置（与loadso相同） |
