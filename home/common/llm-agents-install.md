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

## Обновление

```bash
bun update -g @oh-my-pi/pi-coding-agent   # omp
npm update -g @kilocode/cli               # kilocode
curl -fsSL https://nono.sh/install.sh | sh # nono
cargo install workmux --force              # workmux
curl -fsSL https://herdr.dev/install.sh | sh # herdr
npm update -g openskills                   # openskills
npm update -g @fission-ai/openspec@latest  # openspec
```
