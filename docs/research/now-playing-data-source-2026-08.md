# macOS 26 上读取网易云音乐 Now Playing 的公开资料调研

- 日期：2026-08-05
- 验证环境：macOS 26.3（25D125）、网易云音乐 3.1.9（3364）
- 目标：在普通 GitHub 直装、自签或 ad-hoc 签名、不读取 Cookie、不调用网易云社区逆向 API、
  不附加或修改网易云进程的前提下，实时取得当前曲目的标题、艺人、播放状态与封面。

## 结论

**项目不应关闭，建议继续（Go）。** 之前的“普通自签进程直接调用 MediaRemote 会被拒绝”
结论本身成立，但它不等于“普通直装应用无法取得数据”。公开源码给出了两条已经在本机复验
成功的 Apple 签名宿主路线：

1. **首选：`/usr/bin/perl` + 随 App 分发的 MediaRemote 适配框架。** App 启动 Apple
   自带的 Perl 子进程，Perl 通过 `DynaLoader` 加载我们的 ad-hoc 签名框架；框架在该子进程中
   订阅 MediaRemote 通知并通过 stdout 实时输出 JSON。它能取得网易云的标题、艺人、专辑、
   进度、播放状态和 JPEG 封面，切歌时会立即产生更新。
2. **备选：`/usr/bin/osascript -l JavaScript`（JXA）轮询。** 不需要自定义原生宿主，
   通过 Apple 签名的 `osascript` 调用 `MRNowPlayingRequest`；公开项目已针对
   `com.netease.163music` 实现曲目级查询与封面回调，默认每秒轮询。本机同样验证成功。

这两条路线都仍然使用 Apple 私有 MediaRemote，不能承诺跨系统版本永久稳定，也不适合
Mac App Store；但项目原本就是 GitHub 直装版。它们无需辅助功能或屏幕录制权限，不读取
网易云文件、Cookie 或历史，也不向网易云进程注入代码。

需要明确披露：Perl 路线会在**由我们创建的 Apple Perl 子进程**里动态加载自带框架。
这不是附加、修改或注入网易云进程，但如果项目把“不注入进程”解释为“任何进程都不能加载
我们的动态代码”，则只能采用 JXA 轮询方案。

## 1. Apple 公共 API 的边界

### 1.1 `MPNowPlayingInfoCenter` 是发布接口，不是跨应用读取接口

Apple 对 [`MPNowPlayingInfoCenter`](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter)
和 [`nowPlayingInfo`](https://developer.apple.com/documentation/mediaplayer/mpnowplayinginfocenter/nowplayinginfo)
的公开说明是让播放应用向系统提供 Now Playing 信息。公开 MediaPlayer API 没有“读取其他
应用当前媒体”的对称接口。因此，直接在 CloudPlatter 进程里使用公开 API 无法完成目标。

### 1.2 Accessibility、ScreenCaptureKit 能工作，但不是理想主数据源

Apple 的公开 Accessibility API 提供
[`AXUIElementCopyAttributeValue`](https://developer.apple.com/documentation/applicationservices/1459138-axuielementcopyattributevalue)
和 [`AXObserver`](https://developer.apple.com/documentation/applicationservices/axobserver)，
ScreenCaptureKit 提供窗口/屏幕内容捕获（Apple 示例：
[Capturing screen content in macOS](https://developer.apple.com/documentation/screencapturekit/capturing-screen-content-in-macos)）。
这些 API 解释了为什么控制中心卡片的文本和可见封面可以被读取，但也意味着辅助功能、屏幕
录制权限和系统 UI 生命周期会进入关键路径。此前本机 Spike 已证明控制中心会自动关闭，
离屏截图会失败，因此它适合作为诊断或降级路径，不应再作为首选实时数据源。

### 1.3 `DistributedNotificationCenter` 不是统一 Now Playing 总线

Apple 将
[`DistributedNotificationCenter`](https://developer.apple.com/documentation/foundation/distributednotificationcenter)
定义为同一用户会话中任务间的通知中心，但通知名称和 `userInfo` 都由发布方约定。Vinyl 的
[隐私政策](https://www.vinylformac.com/privacy.html)只明确说它读取 Spotify 桌面端发布的
本地播放变化通知；网站首页虽宣称同时支持 Spotify 与 Apple Music，但没有公开 Vinyl 源码，
不能据此推断网易云也发布同类通知。

一个开源同类项目 Vinilo 的实际源码更清楚地展示了这种应用专用实现：它监听
`com.spotify.client.PlaybackStateChanged` 与 `com.apple.Music.playerInfo`，随后分别用
AppleScript 查询 Spotify/Music，而不是从通知中心读取任意播放器：
[NowPlayingModel.swift 第 45–85 行](https://github.com/Railly/vinilo/blob/6ca38d299b378ecde4f643a7a7474ba677ba4edf/Sources/vinilo/NowPlayingModel.swift#L45-L85)。
公开代码检索没有找到网易云 3.x 等价的稳定通知协议，故不能把这条 Spotify 路径照搬过来。

### 1.4 AppleScript / ScriptingBridge 没有网易云曲目字典

Apple 的 [`ScriptingBridge`](https://developer.apple.com/documentation/scriptingbridge) 依赖目标
应用公开的脚本字典。本机检查 `/Applications/NeteaseMusic.app/Contents`，网易云 3.1.9
没有 `.sdef`、`.scriptSuite` 或 `.scriptTerminology`；其 `Info.plist` 也没有脚本能力声明。
因此只能通过 System Events 做 UI 自动化，不能像 Spotify 或 Music 那样请求
`current track`。旧项目 `NeteaseMusic2OBS` 正是按窗口层级读取网易云 UI，并直接操作图片
缓存：[nm2obs.sh 第 34–87 行](https://github.com/lihaoyun6/NeteaseMusic2OBS/blob/149bbcdb6077ff53c3e5faa9bc3e47392c32aee2/nm2obs.sh#L34-L87)。
该结构已不适配当前 CEF 客户端，也会引入辅助功能权限和缓存隐私问题。

## 2. macOS 15.4/26 的 MediaRemote 变化与公开解法

### 2.1 自签 App 直接读取失败是已知系统变化

`nowplaying-cli` 在 macOS 15.4 后失效的公开 Issue 记录了同样现象：
[kirtan-shah/nowplaying-cli#28](https://github.com/kirtan-shah/nowplaying-cli/issues/28)。
其讨论随后给出两类恢复方案：AppleScript/JXA 的 `MRNowPlayingRequest`，以及使用 Apple
平台二进制加载自定义适配框架。项目作者在 2026-04 的 macOS 15/26 版本中采用后者恢复支持。

本项目先前的原生探针也与此一致：直接查询为空，显式请求返回
`kMRMediaRemoteFrameworkErrorDomain / 3 / Operation not permitted`；给自签 App 添加私有
读取 entitlement 后被 AMFI 终止。这个结果只否定“由 CloudPlatter 自身承载调用”。

### 2.2 `/usr/bin/perl` 适配器：事件驱动且无需开发工具

高价值参考实现是
[`ungive/mediaremote-adapter`](https://github.com/ungive/mediaremote-adapter/tree/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a)：

- README 明确说明 macOS 15.4+ 和 macOS 26，机制是由 `/usr/bin/perl` 加载自定义框架并把
  实时更新写到 stdout：
  [第 25–33 行](https://github.com/ungive/mediaremote-adapter/blob/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a/README.md#L25-L33)。
- Perl 脚本用标准 `DynaLoader::dl_load_file` 加载框架，并安装、调用导出符号：
  [mediaremote-adapter.pl 第 105–123 行](https://github.com/ungive/mediaremote-adapter/blob/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a/bin/mediaremote-adapter.pl#L105-L123)、
  [第 270–279 行](https://github.com/ungive/mediaremote-adapter/blob/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a/bin/mediaremote-adapter.pl#L270-L279)。
- 框架通过运行时符号获取 MediaRemote 函数，不在主 App 中链接私有框架：
  [MediaRemote.m 第 77–112 行](https://github.com/ungive/mediaremote-adapter/blob/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a/src/private/MediaRemote.m#L77-L112)。
- `stream` 注册 MediaRemote 通知并维持 run loop，是真正的事件流而非截图轮询：
  [stream.m 第 367–488 行](https://github.com/ungive/mediaremote-adapter/blob/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a/src/adapter/stream.m#L367-L488)。
- 构建配置同时产出 x86_64/arm64，并对框架做 ad-hoc 签名：
  [CMakeLists.txt 第 35–76 行](https://github.com/ungive/mediaremote-adapter/blob/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a/CMakeLists.txt#L35-L76)。
- 输出覆盖标题、艺人、专辑、时长、进度、状态和封面：
  [README 第 133–200 行](https://github.com/ungive/mediaremote-adapter/blob/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a/README.md#L133-L200)。

`/usr/bin/perl` 在本机 macOS 26.3 仍然存在，版本为 5.34.1，代码签名标识为
`com.apple.perl` 且具有 platform identifier 26。它不要求用户安装 Xcode 或 Command Line
Tools。

### 2.3 `/usr/bin/osascript` JXA：更轻的每秒轮询备选

[`Innei/YohakuCompanion`](https://github.com/Innei/YohakuCompanion/tree/470bc72ae78b2465c1ddfb8fcb48f1fff63040b1)
提供了直接针对网易云的当前实现：

- 源码明确说明查询运行在 Apple 签名的 `osascript` 中，并将
  `com.netease.163music` 列为目标播放器：
  [JXAMediaInfoProvider.swift 第 7–24 行](https://github.com/Innei/YohakuCompanion/blob/470bc72ae78b2465c1ddfb8fcb48f1fff63040b1/YohakuCompanion/Core/MediaInfoManager/JXAMediaInfoProvider.swift#L7-L24)。
- JXA 加载 MediaRemote、构造播放器路径、请求 info/isPlaying/artwork：
  [第 148–320 行](https://github.com/Innei/YohakuCompanion/blob/470bc72ae78b2465c1ddfb8fcb48f1fff63040b1/YohakuCompanion/Core/MediaInfoManager/JXAMediaInfoProvider.swift#L148-L320)。
- 默认每秒轮询，并实际启动 `/usr/bin/osascript -l JavaScript`：
  [第 385–424 行](https://github.com/Innei/YohakuCompanion/blob/470bc72ae78b2465c1ddfb8fcb48f1fff63040b1/YohakuCompanion/Core/MediaInfoManager/JXAMediaInfoProvider.swift#L385-L424)、
  [第 470–486 行](https://github.com/Innei/YohakuCompanion/blob/470bc72ae78b2465c1ddfb8fcb48f1fff63040b1/YohakuCompanion/Core/MediaInfoManager/JXAMediaInfoProvider.swift#L470-L486)。

另一个当前项目 MusicIsland 采用 `/usr/bin/swift` 承载同样查询，并订阅 MediaRemote 通知：
[NowPlayingHelperProcess.swift 第 5–12 行](https://github.com/James-Kua/MusicIsland/blob/797227adaf0d89a7ae3c44540af77c173b84af78/Sources/MusicIsland/NowPlaying/NowPlayingHelperProcess.swift#L5-L12)、
[第 205–310 行](https://github.com/James-Kua/MusicIsland/blob/797227adaf0d89a7ae3c44540af77c173b84af78/Sources/MusicIsland/NowPlaying/NowPlayingHelperProcess.swift#L205-L310)。
但它的源码也承认 `/usr/bin/swift` 需要开发工具链：
[第 122–139 行](https://github.com/James-Kua/MusicIsland/blob/797227adaf0d89a7ae3c44540af77c173b84af78/Sources/MusicIsland/NowPlaying/NowPlayingHelperProcess.swift#L122-L139)。
因此这只能作为开发期诊断，不宜成为公开安装包的依赖。

## 3. 本机复验结果

为避免记录个人播放信息，所有探针只输出字段是否存在、字段长度与来源匹配，不保存曲名、
艺人或封面内容。

### 3.1 Perl 适配器

在 macOS 26.3 上从上述固定提交构建 universal `MediaRemoteAdapter.framework`，执行
`/usr/bin/perl ... get`：

- `bundleIdentifier == com.netease.163music`；
- 标题、艺人、专辑、时长、进度、时间戳和播放状态均存在；
- `artworkData` 存在，MIME 类型为 `image/jpeg`；
- 无辅助功能或屏幕录制权限请求。

随后启动 `stream --no-artwork --no-diff`，再发送 `kMRNextTrack`。流先收到同一曲目的状态
过渡，随后收到标题/艺人长度均变化的新曲目，证明它能在当前组合上事件驱动地跟随切歌。

### 3.2 JXA

`/usr/bin/osascript -l JavaScript` 中加载 MediaRemote 后：

- `MRNowPlayingRequest.localNowPlayingPlayerPath.client.bundleIdentifier` 匹配网易云；
- `localNowPlayingItem.nowPlayingInfo` 包含标题和艺人；
- 针对 `com.netease.163music` 的 `requestNowPlayingInfoWithCompletion:` 成功，无 error；
- `requestNowPlayingItemArtworkWithCompletion:` 返回非空 artwork，无 error。

这两次验证直接推翻了“只能依赖控制中心截图”的产品前提，但不推翻“自签主进程不能直接
读取”的安全边界判断。

## 4. 其他公开方案为何不作为主路线

| 方案 | 当前判断 | 依据与问题 |
| --- | --- | --- |
| 网易云本地日志/历史文件 | 不采用 | 2016 年项目通过 `music.163.log` 的 `player.$load` 行读取曲目：[mainwindow.cpp 第 1–80 行](https://github.com/supertanglang/NeteaseMusicNowPlaying/blob/49a2ff3309a99e804365daf91d6984c7b3918ea1/mainwindow.cpp#L1-L80)。当前 3.1.9 日志是二进制且本机最近更新时间早于当前播放；`playingList` 也不是实时状态。还会扩大对历史数据的读取范围。 |
| 网易云 `history` 文件 | 不采用 | 2019 OBS 脚本每秒读取容器内 history：[neteasemusic.lua 第 410–588 行](https://github.com/TinkoLiu/obs-netease-music-now-playing/blob/a42c008294e08438702168bf58de098acb0e19d7/neteasemusic.lua#L410-L588)。当前安装中已无该实时文件，且与“不读取收听历史”冲突。 |
| AppleScript/ScriptingBridge | 不可直接采用 | 网易云 3.1.9 没有脚本字典；System Events 最终仍是脆弱的 UI 自动化。 |
| Control Center AX + ScreenCaptureKit | 保留降级 | 公开、可工作，但需两个敏感权限，且窗口自动关闭、离屏封面捕获失败。 |
| CoreAudio/音频进程 | 仅能识别活跃进程 | CoreAudio 的公开硬件/进程属性没有跨应用曲名、艺人、封面字段；音频指纹识别会上传或维护大规模曲库，偏离项目目标。 |
| Unified Log | 不采用 | 日志不是应用间数据契约，格式和隐私裁剪均不稳定；当前网易云日志也未提供可验证的实时文本元数据。 |
| 注入网易云/CDP/读取 Cookie/社区 API | 明确排除 | 虽有开源项目通过这些方式实现，但违反既定隐私和维护边界。 |

## 5. 许可证与分发影响

- `ungive/mediaremote-adapter` 使用
  [BSD 3-Clause](https://github.com/ungive/mediaremote-adapter/blob/3ac3d4bdf862c7b5399b4fba4df5689f5c38609a/LICENSE)。
  可以源码或二进制再分发，但必须在源码以及安装包文档/第三方声明中保留版权、许可条件和
  免责声明，不能用作者名为项目背书。
- YohakuCompanion、MusicIsland、Vinilo 都使用 MIT；若复制其 JXA 或 Swift 实现的实质部分，
  必须保留对应版权与 MIT 声明。只参考接口思路、独立实现则仍建议在研究与致谢中链接来源。
- MediaRemote 是 Apple 私有框架。这不会阻止 GitHub 自签包运行，但存在未来系统更新失效、
  被安全软件标记为异常解释器/动态加载行为的风险，也不应声称为 Apple 支持的能力。
- Perl 桥不会读取网易云容器文件，也不需要 TCC 媒体权限；它读取的是网易云已发布给 macOS
  的系统 Now Playing 状态。应用仍应只在内存保存当前状态，默认不写日志、不上传元数据。

## 6. 推荐落地顺序

1. **先建一个限时 Spike，不直接把第三方包接入产品 UI。** 将 BSD 适配器固定到提交
   `3ac3d4b...`，构建 universal framework，放入 App Resources；用 Swift `Process` 启动
   `/usr/bin/perl`，解析行分隔 JSON，转成现有 `NowPlayingState`。
2. 加入运行时自检：确认 `/usr/bin/perl`、框架签名、首包超时和来源 bundle ID；失败时自动
   切换到 JXA 每秒轮询，不再自动展开控制中心。
3. 做 30–60 分钟兼容矩阵：连续切歌、暂停/恢复、拖动进度、网易云重启、休眠唤醒、VIP、
   私人 FM、播客、本地音乐、多显示器；记录匿名字段与延迟，不记录内容。
4. CI 构建 arm64/x86_64 并验证框架在最终 `.app` 和 `.dmg` 内的签名；在 Release 文档中加入
   私有 API、Apple Perl 子进程、非 App Store、未来 macOS 可能失效和 BSD 第三方许可说明。
5. 只有在 Perl 与 JXA 两条路线都被未来 macOS 阻断，或项目明确不接受“Apple 签名宿主调用
   私有 MediaRemote”这一边界时，才建议 Close。以 2026-08-05 的证据，现在 Close 会过早。

## 7. Go / Close 判定

**Go，但把风险等级定为“可发布、需版本兼容层”，而不是“官方稳定 API”。**

- 技术可行性：已在目标机器、目标网易云版本完成一次读取、封面读取和事件驱动切歌验证。
- 用户体验：主路线不展开控制中心，不需要辅助功能/屏幕录制权限，优于原 MVP 假设。
- 隐私：不碰 Cookie、历史、缓存或网易云进程；可维持现有“不落盘、不上传”承诺。
- 主要剩余风险：私有 API 与 Apple 平台宿主行为可能随 macOS 更新变化；应由 JXA fallback、
  兼容矩阵和明确安装说明管理，而不是据此立即关闭项目。
