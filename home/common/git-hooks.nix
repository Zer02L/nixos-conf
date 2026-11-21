{ config
, pkgs
, lib
, ...
}:

let
  # ═══════════════════════════════════════════════════════════════
  # 1. Паттерны секретов
  # ═══════════════════════════════════════════════════════════════
  secretsPatternsFile = pkgs.writeText "secret-patterns" ''
    # format: name<tab>flags<tab>pattern (разделение строго знаком ТАБУЛЯЦИИ)
    # flags: i = case-insensitive, - = case-sensitive
    AWS Access Key	-	\bAKIA[0-9A-Z]{16}\b
    GitHub Token	-	\bgh[ps]_[a-zA-Z0-9_]{36,255}\b
    GitHub Fine-Grained	-	\bgithub_pat_[a-zA-Z0-9_]{82}\b
    GitLab Token	-	\bglpat-[a-zA-Z0-9\-_]{20,}\b
    OpenAI Key	-	\b(sk-[a-zA-Z0-9]{48}|sk-proj-[a-zA-Z0-9_\-]{48,})\b
    Anthropic Key	-	\bsk-ant-[a-zA-Z0-9\-_]{32,}\b
    Google API	-	\bAIza[0-9A-Za-z\-_]{35}\b
    Slack Token	-	\bxox[baprs]-[a-zA-Z0-9\-]{10,}\b
    Slack Webhook	-	https://hooks\.slack\.com/services/T[A-Z0-9]{8}/B[A-Z0-9]{8}/[a-zA-Z0-9]{24}
    Telegram Bot Token	-	\b[0-9]{9,10}:[a-zA-Z0-9_-]{35}\b
    Discord Token	-	\b[mN][a-zA-Z0-9]{23,}\.[a-zA-Z0-9_-]{6}\.[a-zA-Z0-9_-]{27,}\b
    Discord Webhook	-	https://discord(app)?\.com/api/webhooks/[0-9]+/[a-zA-Z0-9\-_]+
    Exa API Key	-	\bexa-[a-zA-Z0-9]{32,}\b
    Stripe Key	-	\bsk_live_[0-9a-zA-Z]{24,}\b
    Stripe Publishable	-	\bpk_live_[0-9a-zA-Z]{24,}\b
    Twilio Account SID	-	\bAC[0-9a-fA-F]{32}\b
    SendGrid Key	-	\bSG\.[a-zA-Z0-9\-_]{22}\.[a-zA-Z0-9\-_]{43}\b
    Mailgun Key	-	\bkey-[0-9a-zA-Z]{32}\b
    NPM Token	-	\bnpm_[a-zA-Z0-9]{36}\b
    RSA Private Key	-	-----BEGIN RSA PRIVATE KEY-----
    DSA Private Key	-	-----BEGIN DSA PRIVATE KEY-----
    EC Private Key	-	-----BEGIN EC PRIVATE KEY-----
    OpenSSH Private Key	-	-----BEGIN OPENSSH PRIVATE KEY-----
    PGP Private Key	-	-----BEGIN PGP PRIVATE KEY BLOCK-----
    Generic Private Key	-	-----BEGIN PRIVATE KEY-----
    Password Assignment	i	(password|passwd|pwd)[[:space:]]*[:=][[:space:]]*['"][^'"]{4,}['"]
    API Key Assignment	i	(api_key|apikey)[[:space:]]*[:=][[:space:]]*['"][^'"]{4,}['"]
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

    # Возможность отключения проверки через переменную окружения или git config
    if [ -n "$GIT_SECRETS_SKIP" ] || [ -n "$SKIP_SECRET_SCAN" ]; then
      exit 0
    fi
    if [ "$(git config --bool --get hooks.secret-scan 2>/dev/null)" = "false" ]; then
      exit 0
    fi

    export LC_ALL=C

    # 1. Собираем только измененные строки текстовых файлов (без --text, исключая бинарные файлы)
    STAGED_CHANGES=$(git diff --no-color --no-ext-diff --src-prefix=a/ --dst-prefix=b/ --cached --unified=0 | \
      awk '
        /^---/ {next}
        /^\+\+\+/ {sub(/^\+\+\+ (b\/)?/, ""); file=$0; next}
        /^@@/ {split(substr($3, 2), a, ","); line=a[1]; next}
        /^\+/ {print file ":" line ":" substr($0, 2); line++}
      ')

    if [ -z "$STAGED_CHANGES" ]; then
      exit 0
    fi

    FOUND_SECRETS=0
    REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo "")

    # 2. Построчно проверяем паттерны секретов
    while IFS=$'\t' read -r name flags pattern || [ -n "$name" ]; do
      [[ "$name" =~ ^# ]] && continue
      [[ -z "$name" || -z "$pattern" ]] && continue

      if [ "$flags" = "i" ]; then
        MATCHES=$(echo "$STAGED_CHANGES" | grep -E -i -e "$pattern" || true)
      else
        MATCHES=$(echo "$STAGED_CHANGES" | grep -E -e "$pattern" || true)
      fi

      if [ -n "$MATCHES" ]; then
        while IFS= read -r match_line; do
          [ -z "$match_line" ] && continue
          FILE_PATH=$(echo "$match_line" | cut -d':' -f1)
          LINE_NUM=$(echo "$match_line" | cut -d':' -f2)
          CONTENT=$(echo "$match_line" | cut -d':' -f3-)

          # Проверяем исключения .secretsignore через git check-ignore (поддержка масок, папок и т.д.)
          if [ -n "$REPO_ROOT" ] && [ -f "$REPO_ROOT/.secretsignore" ]; then
            if git -C "$REPO_ROOT" -c "core.excludesFile=$REPO_ROOT/.secretsignore" check-ignore --no-index -q "$FILE_PATH" 2>/dev/null; then
              continue
            fi
          fi

          # Игнорируем очевидные тестовые заглушки в присваиваниях ключей и паролей
          if [[ "$name" == *"Assignment"* ]]; then
            if echo "$CONTENT" | grep -E -i -q "[:=][[:space:]]*['\"][^'\"]*(test|dummy|mock|fake|example|sample|placeholder|offline|xxx|your[-_]|changeme|<[^>]+>)[^'\"]*['\"]"; then
              continue
            fi
          fi

          echo -e "\n\033[0;31m[ERROR] Обнаружен секрет типа: $name\033[0m"
          echo "  -> Файл: $FILE_PATH (строка $LINE_NUM): $CONTENT"
          FOUND_SECRETS=1
        done <<< "$MATCHES"
      fi
    done < "${secretsPatternsFile}"

    if [ "$FOUND_SECRETS" -eq 1 ]; then
      echo -e "\n\033[1;31m[BLOCK] Коммит заблокирован. Удалите секреты или добавьте файл/маску в .secretsignore перед коммитом.\033[0m"
      echo -e "\033[0;33m(Для разового пропуска: GIT_SECRETS_SKIP=1 git commit, либо git config hooks.secret-scan false для репозитория)\033[0m"
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

    # Пропускаем служебные коммиты слияний, фиксапов и сквошей
    if echo "$COMMIT_MSG" | grep -E -q "^(Merge |Revert |fixup! |squash! |amend! )"; then
      exit 0
    fi

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
      force = true;
    };
    ".config/git/hooks/commit-msg" = {
      source = commitMsgScript;
      executable = true;
      force = true;
    };
  };

  programs.git = {
    enable = true;
    settings = {
      core.hooksPath = "~/.config/git/hooks";
    };
  };
}
