const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const st7789 = @import("st7789.zig");

pub fn main() !void {
    const spi = rp2xxx.spi.instance.SPI0;

    try spi.apply(.{
        .clock_config = rp2xxx.clock_config,
        .baud_rate = 40_000_000,
        .data_width = .eight,
        .frame_format = .{
            .motorola = .{
                .clock_polarity = .default_high,
                .clock_phase = .second_edge,
            },
        },
    });

    var display = st7789.ST7789.init(.{
        .spi_inst = spi,
        .sck = 18,
        .mosi = 19,
        .rst = 20,
        .dc = 21,
        .blk = 13,
    });

    try display.begin();

    display.fillScreen(0x0000); // Очистка

    // Вывод текста
    var last_value: i32 = -1;
    var current_value: i32 = 0;

    // Координаты текста
    const txt_x: u16 = 20;
    const txt_y: u16 = 100;
    const txt_size: u8 = 2;

    while (true) {
        if (current_value != last_value) {
            // 1. Сначала затираем старое значение
            // Ширина: допустим число не длиннее 5 знаков -> (5 символов * 6 пикс) * size = 60
            // Высота: 8 пикс * size = 16
            display.fillRect(txt_x, txt_y, 60 * txt_size, 8 * txt_size, 0x0000);

            // 2. Печатаем новое значение
            var buf: [16]u8 = undefined;
            const str = std.fmt.bufPrint(&buf, "{d}", .{current_value}) catch "Err";

            display.drawString(txt_x, txt_y, str, 0xFFFF, txt_size);

            last_value = current_value;
        }

        current_value += 1;
        rp2xxx.time.sleep_ms(300); // 10 раз в секунду — мерцания не будет
    }
}
