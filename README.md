# 逸剑风云决 · 全地图传送 MOD (TeleportMod)

[English](./README.en-US.md) | 中文

基于 [UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) 的《逸剑风云决》(Wandering Sword) 全地图传送模组。以 Lua 脚本挂载，不改游戏本体文件：控制台输拼音即可传送全部 258 张地图，驿站界面点击直达 92 个世界地图大地点。

## 功能特性

- **F1 控制台拼音传送**：全部 258 张地图可传（含测试地图与禁地），大小写不敏感
- **前缀速传**：92 个世界地图大地点输前两字即可，如 十万大山 → `shiwan`
- **tpm 关键词搜索**：记不清拼音时按中文关键词查地名，如 `tpm 万`
- **F2 驿站界面**：复用游戏原生驿站 UI，选中即传送
- **tomap \<ID\>**：按地图 ID 直接传送
- **F8 / tpfav**（调试向）：呼出游戏 GM 命令界面、探测好感度数据结构

## 环境要求

- 《逸剑风云决》(Wandering Sword) PC 版（Unreal Engine 4.26）
- UE4SS 实验版 v3.0.1-944（zDEV/EXPERIMENTAL 构建）

## 安装

1. 将 `dwmapi.dll` 与 `ue4ss` 文件夹放入 `游戏目录\Binaries\Win64`（已存在则覆盖）
2. 启动游戏即可，无需额外配置
3. 卸载：删除 `dwmapi.dll` 与 `ue4ss` 文件夹

## 使用

| 按键 / 命令 | 说明 |
| --- | --- |
| F1 | 打开控制台（屏幕底部输入框） |
| `拼音` + 回车 | 传送到对应地图，如 `wutongcun` → 梧桐村 |
| `拼音前缀` + 回车 | 92 个大地点可只输前两字，如 `shiwan` → 十万大山 |
| `tpm 关键词` + 回车 | 按中文关键词搜索地名 |
| `tomap ID` + 回车 | 按地图 ID 传送 |
| F2 | 打开驿站界面，点击直达 |
| F8 | 呼出游戏 GM 命令界面 |

注意：

- 3 组重名地名需输完整拼音（`pili` 霹雳岛/霹雳门、`tianshan` 天山/天山派、`wuxian` 五仙教/五仙岭）
- 全拼可传禁地、跳过剧情，可能影响正常流程，请酌情使用
- 偶发传送黑屏时再传一次即可恢复

## 目录结构

```
mod/TeleportMod/Scripts/   MOD 源码（Lua）
tools/                     数据生成、部署与打包脚本
extracted/                 游戏数据解析产物与 UE4SS 运行时（运行时不入库）
发布/                       本地打包产物（不入库）
```

## 开发工具（tools/）

| 脚本 | 用途 |
| --- | --- |
| `parse_maps.py` / `parse_maps2.py` | 解析游戏地图表 |
| `parse_courier.py` | 解析驿站传送点数据 |
| `gen_maps_names.py` | 生成地图 ID ↔ 中文名映射 |
| `gen_pinyin.py` / `gen_maps_cmd.py` | 生成地名拼音与传送命令数据 |
| `gen_bigmap.py` / `gen_final_bigmap.py` / `gen_map_maps.py` | 生成世界地图大位置数据 |
| `gen_maps_path.py` | 生成地图路径数据 |
| `gen_mod_readme.py` / `gen_mod_readme_txt.py` | 生成用户说明文档 |
| `install_mod.py` / `replace_ue4ss.py` | 部署 mod 与 UE4SS 到游戏目录 |
| `check_lua.py` | Lua 语法校验 |
| `package_release.py` | 一键打包发布 |

## 仓库说明

以下内容体积较大或可重新生成，未纳入版本库（见 `.gitignore`）：

- `extracted/UE4SS*/`：第三方 UE4SS 运行时，请从 [UE4SS Releases](https://github.com/UE4SS-RE/RE-UE4SS/releases) 下载
- `tools/*.zip`：UE4SS 原始压缩包
- `tools/*.bin`：游戏数据解码中间产物
- `发布/`：发布打包产物，可由 `python tools/package_release.py` 重建

## 致谢

- [UE4SS-RE/RE-UE4SS](https://github.com/UE4SS-RE/RE-UE4SS) —— Unreal Engine Lua 脚本注入框架
- 《逸剑风云决》开发团队
