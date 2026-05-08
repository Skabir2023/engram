#!/bin/bash
# =============================================================
# update-context.sh
# Run this manually only when AI tools CANNOT update memory
# themselves. See the menu for specific situations.
# =============================================================

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

TODAY=$(date '+%Y-%m-%d')
NOW=$(date '+%Y-%m-%d %H:%M')

# Guard: must be run inside a project with .ai-context/
if [ ! -d ".ai-context" ]; then
  echo -e "${RED}Error: .ai-context/ not found.${NC}"
  echo "Run setup-context.sh first, or move to your project root."
  exit 1
fi

echo -e "${BLUE}"
echo "================================"
echo "   AI Memory — Manual Update"
echo "================================"
echo -e "${NC}"

echo "What do you want to update?"
echo ""
echo "  1) Log a completed session manually"
echo "     (use when AI crashed, timed out, or forgot to update)"
echo ""
echo "  2) Add a task to TASKS.md"
echo "     (use when you think of a task outside an AI session)"
echo ""
echo "  3) Log a decision to DECISIONS.md"
echo "     (use when YOU made a decision without an AI session)"
echo ""
echo "  4) Fix or overwrite the last PROGRESS.md entry"
echo "     (use when AI wrote something wrong or incomplete)"
echo ""
echo "  5) Update TASKS.md — mark a task done manually"
echo "     (use when you completed something without AI help)"
echo ""
echo "  6) Full review — show all memory files in terminal"
echo "     (use to audit what the AI knows before a new session)"
echo ""
echo "  7) Exit"
echo ""
read -p "Choose (1-7): " CHOICE

case $CHOICE in

  1)
    echo ""
    echo -e "${YELLOW}Manual session log — appending to PROGRESS.md${NC}"
    read -p "Which tool was used? (e.g. Claude Code, OpenCode, Aider): " TOOL
    read -p "What was done? (one or two lines): " DONE
    read -p "Files changed (comma separated, or 'none'): " FILES
    read -p "Any blockers? (or press Enter to skip): " BLOCKERS
    read -p "What should the next session start with?: " NEXT

    cat >> .ai-context/PROGRESS.md << EOF

## $NOW — $TOOL session (logged manually)
- Done: $DONE
- Files: $FILES
- Blockers: ${BLOCKERS:-none}
- Next: $NEXT
EOF
    echo -e "${GREEN}✓ Appended to PROGRESS.md${NC}"
    ;;

  2)
    echo ""
    echo -e "${YELLOW}Adding task to TASKS.md${NC}"
    echo "Which list?"
    echo "  1) Current Sprint"
    echo "  2) Up Next"
    echo "  3) Backlog"
    read -p "Choose (1-3): " LIST_CHOICE
    read -p "Task description: " TASK_DESC

    case $LIST_CHOICE in
      1) SECTION="Current Sprint" ;;
      2) SECTION="Up Next" ;;
      3) SECTION="Backlog" ;;
      *) SECTION="Backlog" ;;
    esac

    # Insert task under the correct section header
    sed -i "s/## 🔴 $SECTION/## 🔴 $SECTION\n- [ ] $TASK_DESC/" .ai-context/TASKS.md 2>/dev/null \
    || sed -i "s/## 🟡 $SECTION/## 🟡 $SECTION\n- [ ] $TASK_DESC/" .ai-context/TASKS.md 2>/dev/null \
    || sed -i "s/## 🟢 $SECTION/## 🟢 $SECTION\n- [ ] $TASK_DESC/" .ai-context/TASKS.md 2>/dev/null \
    || echo "- [ ] $TASK_DESC" >> .ai-context/TASKS.md

    echo -e "${GREEN}✓ Task added to TASKS.md under $SECTION${NC}"
    ;;

  3)
    echo ""
    echo -e "${YELLOW}Logging a decision to DECISIONS.md${NC}"
    read -p "Decision title (short): " DEC_TITLE
    read -p "What was decided?: " DEC_WHAT
    read -p "Why? (alternatives considered): " DEC_WHY
    read -p "Trade-offs accepted: " DEC_TRADEOFF

    cat >> .ai-context/DECISIONS.md << EOF

## $TODAY — $DEC_TITLE
- Decision: $DEC_WHAT
- Reason: $DEC_WHY
- Trade-offs: $DEC_TRADEOFF
EOF
    echo -e "${GREEN}✓ Decision appended to DECISIONS.md${NC}"
    ;;

  4)
    echo ""
    echo -e "${YELLOW}Last 20 lines of PROGRESS.md:${NC}"
    echo "---"
    tail -20 .ai-context/PROGRESS.md
    echo "---"
    echo ""
    echo "Open PROGRESS.md in your editor to fix the last entry."
    echo "Command: code .ai-context/PROGRESS.md"
    echo "         (or use any editor you prefer)"
    ;;

  5)
    echo ""
    echo -e "${YELLOW}Current open tasks in TASKS.md:${NC}"
    echo "---"
    grep -n "\- \[ \]" .ai-context/TASKS.md || echo "(no open tasks found)"
    echo "---"
    echo ""
    read -p "Enter the task description to mark as done (copy exactly): " TASK_MATCH
    sed -i "s/- \[ \] $TASK_MATCH/- [x] $TASK_MATCH/" .ai-context/TASKS.md
    echo -e "${GREEN}✓ Task marked done in TASKS.md${NC}"
    ;;

  6)
    echo ""
    echo -e "${BLUE}=== TASKS.md ===${NC}"
    cat .ai-context/TASKS.md
    echo ""
    echo -e "${BLUE}=== Last 30 lines of PROGRESS.md ===${NC}"
    tail -30 .ai-context/PROGRESS.md
    echo ""
    echo -e "${BLUE}=== DECISIONS.md ===${NC}"
    cat .ai-context/DECISIONS.md
    ;;

  7)
    echo "Exited."
    exit 0
    ;;

  *)
    echo -e "${RED}Invalid choice.${NC}"
    exit 1
    ;;

esac

echo ""
echo "Done. Your AI memory is up to date."
echo ""
