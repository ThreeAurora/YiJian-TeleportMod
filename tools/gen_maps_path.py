# -*- coding: utf-8 -*-
"""从 pak 文件路径构建 MapName → 完整地图路径映射，生成 maps_path.lua"""
import os

PAK_LIST = r'C:\Users\Administrator\AppData\Local\Temp\pak_list.txt'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\maps_path.lua'

with open(PAK_LIST, encoding='utf-8') as f:
    lines = [l.strip() for l in f if l.strip()]

# MapName(关卡文件名) -> 完整路径
paths = {}
for l in lines:
    if '.umap' in l and '/JH/Maps/' in l:
        base = l[:-5]  # 去 .umap
        fn = base.rsplit('/', 1)[-1]
        pkg = '/Game' + base[len('Wandering_Sword/Content'):]
        if fn not in paths:
            paths[fn] = pkg

print('地图路径映射数:', len(paths))
for k in ['LV_25_P', 'LV_26_P', 'LV_WuDang_P', 'LV_32_P']:
    print('  %s -> %s' % (k, paths.get(k)))

lines_out = []
lines_out.append('-- 逸剑风云决 MapName → 完整地图路径（从 pak 生成）')
lines_out.append('local MapPaths = {')
for fn, pkg in sorted(paths.items()):
    fn_lua = fn.replace('\\', '\\\\').replace('"', '\\"')
    pkg_lua = pkg.replace('\\', '\\\\').replace('"', '\\"')
    lines_out.append('    ["%s"] = "%s",' % (fn_lua, pkg_lua))
lines_out.append('}')
lines_out.append('return MapPaths')

os.makedirs(os.path.dirname(OUT), exist_ok=True)
with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(lines_out))
print('已生成:', OUT)
