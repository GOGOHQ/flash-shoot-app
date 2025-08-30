import 'package:flutter/material.dart';

/// 构图辅助线类型
enum GridType {
  none,          // 不显示
  ruleOfThirds,  // 九宫格（三分法）
  diagonals,     // 对角线
  cross,         // 十字线
  goldenRatio,   // 黄金比例
}

class GridPainter extends CustomPainter {
  final GridType gridType;

  GridPainter({required this.gridType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 1;

    switch (gridType) {
      case GridType.none:
        // 什么都不画
        break;

      case GridType.ruleOfThirds:
        _drawRuleOfThirds(canvas, size, paint);
        break;

      case GridType.diagonals:
        _drawDiagonals(canvas, size, paint);
        break;

      case GridType.cross:
        _drawCross(canvas, size, paint);
        break;

      case GridType.goldenRatio:
        _drawGoldenRatio(canvas, size, paint);
        break;
    }
  }

  void _drawRuleOfThirds(Canvas canvas, Size size, Paint paint) {
    final double thirdWidth = size.width / 3;
    final double thirdHeight = size.height / 3;

    for (int i = 1; i < 3; i++) {
      // 竖线
      canvas.drawLine(
        Offset(thirdWidth * i, 0),
        Offset(thirdWidth * i, size.height),
        paint,
      );
      // 横线
      canvas.drawLine(
        Offset(0, thirdHeight * i),
        Offset(size.width, thirdHeight * i),
        paint,
      );
    }
  }

  void _drawDiagonals(Canvas canvas, Size size, Paint paint) {
    // 左上 → 右下
    canvas.drawLine(Offset(0, 0), Offset(size.width, size.height), paint);
    // 右上 → 左下
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  void _drawCross(Canvas canvas, Size size, Paint paint) {
    // 中心竖线
    canvas.drawLine(
      Offset(size.width / 2, 0),
      Offset(size.width / 2, size.height),
      paint,
    );
    // 中心水平线
    canvas.drawLine(
      Offset(0, size.height / 2),
      Offset(size.width, size.height / 2),
      paint,
    );
  }

  void _drawGoldenRatio(Canvas canvas, Size size, Paint paint) {
    const phi = 0.618; // 黄金比例
    final vertical = size.width * phi;
    final horizontal = size.height * phi;

    // 竖线
    canvas.drawLine(Offset(vertical, 0), Offset(vertical, size.height), paint);
    // 横线
    canvas.drawLine(Offset(0, horizontal), Offset(size.width, horizontal), paint);
  }

  @override
  bool shouldRepaint(covariant GridPainter oldDelegate) {
    return oldDelegate.gridType != gridType;
  }
}
