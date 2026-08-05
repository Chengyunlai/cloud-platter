# 架构决策记录

本目录保存影响 CloudPlatter 长期实现和维护的重要架构决策（ADR）。

文件名使用 `NNNN-short-title.md`，正文至少包含：状态、背景、决策、后果和替代方案。中文是默认语言；框架、类型和 API 名称保留官方英文。

状态使用：`提议`、`已接受`、`已替代` 或 `已废弃`。已经接受的 ADR 不直接改写结论；需要改变方向时新增一份 ADR，并在两份文档中互相引用。

## 当前决策

- [ADR-0001：使用原生 Swift 并隔离 MediaRemote 边界](0001-native-swift-and-mediaremote-boundary.md)
- [ADR-0002：使用 Swift Package 构建并发布应用包](0002-swift-package-build-and-release.md)
- [ADR-0003：使用系统媒体卡片作为 MVP 播放状态源](0003-control-center-observation-source.md)
