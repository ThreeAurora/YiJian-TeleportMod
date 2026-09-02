# -*- coding: utf-8 -*-
"""events.jsonl → 10分钟窗分组 + 逐文件内容回放重建 → groups.json / summary.txt"""
import json, os, datetime
from collections import OrderedDict

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = r'E:\CCSpace\projects\2026\08\逸剑风云决传送mod'
WINDOW = 600  # 秒

# 无法正向回放的文件 → 用磁盘现存近亲作种子（近似）
SEED_OVERRIDE = {
    'MOD说明.md': 'MOD说明.txt',
}

def read_disk(rel):
    p = os.path.join(PROJ, rel)
    if os.path.isfile(p):
        try:
            return open(p, encoding='utf-8', newline='').read()
        except UnicodeDecodeError:
            return open(p, encoding='utf-8', newline='').read(0)  # 二进制罕见
    return None

def apply_pair(content, old, new, all_):
    if content is None: return None, False
    if old == new:
        return content, old in content
    if old in content:
        return (content.replace(old, new) if all_ else content.replace(old, new, 1)), True
    return content, False

def replay_file(fevs, seed):
    """返回 states[i] = 第 i 个事件之后的内容；approx_flags[i]"""
    states, approx = [], []
    state, unknown_base = (None, True) if fevs[0]['action'] != 'write' else (None, False)
    fails = 0
    for ev in fevs:
        if ev['action'] == 'write':
            state = ev['content']; unknown_base = False
        else:
            pairs = ev['edits'] if ev['action'] == 'multiedit' else [
                {'old': ev['old'], 'new': ev['new'], 'all': ev['all']}]
            for pr in pairs:
                if state is None:
                    fails += 1; continue
                state, ok = apply_pair(state, pr['old'], pr['new'], pr['all'])
                if not ok: fails += 1
        states.append(state)
        approx.append(False)
    # 未知起点 → 逆向回放补齐
    if unknown_base and seed is not None:
        st = seed
        ok_all = True
        for i in range(len(fevs) - 1, -1, -1):
            if states[i] is None:
                states[i] = st; approx[i] = ok_all
            # 逆应用事件 i
            pairs = fevs[i]['edits'] if fevs[i]['action'] == 'multiedit' else [
                {'old': fevs[i]['old'], 'new': fevs[i]['new'], 'all': fevs[i]['all']}]
            for pr in reversed(pairs):
                st, ok = apply_pair(st, pr['new'], pr['old'], pr['all'])
                if not ok:
                    ok_all = True  # 之前的全部用当前近似
                    break
        # 校验：正向重放应回到 seed
    return states, approx, fails

def main():
    evs = [json.loads(l) for l in open(os.path.join(HERE, 'events.jsonl'), encoding='utf-8')]
    evs.sort(key=lambda e: (e['ts'], e['line']))
    # 逐文件事件
    byfile = OrderedDict()
    for i, e in enumerate(evs):
        byfile.setdefault(e['file'], []).append(i)
    # 种子
    seeds = {}
    for f in byfile:
        if f in SEED_OVERRIDE:
            seeds[f] = read_disk(SEED_OVERRIDE[f])
        else:
            seeds[f] = read_disk(f)
    # 回放
    states = {}   # event_idx -> content
    approx = {}   # event_idx -> bool
    report = []
    for f, idxs in byfile.items():
        fevs = [evs[i] for i in idxs]
        st, ap, fails = replay_file(fevs, seeds.get(f))
        for k, i in enumerate(idxs):
            states[i] = st[k]; approx[i] = ap[k]
        last = st[-1]
        d = seeds.get(f)
        match = (last == d) if (d is not None and f not in SEED_OVERRIDE) else None
        report.append((f, len(fevs), fails, 'OK' if match else ('APPROX' if match is None else 'MISMATCH')))
    print('--- replay report ---')
    for r in report:
        print(f'{r[3]:9s} fails={r[2]:<3d} n={r[1]:<4d} {r[0]}')

    # 分组
    groups, cur = [], None
    last_ts = None
    for i, e in enumerate(evs):
        t = datetime.datetime.fromisoformat(e['ts'].replace('Z', '+00:00'))
        if cur is None or (last_ts and (t - last_ts).total_seconds() > WINDOW):
            cur = {'start': e['ts'], 'end': e['ts'], 'idxs': []}
            groups.append(cur)
        cur['end'] = e['ts']; cur['idxs'].append(i); last_ts = t

    # 组内变更文件最终内容（与上一组比较，无变化则剔除）
    prev_content = {}
    gout = []
    for gi, g in enumerate(groups):
        changed = OrderedDict()
        for i in g['idxs']:
            f = evs[i]['file']
            c = states[i]
            if c is None: continue
            changed[f] = c
        final = OrderedDict()
        for f, c in changed.items():
            if prev_content.get(f) != c:
                final[f] = c
        prev_content.update(changed)
        g['changed'] = final
        g['n_events'] = len(g['idxs'])
        g['intents'] = list(OrderedDict.fromkeys(evs[i]['intent'] for i in g['idxs'] if evs[i]['intent']))
        gout.append(g)

    # 序列化
    with open(os.path.join(HERE, 'groups.json'), 'w', encoding='utf-8') as f:
        json.dump([{'start': g['start'], 'end': g['end'], 'n_events': g['n_events'],
                    'files': {k: v for k, v in g['changed'].items()},
                    'intents': g['intents']} for g in gout],
                  f, ensure_ascii=False)
    # 摘要
    with open(os.path.join(HERE, 'summary.txt'), 'w', encoding='utf-8') as f:
        for gi, g in enumerate(gout):
            f.write(f"== G{gi:03d} {g['start']} ~ {g['end']} events={g['n_events']} files={len(g['changed'])}\n")
            for fn, c in g['changed'].items():
                f.write(f"   M {fn}  ({len(c)} chars)\n")
            for it in g['intents'][:6]:
                f.write(f"   I {it}\n")
    print(f'groups={len(gout)}')
    total_changed = sum(len(g['changed']) for g in gout)
    empty = [gi for gi, g in enumerate(gout) if not g['changed']]
    print(f'total file-commits={total_changed} empty-groups={empty}')

if __name__ == '__main__':
    main()
