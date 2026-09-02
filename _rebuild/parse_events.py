# -*- coding: utf-8 -*-
"""解析 Claude Code 会话 jsonl → events.jsonl（仅本项目 Edit/Write/MultiEdit 事件）"""
import json, os, re, sys

SRC = r'C:\Users\Administrator\.claude\projects\e--CCSpace\2aa173f6-4273-43d7-86b8-fb8b6e2e9490.jsonl'
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), 'events.jsonl')
PROJ = r'E:\CCSpace\projects\2026\08\逸剑风云决传送mod'
TOOLS = ['Edit', 'Write', 'MultiEdit']

def norm_path(p):
    """规范化为项目相对路径；非项目文件返回 None"""
    if not p: return None
    p = p.strip().replace('/', '\\')
    # 统一盘符大小写
    m = re.match(r'^([a-zA-Z]):\\(.*)$', p)
    if m: p = m.group(1).upper() + ':\\' + m.group(2)
    pl = p.lower()
    proj_l = PROJ.lower()
    if pl.startswith(proj_l):
        rel = p[len(PROJ):].lstrip('\\')
        return rel.replace('\\', '/') if rel else None
    # 含"逸剑"的其他路径（如复制到的游戏目录）也归一，若无法映射则忽略
    return None

def user_text(o):
    m = o.get('message') or {}
    c = m.get('content')
    if isinstance(c, str): return c
    if isinstance(c, list):
        parts = []
        for it in c:
            if isinstance(it, dict) and it.get('type') == 'text':
                parts.append(it.get('text', ''))
        return '\n'.join(parts)
    return ''

def main():
    events, orphans = [], []
    last_intent = ''
    n_lines = 0
    with open(SRC, encoding='utf-8') as f:
        for ln, line in enumerate(f, 1):
            n_lines += 1
            try:
                o = json.loads(line)
            except Exception:
                orphans.append({'line': ln, 'err': 'json'})
                continue
            t = o.get('type')
            if t == 'user':
                txt = (user_text(o) or '').strip()
                # 过滤工具结果/系统包裹
                if txt and not txt.startswith('<') and not txt.startswith('[Request interrupted'):
                    last_intent = txt[:80].replace('\n', ' ').replace('\r', ' ')
                continue
            if t != 'assistant': continue
            msg = o.get('message') or {}
            content = msg.get('content') or []
            ts = o.get('timestamp', '')
            if not isinstance(content, list): continue
            for item in content:
                if not (isinstance(item, dict) and item.get('type') == 'tool_use'): continue
                if item.get('name') not in TOOLS: continue
                inp = item.get('input') or {}
                rel = norm_path(inp.get('file_path'))
                if rel is None: continue
                ev = {
                    'line': ln, 'ts': ts, 'tool': item['name'], 'file': rel,
                    'intent': last_intent,
                }
                try:
                    if item['name'] == 'Write':
                        ev['content'] = inp.get('content', '')
                        ev['action'] = 'write'
                    elif item['name'] == 'Edit':
                        ev['old'] = inp.get('old_string', '')
                        ev['new'] = inp.get('new_string', '')
                        ev['all'] = bool(inp.get('replace_all'))
                        ev['action'] = 'edit'
                    else:  # MultiEdit
                        ev['edits'] = [
                            {'old': e.get('old_string', ''), 'new': e.get('new_string', ''),
                             'all': bool(e.get('replace_all'))}
                            for e in (inp.get('edits') or [])
                        ]
                        ev['action'] = 'multiedit'
                    events.append(ev)
                except Exception as e:
                    orphans.append({'line': ln, 'err': str(e)[:80]})

    events.sort(key=lambda e: (e['ts'], e['line']))
    with open(OUT, 'w', encoding='utf-8') as f:
        for ev in events:
            f.write(json.dumps(ev, ensure_ascii=False) + '\n')
    print(f'lines={n_lines} events={len(events)} orphans={len(orphans)}')
    # 汇总
    from collections import Counter
    files = Counter(e['file'] for e in events)
    first = {}
    for e in events:
        first.setdefault(e['file'], e['action'])
    print('--- files (%d) [first_action] ---' % len(files))
    for fp, n in files.most_common():
        print(f'{first[fp]:10s} {n:4d}  {fp}')

if __name__ == '__main__':
    main()
