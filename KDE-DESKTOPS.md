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

**KWin Window Rules** — механизм KDE, который автоматически назначает приложение на нужный виртуальный рабочий стол при запуске. Правила хранятся в `~/.config/kwinrulesrc`.

**kwinrulesrc** — единственный plasma-конфиг, которым KDE управляет напрямую (не симлинк). При `home-manager switch` изменения из GUI автоматически копируются обратно в `dotfiles/plasma/kwinrulesrc`.

**Karousel** — тайлинг-скрипт, работающий *внутри* каждого рабочего стола. KWin Rules управлют распределением окон по столам, Karousel — расположением внутри стола.

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

### Вариант A: Через dotfiles (быстро)

Правила живут в `dotfiles/plasma/kwinrulesrc`. Редактируешь напрямую, потом применяешь:

1. Открой `dotfiles/plasma/kwinrulesrc`
2. Добавь новую секцию с индексом `[N]` (следующий свободный номер) и полями:
   ```ini
   [N]
   Description=My App
   wmclass=myapp
   wmclassmatch=0
   desktop=3
   desktoprule=2
   ```
3. Увеличь `count=` в секции `[General]`
4. Скопируй в конфиг: `cp dotfiles/plasma/kwinrulesrc ~/.config/kwinrulesrc`
5. Перезагрузи KWin: `qdbus org.kde.KWin /KWin reconfigure`
6. Или сразу сделай `home-manager switch` — activation-хук сам раскидает

### Вариант B: Через GUI

1. **Настрой → Окно → Диспетчер правил окон**
2. **Добавить** → «Определить свойства окна» → кликни по окну
3. Вкладка «Свойства окна» → **Виртуальный рабочий стол** → выбери номер
4. Режим: Apply Initially или Force
5. Сохрани
6. **GUI-изменения автоматически скопируются в dotfiles при следующем `home-manager switch`** (активационный хук `captureKwinRules`)

### Вариант C: Вручную

Отредактируй `~/.config/kwinrulesrc` напрямую. Изменения нужно синхронизировать в dotfiles вручную: `cp ~/.config/kwinrulesrc dotfiles/plasma/kwinrulesrc`.

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

- `dotfiles/plasma/kwinrulesrc` — master-копия правил в репозитории
- `~/.config/kwinrulesrc` — актуальный конфиг, читаемый KWin. KDE управляет им напрямую (не симлинк). При `home-manager switch` изменения автоматически копируются в dotfiles.
