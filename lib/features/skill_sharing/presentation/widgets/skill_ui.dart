import 'package:flutter/material.dart';

import '../../models/skill_models.dart';

abstract final class SkillColors {
  static const primary = Color(0xFF1674EA);
  static const navy = Color(0xFF061638);
  static const secondary = Color(0xFF52617E);
  static const border = Color(0xFFDCE4EF);
  static const paleBlue = Color(0xFFEDF5FF);
  static const green = Color(0xFF0AA34F);
  static const orange = Color(0xFFF59A0A);
}

class SkillPage extends StatelessWidget {
  const SkillPage({
    super.key,
    required this.child,
    this.appBar,
    this.bottomNavigationBar,
    this.safeTop = true,
  });

  final Widget child;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final bool safeTop;

  @override
  Widget build(BuildContext context) {
    final content = ColoredBox(color: Colors.white, child: child);
    return Theme(
      data: Theme.of(context).copyWith(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: Theme.of(context).colorScheme.copyWith(
          primary: SkillColors.primary,
          surface: Colors.white,
        ),
        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: SkillColors.navy,
          displayColor: SkillColors.navy,
        ),
      ),
      child: Scaffold(
        appBar: appBar,
        bottomNavigationBar: bottomNavigationBar,
        body: safeTop && appBar == null ? SafeArea(child: content) : content,
      ),
    );
  }
}

class SkillAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SkillAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions = const <Widget>[],
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Size get preferredSize => Size.fromHeight(subtitle == null ? 72 : 94);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      toolbarHeight: preferredSize.height,
      iconTheme: const IconThemeData(color: SkillColors.navy, size: 28),
      titleSpacing: Navigator.canPop(context) ? 0 : 20,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle!,
              style: const TextStyle(
                color: SkillColors.secondary,
                fontSize: 15,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }
}

class SkillCard extends StatelessWidget {
  const SkillCard({
    super.key,
    required this.child,
    this.padding,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor ?? SkillColors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10061A3A),
            blurRadius: 14,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.initials,
    required this.color,
    this.radius = 28,
    this.online = true,
  });

  final String initials;
  final Color color;
  final double radius;
  final bool online;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: radius * 2 + 4,
      height: radius * 2 + 4,
      child: Stack(
        children: [
          CircleAvatar(
            radius: radius,
            backgroundColor: color,
            child: Text(
              initials,
              style: TextStyle(
                color: SkillColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: radius * .52,
              ),
            ),
          ),
          if (online)
            Positioned(
              right: 0,
              bottom: 2,
              child: Container(
                width: radius * .42,
                height: radius * .42,
                decoration: BoxDecoration(
                  color: SkillColors.green,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class BlueButton extends StatelessWidget {
  const BlueButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.outlined = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool outlined;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: compact ? 18 : 21),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? 13 : 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
    );
    if (outlined) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(0, compact ? 42 : 50),
          padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
          foregroundColor: SkillColors.primary,
          side: const BorderSide(color: SkillColors.primary),
          shape: shape,
        ),
        child: child,
      );
    }
    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        minimumSize: Size(0, compact ? 42 : 50),
        padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 16),
        backgroundColor: SkillColors.primary,
        disabledBackgroundColor: const Color(0xFF9DC6F8),
        shape: shape,
      ),
      child: child,
    );
  }
}

class SoftTag extends StatelessWidget {
  const SoftTag({super.key, required this.label, this.icon, this.color});

  final String label;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? SkillColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: foreground.withValues(alpha: .09),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              color: foreground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.text, this.green = false});

  final String text;
  final bool green;

  @override
  Widget build(BuildContext context) {
    final color = green ? SkillColors.green : SkillColors.primary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(
            green ? Icons.verified_user_outlined : Icons.info_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: TextStyle(color: color, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }
}

class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level});

  final SkillLevel level;

  @override
  Widget build(BuildContext context) {
    final isIntermediate = level == SkillLevel.intermediate;
    final color = isIntermediate ? SkillColors.orange : SkillColors.green;
    final label = switch (level) {
      SkillLevel.beginner => 'Beginner',
      SkillLevel.intermediate => 'Intermediate',
      SkillLevel.advanced => 'Advanced',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }
}

class LabeledIconInfo extends StatelessWidget {
  const LabeledIconInfo({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: SkillColors.primary, size: 23),
        const SizedBox(width: 9),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: SkillColors.secondary,
                  fontSize: 11,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(
                      value,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: 5),
                    trailing!,
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

String formatSkillDate(DateTime date) {
  const months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
