# 任务计划：逸剑风云决全地图传送 mod

## 目标
为《逸剑风云决》(Wandering Sword, UE4.26) 编写"全地图任意传送"功能性 mod。
基于 UE4SS 3.x + Lua，快捷键/控制台命令触发，跨地图传送。

## 需求（用户确认）
- 功能形态：传送菜单
- 传送范围：所有地图随便传（不限制剧情/任务解锁）

## 项目位置
`e:\CCSpace\projects\2026\08\逸剑风云决传送mod\`
游戏位置：`G:\Wandering Sword\Wandering_Sword\`

## Phase 1: 资源侦察 ✅
- [X] 解析 pak（repak）：版本 V11、索引未加密、28.9 万文件
- [X] 确认引擎：UE 4.26.2（exe 版本 4.26.2.0）
- [X] 确认游戏结构：主包 JH/，739 张地图，驿站表 CourierStation（北地/关外/南疆/海外/西域）
- [X] 地图数据表：JH/Tables/Maps.uasset（含 ViewName 显示名）
- [X] mod 生态：官方无创意工坊，功能性 mod 走 UE4SS，pak 数据 mod 放 Content/Paks

## Phase 2: 环境搭建 ✅
- [X] 下载 repak（pak 解析）、UE4SS v3.0.1、zDEV（API 参考）
- [X] 研究 UE4SS Lua API（无屏幕绘制 API，IMGui 仅 C++）
- [X] 确认传送路径：UGameplayStatics::OpenLevel 跨地图；ProcessConsoleExec 备选
- [X] 交互方案：游戏内控制台命令（tpm/tplist/tphelp）+ F6 快捷键

## Phase 3: mod 开发（进行中）
- [X] 生成 maps.lua（736 张地图数据，含 UE 包路径）
- [X] 编写 main.lua（搜索 + 传送 + 命令注册）
- [ ] 增强：地图中文显示名（运行时读 DataTable 或离线提取）
- [ ] 增强：驿站表快速传送列表
- [ ] 创建安装脚本 + 安装说明

## Phase 4: 安装与测试（待做）
- [ ] 安装 UE4SS + mod 到游戏 Binaries/Win64
- [ ] 配置 EngineVersionOverride = 4.26
- [ ] 游戏内测试：tpm/tplist 命令、跨地图传送
- [ ] 记录测试结果，修复问题

## 决策
| 决策 | 内容 |
|------|------|
| D1 | 用 UE4SS Lua（非 pak 数据修改），因"任意地图传送"需运行时逻辑 |
| D2 | 传送用 GameplayStatics::OpenLevel（引擎原生，不依赖游戏代码） |
| D3 | UI 用游戏内控制台命令（UE4SS 无 Lua 绘制 API），非 UMG |
| D4 | 地图数据从 pak 提取生成 maps.lua，不依赖游戏数据表 |
| D5 | 交互命令：tpm <关键词> / tplist / tphelp |
| D6 | 快捷键 F6 呼出帮助提示 |

## 已知风险
- 部分 LV_ 开头地图可能是子关卡，open 后可能无 PlayerStart
- ClientMessage 可能不显示（游戏禁用 HUD 消息），需测试
- 传送到未加载剧情区域可能触发异常，测试确认
