# hello-interview-system-design

System design interview practice for Claude Code, following the Hello Interview method: Requirements → Core Entities → API → (Data Flow) → High-Level Design → Deep Dives, graded on Problem Navigation, Solution Design, Technical Excellence, and Communication & Collaboration.

Unofficial; not affiliated with Hello Interview.

## Install

```bash
claude plugin marketplace add ~/GitHub/hello-interview-system-design
claude plugin install hello-interview-system-design@hello-interview-system-design
```

## Use

```
/hello-interview-system-design mock                      # random problem at your level
/hello-interview-system-design mock ticketmaster --level=staff
/hello-interview-system-design learn "design WhatsApp"
/hello-interview-system-design learn --auto --exchanges=10
/hello-interview-system-design postmortem --file=./notes.md
/hello-interview-system-design generate "url shortener"
```

Set a default level: `echo senior > ~/.hello-interview/level.md` (`mid`, `senior` or `staff`).

Progress lives in `~/.hello-interview/runs.md` and `weaknesses.md`.

## Develop

`scripts/check.sh` runs the structural checks.
