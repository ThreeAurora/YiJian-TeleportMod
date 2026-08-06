# -*- coding: utf-8 -*-
"""生成《MOD说明.txt》：精炼纯文本说明（无表格）+ 92 地点拼音列表
数据源：maps_cmd.lua（命令表）、maps_pinyin.lua（完整拼音）"""
import re

MOD = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\MOD说明.txt'

# ---- maps_pinyin -> name -> 完整拼音 ----
py = {}
for m in re.finditer(r'\{ id = \d+, name = "([^"]*)", pinyin = "([^"]*)",', open(MOD + r'\maps_pinyin.lua', encoding='utf-8').read()):
    py.setdefault(m.group(1), m.group(2))

# ---- maps_cmd -> name -> {keys, id} ----
name_keys, name_id = {}, {}
for line in open(MOD + r'\maps_cmd.lua', encoding='utf-8').read().splitlines():
    m = re.match(r'\["([^"]+)"\] = (.*),$', line.strip())
    if not m:
        continue
    key, val = m.group(1), m.group(2)
    for i, n in re.findall(r'\{ id = (\d+), name = "([^"]*)" \}', val):
        name_keys.setdefault(n, set()).add(key)
        name_id.setdefault(n, int(i))

# ---- 92 地点行 ----
sharer = {}
for n, keys in name_keys.items():
    for k in keys:
        sharer[k] = sharer.get(k, 0) + 1

rows = []
for name, keys in name_keys.items():
    full = py.get(name) or (sorted(keys, key=len)[-1] if keys else '')
    others = [k for k in keys if k != full]
    prefix = sorted(others, key=len)[0] if others else full
    rows.append({'name': name, 'prefix': prefix, 'full': full,
                 'id': name_id.get(name, 0), 'conflict': sharer.get(prefix, 0) > 1})
rows.sort(key=lambda r: r['id'])

# ---- 拼装 txt ----
L = []
L.append('逸剑风云决 · 全地图传送 MOD')
L.append('适用 UE4.26 · UE4SS 实验版 v3.0.1-944')
L.append('')
L.append('【按键】')
L.append('  F1  控制台（屏幕底部输入框）')
L.append('  F2  驿站界面（仅已解锁驿站）')
L.append('')
L.append('【怎么传送】')
L.append('  按 F1 输拼音回车，大小写不限。')
L.append('  · 全部 258 个地图都能传，含测试地图、禁地')
L.append('  · 92 个世界地图大地点输前两字即可：十万大山 → shiwan')
L.append('  · 任意地图输完整拼音：测试地图 → ceshiditu')
L.append('  · 记不清拼音？输 tpm 关键词：tpm 万')
L.append('')
L.append('【重名（3 组，须输完整拼音）】')
L.append('  pili     → pilidao 霹雳岛 / pilimen 霹雳门')
L.append('  tianshan → tianshan 天山 / tianshanpai 天山派')
L.append('  wuxian   → wuxianjiao 五仙教 / wuxianling 五仙岭')
L.append('')
L.append('【F1 控制台还能用别的】')
L.append('  这是游戏原生 UE 控制台，除拼音命令外也可执行游戏自带指令，')
L.append('  如 tomap 9（按地图 ID 传送）。')
L.append('')
L.append('【注意】')
L.append('  · 全拼可传禁地、跳过剧情，不推荐')
L.append('  · 传送黑屏（少见）再传一次即可')
L.append('  · 卸载：删掉 dwmapi.dll 和 ue4ss 即可')
L.append('')
L.append('【安装】')
L.append('  1. 把 dwmapi.dll、ue4ss 解压到 游戏目录\\Binaries\\Win64（覆盖）')
L.append('  2. 启动游戏')
L.append('')
L.append('【92 个世界地图大地点】')
L.append('（完整拼音即可传；重名前缀须用完整拼音）')
for r in rows:
    if r['full'] == r['prefix']:
        L.append('  %s  %s' % (r['name'], r['full']))
    else:
        pfx = r['prefix'] if not r['conflict'] else r['prefix'] + '(重名)'
        L.append('  %s  %s  (前缀 %s)' % (r['name'], r['full'], pfx))
L.append('')

with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(L))
print('已生成:', OUT, '| 地点:', len(rows))
