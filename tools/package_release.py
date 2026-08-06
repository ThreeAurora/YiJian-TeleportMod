# -*- coding: utf-8 -*-
"""打包发布 zip：玩家解压到 Binaries/Win64 覆盖即完成安装。
只带核心：dwmapi.dll + UE4SS.dll + 配置 + TeleportMod/ConsoleEnablerMod/Keybinds/shared，
排除 crash dump、日志、无关 mod，并生成精简 mods.txt。"""
import os
import zipfile

SRC = r'G:\Wandering Sword\Wandering_Sword\Binaries\Win64'
OUT_DIR = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\发布'
OUT = os.path.join(OUT_DIR, '逸剑风云决传送MOD_v1.0.zip')

# 只保留这些 mod（ConsoleEnablerMod= F1 控制台；Keybinds/shared = UE4SS 内建必需）
KEEP_MODS = {'TeleportMod', 'ConsoleEnablerMod', 'Keybinds', 'shared'}

MODS_TXT = 'ConsoleEnablerMod : 1\nTeleportMod : 1\n\n; Built-in keybinds, do not move up!\nKeybinds : 1\n'

INSTALL_TXT = u'''【逸剑风云决 · 全地图传送 MOD】安装方法

只需 2 步：

1. 找到游戏文件夹里的这个位置：
   Binaries\\Win64
   （Steam 上：右键游戏 → 管理 → 浏览本地文件，然后进入 Wandering_Sword\\Binaries\\Win64）

2. 把压缩包里的【dwmapi.dll】和【ue4ss】文件夹，
   解压到这个 Binaries\\Win64 里面（提示覆盖就点“是”）。

完成！启动游戏即可。

【怎么用】
- 按 F1：打开控制台，输入拼音按回车，立刻传送
  例：wutongcun = 梧桐村，shiwan = 十万大山
- 按 F2：打开驿站界面（快速旅行）
- 92 个地点的拼音对照表：见《MOD说明.txt》

【小提示】
- 想传“十万大山”这种，输前两字 shiwan 就行；重名的要输全拼
- 大小写都行：WUTONG 和 wutong 一样
- 所有地图输全拼都能传，包括禁地（会跳过剧情，不推荐）
- 本 MOD 不联网、不改存档。想卸载：删掉 dwmapi.dll 和 ue4ss 文件夹即可
'''

os.makedirs(OUT_DIR, exist_ok=True)

def walk_exclude():
    """生成 (源路径, 压缩内路径)，排除垃圾和无关 mod"""
    for root, dirs, files in os.walk(os.path.join(SRC, 'ue4ss')):
        rel = os.path.relpath(root, SRC).replace('\\', '/')
        parts = rel.split('/')
        # 排除 Mods 下不需要的 mod 目录
        if 'Mods' in parts:
            mi = parts.index('Mods')
            if len(parts) > mi + 1 and parts[mi + 1] not in KEEP_MODS:
                dirs[:] = []
                continue
        for f in files:
            if f.endswith('.dmp') or f.startswith('crash_') or f == 'UE4SS.log':
                continue
            if f in ('mods.txt', 'mods.json'):  # mods.txt 用精简版覆盖，mods.json 不需要
                continue
            p = os.path.join(root, f)
            yield p, os.path.relpath(p, SRC)

count = 0
size = 0
with zipfile.ZipFile(OUT, 'w', zipfile.ZIP_DEFLATED) as zf:
    # dwmapi.dll（Win64 根目录）
    zf.write(os.path.join(SRC, 'dwmapi.dll'), 'dwmapi.dll')
    count += 1
    # ue4ss 核心 + 保留的 mod
    for p, arc in walk_exclude():
        zf.write(p, arc)
        count += 1
        size += os.path.getsize(p)
    # 精简 mods.txt + 安装说明 + 拼音对照表
    zf.writestr('ue4ss/Mods/mods.txt', MODS_TXT)
    zf.writestr('安装说明.txt', INSTALL_TXT)
    zf.write(os.path.join(OUT_DIR, '..', 'MOD说明.txt'), 'MOD说明.txt')
    count += 3

zsize = os.path.getsize(OUT)
print('打包完成:', OUT)
print('文件数:', count, '| 源大小: %.1f MB | 压缩后: %.1f MB' % (size / 1048576, zsize / 1048576))
