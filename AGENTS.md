# CloudPlatter 仓库规则

本文件适用于整个仓库。开始修改前先阅读 `CONTRIBUTING.md`。

- `README.md` 必须保持为中文默认入口；英文内容维护在 `README.en.md`。
- 代码标识符使用英文，所有代码注释和文档注释使用中文。
- 注释说明原因、限制和不明显的约束，不重复显而易见的代码行为。
- 架构、隐私、测试、Git 和发布要求以 `CONTRIBUTING.md` 为唯一规范来源。

## Agent skills

### Issue tracker

使用 GitHub Issues 跟踪工作。首个稳定版本前，外部 PR 不作为需求入口，仅接受受邀 contributor 的协作提交。详见 `docs/agents/issue-tracker.md`。

### Triage labels

使用中文分诊标签：待评估、待补充信息、可由代理处理、需人工处理、不予处理。详见 `docs/agents/triage-labels.md`。

### Domain docs

使用单领域结构：根目录 `CONTEXT.md` 与 `docs/adr/`。详见 `docs/agents/domain.md`。
