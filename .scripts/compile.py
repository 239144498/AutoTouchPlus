#!/usr/bin/env python3
import os, re
boilerplate = """AUTOTOUCHPLUS_VERSION = "0.4.0"
"""

files = ['src/core.lua', 'src/logic.lua'] + sorted(['src/' + i for i in os.listdir('src') if i != 'core.lua' and i != 'logic.lua'])

lines = []
for fn in files:
  with open(fn) as f:
    lines.extend(f.read().splitlines())


result = []
for ln in lines:
  c = ln.strip('\r\n ')
  if any(ln.startswith(i) for i in ['return', 'require', '--']):
    continue
  else:
    result.append(c)


with open('AutoTouchPlus.lua', 'w') as f:
  f.write(boilerplate)
  for ln in result:
    f.write(ln + '\n')
