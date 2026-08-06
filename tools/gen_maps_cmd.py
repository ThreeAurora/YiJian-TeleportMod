# -*- coding: utf-8 -*-
"""重建 maps_cmd.lua：92 地点 = 完整拼音全称 + 前两字前缀 双命令

规则：
- 全拼全称必有（如 梧桐村 -> wutongcun、十万大山 -> shiwandashan）
- 前两字前缀必有（如 梧桐村 -> wutong、十万大山 -> shiwan）
- 两个字的地名全拼==前缀，自动去重
- 前缀/全拼冲突（多个地点同键）存数组，由 main.lua 跳过注册、提示输完整拼音
"""
import re
from collections import OrderedDict

MOD = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts'

# ---- 1. 解析 maps_pinyin.lua -> name -> 完整拼音 ----
py_src = open(MOD + r'\maps_pinyin.lua', encoding='utf-8').read()
name_to_py = {}
for m in re.finditer(r'\{ id = (\d+), name = "([^"]*)", pinyin = "([^"]*)", abbr = "([^"]*)" \}', py_src):
    name_to_py.setdefault(m.group(2), m.group(3))
# Maps 表叫法不同但同一地点的补丁
for n, p in {'桃花坞': 'taohuawu', '幽云泽': 'youyunze'}.items():
    name_to_py.setdefault(n, p)

# ---- 2. 解析现有 maps_cmd.lua（前缀表）-> (前缀键, [地点]) ----
cmd_src = open(MOD + r'\maps_cmd.lua', encoding='utf-8').read()
entries = []  # (prefix_key, [(id, name), ...])
for line in cmd_src.splitlines():
    line = line.strip()
    m = re.match(r'\["([^"]+)"\] = (.*),$', line)
    if not m:
        continue
    key, val = m.group(1), m.group(2)
    locs = [(int(i), n) for i, n in re.findall(r'\{ id = (\d+), name = "([^"]*)" \}', val)]
    if locs:
        entries.append((key, locs))

print('解析到前缀条目:', len(entries), '地点总数:', sum(len(l) for _, l in entries))

# ---- 3. 每个地点生成 全拼 + 前缀 两个命令 ----
final = OrderedDict()  # cmd -> [(id, name)]
for key, locs in entries:
    final.setdefault(key, [])
    for loc in locs:
        if loc not in final[key]:
            final[key].append(loc)
    for mid, name in locs:
        py = name_to_py.get(name)
        if not py:
            print('  [!] 缺完整拼音:', name)
            continue
        final.setdefault(py, [])
        if (mid, name) not in final[py]:
            final[py].append((mid, name))

# ---- 4. 输出 ----
lines = []
lines.append('-- 逸剑风云决 传送命令表（完整拼音全称 + 前两字前缀，冲突命令名存数组）')
lines.append('local Cmds = {')
unique_locs = 0
for cmd in sorted(final):
    locs = final[cmd]
    if len(locs) == 1:
        mid, name = locs[0]
        name_lua = name.replace('\\', '\\\\').replace('"', '\\"')
        lines.append('    ["%s"] = { id = %d, name = "%s" },' % (cmd, mid, name_lua))
        unique_locs += 1
    else:
        parts = []
        for mid, name in locs:
            name_lua = name.replace('\\', '\\\\').replace('"', '\\"')
            parts.append('{ id = %d, name = "%s" }' % (mid, name_lua))
        lines.append('    ["%s"] = { %s },' % (cmd, ', '.join(parts)))
lines.append('}')
lines.append('return Cmds')

# 统计冲突
conflict_cmds = [c for c, l in final.items() if len(l) > 1]
print('命令总数:', len(final))
print('冲突键（需输完整拼音区分）:', len(conflict_cmds))
for c in conflict_cmds:
    print('   ', c, '->', '、'.join(n for _, n in final[c]))

OUT = MOD + r'\maps_cmd.lua'
with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines) + '\n')
print('已生成:', OUT)
