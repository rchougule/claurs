#!/usr/bin/env bash
set -euo pipefail

CLAURS_DIR="$(cd "$(dirname "$0")" && pwd)"
GLOBAL_COMMANDS_DIR="$HOME/.claude/commands"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

usage() {
    echo -e "${BOLD}claurs${NC} — Claude Code skills installer"
    echo ""
    echo "Usage:"
    echo "  ./setup.sh install [category]    Install skills (globally or by category)"
    echo "  ./setup.sh install finance       Install only finance skills"
    echo "  ./setup.sh list                  List available skill categories"
    echo "  ./setup.sh uninstall [category]  Remove installed skill symlinks"
    echo "  ./setup.sh status                Show which skills are installed"
    echo ""
    echo "Skills are symlinked to ~/.claude/commands/ so they work in any project."
    echo "Run 'git pull && ./setup.sh install' after updates to get new skills."
}

list_categories() {
    echo -e "${BOLD}Available skill categories:${NC}"
    echo ""
    for dir in "$CLAURS_DIR"/skills/*/; do
        [ -d "$dir" ] || continue
        category=$(basename "$dir")
        count=$(find "$dir" -name "*.md" -maxdepth 1 | wc -l | tr -d ' ')
        echo -e "  ${GREEN}$category${NC} ($count skills)"
        for skill in "$dir"*.md; do
            [ -f "$skill" ] || continue
            name=$(basename "$skill" .md)
            desc=$(head -1 "$skill" | sed 's/^#* *//')
            echo "    /$name — $desc"
        done
        echo ""
    done
}

install_skills() {
    local category="${1:-all}"

    mkdir -p "$GLOBAL_COMMANDS_DIR"

    local installed=0
    local skipped=0

    if [ "$category" = "all" ]; then
        dirs=("$CLAURS_DIR"/skills/*/)
    else
        if [ ! -d "$CLAURS_DIR/skills/$category" ]; then
            echo -e "${RED}Category '$category' not found.${NC}"
            echo "Run './setup.sh list' to see available categories."
            exit 1
        fi
        dirs=("$CLAURS_DIR/skills/$category/")
    fi

    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || continue
        cat_name=$(basename "$dir")
        echo -e "${BOLD}Installing: $cat_name${NC}"

        for skill in "$dir"*.md; do
            [ -f "$skill" ] || continue
            name=$(basename "$skill")
            target="$GLOBAL_COMMANDS_DIR/$name"

            if [ -L "$target" ]; then
                current=$(readlink "$target")
                if [ "$current" = "$skill" ]; then
                    echo -e "  ${YELLOW}skip${NC}  /$( basename "$name" .md) (already linked)"
                    skipped=$((skipped + 1))
                    continue
                else
                    echo -e "  ${YELLOW}update${NC}  /$( basename "$name" .md) (repointing symlink)"
                    rm "$target"
                fi
            elif [ -f "$target" ]; then
                echo -e "  ${YELLOW}backup${NC}  /$( basename "$name" .md) (existing file moved to $name.bak)"
                mv "$target" "$target.bak"
            fi

            ln -s "$skill" "$target"
            echo -e "  ${GREEN}done${NC}  /$( basename "$name" .md)"
            installed=$((installed + 1))
        done
    done

    echo ""
    echo -e "${GREEN}Installed: $installed${NC}, Skipped: $skipped"
    echo ""
    echo "Skills are now available globally in Claude Code. Try: /financial-plan"
}

uninstall_skills() {
    local category="${1:-all}"

    if [ "$category" = "all" ]; then
        dirs=("$CLAURS_DIR"/skills/*/)
    else
        dirs=("$CLAURS_DIR/skills/$category/")
    fi

    local removed=0

    for dir in "${dirs[@]}"; do
        [ -d "$dir" ] || continue
        for skill in "$dir"*.md; do
            [ -f "$skill" ] || continue
            name=$(basename "$skill")
            target="$GLOBAL_COMMANDS_DIR/$name"

            if [ -L "$target" ]; then
                current=$(readlink "$target")
                if [ "$current" = "$skill" ]; then
                    rm "$target"
                    echo -e "  ${RED}removed${NC}  /$(basename "$name" .md)"
                    removed=$((removed + 1))
                fi
            fi
        done
    done

    echo ""
    echo -e "Removed: $removed"
}

status() {
    echo -e "${BOLD}Installed claurs skills:${NC}"
    echo ""

    local found=0
    for target in "$GLOBAL_COMMANDS_DIR"/*.md; do
        [ -f "$target" ] || continue
        if [ -L "$target" ]; then
            source=$(readlink "$target")
            if [[ "$source" == "$CLAURS_DIR"* ]]; then
                name=$(basename "$target" .md)
                category=$(echo "$source" | sed "s|$CLAURS_DIR/skills/||" | cut -d'/' -f1)
                echo -e "  ${GREEN}/$name${NC} ($category)"
                found=$((found + 1))
            fi
        fi
    done

    if [ "$found" -eq 0 ]; then
        echo "  (none)"
        echo ""
        echo "Run './setup.sh install' to install skills."
    fi
}

case "${1:-}" in
    install)  install_skills "${2:-all}" ;;
    list)     list_categories ;;
    uninstall) uninstall_skills "${2:-all}" ;;
    status)   status ;;
    *)        usage ;;
esac
