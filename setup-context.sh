#!/bin/bash
# =============================================================
# setup-context.sh
# Works for both NEW and EXISTING projects.
# - New project      → creates all files with your input
# - Existing project → scans codebase, auto-detects stack,
#                      pre-fills memory files from real code
# - Already has .ai-context/ → merge (add missing) or reset
# =============================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

TODAY=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M')

echo -e "${BLUE}"
echo "================================================"
echo "   AI Memory Setup"
echo "================================================"
echo -e "${NC}"

# -------------------------------------------------------
# STEP 1 — Detect: new / existing / already has memory
# -------------------------------------------------------

HAS_CODE=false
HAS_CONTEXT=false
PROJECT_MODE="new"

if [ -d ".ai-context" ]; then
  HAS_CONTEXT=true
fi

CODE_FILES=$(find . -maxdepth 3 \
  -not -path './.git/*' \
  -not -path './.ai-context/*' \
  -not -path './node_modules/*' \
  -not -path './.venv/*' \
  -not -path './venv/*' \
  \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \
     -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.php" \
     -o -name "*.rb" -o -name "*.cs" -o -name "*.cpp" -o -name "*.c" \
     -o -name "package.json" -o -name "requirements.txt" -o -name "Cargo.toml" \
     -o -name "go.mod" -o -name "pom.xml" -o -name "Gemfile" \) \
  2>/dev/null | head -5)

[ -n "$CODE_FILES" ] && HAS_CODE=true

if $HAS_CONTEXT; then
  echo -e "${YELLOW}⚠ .ai-context/ already exists in this directory.${NC}"
  echo ""
  echo "  1) Add missing files only — safe, keeps existing memory"
  echo "  2) Full reset — overwrites everything (loses existing memory)"
  echo "  3) Exit"
  echo ""
  read -p "Choose (1-3): " EXIST_CHOICE
  case $EXIST_CHOICE in
    1) PROJECT_MODE="merge" ;;
    2) PROJECT_MODE="reset" ;;
    3) echo "Exited."; exit 0 ;;
    *) echo -e "${RED}Invalid choice.${NC}"; exit 1 ;;
  esac
elif $HAS_CODE; then
  echo -e "${CYAN}Existing project detected — source files found.${NC}"
  echo "Running in EXISTING PROJECT mode: codebase will be scanned"
  echo "and memory files pre-filled automatically."
  echo ""
  PROJECT_MODE="existing"
else
  echo -e "${CYAN}Empty directory — running in NEW PROJECT mode.${NC}"
  echo ""
  PROJECT_MODE="new"
fi

# -------------------------------------------------------
# STEP 2 — Collect project info
# -------------------------------------------------------

read -p "Project name: " PROJECT_NAME
read -p "Short description (one line): " PROJECT_DESC
read -p "Your name or team name: " AUTHOR

# -------------------------------------------------------
# STEP 3 — Auto-detect stack (existing / merge modes)
# -------------------------------------------------------

LANG=""
FRAMEWORKS=""
DATABASE=""
DETECTED_STACK_NOTE=""
FOLDER_STRUCTURE=""

if [ "$PROJECT_MODE" = "existing" ] || [ "$PROJECT_MODE" = "merge" ] || [ "$PROJECT_MODE" = "reset" ]; then
  echo ""
  echo -e "${YELLOW}Scanning codebase...${NC}"

  # Detect primary language by file count
  count_files() { find . -name "$1" -not -path './.git/*' -not -path './node_modules/*' -not -path './.venv/*' -not -path './venv/*' 2>/dev/null | wc -l | tr -d ' '; }

  PY=$(count_files "*.py")
  TS=$(( $(count_files "*.ts") + $(count_files "*.tsx") ))
  JS=$(( $(count_files "*.js") + $(count_files "*.jsx") ))
  GO=$(count_files "*.go")
  RS=$(count_files "*.rs")
  RB=$(count_files "*.rb")
  JV=$(count_files "*.java")

  LANG="Python"; MAX=$PY
  [ "$TS" -gt "$MAX" ] 2>/dev/null && MAX=$TS && LANG="TypeScript"
  [ "$JS" -gt "$MAX" ] 2>/dev/null && MAX=$JS && LANG="JavaScript"
  [ "$GO" -gt "$MAX" ] 2>/dev/null && MAX=$GO && LANG="Go"
  [ "$RS" -gt "$MAX" ] 2>/dev/null && MAX=$RS && LANG="Rust"
  [ "$RB" -gt "$MAX" ] 2>/dev/null && MAX=$RB && LANG="Ruby"
  [ "$JV" -gt "$MAX" ] 2>/dev/null && MAX=$JV && LANG="Java"
  [ "$MAX" -eq 0 ] && LANG="(not detected — fill in manually)"

  # Detect frameworks
  FW=""
  if [ -f "package.json" ]; then
    PKG=$(cat package.json)
    echo "$PKG" | grep -q '"next"'        && FW="$FW Next.js,"
    echo "$PKG" | grep -q '"react"'       && FW="$FW React,"
    echo "$PKG" | grep -q '"vue"'         && FW="$FW Vue,"
    echo "$PKG" | grep -q '"svelte"'      && FW="$FW Svelte,"
    echo "$PKG" | grep -q '"express"'     && FW="$FW Express,"
    echo "$PKG" | grep -q '"fastify"'     && FW="$FW Fastify,"
    echo "$PKG" | grep -q '"@nestjs"'     && FW="$FW NestJS,"
    echo "$PKG" | grep -q '"nuxt"'        && FW="$FW Nuxt,"
    echo "$PKG" | grep -q '"tailwindcss"' && FW="$FW Tailwind CSS,"
    echo "$PKG" | grep -q '"prisma"'      && FW="$FW Prisma,"
    echo "$PKG" | grep -q '"drizzle"'     && FW="$FW Drizzle ORM,"
    echo "$PKG" | grep -q '"trpc"'        && FW="$FW tRPC,"
  fi
  for REQ in requirements.txt pyproject.toml setup.py; do
    if [ -f "$REQ" ]; then
      grep -qi "fastapi"    "$REQ" 2>/dev/null && FW="$FW FastAPI,"
      grep -qi "django"     "$REQ" 2>/dev/null && FW="$FW Django,"
      grep -qi "flask"      "$REQ" 2>/dev/null && FW="$FW Flask,"
      grep -qi "sqlalchemy" "$REQ" 2>/dev/null && FW="$FW SQLAlchemy,"
      grep -qi "pydantic"   "$REQ" 2>/dev/null && FW="$FW Pydantic,"
      grep -qi "celery"     "$REQ" 2>/dev/null && FW="$FW Celery,"
      grep -qi "pytest"     "$REQ" 2>/dev/null && FW="$FW pytest,"
    fi
  done
  if [ -f "Cargo.toml" ]; then
    grep -qi "actix" Cargo.toml && FW="$FW Actix,"
    grep -qi "axum"  Cargo.toml && FW="$FW Axum,"
    grep -qi "tokio" Cargo.toml && FW="$FW Tokio,"
  fi
  if [ -f "go.mod" ]; then
    grep -qi "gin"   go.mod && FW="$FW Gin,"
    grep -qi "echo"  go.mod && FW="$FW Echo,"
    grep -qi "fiber" go.mod && FW="$FW Fiber,"
  fi
  FRAMEWORKS=$(echo "$FW" | sed 's/^ //;s/,$//' | tr ',' ',' | sed 's/,/, /g')
  [ -z "$FRAMEWORKS" ] && FRAMEWORKS="(not detected — fill in manually)"

  # Detect database
  DB=""
  ALL_CFG=$(find . -maxdepth 4 -not -path './.git/*' -not -path './node_modules/*' \
    \( -name ".env" -o -name ".env*" -o -name "docker-compose*" -o -name "*.yaml" \
       -o -name "*.yml" -o -name "*.toml" -o -name "requirements.txt" -o -name "package.json" \) \
    2>/dev/null | xargs cat 2>/dev/null || true)
  echo "$ALL_CFG" | grep -qi "postgresql\|postgres" && DB="$DB PostgreSQL,"
  echo "$ALL_CFG" | grep -qi "mysql\|mariadb"       && DB="$DB MySQL,"
  echo "$ALL_CFG" | grep -qi "mongodb\|mongoose"    && DB="$DB MongoDB,"
  echo "$ALL_CFG" | grep -qi "redis"                && DB="$DB Redis,"
  echo "$ALL_CFG" | grep -qi "sqlite"               && DB="$DB SQLite,"
  echo "$ALL_CFG" | grep -qi "supabase"             && DB="$DB Supabase,"
  echo "$ALL_CFG" | grep -qi "firebase"             && DB="$DB Firebase,"
  echo "$ALL_CFG" | grep -qi "dynamodb"             && DB="$DB DynamoDB,"
  DATABASE=$(echo "$DB" | sed 's/^ //;s/,$//' | tr ',' ',' | sed 's/,/, /g')
  [ -z "$DATABASE" ] && DATABASE="(not detected — fill in manually)"

  echo -e "${GREEN}  Language:   $LANG${NC}"
  echo -e "${GREEN}  Frameworks: $FRAMEWORKS${NC}"
  echo -e "${GREEN}  Database:   $DATABASE${NC}"

  DETECTED_STACK_NOTE="Auto-detected by setup-context.sh on $TODAY. Verify and correct if needed."

  # Capture folder structure
  FOLDER_STRUCTURE=$(find . -maxdepth 3 \
    -not -path './.git/*' -not -path './node_modules/*' \
    -not -path './.venv/*' -not -path './venv/*' \
    -not -path './.ai-context/*' \
    -not -name "*.pyc" -not -name ".DS_Store" \
    2>/dev/null | sort | head -60 | sed 's|^\./||')

else
  # New project — manual input
  read -p "Primary language (e.g. Python, TypeScript): " LANG
  read -p "Frameworks/libraries (e.g. FastAPI, React): " FRAMEWORKS
  read -p "Database (e.g. PostgreSQL, MongoDB, none): " DATABASE
  FOLDER_STRUCTURE="(project not yet created)"
  DETECTED_STACK_NOTE="Entered manually at project creation."
fi

# -------------------------------------------------------
# STEP 4 — Write files
# -------------------------------------------------------

echo ""
echo -e "${YELLOW}Writing memory files...${NC}"
mkdir -p .ai-context

# Only write if file does not exist in merge mode
write_file() {
  local PATH="$1"
  local BODY="$2"
  if [ "$PROJECT_MODE" = "merge" ] && [ -f "$PATH" ]; then
    echo -e "${CYAN}  skipped (exists): $PATH${NC}"
  else
    printf '%s\n' "$BODY" > "$PATH"
    echo -e "${GREEN}  written: $PATH${NC}"
  fi
}

write_file ".ai-context/ARCHITECTURE.md" "# Architecture — $PROJECT_NAME

**Created:** $TODAY
**Author:** $AUTHOR

## Overview
$PROJECT_DESC

## Folder Structure
\`\`\`
$FOLDER_STRUCTURE
\`\`\`

## System Design
<!-- Describe main components, services, how they connect -->

## Data Flow
<!-- How does data move through the system? -->

## Key Design Choices
<!-- Why is the project structured this way? -->"

write_file ".ai-context/TECH_STACK.md" "# Tech Stack — $PROJECT_NAME

**Created:** $TODAY
**Note:** $DETECTED_STACK_NOTE

## Language
$LANG

## Frameworks & Libraries
$FRAMEWORKS

## Database
$DATABASE

## Dev Tools
- Version control: Git
- AI tools: Antigravity, Claude Code, OpenCode, Aider

## Environment Setup
\`\`\`bash
# Add setup commands here as you build
\`\`\`"

write_file ".ai-context/CONVENTIONS.md" "# Code Conventions — $PROJECT_NAME

**Created:** $TODAY

## Naming Rules
- Variables: (fill in — e.g. snake_case / camelCase)
- Files: (fill in)
- Components: (fill in)

## Folder Rules
- (describe where new files should go)

## Git Commit Style
- Use present tense: \"add feature\" not \"added feature\"
- Format: type(scope): message
- Types: feat, fix, refactor, docs, test, chore

## What AI Agents Must Follow
- Always match the naming rules above
- Never create files outside the defined folder structure
- Add comments for any non-obvious logic
- Do not remove existing comments without reason"

write_file ".ai-context/DECISIONS.md" "# Decisions Log — $PROJECT_NAME

**Created:** $TODAY

This file records WHY choices were made.
AI agents must read this before suggesting architectural changes.

---

## $TODAY — Project memory initialized
- Language: $LANG
- Frameworks: $FRAMEWORKS
- Database: $DATABASE
- Reason: (fill in your reasoning)

---
<!-- Format for new entries:
## YYYY-MM-DD — Decision title
- What was decided
- Why (alternatives considered)
- Trade-offs accepted
-->"

write_file ".ai-context/TASKS.md" "# Tasks — $PROJECT_NAME

**Created:** $TODAY
**Update this file at the start of every session.**

---

## 🔴 Current Sprint (active right now)
- [ ] (add your first task)

## 🟡 Up Next
- [ ] (planned but not started)

## 🟢 Backlog
- [ ] (future ideas)

---

## Rules for AI agents
- Read this file before starting work
- Mark tasks as [x] when complete
- Add newly discovered tasks under Up Next
- Never remove tasks — mark them done instead"

if [ "$PROJECT_MODE" = "existing" ] || [ "$PROJECT_MODE" = "reset" ]; then
  FIRST_ENTRY="## $NOW — AI memory initialized on existing project by $AUTHOR
- Scanned codebase: $LANG / $FRAMEWORKS / $DATABASE
- Folder structure captured in ARCHITECTURE.md
- No code was changed — memory layer added on top of existing project
- Next: fill in TASKS.md with current priorities and ARCHITECTURE.md with system design"
else
  FIRST_ENTRY="## $NOW — Project initialized by $AUTHOR
- Set up AI memory structure
- Tech stack: $LANG / $FRAMEWORKS / $DATABASE
- No code written yet"
fi

write_file ".ai-context/PROGRESS.md" "# Progress Log — $PROJECT_NAME

**Created:** $TODAY

AI agents MUST append to this file at the end of every session.

---

$FIRST_ENTRY

---
<!-- AI agents: append entries below in this format:
## YYYY-MM-DD HH:MM — [Tool] session
- What was done
- Files created or modified
- Blockers
- What to do next
-->"

# Root config files
write_file "AGENTS.md" "# $PROJECT_NAME — Agent Rules

## Memory — read first, always
Before doing anything read ALL files in .ai-context/ in this order:
1. TECH_STACK.md
2. ARCHITECTURE.md
3. CONVENTIONS.md
4. DECISIONS.md
5. TASKS.md
6. PROGRESS.md

## Memory — write before ending session
- Append a new entry to .ai-context/PROGRESS.md
- Update .ai-context/TASKS.md (mark done, add discovered tasks)
- Append to .ai-context/DECISIONS.md if a decision was made

## Behavior rules
- Follow CONVENTIONS.md exactly
- Do not change tech stack without logging to DECISIONS.md
- Ask before deleting any file
- Run tests after every code change"

write_file "CLAUDE.md" "# $PROJECT_NAME — Claude Code Rules

## On startup
Read all files in .ai-context/ before doing any work.
Summarize what TASKS.md says is active right now.

## On session end
Append to .ai-context/PROGRESS.md before stopping.
Format: ## YYYY-MM-DD HH:MM — Claude Code session

## Conventions
Follow CONVENTIONS.md strictly."

write_file "GEMINI.md" "# $PROJECT_NAME — Gemini CLI Rules

## On startup
Read all files in .ai-context/ before doing any work.

## On session end
Append to .ai-context/PROGRESS.md before stopping.
Format: ## YYYY-MM-DD HH:MM — Gemini CLI session

## Conventions
Follow CONVENTIONS.md strictly."

# .gitignore
if [ -f .gitignore ]; then
  grep -q "ai-context" .gitignore 2>/dev/null || printf "\n# AI memory logs\n# .ai-context/PROGRESS.md\n" >> .gitignore
else
  printf "# AI memory logs\n# .ai-context/PROGRESS.md\n" > .gitignore
fi

# -------------------------------------------------------
# STEP 5 — Summary
# -------------------------------------------------------
echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Done — $PROJECT_NAME${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

if [ "$PROJECT_MODE" = "existing" ] || [ "$PROJECT_MODE" = "reset" ]; then
  echo "Detected stack:"
  echo "  Language:   $LANG"
  echo "  Frameworks: $FRAMEWORKS"
  echo "  Database:   $DATABASE"
  echo ""
  echo -e "${YELLOW}Two files need your attention before the first AI session:${NC}"
  echo "  1. .ai-context/ARCHITECTURE.md  — review folder structure, add system design"
  echo "  2. .ai-context/TASKS.md         — add what you are currently working on"
else
  echo -e "${YELLOW}Fill these in before your first AI session:${NC}"
  echo "  1. .ai-context/ARCHITECTURE.md  — describe your system design"
  echo "  2. .ai-context/TASKS.md         — add your first task"
fi

echo ""
echo "Then open Antigravity, Claude Code, or any tool — context loads automatically."
echo ""
