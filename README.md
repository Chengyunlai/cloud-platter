# CloudPlatter

[English](README.en.md)

[![CI](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml/badge.svg)](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml)

CloudPlatter 是一个开源的 macOS 桌面黑胶唱机，为 Mac 上正在播放的音乐提供轻量、沉浸的可视化体验。

项目首期面向网易云音乐 macOS 客户端：读取本机 Now Playing 信息，把当前歌曲呈现为桌面黑胶场景。CloudPlatter 不替代播放器、不要求登录音乐账号，也不上传用户的收听记录。

## 项目状态

目前处于技术验证和原型阶段。第一个里程碑是验证能否从网易云音乐 macOS 客户端稳定取得只读的 Now Playing 元数据。

## MVP 规划

- 识别网易云音乐的播放、暂停和切歌状态
- 显示当前歌曲标题、艺人、专辑和封面
- 在桌面渲染轻量的黑胶唱机动画
- 通过菜单栏控制显示、登录时启动和减少动态效果
- 全程在本机运行，无需再次登录网易云音乐账号

## 技术方向

- 使用 Swift 和 AppKit 构建 macOS 应用与桌面窗口
- 使用 SwiftUI 和 Core Animation 构建设置界面与唱机动画
- 使用独立、轻量的 MediaRemote 适配层读取只读 Now Playing 数据
- 通过 GitHub Releases 提供可下载的安装包

CloudPlatter 需要使用未公开的 macOS 媒体接口读取其他应用的 Now Playing 数据。这些接口可能随 macOS 版本变化。未经签名和公证的下载版本，也可能需要用户在 macOS“隐私与安全性”设置中手动允许打开。

## 开发与贡献

项目以中文作为默认文档语言，英文文档作为同步翻译。代码标识符使用英文，代码注释使用中文。完整规范请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

```bash
make check
make package VERSION=0.1.0-dev
```

- [项目路线图](docs/ROADMAP.md)
- [领域上下文](CONTEXT.md)
- [架构决策](docs/adr/README.md)

## 独立项目声明

CloudPlatter 是独立、非官方的开源项目，与网易云音乐、Apple 或 Vinyl for Mac 没有从属、合作或背书关系。相关产品名称和作品版权归各自权利人所有。

## 许可证

[MIT](LICENSE)
