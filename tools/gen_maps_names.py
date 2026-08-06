# -*- coding: utf-8 -*-
"""从 maps_id_name.json 生成 mod 用的 maps_names.lua"""
import json
import os

JSON = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\maps_id_name.json'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\maps_names.lua'

with open(JSON, encoding='utf-8') as f:
    data = json.load(f)

# data: {id: 地名} 或 {id: null}
rows = []
for id_str, name in data.items():
    if name:
        rows.append((int(id_str), name))

rows.sort()
print('有效地图条目:', len(rows))

lines = []
lines.append('-- 逸剑风云决 地图 ID→地名（从 Maps 表解析，勿手改）')
lines.append('-- 格式: { id = 数字ID, name = 中文地名 }')
lines.append('local Maps = {')
for mid, name in rows:
    name_lua = name.replace('\\', '\\\\').replace('"', '\\"')
    lines.append('    { id = %d, name = "%s" },' % (mid, name_lua))
lines.append('}')
lines.append('')
lines.append('return Maps')
lines.append('')

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print('已生成:', OUT)
print('示例:')
for mid, name in rows[:10]:
    print('  %d -> %s' % (mid, name))
