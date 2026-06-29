# KDE Plasma — Виртуальные рабочие столы и KWin Rules

## Раскладка рабочих столов

| Десктоп | Категория | Приложения |
|---|---|---|
| **1** | Терминал | ghostty, neovim |
| **2** | Браузер | librewolf, mullvad-browser |
| **3** | IDE | zed, vscode, jetbrains |
| **4** | Коммуникация | vesktop, telegram, bitwarden |
| **5** | Прочее | obsidian, super-productivity, blender, onlyoffice, obs, mpv |

## Как это работает

**plasma-manager** (nix-community/plasma-manager) — home-manager модуль, который управляет всеми Plasma-конфигами декларативно через `programs.plasma`.

**kwinrulesrc** теперь генерируется plasma-manager'ом из `home/common/plasma.nix` (опция `programs.plasma.window-rules`). Изменения вносятся в Nix, после чего `home-manager switch`.

**Karousel** — тайлинг-скрипт, работающий *внутри* каждого рабочего стола. KWin Rules управляют распределением окон по столам, Karousel — расположением внутри стола.

## Два режима привязки

| Режим | `desktopsrule` | Поведение |
|---|---|---|
| **Apply Initially** | `0` | Окно стартует на нужном столе, но можно перетащить |
| **Force** | `2` | Жёсткая привязка, перетаскивание невозможно |

По умолчанию в конфиге используется **Apply Initially**.

## Найти WM_CLASS приложения

```bash
# Запусти приложение, затем:
xprop | grep WM_CLASS
# Кликни по окну приложения. Вывод: WM_CLASS(STRING) = "instance", "class"
# Для KWin Rules используется "class" (второе значение).
```

Или через `kwinrulesrc` GUI:
1. ПКМ на заголовке окна → **Дополнительные действия** → **Настройки менеджера окон**
2. Нажми **«Определить свойства окна»** → кликни по окну.

## Добавить новое приложение
### Вариант A: Через plasma.nix (рекомендуется)

Правила декларируются в `home/common/plasma.nix`:

1. Открой `home/common/plasma.nix`
2. Добавь правило через `mkDesktopRule`:
   ```nix
   (mkDesktopRule { name = "My App"; wmclass = "myapp"; desktop = 3; })
   ```
3. Для Force-режима: `force = true`
4. Сделай `home-manager switch`

### Вариант B: Через GUI + capture

1. **Настрой → Окно → Диспетчер правил окон**
2. **Добавить** → «Определить свойства окна» → кликни по окну
3. Вкладка «Свойства окна» → **Виртуальный рабочий стол** → выбери номер
4. Режим: Apply Initially или Force
5. Сохрани
6. Захвати изменения и перенеси в Nix: прочитай `~/.config/kwinrulesrc` и перенеси в `home/common/plasma.nix`
7. Удали GUI-правило (чтобы не было дублирования) и сделай `home-manager switch`

### Вариант C: Вручную (не рекомендуется — plasma-manager перезапишет)

Можно отредактировать `~/.config/kwinrulesrc` напрямую, но plasma-manager перезапишет файл при `home-manager switch`.
Используй этот вариант только для тестирования: внеси изменения, проверь, что работает, перенеси в `plasma.nix`.


## Полезные команды

| Команда | Действие |
|---|---|
| `qdbus org.kde.KWin /KWin reconfigure` | Перечитать kwinrulesrc без перезагрузки |
| `xprop \| grep WM_CLASS` | Узнать WM_CLASS окна |
| `kcmshell6 kwinrules` | Открыть GUI диспетчера правил |
| `qdbus org.kde.KWin /KWin currentDesktop` | Текущий рабочий стол |
| `qdbus org.kde.KWin /KWin numDesktops` | Количество рабочих столов |
| `qdbus org.kde.KWin /KWin setActiveDesktop N` | Переключиться на стол N |

## Горячие клавиши (по умолчанию)

| Комбинация | Действие |
|---|---|
| `Meta + Tab` | Переключение между окнами |
| `Meta + Shift + Tab` | Переключение в обратном порядке |
| `Meta + Ctrl + ←/→` | Предыдущий/следующий стол |
| `Meta + F1-F4` | Перейти к столу N |
| `Meta + W` | Overview (все столы) |
| `Meta + G` | Grid View (сетка столов) |
| `Meta + T` | Редактор тайлов (Tile Editor) |
| `Meta + D` | Показать/скрыть рабочий стол |
| `Meta + Q` | Переключатель активностей |
| `Meta + L` | **Блокировка экрана** (занято!) |
| `Meta + Enter` | Терминал (если настроено в KDE) |

## Karousel (тайлинг внутри стола)

WASD-схема: `A`/`S`/`D`/`W` + модификаторы под левую руку. Никаких конфликтов с глобальными шорткатами KDE.

| Комбинация | Действие |
|---|---|
| `Meta + S` | Фокус на следующую колонку вниз |
| `Meta + Home` / `Meta + End` | Фокус на первую/последнюю колонку |
| `Meta + [` / `Meta + ]` | Уменьшить/увеличить колонку |
| `Meta + Ctrl + D` | Сжать колонки вправо |
| **Перемещение окон** | |
| `Meta + Shift + W` | Окно вверх |
| `Meta + Shift + D` | Окно вправо |
| `Meta + Shift + 1..9` | Окно в колонку N |
| **Перемещение колонок** | |
| `Meta + Ctrl + Shift + A` | Колонку влево |
| `Meta + Ctrl + Shift + D` | Колонку вправо |
| `Meta + Ctrl + Shift + 1..9` | Колонку на позицию N |
| `Meta + Ctrl + Shift + F1..F12` | Колонку на десктоп N |
| **Режимы** | |
| `Meta + Space` | Float/unfloat окна |
| `Meta + X` | Stacked/grid режим колонки |
| **Скролл** | |
| `Meta + Alt + A` / `Meta + Alt + D` | Скролл на колонку влево/вправо |
| `Meta + Alt + PgUp` / `Meta + Alt + PgDown` | Скролл влево/вправо |
| `Meta + Alt + Return` | Центрировать фокус |
| `Meta + Ctrl + Return` | Переместить Karousel на текущий экран |
| **Сервис** | |
| `Meta + Ctrl + Shift + R` | Перезапустить Karousel (если тайлинг сломался) |
| `Meta + Ctrl + Shift + X` | Перезагрузить Plasma Shell (если глючит интерфейс) |

## Troubleshooting

**Правило не работает?**
- Убедись, что WMClass совпадает точно (регистр имеет значение)
- Проверь `qdbus org.kde.KWin /KWin reconfigure`
- Некоторые Wayland-приложения报告уют другой WM_CLASS, чем X11. Проверь через `xprop`

**Не видишь нужный стол?**
- Добавь столы: **Настрой → Рабочий стол → Виртуальные рабочие столы** → кол-во

**Конфликт с Karousel?**
- Если окно открывается на **всех столах** сразу — Karousel видит `desktops.length = 0` и не тайлит его.
- Внутренняя проверка в Karousel: `getDesktopForClient()` требует `kwinClient.desktops.length === 1`.
- Решение: `qdbus org.kde.KWin /KWin reconfigure` — после `home-manager switch` KWin перечитывает kwinrulesrc.
- При `home-manager switch` `qdbus` теперь вызывается автоматически из activation-скриптов.

**Окно на всех столах?**
- Проверь, что KWin перечитал конфиг: `qdbus org.kde.KWin /KWin reconfigure`
- Проверь WM_CLASS через `xprop` (или `kwin_rules_dump` на Wayland)
- Отключи Karousel временно: если правила работают без него — конфликт с Karousel

---

- `home/common/plasma.nix` — декларативный источник правил (Nix)
- `~/.config/kwinrulesrc` — генерируется plasma-manager'ом, перезаписывается при `home-manager switch`
- Для тестирования правь `~/.config/kwinrulesrc` напрямую, затем переноси в `plasma.nix`
- Перезагрузить KWin после изменений: `qdbus org.kde.KWin /KWin reconfigure`
