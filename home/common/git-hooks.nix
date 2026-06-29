{
  config,
  pkgs,
  lib,
  ...
}:

let
  # ═══════════════════════════════════════════════════════════════
  # 1. Паттерны секретов
  # ═══════════════════════════════════════════════════════════════
  secretsPatternsFile = pkgs.writeText "secret-patterns" ''
    # format: name<tab>pattern (разделение строго знаком ТАБУЛЯЦИИ)
    AWS Access Key	AKIA[0-9A-Z]{16}
    GitHub Token	gh[ps]_[a-zA-Z0-9_]{36,255}
    GitHub Fine-Grained	github_pat_[a-zA-Z0-9_]{82}
    GitLab Token	glpat-[a-zA-Z0-9\-_]{20,}
    OpenAI Key	sk-[a-zA-Z0-9]{48}
    Anthropic Key	sk-ant-[a-zA-Z0-9\-_]{40,}
    Google API	AIza[0-9A-Za-z\-_]{35}
    Slack Token	xox[baprs]-[a-zA-Z0-9\-]{10,}
    Slack Webhook	https://hooks\.slack\.com/services/T[A-Z0-9]{8}/B[A-Z0-9]{8}/[a-zA-Z0-9]{24}
    Telegram Bot Token	[0-9]{9}:[a-zA-Z0-9_-]{35}
    Discord Token	[mN][a-zA-Z0-9]{23,}\.[a-zA-Z0-9_-]{6}\.[a-zA-Z0-9_-]{27,}
    Discord Webhook	https://discord(app)?\.com/api/webhooks/[0-9]+/[a-zA-Z0-9\-_]+
    Exa API Key	exa-[a-zA-Z0-9]{32,}
    Stripe Key	sk_live_[0-9a-zA-Z]{24,}
    Stripe Publishable	pk_live_[0-9a-zA-Z]{24,}
    Twilio Account SID	AC[0-9a-fA-F]{32}
    SendGrid Key	SG\.[a-zA-Z0-9\-_]{22}\.[a-zA-Z0-9\-_]{43}
    Mailgun Key	key-[0-9a-zA-Z]{32}
    NPM Token	npm_[a-zA-Z0-9]{36}
    RSA Private Key	-----BEGIN RSA PRIVATE KEY-----
    DSA Private Key	-----BEGIN DSA PRIVATE KEY-----
    EC Private Key	-----BEGIN EC PRIVATE KEY-----
    OpenSSH Private Key	-----BEGIN OPENSSH PRIVATE KEY-----
    PGP Private Key	-----BEGIN PGP PRIVATE KEY BLOCK-----
    Generic Private Key	-----BEGIN PRIVATE KEY-----
    Password Assignment	(?i)(password|passwd|pwd)\s*[:=]\s*['"][^'"]+['"]
    API Key Assignment	(?i)(api_key|apikey)\s*[:=]\s*['"][^'"]+['"]
  '';

  # ═══════════════════════════════════════════════════════════════
  # 2. Скрипт pre-commit (Блокировка коммита)
  # ═══════════════════════════════════════════════════════════════
  preCommitScript = pkgs.writeShellScript "pre-commit" ''
    export PATH="${
      lib.makeBinPath [
        pkgs.git
        pkgs.gnugrep
        pkgs.gawk
      ]
    }:$PATH"

    # 1. Собираем только измененные строки текстовых файлов (учитывает .gitignore)
    STAGED_CHANGES=$(git diff --cached --unified=0 --text | \
      awk '
        /^---/ {next}
        /^\+\+\+/ {file=substr($0,6); next}
        /@@/ {split($3,a,","); line=a; next}
        /^\+/ {print file ":" line ":" substr($0,2); line++}
      ')

    if [ -z "$STAGED_CHANGES" ]; then
      exit 0
    fi

    FOUND_SECRETS=0
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    # 2. Построчно проверяем паттерны секретов
    while IFS=$'\t' read -r name pattern || [ -n "$name" ]; do
      [[ "$name" =~ ^# ]] && continue
      [[ -z "$name" || -z "$pattern" ]] && continue

      # Ищем совпадения в staged изменениях
      MATCHES=$(echo "$STAGED_CHANGES" | grep -E -i "$pattern" || true)

      if [ -n "$MATCHES" ]; then
        # Читаем совпадения построчно, чтобы проверить правила исключений (.secretsignore)
        while IFS= read -r match_line; do
          FILE_PATH=$(echo "$match_line" | cut -d':' -f1)
          LINE_NUM=$(echo "$match_line" | cut -d':' -f2)
          CONTENT=$(echo "$match_line" | cut -d':' -f3-)

          # Проверяем, добавлен ли этот конкретный файл в локальный .secretsignore репозитория
          if [ -n "$REPO_ROOT" ] && [ -f "$REPO_ROOT/.secretsignore" ]; then
            if grep -Fxq "$FILE_PATH" "$REPO_ROOT/.secretsignore"; then
              continue # Файл в исключениях, пропускаем ошибку
            fi
          fi

          echo -e "\n\033[0;31m[ERROR] Обнаружен секрет типа: $name\033[0m"
          echo "  -> Файл: $FILE_PATH (строка $LINE_NUM): $CONTENT"
          FOUND_SECRETS=1
        done <<< "$MATCHES"
      fi
    done < "${secretsPatternsFile}"

    if [ "$FOUND_SECRETS" -eq 1 ]; then
      echo -e "\n\033[1;31m[BLOCK] Коммит заблокирован. Удалите секреты или добавьте файл в .secretsignore перед коммитом.\033[0m"
      exit 1
    fi
    exit 0
  '';

  # ═══════════════════════════════════════════════════════════════
  # 3. Скрипт commit-msg (Предупреждение Conventional Commits)
  # ═══════════════════════════════════════════════════════════════
  commitMsgScript = pkgs.writeShellScript "commit-msg" ''
    export PATH="${lib.makeBinPath [ pkgs.gnugrep ]}:$PATH"

    MSG_FILE="$1"
    COMMIT_MSG=$(cat "$MSG_FILE")

    # Регулярное выражение для Conventional Commits
    CONVENTIONAL_REGEX="^(feat|fix|docs|style|refactor|perf|test|build|ci|chore|revert)(\([a-z0-9_-]+\))?!?: .+"

    if ! echo "$COMMIT_MSG" | grep -E -q "$CONVENTIONAL_REGEX"; then
      echo -e "\n\033[0;33m[WARNING] Сообщение коммита не соответствует Conventional Commits!\033[0m"
      echo -e "Текущее сообщение: \033[1m$COMMIT_MSG\033[0m"
      echo -e "Рекомендуемый формат: \033[0;32mtype(scope): description\033[0m (например: feat(auth): add login button)"
      echo -e "Допустимые типы: feat, fix, docs, style, refactor, perf, test, build, ci, chore, revert\n"
    fi
    exit 0
  '';

in
{
  # Интеграция через Home Manager (глобальные хуки)
  home.file = {
    ".config/git/hooks/pre-commit" = {
      source = preCommitScript;
      executable = true;
    };
    ".config/git/hooks/commit-msg" = {
      source = commitMsgScript;
      executable = true;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      core.hooksPath = "~/.config/git/hooks";
    };
  };
}
