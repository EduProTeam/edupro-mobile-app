import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

abstract final class EduProBrand {
  static const icon = 'assets/images/edupro-icon.svg';
  static const letterE = 'assets/branding/generated/letter-e.svg';
  static const letterP = 'assets/branding/generated/letter-p.svg';
  static const cap = 'assets/branding/generated/cap.svg';
  static const tassel = 'assets/branding/generated/tassel.svg';
  static const navy = Color(0xFF0B2544);
  static const blue = Color(0xFF087CF0);
}

class EduProMark extends StatelessWidget {
  const EduProMark({super.key, this.size = 44});

  final double size;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
    EduProBrand.icon,
    width: size,
    height: size,
    semanticsLabel: 'EduPro',
  );
}

class EduProWordmark extends StatelessWidget {
  const EduProWordmark({super.key, this.fontSize = 22});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Text.rich(
    const TextSpan(
      children: [
        TextSpan(
          text: 'Edu',
          style: TextStyle(color: EduProBrand.navy),
        ),
        TextSpan(
          text: 'Pro',
          style: TextStyle(color: EduProBrand.blue),
        ),
      ],
    ),
    style: TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: -fontSize * 0.03,
    ),
  );
}
