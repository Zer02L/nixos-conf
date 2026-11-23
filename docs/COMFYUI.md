# ComfyUI в NixOS (декларативный Podman / systemd)

Руководство по запуску и управлению ComfyUI с аппаратным ускорением NVIDIA GPU через Podman в NixOS.

---

## 1. Архитектура и почему выбран rootless Podman

* **Декларативное управление:** сервис объявлен в NixOS модуле `modules/services/comfyui.nix`, включен в миксине `profiles/mixins/ai.nix` и подключен к хосту `hosts/zerg/default.nix`.
* **Rootless изоляция:** запускается через пользовательский `systemd.user.services.comfyui` от имени пользователя `zerg`. Все сгенерированные изображения, кэш, ноды и модели принадлежат пользователю `zerg:users` (без необходимости sudo и без конфликтов прав доступа).
* **Готовый бинарный образ:** используется проверенный образ `docker.io/yanwk/comfyui-boot:cu126-slim` (PyTorch + CUDA 12.6 + ComfyUI) без многочасовой сборки из исходников.
* **Аппаратное ускорение NVIDIA GPU:** проброс видеокарты через CDI (`--device nvidia.com/gpu=all`).
* **Постоянное хранилище:** локальная папка `~/comfyui/storage/`.

---

## 2. Управление сервисом (быстрые команды)

Для Fish настроена удобная функция-хелпер **`comfy`** (определена в `dotfiles/fish/config.fish`, подключенном через `home/common/shell.nix`). В других оболочках используйте прямые `systemctl --user` команды ниже.

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

Модуль объявляет опции в пространстве `services.comfyui-podman`:

* `services.comfyui-podman.enable = true;` — активация сервиса (в `hosts/zerg/default.nix`); модуль подключён через `profiles/mixins/ai.nix`.
* `services.comfyui-podman.autoStart = false;` — `false` по умолчанию, чтобы ComfyUI не занимал видеопамять (VRAM) при старте ПК. Запуск происходит мгновенно по команде `comfy start`. Если нужен автозапуск вместе с системой — установите `true`. Поскольку сервис пользовательский (`systemd.user.services.comfyui`), для старта до логина нужен `linger = true` у пользователя `zerg` — на хосте `zerg` он уже включён в `modules/users/zerg.nix`.
* `services.comfyui-podman.port = 8188;` — порт веб-интерфейса (публикуется только на `127.0.0.1`).
* `services.comfyui-podman.storageDir = "/home/zerg/comfyui/storage";` — путь к данным.
* `services.comfyui-podman.image = "docker.io/yanwk/comfyui-boot:cu126-slim";` — образ контейнера; при смене образа проверьте совместимость CUDA с драйвером хоста.

### Особенности rootless GPU

* CDI-манифест NVIDIA фильтруется в `ExecStartPre`: из `/var/run/cdi/nvidia-container-toolkit.json` удаляются несуществующие mount-пути, результат пишется в `~/.config/cdi/nvidia.json`.
* В `podman run` добавлен `--group-add keep-groups` — без него `crun` падает на `setgroups` и GPU недоступен.
* Путь `PATH` юнита расширен до `/run/wrappers/bin`, откуда rootless Podman берёт `newuidmap`/`newgidmap`.
* ComfyUI-Manager при первом запуске получает `config.ini` с `security_level = weak` и `allow_flagged_nodepack_install = True` (только для локального хоста) — это нужно для установки кастомных нод.

### Восстановление при ошибке GPU

1. Посмотрите причину: `comfy logs` (эквивалент `journalctl --user -u comfyui -f`).
2. Убедитесь, что CDI-манифест создан: `ls -l /var/run/cdi/nvidia-container-toolkit.json`. Если файла нет, включите `hardware.nvidia-container-toolkit.enable = true` (уже задано в модуле) и пересоберите систему, затем перегенерируйте манифест:
   ```bash
   sudo nvidia-ctk cdi generate --output=/var/run/cdi/nvidia-container-toolkit.json
   ```
3. Удалите кэш сгенерированного манифеста и зависший контейнер, затем перезапустите:
   ```bash
   rm -f ~/.config/cdi/nvidia.json
   podman rm -f comfyui
   comfy restart
   ```
4. Если GPU по-прежнему недоступен, проверьте `nvidia-smi` на хосте и соответствие версии CUDA в образе (`cu126`) версии драйвера.
