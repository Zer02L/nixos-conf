# LLM Agents — ручная установка

Установка CLI-инструментов для AI-кодинга без flake `llm-agents.nix`.

## omp (Oh My Pi)

AI-кодирующий агент с IDE-интеграцией.

```bash
# Bun (рекомендуется)
bun install -g @oh-my-pi/pi-coding-agent

# Или через curl
curl -fsSL https://omp.sh/install | sh

# Или Homebrew
brew install can1357/tap/omp
```

- Homepage: https://omp.sh
- Repo: https://github.com/can1357/oh-my-pi

---

## kilocode

Open source CLI coding agent на базе OpenCode.

```bash
# npm
npm install -g @kilocode/cli

# Bun
bun install -g @kilocode/cli

# Homebrew
brew install kilocode
```

- Homepage: https://kilo.ai/cli
- Repo: https://github.com/kilo-org/kilo

---

## nono

Sandbox для AI-агентов с kernel-level isolation.

```bash
# curl
curl -fsSL https://nono.sh/install.sh | sh

# Homebrew
brew install nono
```

- Homepage: https://nono.sh
- Repo: https://github.com/always-further/nono

---

## workmux

Git worktrees + tmux для параллельной разработки с AI-агентами.

```bash
# curl
curl -fsSL https://raw.githubusercontent.com/raine/workmux/main/scripts/install.sh | bash

# Homebrew
brew install raine/workmux/workmux

# Cargo
cargo install workmux
```

- Homepage: https://workmux.raine.dev
- Repo: https://github.com/raine/workmux

---

## herdr

Agent multiplexer — tmux для AI-агентов.

```bash
# curl
curl -fsSL https://herdr.dev/install.sh | sh
```

- Homepage: https://herdr.dev
- Repo: https://github.com/herdr/herdr

---

## openskills

Universal skills loader для AI-агентов (Anthropic SKILL.md format).

```bash
# npm
npm install -g openskills

# Или через npx (без глобальной установки)
npx openskills install anthropics/skills
npx openskills sync
```

- Repo: https://github.com/numman-ali/openskills

---

## openspec

Spec-driven development для AI-ассистентов.

```bash
# npm
npm install -g @fission-ai/openspec@latest
```

Требуется Node.js ≥ 20.19.0.

- Homepage: https://github.com/Fission-AI/OpenSpec

---

## antigravity-cli

CLI для Google Antigravity — agentic development platform.

```bash
# nix (без flake, одноразово)
nix run github:numtide/llm-agents.nix#antigravity-cli -- --help
```

Альтернативно — скачать бинарник из релизов или использовать `nono` для sandboxed запуска.

- Homepage: https://antigravity.google

---

## t3code / t3-cli

T3 Code (IDE + headless CLI). В этом репозитории пакеты собраны через `nvfetcher` и доступны сразу:

```bash
# Стабильный / nightly канал
nix run .#t3-cli -- --help
nix run .#t3-cli-nightly -- --help

# Собрать AppImage GUI
nix build .#t3code-nightly
```

Декларативно канал выбирается опциями `custom.t3code.channel` (home) и `custom.services.t3-server.channel` (server); по умолчанию `nightly` и `stable` соответственно.

- Repo: https://github.com/pingdotgg/t3code

---

## opencode

OpenCode — агентный CLI/TUI для кодинга.

```bash
nix run .#opencode
# или из апстрима: curl -fsSL https://opencode.ai/install | bash
```

- Repo: https://github.com/anomalyco/opencode

---

## orca (Orca AI IDE)

```bash
nix run .#orca
```

Алиасы в оверлее: `orca`, `orca-ai`, `orca-ide`.

- Repo: https://github.com/stablyai/orca

---

## skills-manager

Графический менеджер agent-скиллов (AppImage).

```bash
nix run .#skills-manager
```

- Repo: https://github.com/xingkongliang/skills-manager

---

## pi-coding-agent

Агент Oh My Pi (`pi`), пакет дублируется с omp:

```bash
nix run .#pi-coding-agent
```

- Repo: https://github.com/can1357/oh-my-pi

---

## Обновление

```bash
bun update -g @oh-my-pi/pi-coding-agent   # omp
npm update -g @kilocode/cli               # kilocode
curl -fsSL https://nono.sh/install.sh | sh # nono
cargo install workmux --force              # workmux
curl -fsSL https://herdr.dev/install.sh | sh # herdr
npm update -g openskills                   # openskills
npm update -g @fission-ai/openspec@latest  # openspec

# nvfetcher-пакеты (t3code, opencode, orca, skills-manager и др.)
nvfetcher   # бинарник из home/common/dev-tools.nix
git add _sources/generated.nix _sources/generated.json
```

> [!NOTE]
> Для инструментов, уже упакованных в этом флаке, ручная установка через `npm`/`bun`/`curl` не нужна и может конфликтовать с декларативной — используйте `nix run .#<package>` или соответствующий home-manager модуль.
