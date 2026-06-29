# Git hooks
#
# 1. pre-commit — блокировка коммитов с секретами (блокирует)
# 2. commit-msg — напоминание о Conventional Commits (предупреждение)

{ config, pkgs, lib, ... }:

let
  # ═══════════════════════════════════════════════════════════════
  # Pre-commit: сканирование staged файлов на наличие секретов
  # ═══════════════════════════════════════════════════════════════

  # Файл с паттернами секретов (вынесен отдельно для читаемости)
  secretsPatternsFile = pkgs.writeText "secret-patterns" ''
    # Format: NAME<TAB>PATTERN
    # One pattern per line. Lines starting with # are comments.

    # === API Keys ===
    AWS Access Key	AKIA[0-9A-Z]{16}
    GitHub Token	gh[ps]_[A-Za-z0-9_]{36,255}
    GitHub Fine-grained	github_pat_[A-Za-z0-9_]{82}
    GitLab Token	glpat-[A-Za-z0-9\-_]{20,}
    OpenAI Key	sk-[A-Za-z0-9]{48}
    Anthropic Key	sk-ant-[A-Za-z0-9\-_]{40,}
    Google API	AIza[0-9A-Za-z\-_]{35}
    Slack Token	xox[baprs]-[A-Za-z0-9\-]{10,}
    Slack Webhook	https://hooks\.slack\.com/services/T[A-Z0-9]{8}/B[A-Z0-9]{8}/[a-zA-Z0-9]{24}
    Telegram Bot Token	[0-9]{9}:[A-Za-z0-9_-]{35}
    Discord Token	[MN][A-Za-z0-9]{23,}\.[A-Za-z0-9_-]{6}\.[A-Za-z0-9_-]{27,}
    Discord Webhook	https://discord(app)?\.com/api/webhooks/[0-9]+/[A-Za-z0-9\-_]+
    Exa API Key	exa-[A-Za-z0-9]{32,}
    Stripe Key	sk_live_[0-9a-zA-Z]{24,}
    Stripe Publishable	pk_live_[0-9a-zA-Z]{24,}
    Twilio Account SID	AC[0-9a-fA-F]{32}
    SendGrid Key	SG\.[A-Za-z0-9\-_]{22}\.[A-Za-z0-9\-_]{43}
    Mailgun Key	key-[0-9a-zA-Z]{32}
    npm Token	npm_[A-Za-z0-9]{36}

    # === Private Keys ===
    RSA Private Key	-----BEGIN RSA PRIVATE KEY-----
    DSA Private Key	-----BEGIN DSA PRIVATE KEY-----
    EC Private Key	-----BEGIN EC PRIVATE KEY-----
    OpenSSH Private Key	-----BEGIN OPENSSH PRIVATE KEY-----
    PGP Private Key	-----BEGIN PGP PRIVATE KEY BLOCK-----
    Generic Private Key	-----BEGIN PRIVATE KEY-----

    # === Passwords / Credentials ===
    Password Assignment	(?i)(password|passwd|pwd)\s*[:=]\s*['"][^'"]+['"]
    API Key Assignment	(?i)(api[_-]?key|apikey)\s*[:=]\s*['"][^'"]+['"]
    Secret Assignment	(?i)(secret|token)\s*[:=]\s*['"][^'"]+['"]
    ConnectionString	(?i)(connection[_-]?string|conn[_-]?str)\s*[:=]\s*['"][^'"]+['"]
    Bearer Token	Bearer\s+[A-Za-z0-9\-._~+/]+=*

    # === .env files ===
    ENV File	\.env$
    ENV Backup	\.env\.(backup|bak|old|local|example)$
  '';

  preCommitHook = pkgs.writeShellScript "pre-commit" ''
    set -euo pipefail

    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    PATTERNS_FILE="${secretsPatternsFile}"

    # Файлы-исключения
    EXCLUDE_DIRS=".git node_modules .direnv result"

    # Получаем список staged файлов
    STAGED_FILES=$(git diff --cached --name-only --diff-filter=ACMR 2>/dev/null || true)

    if [ -z "$STAGED_FILES" ]; then
      exit 0
    fi

    FOUND_SECRETS=0
    SECRET_REPORT=""

    while IFS= read -r file; do
      # Пропускаем бинарные
      if file --mime-type "$file" 2>/dev/null | grep -q "binary"; then
        continue
      fi

      # Пропускаем исключённые директории
      SKIP=false
      for dir in $EXCLUDE_DIRS; do
        case "$file" in
          "$dir"|"$dir"/*) SKIP=true; break ;;
        esac
      done
      $SKIP && continue

      # Получаем staged содержимое
      CONTENT=$(git show ":$file" 2>/dev/null || true)
      if [ -z "$CONTENT" ]; then
        continue
      fi

      # Проверяем каждый паттерн из файла
      while IFS=$'\t' read -r name pattern; do
        # Пропускаем комментарии и пустые строки
        [[ "$name" =~ ^#.*$ || -z "$name" ]] && continue

        # Ищем совпадения
        MATCHES=$(echo "$CONTENT" | grep -nE "$pattern" 2>/dev/null || true)

        if [ -n "$MATCHES" ]; then
          FOUND_SECRETS=1
          SECRET_REPORT+="''${RED}✗ $name''${NC}\n"
          SECRET_REPORT+="  File: ''${CYAN}$file''${NC}\n"

          MATCH_COUNT=0
          while IFS= read -r match; do
            if [ $MATCH_COUNT -ge 3 ]; then
              SECRET_REPORT+="  ... and more\n"
              break
            fi
            LINE_NUM="''${match%%:*}"
            LINE_CONTENT="''${match#*:}"
            # Маскируем найденные значения
            MASKED=$(echo "$LINE_CONTENT" | sed -E 's/([A-Za-z0-9+/=_-]{4})[A-Za-z0-9+/=_-]{8,}/\1****/g')
            SECRET_REPORT+="  Line $LINE_NUM: ''${MASKED}''${NC}\n"
            MATCH_COUNT=$((MATCH_COUNT + 1))
          done <<< "$MATCHES"
          SECRET_REPORT+="\n"
        fi
      done < "$PATTERNS_FILE"
    done <<< "$STAGED_FILES"

    if [ $FOUND_SECRETS -eq 1 ]; then
      echo ""
      echo -e "''${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
      echo -e "''${RED}🔒 BLOCKED: Sensitive data detected in commit''${NC}"
      echo -e "''${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
      echo ""
      echo -e "$SECRET_REPORT"
      echo -e "''${YELLOW}To fix:''${NC}"
      echo "  1. Remove the sensitive data from the file"
      echo "  2. Add the file to .gitignore if it should never be committed"
      echo "  3. Run: git reset HEAD <file> && git add <file>"
      echo ""
      echo -e "''${YELLOW}Emergency bypass (NOT recommended):''${NC}"
      echo "  git commit --no-verify"
      echo ""
      echo -e "''${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━''${NC}"
      echo ""
      exit 1
    fi

    exit 0
  '';

  # ═══════════════════════════════════════════════════════════════
  # Commit-msg: проверка Conventional Commits (предупреждение)
  # ═══════════════════════════════════════════════════════════════
  commitMsgHook = pkgs.writeShellScript "commit-msg" ''
    RED='\033[0;31m'
    YELLOW='\033[0;33m'
    CYAN='\033[0;36m'
    NC='\033[0m'

    MSG_FILE="$1"
    if [ ! -f "$MSG_FILE" ]; then
      echo -e "''${RED}commit-msg: file not found: $MSG_FILE''${NC}"
      exit 1
    fi

    MSG=$(head -n 1 "$MSG_FILE")

    if [ -z "$MSG" ]; then
      echo -e "''${RED}commit-msg: empty commit message''${NC}"
      exit 1
    fi

    PATTERN='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-zA-Z0-9_./-]+\))?: .+'

    if echo "$MSG" | grep -qE "$PATTERN"; then
      exit 0
    fi

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
    echo "            feat(plasma): update window rules or plasma settings"
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
      pre-commit = preCommitHook;
      commit-msg = commitMsgHook;
    };
  };
}
