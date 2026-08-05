## 安装提示

这个版本使用 ad-hoc 签名。首次打开时，你可能需要在 macOS“隐私与安全性”设置中手动允许 CloudPlatter；不需要也不建议全局关闭 Gatekeeper。

下载后可以使用同目录的 `.sha256` 文件验证 ZIP 完整性：

```bash
shasum -a 256 -c CloudPlatter-*.zip.sha256
```

## 已验证环境

- macOS：CI 在 GitHub `macos-15` Runner 完成构建、测试和 Universal 打包。
- 动态兼容性：已在 macOS 26.3、网易云音乐 3.1.9 上完成标题、艺人、专辑、封面、进度、
  播放状态和实时切歌验证。

## 已知兼容性

CloudPlatter 会启动系统 `/usr/bin/perl` 子进程，并由它加载应用附带的 BSD-3-Clause
MediaRemote Adapter。该路径依赖未公开的 macOS MediaRemote 行为，系统或网易云音乐升级后
可能失效；应用会先完成能力测试并安全降级，不会要求你关闭系统安全功能。安装包内包含完整
第三方软件声明。
