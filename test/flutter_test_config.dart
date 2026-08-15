import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  if (Platform.environment['PROPERTY_SHOT_GOLDEN_MODE'] == 'structure') {
    final current = goldenFileComparator;
    if (current is! LocalFileComparator) {
      throw StateError(
        'structure Golden mode requires LocalFileComparator, '
        'but found ${current.runtimeType}.',
      );
    }
    goldenFileComparator = _StructuralGoldenComparator(current);
  }
  await testMain();
}

/// Keeps every Golden test and render path active on Linux while avoiding
/// platform-specific font rasterization comparisons against macOS baselines.
///
/// The committed baseline must exist and both PNGs must have the same canvas
/// size. Exact pixel comparison remains the default everywhere else.
final class _StructuralGoldenComparator extends GoldenFileComparator {
  _StructuralGoldenComparator(this._delegate);

  final LocalFileComparator _delegate;

  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    final goldenFile = File.fromUri(_delegate.basedir.resolveUri(golden));
    if (!goldenFile.existsSync()) {
      throw TestFailure('Golden baseline does not exist: $golden');
    }
    final baselineBytes = await goldenFile.readAsBytes();
    final actualSize = _pngSize(imageBytes, label: 'rendered image');
    final baselineSize = _pngSize(baselineBytes, label: 'Golden $golden');
    if (actualSize != baselineSize) {
      throw TestFailure(
        'Golden canvas size changed for $golden: '
        '${baselineSize.width}x${baselineSize.height} -> '
        '${actualSize.width}x${actualSize.height}.',
      );
    }
    return true;
  }

  @override
  Uri getTestUri(Uri key, int? version) =>
      _delegate.getTestUri(key, version);

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) =>
      _delegate.update(golden, imageBytes);
}

({int width, int height}) _pngSize(List<int> bytes, {required String label}) {
  const signature = <int>[137, 80, 78, 71, 13, 10, 26, 10];
  if (bytes.length < 24 ||
      !Iterable<int>.generate(signature.length).every(
        (index) => bytes[index] == signature[index],
      )) {
    throw TestFailure('$label is not a valid PNG file.');
  }
  int readUint32(int offset) =>
      (bytes[offset] << 24) |
      (bytes[offset + 1] << 16) |
      (bytes[offset + 2] << 8) |
      bytes[offset + 3];
  return (width: readUint32(16), height: readUint32(20));
}
