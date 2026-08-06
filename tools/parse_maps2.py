# -*- coding: utf-8 -*-
"""解析 Maps.uexp: 从 X_ViewName FText Key 提取 行号 -> 地名"""
import re
import json

UEXP = r'C:\Users\Administrator\AppData\Local\Temp\Maps.uexp'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\maps_id_name.json'

with open(UEXP, 'rb') as f:
    data = f.read()


def read_utf16_string(data, off, max_chars=50):
    """读 UTF-16LE 字符串直到 null，返回 (str, next_off) 或 (None, None)"""
    chars = []
    for i in range(max_chars):
        pos = off + i * 2
        if pos + 2 > len(data):
            break
        c = data[pos:pos + 2]
        if c == b'\x00\x00':
            return ''.join(chars), off + (i + 1) * 2
        try:
            chars.append(c.decode('utf-16-le'))
        except Exception:
            break
    return None, None


results = {}
for m in re.finditer(rb'(\d+)_ViewName', data):
    key_str = m.group(1).decode()
    key_off = m.start()
    key_len = len(m.group(0)) + 1  # 含 null

    # Key 前面应有 FString 长度(含null) 字段
    # Key 结束后 +4 字节 = SourceString 起点
    src_off = key_off + key_len + 4
    text, next_off = read_utf16_string(data, src_off)
    if text and re.search(r'[\u4e00-\u9fff]', text):
        results[int(key_str)] = text

print('提取到的地名数:', len(results))

# 验证已知映射
for check in [10, 11, 13]:
    print('验证 %d -> %s' % (check, results.get(check)))

with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=1, sort_keys=True)
print('已保存:', OUT)

print('=== 前 50 个 ===')
for k in sorted(results)[:50]:
    print('  %s -> %s' % (k, results[k]))
