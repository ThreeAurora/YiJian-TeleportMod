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

## 待验证（游戏内测试）
- [ ] OpenLevel 跨地图传送是否生效
- [ ] ClientMessage 是否显示到屏幕
- [ ] CommandParts 索引约定（[1]=命令名?）
- [ ] F6 快捷键是否与其他按键冲突
- [ ] 子关卡（LV_ 前缀）open 是否正常
