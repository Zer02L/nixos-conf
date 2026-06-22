# Git hooks — напоминание о Conventional Commits
#
# commit-msg хук проверяет формат коммита:
#   type(scope): description
#
# Типы: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert
#
# Если коммит не соответствует формату — выводится предупреждение (не блокирует).
# Чтобы заблокировать: замени exit 0 на exit 1 в конце хука.

{ config, pkgs, lib, ... }:

let
  commitMsgHook = pkgs.writeShellScript "commit-msg" ''
    # Цвета
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    # Читаем сообщение коммита
    MSG_FILE="$1"
    if [ ! -f "$MSG_FILE" ]; then
      echo -e "''${RED}commit-msg: file not found: $MSG_FILE''${NC}"
      exit 1
    fi

    MSG=$(head -n 1 "$MSG_FILE")

    # Пустое сообщение
    if [ -z "$MSG" ]; then
      echo -e "''${RED}commit-msg: empty commit message''${NC}"
      exit 1
    fi

    # Формат: type(scope): description
    PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_./-]+\))?: .+'

    if echo "$MSG" | grep -qE "$PATTERN"; then
      exit 0
    fi

    # Не соответствует — предупреждение
    echo ""
    echo -e "''${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
    echo -e "''${YELLOW}⚠  Non-conventional commit message''${NC}"
    echo -e "''${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
    echo ""
    echo "  Got:      $MSG"
    echo ""
    echo "  Expected: type(scope): description"
    echo ""
    echo "  Types:    feat | fix | docs | style | refactor | perf | test"
    echo "            build | ci | chore | revert"
    echo ""
    echo "  Examples:"
    echo "            feat(kwin-rules): add window rules for dev workflow"
    echo "            fix(ghostty): correct font size on HiDPI"
    echo "            docs: update KDE-DESKTOPS cheatsheet"
    echo "            chore: update flake inputs"
    echo ""
    echo -e "  ''${YELLOW}Commit proceeds anyway (warning only).''${NC}"
    echo -e "  ''${YELLOW}To enforce: change 'exit 0' to 'exit 1' in commit-msg hook.''${NC}"
    echo ""
    echo -e "''${YELLOW}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
    echo ""

    exit 0
  '';
in
{
  programs.git = {
    hooks = {
      commit-msg = commitMsgHook;
    };
  };
}
