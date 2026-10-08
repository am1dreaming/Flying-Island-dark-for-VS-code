<div align="center">

# 🏝️ Flying Island

### Плавающие острова и настоящее стекло окна для VS Code.

Скруглённые острова · нативное размытие macOS / Windows 11 · тема Darcula Contrast · подсветка C/C++ через clangd.
Без сторонних утилит — одно расширение и скрипт установки.
<br/>


<img src="https://img.shields.io/badge/Windows-10%20%2F%2011-0078D6?logo=windows&logoColor=white" />
<img src="https://img.shields.io/badge/macOS-vibrancy-000000?logo=apple&logoColor=white" />
<img src="https://img.shields.io/badge/VS%20Code-1.85%2B-007ACC?logo=visualstudiocode&logoColor=white" />
<img src="https://img.shields.io/badge/license-MIT-3fb950" />
<br>

<br/>
<!-- Превью: положи картинку, например docs/preview.png, и раскомментируй строку ниже -->
<!-- <img src="docs/preview.png" width="80%" alt="Flying Island — превью" /> -->
<br/>
<sub>Острова со скруглёнными углами · стекло в зазорах · сплошные панели поверх размытия.</sub>
<br/><br/>

**Установка — одна команда из папки проекта:**

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

<sub>

[✨ Возможности](#-возможности) | [⚡ Быстрый старт](#-быстрый-старт) | [⚙️ Настройки](#️-настройки) | [🧩 Как это работает](#-как-это-работает) | [🩹 Решение проблем](#-решение-проблем) | [🧹 Удаление](#-удаление)

</sub>

</div>

---



## ✨ Возможности

<table>
<tr>
<td width="50%" valign="top">

**🏝️ Плавающие острова**
- Проводник, редакторы, терминал и чат — отдельные скруглённые острова
- Каждая группа разделённого редактора — свой остров
- Зазоры, радиус и отступы от краёв окна настраиваются
- Вкладка-«таблетка» с обводкой, как в New UI

</td>
<td width="50%" valign="top">

**🪟 Настоящее стекло**
- macOS: системный vibrancy (`under-window`, `sidebar`, `hud`)
- Windows 11: Acrylic, Mica или Tabbed
- Размытие видно в зазорах, заголовке и строке состояния
- Острова остаются сплошными, плотность стекла регулируется

</td>
</tr>
<tr>
<td width="50%" valign="top">

**🎨 Тема Flying Island Dark**
- Цвета из открытых исходников IntelliJ Platform (Islands + Darcula Contrast)
- 371 цвет интерфейса, правила TextMate и semantic tokens
- C/C++: макросы, поля и типы различаются через clangd
- Шрифты JetBrains Mono и Inter в комплекте

</td>
<td width="50%" valign="top">

**⚙️ Работает само**
- Патч заново применяется после обновлений VS Code
- Ставится во все профили VS Code сразу
- Сам переносит настройки со старой версии «Islands Dark»
- Команда **Remove All Patches** возвращает VS Code в исходный вид

</td>
</tr>
</table>

---

## ⚡ Быстрый старт

Скачай репозиторий (**Code → Download ZIP**) и распакуй в любую папку.

**Windows** — открой PowerShell в этой папке:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

**macOS** — в Терминале из этой папки:

```bash
./install.sh
```

Установщик делает всё сам:

> Ставит шрифты **JetBrains Mono** и **Inter** (только для текущего пользователя) · упаковывает и устанавливает расширение во все профили VS Code · ставит **clangd** и пак иконок **JetBrains Icon Theme** · добавляет настройки темы в `settings.json` (копия старых — `settings.json.bak-islands`) · удаляет старое расширение «Islands Dark (CLion)», если оно было. Запускать повторно безопасно.

Когда установка закончится: **полностью закрой VS Code → открой снова → нажми «Reload Window»** в уведомлении Flying Island. На Windows 11 VS Code попросит перезапуститься ещё раз, чтобы включить стекло. ✨

<details>
<summary><b>Установка только расширения, без скрипта</b></summary>

1. Собери пакет: `python3 tools/pack_vsix.py` → появится `dist/flying-island-<версия>.vsix`.
2. В VS Code: **Extensions → ⋯ → Install from VSIX…** и выбери этот файл.
3. Выбери тему **Flying Island Dark** (`Ctrl+K Ctrl+T`).
4. Выполни команду **Flying Island: Apply** и нажми **Reload Window**.

Шрифты и настройки в этом случае не ставятся.

</details>

---

## ⚙️ Настройки

Все настройки — в разделе **Flying Island** окна настроек VS Code. После изменения расширение само предложит перезагрузить окно.

**Геометрия островов** (в пикселях):

| Настройка | По умолчанию | Что задаёт |
|---|---|---|
| `flyingIsland.gap` | `4` (0–16) | зазор между соседними островами |
| `flyingIsland.radius` | `10` (0–20) | скругление углов |
| `flyingIsland.margin.top` | `0` (0–16) | отступ от заголовка окна |
| `flyingIsland.margin.right` | `7` (0–16) | отступ от правого края окна |
| `flyingIsland.margin.bottom` | `4` (0–6) | отступ над строкой состояния |
| `flyingIsland.margin.left` | `0` (0–16) | отступ от полосы иконок слева |

**Стекло:**

| Настройка | Значения |
|---|---|
| `flyingIsland.vibrancy` | `off` · macOS: `under-window`, `sidebar`, `hud` · Windows 11: `acrylic`, `mica`, `tabbed` |
| `flyingIsland.vibrancyOpacity` | `0.3`–`1`, по умолчанию `0.4` (меньше — прозрачнее) |

> 💡 После смены **материала** стекла VS Code нужно закрыть и открыть заново. После смены **плотности** или геометрии хватит Reload Window.

<details>
<summary><b>Свои цвета поверх темы</b></summary>

Пересобирать ничего не нужно — стандартные настройки VS Code работают поверх темы:

```jsonc
"workbench.colorCustomizations": {
  "[Flying Island Dark]": { "editor.background": "#1B1C1F" }
},
"editor.tokenColorCustomizations": {
  "[Flying Island Dark]": { "comments": "#7A7E85" }
},
"editor.semanticTokenColorCustomizations": {
  "[Flying Island Dark]": { "rules": { "macro": "#908B25" } }
}
```

</details>

---

## 🧩 Как это работает

VS Code не умеет ни острова, ни стекло, поэтому расширение при запуске аккуратно дополняет два файла самого VS Code и следит, чтобы правки пережили обновления.

```
┌────────────────────┐           ┌─────────────────────────┐
│  Flying Island     │  стили    │  workbench.html          │  острова, зазоры, радиус,
│  extension.js      │ ────────▶ │  + css/islands.css       │  стекло в зазорах
│  (при запуске)     │           └─────────────────────────┘
│                    │  окно     ┌─────────────────────────┐
│                    │ ────────▶ │  mainImpl.js             │  vibrancy (macOS)
└────────────────────┘           │  + хук создания окна     │  acrylic / mica (Windows 11)
                                 └─────────────────────────┘
```

Материал стекла хранится в `~/.flying-island/vibrancy.json`, поэтому его смена не требует повторного патча. Оригиналы файлов VS Code сохраняются рядом с ними с расширением `.bak-islands`.

---

## 📦 Требования

| | Windows | macOS |
|---|---|---|
| **VS Code** | User Installer (в `%LOCALAPPDATA%\Programs`) | в папке `/Applications` |
| **Стекло** | Windows 11 22H2+, включены эффекты прозрачности | выключено «Уменьшить прозрачность» |
| **Для установки** | ничего — только PowerShell | Xcode Command Line Tools (`xcode-select --install`) |
| **Для C/C++** | компилятор (LLVM, MinGW или MSVC) | clangd из Command Line Tools |

На Windows 10 острова работают, а окно просто остаётся сплошным.

---

## 🩹 Решение проблем

<details>
<summary>Нет островов и скруглений</summary>

- **Windows:** VS Code установлен через System Installer в `Program Files`, куда расширение не может писать. Переустанови VS Code через **User Installer**.
- **macOS:** VS Code запущен из «Загрузок». macOS открывает его из защищённой копии — перетащи VS Code в `/Applications`.
- Выполни команду **Flying Island: Apply** и посмотри, нет ли сообщения об ошибке.

</details>

<details>
<summary>VS Code пишет «Your Code installation appears to be corrupt»</summary>

Так VS Code реагирует на любое изменение своих файлов — это ожидаемо. Уведомление можно скрыть кнопкой с шестерёнкой.

</details>

<details>
<summary>Стекло серое или его нет</summary>

- **Windows:** включи «Параметры → Персонализация → Цвета → Эффекты прозрачности».
- **macOS:** выключи «Универсальный доступ → Дисплей → Уменьшить прозрачность».
- После смены материала VS Code нужно **полностью закрыть** и открыть снова.
- Утилиты вроде MicaForEveryone конфликтуют с расширением — добавь `Code.exe` в их исключения.

</details>

<details>
<summary>После обновления VS Code всё пропало</summary>

Обновление заменяет файлы VS Code. Расширение повторит патч при следующем запуске и предложит перезагрузить окно — просто нажми кнопку в уведомлении.

</details>

<details>
<summary>Стили ломаются вместе с другими расширениями</summary>

**Custom CSS and JS Loader** и **Apc Customize UI++** тоже правят `workbench.html`. Не используй их вместе с Flying Island.

</details>

<details>
<summary>На Windows clangd ищет <code>/usr/bin/clangd</code></summary>

Это настройка, прилетевшая с Mac через Settings Sync. Удали строку `"clangd.path"` из настроек Windows.

</details>

---

## 🧹 Удаление

1. В VS Code выполни **Flying Island: Remove All Patches** и перезапусти VS Code.
2. Верни настройки из копии и удали расширение:

```bash
# macOS (на Windows файл лежит в %APPDATA%\Code\User\)
cp ~/Library/Application\ Support/Code/User/settings.json.bak-islands ~/Library/Application\ Support/Code/User/settings.json
code --uninstall-extension yaroslav.flying-island
```

Шрифты, clangd и пак иконок остаются — их можно удалить отдельно.

---

## 📁 Структура проекта

```
flying-island/
├── install.ps1 · install.sh          установка (Windows / macOS)
├── extension.js                      патчер: острова + стекло, миграция со старой версии
├── package.json                      манифест расширения и настройки
├── css/
│   ├── islands.css                   геометрия островов
│   └── vibrancy.css                  прозрачные края окна поверх размытия
├── themes/
│   └── flying-island-dark-color-theme.json   готовая цветовая тема
├── settings/settings.jsonc           настройки, которые добавляет установщик
├── fonts/                            JetBrains Mono, Inter + тексты лицензий OFL
├── tools/pack_vsix.py                упаковка в .vsix без node/vsce
└── LICENSE · NOTICE · licenses/      лицензии и атрибуция
```

## ⚖️ Лицензии

Код проекта — **MIT** (`LICENSE`). Цвета темы получены из [IntelliJ Community](https://github.com/JetBrains/intellij-community) (Apache 2.0), шрифты распространяются по **SIL OFL 1.1**. Подробности — в `NOTICE`.

---

<div align="center">

**Flying Island** — made with 🩵 by **Yaroslav**

<sub>MIT License · не связан с JetBrains и Microsoft и не одобрен ими</sub>

⭐ *Если понравилось — поставь звезду репозиторию.*

</div>
