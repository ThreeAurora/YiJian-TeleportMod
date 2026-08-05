# -*- coding: utf-8 -*-
"""检查 Lua 文件的括号配对和引号配对（简化静态检查）"""
import sys


def strip_strings_comments(s):
    """去掉字符串字面量和注释，返回纯代码"""
    out = []
    i = 0
    n = len(s)
    state = 'code'
    while i < n:
        c = s[i]
        if state == 'code':
            if c == '"':
                state = 'str_dq'
            elif c == "'":
                state = 'str_sq'
            elif c == '-' and i + 1 < n and s[i + 1] == '-':
                # 注释
                if i + 2 < n and s[i + 2] == '[':
                    state = 'block_comment'
                    i += 2
                    continue
                else:
                    state = 'line_comment'
            elif c == '[':
                # 可能是长字符串 [[...]]，保守按 code 处理（括号检查）
                out.append(c)
            else:
                out.append(c)
        elif state == 'str_dq':
            if c == '\\':
                i += 1
            elif c == '"':
                state = 'code'
        elif state == 'str_sq':
            if c == '\\':
                i += 1
            elif c == "'":
                state = 'code'
        elif state == 'line_comment':
            if c == '\n':
                state = 'code'
                out.append(c)
        elif state == 'block_comment':
            if c == ']':
                state = 'code'
        i += 1
    return ''.join(out)


def check(path):
    with open(path, encoding='utf-8') as f:
        src = f.read()
    lines = src.split('\n')
    code = strip_strings_comments(src)
    pairs = {'(': ')', '[': ']', '{': '}'}
    stack = []
    errors = []
    for idx, c in enumerate(code):
        if c in pairs:
            stack.append((c, idx))
        elif c in pairs.values():
            if not stack:
                errors.append('多余闭合 %s (约第 %d 行)' % (c, src[:idx].count('\n') + 1))
            else:
                open_c, oi = stack.pop()
                if pairs[open_c] != c:
                    errors.append('括号不匹配: %s 对 %s (约第 %d 行)' % (open_c, c, src[:idx].count('\n') + 1))
    if stack:
        for c, idx in stack:
            errors.append('未闭合 %s (约第 %d 行)' % (c, src[:idx].count('\n') + 1))
    if errors:
        print('%s: 发现问题' % path)
        for e in errors:
            print('  -', e)
        return False
    print('%s: OK (%d 行)' % (path, len(lines)))
    return True


if __name__ == '__main__':
    files = [
        r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\main.lua',
        r'e:\CCSpace\projects\2026\08\逸剑风云决传送mod\mod\TeleportMod\Scripts\maps.lua',
    ]
    ok = all(check(p) for p in files)
    sys.exit(0 if ok else 1)
