# ComfyUI в NixOS (декларативный Podman / systemd)

Руководство по запуску и управлению ComfyUI с аппаратным ускорением NVIDIA GPU через Podman в NixOS.

---

## 1. Архитектура и почему выбран rootless Podman

* **Декларативное управление:** сервис объявлен в NixOS модуле `modules/services/comfyui.nix` и подключен в `hosts/zerg/default.nix`.
* **Rootless изоляция:** запускается через пользовательский `systemd.user.services.comfyui` от имени пользователя `zerg`. Все сгенерированные изображения, кэш, ноды и модели принадлежат пользователю `zerg:users` (без необходимости sudo и без конфликтов прав доступа).
* **Готовый бинарный образ:** используется проверенный образ `docker.io/yanwk/comfyui-boot:cu126-slim` (PyTorch + CUDA 12.6 + ComfyUI) без многочасовой сборки из исходников.
* **Аппаратное ускорение NVIDIA GPU:** проброс видеокарты через CDI (`--device nvidia.com/gpu=all`).
* **Постоянное хранилище:** локальная папка `~/comfyui/storage/`.

---

## 2. Управление сервисом (быстрые команды)

Для Fish настроена удобная функция-хелпер **`comfy`**:

```bash
# Запустить сервис ComfyUI в фоне
comfy start

# Проверить статус работы
comfy status

# Смотреть логи в реальном времени
comfy logs

# Остановить сервис
comfy stop

# Перезапустить сервис
comfy restart

# Открыть веб-интерфейс в браузере
comfy open
```

Веб-интерфейс доступен в браузере:  
👉 **http://127.0.0.1:8188**

*(Также всегда доступны стандартные команды systemd: `systemctl --user start comfyui`, `systemctl --user stop comfyui`, `journalctl --user -u comfyui -f`)*

---

## 3. Структура директорий (`~/comfyui/`)

- `storage/` — данные, сохраняемые между перезапусками:
  - `storage/models/checkpoints/` — базовые модели (`.safetensors`, `.ckpt`)
  - `storage/models/loras/` — LoRA модели
  - `storage/models/vae/` — VAE
  - `storage/custom_nodes/` — кастомные ноды и ComfyUI-Manager
  - `storage/input/` — входные изображения
  - `storage/output/` — результаты генерации
  - `storage/user/` — сохранённые воркфлоу и настройки интерфейса
  - `storage/dot-cache/` и `storage/dot-local/` — pip/huggingface кэш

---

## 4. Конфигурация в NixOS (`modules/services/comfyui.nix`)

Опции модуля:
* `services.comfyui.enable = true;` — активация сервиса (в `hosts/zerg/default.nix`).
* `services.comfyui.autoStart = false;` — `false` по умолчанию, чтобы ComfyUI не занимал видеопамять (VRAM) при старте ПК. Запуск происходит мгновенно по команде `comfy start`. Если нужен автозапуск вместе с системой — установите `true`.
* `services.comfyui.port = 8188;` — порт веб-интерфейса.
* `services.comfyui.storageDir = "/home/zerg/comfyui/storage";` — путь к данным.
