#!/usr/bin/env python

import random
import fileinput
import sys
import os

def print_usage(prog):
    print ("%s [list of files]" % prog)
    return

if len(sys.argv) == 1:
    print_usage(sys.argv[0])
    sys.exit(1)

for f in sys.argv[1:]:
    if not os.access(f, os.R_OK):
        print "file '%s' is not readable" % f
        sys.exit(1)

for line in fileinput.input():
    columns = line.split()
    cn = len(columns)
    if cn > 0:
        col_idx = int(random.random() * cn + 0.5)
        if col_idx == cn:
            col_idx = 0
        print columns[col_idx]

sys.exit(0)
