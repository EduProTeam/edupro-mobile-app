import 'package:flutter/material.dart';

import '../../../posts/services/post_service.dart';

const _blue = Color(0xFF167BFF);
const _ink = Color(0xFF0A1638);
const _muted = Color(0xFF727D95);

class HomeFeedHeader extends StatelessWidget {
  const HomeFeedHeader({
    super.key,
    required this.search,
    required this.userName,
    this.imageUrl,
    this.onProfile,
    this.onSaved,
  });
  final Widget search;
  final String userName;
  final String? imageUrl;
  final VoidCallback? onProfile;
  final VoidCallback? onSaved;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final brand = Semantics(
        label: 'EduPro',
        image: true,
        child: ClipRect(
          child: SizedBox(
            width: 110,
            height: 34,
            child: OverflowBox(
              maxWidth: 137,
              maxHeight: 77,
              child: Image.asset(
                'assets/images/edupro_graduation_logo.png',
                width: 137,
                height: 77,
                excludeFromSemantics: true,
              ),
            ),
          ),
        ),
      );
      final actions = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onSaved != null)
            IconButton(
              tooltip: 'Saved posts',
              onPressed: onSaved,
              icon: const Icon(
                Icons.bookmark_border_rounded,
                size: 22,
                color: _ink,
              ),
              visualDensity: VisualDensity.compact,
            ),
          if (onProfile != null)
            IconButton(
              tooltip: 'Open your profile',
              onPressed: onProfile,
              icon: HomeUserAvatar(
                name: userName,
                imageUrl: imageUrl,
                radius: 16,
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      );
      if (constraints.maxWidth < 340 ||
          MediaQuery.textScalerOf(context).scale(12) > 17) {
        return Column(
          children: [
            Row(children: [brand, const Spacer(), actions]),
            const SizedBox(height: 8),
            search,
          ],
        );
      }
      return Row(
        children: [
          brand,
          const SizedBox(width: 10),
          Expanded(child: search),
          actions,
        ],
      );
    },
  );
}

class HomeLearningBanner extends StatelessWidget {
  const HomeLearningBanner({super.key});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(20),
    child: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [Color(0xFFEBF4FF), Color(0xFFB4D4FF), Color(0xFF79ADFF)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 16, 8, 16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final largeText = MediaQuery.textScalerOf(context).scale(12) > 18;
            return Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LEARN  ·  SHARE  ·  GROW',
                        style: TextStyle(
                          color: Color(0xFF4A6FAD),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Semantics(
                        header: true,
                        child: const Text(
                          'A Community\nfor Better Learning',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            height: 1.12,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Share knowledge, get help, and learn together with EduPro.',
                        style: TextStyle(
                          color: Color(0xFF526787),
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!largeText) ...[
                  const SizedBox(width: 4),
                  Expanded(
                    flex: 4,
                    child: Image.asset(
                      'assets/images/home_learning_books.png',
                      height: constraints.maxWidth < 300 ? 125 : 136,
                      fit: BoxFit.contain,
                      cacheWidth: 384,
                      excludeFromSemantics: true,
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

class HomePostComposer extends StatelessWidget {
  const HomePostComposer({
    super.key,
    required this.userName,
    required this.onCreate,
    this.imageUrl,
  });
  final String userName;
  final String? imageUrl;
  final ValueChanged<PostAttachmentType?> onCreate;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFF0F3F8)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x081C3A62),
          blurRadius: 14,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      children: [
        Row(
          children: [
            HomeUserAvatar(name: userName, imageUrl: imageUrl, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Material(
                color: const Color(0xFFF5F8FD),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                  side: const BorderSide(color: Color(0xFFE4EBF6)),
                ),
                child: InkWell(
                  onTap: () => onCreate(null),
                  borderRadius: BorderRadius.circular(28),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 13, vertical: 13),
                    child: Text(
                      'Share your knowledge, question or idea...',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final compact =
                constraints.maxWidth < 330 ||
                MediaQuery.textScalerOf(context).scale(12) > 16;
            const attachments = [
              (
                PostAttachmentType.image,
                Icons.image_rounded,
                'Photo',
                Color(0xFF2494FF),
              ),
              (
                PostAttachmentType.video,
                Icons.videocam_rounded,
                'Video',
                Color(0xFF9D56FF),
              ),
              (
                PostAttachmentType.file,
                Icons.description_rounded,
                'File',
                Color(0xFFFFAF1A),
              ),
              (
                PostAttachmentType.link,
                Icons.link_rounded,
                'Link',
                Color(0xFF00BD8D),
              ),
            ];
            return Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 6,
              spacing: 2,
              children: [
                for (final (type, icon, label, color) in attachments)
                  if (compact)
                    IconButton(
                      tooltip: label,
                      onPressed: () => onCreate(type),
                      icon: Icon(icon, color: color, size: 22),
                    )
                  else
                    TextButton.icon(
                      onPressed: () => onCreate(type),
                      icon: Icon(icon, color: color, size: 18),
                      label: Text(label),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF415475),
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        minimumSize: const Size(0, 40),
                        textStyle: Theme.of(
                          context,
                        ).textTheme.labelMedium?.copyWith(fontSize: 11),
                      ),
                    ),
                FilledButton.icon(
                  onPressed: () => onCreate(null),
                  icon: const Icon(Icons.send_rounded, size: 17),
                  label: const Text('Post'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 13),
                    minimumSize: const Size(0, 40),
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );
}

class HomeUserAvatar extends StatelessWidget {
  const HomeUserAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.radius = 18,
  });
  final String name;
  final String? imageUrl;
  final double radius;

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
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFE5F1FF),
      child: Text(
        initials,
        style: TextStyle(
          color: _blue,
          fontWeight: FontWeight.w700,
          fontSize: radius * 0.66,
        ),
      ),
    );
    return imageUrl == null
        ? fallback
        : ClipOval(
            child: Image.network(
              imageUrl!,
              width: radius * 2,
              height: radius * 2,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => fallback,
            ),
          );
  }
}
