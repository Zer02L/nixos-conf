# ComfyUI в NixOS через Podman

Руководство по запуску и управлению ComfyUI с аппаратным ускорением NVIDIA GPU через Podman.

---

## 1. Архитектура и почему выбран Podman

В репозитории есть модуль `modules/services/comfyui.nix` и flake `comfyui-nix`, однако нативным способом сборка PyTorch с поддержкой CUDA в NixOS может вызывать длительную компиляцию из исходников при отсутствии нужной ревизии в бинарном кэше.

**Решение через Podman:**
* Полностью готовый бинарный образ `docker.io/yanwk/comfyui-boot:cu126-slim` (PyTorch + CUDA 12.6 + ComfyUI).
* Запуск без какой-либо компиляции.
* Использование драйвера NVIDIA хоста через CDI (`--device nvidia.com/gpu=all`).
* Постоянное хранение моделей, кастомных нод и результатов генерации в локальной папке `~/comfyui/storage/`.

---

## 2. Быстрые команды

Все операции выполняются из каталога `~/comfyui`:

```bash
cd ~/comfyui

# Запуск в фоне
./start.sh
# или напрямую: podman-compose up -d

# Просмотр логов в реальном времени
./logs.sh
# или: podman-compose logs -f

# Остановка контейнера
./stop.sh
# или: podman-compose down
```

Веб-интерфейс доступен в браузере:  
👉 **http://127.0.0.1:8188**

---

## 3. Структура директорий (`~/comfyui/`)

- `compose.yaml` — декларативная конфигурация сервиса (образ, порты, CDI GPU, volumes с меткой `:Z`).
- `start.sh`, `stop.sh`, `logs.sh` — скрипты управления.
- `storage/` — директория данных (сохраняются между перезапусками):
  - `storage/models/checkpoints/` — базовые модели (`.safetensors`, `.ckpt`)
  - `storage/models/loras/` — LoRA модели
  - `storage/models/vae/` — VAE
  - `storage/custom_nodes/` — кастомные расширения и ComfyUI-Manager
  - `storage/input/` — загружаемые изображения
  - `storage/output/` — результаты генерации
  - `storage/user/` — сохранённые воркфлоу и настройки интерфейса

---

## 4. Важные нюансы NixOS + Podman

1. **Полные имена образов (FQIN):**  
   В NixOS в Podman по умолчанию выключен неявный поиск по Docker Hub. Всегда указывайте полный путь: `docker.io/yanwk/comfyui-boot:cu126-slim` (вместо `yanwk/...`).
2. **Проброс GPU через CDI:**  
   В `modules/services/podman.nix` включён `hardware.nvidia-container-toolkit.enable = true`. Podman автоматически генерирует `/var/run/cdi/nvidia-container-toolkit.json`. Проброс выполняется директивой `devices: ["nvidia.com/gpu=all"]`.
3. **Метка `:Z` для томов:**  
   Все тома монтируются с флагом `:Z`, чтобы корректно выставлялись права доступа внутри rootless-контейнера.
