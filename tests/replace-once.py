#!/usr/bin/env python3
"""Replace the first occurrence of a string in a file, preserving line endings.

Used by generate-defect-fixtures.sh instead of `sed -i`, which rewrites a
file's line endings and so turns a one-line injected defect into a whole-file
diff. `@@EOL@@` in the replacement becomes whatever the file already uses.

    replace-once.py <file> <old> <new>
"""

import io
import sys


def main(argv):
    if len(argv) != 4:
        print(__doc__, file=sys.stderr)
        return 2
    path, old, new = argv[1], argv[2], argv[3]
    text = io.open(path, encoding="utf-8", newline="").read()
    if old not in text:
        print("error: %r not found in %s" % (old, path), file=sys.stderr)
        return 1
    eol = "\r\n" if "\r\n" in text else "\n"
    io.open(path, "w", encoding="utf-8", newline="").write(
        text.replace(old, new.replace("@@EOL@@", eol), 1)
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
