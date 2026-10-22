const std = @import("std");

/// Represents a 0-based source position within an input buffer.
/// - `index`: 0-based byte offset into `raw`.
/// - `line`: 0-based line number.
/// - `column`: 0-based UTF-8 codepoint column offset on the current line.
///
/// When formatted with `{f}`, outputs 1-based `<line>:<column>` for editor/compiler compatibility.
pub const Location = struct {
    index: usize = 0,
    line: usize = 0,
    column: usize = 0,

    /// Advances `index` by `raw.len` bytes and `column` by the number of UTF-8 codepoints in `raw`.
    pub fn advance(self: *Location, raw: []const u8) void {
        self.index += raw.len;
        self.column += codepointCount(raw);
    }

    /// Advances `index` by `newline_raw.len` bytes, increments `line` by 1, and resets `column` to 0.
    pub fn advanceLine(self: *Location, newline_raw: []const u8) void {
        self.index += newline_raw.len;
        self.line += 1;
        self.column = 0;
    }

    pub fn format(self: Location, writer: *std.Io.Writer) std.Io.Writer.Error!void {
        try writer.print("{d}:{d}", .{ self.line + 1, self.column + 1 });
    }
};

/// Returns the number of UTF-8 codepoints in `raw`, treating any invalid byte sequence as 1 column.
pub fn codepointCount(raw: []const u8) usize {
    var count: usize = 0;
    var index: usize = 0;
    while (index < raw.len) {
        const len = codepointByteLength(raw[index..]);
        index += len;
        count += 1;
    }
    return count;
}

/// Returns the byte length of the first UTF-8 codepoint in `raw` (clamped to `raw.len`),
/// falling back to `1` if `raw[0]` is not a valid UTF-8 leading byte.
pub fn codepointByteLength(raw: []const u8) usize {
    if (raw.len == 0) return 0;
    const cp_len = std.unicode.utf8ByteSequenceLength(raw[0]) catch 1;
    return @min(cp_len, raw.len);
}
