# ADR-0004：使用隔离的 MediaRemote Adapter 作为播放状态源

- 状态：已接受
- 日期：2026-08-05
- 替代：[ADR-0003](0003-control-center-observation-source.md)

## 背景

macOS 没有提供读取其他应用 Now Playing 信息的公共 API。普通进程直接调用
`MRNowPlayingRequest` 时，即使请求被正确路由到网易云音乐，也会返回
`kMRMediaRemoteFrameworkErrorDomain / 3 / Operation not permitted`；给应用声明 Apple 私有
entitlement 又会被 AMFI 拒绝。因此，CloudPlatter 本身不能直接获得完整 MediaRemote 权限。

Accessibility 可以在主动展开 macOS 控制中心后读取一次媒体卡片，但控制中心会自动关闭，
离屏节点会失效，而且普通进程收不到可用于重新采样的可靠 MediaRemote 或 AX 切歌事件。
周期性展开系统界面会打扰用户，不能满足实时桌面伴侣的体验要求。

公开项目 [ungive/mediaremote-adapter](https://github.com/ungive/mediaremote-adapter) 提供了另一条
边界清晰的兼容路径：由 Apple 随系统提供并已获 MediaRemote 权限的 `/usr/bin/perl` 加载应用
附带的 `MediaRemoteAdapter.framework`，再通过标准输出提供 JSON 快照或实时事件流。项目采用
BSD-3-Clause 许可证，并明确支持 macOS 15.4 及以上版本。

在 macOS 26.3、网易云音乐 3.1.9 的现场验证中，该适配器成功取得
`com.netease.163music` 的来源、播放状态、标题、艺人、专辑、时长、进度和封面；自动发送一次
“下一首”后，`stream` 实时输出了新的匿名字段长度，证明切歌更新链路可用。验证过程没有输出
或保存真实曲名、艺人和封面。

公开资料、源码位置、许可证和现场验证记录见
[macOS 26 上读取网易云音乐 Now Playing 的公开资料调研](../research/now-playing-data-source-2026-08.md)。

## 决策

- 继续使用 Swift、AppKit、SwiftUI 和 Core Animation 构建主应用。
- MVP 使用 `ungive/mediaremote-adapter` 的 BSD-3-Clause 实现作为默认播放状态源，并固定到经过
  审核和兼容性验证的提交；源码分发和二进制安装包都保留上游版权与许可证文本。
- 主应用只受控启动 Apple 系统 `/usr/bin/perl` 子进程，由子进程动态加载应用包内的 helper
  framework。CloudPlatter 不声明 Apple 私有 entitlement，不修改系统二进制，也不向网易云音乐
  进程注入代码。
- MVP 只使用只读的 `test`、`get` 和 `stream` 能力，不暴露上游的播放控制命令。
- 适配层负责子进程生命周期、NDJSON 解码、全量与 diff 状态合并、崩溃重启和指数退避；原始
  MediaRemote 字段不能进入 UI 或渲染层。
- 只有 bundle id 为 `com.netease.163music` 的状态可以转换为 `NowPlayingState`。其他播放器、
  字段缺失、类型变化、helper 失败或来源切换时进入安全降级状态。
- 启动时先运行 capability test。系统缺少 `/usr/bin/perl`、私有框架发生变化或测试失败时，
  不反复拉起子进程，不请求用户关闭安全机制。经独立实现和兼容性测试后，可降级为由
  `/usr/bin/osascript -l JavaScript` 承载的低频 JXA 查询；两条路径都失败时显示明确的兼容性
  提示和默认唱片。
- 默认日志只记录事件类型、字段是否存在、字段类型和错误分类，不记录完整曲名、艺人、封面、
  URL、账号标识或本地路径。封面只在内存中解码和渲染。
- Accessibility 与 ScreenCaptureKit 不再作为默认数据通道；它们只保留为开发诊断或未来经用户
  明确启用的备用方案。

## 后果

- 项目具备实时读取网易云音乐元数据和切歌变化的可行路径，可以继续推进，不需要关闭。
- 默认路径不需要辅助功能、屏幕录制、关闭 SIP/AMFI 或申请 Apple 私有 entitlement。
- 该方案仍依赖未公开的 MediaRemote 行为和 Apple 系统解释器的现有权限，macOS 更新可能随时
  使其失效；它不适合 Mac App Store，必须在 README、安装说明和每次发布说明中披露风险。
- `/usr/bin/perl` 并非 Apple 承诺永久预装的公共运行时。正式发布前必须在支持矩阵中验证目标
  macOS 版本，并把“系统不再提供 Perl”作为可测试的不可用状态。
- JXA 备用路径需要定时查询，实时性和能耗弱于默认事件流；它同样使用私有 MediaRemote，
  不能被描述为 Apple 官方支持的解决方案。
- 上游接口仍处于开发阶段，升级固定提交前需要检查源码、许可证、输出协议和兼容性，并重新跑
  真实客户端的匿名回归测试。
- framework 会增加构建和 Universal 打包步骤；CI 需要验证 arm64/x86_64 架构、资源路径、
  BSD 许可证归档以及安装包内的 capability test。

## 替代方案

- 主应用直接调用 MediaRemote：普通自签进程读取完整元数据会被权限系统拒绝。
- Accessibility 与 ScreenCaptureKit：可以读取主动展开的系统媒体卡片，但不能形成稳定且不打扰
  用户的实时数据通道。
- `kirtan-shah/nowplaying-cli`：已经采用相同 helper 恢复 macOS 26 支持，可作为兼容性旁证；
  整体为 GPL-3.0，不直接复制到 MIT 项目。
- `ejbills/mediaremote-adapter`：提供 Swift Package 封装，但当前仓库没有许可证文件；许可证澄清前
  不作为依赖。
- `/usr/bin/osascript` JXA 查询：本机验证可读取网易云元数据与封面，作为 Perl 适配器失效时的
  备用路径，不作为默认事件源。
- 读取网易云本地文件、社区逆向 API、Cookie 或进程注入：超出项目的隐私和维护边界。
- 关闭 SIP/AMFI 或伪造私有 entitlement：安全代价不可接受，不作为安装路径。
