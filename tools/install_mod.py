# -*- coding: utf-8 -*-
"""
逸剑风云决传送 mod 安装脚本
将 UE4SS + TeleportMod 安装到游戏 Binaries/Win64。

设计原则：
- 新增文件，不覆盖游戏已有文件（除非同名且属于本 mod）
- 修改 UE4SS-settings.ini / mods.txt 前先备份
- 幂等：重复运行安全
"""
import os
import shutil
import time

# ===== 路径 =====
PROJECT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod'
UE4SS_SRC = os.path.join(PROJECT, 'extracted', 'UE4SS')
MOD_SRC = os.path.join(PROJECT, 'mod', 'TeleportMod')

GAME_WIN64 = r'G:\Wandering Sword\Wandering_Sword\Binaries\Win64'

def info(msg):
    print('[安装] ' + msg)

def backup(path):
    """备份已有文件（防止覆盖用户配置）"""
    if os.path.exists(path):
        bak = path + '.bak_' + time.strftime('%Y%m%d_%H%M%S')
        shutil.copy2(path, bak)
        info('已备份 %s -> %s' % (os.path.basename(path), os.path.basename(bak)))

def ensure_dir(path):
    os.makedirs(path, exist_ok=True)

def main():
    if not os.path.isdir(GAME_WIN64):
        info('错误：未找到游戏目录 %s' % GAME_WIN64)
        return False
    if not os.path.isdir(UE4SS_SRC):
        info('错误：未找到 UE4SS 源目录 %s' % UE4SS_SRC)
        return False

    # 1. 复制 UE4SS 核心文件到 Win64
    info('复制 UE4SS 核心文件...')
    for fname in ['dwmapi.dll', 'UE4SS.dll', 'UE4SS-settings.ini', 'README.md', 'Changelog.md']:
        src = os.path.join(UE4SS_SRC, fname)
        if os.path.exists(src):
            dst = os.path.join(GAME_WIN64, fname)
            if os.path.exists(dst):
                info('跳过（已存在）: %s' % fname)
            else:
                shutil.copy2(src, dst)
                info('已复制: %s' % fname)

    # 2. 复制 UE4SS 自带 Mods（内置示例 mod）
    mods_dst = os.path.join(GAME_WIN64, 'Mods')
    ensure_dir(mods_dst)
    src_mods = os.path.join(UE4SS_SRC, 'Mods')
    if os.path.isdir(src_mods):
        info('复制 UE4SS 内置 mods...')
        for item in os.listdir(src_mods):
            s = os.path.join(src_mods, item)
            d = os.path.join(mods_dst, item)
            if os.path.exists(d):
                # 已存在：检查是否内置 mod（跳过），TeleportMod 单独处理
                if item == 'TeleportMod':
                    shutil.rmtree(d)
                    shutil.copytree(s, d)
                    info('更新 TeleportMod')
                else:
                    info('跳过（已存在）: Mods/%s' % item)
            else:
                if os.path.isdir(s):
                    shutil.copytree(s, d)
                else:
                    shutil.copy2(s, d)
                info('已复制: Mods/%s' % item)

    # 3. 复制 TeleportMod
    info('复制 TeleportMod...')
    tel_dst = os.path.join(mods_dst, 'TeleportMod')
    if os.path.exists(tel_dst):
        shutil.rmtree(tel_dst)
    shutil.copytree(MOD_SRC, tel_dst)
    info('已复制 TeleportMod')

    # 4. 配置 UE4SS-settings.ini（引擎版本覆盖 4.26）
    settings_path = os.path.join(GAME_WIN64, 'UE4SS-settings.ini')
    if os.path.exists(settings_path):
        backup(settings_path)
        with open(settings_path, 'r', encoding='utf-8-sig') as f:
            content = f.read()
        if '[EngineVersionOverride]' not in content:
            content += '\n[EngineVersionOverride]\nMajorVersion = 4\nMinorVersion = 26\n'
        else:
            # 替换空值
            import re
            content = re.sub(r'MajorVersion\s*=\s*\n?', 'MajorVersion = 4\n', content, count=1)
            content = re.sub(r'MinorVersion\s*=\s*\n?', 'MinorVersion = 26\n', content, count=1)
        with open(settings_path, 'w', encoding='utf-8') as f:
            f.write(content)
        info('已配置 UE4SS-settings.ini: EngineVersionOverride 4.26')

    # 5. 配置 mods.txt（启用 TeleportMod）
    mods_txt = os.path.join(mods_dst, 'mods.txt')
    if os.path.exists(mods_txt):
        backup(mods_txt)
        with open(mods_txt, 'r', encoding='utf-8-sig') as f:
            content = f.read()
        if 'TeleportMod' not in content:
            content = content.rstrip() + '\nTeleportMod : 1\n'
            with open(mods_txt, 'w', encoding='utf-8') as f:
                f.write(content)
            info('已在 mods.txt 启用 TeleportMod')
        else:
            # 确保为 1
            content = content.replace('TeleportMod : 0', 'TeleportMod : 1')
            with open(mods_txt, 'w', encoding='utf-8') as f:
                f.write(content)
            info('mods.txt 已包含 TeleportMod（确保启用）')

    info('安装完成！')
    info('下一步：启动游戏，游戏内按 `~` 打开控制台，输入 tphelp 查看帮助')
    return True

if __name__ == '__main__':
    main()
