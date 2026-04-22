# Linux 系统指定本地 Dart SDK 配置指南

## 问题背景
在 Linux 系统中，通过 `git clone` 下载的 Flutter SDK 默认会在首次运行时自动下载 Dart SDK 到 `flutter/bin/cache/dart-sdk` 目录。本文档介绍如何指定本地已下载的 Dart SDK 并阻止 Flutter 自动下载 SDK。

## 配置步骤

### 步骤 1：确认本地 Dart SDK 路径
1. 从 [Dart 官网](https://dart.dev/get-dart) 下载对应版本的 Dart SDK
2. 解压到本地目录（例如 `~/dart-sdk`）
3. 确认目录结构：`~/dart-sdk/bin/dart` 应存在

### 步骤 2：停止 Flutter 自动下载 SDK
Flutter 首次运行时会检查 `flutter/bin/cache/dart-sdk` 目录是否存在。若不存在，会自动下载。因此需要：

1. **删除或备份** Flutter 自带的 dart-sdk 目录（如果存在）：
   ```bash
   # 假设 Flutter 安装在 ~/flutter
   rm -rf ~/flutter/bin/cache/dart-sdk
   ```

### 步骤 3：将本地 Dart SDK 与 Flutter 关联

#### 方法 A：创建符号链接（推荐）
通过符号链接将本地 Dart SDK 关联到 Flutter 的 `bin/cache/dart-sdk` 目录：

```bash
# 假设本地 Dart SDK 位于 ~/dart-sdk
# 假设 Flutter 安装在 ~/flutter
ln -s ~/dart-sdk ~/flutter/bin/cache/dart-sdk
```

#### 方法 B：通过环境变量指定（可选）
设置 `DART_HOME` 环境变量指向本地 Dart SDK：

```bash
export DART_HOME=~/dart-sdk
export PATH=$DART_HOME/bin:$PATH
```

> **注意**：此方式可能不被所有 Flutter 命令完全支持，部分命令仍可能依赖内置 SDK。

### 步骤 4：验证配置
执行以下命令验证配置是否成功：

```bash
# 检查 Dart 版本（应显示本地 Dart SDK 版本）
~/flutter/bin/dart --version

# 运行 Flutter 命令（不应再下载 SDK）
flutter doctor
```

## 注意事项

### 1. 版本兼容性
本地 Dart SDK 版本必须与 Flutter 版本兼容。例如：
- Flutter 3.10+ 通常需要 Dart 3.0+
- Flutter 3.0+ 通常需要 Dart 2.17+

### 2. 权限问题
确保：
- 符号链接创建成功
- Flutter 有权限访问本地 Dart SDK 目录
- 本地 Dart SDK 目录权限正确（可执行文件应有执行权限）

### 3. 路径更新
如果后续更新本地 Dart SDK：
1. 下载并解压新版本到 `~/dart-sdk` 目录
2. 无需重新创建符号链接（指向目录的链接会自动指向新内容）

### 4. 故障排查
若执行 Flutter 命令时仍提示下载 SDK：
1. 检查符号链接是否正确创建：`ls -la ~/flutter/bin/cache/dart-sdk`
2. 确认本地 Dart SDK 目录结构完整：`ls -la ~/dart-sdk/bin/`
3. 尝试重新创建符号链接

## 总结
通过创建符号链接将本地 Dart SDK 关联到 Flutter 的 `bin/cache/dart-sdk` 目录，可以：
- 避免 Flutter 自动下载 SDK
- 使用指定的本地 Dart SDK 版本
- 提高 Flutter 命令执行速度（无需等待下载）

此配置适用于需要控制 Dart SDK 版本或网络环境受限的场景。