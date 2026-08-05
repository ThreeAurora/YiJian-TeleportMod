# -*- coding: utf-8 -*-
"""
将稳定版 UE4SS 替换为实验版（v3.0.1-944，mod 作者验证兼容逸剑风云决）
结构：dwmapi.dll + ue4ss/ 子目录

步骤：
1. 检查游戏是否已退出（DLL 占用时无法替换）
2. 删除旧稳定版文件（走回收站）
3. 复制实验版
4. 配置引擎版本 4.26 + 启用 TeleportMod
"""
import os
import shutil
import sys
import time
from send2trash import send2trash

GAME_WIN64 = r'G:\Wandering Sword\Wandering_Sword\Binaries\Win64'
EXP_SRC = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\UE4SS_EXP944'
MOD_SRC = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod'

# 旧稳定版文件（删除走回收站）
OLD_FILES = ['dwmapi.dll', 'UE4SS.dll', 'UE4SS-settings.ini',
             'README.md', 'Changelog.md', 'Mods',
             'UE4SS-settings.ini.bak_20260806_015733']

def info(msg):
    print('[替换] ' + msg)

def is_game_running():
    import subprocess
    r = subprocess.run(['powershell', '-Command',
                        'Get-Process -Name "JH-Win64-Shipping" -ErrorAction SilentlyContinue'],
                       capture_output=True, text=True)
    return 'JH-Win64-Shipping' in r.stdout

def main():
    if is_game_running():
        info('错误：游戏正在运行！请先退出游戏（Steam 或任务管理器），再运行本脚本')
        return False

    if not os.path.isdir(GAME_WIN64):
        info('错误：游戏目录不存在 %s' % GAME_WIN64)
        return False
    if not os.path.isdir(EXP_SRC):
        info('错误：实验版源目录不存在 %s' % EXP_SRC)
        return False

    # 1. 删除旧稳定版文件（回收站）
    for f in OLD_FILES:
        p = os.path.join(GAME_WIN64, f)
        if os.path.exists(p):
            try:
                send2trash(p)
                info('已删除(回收站): %s' % f)
            except Exception as e:
                info('删除失败 %s: %s' % (f, e))
                return False

    # 2. 复制实验版
    info('复制 dwmapi.dll ...')
    shutil.copy2(os.path.join(EXP_SRC, 'dwmapi.dll'), os.path.join(GAME_WIN64, 'dwmapi.dll'))

    ue4ss_dst = os.path.join(GAME_WIN64, 'ue4ss')
    if os.path.exists(ue4ss_dst):
        send2trash(ue4ss_dst)
        info('已删除旧 ue4ss(回收站)')
    shutil.copytree(os.path.join(EXP_SRC, 'ue4ss'), ue4ss_dst)
    info('已复制 ue4ss/ 目录')

    # 3. 配置 UE4SS-settings.ini（引擎版本 4.26）
    settings = os.path.join(ue4ss_dst, 'UE4SS-settings.ini')
    if os.path.exists(settings):
        with open(settings, 'r', encoding='utf-8-sig') as f:
            content = f.read()
        if '[EngineVersionOverride]' in content:
            import re
            content = re.sub(r'MajorVersion\s*=\s*\d*', 'MajorVersion = 4', content, count=1)
            content = re.sub(r'MinorVersion\s*=\s*\d*', 'MinorVersion = 26', content, count=1)
        else:
            content += '\n[EngineVersionOverride]\nMajorVersion = 4\nMinorVersion = 26\n'
        with open(settings, 'w', encoding='utf-8') as f:
            f.write(content)
        info('已配置引擎版本 4.26')

    # 4. 配置 mods.txt（启用 TeleportMod + ConsoleEnabler）
    mods_txt = os.path.join(ue4ss_dst, 'Mods', 'mods.txt')
    if os.path.exists(mods_txt):
        with open(mods_txt, 'r', encoding='utf-8-sig') as f:
            content = f.read()
        if 'TeleportMod' not in content:
            content = content.rstrip() + '\nTeleportMod : 1\n'
        with open(mods_txt, 'w', encoding='utf-8') as f:
            f.write(content)
        info('已在 mods.txt 启用 TeleportMod')
    else:
        info('警告：mods.txt 不存在')

    # 5. 复制 TeleportMod
    tel_dst = os.path.join(ue4ss_dst, 'Mods', 'TeleportMod')
    if os.path.exists(tel_dst):
        shutil.rmtree(tel_dst)
    shutil.copytree(MOD_SRC, tel_dst)
    info('已复制 TeleportMod')

    info('替换完成！现在可以启动游戏测试')
    return True

if __name__ == '__main__':
    sys.exit(0 if main() else 1)
