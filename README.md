# CloudPlatter

[English](README.en.md)

[![CI](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml/badge.svg)](https://github.com/Chengyunlai/cloud-platter/actions/workflows/ci.yml)

当你在 Mac 上播放网易云音乐时，CloudPlatter 会在桌面呈现一台随音乐转动的黑胶唱机，让当前歌曲拥有轻量、沉浸的视觉陪伴。

你可以继续使用熟悉的网易云音乐客户端：CloudPlatter 只读取本机 Now Playing 信息，不替代播放器、不要求再次登录音乐账号，也不上传你的收听记录。

## 项目状态

目前处于技术验证和原型阶段。已确认网易云音乐会把当前媒体展示在 macOS 控制中心，
并能通过公开的系统辅助功能与屏幕捕获能力读取；仍在验证切歌、客户端重启和不同内容
类型下的稳定性。

## MVP 规划

- 识别网易云音乐的播放、暂停和切歌状态
- 显示当前歌曲标题、艺人、专辑和封面
- 在桌面渲染轻量的黑胶唱机动画
- 通过菜单栏控制显示、登录时启动和减少动态效果
- 全程在本机运行，无需再次登录网易云音乐账号

## 技术方向

- 使用 Swift 和 AppKit 构建 macOS 应用与桌面窗口
- 使用 SwiftUI 和 Core Animation 构建设置界面与唱机动画
- 使用可替换的播放状态源，通过 macOS Accessibility 读取系统媒体卡片
- 在用户允许时使用 ScreenCaptureKit 在内存中取得封面，不保存系统截图
- 通过 GitHub Releases 提供可下载的安装包

CloudPlatter 需要你授予“辅助功能”权限；显示真实封面时还需要“屏幕与系统音频录制”
权限。应用不会保存系统截图或上传收听记录。未经签名和公证的下载版本，也可能需要你在
macOS“隐私与安全性”设置中手动允许打开。

## 开发与贡献

项目以中文作为默认文档语言，英文文档作为同步翻译。代码标识符使用英文，代码注释使用中文。完整规范请阅读 [CONTRIBUTING.md](CONTRIBUTING.md)。

```bash
make check
make package VERSION=0.1.0-dev
```

- [项目路线图](docs/ROADMAP.md)
- [领域上下文](CONTEXT.md)
- [架构决策](docs/adr/README.md)
- [安全政策](SECURITY.md)

## 独立项目声明

CloudPlatter 是独立、非官方的开源项目，与网易云音乐、Apple 或 Vinyl for Mac 没有从属、合作或背书关系。相关产品名称和作品版权归各自权利人所有。

## 许可证

[MIT](LICENSE)
