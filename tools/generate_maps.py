# -*- coding: utf-8 -*-
"""从 pak 文件清单生成 maps.lua（传送 mod 用的地图数据）"""
import os
import re

# pak 文件清单（bash /tmp 下，Windows 临时目录）
pak_list = r'C:\Users\Administrator\AppData\Local\Temp\pak_list.txt'

# 输出
out_path = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\maps.lua'

with open(pak_list, encoding='utf-8') as f:
    lines = [l.strip() for l in f if l.strip()]

maps = [l for l in lines if '/JH/Maps/' in l and l.endswith('.umap')]

# 排除工具/测试地图
exclude_kw = ['UITool', 'TestMap', 'LittleGame', '_CG', 'Tool', 'Test']
filtered = []
for m in maps:
    base = m[:-5]  # 去 .umap
    fn = base.rsplit('/', 1)[-1]
    if any(k in fn for k in exclude_kw):
        continue
    # 包路径: Wandering_Sword/Content/... -> /Game/...
    pkg = '/Game' + base[len('Wandering_Sword/Content'):]
    filtered.append((fn, pkg))

print('Maps 目录地图总数:', len(maps))
print('过滤后地图数:', len(filtered))

# 生成 Lua 文件（UTF-8，含中文文件名）
lines_out = []
lines_out.append('-- 逸剑风云决 地图数据（由 pak 提取生成，勿手改）')
lines_out.append('-- 格式: { name = 显示名, path = UE包路径 }')
lines_out.append('local Maps = {')
for fn, pkg in filtered:
    fn_lua = fn.replace('\\', '\\\\').replace('"', '\\"')
    pkg_lua = pkg.replace('\\', '\\\\').replace('"', '\\"')
    lines_out.append('    { name = "%s", path = "%s" },' % (fn_lua, pkg_lua))
lines_out.append('}')
lines_out.append('')
lines_out.append('return Maps')
lines_out.append('')

os.makedirs(os.path.dirname(out_path), exist_ok=True)
with open(out_path, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines_out))
print('已生成:', out_path)
print('示例:')
for fn, pkg in filtered[:10]:
    print('  %s -> %s' % (fn, pkg))
