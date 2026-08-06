# -*- coding: utf-8 -*-
"""按 AI 识图的完整地图地名列表，匹配 tomap ID，生成最终 bigmap_data.lua"""
import json
import os

JSON = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\maps_id_name.json'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\bigmap_data.lua'

with open(JSON, encoding='utf-8') as f:
    data = json.load(f)

# AI 识图的完整地图地名（按图分，去重）
map_names = [
    # 海域/岛屿
    '玉璧岛', '蟹岛', '霓光岛', '无名岛', '游仙村', '霹雳岛', '雾岛', '暮霞岛', '灵龟岛',
    # 中原/陆地
    '恶人谷', '平阳堡', '峋谷关', '葬龙谷', '天佛窟', '白龟洞', '少林寺', '檀林', '白帝湖',
    '仙人渡', '天水城', '樊城', '断天崖', '天剑宗', '阎浮镇', '北山村', '六扇门', '碧幽林',
    '梧桐村', '洛村', '碗子山', '青木舫', '武当派', '平康城', '神鹰门', '苍岚村', '程家村',
    '苦水村', '穷山据点', '鹰愁谷', '猴儿林', '清河村', '野猪林', '莲心湖', '城隍庙', '饿虎坡',
    '素节林', '竹海', '姑苏城', '名剑山庄', '五仙教', '蝴蝶村', '愁雾林', '蔓阴林', '桃源小径',
    '津鲤村', '千陵渡', '万劫窟', '威远镖局', '石屏村', '百药谷', '十万大山', '五仙岭', '洱郡',
    '景陇', '落英林', '青萝山', '丐帮', '谭城', '双河村', '桃花坞', '霹雳门', '凤凰洞',
    '幽云泽', '南渝村', '紫竹林', '天鸣村', '连鼓山', '雷家村', '雷山',
    # 西北/西域
    '蜃楼海域', '辽城', '龙门峡', '临昌', '驼铃丘', '天龙帮', '黎城', '不风山', '玄火教',
    '子河谷', '豫村', '天山', '天山派',
]

# 地名 -> 最小 ID
name_to_ids = {}
for id_str, name in data.items():
    if name:
        name_to_ids.setdefault(name, []).append(int(id_str))

# 手动映射（Maps 表叫法不同，但同一地点）
manual_map = {
    '桃花坞': 54,    # Maps 表叫「桃花林」
    '幽云泽': 904,   # Maps 表叫「幽云泽渡口」
}

results = []
missing = []
for name in map_names:
    ids = name_to_ids.get(name)
    if ids:
        results.append((min(ids), name))
    elif name in manual_map:
        results.append((manual_map[name], name))
    else:
        missing.append(name)

# 去重（脚本里已无重复，但保险）
seen = set()
unique = []
for mid, name in sorted(results):
    if name not in seen:
        seen.add(name)
        unique.append((mid, name))

print('=== 匹配成功: %d 个 ===' % len(unique))
for mid, name in unique:
    print('  %d  %s' % (mid, name))

print()
print('=== 未匹配（不在 Maps 表 258 里）: %d 个 ===' % len(missing))
for name in missing:
    print('  - ' + name)

# 生成 Lua
lines = []
lines.append('-- 逸剑风云决 世界地图大位置（按 AI 识图完整地图，%d 个）' % len(unique))
lines.append('local BigMaps = {')
for mid, name in unique:
    name_lua = name.replace('\\', '\\\\').replace('"', '\\"')
    lines.append('    { id = %d, name = "%s" },' % (mid, name_lua))
lines.append('}')
lines.append('return BigMaps')

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print()
print('已生成:', OUT)
