import 'package:flutter/material.dart';

const _blue = Color(0xFF167BFF);
const _ink = Color(0xFF090D31);
const _muted = Color(0xFF72778F);

/// The profile layout, kept independent of authentication and data loading.
class ProfileDashboard extends StatelessWidget {
  const ProfileDashboard({
    super.key,
    required this.name,
    required this.title,
    required this.skills,
    required this.interests,
    this.onSettings,
    this.onPhoto,
    this.onEdit,
    this.onShare,
    this.onAddSkill,
    this.onAddInterest,
    this.readOnly = false,
    this.organization,
    this.email,
    this.bio,
    this.imageUrl,
    this.postCount = 0,
    this.courseCount = 0,
    this.onRetryPostCount,
    this.postLibrary,
  });

  final String name;
  final String title;
  final String? organization;
  final String? email;
  final String? bio;
  final String? imageUrl;
  final List<String> skills;
  final List<String> interests;
  final int? postCount;
  final int courseCount;
  final VoidCallback? onRetryPostCount;
  final Widget? postLibrary;
  final bool readOnly;
  final VoidCallback? onSettings;
  final VoidCallback? onPhoto;
  final VoidCallback? onEdit;
  final VoidCallback? onShare;
  final VoidCallback? onAddSkill;
  final VoidCallback? onAddInterest;

  @override
  Widget build(BuildContext context) {
    final displayBio = readOnly && (bio == null || bio!.trim().isEmpty)
        ? 'No bio added yet.'
        : bio ?? 'Add a bio to tell the community about yourself.';
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _BrandHeader(onSettings: readOnly ? null : onSettings),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: CustomPaint(
                      painter: const _ProfileBackdrop(),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                        child: Column(
                          children: [
                            _ProfileAvatar(
                              name: name,
                              imageUrl: imageUrl,
                              onPhoto: readOnly ? null : onPhoto,
                            ),
                            const SizedBox(height: 12),
                            Semantics(
                              header: true,
                              child: Text(
                                name,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.6,
                                ),
                              ),
                            ),
                            const SizedBox(height: 9),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF4FF),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    color: _blue,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      title,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        color: _blue,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (organization != null || email != null) ...[
                              const SizedBox(height: 10),
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 12,
                                runSpacing: 6,
                                children: [
                                  if (organization != null)
                                    _ContactDetail(
                                      icon: Icons.account_balance_outlined,
                                      text: organization!,
                                    ),
                                  if (email != null)
                                    _ContactDetail(
                                      icon: Icons.mail_outline_rounded,
                                      text: email!,
                                    ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 12),
                            Text(
                              displayBio,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: _muted,
                                fontSize: 12.5,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _SurfaceCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 14,
                    ),
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _StatItem(
                            value: postCount,
                            label: 'Posts',
                            icon: Icons.article_outlined,
                            color: _blue,
                            background: const Color(0xFFEAF5FF),
                            onRetry: onRetryPostCount,
                          ),
                          const _StatDivider(),
                          _StatItem(
                            value: skills.length,
                            label: 'Skills',
                            icon: Icons.lightbulb_outline_rounded,
                            color: const Color(0xFF8247FF),
                            background: const Color(0xFFF2ECFF),
                          ),
                          const _StatDivider(),
                          _StatItem(
                            value: courseCount,
                            label: 'Courses',
                            icon: Icons.menu_book_rounded,
                            color: const Color(0xFF00B678),
                            background: const Color(0xFFE9F9F1),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!readOnly && (onEdit != null || onShare != null)) ...[
                    const SizedBox(height: 12),
                    _ProfileActions(onEdit: onEdit, onShare: onShare),
                  ],
                  const SizedBox(height: 14),
                  _TagSection(
                    title: readOnly ? 'Skills' : 'My Skills',
                    action: 'Add Skill',
                    values: skills,
                    emptyText: 'No skills added yet',
                    onAdd: readOnly ? null : onAddSkill,
                  ),
                  const SizedBox(height: 12),
                  _TagSection(
                    title: 'Learning Interests',
                    action: 'Add Interest',
                    values: interests,
                    emptyText: 'No learning interests selected yet',
                    onAdd: readOnly ? null : onAddInterest,
                  ),
                  if (postLibrary != null) ...[
                    const SizedBox(height: 22),
                    postLibrary!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({this.onSettings});
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 5),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Display the supplied logo without its surrounding white margins.
        Semantics(
          label: 'EduPro',
          image: true,
          child: ClipRect(
            child: SizedBox(
              width: 154,
              height: 44,
              child: OverflowBox(
                maxWidth: 192,
                maxHeight: 108,
                child: Image.asset(
                  'assets/images/edupro_graduation_logo.png',
                  width: 192,
                  height: 108,
                  excludeFromSemantics: true,
                ),
              ),
            ),
          ),
        ),
        if (onSettings != null)
          IconButton.filledTonal(
            onPressed: onSettings,
            tooltip: 'Settings',
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFEEF4FF),
              foregroundColor: _ink,
              fixedSize: const Size(40, 40),
            ),
            icon: const Icon(Icons.settings_outlined, size: 24),
          ),
      ],
    ),
  );
}

class _ProfileBackdrop extends CustomPainter {
  const _ProfileBackdrop();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF0F5FF), Colors.white],
          stops: [0, 0.95],
        ).createShader(rect),
    );

    final leftRibbon = Path()
      ..moveTo(0, size.height * 0.12)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.25,
        -size.width * 0.1,
        size.height * 0.32,
        size.width * 0.15,
        size.height * 0.45,
      )
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.57,
        size.width * 0.04,
        size.height * 0.63,
        0,
        size.height * 0.70,
      )
      ..close();
    canvas.drawPath(
      leftRibbon,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFD3E5FF), Color(0x00ECF5FF)],
        ).createShader(rect),
    );

    final rightRibbon = Path()
      ..moveTo(size.width, size.height * 0.06)
      ..cubicTo(
        size.width * 0.87,
        size.height * 0.20,
        size.width * 0.63,
        size.height * 0.25,
        size.width * 0.84,
        size.height * 0.40,
      )
      ..cubicTo(
        size.width * 0.98,
        size.height * 0.50,
        size.width * 0.70,
        size.height * 0.51,
        size.width,
        size.height * 0.66,
      )
      ..close();
    canvas.drawPath(
      rightRibbon,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [Color(0xFF87B4FF), Color(0x00E8F2FF)],
          stops: [0, 0.7],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(_ProfileBackdrop oldDelegate) => false;
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.name,
    required this.imageUrl,
    this.onPhoto,
  });
  final String name;
  final String? imageUrl;
  final VoidCallback? onPhoto;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part.characters.first)
        .join()
        .toUpperCase();
    final placeholder = ColoredBox(
      color: const Color(0xFFE5F1FF),
      child: Center(
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: _blue,
          ),
        ),
      ),
    );
    return SizedBox(
      width: 106,
      height: 100,
      child: Stack(
        children: [
          Container(
            width: 98,
            height: 98,
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1F182C57),
                  blurRadius: 16,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: ClipOval(
              child: imageUrl == null
                  ? placeholder
                  : Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      width: 90,
                      height: 90,
                      errorBuilder: (_, _, _) => placeholder,
                    ),
            ),
          ),
          if (onPhoto != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: IconButton.filled(
                onPressed: onPhoto,
                tooltip: 'Change profile photo',
                style: IconButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(36, 36),
                  padding: const EdgeInsets.all(9),
                ),
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
              ),
            ),
        ],
      ),
    );
  }
}

class _ContactDetail extends StatelessWidget {
  const _ContactDetail({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: const EdgeInsets.all(5),
        decoration: const BoxDecoration(
          color: Color(0xFFEBF4FF),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 15, color: _blue),
      ),
      const SizedBox(width: 5),
      Flexible(
        child: Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
      ),
    ],
  );
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
  });
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFF5F6F8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x0F182C57),
          blurRadius: 14,
          offset: Offset(0, 3),
        ),
      ],
    ),
    child: child,
  );
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.background,
    this.onRetry,
  });
  final int? value;
  final String label;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: background, shape: BoxShape.circle),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(height: 4),
        if (onRetry != null)
          IconButton(
            tooltip: 'Retry post count',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, color: _muted),
          )
        else
          Text(
            value?.toString() ?? '—',
            style: const TextStyle(
              color: _ink,
              fontSize: 19,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
      ],
    ),
  );
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(vertical: 5),
    child: VerticalDivider(width: 1, color: Color(0xFFE7EAF2)),
  );
}

class _ProfileActions extends StatelessWidget {
  const _ProfileActions({this.onEdit, this.onShare});
  final VoidCallback? onEdit;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );
    final edit = onEdit == null
        ? null
        : FilledButton(
            onPressed: onEdit,
            style: FilledButton.styleFrom(
              backgroundColor: _blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              shape: shape,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const _ActionLabel(
              icon: Icons.edit_rounded,
              label: 'Edit Profile',
            ),
          );
    final share = onShare == null
        ? null
        : OutlinedButton(
            onPressed: onShare,
            style: OutlinedButton.styleFrom(
              foregroundColor: _blue,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 13),
              side: const BorderSide(color: _blue),
              shape: shape,
              textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const _ActionLabel(
              icon: Icons.share_outlined,
              label: 'Share Profile',
            ),
          );
    if (edit == null) return share ?? const SizedBox.shrink();
    if (share == null) return edit;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 20) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [edit, const SizedBox(height: 8), share],
          );
        }
        return Row(
          children: [
            Expanded(child: edit),
            const SizedBox(width: 8),
            Expanded(child: share),
          ],
        );
      },
    );
  }
}

class _ActionLabel extends StatelessWidget {
  const _ActionLabel({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 8),
      Flexible(child: Text(label, textAlign: TextAlign.center)),
    ],
  );
}

class _TagSection extends StatelessWidget {
  const _TagSection({
    required this.title,
    required this.action,
    required this.values,
    required this.emptyText,
    this.onAdd,
  });
  final String title;
  final String action;
  final List<String> values;
  final String emptyText;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) => _SurfaceCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final heading = Semantics(
              header: true,
              child: Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            );
            if (onAdd == null) return heading;
            final addButton = TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle, size: 16),
              label: Text(action),
              style: TextButton.styleFrom(
                foregroundColor: _blue,
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 6),
                minimumSize: const Size(0, 36),
                textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
            if (constraints.maxWidth < 290 ||
                MediaQuery.textScalerOf(context).scale(17) > 22) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [heading, addButton],
              );
            }
            return Row(
              children: [
                Expanded(child: heading),
                addButton,
              ],
            );
          },
        ),
        const SizedBox(height: 4),
        if (values.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              emptyText,
              style: const TextStyle(color: _muted, fontSize: 12.5),
            ),
          )
        else
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values.map((value) => _ColorTag(label: value)).toList(),
          ),
      ],
    ),
  );
}

class _ColorTag extends StatelessWidget {
  const _ColorTag({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final style = _TagStyle.forLabel(label);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label.toLowerCase() == 'flutter')
            const FlutterLogo(size: 20)
          else
            Icon(style.icon, color: style.color, size: 19),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: style.textColor,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagStyle {
  const _TagStyle(this.icon, this.color, this.background, this.textColor);
  final IconData icon;
  final Color color;
  final Color background;
  final Color textColor;

  static _TagStyle forLabel(String label) {
    final value = label.toLowerCase();
    if (value.contains('design') || value.contains('ui/ux')) {
      return const _TagStyle(
        Icons.palette_rounded,
        Color(0xFF8043F7),
        Color(0xFFF3EDFF),
        Color(0xFF5522B9),
      );
    }
    if (value.contains('html') ||
        value.contains('intelligence') ||
        value == 'ai') {
      return _TagStyle(
        value.contains('html') ? Icons.html_rounded : Icons.memory_rounded,
        const Color(0xFFED474D),
        const Color(0xFFFFEEEE),
        const Color(0xFFAD2028),
      );
    }
    if (value.contains('firebase') || value.contains('trend')) {
      return _TagStyle(
        value.contains('firebase')
            ? Icons.local_fire_department_rounded
            : Icons.trending_up_rounded,
        const Color(0xFFFFAC00),
        const Color(0xFFFFF8E3),
        const Color(0xFF80500D),
      );
    }
    if (value.contains('web') || value.contains('problem')) {
      return _TagStyle(
        value.contains('web')
            ? Icons.language_rounded
            : Icons.psychology_outlined,
        const Color(0xFF00B678),
        const Color(0xFFEAF9F1),
        const Color(0xFF174C3A),
      );
    }
    return _TagStyle(
      value.contains('mobile')
          ? Icons.phone_android_rounded
          : value.contains('dart')
          ? Icons.diamond_rounded
          : Icons.auto_awesome_outlined,
      _blue,
      const Color(0xFFE8F4FF),
      const Color(0xFF123866),
    );
  }
}
