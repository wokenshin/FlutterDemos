# Dart SDK 和 PUB 缓存配置指南

## Dart SDK 位置

在当前 Flutter 仓库项目中，Dart SDK 位于：
```
/Users/kibou/Desktop/Git/Flutter_ohos/bin/cache/dart-sdk/
```

这是 Flutter 工具默认的 Dart SDK 存储位置，Flutter 会自动管理和更新这个 SDK。

## PUB 缓存配置

### 缓存位置

PUB 缓存的默认位置取决于操作系统：
- macOS/Linux: `~/.pub-cache/`
- Windows: `%APPDATA%\Pub\Cache\`

### 自定义 PUB 缓存位置

有两种方法可以自定义 PUB 缓存位置：

1. **通过环境变量**：
   ```bash
   export PUB_CACHE=/path/to/custom/pub-cache
   ```

2. **在 Flutter 根目录创建 `.pub-cache` 目录**：
   如果在 Flutter 根目录创建了 `.pub-cache` 目录，Flutter 工具会自动使用它，无需设置环境变量。

## 离线配置方法

要配置 Flutter 环境以支持离线使用，需要执行以下步骤：

1. **准备 PUB 缓存**：
   - 设置 `PUB_CACHE` 环境变量或在 Flutter 根目录创建 `.pub-cache` 目录

2. **初始化 Flutter 工具**：
   ```bash
   flutter doctor
   ```
   这会检查安装并构建 Flutter 工具的初始快照。

3. **下载所有依赖包**：
   ```bash
   flutter update-packages
   ```
   这会下载 Flutter 主要分发版中所有包的依赖。

4. **预缓存二进制工件**：
   ```bash
   flutter precache
   ```
   确保 Flutter 工具的二进制工件缓存是最新的。

5. **填充模板所需的额外包**：
   ```bash
   # 在临时目录中
   flutter create --template=app app_sample
   flutter create --template=package package_sample
   flutter create --template=plugin plugin_sample
   # 然后删除这些目录
   ```
   这会将创建新 Flutter 项目所需的额外包添加到 pub 缓存中。

## 验证离线配置

完成上述步骤后，您的 Flutter 环境应该可以在离线状态下正常工作，因为所有必要的依赖和工件都已经缓存。

### 注意事项

- 确保在有网络连接时完成上述步骤
- 离线状态下，您仍然可以使用 `flutter run`、`flutter build` 等命令
- 如果需要添加新的依赖包，仍然需要网络连接

通过这种方式配置后，您的 Flutter 环境将能够在没有网络连接的情况下正常工作，非常适合在网络受限的环境中使用。