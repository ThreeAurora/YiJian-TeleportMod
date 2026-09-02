# -*- coding: utf-8 -*-
"""groups.json + messages.json → timeline.fi
规避 git 2.43 fast-import 的 data 载荷行尾怪癖：
- 文件 blob 全部经 git hash-object -w 预写，流内用 <sha> 引用；
- 流内仅剩提交消息 data 块，且一律以 \n 结尾（已验证安全）。
收尾三提交：.gitignore / 会话外产物对齐 / README。
"""
import json, os, calendar, datetime, subprocess

HERE = os.path.dirname(os.path.abspath(__file__))
PROJ = os.path.dirname(HERE)
IDENT = b'Aurora <chengweida2010@163.com>'
TZ = b'+0800'
FI = os.path.join(HERE, 'timeline.fi')

_sha_cache = {}

def blob_sha(b: bytes) -> str:
    if b in _sha_cache: return _sha_cache[b]
    r = subprocess.run(['git', 'hash-object', '-w', '--stdin'], cwd=PROJ,
                       input=b, capture_output=True)
    if r.returncode != 0:
        raise RuntimeError(r.stderr.decode('utf-8', 'replace'))
    sha = r.stdout.decode().strip()
    _sha_cache[b] = sha
    return sha

def epoch(ts):
    return calendar.timegm(datetime.datetime.fromisoformat(ts.replace('Z', '+00:00')).utctimetuple())

def emit_commit(out, ts, msg: str, changes):
    out.write(b'commit refs/heads/main\n')
    out.write(b'author %s %d %s\n' % (IDENT, ts, TZ))
    out.write(b'committer %s %d %s\n' % (IDENT, ts, TZ))
    mb = msg.encode('utf-8')
    if not mb.endswith(b'\n'): mb += b'\n'
    out.write(b'data %d\n' % len(mb)); out.write(mb)
    for kind, *rest in changes:
        if kind in ('M_str', 'M_raw'):
            path = rest[0]
            raw = rest[1].encode('utf-8') if kind == 'M_str' else rest[1]
            out.write(('M 100644 %s ' % blob_sha(raw)).encode() + path.encode('utf-8') + b'\n')
        elif kind == 'D':
            out.write(('D ' + rest[0]).encode('utf-8') + b'\n')
    out.write(b'\n')

def walk_disk():
    import fnmatch
    out = {}
    for root, dirs, files in os.walk(PROJ):
        rel_root = os.path.relpath(root, PROJ).replace(os.sep, '/')
        if rel_root == '.': rel_root = ''
        if rel_root.split('/')[0] in ('.git', '_rebuild', '发布'):
            dirs[:] = []; continue
        if rel_root == 'extracted':
            dirs[:] = [d for d in dirs if d not in ('UE4SS', 'UE4SS_EXP944')]
        for fn in files:
            rel = (rel_root + '/' if rel_root else '') + fn
            if fnmatch.fnmatch(rel, 'tools/*.zip') or fnmatch.fnmatch(rel, 'tools/*.bin'):
                continue
            p = os.path.join(PROJ, rel.replace('/', os.sep))
            if os.path.isfile(p):
                out[rel] = open(p, 'rb').read()
    return out

def main():
    groups = json.load(open(os.path.join(HERE, 'groups.json'), encoding='utf-8'))
    msgs = json.load(open(os.path.join(HERE, 'messages.json'), encoding='utf-8'))
    assert len(msgs) == len(groups)
    out = open(FI, 'wb')
    tracked = set()
    for gi, g in enumerate(groups):
        changes = []
        for path, content in g['files'].items():
            changes.append(('M_str', path, content))
            tracked.add(path)
        emit_commit(out, epoch(g['end']), msgs[str(gi)], changes)
    now = int(datetime.datetime.now().timestamp())
    # 收尾 1：.gitignore
    emit_commit(out, now,
                'chore: 添加 .gitignore\n\n排除第三方 UE4SS 运行时与压缩包、游戏数据解码中间产物、\n发布打包产物及本地重建工作区。',
                [('M_raw', '.gitignore', open(os.path.join(PROJ, '.gitignore'), 'rb').read())])
    # 收尾 2：会话外产物对齐
    disk = walk_disk()
    changes, aligned = [], []
    for rel, raw in sorted(disk.items()):
        if rel in tracked or rel in ('.gitignore', 'README.md'):
            continue
        changes.append(('M_raw', rel, raw)); aligned.append(rel)
    if 'MOD说明.md' in tracked and 'MOD说明.md' not in disk:
        changes.append(('D', 'MOD说明.md'))
    body = ('纳入由脚本运行生成、未经过编辑器事件的产物：地图数据 lua、解析 json、\n'
            'UE4SS 参考文档与 main.lua 备份快照；MOD说明.md 定稿更名为 MOD说明.txt。'
            + ('\n\n新增文件：\n' + '\n'.join('- ' + a for a in aligned) if aligned else ''))
    emit_commit(out, now + 60, 'chore: 纳入会话外脚本产物并对齐工作区\n\n' + body, changes)
    # 收尾 3：README
    emit_commit(out, now + 120,
                'docs: 添加 README 项目说明\n\n面向使用者的项目门面：功能特性、安装与按键说明、目录结构、\n工具链说明及不入库内容的重建方式。',
                [('M_raw', 'README.md', open(os.path.join(PROJ, 'README.md'), 'rb').read())])
    out.close()
    print('fi written:', FI, os.path.getsize(FI), 'bytes; aligned files:', len(aligned),
          '; blobs hashed:', len(_sha_cache))

if __name__ == '__main__':
    main()
