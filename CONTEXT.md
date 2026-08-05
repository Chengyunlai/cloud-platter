# CloudPlatter 领域上下文

## 产品定义

CloudPlatter 是网易云音乐 macOS 客户端的只读桌面可视化伴侣。它观察本机已经存在的播放状态，把当前歌曲呈现为桌面黑胶场景，但不接管音频播放。

## 核心术语

| 术语 | 定义 |
| --- | --- |
| 播放来源（Playback Source） | 发布当前媒体状态的应用。MVP 只识别 bundle id 为 `com.netease.163music` 的网易云音乐。 |
| 正在播放状态（Now Playing State） | CloudPlatter 内部使用的规范化状态，包含来源、标题、艺人、专辑、封面、时长、进度和播放状态。 |
| 播放状态源（Playback Observation Source） | 从隔离的 MediaRemote helper 读取媒体状态，并转换为规范化状态的可替换边界。 |
| MediaRemote Adapter | 由系统 `/usr/bin/perl` 子进程动态加载的隔离 helper，向主应用输出 JSON 快照和实时变化。 |
| 备用快照源（Fallback Snapshot Source） | 长驻事件流空闲、不可用或静默超时时，按顺序执行一次性 MediaRemote 快照与网易云定向 JXA 查询的自愈通道。 |
| 系统媒体卡片（System Media Card） | macOS 控制中心展示当前歌曲、艺人、封面和播放按钮的系统界面。 |
| 空闲状态（Idle State） | 没有受支持的播放来源、没有当前媒体，或适配器不可用时的安全降级状态。 |
| 桌面场景（Desktop Scene） | 每块显示器上的全屏动态唱机层；位于系统壁纸之上、桌面图标和普通窗口之下，显示封套、唱片、唱臂、元数据和播放动画。 |
| 设置窗口（Settings Window） | 管理显示模式、登录时启动、减少动态效果和诊断开关的普通应用窗口。 |

## 核心状态

- `idle`：没有可展示的受支持媒体，显示默认唱片或隐藏桌面场景。
- `playing`：展示当前元数据并驱动唱片旋转。
- `paused`：保留当前元数据，平滑停止唱片动画。
- `unavailable`：系统能力缺失或字段格式不兼容，安全降级并提供脱敏诊断。

## 产品边界

- MVP 只读取网易云音乐已经发布给 macOS Now Playing 的本机信息。
- MVP 不提供播放控制、歌词、账号、歌单、收藏或推荐能力。
- 不注入其他进程，不抓取 Cookie，不模拟登录，不调用社区逆向 API。
- 默认数据源由系统 `/usr/bin/perl` 子进程加载应用附带的 MediaRemote helper；主应用不声明
  Apple 私有 entitlement，也不向网易云音乐进程注入代码。
- 默认事件流返回空闲、不可用或连续 4 秒没有事件时，先由隔离 helper 执行一次性 `get`
  快照；没有得到可展示状态时，再由系统 `/usr/bin/osascript -l JavaScript` 执行只针对
  `com.netease.163music` 的低频 JXA 查询。事件流恢复后立即停止备用轮询。
- MVP 只使用 helper 的只读能力；上游提供的播放控制不属于产品边界。
- 应用必须在 `/usr/bin/perl` 缺失、capability test 失败、字段结构变化、helper 退出或来源切换时
  安全降级，不能要求用户关闭系统安全机制。
- Accessibility 与 ScreenCaptureKit 只保留为开发诊断或未来由用户主动开启的备用能力。
- UI 和渲染层只消费规范化的 Now Playing State，不理解私有字段。
- 桌面场景不修改系统壁纸文件，默认点击穿透且不能抢占键盘焦点。

## 隐私不变量

- 默认不上传或持久化用户的收听历史。
- 默认日志不包含完整曲名、艺人、封面 URL、账号标识或本地路径。
- 封面只在内存中解码和渲染，不保存到磁盘。
- 新增网络请求、遥测或敏感权限前必须更新隐私说明并经过明确评审。
