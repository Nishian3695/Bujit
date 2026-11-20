// Writes an image as an RGB PNG (no alpha channel). The App Store rejects
// screenshots and creative assets with transparency, and Flutter's own PNG
// encoder always writes RGBA.
import 'dart:io';
import 'dart:typed_data';

Uint8List encodeRgbPng(Uint8List rgba, int width, int height) {
    // Each row: filter type 0 (none), then the pixels' red, green and blue.
    final Uint8List raw = Uint8List(height * (1 + width * 3));
    int out = 0;
    for (int y = 0; y < height; y++) {
        raw[out++] = 0;
        int i = y * width * 4;
        for (int x = 0; x < width; x++, i += 4) {
            raw[out++] = rgba[i];
            raw[out++] = rgba[i + 1];
            raw[out++] = rgba[i + 2];
        }
    }

    final BytesBuilder png = BytesBuilder(copy: false)
        ..add(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A]);
    final ByteData header = ByteData(13)
        ..setUint32(0, width)
        ..setUint32(4, height)
        ..setUint8(8, 8) // Bits per channel
        ..setUint8(9, 2); // Color type 2: RGB (compression, filter, interlace stay 0)
    _chunk(png, "IHDR", header.buffer.asUint8List());
    _chunk(png, "IDAT", Uint8List.fromList(ZLibCodec(level: 6).encode(raw)));
    _chunk(png, "IEND", Uint8List(0));
    return png.takeBytes();
}

void _chunk(BytesBuilder png, String type, Uint8List data) {
    final Uint8List typeBytes = Uint8List.fromList(type.codeUnits);
    png.add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List());
    png.add(typeBytes);
    png.add(data);
    final int crc = _crc32(data, _crc32(typeBytes, 0xFFFFFFFF)) ^ 0xFFFFFFFF;
    png.add((ByteData(4)..setUint32(0, crc)).buffer.asUint8List());
}

final List<int> _crcTable = List.generate(256, (n) {
    int c = n;
    for (int k = 0; k < 8; k++) {
        c = (c & 1) != 0 ? 0xEDB88320 ^ (c >> 1) : c >> 1;
    }
    return c;
});

// Continues a CRC-32 over [bytes] (start with 0xFFFFFFFF, finish with ^ 0xFFFFFFFF).
int _crc32(Uint8List bytes, int crc) {
    for (final int b in bytes) {
        crc = _crcTable[(crc ^ b) & 0xFF] ^ (crc >> 8);
    }
    return crc;
}
