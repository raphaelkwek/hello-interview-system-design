# hello-interview-sd

System design interview practice for Claude Code, following the Hello Interview method: Requirements → Core Entities → API → (Data Flow) → High-Level Design → Deep Dives, graded on Problem Navigation, Solution Design, Technical Excellence, and Communication & Collaboration.

Unofficial; not affiliated with Hello Interview.

## Install

```bash
claude plugin marketplace add ~/GitHub/hello-interview-sd
claude plugin install hello-interview-sd@hello-interview-sd
```

## Use

```
/hello-interview mock                      # random problem at your level
/hello-interview mock ticketmaster --level=staff
/hello-interview learn "design WhatsApp"
/hello-interview learn --auto --exchanges=10
/hello-interview postmortem --file=./notes.md
/hello-interview generate "url shortener"
```

Set a default level: `echo senior > ~/.hello-interview/level.md` (`mid`, `senior` or `staff`).

Progress lives in `~/.hello-interview/runs.md` and `weaknesses.md`.

## Develop

`scripts/check.sh` runs the structural checks.
