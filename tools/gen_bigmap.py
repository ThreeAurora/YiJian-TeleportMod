# -*- coding: utf-8 -*-
"""从 WorldMap 资产匹配大位置到 maps_id_name 的 ID，生成大地图传送面板数据"""
import json
from pypinyin import pinyin, Style

JSON = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\maps_id_name.json'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\bigmap_data.lua'

with open(JSON, encoding='utf-8') as f:
    data = json.load(f)

def py(s):
    return ''.join(pinyin(c, style=Style.NORMAL)[0][0] for c in s if c != ' ')

# WorldMap 资产对应的大位置（拼音名 -> 中文名候选）
bigmap_pinyin = {
    'yucun': '豫村',
    'wudang': '武当',
    'linchang': '临昌',
    'xunguguan': '寻古关',
    'yanfuzhen': '阎浮镇',
    'pingkangcheng': '平康城',
    'tianshuicheng': '天水城',
    'jinglong': '景陇',
    'tancheng': '谭城',
    'gusucheng': '姑苏城',
    'erjun': '洱郡',
    'bibomen': '比波门',
    'tongyouzhao': '通幽沼',
    'tianfoku': '天佛窟',
    'xianrendu': '仙人渡',
    'huanlin': '幻林',
    'shenloudao': '神龙岛',
    'youxiuancun': '游仙村',
    'wumingdao': '无名岛',
    'taoyuanxiaojing': '桃源小径',
    'shanlouhaiyu': '蜃楼海域',
}

# 建立 地名拼音 -> [(id, name)]
name_to_ids = {}
for id_str, name in data.items():
    if name:
        p = py(name)
        name_to_ids.setdefault(p, []).append((int(id_str), name))

results = []
matched = set()
for bp, cn in bigmap_pinyin.items():
    p = py(cn)
    if p in name_to_ids:
        # 取第一个 ID（同一地名多入口）
        mid, name = name_to_ids[p][0]
        results.append((mid, name, bp))
        matched.add(bp)
    else:
        print('未匹配: %s (%s)' % (bp, cn))

print('匹配到 %d / %d 个大位置' % (len(matched), len(bigmap_pinyin)))

# 额外：看看还能加哪些常见大位置（城镇/门派）
extra_candidates = ['樊城', '武当派', '少林寺', '天剑宗', '恶人谷', '丐帮']
for cn in extra_candidates:
    p = py(cn)
    if p in name_to_ids:
        mid, name = name_to_ids[p][0]
        if not any(r[1] == name for r in results):
            results.append((mid, name, ''))
            print('额外: %s -> %d' % (name, mid))

# 排序
results.sort(key=lambda x: x[0])
print('最终大位置:')
for mid, name, bp in results:
    print('  %d: %s' % (mid, name))

# 生成 Lua
lines = []
lines.append('-- 逸剑风云决 世界地图大位置（自动生成）')
lines.append('-- 格式: { id, name }')
lines.append('local BigMaps = {')
for mid, name, bp in results:
    name_lua = name.replace('\\', '\\\\').replace('"', '\\"')
    lines.append('    { id = %d, name = "%s" },' % (mid, name_lua))
lines.append('}')
lines.append('return BigMaps')

with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines))
print('已生成:', OUT)
