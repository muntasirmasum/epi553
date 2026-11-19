#!/usr/bin/env python3
"""Build a student lab template from the in-class lab at the end of a lecture.

Usage:
    python3 tools/convert/lab_template.py LECTURE.qmd TEMPLATE.qmd "Template title" ["Author line"]

The lecture's lab must contain a chunk labeled `lab-setup` (the full data code)
and task headings of the form `### Task N: ...` (or `####`). The template gets:
  * a YAML header with `embed-resources: true`, so the rendered HTML is one file;
  * the lab-setup code as a runnable setup chunk;
  * every task heading and prompt, verbatim, each followed by an empty R chunk
    and an "Your answer:" line (one per lettered part such as **2a. (5 pts)**).
Render the template on its own afterwards to check that it runs.
"""
import re
import sys

PART = re.compile(r"^\*\*(\d+[a-z])\.")
TASK = re.compile(r"^#{3,4} (Task \d+[^\n]*)")
HEADING = re.compile(r"^#{2,4} (.*)")


def answer_block(label):
    return f"\n```{{r}}\n#| label: {label}\n\n```\n\n*Your answer:*\n"


def main(src, dst, title, author="Your Name"):
    s = open(src, encoding="utf-8").read()

    m = re.search(r"```\{r\}\n#\| label: lab-setup\n(.*?)```\n", s, flags=re.S)
    if not m:
        sys.exit("no lab-setup chunk found")
    setup = "\n".join(l for l in m.group(1).splitlines() if not l.startswith("#|")).strip()

    start = re.search(r"\n#{2,4} (Round 1|Task 1)\b", s).start()
    # The tasks end at the session info, the submission text, or the summary
    end_marks = [s.find(x, start) for x in (
        "\n::: {.callout-note collapse=\"true\"}\n## Session info", "\n## Session info",
        "\n### Submission Instructions", "\n**Submission:**", "\n## Summary")]
    end_marks = [e for e in end_marks if e > 0]
    end = min(end_marks) if end_marks else len(s)
    tasks = s[start:end].strip().splitlines()
    # A grading note such as "**Completion credit ...**" goes after the last answer block
    credit = [l for l in tasks if l.startswith("**Completion credit")]
    tasks = [l for l in tasks if not l.startswith("**Completion credit")]

    out, n_task, open_label, block_start = [], 0, None, 0

    def close(label):
        # Tasks that already give a starter code chunk only need an answer line
        if any(l.startswith("```{r}") for l in out[block_start:]):
            out.append("\n*Your answer:*\n")
        else:
            out.append(answer_block(label))

    for line in tasks:
        t = TASK.match(line)
        p = PART.match(line)
        if t or p:
            # A task's own answer block is only needed when it has no lettered parts
            if open_label and not (p and open_label == f"task-{n_task}"):
                close(open_label)
            if t:
                n_task += 1
                out.append(f"\n## {t.group(1)}\n")
                open_label, block_start = f"task-{n_task}", len(out)
                continue
            open_label, block_start = f"task-{p.group(1)}", len(out)
        if line.strip() in ("*End of Lab Activity*",):
            continue
        h = HEADING.match(line)
        if h:  # other headings inside the lab (for example "Round 2") become level 2
            if open_label:
                close(open_label)
                open_label = None
            out.append(f"\n## {h.group(1)}\n")
            block_start = len(out)
            continue
        out.append(line)
    if open_label:
        close(open_label)

    out.extend([""] + credit)
    body = re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip() + "\n"
    header = f'''---
title: "{title}"
author: "{author}"
format:
  html:
    embed-resources: true
    toc: true
---

```{{r}}
#| label: setup
#| message: false
#| warning: false
{setup}
```

'''
    open(dst, "w", encoding="utf-8").write(header + body)
    print(f"wrote {dst}: {n_task} tasks, {body.count('*Your answer:*')} answer blocks")


if __name__ == "__main__":
    if len(sys.argv) not in (4, 5):
        sys.exit(__doc__)
    main(*sys.argv[1:])
