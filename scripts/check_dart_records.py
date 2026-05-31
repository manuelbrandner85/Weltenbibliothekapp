#!/usr/bin/env python3
"""dart2js Named-Record Guard.

Named Dart 3 record TYPE annotations like ({String name, int count}) crash
dart2js (Flutter Web build). Positional records (.$1/.$2) and named method
parameters ({String? foo}) are fine. This scanner flags only real record TYPE
annotations in type positions (generics, field/var types, return types).

Deterministic and UTF-8 safe -- unlike `grep -P`, which can misbehave on the
emoji-heavy .dart files in this repo depending on the CI locale.

Exit 0 = clean. Exit 1 = forbidden named record types found.
"""
import re
import sys
import pathlib

# A record type body opens with ({ then "Type identifier" pairs.
# Type = an uppercase-leading identifier or a known lowercase primitive.
# The (?<![A-Za-z0-9_]) before ( excludes method parameter lists like
# foo({String? x}) where ( follows a function name.
PRIM = r"(?:String|int|double|bool|num|void|dynamic|Object)"
PATTERN = re.compile(
    r"(?<![A-Za-z0-9_])\(\{\s*(?:" + PRIM + r"|[A-Z][A-Za-z0-9_]*)\??\s+[a-z][A-Za-z0-9_]*\s*[,}]"
)

root = pathlib.Path("lib")
hits = []
for path in sorted(root.rglob("*.dart")):
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        text = path.read_text(encoding="utf-8", errors="replace")
    for lineno, line in enumerate(text.splitlines(), 1):
        if line.lstrip().startswith("//"):
            continue
        if PATTERN.search(line):
            hits.append((str(path), lineno, line.strip()[:120]))

if hits:
    print("FATAL: Named Dart 3 record types found - these crash dart2js web compilation.")
    print("Replace each ({Type field, ...}) annotation with a plain Dart class.")
    print("-" * 60)
    for f, n, t in hits:
        print(f"{f}:{n}: {t}")
    sys.exit(1)

print("OK: No dart2js-incompatible named record types found.")
sys.exit(0)
