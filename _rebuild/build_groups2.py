# -*- coding: utf-8 -*-
"""v2: 前向回放 + 失败点后切换磁盘逆向锚定；组内容按磁盘行尾风格输出 → groups.json / summary.txt"""
import json, os, datetime
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'E:\CCSpace\projects\2026\08\逸剑风云决传送mod'
WINDOW = 600

SEED_OVERRIDE = {'MOD说明.md': 'MOD说明.txt'}  # 磁盘近亲种子（近似）

def disk_info(rel):
    p = os.path.join(PROJ, rel.replace('/', os.sep))
    if not os.path.isfile(p): return None, False
    raw = open(p, 'rb').read()
    crlf = raw.count(b'\r\n') > 0 and raw.count(b'\r\n') * 2 >= raw.count(b'\n')
    return raw.decode('utf-8').replace('\r\n', '\n'), crlf

def pairs_of(e):
    if e['action'] == 'write': return None
    return e['edits'] if e['action'] == 'multiedit' else [
        {'old': e['old'], 'new': e['new'], 'all': e['all']}]

def rep_apply(c, old, new, all_):
    if old == new: return c, old in c
    if old in c: return (c.replace(old, new) if all_ else c.replace(old, new, 1)), True
    return c, False

def main():
    evs = [json.loads(l) for l in open(os.path.join(HERE, 'events.jsonl'), encoding='utf-8')]
    evs.sort(key=lambda e: (e['ts'], e['line']))
    byfile = OrderedDict()
    for i, e in enumerate(evs):
        byfile.setdefault(e['file'], []).append(i)

    states = {}   # global event idx -> LF content (or None)
    print('--- per-file plan ---')
    for f, idxs in byfile.items():
        fevs = [evs[i] for i in idxs]
        dnorm, crlf = disk_info(f)
        seed = dnorm if dnorm is not None else (disk_info(SEED_OVERRIDE[f])[0] if f in SEED_OVERRIDE else None)
        # 前向
        F, fails = [], []
        st = None
        for ev in fevs:
            if ev['action'] == 'write':
                st = ev['content'].replace('\r\n', '\n')
            else:
                for pr in pairs_of(ev):
                    if st is None:
                        fails.append(True)
                        # 磁盘无此文件但指定了近亲种子 → 用种子近似（无法精确回放）
                        if st is None and seed is not None and dnorm is None:
                            st = seed
                        continue
                    st, ok = rep_apply(st, pr['old'], pr['new'], pr['all'])
                    if not ok: fails.append(True)
            F.append(st); fails.append(False)
        # 后向（从磁盘）
        B, bvalid = [None] * len(fevs), [False] * len(fevs)
        if dnorm is not None:
            st = dnorm; bvalid[-1] = True; B[-1] = dnorm
            for k in range(len(fevs) - 1, 0, -1):
                ps = pairs_of(fevs[k])
                if ps is None:  # write：前态未知，链断
                    break
                ok2 = True
                for pr in reversed(ps):
                    if pr['new'] in st:
                        st = st.replace(pr['new'], pr['old'])
                    else:
                        ok2 = False; break
                if not ok2: break
                B[k - 1] = st; bvalid[k - 1] = True
        # 切换点：第一个失败事件；其后用 B（要求 B 有效）
        fail_idx = next((k for k, x in enumerate(fails) if x), None)
        T = fail_idx if (fail_idx is not None and dnorm is not None) else None
        if T is not None:
            bad = [k for k in range(T, len(fevs)) if not bvalid[k]]
            if bad:
                print(f'  !! {f}: B链在 {bad[0]} 处断（T={T}），退化为 F 近似')
                T = None if bad[0] == T else T
        for k, gi in enumerate(idxs):
            states[gi] = F[k] if (T is None or k < T) else B[k]
        mode = 'F' if T is None else f'F->B@{T}'
        final_ok = (F[-1] == dnorm) if dnorm is not None else None
        print(f'  {f}: n={len(idxs)} fails={sum(fails)} mode={mode} forward_final_matches_disk={final_ok} crlf={crlf}')

    # 分组
    groups, cur, last_ts = [], None, None
    for i, e in enumerate(evs):
        t = datetime.datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
        if cur is None or (last_ts and (t - last_ts).total_seconds() > WINDOW):
            cur = {'start': e['ts'], 'end': e['ts'], 'idxs': [], 'actions': {}}
            groups.append(cur)
        cur['end'] = e['ts']; cur['idxs'].append(i); last_ts = t
        cur['actions'].setdefault(e['file'], []).append(e['action'])

    # 组内容（磁盘行尾风格）
    prev = {}
    gout = []
    for g in groups:
        changed = OrderedDict()
        seen = OrderedDict()
        for i in g['idxs']:
            seen.setdefault(evs[i]['file'], i)  # 首次出现
            c = states[i]
            if c is None: continue
            changed[evs[i]['file']] = c
        final = OrderedDict()
        for f, c in changed.items():
            _, crlf = disk_info(f)
            if crlf: c = c.replace('\n', '\r\n')
            if prev.get(f) != c:
                final[f] = c
        prev.update(changed)
        g['changed'] = final

    # 校验：每文件最后组内容 == 磁盘
    last_state = {}
    for g in groups:
        for f, c in g['changed'].items(): last_state[f] = c
    print('--- final-vs-disk ---')
    for f, idxs in byfile.items():
        dnorm, _ = disk_info(f)
        if dnorm is None: continue
        c = last_state.get(f)
        if c is None: continue
        _, crlf = disk_info(f)
        want = dnorm.replace('\n', '\r\n') if crlf else dnorm
        print(f'  {"OK " if c == want else "DIFF"} {f}')

    with open(os.path.join(HERE, 'groups.json'), 'w', encoding='utf-8') as f:
        json.dump([{'start': g['start'], 'end': g['end'], 'n_events': len(g['idxs']),
                    'files': g['changed'],
                    'file_actions': {k: v for k, v in g['actions'].items()},
                    'intents': list(OrderedDict.fromkeys(evs[i]['intent'] for i in g['idxs'] if evs[i]['intent']))}
                   for g in groups], f, ensure_ascii=False)
    with open(os.path.join(HERE, 'summary.txt'), 'w', encoding='utf-8') as f:
        for gi, g in enumerate(groups):
            lt = lambda ts: (datetime.datetime.fromisoformat(ts.replace('Z', '+00:00')) +
                             datetime.timedelta(hours=8)).strftime('%m-%d %H:%M')
            f.write(f"== G{gi:02d} {lt(g['start'])}~{lt(g['end'])} events={len(g['idxs'])}\n")
            for fn, acts in g['actions'].items():
                w = acts.count('write'); ed = len(acts) - w
                tag = ('new' if fn not in getattr(g, '_prev', set()) else 'mod')
                stat = f"W{w}E{ed}" if w else f"E{ed}"
                size = len(g['changed'][fn]) if fn in g['changed'] else -1
                f.write(f"   {tag:3s} {stat:8s} {fn} ({size})\n")
            for it in list(OrderedDict.fromkeys(evs[i]['intent'] for i in g['idxs'] if evs[i]['intent']))[:8]:
                f.write(f"   I {it}\n")
    ne = sum(len(g['changed']) for g in groups)
    print(f'groups={len(groups)} file_commits={ne} empty={sum(1 for g in groups if not g["changed"])}')

if __name__ == '__main__':
    main()
