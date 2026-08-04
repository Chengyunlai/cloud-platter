# Issue 跟踪器：GitHub

本仓库的需求、缺陷、Spike 和实现任务统一记录在 [GitHub Issues](https://github.com/Chengyunlai/cloud-platter/issues)，所有自动化操作使用 `gh` CLI，并从仓库的 `origin` 推断目标仓库。

## 基本操作

- 创建：`gh issue create --title "..." --body "..."`
- 阅读：`gh issue view <number> --comments`
- 列表：`gh issue list --state open`
- 评论：`gh issue comment <number> --body "..."`
- 标签：`gh issue edit <number> --add-label "..."`
- 关闭：`gh issue close <number> --comment "..."`

创建计划内 Issue 时必须写明用户可验证的交付结果、验收标准和阻塞关系。实现细节只记录稳定的架构约束，不在 Issue 中固定容易过时的文件路径。

## Pull Request 政策

**外部 PR 暂不作为需求入口。**

- 首个稳定版本发布前，仅接受维护者邀请的 contributor 提交 PR。
- 未经邀请的外部贡献应先创建 Issue 讨论；维护者可以关闭未协商的 PR。
- 分诊流程只处理 Issues，不自动读取外部 PR。
- 首个稳定版本发布后再重新评估是否开放常规外部 PR。

GitHub 公共仓库无法禁止用户创建 PR，因此上述规则通过贡献说明和 PR 模板传达，而不是要求关闭系统安全或协作能力。

## 自动化技能约定

- 当技能要求“发布到 Issue 跟踪器”时，创建 GitHub Issue。
- 当技能要求“读取任务”时，使用 `gh issue view <number> --comments` 并同时读取标签。
- GitHub Issue 与 PR 共用编号空间；遇到不确定的 `#<number>` 时先确认其类型。
- 任务依赖优先使用 GitHub 原生 issue dependencies；不可用时在 Issue 正文保留 `Blocked by: #<number>`。
