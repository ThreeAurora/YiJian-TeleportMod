# -*- coding: utf-8 -*-
"""生成《MOD说明.md》：规范使用说明 + 92 地点拼音对照表（前缀/全拼/tomap ID）
数据源：maps_cmd.lua（命令表）、maps_pinyin.lua（完整拼音）"""
import re

MOD = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\MOD说明.md'

# ---- 1. maps_pinyin.lua -> name -> 完整拼音（首个） ----
py = {}
for m in re.finditer(r'\{ id = \d+, name = "([^"]*)", pinyin = "([^"]*)",', open(MOD + r'\maps_pinyin.lua', encoding='utf-8').read()):
    py.setdefault(m.group(1), m.group(2))

# ---- 2. maps_cmd.lua -> name -> {keys集合, id} ----
name_keys = {}
name_id = {}
for line in open(MOD + r'\maps_cmd.lua', encoding='utf-8').read().splitlines():
    line = line.strip()
    m = re.match(r'\["([^"]+)"\] = (.*),$', line)
    if not m:
        continue
    key, val = m.group(1), m.group(2)
    for i, n in re.findall(r'\{ id = (\d+), name = "([^"]*)" \}', val):
        name_keys.setdefault(n, set()).add(key)
        name_id.setdefault(n, int(i))

# ---- 3. 生成对照表行 ----
rows = []
key_sharer = {}  # key -> 共享该 key 的地点数（冲突检测）
allkeys = set()
for n, keys in name_keys.items():
    for k in keys:
        key_sharer[k] = key_sharer.get(k, 0) + 1

for name, keys in name_keys.items():
    full = py.get(name) or (sorted(keys, key=len)[-1] if keys else '')
    # 前缀：不等于全拼的最短键；无则前缀=全拼
    others = [k for k in keys if k != full]
    if others:
        prefix = sorted(others, key=len)[0]
    else:
        prefix = full
    conflict = key_sharer.get(prefix, 0) > 1  # 前缀被多个地点共享
    rows.append({
        'name': name, 'prefix': prefix, 'full': full,
        'id': name_id.get(name, 0), 'conflict': conflict,
    })

rows.sort(key=lambda r: r['id'])

# ---- 4. 拼装文档 ----
def tb(lines):
    return '| ' + ' | '.join(lines) + ' |'

head = []
head.append('# 逸剑风云决 · 全地图传送 MOD 使用说明')
head.append('')
head.append('> 基于 UE4SS 实验版 v3.0.1-944 · 适用《逸剑风云决》(UE4.26)')
head.append('')
head.append('## 一、按键')
head.append('')
head.append(tb(['按键', '功能']))
head.append(tb(['---', '---']))
head.append(tb(['**F1**', '呼出/关闭控制台（屏幕底部黑色输入框）']))
head.append(tb(['**F2**', '随时随地呼出驿站界面（快速旅行，仅显示已解锁驿站）']))
head.append('')
head.append('## 二、传送命令（F1 控制台输入后回车）')
head.append('')
head.append('大小写不敏感：`SHIWAN`、`Shiwan`、`shiwan` 均有效。')
head.append('')
head.append(tb(['类型', '示例', '说明']))
head.append(tb(['---', '---', '---']))
head.append(tb(['世界地图·前两字', '`shiwan` → 十万大山', '大部分地点这样输即可']))
head.append(tb(['世界地图·完整拼音', '`shiwandashan`', '当前缀重名时必用（见第三节）']))
head.append(tb(['任意地图·完整拼音', '`ceshiditu`（测试地图）', '全部地图全拼均可传，含禁地，不推荐']))
head.append(tb(['地图中文名', '`十万大山`', '控制台支持中文输入时可直输']))
head.append(tb(['唯一缩写', '`pkc`（平康城）', '仅唯一缩写可用，见附录']))
head.append('')
head.append('## 三、前缀重名（必须输完整拼音区分）')
head.append('')
head.append(tb(['前缀', '地点']))
head.append(tb(['---', '---']))
head.append(tb(['`pili`', '霹雳岛 → `pilidao`　/　霹雳门 → `pilimen`']))
head.append(tb(['`tianshan`', '天山 → `tianshan`　/　天山派 → `tianshanpai`']))
head.append(tb(['`wuxian`', '五仙教 → `wuxianjiao`　/　五仙岭 → `wuxianling`']))
head.append('')
head.append('## 四、记不清拼音？用搜索')
head.append('')
head.append('F1 控制台输入 `tpm <关键词>`，例如 `tpm 万`，列出所有匹配地图。')
head.append('')
head.append('## 五、注意事项')
head.append('')
head.append('- ⚠️ 完整全拼传送可直达禁地（测试地图、达摩洞等），会跳过剧情，强烈建议走剧情')
head.append('- 传送到剧情未解锁区域可能触发异常')
head.append('- 若传送后黑屏（少见），等待加载完成或再传一次即可')
head.append('')
head.append('## 六、安装')
head.append('')
head.append('1. 安装 UE4SS 实验版 v3.0.1-944（`dwmapi.dll` + `ue4ss/` 放游戏 `Binaries/Win64/`）')
head.append('2. 将 `TeleportMod` 文件夹放入 `Binaries/Win64/ue4ss/Mods/`')
head.append('3. 确认 `mods.txt` 中 `TeleportMod : 1`')
head.append('4. 启动游戏，按 F1 测试')
head.append('')
head.append('---')
head.append('')
head.append('## 附录：92 个世界地图地点拼音对照表')
head.append('')
head.append(tb(['地名', '前两字前缀', '完整拼音', 'tomap ID']))
head.append(tb(['---', '---', '---', '---']))
for r in rows:
    prefix_col = r['prefix'] if not r['conflict'] else r['prefix'] + '（重名）'
    head.append(tb([r['name'], '`' + prefix_col + '`', '`' + r['full'] + '`', str(r['id'])]))
head.append('')
head.append('> 说明：前缀冲突的 3 组已在上方第三节列出，输完整拼音即可；两字地名的前缀与完整拼音相同。')
head.append('')

with open(OUT, 'w', encoding='utf-8') as f:
    f.write('\n'.join(head))
print('已生成:', OUT, '| 地点数:', len(rows))
