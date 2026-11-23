# KDE Plasma — Виртуальные рабочие столы и KWin Rules

## Раскладка рабочих столов

| Десктоп | Категория | Приложения |
|---|---|---|
| **1** | Терминал | ghostty, kitty (nvim запускается внутри терминала) |
| **2** | Браузер | librewolf, firefox, mullvad-browser |
| **3** | IDE | zed, vscode (`Code`), jetbrains-* |
| **4** | Коммуникация | vesktop, telegram-desktop, bitwarden |
| **5** | Прочее | obsidian, super-productivity, blender, obs, mpv |

Источник правил — `home/common/plasma.nix`, секция `programs.plasma.window-rules`.

## Как это работает

**plasma-manager** (nix-community/plasma-manager) — home-manager модуль, который управляет всеми Plasma-конфигами декларативно через `programs.plasma`.

**kwinrulesrc** теперь генерируется plasma-manager'ом из `home/common/plasma.nix` (опция `programs.plasma.window-rules`). Изменения вносятся в Nix, после чего `home-manager switch`.

**Karousel** — тайлинг-скрипт, работающий *внутри* каждого рабочего стола. KWin Rules управляют распределением окон по столам, Karousel — расположением внутри стола.

> [!WARNING]
> Модуль `home/common/karousel.nix` сейчас **закомментирован** в `parts/home.nix` и не импортируется профилями — то есть Karousel не включается при `home-manager switch`. Таблица биндингов ниже описана по коду модуля и актуальна только если вы его вернёте в `modules`/профиль.

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
| `Meta + F1-F4` | Перейти к столу N (1–4); для 5-го стола используйте `Meta + Ctrl + →` с 4-го или `qdbus org.kde.KWin /KWin setActiveDesktop 5` |
| `Meta + W` | Overview (все столы) |
| `Meta + G` | Grid View (сетка столов) |
| `Meta + T` | Редактор тайлов (Tile Editor) |
| `Meta + D` | Показать/скрыть рабочий стол |
| `Meta + Q` | Переключатель активностей |
| `Meta + L` | **Блокировка экрана** (занято!) |
| `Meta + Enter` | Терминал (если настроено в KDE) |

## Karousel (тайлинг внутри стола)

Схема **HJKL** (vi-подобная), как задано в `home/common/karousel.nix`. Если модуль включён, эти комбинации пересекаются с глобальными (`Meta + L` — блокировка экрана, `Meta + H/J/K/L` — навигация), поэтому проверьте `~/.config/kglobalshortcutsrc` после `home-manager switch`.

| Комбинация | Действие |
|---|---|
| `Meta + H` / `Meta + J` / `Meta + K` / `Meta + L` | Фокус на колонку влево / вниз / вверх / вправо |
| `Meta + Home` / `Meta + End` | Фокус на первую/последнюю колонку |
| `Meta + 1..9` | Фокус на колонку N |
| **Перемещение окон** | |
| `Meta + Shift + H/J/K/L` | Окно влево / вниз / вверх / вправо |
| `Meta + Shift + Home/End` | Окно в первую/последнюю колонку |
| `Meta + Shift + 1..9` | Окно в колонку N |
| **Перемещение колонок** | |
| `Meta + Ctrl + Shift + H/L` | Колонку влево / вправо |
| `Meta + Ctrl + Shift + Home/End` | Колонку в начало/конец |
| `Meta + Ctrl + Shift + 1..9` | Колонку на позицию N |
| `Meta + Ctrl + PgUp/PgDown` | Колонку на предыдущий/следующий десктоп |
| **Размеры и режимы** | |
| `Meta + Ctrl + Plus/Minus` | Увеличить/уменьшить колонку |
| `Meta + Ctrl + X` | Выровнять ширину колонок |
| `Meta + Ctrl + H/L` | Сжать колонки влево/вправо |
| `Meta + R` / `Meta + Shift + R` | Цикл предустановленных ширин (вперёд/назад) |
| `Meta + Shift + Space` | Float/unfloat окна |
| `Meta + X` | Stacked/grid режим колонки |
| **Скролл** | |
| `Meta + Alt + C` | Скролл к окну в фокусе |
| `Meta + Alt + H/L` | Скролл на колонку влево/вправо |
| `Meta + Alt + PgUp/PgDown` | Скролл влево/вправо |
| `Meta + Alt + Home/End` | Скролл в начало/конец |

## Troubleshooting

**Правило не работает?**
- Убедись, что WMClass совпадает точно (регистр имеет значение)
- Проверь `qdbus org.kde.KWin /KWin reconfigure`
- Некоторые Wayland-приложения сообщают другой WM_CLASS, чем X11. `xprop` работает только в X11/XWayland; в чистом Wayland используйте GUI «Определить свойства окна» в диспетчере правил KWin (см. раздел «Найти WM_CLASS приложения»)

**Не видишь нужный стол?**
- Добавь столы: **Настрой → Рабочий стол → Виртуальные рабочие столы** → кол-во

**Конфликт с Karousel?**
- Если окно открывается на **всех столах** сразу — Karousel видит `desktops.length = 0` и не тайлит его.
- Внутренняя проверка в Karousel: `getDesktopForClient()` требует `kwinClient.desktops.length === 1`.
- Решение: выполни `qdbus org.kde.KWin /KWin reconfigure` вручную после `home-manager switch` — автоматического вызова в activation-скриптах сейчас нет.

**Окно на всех столах?**
- Проверь, что KWin перечитал конфиг: `qdbus org.kde.KWin /KWin reconfigure`
- Проверь WM_CLASS через `xprop` (X11/XWayland) или GUI «Определить свойства окна» в KWin (Wayland)
- Отключи Karousel временно: если правила работают без него — конфликт с Karousel

---

- `home/common/plasma.nix` — декларативный источник правил (Nix)
- `home/common/karousel.nix` — конфиг тайлинга (сейчас отключён в `parts/home.nix`)
- `~/.config/kwinrulesrc` — генерируется plasma-manager'ом, перезаписывается при `home-manager switch`
- `~/.config/kglobalshortcutsrc` — биндинги Karousel (если модуль включён)
- Для тестирования правь `~/.config/kwinrulesrc` напрямую, затем переноси в `plasma.nix`
- Перезагрузить KWin после изменений: `qdbus org.kde.KWin /KWin reconfigure`
