"""Runs the open77_quickhack Lua tests with lupa (Lua 5.4): python tests/run.py"""
import pathlib
import sys

import lupa.lua54 as lua54

root = pathlib.Path(__file__).resolve().parent.parent
failures = 0
for test in sorted((root / "tests").glob("*.test.lua")):
    rt = lua54.LuaRuntime()
    rt.globals().ROOT = str(root).replace("\\", "/")
    print(f"== {test.name}")
    failures += int(rt.execute(test.read_text(encoding="utf-8")) or 0)
sys.exit(1 if failures else 0)
