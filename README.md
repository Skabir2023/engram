# AI Memory Setup
### A shared memory layer for Claude Code, OpenCode, Aider, and Antigravity

> Stop re-explaining your project to every AI tool. Engram gives Claude Code, OpenCode, Aider, and Antigravity a shared memory they read on startup and update on exit.

---

## The problem this solves

Every AI coding tool starts fresh. Switch from Claude Code to OpenCode mid-project and it reads your entire codebase from scratch, asks what you are building, and forgets everything the last session decided. This setup fixes that by giving every tool a shared memory it reads on startup and writes to before it ends.

---

## How it works

```
your-project/
│
├── AGENTS.md          ← Antigravity reads this
├── CLAUDE.md          ← Claude Code reads this
├── GEMINI.md          ← Gemini CLI reads this
│
└── .ai-context/       ← shared memory (all tools read and write here)
    ├── ARCHITECTURE.md    system design and folder structure
    ├── TECH_STACK.md      languages, frameworks, database, versions
    ├── CONVENTIONS.md     naming rules, folder rules, commit style
    ├── DECISIONS.md       why things were built the way they were
    ├── TASKS.md           current sprint, up next, backlog
    └── PROGRESS.md        timestamped log of every session
```

The root config files each contain one instruction: read `.ai-context/` before doing anything, and write to it before ending. The folder is the single source of truth that every tool shares.

---

## Quickstart

```bash
chmod +x setup-context.sh update-context.sh
./setup-context.sh
```

The script detects your situation automatically and runs in the right mode. See the next section for what each mode does.

---

## Three setup modes

### Mode 1 — New project (empty directory)

Run `setup-context.sh` in an empty folder. It asks you for the project name, language, framework, and database, then creates every file from scratch with those details pre-filled.

After it finishes, fill in two files before your first AI session:
- `.ai-context/ARCHITECTURE.md` — describe how the system is structured
- `.ai-context/TASKS.md` — add your first task under Current Sprint

### Mode 2 — Existing project (code already there, no memory yet)

Run `setup-context.sh` in a folder that already has source code. The script detects this automatically and switches to existing project mode. It then:

- Scans file extensions to identify the primary language
- Reads `package.json`, `requirements.txt`, `Cargo.toml`, `go.mod`, and similar files to detect frameworks
- Reads `.env`, `docker-compose.yml`, and config files to detect the database
- Captures the real folder structure and puts it inside `ARCHITECTURE.md`
- Pre-fills all memory files based on what it found

What the script detects automatically:

| Category | Detected from |
|---|---|
| Language | File extension counts across the project |
| Frameworks | `package.json`, `requirements.txt`, `pyproject.toml`, `Cargo.toml`, `go.mod` |
| Database | `.env`, `docker-compose.yml`, config files, dependency files |
| Folder structure | Real directory tree, excluding git and node_modules |

After it finishes, you only need to complete two things:
- `.ai-context/ARCHITECTURE.md` — the folder structure is already there, add the system design description
- `.ai-context/TASKS.md` — add what you are currently working on

Everything else is filled in from the scan.

### Mode 3 — Already has memory (`.ai-context/` exists)

If you run `setup-context.sh` and `.ai-context/` already exists, it asks what you want to do:

- **Add missing files only** — safe option, creates any files that are absent but leaves existing memory files untouched. Use this if you added a new AI tool and need its config file.
- **Full reset** — overwrites everything. Use this if you want to rebuild the memory from scratch after a major refactor.

---

## The two scripts

### `setup-context.sh`

Run once per project (or when you need to reset). Handles new projects, existing projects, and already-initialized projects. Never run in merge mode on a directory you do not own — it scans config files to detect the stack.

### `update-context.sh`

Run manually only when an AI tool could not update memory itself. Gives you a numbered menu:

```
1) Log a completed session manually
2) Add a task to TASKS.md
3) Log a decision to DECISIONS.md
4) Fix or overwrite the last PROGRESS.md entry
5) Mark a task done manually
6) Full review — show all memory files in terminal
```

---

## When the AI updates memory automatically

This is the normal case. Every root config file tells the AI:

> Before ending any session, append a new entry to `.ai-context/PROGRESS.md` and update `.ai-context/TASKS.md`.

So after a normal session in Antigravity, Claude Code, or OpenCode, the AI writes its own summary before it stops. The next session in any tool reads that summary and continues from there.

---

## When to run `update-context.sh` manually

| Situation | Why the AI cannot update |
|---|---|
| Session crashed or timed out | Never reached the end-of-session step |
| Free model limit hit mid-task | Session cut off before the update |
| You wrote code yourself without AI | No AI involved to write anything |
| You made a decision without an AI session | The AI does not know what you decided |
| AI wrote something wrong in PROGRESS.md | Needs manual correction |

---

## Switching tools mid-project

This is the main use case. Here is what happens in practice:

**Scenario: Antigravity free limits exhausted, switching to OpenCode**

1. Antigravity's last session wrote its summary to `PROGRESS.md`
2. Open OpenCode in Antigravity's integrated terminal
3. OpenCode reads `AGENTS.md` → reads `.ai-context/` → reads `PROGRESS.md`
4. OpenCode knows what was done last and what is next
5. OpenCode does the work and writes its own `PROGRESS.md` entry
6. Antigravity limits reset → next session reads `PROGRESS.md` → continues

No context lost. No re-explaining the project. The markdown files carry state across every tool and across days.

---

## Supported tools

| Tool | Config file | Where to run |
|---|---|---|
| Antigravity (built-in agents) | `AGENTS.md` | Antigravity Agent Manager |
| Claude Code | `CLAUDE.md` | Antigravity terminal or standalone |
| Gemini CLI | `GEMINI.md` | Antigravity terminal or standalone |
| OpenCode | `AGENTS.md` | Antigravity terminal or standalone |
| Aider | Pass files explicitly (see below) | Antigravity terminal |

For Aider, pass the context files on startup:

```bash
aider --read .ai-context/TASKS.md --read .ai-context/PROGRESS.md
```

---

## Free model strategy (zero cost)

| Tool | Free model | Best used for |
|---|---|---|
| Antigravity | Gemini 3.1 Pro (generous limits) | Main daily driver |
| Claude Code | Claude Sonnet (free tier) | Complex reasoning, refactoring |
| OpenCode + Groq | Llama 3.3 70B (free API at console.groq.com) | When Antigravity limits hit |
| Aider + Groq | Llama 3.3 70B | Git-commit-level edits |
| Ollama (local) | Qwen 2.5 Coder 7B | Offline or sensitive code |

---

## What each memory file is for

**ARCHITECTURE.md** — Describes the system design and folder structure. AI agents read this to know where new code should go before writing anything.

**TECH_STACK.md** — Lists every language, framework, and library with versions. Prevents AI from suggesting the wrong version or a package not in the project.

**CONVENTIONS.md** — Your naming rules, folder rules, and commit format. The most important file for code consistency. AI agents that skip this produce code that does not match the rest of the project.

**DECISIONS.md** — A log of why things are the way they are. If an AI suggests changing the architecture or switching databases, it should read this file first.

**TASKS.md** — A three-section task list: Current Sprint, Up Next, Backlog. AI agents check this at the start of every session to know what to work on.

**PROGRESS.md** — A timestamped log of every session. Each entry records which tool was used, what was done, which files changed, blockers, and what the next session should start with. This is the primary handoff mechanism between tools and between days.

---

## Git and the memory files

Commit `ARCHITECTURE.md`, `TECH_STACK.md`, `CONVENTIONS.md`, and `DECISIONS.md` to git. These describe the project and are useful to anyone who clones the repo.

`PROGRESS.md` and `TASKS.md` are more like a working notepad. The `.gitignore` created by `setup-context.sh` includes a commented-out line for `PROGRESS.md` so you can decide either way.

---

## Troubleshooting

**AI ignored the memory files and started fresh**
Check that the root config file exists. If it does, open it and confirm it still has the instruction to read `.ai-context/`. Some tools reset config files during updates.

**Stack detection got it wrong**
Open `.ai-context/TECH_STACK.md` and correct the values manually. This is expected for unusual setups — the detection is a starting point, not a guarantee.

**PROGRESS.md has wrong or incomplete entries**
Run `./update-context.sh` and choose option 4.

**A new developer joined and needs context**
Point them to `.ai-context/ARCHITECTURE.md` and `DECISIONS.md`. These two files explain what the project is and why it is built the way it is.

**OpenCode or Aider is not picking up context**
Make sure you are running them from the project root, not a subfolder. Run `pwd` to confirm before starting any AI tool.

---

## Recommended daily workflow

```
Start of day
  → read PROGRESS.md to see where things left off
  → read TASKS.md to confirm today's priority
  → open any AI tool — it reads the same files automatically

During the day
  → work normally across any combination of tools
  → if you make a decision yourself, run update-context.sh → option 3

End of day
  → AI writes its PROGRESS.md entry automatically at session end
  → if it crashed or timed out, run update-context.sh → option 1
  → commit .ai-context/ if you track it in git
```

---

*Built for zero-cost multi-AI development using Antigravity, Claude Code, OpenCode, Gemini CLI, and Aider.*
