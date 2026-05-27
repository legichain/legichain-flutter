/// On-device image-quality pre-flight gate.
///
/// Stop the SDK from uploading useless frames — saves bandwidth, saves
/// attempt counters, improves UX. Two checks:
///
///   * [checkBlur] — Laplacian variance over a small random sample.
///     Below `blurThreshold` (default 100.0) → reject.
///   * [detectMrzLines] — visual MRZ pattern hint. Returns the matched
///     line text or null. Use it before uploading the data page of a
///     passport / EU national ID.
///
/// The Laplacian variance impl is pure Dart (works on any byte buffer
/// regardless of platform). For production, swap in a GPU shader
/// (Metal / Vulkan via `flutter_gpu`) when you target every frame.
library;

import 'dart:math';
import 'dart:typed_data';

import '../errors.dart';

class ImageQualityGate {
  final double blurThreshold;
  final int sampleCount;

  const ImageQualityGate({
    this.blurThreshold = 100.0,
    this.sampleCount = 512,
  });

  /// Runs every check. Returns null on pass, or a short reason string
  /// for the caller to surface in the UI.
  String? evaluate({
    required Uint8List grayscale,
    required int width,
    required int height,
  }) {
    if (width < 800 || height < 600) return 'image_too_small';
    final variance =
        _laplacianVariance(grayscale, width, height, samples: sampleCount);
    if (variance < blurThreshold) return 'image_blurred';
    return null;
  }

  /// Convenience wrapper that throws instead of returning null.
  void mustPass({
    required Uint8List grayscale,
    required int width,
    required int height,
  }) {
    final reason = evaluate(
      grayscale: grayscale,
      width: width,
      height: height,
    );
    if (reason != null) throw LegichainCaptureRejected(reason);
  }

  /// Approximate Laplacian variance over a random pixel sample.
  /// `bytes` must be a single-channel grayscale buffer of size
  /// `width * height`.
  static double _laplacianVariance(
    Uint8List bytes,
    int width,
    int height, {
    int samples = 512,
  }) {
    if (bytes.length < width * height || width < 3 || height < 3) return 0;
    final rng = Random();
    final vals = <double>[];
    vals.length = samples;
    for (var i = 0; i < samples; i++) {
      final x = 1 + rng.nextInt(width - 2);
      final y = 1 + rng.nextInt(height - 2);
      final c = bytes[y * width + x];
      final up = bytes[(y - 1) * width + x];
      final dn = bytes[(y + 1) * width + x];
      final lf = bytes[y * width + x - 1];
      final rt = bytes[y * width + x + 1];
      vals[i] = (4 * c - up - dn - lf - rt).toDouble();
    }
    final mean = vals.reduce((a, b) => a + b) / vals.length;
    var sumSq = 0.0;
    for (final v in vals) {
      final d = v - mean;
      sumSq += d * d;
    }
    return sumSq / vals.length;
  }

  /// Look for ICAO MRZ patterns (chains of OCR-B chars `[A-Z0-9<]`).
  /// Returns the longest run of MRZ-style lines if at least two
  /// consecutive lines match; otherwise null.
  ///
  /// Pre-OCR pattern check — pair this with platform OCR
  /// (`google_mlkit_text_recognition`, Apple Vision) to get real text.
  static String? detectMrzLines(List<String> ocrLines) {
    final stripped =
        ocrLines.map((l) => l.replaceAll(' ', '')).toList(growable: false);
    final mrz = <String>[];
    for (final line in stripped) {
      if (line.length < 30) {
        if (mrz.length >= 2) break;
        mrz.clear();
        continue;
      }
      final isMrz = RegExp(r'^[A-Z0-9<]+$').hasMatch(line);
      if (isMrz) {
        mrz.add(line);
      } else if (mrz.length >= 2) {
        break;
      } else {
        mrz.clear();
      }
    }
    if (mrz.length < 2) return null;
    return mrz.join('\n');
  }
}
