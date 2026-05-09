#!/bin/bash
# =============================================================
# setup-context.sh
#
# USAGE:
#   /your-project/
#   └── engram/          ← git clone lands here
#       └── setup-context.sh
#
#   cd your-project/engram
#   ./setup-context.sh
#
# All files are created in the PARENT directory (your-project/).
# The engram/ folder self-deletes when setup is complete.
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

# -------------------------------------------------------
# TARGET = parent directory of wherever this script lives
# -------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET="$(dirname "$SCRIPT_DIR")"
TARGET_NAME="$(basename "$TARGET")"

echo -e "${BLUE}"
echo "================================================"
echo "   engram — AI Memory Setup"
echo "================================================"
echo -e "${NC}"
echo "Target directory: $TARGET"
echo ""

# -------------------------------------------------------
# STEP 1 — Detect mode
# -------------------------------------------------------

HAS_CODE=false
HAS_CONTEXT=false
PROJECT_MODE="new"

[ -d "$TARGET/.ai-context" ] && HAS_CONTEXT=true

CODE_FILES=$(find "$TARGET" -maxdepth 3 \
  -not -path "$TARGET/.git/*" \
  -not -path "$TARGET/.ai-context/*" \
  -not -path "$TARGET/node_modules/*" \
  -not -path "$TARGET/.venv/*" \
  -not -path "$TARGET/venv/*" \
  -not -path "$SCRIPT_DIR/*" \
  \( -name "*.py" -o -name "*.js" -o -name "*.ts" -o -name "*.jsx" -o -name "*.tsx" \
     -o -name "*.go" -o -name "*.rs" -o -name "*.java" -o -name "*.php" \
     -o -name "*.rb" -o -name "*.cs" -o -name "*.cpp" -o -name "*.c" \
     -o -name "package.json" -o -name "requirements.txt" -o -name "Cargo.toml" \
     -o -name "go.mod" -o -name "pom.xml" -o -name "Gemfile" \) \
  2>/dev/null | head -5)

[ -n "$CODE_FILES" ] && HAS_CODE=true

if $HAS_CONTEXT; then
  echo -e "${YELLOW}⚠ .ai-context/ already exists in $TARGET_NAME/.${NC}"
  echo ""
  echo "  1) Add missing files only — safe, keeps existing memory"
  echo "  2) Full reset — overwrites everything"
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
  echo -e "${CYAN}Existing project detected in $TARGET_NAME/.${NC}"
  echo "Running in EXISTING PROJECT mode — scanning codebase."
  echo ""
  PROJECT_MODE="existing"
else
  echo -e "${CYAN}Empty project directory — running in NEW PROJECT mode.${NC}"
  echo ""
  PROJECT_MODE="new"
fi

# -------------------------------------------------------
# STEP 2 — Project info
# -------------------------------------------------------

read -p "Project name: " PROJECT_NAME
read -p "Short description (one line): " PROJECT_DESC
read -p "Your name or team name: " AUTHOR

# -------------------------------------------------------
# STEP 3 — Auto-detect stack
# -------------------------------------------------------

LANG=""
FRAMEWORKS=""
DATABASE=""
DETECTED_STACK_NOTE=""
FOLDER_STRUCTURE=""

if [ "$PROJECT_MODE" = "existing" ] || [ "$PROJECT_MODE" = "merge" ] || [ "$PROJECT_MODE" = "reset" ]; then
  echo ""
  echo -e "${YELLOW}Scanning $TARGET_NAME/...${NC}"

  count_files() {
    find "$TARGET" -name "$1" \
      -not -path "$TARGET/.git/*" \
      -not -path "$TARGET/node_modules/*" \
      -not -path "$TARGET/.venv/*" \
      -not -path "$TARGET/venv/*" \
      -not -path "$SCRIPT_DIR/*" \
      2>/dev/null | wc -l | tr -d ' '
  }

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

  FW=""
  if [ -f "$TARGET/package.json" ]; then
    PKG=$(cat "$TARGET/package.json")
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
  for REQ in "$TARGET/requirements.txt" "$TARGET/pyproject.toml" "$TARGET/setup.py"; do
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
  [ -f "$TARGET/Cargo.toml" ] && {
    grep -qi "actix" "$TARGET/Cargo.toml" && FW="$FW Actix,"
    grep -qi "axum"  "$TARGET/Cargo.toml" && FW="$FW Axum,"
    grep -qi "tokio" "$TARGET/Cargo.toml" && FW="$FW Tokio,"
  }
  [ -f "$TARGET/go.mod" ] && {
    grep -qi "gin"   "$TARGET/go.mod" && FW="$FW Gin,"
    grep -qi "echo"  "$TARGET/go.mod" && FW="$FW Echo,"
    grep -qi "fiber" "$TARGET/go.mod" && FW="$FW Fiber,"
  }
  FRAMEWORKS=$(echo "$FW" | sed 's/^ //;s/,$//' | sed 's/,/, /g')
  [ -z "$FRAMEWORKS" ] && FRAMEWORKS="(not detected — fill in manually)"

  DB=""
  ALL_CFG=$(find "$TARGET" -maxdepth 4 \
    -not -path "$TARGET/.git/*" \
    -not -path "$TARGET/node_modules/*" \
    -not -path "$SCRIPT_DIR/*" \
    \( -name ".env" -o -name ".env*" -o -name "docker-compose*" \
       -o -name "*.yaml" -o -name "*.yml" -o -name "*.toml" \
       -o -name "requirements.txt" -o -name "package.json" \) \
    2>/dev/null | xargs cat 2>/dev/null || true)
  echo "$ALL_CFG" | grep -qi "postgresql\|postgres" && DB="$DB PostgreSQL,"
  echo "$ALL_CFG" | grep -qi "mysql\|mariadb"       && DB="$DB MySQL,"
  echo "$ALL_CFG" | grep -qi "mongodb\|mongoose"    && DB="$DB MongoDB,"
  echo "$ALL_CFG" | grep -qi "redis"                && DB="$DB Redis,"
  echo "$ALL_CFG" | grep -qi "sqlite"               && DB="$DB SQLite,"
  echo "$ALL_CFG" | grep -qi "supabase"             && DB="$DB Supabase,"
  echo "$ALL_CFG" | grep -qi "firebase"             && DB="$DB Firebase,"
  echo "$ALL_CFG" | grep -qi "dynamodb"             && DB="$DB DynamoDB,"
  DATABASE=$(echo "$DB" | sed 's/^ //;s/,$//' | sed 's/,/, /g')
  [ -z "$DATABASE" ] && DATABASE="(not detected — fill in manually)"

  echo -e "${GREEN}  Language:   $LANG${NC}"
  echo -e "${GREEN}  Frameworks: $FRAMEWORKS${NC}"
  echo -e "${GREEN}  Database:   $DATABASE${NC}"

  DETECTED_STACK_NOTE="Auto-detected by engram/setup-context.sh on $TODAY. Verify and correct if needed."

  FOLDER_STRUCTURE=$(find "$TARGET" -maxdepth 3 \
    -not -path "$TARGET/.git/*" \
    -not -path "$TARGET/node_modules/*" \
    -not -path "$TARGET/.venv/*" \
    -not -path "$TARGET/venv/*" \
    -not -path "$TARGET/.ai-context/*" \
    -not -path "$SCRIPT_DIR/*" \
    -not -name "*.pyc" \
    -not -name ".DS_Store" \
    2>/dev/null | sort | head -60 | sed "s|$TARGET/||" | sed "s|$TARGET||")

else
  read -p "Primary language (e.g. Python, TypeScript): " LANG
  read -p "Frameworks/libraries (e.g. FastAPI, React): " FRAMEWORKS
  read -p "Database (e.g. PostgreSQL, MongoDB, none): " DATABASE
  FOLDER_STRUCTURE="(project not yet created)"
  DETECTED_STACK_NOTE="Entered manually at project creation."
fi

# -------------------------------------------------------
# STEP 4 — Write all files into TARGET (parent directory)
# -------------------------------------------------------

echo ""
echo -e "${YELLOW}Writing memory files to $TARGET_NAME/...${NC}"
mkdir -p "$TARGET/.ai-context"

write_file() {
  local FPATH="$1"
  local BODY="$2"
  if [ "$PROJECT_MODE" = "merge" ] && [ -f "$FPATH" ]; then
    echo -e "${CYAN}  skipped (exists): $(basename $FPATH)${NC}"
  else
    printf '%s\n' "$BODY" > "$FPATH"
    echo -e "${GREEN}  written: $(basename $(dirname $FPATH))/$(basename $FPATH)${NC}"
  fi
}

write_file "$TARGET/.ai-context/ARCHITECTURE.md" "# Architecture — $PROJECT_NAME

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

write_file "$TARGET/.ai-context/TECH_STACK.md" "# Tech Stack — $PROJECT_NAME

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

write_file "$TARGET/.ai-context/CONVENTIONS.md" "# Code Conventions — $PROJECT_NAME

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

write_file "$TARGET/.ai-context/DECISIONS.md" "# Decisions Log — $PROJECT_NAME

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

write_file "$TARGET/.ai-context/TASKS.md" "# Tasks — $PROJECT_NAME

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
- Set up AI memory structure via engram
- Tech stack: $LANG / $FRAMEWORKS / $DATABASE
- No code written yet"
fi

write_file "$TARGET/.ai-context/PROGRESS.md" "# Progress Log — $PROJECT_NAME

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

write_file "$TARGET/AGENTS.md" "# $PROJECT_NAME — Agent Rules

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

write_file "$TARGET/CLAUDE.md" "# $PROJECT_NAME — Claude Code Rules

## On startup
Read all files in .ai-context/ before doing any work.
Summarize what TASKS.md says is active right now.

## On session end
Append to .ai-context/PROGRESS.md before stopping.
Format: ## YYYY-MM-DD HH:MM — Claude Code session

## Conventions
Follow CONVENTIONS.md strictly."

write_file "$TARGET/GEMINI.md" "# $PROJECT_NAME — Gemini CLI Rules

## On startup
Read all files in .ai-context/ before doing any work.

## On session end
Append to .ai-context/PROGRESS.md before stopping.
Format: ## YYYY-MM-DD HH:MM — Gemini CLI session

## Conventions
Follow CONVENTIONS.md strictly."

write_file "$TARGET/KILO.md" "# $PROJECT_NAME — Kilo Code Rules

## On startup
Read all files in .ai-context/ before doing any work.
Start by checking what TASKS.md says is active right now.

## On session end
Append to .ai-context/PROGRESS.md before stopping.
Format: ## YYYY-MM-DD HH:MM — Kilo Code session

## Conventions
Follow CONVENTIONS.md strictly.

## Kilo-specific
Kilo Code uses .kilocode/skills/ folder for custom extensions.
Store project-specific skills there but always read .ai-context/
for the source of truth about project memory."

# .gitignore in target
if [ -f "$TARGET/.gitignore" ]; then
  grep -q "ai-context" "$TARGET/.gitignore" 2>/dev/null || \
    printf "\n# AI memory logs\n# .ai-context/PROGRESS.md\n" >> "$TARGET/.gitignore"
else
  printf "# AI memory logs\n# .ai-context/PROGRESS.md\n" > "$TARGET/.gitignore"
fi
echo -e "${GREEN}  written: .gitignore${NC}"

# Also copy update-context.sh to target so it's available in the project
if [ -f "$SCRIPT_DIR/update-context.sh" ]; then
  cp "$SCRIPT_DIR/update-context.sh" "$TARGET/update-context.sh"
  chmod +x "$TARGET/update-context.sh"
  echo -e "${GREEN}  copied:  update-context.sh${NC}"
fi

# -------------------------------------------------------
# STEP 5 — Self-delete engram directory
# -------------------------------------------------------

echo ""
echo -e "${YELLOW}Removing engram/ setup directory...${NC}"
cd "$TARGET"
rm -rf "$SCRIPT_DIR"
echo -e "${GREEN}  removed: engram/${NC}"

# -------------------------------------------------------
# STEP 6 — Summary
# -------------------------------------------------------

echo ""
echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}   Done — $PROJECT_NAME${NC}"
echo -e "${GREEN}   All files created in: $TARGET_NAME/${NC}"
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
echo -e "${CYAN}Supported AI tools — all read your .ai-context/ folder:${NC}"
echo "  • Antigravity (AGENTS.md)"
echo "  • Claude Code (CLAUDE.md)"
echo "  • Gemini CLI (GEMINI.md)"
echo "  • Kilo Code (KILO.md)"
echo "  • OpenCode (AGENTS.md)"
echo "  • Aider (pass --read .ai-context/TASKS.md)"
echo ""
echo "Then open any tool — context loads automatically."
echo "To manually update memory later: ./update-context.sh"
echo ""
