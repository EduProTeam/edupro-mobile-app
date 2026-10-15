import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/theme/app_colors.dart';

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
    colorMapper: context.appColors.isDark
        ? const EduProDarkColorMapper()
        : null,
    width: size,
    height: size,
    semanticsLabel: 'EduPro',
  );
}

/// Keeps the navy SVG details legible while retaining its blue/cyan artwork.
class EduProDarkColorMapper extends ColorMapper {
  const EduProDarkColorMapper();

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color == const Color(0xFF0B2544)) return const Color(0xFFD9E8FF);
    if (color == const Color(0xFF071D37)) return const Color(0xFFB1C8EB);
    if (color == const Color(0xFF09223F)) return const Color(0xFFCBDFFF);
    return color;
  }
}

class EduProWordmark extends StatelessWidget {
  const EduProWordmark({super.key, this.fontSize = 22});

  final double fontSize;

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        TextSpan(
          text: 'Edu',
          style: TextStyle(
            color: context.appColors.isDark
                ? context.appColors.textPrimary
                : EduProBrand.navy,
          ),
        ),
        const TextSpan(
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
