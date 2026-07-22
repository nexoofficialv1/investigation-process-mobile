import 'package:flutter/material.dart';

import '../core/app_theme.dart';

class IntroScreen extends StatelessWidget {
  final VoidCallback onStart;

  const IntroScreen({
    super.key,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
          child: Column(
            children: <Widget>[
              const Spacer(),
              const _InvestigoLogo(size: 132),
              const SizedBox(height: 24),
              const Text(
                'ইনভেস্টিগো —\nতদন্ত সহায়ক',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 38,
                  height: 1.18,
                  letterSpacing: 1.1,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.deepGreen,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Investigation Process Manager',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.3,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Smart Forms • Fast Investigation • Secure & Paperless',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.35,
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const <BoxShadow>[
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: const Column(
                  children: <Widget>[
                    _IntroLine(
                      icon: Icons.manage_search_rounded,
                      text: 'SOP guided investigation workflow',
                    ),
                    _IntroLine(
                      icon: Icons.description_rounded,
                      text: 'Official forms with point wise entry',
                    ),
                    _IntroLine(
                      icon: Icons.picture_as_pdf_rounded,
                      text: 'Preview, print, PDF and DOC export',
                    ),
                    _IntroLine(
                      icon: Icons.offline_bolt_rounded,
                      text: 'Offline-first with backend sync ready',
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Start'),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '© Astra Technologies',
                style: TextStyle(
                  color: AppTheme.deepGreen,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InvestigoLogo extends StatelessWidget {
  final double size;

  const _InvestigoLogo({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[
            Color(0xFF003E34),
            Color(0xFF006B57),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * .28),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Colors.black26,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _InvestigoLogoPainter(),
      ),
    );
  }
}

class _InvestigoLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final gold = Paint()
      ..color = AppTheme.gold
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .035
      ..strokeJoin = StrokeJoin.round;

    final white = Paint()..color = Colors.white;
    final dark = Paint()..color = AppTheme.deepGreen;

    final glass = Paint()
      ..color = const Color(0xFFE8FFF8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .045;

    final shield = Path()
      ..moveTo(size.width * .50, size.height * .16)
      ..lineTo(size.width * .78, size.height * .29)
      ..quadraticBezierTo(
        size.width * .74,
        size.height * .68,
        size.width * .50,
        size.height * .84,
      )
      ..quadraticBezierTo(
        size.width * .26,
        size.height * .68,
        size.width * .22,
        size.height * .29,
      )
      ..close();

    canvas.drawPath(shield, gold);

    final paper = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * .34,
        size.height * .30,
        size.width * .31,
        size.height * .38,
      ),
      Radius.circular(size.width * .035),
    );
    canvas.drawRRect(paper, white);

    final line = Paint()
      ..color = AppTheme.deepGreen.withOpacity(.80)
      ..strokeWidth = size.width * .02
      ..strokeCap = StrokeCap.round;

    for (final y in <double>[.40, .49, .58]) {
      canvas.drawLine(
        Offset(size.width * .40, size.height * y),
        Offset(size.width * .58, size.height * y),
        line,
      );
    }

    canvas.drawCircle(
      Offset(size.width * .67, size.height * .62),
      size.width * .12,
      glass,
    );
    canvas.drawLine(
      Offset(size.width * .75, size.height * .71),
      Offset(size.width * .85, size.height * .81),
      glass,
    );

    final pen = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * .025
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(size.width * .70, size.height * .25),
      Offset(size.width * .74, size.height * .48),
      pen,
    );
    canvas.drawCircle(
      Offset(size.width * .70, size.height * .25),
      size.width * .018,
      white,
    );
    canvas.drawCircle(
      Offset(size.width * .73, size.height * .47),
      size.width * .018,
      dark,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _IntroLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _IntroLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.cream,
            child: Icon(
              icon,
              color: AppTheme.deepGreen,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
