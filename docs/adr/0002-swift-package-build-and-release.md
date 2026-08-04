# ADR-0002：使用 Swift Package 建立可复现构建与开源发布

- 状态：已接受
- 日期：2026-08-04

## 背景

项目早期需要让本地开发和 GitHub Actions 使用同一组命令完成格式检查、构建、测试和应用打包。当前还没有复杂 Asset Catalog、签名 entitlement 或 Xcode 工程配置需求。

## 决策

- 使用 `Package.swift` 管理核心库、菜单栏应用和测试目标。
- 使用 `make check` 作为本地与 CI 的统一质量入口。
- 使用脚本把两种架构的 Release 可执行文件合并为 Universal `.app`。
- 开源 Release 使用 ad-hoc 签名，产出 ZIP 和 SHA-256；不包含证书或私钥。
- 当 Asset Catalog、正式签名、公证或 Xcode 特有能力使脚本维护成本明显上升时，再用新 ADR 评估迁移到 Xcode project 或 XcodeGen。

## 后果

- 克隆仓库后只需要 Swift 工具链即可运行核心构建和测试。
- CI/CD 与本地命令一致，发布流程可复现且不依赖维护者证书。
- 手工组装 app bundle 需要维护 Info.plist 和资源复制逻辑，后续复杂度上升时必须重新评估。

## 替代方案

- 提交 `.xcodeproj`：系统集成直接，但早期工程文件噪声和冲突更多。
- XcodeGen/Tuist：配置清晰，但给首个骨架增加额外工具依赖。
- 只发布命令行二进制：无法验证真实菜单栏应用的安装和启动链路。
