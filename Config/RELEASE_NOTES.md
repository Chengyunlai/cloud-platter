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
MediaRemote Adapter。事件流为空或不可用时，应用会先通过同一隔离边界执行一次性快照；仍无
可展示状态时，再由系统 `/usr/bin/osascript` 按需执行 MIT 许可的网易云定向 JXA 查询，并在
事件流恢复后停止轮询。这些路径依赖未公开的 macOS
MediaRemote 行为，系统或网易云音乐升级后可能失效；应用会安全降级，不会要求你关闭系统
安全功能。安装包内包含完整第三方软件声明。本项目通过 GitHub Releases 直接分发，不通过
Mac App Store。

## 桌面视觉

CloudPlatter 使用每块显示器一个全屏、点击穿透的桌面层呈现胡桃木唱机场景。场景位于系统
壁纸之上、桌面图标和普通应用窗口之下，不修改系统壁纸文件。当前封面会同时显示在专辑封套
和唱片中心；低分辨率封面会限制放大倍数，并在封套的独立印刷底板中呈现。播放、暂停、
Reduce Motion、屏幕休眠和会话锁定会控制持续动画。
