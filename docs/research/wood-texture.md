# 桌面木纹素材许可与分发调研

- 日期：2026-08-06
- 调研范围：仅核验素材发布方 Poly Haven 与许可证发布方 Creative Commons 的官方资料
- 目标：确认 `Wood Table 001` 能否作为 CloudPlatter 的全屏木纹背景，随 GitHub 源码与安装包再分发

## 结论

**可采用，首选 Poly Haven 的 `Wood Table 001` 4K Diffuse JPG。** Poly Haven 将该资产标记为
CC0 1.0，并在自己的许可页明确允许任意用途、商业使用、修改和再分发，也明确允许把资产包含
在自己分享或销售的产品中。因此，本项目可以把下载的 Diffuse 纹理经过旋转、裁切或调色后：

- 提交到 GitHub 开源仓库；
- 打包进可安装的 `.app`、DMG 或 ZIP；
- 继续以项目自身的开源许可证发布代码，同时单独注明该图片采用 CC0 1.0；
- 不强制署名，但建议在 `THIRD_PARTY_NOTICES.md` 保留来源、作者和修改说明，方便追溯。

本结论针对的是 **官方文件 API 列出的 CC0 资产文件本身**，不外推到 Poly Haven 的 Logo、
网站页面、页面文案等站点内容。项目应使用官方文件 API 返回的 Diffuse 下载地址，而不是抓取
网页预览图，这样可以清楚对应资产名、文件类型、散列与许可记录。

## 1. 资产身份与视觉适配

官方资产页：[`Wood Table 001`](https://polyhaven.com/a/wood_table_001)

Poly Haven 将它描述为干净、红棕染色、细密纹理、带平滑清漆光泽的木桌表面；官方元数据还
给出 `grain`、`vinyl` 等标签，最大分辨率为 16384 × 16384。资产作者信息为：

- Dimitrios Savva：摄影；
- Rico Cilliers：处理。

这些信息同时可由 Poly Haven 官方
[`info` API](https://api.polyhaven.com/info/wood_table_001) 核验。红棕色、细木纹和清漆光泽
与唱片机桌面场景匹配；方形、最高 16K 的源素材也给全屏裁切留出了余量。

## 2. 推荐下载项与完整性信息

首选文件是 **4K Diffuse JPG**：

- 官方下载地址：
  [`wood_table_001_diff_4k.jpg`](https://dl.polyhaven.org/file/ph-assets/Textures/jpg/4k/wood_table_001/wood_table_001_diff_4k.jpg)
- 文件大小：3,562,033 字节；
- 官方 MD5：`a091443bf883e836b9d604dba4eda765`；
- 官方清单来源：Poly Haven
  [`files` API](https://api.polyhaven.com/files/wood_table_001)。

推荐 4K JPG 而不是 16K 或无损 PNG：它已经足以覆盖常见 Retina 桌面渲染，约 3.56 MB 的
原始体积也适合跟随 Git 仓库和安装包分发。项目只需要颜色纹理时，Diffuse 文件就是正确的
资产；不必同时引入 normal、roughness、displacement 等 PBR 贴图。

下载后应校验官方 MD5，再记录项目实际纳入文件的 SHA-256。旋转、裁切、亮度或色调调整都会
改变散列值，修改后的散列应作为项目自己的制品完整性记录，不能再与官方原文件 MD5 混用。

## 3. CC0 与项目内再分发

Poly Haven 的官方[资产许可页](https://polyhaven.com/license)明确说明：

- 站内资产均采用 CC0；
- 可以用于任意目的，包括商业作品；
- 无需署名；
- 可以再分发、分享，并可以包含在自己分享或销售的产品中。

`Wood Table 001` 资产页内的结构化元数据也把许可直接指向
[`CC0 1.0 Universal`](https://creativecommons.org/publicdomain/zero/1.0/)，并标明
“public domain dedication, no attribution required”。

Creative Commons 的官方
[`CC0 1.0 法律文本`](https://creativecommons.org/publicdomain/zero/1.0/legalcode)进一步说明，
权利确认者在法律允许的最大范围内放弃相关版权与邻接权；若某地的放弃无效，则提供免版税、
不可撤销的后备许可，允许以任何媒介、任意份数、任意目的使用。因此，把纹理复制、修改、
纳入软件并随源代码及二进制安装包发布，都在其预期授权范围内。

### 与项目开源许可证的关系

CC0 图片可以与采用其他开源许可证的代码放在同一仓库和安装包中。为了不让读者误以为图片
的来源或许可与自研代码完全相同，建议：

1. 在 `THIRD_PARTY_NOTICES.md` 单列素材名、作者、资产页、下载文件、CC0 1.0 与所做修改；
2. 明确“CC0 不要求署名，此处信息用于来源追溯”；
3. 不使用 Poly Haven 名称或 Logo 暗示其为 CloudPlatter 背书。

## 4. 边界与风险

CC0 并非质量保证。Creative Commons 法律文本说明作品按现状提供，不保证权属、适销性、
特定用途适用性、不侵权或无缺陷；CC0 也不放弃商标或专利权。对这张不含人物、品牌或可识别
产品的木材表面纹理而言，第三方人格权和商标风险很低，但项目仍应保留来源和校验记录。

Poly Haven 的许可页措辞是“assets”，本调研没有据此推断整个网站及品牌元素都适用 CC0。
实现时只取官方 `files` API 为 `wood_table_001` 列出的 Diffuse 文件，并保留资产页和文件清单
链接；不要复制 Poly Haven 的 Logo、网页文案或其他未在该文件清单中确认的站点内容。

## 5. 采用建议

采用 `Wood Table 001` 4K Diffuse JPG，不再额外引入其他来源的木纹。它已经同时满足真实木纹、
高分辨率、合理包体和明确可再分发许可四项要求。进入应用后可做无损旋转，使木纹方向适合横屏，
再以暗色叠层和边缘压暗保证白色曲目信息可读；这些修改均为 CC0 允许的再利用方式。

最终第三方声明至少应记录：

> Wood Table 001 — Dimitrios Savva（摄影）、Rico Cilliers（处理），Poly Haven，CC0 1.0。
> 使用官方 4K Diffuse JPG；项目版本进行了旋转及显示层调色。CC0 不要求署名，本声明用于来源追溯。

## 官方来源

- Poly Haven 资产页：<https://polyhaven.com/a/wood_table_001>
- Poly Haven 资产元数据 API：<https://api.polyhaven.com/info/wood_table_001>
- Poly Haven 文件清单 API：<https://api.polyhaven.com/files/wood_table_001>
- Poly Haven 资产许可：<https://polyhaven.com/license>
- Creative Commons CC0 1.0 摘要：<https://creativecommons.org/publicdomain/zero/1.0/>
- Creative Commons CC0 1.0 法律文本：<https://creativecommons.org/publicdomain/zero/1.0/legalcode>
