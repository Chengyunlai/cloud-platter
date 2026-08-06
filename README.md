# CloudPlatter

[English](README.en.md)

[![CI](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml/badge.svg)](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml)

当你在 Mac 上播放网易云音乐时，CloudPlatter 会把桌面变成一张随音乐变化的全屏胡桃木唱机
场景，让当前歌曲的封面、黑胶和唱臂成为桌面背景的一部分。

你可以继续使用熟悉的网易云音乐客户端：CloudPlatter 读取本机 Now Playing 信息，并提供上一首、
播放/暂停和下一首三个桌面按钮；它不替代播放器、不要求再次登录音乐账号，也不上传你的收听记录。

## 项目状态

目前处于技术验证和原型阶段。已在 macOS 26.3 与网易云音乐 3.1.9 上验证实时读取标题、
艺人、专辑、封面、播放状态和切歌更新；仍需完成更多内容类型、客户端重启和系统版本的
兼容性验证。

## MVP 规划

- 识别网易云音乐的播放、暂停和切歌状态
- 显示当前歌曲标题、艺人、专辑和封面
- 在每块显示器上渲染点击穿透的全屏动态唱机桌面
- 在桌面使用上一首、播放/暂停和下一首控制当前网易云音乐
- 通过菜单栏控制显示、登录时启动和减少动态效果
- 全程在本机运行，无需再次登录网易云音乐账号

## 技术方向

- 使用 Swift 和 AppKit 构建 macOS 应用与位于桌面层的多显示器全屏窗口
- 使用 SwiftUI 和 Core Animation 构建设置界面与唱机动画
- 使用可替换的播放状态源，由系统 `/usr/bin/perl` 子进程加载隔离的 MediaRemote helper；
  事件流为空、不可用或静默超时后先执行一次性 MediaRemote 快照，仍无结果时再由
  `/usr/bin/osascript` 按需执行网易云定向查询
- 在应用边界过滤网易云音乐来源，并把私有字段转换为项目自己的播放状态
- 发送播放命令前即时复核当前来源，避免控制其他播放器
- 通过 GitHub Releases 提供可下载的安装包

默认读取路径及按需备用路径都不需要“辅助功能”或“屏幕与系统音频录制”权限，也不会上传
收听记录。它们依赖 Apple 未公开的 MediaRemote 行为以及 macOS 当前附带的 `/usr/bin/perl`
和 `/usr/bin/osascript`，可能随系统更新
失效，不适合通过 Mac App Store 分发；应用会先自检并在不兼容时安全降级。未经签名和公证的下载版本，也可能需要你在
macOS“隐私与安全性”设置中手动允许打开。详细技术边界见
[ADR-0004](docs/adr/0004-isolated-mediaremote-adapter.md)。

## 开发与贡献

项目以中文作为默认文档语言，英文文档作为同步翻译。代码标识符使用英文，代码注释使用中文。完整规范请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

```bash
git submodule update --init --recursive
make check
make adapter
make package VERSION=0.1.0-dev
```

- [项目路线图](docs/ROADMAP.md)
- [领域上下文](CONTEXT.md)
- [架构决策](docs/adr/README.md)
- [播放状态源技术调研](docs/research/now-playing-data-source-2026-08.md)
- [macOS 26.3 / 网易云音乐 3.1.9 兼容矩阵](docs/compatibility/macos-26-netease-3.1.9.md)
- [第三方软件声明](THIRD_PARTY_NOTICES.md)
- [安全政策](SECURITY.md)

## 独立项目声明

CloudPlatter 是独立、非官方的开源项目，与网易云音乐、Apple 或 Vinyl for Mac 没有从属、合作或背书关系。相关产品名称和作品版权归各自权利人所有。

## 许可证

[MIT](LICENSE)
