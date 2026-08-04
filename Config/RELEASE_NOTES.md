## 安装提示

这个版本使用 ad-hoc 签名。首次打开时，你可能需要在 macOS“隐私与安全性”设置中手动允许 CloudPlatter；不需要也不建议全局关闭 Gatekeeper。

下载后可以使用同目录的 `.sha256` 文件验证 ZIP 完整性：

```bash
shasum -a 256 -c CloudPlatter-*.zip.sha256
```

## 已验证环境

- macOS：CI 在 GitHub `macos-15` Runner 完成构建、测试和 Universal 打包。
- 网易云音乐：动态 MediaRemote 兼容性验证尚未完成，请关注 [#3](https://github.com/Chengyunlai/cloud-platter/issues/3)。

## 已知兼容性

CloudPlatter 依赖未公开的 macOS MediaRemote 接口。系统或网易云音乐升级后，当前播放信息可能暂时不可用；应用应进入安全降级状态，而不是要求你关闭系统安全功能。
