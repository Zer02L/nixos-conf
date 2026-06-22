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

**KWin Window Rules** — механизм KDE, который автоматически назначает приложение на нужный виртуальный рабочий стол при запуске. Правила генерируются декларативно через Nix в файл `~/.config/kwinrulesrc`.

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

### Вариант A: Через Nix (рекомендуется)

Отредактируй `home/common/kwin-rules.nix`, добавь правило в список `rules`:

```nix
(mkRule { name = "Новое приложение"; wmclass = "app-wmclass"; desktop = 3; })
```

Затем применить:
```bash
home-manager switch --flake .#zerg@zerg
```

### Вариант B: Через GUI

1. **Настрой → Окно → Диспетчер правил окон**
2. **Добавить** → «Определить свойства окна» → кликни по окну
3. Вкладка «Свойства окна» → **Виртуальный рабочий стол** → выбери номер
4. Режим: Apply Initially или Force
5. Сохрани

### Вариант C: Вручную в kwinrulesrc

Добавь секцию в `~/.config/kwinrulesrc`:

```ini
[9]
Description=My App
wmclass=myapp
wmclassmatch=2
wmclasscomplete=true
desktops=3
desktopsrule=0
```

Затем перезагрузи KWin: `qdbus org.kde.KWin /KWin reconfigure`

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
| `Meta + Tab` | Переключение между рабочими столами |
| `Meta + Shift + Tab` | Переключение в обратном порядке |
| `Meta + Ctrl + ←/→` | Предыдущий/следующий стол |
| `Meta + 1-5` | Перейти к столу N |
| `Meta + Shift + 1-5` | Переместить окно на стол N |
| `Meta + T` | Показать все столы (Overview) |

## Karousel (тайлинг внутри стола)

| Комбинация | Действие |
|---|---|
| `Super + j/k` | Фокус влево/вправо по колонкам |
| `Super + J/K` | Переместить колонку влево/вправо |
| `Super + h/l` | Уменьшить/увеличить колонку |
| `Super + Shift + h/l` | Сдвинуть соседа |
| `Super + Enter` | Новый терминал (stacked) |
| `Super + Shift + c` | Закрыть колонку |
| `Super + f` | Полноэкранный режим колонки |
| `Super + space` | Float/unfloat окно |

## Troubleshooting

**Правило не работает?**
- Убедись, что WMClass совпадает точно (регистр имеет значение)
- Проверь `qdbus org.kde.KWin /KWin reconfigure`
- Некоторые Wayland-приложения报告уют другой WM_CLASS, чем X11. Проверь через `xprop`

**Не видишь нужный стол?**
- Добавь столы: **Настрой → Рабочий стол → Виртуальные рабочие столы** → кол-во

**Конфликт с Karousel?**
- Karousel тайлингует *внутри* стола, KWin Rules — *между* столами. Конфликта быть не должно.
- Если окно «улетает» — проверь, нет ли правила с `desktopsrule=2` (Force) на неправильном столе.

---

Связанные файлы конфигурации:
- `home/common/kwin-rules.nix` — правила назначения на столы
- `home/common/karousel.nix` — тайлинг внутри столов
- `~/.config/kwinrulesrc` — генерируемый файл (NEVER редактировать вручную)
