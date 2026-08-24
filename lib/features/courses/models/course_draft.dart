class CourseDraft {
  CourseDraft({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.currency,
    required this.price,
    required this.applyDiscount,
    required this.couponCode,
    required this.thumbnailPath,
    required this.promoVideoPath,
    required this.modules,
    required this.status,
  });

  final String id;
  final String title;
  final String category;
  final String description;
  final String currency;
  final String price;
  final bool applyDiscount;
  final String couponCode;
  final String thumbnailPath;
  final String promoVideoPath;
  final List<CourseModule> modules;
  final CourseStatus status;
}

class CourseModule {
  CourseModule({
    required this.title,
    required this.lessons,
  });

  final String title;
  final List<CourseLesson> lessons;
}

class CourseLesson {
  CourseLesson({
    required this.title,
    required this.duration,
    required this.videoPath,
  });

  final String title;
  final String duration;
  final String videoPath;
}

enum CourseStatus {
  draft,
  published,
}
