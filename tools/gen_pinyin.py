# -*- coding: utf-8 -*-
"""为 258 个地图生成拼音数据，检查缩写冲突，生成 maps_pinyin.lua"""
import json
import os
from pypinyin import pinyin, Style
from collections import defaultdict

JSON = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\maps_id_name.json'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\maps_pinyin.lua'

with open(JSON, encoding='utf-8') as f:
    data = json.load(f)

# data: {id: 地名}
rows = []
for id_str, name in data.items():
    if name:
        rows.append((int(id_str), name))

# 生成拼音
def to_pinyin(name):
    """返回 (全拼无空格, 首字母)"""
    full = ''.join(pinyin(c, style=Style.NORMAL)[0][0] for c in name if c != ' ')
    first = ''.join(pinyin(c, style=Style.FIRST_LETTER)[0][0] for c in name if c != ' ')
    return full, first

# 首字母冲突检查
first_abbr = defaultdict(list)
for mid, name in rows:
    _, first = to_pinyin(name)
    first_abbr[first].append(name)

print('=== 首字母缩写冲突检查 ===')
conflicts = 0
for abbr, names in sorted(first_abbr.items()):
    if len(names) > 1:
        conflicts += len(names)
        print('  缩写 %s 冲突: %s' % (abbr, '、'.join(names)))

total = len(rows)
print('总地名数: %d, 冲突地名数: %d' % (total, conflicts))

# 生成 Lua 数据
lines = []
lines.append('-- 逸剑风云决 地图 ID→地名→拼音（自动生成，勿手改）')
lines.append('-- 格式: { id, name, pinyin, abbr }')
lines.append('local Maps = {')
for mid, name in rows:
    full, first = to_pinyin(name)
    name_lua = name.replace('\\', '\\\\').replace('"', '\\"')
    full_lua = full.replace('\\', '\\\\').replace('"', '\\"')
    lines.append('    { id = %d, name = "%s", pinyin = "%s", abbr = "%s" },' % (mid, name_lua, full_lua, first))
lines.append('}')
lines.append('')
lines.append('return Maps')
lines.append('')

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print('已生成:', OUT)
print('示例:')
for mid, name in rows[:8]:
    full, first = to_pinyin(name)
    print('  %d %s -> %s / %s' % (mid, name, full, first))
