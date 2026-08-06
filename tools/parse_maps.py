# -*- coding: utf-8 -*-
"""解析 Maps.uexp，提取 地图ID(行号) -> ViewName(中文地名) 映射"""
import re
import json

UEXP = r'C:\Users\Administrator\AppData\Local\Temp\Maps.uexp'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\maps_id_name.json'

with open(UEXP, 'rb') as f:
    data = f.read()


def decode_utf16_at(data, offset, max_len=200):
    """尝试从 offset 解码 UTF-16 可读字符串（FText 内联文本）"""
    # 直接按 UTF-16LE 解码一小段
    try:
        text = data[offset:offset + max_len * 2].decode('utf-16-le', errors='replace')
        # 提取开头的连续可读中文字符
        m = re.match(r'[\u4e00-\u9fff\u3000-\u303f\uff00-\uffef\u0020-\u007e]{2,}', text)
        if m:
            return m.group()
    except Exception:
        pass
    return None


# 找到所有 "数字_ViewName" ASCII 模式及偏移
key_matches = []
for m in re.finditer(rb'(\d+)_ViewName', data):
    key_matches.append((int(m.group(1)), m.start()))

print('找到 ViewName Key 数量:', len(key_matches))

results = {}
for row_id, key_off in key_matches:
    # 在 Key 之后搜索 UTF-16 内联文本（FText 的 SourceString）
    # FText: Flags(4) + TextHistoryType(4) + FString(len + chars)
    # 直接向后搜索第一个可读中文
    found_text = None
    # 搜索范围：key_off 后 2~600 字节内，每 2 字节对齐尝试
    for off in range(key_off + 4, key_off + 600, 2):
        txt = decode_utf16_at(data, off)
        if txt and re.search(r'[\u4e00-\u9fff]', txt):
            found_text = txt
            break
    if found_text:
        results[row_id] = found_text
    else:
        results[row_id] = None

# 验证已知映射
print('验证: 10 ->', results.get(10))
print('验证: 11 ->', results.get(11))
print('验证: 13 ->', results.get(13))
print('验证: 1 ->', results.get(1))

# 统计
named = {k: v for k, v in results.items() if v}
print('有效地名数量:', len(named))

# 保存
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=1)
print('已保存:', OUT)

# 打印前 40 个
for k in sorted(results)[:40]:
    print('  %s -> %s' % (k, results[k]))
