# 第三方软件声明

CloudPlatter 随安装包分发以下第三方组件。除项目自身许可证外，这些组件分别适用其原始许可证。

## Wood Table 001 木纹纹理

- 作者：Dimitrios Savva（摄影）、Rico Cilliers（处理）
- 来源：Poly Haven，<https://polyhaven.com/a/wood_table_001>
- 原始文件：`wood_table_001_diff_4k.jpg`
- 原始下载地址：<https://dl.polyhaven.org/file/ph-assets/Textures/jpg/4k/wood_table_001/wood_table_001_diff_4k.jpg>
- 许可证：CC0 1.0 Universal，<https://polyhaven.com/license>

CloudPlatter 使用该 4K 漫反射贴图作为全屏桌面的木纹背景。仓库中的
`walnut-desktop-4k.jpg` 仅对原图进行了无损旋转，使木纹方向适合横向显示器；未添加第三方标识、
文字或其他内容。Poly Haven 明确说明其资产采用 CC0，可复制、修改并随开源项目或安装包分发，
无需署名；本节仍保留来源和修改记录，方便复核与后续维护。

## MediaRemote Adapter

- 项目：<https://github.com/ungive/mediaremote-adapter>
- 固定提交：`3ac3d4bdf862c7b5399b4fba4df5689f5c38609a`
- 许可证：BSD 3-Clause

CloudPlatter 通过 GitHub Releases 直接分发，不通过 Mac App Store。该组件由 Apple 系统
`/usr/bin/perl` 子进程加载并调用未公开的 MediaRemote；未来 macOS 更新可能使其失效。

```text
BSD 3-Clause License

Copyright (c) 2025, Jonas van den Berg and contributors

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
   list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice,
   this list of conditions and the following disclaimer in the documentation
   and/or other materials provided with the distribution.

3. Neither the name of the copyright holder nor the names of its
   contributors may be used to endorse or promote products derived from
   this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
```

## YohakuCompanion JXA Media Info Provider

- 项目：<https://github.com/Innei/YohakuCompanion>
- 固定提交：`470bc72ae78b2465c1ddfb8fcb48f1fff63040b1`
- 许可证：MIT

CloudPlatter 使用其 JXA MediaRemote 查询脚本作为按需备用通道，并把脚本与本许可证随安装包
分发。该通道由 Apple 系统 `/usr/bin/osascript` 执行，只定向查询网易云音乐；默认事件流正常
时不会启动轮询。脚本与许可证合计 11,392 字节（未压缩）；固定提交降低上游变更风险，升级前
需要重新检查许可证、输出协议、兼容性和能耗。

```text
MIT License

Copyright (c) 2025 Innei

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
