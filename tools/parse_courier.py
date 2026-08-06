# -*- coding: utf-8 -*-
"""解析 CourierStation.uexp: 从 X_DisplayName FText Key 提取 驿站ID -> 驿站名"""
import re
import json

UEXP = r'C:\Users\Administrator\AppData\Local\Temp\CourierStation.uexp'
OUT = r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\extracted\courier_stations.json'

with open(UEXP, 'rb') as f:
    data = f.read()


def read_utf16_string(data, off, max_chars=50):
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
for m in re.finditer(rb'(\d+)_DisplayName', data):
    key_str = m.group(1).decode()
    key_off = m.start()
    key_len = len(m.group(0)) + 1  # 含 null
    src_off = key_off + key_len + 4
    text, next_off = read_utf16_string(data, src_off)
    if text and re.search(r'[\u4e00-\u9fff]', text):
        results[int(key_str)] = text

print('驿站数量:', len(results))
with open(OUT, 'w', encoding='utf-8') as f:
    json.dump(results, f, ensure_ascii=False, indent=1, sort_keys=True)
print('已保存:', OUT)
print('=== 驿站列表 ===')
for k in sorted(results):
    print('  %s -> %s' % (k, results[k]))
