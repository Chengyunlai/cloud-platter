# ADR-0001：使用原生 Swift 并隔离 MediaRemote 边界

- 状态：已接受
- 日期：2026-08-04

## 背景

CloudPlatter 只面向 macOS。核心难点是读取跨应用 Now Playing、管理桌面层窗口、控制常驻动画能耗，以及在未公开系统接口变化时安全降级。

Apple 的公开 MediaPlayer API 允许播放器发布自己的 Now Playing，但没有公开读取其他应用当前媒体的接口。网易云音乐客户端已经向系统 Now Playing 发布数据，因此项目需要一个很薄的 MediaRemote 私有适配层。

## 决策

- 使用 Swift、AppKit、SwiftUI 和 Core Animation 构建应用。
- MediaRemote 的动态加载、符号、通知和原始字典只存在于独立适配层。
- 其他模块只依赖规范化的 Now Playing State。
- 私有能力运行时探测；缺失或变化时进入安全降级状态。
- MVP 采用 GitHub Releases 直接分发，不以 Mac App Store 为目标。

## 后果

- macOS 集成路径最短，菜单栏、窗口层级和能耗控制可以直接使用系统框架。
- 私有 API 风险集中在一个可替换模块中，但仍需要跨 macOS 版本持续验证。
- Electron/Tauri 的跨平台优势对当前产品没有收益，因此不承担额外运行时和桥接成本。

## 替代方案

- Accessibility：公开但需要敏感权限，且网易云音乐 CEF UI 变化会导致读取不稳定。
- Electron/Tauri：能够实现视觉，但不能消除 MediaRemote 风险，并增加原生桥接。
- 社区网易云音乐 API 或进程注入：隐私、条款和维护风险不可接受。
