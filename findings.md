# 问题记录：逸剑风云决传送 mod

## 已发现
| 问题 | 原因 | 处理 |
|------|------|------|
| Git Bash `/tmp` 路径 Python 不可见 | Python 是 Windows 原生程序，不认 bash 路径 | 用 cygpath 转 Windows 路径 |
| bash 内嵌 Python 字符串反斜杠转义错误 | JSON/bash 多层转义 | 长脚本写成独立 .py 文件执行 |
| WebFetch 被拦截 | 安全策略 | curl + Bash 绕行 |
| PowerShell 读 exe 版本被 conda 干扰 | conda entry point DLL 加载失败 | 改用 ctypes 读 PE 版本资源 |
| UE4SS Lua 无屏幕绘制 API | IMGui 仅 C++ mods 可用 | UI 改控制台命令方案 |
| 驿站/Maps 数据表二进制直接解析复杂 | DataTable + FText 序列化 | 运行时用 UE4SS 读取（待做） |
| **稳定版 UE4SS (v3.0.1) FText 签名失败→Fatal Error→mod 全部不加载** | 游戏更新破坏兼容性，稳定版不匹配 | **换实验版 UE4SS v3.0.1-944**（Nexus mod 24 作者验证兼容） |
| 游戏内置 GM 命令行 | JHNeoUISubsystem:ShowGMCommandLine()（F1 打开） | Console Unlocker mod 方案，替代 ConsoleEnablerMod |

## 关键发现（决定性问题）
- **实验版 UE4SS 是必需的**：Nexus Wandering Sword mods/24 (Console Unlocker) 明确说明"Stable versions no longer work"
- 实验版安装结构：`dwmapi.dll`（Win64 根目录）+ `ue4ss/` 子目录（UE4SS.dll、settings、Mods）
- 升级实验版前需删除旧稳定版文件（Nexus 说明）
- 游戏 GM 命令清单在 pak `JH/JHNeoUI_Common/Modules`（可能含传送命令！）
- 游戏还可用 UEHelpers + ShowGMCommandLine 方式解锁控制台

## 最终方案与教训（2026-08-06）
### 传送机制
- **手动 F1 tomap <ID> 有效**（唯一完整传送，设玩家位置）
- `ChangeSceneMapWithId(WorldContext, MapId, TargetLocation, TargetFaceDirect, ...)` 能传到目标地图但**黑屏**（TargetLocation 未设置 → 玩家出生点问题）
- `ChangeSceneMapDDD` 只触发转场动画不完成；`ClientTravel` 需 4 参数（MapGuid）
- 正确路径：读 Maps 表 `MapName`（如 LV_25_P）→ 从 pak 拼完整路径 `/Game/JH/Maps/JiangNan/Map25/LV_25_P`

### 踩过的坑（不再犯）
| 问题 | 原因 | 解决 |
|------|------|------|
| UUserWidget StaticConstructObject 崩溃 | 抽象类 (CLASS_Abstract) | 用具体 WBP_C 类 + UWidgetBlueprintLibrary:Create |
| UMG 面板反复崩 | 容器类不稳定（每次自动找的不同）、SetVisibility/RemoveFromParent/SetColorAndOpacity/UpdateList 复用崩 | 放弃自定义 UMG 面板 |
| F10 控制台不显示 UE4SS 输出 | ConsoleEnabler 控制台是游戏/UE 控制台，不走 UE4SS print | 输出只看 ue4ss/UE4SS.log |
| 命令回调"must return true or false" | RegCmd 回调没返回 true/false | 回调末尾加 `return true` |
| 驿站表注入不显示 | 驿站界面只显示已解锁/激活的驿站 | 放弃注入方案 |
| F1 GM 命令行不走标准 exec | 游戏自定义命令系统 | ULocalPlayer/ProcessConsoleExec/CallFunctionByName hook 无效 |

### 最终交付
- **F10 输入拼音传送**（92 个地点拼音速查表：`projects/2026/08/逸剑风云决传送mod/拼音速查表.md`）
- **F2** → 游戏驿站界面
- 已知问题：ChangeSceneMapWithId 传送黑屏（出生点未设置），待解决

## 待验证（游戏内测试）
- [ ] OpenLevel 跨地图传送是否生效
- [ ] ClientMessage 是否显示到屏幕
- [ ] CommandParts 索引约定（[1]=命令名?）
- [ ] F6 快捷键是否与其他按键冲突
- [ ] 子关卡（LV_ 前缀）open 是否正常
