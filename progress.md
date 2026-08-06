# 进度：逸剑风云决传送 mod

## 2026-08-06
- 解析主 pak（Wandering_Sword-WindowsNoEditor.pak，5.6GB）：V11、未加密、289441 文件
- 确认引擎 UE 4.26.2，主内容包 JH/，739 张 .umap 地图
- 确认驿站表 CourierStation = 快速旅行系统（五大区域枚举）
- 下载 repak v0.2.3、UE4SS v3.0.1、zDEV（API.txt）
- 生成地图数据 maps.lua（736 张，pak 提取）
- 编写 main.lua v1（tpm/tplist/tphelp 命令 + F6 快捷键）
- 完成项目三文件、地图数据、mod 主体

## 待办
- [ ] 中文地图名增强
- [ ] 驿站快速传送列表
- [ ] 安装脚本
- [ ] 游戏内测试

## 2026-08-06 更新
- 完成 UI 面板：F2 呼出世界地图传送面板（UMG 注入，容器类 BPCMP_YuanWu_Element_C）
- 71 个大位置（用户确认：删天水内外城/武当药谷/无名山谷/一线天山谷，加一线天）
- 分页显示（每页 12 个，PgUp/PgDn 翻页）
- 修复：传送后地图切换崩溃（RemoveFromParent + RegisterLoadMapPreHook 清理）
- 传送用游戏 tomap <ID> 命令（ChangeSceneMapDDD）

## 最终状态（2026-08-06）
- 传送：F10 输入拼音 → ChangeSceneMapWithId 传送（92 个地点，速查表已生成）
- F2 → 游戏驿站界面
- 已知问题：传送黑屏（TargetLocation/出生点未设置）
- 方案历程：UMG 面板(放弃) → 驿站注入(失败) → 指令传送(最终采用)

## 收尾修复（2026-08-06，用户实测通过）
- 键位最终化：删除 ShowGMCommandLineMod（F1 GM 界面），F1 只留黑色 UE 控制台；ConsoleEnabler 去掉 Tilde 键
- 修复 main.lua:943 编译错误（`{ ... }` 写在 pcall 内层非 vararg 函数 → 全脚本加载失败，所有命令失效）
- maps_cmd.lua 重建：每地点 = 完整拼音 + 前两字前缀 双命令（165 键）
- 修复传送自动失效：切图后 AsyncTaskChangeSceneMap 场景实例被销毁 → StaticConstructObject 新建实例兜底（日志证实 22:55 新建实例传送成功）
- 大小写不敏感：RegisterULocalPlayerExecPreHook 实测不触发（黑色控制台不走 ULocalPlayer::Exec）→ 改 RegisterConsoleCommandGlobalHandler 小写+大写双注册
- 验证：wutong / wutongcun / WUTONG 均正常传送

## 代码清理（2026-08-06）
- 移除全部调试残留：13 个调试命令（tpadd2~tpfn）、ChangeSceneMapDDD hook、GM 界面 hook、HandlePinyin 死代码
- 移除废弃 UMG 面板全套代码 + 方向键/回车/ESC 全局键绑定（不再注册任何干扰按键）
- 移除驿站表注入（AddAllMapsToCourier，启动 10 秒后改游戏数据表 CourierStation）
- main.lua 974→193 行（35KB→7KB），保留：CallTomap / F2 驿站 / tpm / RegCmd / maps_cmd 拼音注册
- 语法 luaparser 校验通过，已部署游戏目录

## 交付文档（2026-08-06）
- 生成 `MOD说明.md`：6 节规范使用说明（按键/命令/重名/搜索/注意/安装）+ 附录 92 地点拼音对照表（前两字前缀/完整拼音/tomap ID，重名标注）
- 对照表由 gen_mod_readme.py 从 maps_cmd.lua + maps_pinyin.lua 自动生成，杜绝手打错误
- 旧 `拼音速查表.md` 已过时（写 F10），内容并入 MOD说明.md，已删入回收站
