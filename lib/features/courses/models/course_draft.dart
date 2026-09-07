enum CourseStatus { draft, published }

enum CourseType { free, paid }

class CourseMedia {
  const CourseMedia({
    required this.name,
    required this.path,
    required this.url,
  });
  final String name, path, url;
  Map<String, dynamic> toMap() => {'name': name, 'path': path, 'url': url};
  factory CourseMedia.fromMap(Map<String, dynamic> data) => CourseMedia(
    name: data['name'] as String? ?? '',
    path: data['path'] as String? ?? '',
    url: data['url'] as String? ?? '',
  );
}

class CourseLesson {
  CourseLesson({
    required this.id,
    required this.title,
    this.description = '',
    this.duration = '',
    this.video,
    List<CourseMedia> materials = const [],
  }) : materials = List.unmodifiable(materials);
  final String id, title, description, duration;
  final CourseMedia? video;
  final List<CourseMedia> materials;
  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'duration': duration,
    'video': video?.toMap(),
    'materials': materials.map((m) => m.toMap()).toList(),
  };
  factory CourseLesson.fromMap(Map<String, dynamic> data) => CourseLesson(
    id: data['id'] as String? ?? '',
    title: data['title'] as String? ?? '',
    description: data['description'] as String? ?? '',
    duration: data['duration'] as String? ?? '',
    video: data['video'] is Map
        ? CourseMedia.fromMap(Map<String, dynamic>.from(data['video'] as Map))
        : null,
    materials: (data['materials'] as List? ?? [])
        .map((m) => CourseMedia.fromMap(Map<String, dynamic>.from(m as Map)))
        .toList(),
  );
}

class CourseDraft {
  CourseDraft({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.language,
    required this.type,
    required this.currency,
    required this.price,
    required this.status,
    required List<CourseLesson> lessons,
    this.thumbnail,
    this.instructorName = '',
    this.level = 'Beginner',
    this.rating = 0,
    this.totalDuration = '',
    this.userId = '',
    this.updatedAt = 0,
    this.createdAt = 0,
    this.enrollmentCount = 0,
  }) : lessons = List.unmodifiable(lessons);
  final String id, title, category, description, language, currency, userId;
  final String instructorName, level, totalDuration;
  final double price;
  final double rating;
  final CourseType type;
  final CourseStatus status;
  final CourseMedia? thumbnail;
  final List<CourseLesson> lessons;
  final int updatedAt;
  final int createdAt;
  final int enrollmentCount;
  Map<String, dynamic> toMap() => {
    'title': title,
    'category': category,
    'description': description,
    'language': language,
    'type': type.name,
    'currency': currency,
    'price': type == CourseType.free ? 0 : price,
    'status': status.name,
    'thumbnail': thumbnail?.toMap(),
    'instructorName': instructorName,
    'level': level,
    'rating': rating,
    'totalDuration': totalDuration,
    'lessons': lessons.map((l) => l.toMap()).toList(),
    'userId': userId,
    'schemaVersion': 2,
  };
  factory CourseDraft.fromMap(
    String id,
    Map<String, dynamic> data, {
    int updatedAt = 0,
    int createdAt = 0,
  }) {
    final rawLessons = data['lessons'] as List? ?? [];
    final price = double.tryParse('${data['price'] ?? 0}') ?? 0;
    return CourseDraft(
      id: id,
      title: data['title'] as String? ?? '',
      category: data['category'] as String? ?? '',
      description: data['description'] as String? ?? '',
      language: data['language'] as String? ?? '',
      currency: data['currency'] as String? ?? 'USD',
      instructorName: data['instructorName'] as String? ?? '',
      level: data['level'] as String? ?? 'Beginner',
      rating: double.tryParse('${data['rating'] ?? 0}') ?? 0,
      totalDuration: data['totalDuration'] as String? ?? '',
      type: data['type'] == 'paid' ? CourseType.paid : CourseType.free,
      price: price,
      status: data['status'] == 'published'
          ? CourseStatus.published
          : CourseStatus.draft,
      userId: data['userId'] as String? ?? '',
      updatedAt: updatedAt,
      createdAt: createdAt,
      enrollmentCount: (data['enrollmentCount'] as num?)?.toInt() ?? 0,
      thumbnail: data['thumbnail'] is Map
          ? CourseMedia.fromMap(
              Map<String, dynamic>.from(data['thumbnail'] as Map),
            )
          : null,
      lessons: rawLessons
          .map((l) => CourseLesson.fromMap(Map<String, dynamic>.from(l as Map)))
          .toList(),
    );
  }
}

String lessonLabel(int index) =>
    'Lesson ${(index + 1).toString().padLeft(2, '0')}';
String? validateCoursePrice(String value) {
  final price = double.tryParse(value.trim());
  return price == null || !price.isFinite || price <= 0
      ? 'Enter a price greater than zero.'
      : null;
}
