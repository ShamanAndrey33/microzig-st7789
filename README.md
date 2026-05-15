# MicroZig ST7789 Driver for RP2040

[RU] Драйвер для дисплея ST7789 (240x240) на Zig для RP2040.  
[EN] Zig driver for ST7789 (240x240) on RP2040.

---

## 🇷🇺 Описание
### API:
* `init()` — Настройка пинов.
* `begin()` — Инициализация экрана.
* `clear(color)` — Заливка цветом RGB565.
* `drawString(x, y, text, color, size)` — Вывод текста (размер `size`).

---

## 🇺🇸 Description
### API:
* `init()` — Pin configuration.
* `begin()` — Display startup.
* `clear(color)` — RGB565 fill.
* `drawString(x, y, text, color, size)` — Text rendering (with `size` scale).

---

## 🛠 Hardware / Подключение
| ST7789 | RP2040 |
| :--- | :--- |
| SCL | GP18 |
| SDA | GP19 |
| RES | GP20 |
| DC  | GP21 |

## 🚀 Build
```bash
zig build
