# -*- coding: utf-8 -*-
"""生成最终 70 个大位置 bigmap_data.lua（用户确认）"""
import json
import os

JSON = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\maps_id_name.json'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\bigmap_data.lua'

with open(JSON, encoding='utf-8') as f:
    data = json.load(f)

items = sorted([(int(k), v) for k, v in data.items() if v])

end_kw = ['村', '城', '镇', '派', '门', '教', '宗', '岛', '湖', '关', '庄', '谷',
          '舫', '盟', '帮', '府', '寺', '观', '阁', '寨', '宫', '渊', '山']
exclude_kw = ['测试', '登录', '登陆', '世界地图', '示例', '后山', '山洞', '前',
              '夜市', '客房', '地窖', '密室', '宝库', '渡口', '崖底', '之巅']
# 用户明确删掉的
user_exclude = ['天水外城', '天水内城', '武当药谷', '无名山谷', '一线天山谷']

big = {}
for mid, name in items:
    if any(e in name for e in exclude_kw):
        continue
    if name in user_exclude:
        continue
    if not any(name.endswith(e) for e in end_kw):
        continue
    if name not in big:
        big[name] = mid

# 用户指出"地图上有一线天"（411，不以常见后缀结尾，手动加入）
if '一线天' not in big and '一线天' in {v for v in data.values() if v}:
    big['一线天'] = 411

lines = []
lines.append('-- 逸剑风云决 世界地图大位置（最终 %d 个，用户确认）' % len(big))
lines.append('local BigMaps = {')
for name, mid in sorted(big.items(), key=lambda x: x[1]):
    name_lua = name.replace('\\', '\\\\').replace('"', '\\"')
    lines.append('    { id = %d, name = "%s" },' % (mid, name_lua))
lines.append('}')
lines.append('return BigMaps')

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))

print('最终大位置数:', len(big))
for name, mid in sorted(big.items(), key=lambda x: x[1]):
    print('  %d %s' % (mid, name))
