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

    while (true) {
        display.clear(0xF800);
        rp2xxx.time.sleep_ms(500);

        display.clear(0x07E0);
        rp2xxx.time.sleep_ms(500);

        display.clear(0x0000);
        display.drawString(10, 10, "ST7789 Test", 0xFFFF, 2);
        display.drawString(10, 50, "MicroZig 0.15.1", 0x07E0, 2);
        display.drawString(10, 90, "Status: OK", 0x5D1F, 2);

        rp2xxx.time.sleep_ms(2000);
    }
}
