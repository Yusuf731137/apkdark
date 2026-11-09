import 'dart:io';
import 'dart:typed_data';

class WaveformService {
  /// Extract normalized peaks [0..1] from a WAV file.
  /// Returns null for non-WAV or unreadable files.
  static Future<List<double>?> extractPeaks(
    File file, {
    int points = 200,
  }) async {
    try {
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      return parseWavPeaks(bytes, points);
    } catch (_) {
      return null;
    }
  }

  static List<double>? parseWavPeaks(Uint8List bytes, int targetPoints) {
    if (bytes.length < 44) return null;

    // Check RIFF
    if (bytes[0] != 0x52 ||
        bytes[1] != 0x49 ||
        bytes[2] != 0x46 ||
        bytes[3] != 0x46) {
      return null;
    }
    // Check WAVE
    if (bytes[8] != 0x57 ||
        bytes[9] != 0x41 ||
        bytes[10] != 0x56 ||
        bytes[11] != 0x45) {
      return null;
    }

    final bd = ByteData.sublistView(bytes);
    int offset = 12;
    int? dataOffset;
    int? dataSize;
    int? bitsPerSample;
    int? numChannels;

    while (offset + 8 <= bytes.length) {
      final chunkId =
          String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = bd.getUint32(offset + 4, Endian.little);

      if (chunkId == 'fmt ') {
        final audioFormat = bd.getUint16(offset + 8, Endian.little);
        if (audioFormat != 1) return null; // Only PCM
        numChannels = bd.getUint16(offset + 10, Endian.little);
        bitsPerSample = bd.getUint16(offset + 22, Endian.little);
      } else if (chunkId == 'data') {
        dataOffset = offset + 8;
        dataSize = chunkSize;
        break;
      }

      offset += 8 + chunkSize;
      if (chunkSize.isOdd) offset++;
    }

    if (dataOffset == null ||
        dataSize == null ||
        numChannels == null ||
        bitsPerSample != 16) {
      return null;
    }

    final totalBytes = bytes.length;
    if (dataOffset + dataSize > totalBytes) {
      dataSize = totalBytes - dataOffset;
    }

    final sampleCount = dataSize ~/ 2;
    if (sampleCount <= 0) return List.filled(targetPoints, 0.0);

    final samplesPerPoint = (sampleCount / targetPoints).ceil();
    if (samplesPerPoint < 1) return List.filled(targetPoints, 0.0);

    final peaks = <double>[];
    int maxAbs = 0;

    for (int pt = 0; pt < targetPoints; pt++) {
      int peak = 0;
      final start = pt * samplesPerPoint;
      final end = ((pt + 1) * samplesPerPoint).clamp(0, sampleCount);
      for (int i = start; i < end; i++) {
        final bytePos = dataOffset + i * 2;
        if (bytePos + 2 > totalBytes) break;
        final sample = bd.getInt16(bytePos, Endian.little);
        final abs = sample.abs();
        if (abs > peak) peak = abs;
      }
      peaks.add(peak.toDouble());
      if (peak > maxAbs) maxAbs = peak;
    }

    if (maxAbs == 0) return List.filled(targetPoints, 0.0);
    return peaks.map((v) => v / maxAbs).toList();
  }
}