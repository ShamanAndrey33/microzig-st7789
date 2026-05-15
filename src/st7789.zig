const std = @import("std");
const microzig = @import("microzig");
const rp2xxx = microzig.hal;
const font = @import("font.zig");

pub const ST7789 = struct {
    spi: @TypeOf(rp2xxx.spi.instance.SPI0),
    dc_pin: rp2xxx.gpio.Pin,
    rst_pin: rp2xxx.gpio.Pin,
    blk_pin: ?rp2xxx.gpio.Pin,

    rowstart: u16 = 0,
    colstart: u16 = 0,
    width: u16 = 240,
    height: u16 = 240,

    const Self = @This();

    pub const Config = struct {
        spi_inst: @TypeOf(rp2xxx.spi.instance.SPI0),
        sck: u6,
        mosi: u6,
        rst: u6,
        dc: u6,
        blk: ?u6 = null,
    };

    pub fn init(comptime config: Config) Self {
        const sck_p = rp2xxx.gpio.num(config.sck);
        const mosi_p = rp2xxx.gpio.num(config.mosi);
        sck_p.set_function(.spi);
        mosi_p.set_function(.spi);

        const dc_p = rp2xxx.gpio.num(config.dc);
        dc_p.set_function(.sio);
        dc_p.set_direction(.out);
        dc_p.put(1);

        const rst_p = rp2xxx.gpio.num(config.rst);
        rst_p.set_function(.sio);
        rst_p.set_direction(.out);
        rst_p.put(1);

        var blk: ?rp2xxx.gpio.Pin = null;
        if (config.blk) |blk_num| {
            const b = rp2xxx.gpio.num(blk_num);
            b.set_function(.sio);
            b.set_direction(.out);
            b.put(1);
            blk = b;
        }

        return .{
            .spi = config.spi_inst,
            .dc_pin = dc_p,
            .rst_pin = rst_p,
            .blk_pin = blk,
        };
    }

    pub fn sendCommand(self: *Self, cmd: u8, args: []const u8) void {
        self.dc_pin.put(0);
        self.spi.write_blocking(u8, &[_]u8{cmd});
        if (args.len > 0) {
            self.dc_pin.put(1);
            self.spi.write_blocking(u8, args);
        }
    }

    pub fn begin(self: *Self) !void {
        self.rst_pin.put(0);
        rp2xxx.time.sleep_ms(100);
        self.rst_pin.put(1);
        rp2xxx.time.sleep_ms(200);

        self.sendCommand(0x01, &.{}); // SW Reset
        rp2xxx.time.sleep_ms(150);
        self.sendCommand(0x11, &.{}); // Sleep Out
        rp2xxx.time.sleep_ms(120);
        self.sendCommand(0x3A, &.{0x55}); // 16-bit
        self.sendCommand(0x36, &.{0x00}); // MADCTL
        self.sendCommand(0x21, &.{}); // Inversion ON
        self.sendCommand(0x13, &.{}); // Normal
        self.sendCommand(0x29, &.{}); // Display ON
        rp2xxx.time.sleep_ms(50);
    }

    pub fn setAddrWindow(self: *Self, x: u16, y: u16, w: u16, h: u16) void {
        const x0 = x + self.colstart;
        const x1 = x0 + w - 1;
        const y0 = y + self.rowstart;
        const y1 = y0 + h - 1;

        self.sendCommand(0x2A, &[_]u8{ @intCast(x0 >> 8), @intCast(x0 & 0xFF), @intCast(x1 >> 8), @intCast(x1 & 0xFF) });
        self.sendCommand(0x2B, &[_]u8{ @intCast(y0 >> 8), @intCast(y0 & 0xFF), @intCast(y1 >> 8), @intCast(y1 & 0xFF) });
        self.sendCommand(0x2C, &.{});
    }

    pub fn fillRect(self: *Self, x: u16, y: u16, w: u16, h: u16, color: u16) void {
        self.setAddrWindow(x, y, w, h);
        self.dc_pin.put(1);

        const hi: u8 = @intCast(color >> 8);
        const lo: u8 = @intCast(color & 0xFF);
        var line: [480]u8 = undefined;
        var i: usize = 0;
        while (i < line.len) : (i += 2) {
            line[i] = hi;
            line[i + 1] = lo;
        }

        const total_pixels = @as(u32, w) * @as(u32, h);
        var pixels_sent: u32 = 0;
        while (pixels_sent < total_pixels) {
            const remaining = total_pixels - pixels_sent;
            const to_send = if (remaining > 240) 240 else remaining;
            self.spi.write_blocking(u8, line[0 .. to_send * 2]);
            pixels_sent += to_send;
        }
    }

    pub fn fillScreen(self: *Self, color: u16) void {
        self.fillRect(0, 0, self.width, self.height, color);
    }

    pub fn clear(self: *Self, color: u16) void {
        self.fillScreen(color);
    }

    pub fn drawChar(self: *Self, x: u16, y: u16, char: u8, color: u16, size: u8) void {
        if (char < 32 or char > 126) return;
        const index = char - 32;
        const bitmap = font.font5x7[index];

        var i: u16 = 0;
        while (i < 5) : (i += 1) {
            var col_data = bitmap[i];
            var j: u16 = 0;
            while (j < 8) : (j += 1) {
                if ((col_data & 0x01) != 0) {
                    self.fillRect(x + i * size, y + j * size, size, size, color);
                }
                col_data >>= 1;
            }
        }
    }

    pub fn drawString(self: *Self, x: u16, y: u16, text: []const u8, color: u16, size: u8) void {
        var curr_x = x;
        for (text) |char| {
            self.drawChar(curr_x, y, char, color, size);
            curr_x += 6 * size;
        }
    }
};
