// Run from the repository root: flutter test tool/generate_brand_assets.dart
// Uses the same SVG renderer as the app. All outputs are checked in; ordinary
// builds do not need an extra generator or a third-party image executable.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('Generate native and Flutter brand assets from the approved SVG', () async {
    final source = File('assets/images/edupro-icon.svg').readAsStringSync();
    final info = await vg.loadPicture(SvgStringLoader(source), null);
    try {
      // These are build-time exports of the source groups, never independently
      // edited or parsed at app startup. Retain all gradients and coordinates.
      final groups = RegExp(
        r'<g\b[^>]*id="([^"]+)"[^>]*>[\s\S]*?</g>',
      ).allMatches(source).toList();
      expect(groups.map((g) => g.group(1)).toSet(), {
        'letter-e',
        'letter-p',
        'cap',
        'tassel',
      });
      for (final group in groups) {
        final layer = source.replaceAllMapped(
          RegExp(r'<g\b[^>]*id="([^"]+)"[^>]*>[\s\S]*?</g>'),
          (match) => match.group(1) == group.group(1) ? match.group(0)! : '',
        );
        _writeText('assets/branding/generated/${group.group(1)}.svg', layer);
      }

      const densities = {
        'mdpi': 1.0,
        'hdpi': 1.5,
        'xhdpi': 2.0,
        'xxhdpi': 3.0,
        'xxxhdpi': 4.0,
      };
      for (final density in densities.entries) {
        final res = 'android/app/src/main/res';
        final mipmap = '$res/mipmap-${density.key}';
        await _writeIcon(
          info,
          '$mipmap/ic_launcher.png',
          (48 * density.value).round(),
        );
        // The complete artwork fits inside Android's central 66/108 safe zone.
        await _writeIcon(
          info,
          '$mipmap/ic_launcher_foreground.png',
          (108 * density.value).round(),
          fraction: 0.60,
          opaque: false,
        );
        await _writeIcon(
          info,
          '$mipmap/ic_launcher_monochrome.png',
          (108 * density.value).round(),
          fraction: 0.60,
          opaque: false,
          monochrome: true,
        );
        await _writeIcon(
          info,
          '$res/drawable-${density.key}/ic_stat_edupro.png',
          (24 * density.value).round(),
          fraction: 1,
          opaque: false,
          monochrome: true,
        );
      }

      for (final platform in ['ios', 'macos']) {
        final catalog = '$platform/Runner/Assets.xcassets/AppIcon.appiconset';
        final data =
            jsonDecode(File('$catalog/Contents.json').readAsStringSync())
                as Map<String, dynamic>;
        final seen = <String>{};
        for (final item in data['images'] as List) {
          final name = item['filename'] as String?;
          if (name == null || !seen.add(name)) continue;
          final size = double.parse((item['size'] as String).split('x').first);
          final scale = double.parse(
            (item['scale'] as String).replaceAll('x', ''),
          );
          await _writeIcon(info, '$catalog/$name', (size * scale).round());
        }
      }

      for (final size in [192, 512]) {
        await _writeIcon(info, 'web/icons/Icon-$size.png', size);
        await _writeIcon(
          info,
          'web/icons/Icon-maskable-$size.png',
          size,
          fraction: 0.78,
        );
      }
      await _writeIcon(info, 'web/icons/apple-touch-icon.png', 180);
      await _writeIcon(info, 'web/favicon.png', 32);
      await _writeIcon(info, 'linux/runner/resources/edupro-icon.png', 256);
      await _writeIco(info, 'windows/runner/resources/app_icon.ico');
      await _writeIcon(info, 'build/branding/launcher-preview.png', 512);
    } finally {
      info.picture.dispose();
    }
  });
}

void _writeText(String path, String content) {
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

Future<void> _writeIcon(
  PictureInfo info,
  String path,
  int size, {
  double fraction = 0.84,
  bool opaque = true,
  bool monochrome = false,
}) async {
  final bytes = await _render(
    info,
    size,
    fraction: fraction,
    opaque: opaque,
    monochrome: monochrome,
  );
  final file = File(path)..parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
}

Future<Uint8List> _render(
  PictureInfo info,
  int size, {
  double fraction = 0.84,
  bool opaque = true,
  bool monochrome = false,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  if (opaque) canvas.drawColor(const ui.Color(0xFFFFFFFF), ui.BlendMode.src);
  final scale = size * fraction / info.size.longestSide;
  canvas.translate(
    (size - info.size.width * scale) / 2,
    (size - info.size.height * scale) / 2,
  );
  canvas.scale(scale);
  if (monochrome) {
    canvas.saveLayer(
      null,
      ui.Paint()
        ..colorFilter = const ui.ColorFilter.mode(
          ui.Color(0xFFFFFFFF),
          ui.BlendMode.srcIn,
        ),
    );
  }
  canvas.drawPicture(info.picture);
  if (monochrome) canvas.restore();
  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  try {
    if (opaque) {
      // Apple requires no alpha channel, even when every alpha value is 255.
      final rgba = (await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      return _rgbPng(rgba.buffer.asUint8List(), size);
    }
    return (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
  } finally {
    image.dispose();
    picture.dispose();
  }
}

Uint8List _rgbPng(Uint8List rgba, int size) {
  final rows = BytesBuilder();
  for (var y = 0; y < size; y++) {
    rows.addByte(0); // PNG filter: None.
    for (var x = 0; x < size; x++) {
      final i = (y * size + x) * 4;
      rows.add(rgba.sublist(i, i + 3));
    }
  }
  final header = ByteData(13)
    ..setUint32(0, size)
    ..setUint32(4, size)
    ..setUint8(8, 8)
    ..setUint8(9, 2); // Truecolor RGB, no alpha.
  return (BytesBuilder()
        ..add([137, 80, 78, 71, 13, 10, 26, 10])
        ..add(_chunk('IHDR', header.buffer.asUint8List()))
        ..add(_chunk('IDAT', zlib.encode(rows.takeBytes())))
        ..add(_chunk('IEND', [])))
      .takeBytes();
}

Uint8List _chunk(String name, List<int> data) {
  final content = [...ascii.encode(name), ...data];
  var crc = 0xFFFFFFFF;
  for (final byte in content) {
    crc ^= byte;
    for (var bit = 0; bit < 8; bit++) {
      crc = (crc >> 1) ^ ((crc & 1) != 0 ? 0xEDB88320 : 0);
    }
  }
  return (BytesBuilder()
        ..add((ByteData(4)..setUint32(0, data.length)).buffer.asUint8List())
        ..add(content)
        ..add(
          (ByteData(4)..setUint32(0, crc ^ 0xFFFFFFFF)).buffer.asUint8List(),
        ))
      .takeBytes();
}

Future<void> _writeIco(PictureInfo info, String path) async {
  const sizes = [16, 24, 32, 48, 64, 128, 256];
  final images = <Uint8List>[];
  for (final size in sizes) {
    images.add(await _render(info, size));
  }
  final header = ByteData(6 + sizes.length * 16)
    ..setUint16(2, 1, Endian.little)
    ..setUint16(4, sizes.length, Endian.little);
  var offset = header.lengthInBytes;
  for (var i = 0; i < sizes.length; i++) {
    final entry = 6 + i * 16;
    header
      ..setUint8(entry, sizes[i] % 256)
      ..setUint8(entry + 1, sizes[i] % 256)
      ..setUint16(entry + 4, 1, Endian.little)
      ..setUint16(entry + 6, 32, Endian.little)
      ..setUint32(entry + 8, images[i].length, Endian.little)
      ..setUint32(entry + 12, offset, Endian.little);
    offset += images[i].length;
  }
  final bytes = BytesBuilder()..add(header.buffer.asUint8List());
  images.forEach(bytes.add);
  File(path).writeAsBytesSync(bytes.takeBytes());
}
