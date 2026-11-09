import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class WaveformWidget extends StatelessWidget {
  final List<double> peaks;
  final double progress; // 0.0 - 1.0
  final VoidCallback? onSeek;
  final double height;
  const WaveformWidget({
    super.key,
    required this.peaks,
    required this.progress,
    this.onSeek,
    this.height = 60,
  });

  @override
  Widget build(BuildContext context) {
    if (peaks.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text(
            '—',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: GestureDetector(
        onTap: onSeek,
        child: CustomPaint(
          painter: _WaveformPainter(
            peaks: peaks,
            progress: progress.clamp(0.0, 1.0),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _WaveformPainter extends CustomPainter {
  final List<double> peaks;
  final double progress;
  _WaveformPainter({required this.peaks, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final barWidth = size.width / peaks.length;
    final midY = size.height / 2;
    final playedPaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = barWidth * 0.7
      ..strokeCap = StrokeCap.round;
    final unplayedPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = barWidth * 0.7
      ..strokeCap = StrokeCap.round;

    final playedBars = (progress * peaks.length).floor();

    for (int i = 0; i < peaks.length; i++) {
      final h = (peaks[i].clamp(0.0, 1.0)) * (size.height - 4);
      final x = i * barWidth + barWidth / 2;
      final paint = i <= playedBars ? playedPaint : unplayedPaint;
      canvas.drawLine(
        Offset(x, midY - h / 2),
        Offset(x, midY + h / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.peaks != peaks;
}