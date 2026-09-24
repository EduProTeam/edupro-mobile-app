import 'package:flutter/material.dart';

import '../models/skill_models.dart';

class SkillSharingStore extends ChangeNotifier {
  SkillSharingStore();

  static final SkillSharingStore instance = SkillSharingStore();

  final Set<String> _savedRequestIds = <String>{};
  final Set<String> _offeredRequestIds = <String>{};

  final List<SkillRequest> requests = <SkillRequest>[
    SkillRequest(
      id: 'spoken-english',
      requester: 'Ananya Sharma',
      role: 'Student',
      title: 'Spoken English Practice',
      description:
          'I want to improve my fluency and confidence in spoken English through conversations and feedback.',
      tags: <String>['Language', 'English', 'Communication'],
      date: DateTime(2025, 5, 18),
      time: '5:00 PM – 6:00 PM',
      level: SkillLevel.beginner,
      postedAgo: 'Posted 1h ago',
      avatarColor: Color(0xFFE8C9B2),
      initials: 'AS',
      recommended: true,
    ),
    SkillRequest(
      id: 'ui-ux',
      requester: 'Rohan Verma',
      role: 'Engineering Student',
      title: 'UI/UX Basics',
      description:
          'Looking for someone who can teach the basics of UI/UX design and share real-world tips.',
      tags: <String>['Design', 'UI/UX', 'Figma'],
      date: DateTime(2025, 5, 20),
      time: '7:00 PM – 8:00 PM',
      level: SkillLevel.intermediate,
      postedAgo: 'Posted 2h ago',
      avatarColor: Color(0xFFB9DCE8),
      initials: 'RV',
    ),
    SkillRequest(
      id: 'excel',
      requester: 'Neha Patel',
      role: 'Commerce Student',
      title: 'Excel for Beginners',
      description:
          'Need help learning Excel basics like formulas, functions and building simple reports.',
      tags: <String>['Productivity', 'Excel', 'Data Analysis'],
      date: DateTime(2025, 5, 21),
      time: '4:00 PM – 5:00 PM',
      level: SkillLevel.beginner,
      postedAgo: 'Posted 3h ago',
      avatarColor: Color(0xFFF3D2BC),
      initials: 'NP',
    ),
  ];

  final List<TutorOffer> offers = const <TutorOffer>[
    TutorOffer(
      id: 'ananya',
      name: 'Ananya Sharma',
      title: 'English Language Coach',
      rating: 4.9,
      reviews: 128,
      sessions: 120,
      message:
          'Hi! I’d love to help you become more confident in speaking English. Let’s practice real conversations and improve together!',
      available: 'May 18, 5:00 PM – 6:00 PM',
      price: 0,
      tags: <String>['Conversation', 'Pronunciation'],
      avatarColor: Color(0xFFE8C9B2),
      initials: 'AS',
      recommended: true,
    ),
    TutorOffer(
      id: 'rohan',
      name: 'Rohan Verma',
      title: 'Spoken English Trainer',
      rating: 4.8,
      reviews: 96,
      sessions: 80,
      message:
          'Hey! I focus on practical speaking and confidence building with interactive practice. Happy to help you improve!',
      available: 'May 18, 7:00 PM – 8:00 PM',
      price: 150,
      tags: <String>['Fluency', 'Confidence Building'],
      avatarColor: Color(0xFFB9DCE8),
      initials: 'RV',
    ),
    TutorOffer(
      id: 'neha',
      name: 'Neha Patel',
      title: 'Communication Coach',
      rating: 4.7,
      reviews: 74,
      sessions: 60,
      message:
          'Let’s work on your speaking skills step by step with fun and simple techniques. See you in class!',
      available: 'May 21, 4:00 PM – 5:00 PM',
      price: 100,
      tags: <String>['Grammar', 'Vocabulary'],
      avatarColor: Color(0xFFF3D2BC),
      initials: 'NP',
    ),
  ];

  final List<SkillSession> _sessions = <SkillSession>[
    SkillSession(
      id: 'english-session',
      title: 'Spoken English Practice',
      person: 'Ananya Sharma',
      description:
          'Practice conversations and improve fluency with real-time feedback.',
      date: DateTime(2025, 5, 18),
      time: '5:00 PM – 6:00 PM',
      status: SessionStatus.confirmed,
      avatarColor: Color(0xFFE8C9B2),
      initials: 'AS',
      meetingLink: 'https://meet.google.com/edu-pro-demo',
    ),
    SkillSession(
      id: 'ui-session',
      title: 'UI/UX Basics',
      person: 'Rohan Verma',
      description:
          'Learn the fundamentals of UI/UX design and create your first wireframe.',
      date: DateTime(2025, 5, 20),
      time: '7:00 PM – 8:00 PM',
      status: SessionStatus.awaitingLink,
      avatarColor: Color(0xFFB9DCE8),
      initials: 'RV',
    ),
    SkillSession(
      id: 'excel-session',
      title: 'Excel Mentoring',
      person: 'Neha Patel',
      description:
          'Get help with formulas, functions and building reports in Excel.',
      date: DateTime(2025, 5, 12),
      time: '4:00 PM – 5:00 PM',
      status: SessionStatus.completed,
      avatarColor: Color(0xFFF3D2BC),
      initials: 'NP',
    ),
  ];

  List<SkillSession> get sessions => List<SkillSession>.unmodifiable(_sessions);

  bool isSaved(String id) => _savedRequestIds.contains(id);
  bool hasOffered(String id) => _offeredRequestIds.contains(id);

  void toggleSaved(String id) {
    if (!_savedRequestIds.add(id)) _savedRequestIds.remove(id);
    notifyListeners();
  }

  void sendOffer(String id) {
    _offeredRequestIds.add(id);
    notifyListeners();
  }

  void addScheduledSession({
    required TutorOffer tutor,
    required DateTime date,
    required String time,
    required String platform,
  }) {
    final id = 'scheduled-${tutor.id}';
    _sessions.removeWhere((session) => session.id == id);
    _sessions.insert(
      0,
      SkillSession(
        id: id,
        title: 'Spoken English Practice',
        person: tutor.name,
        description:
            'Practice conversations and improve fluency with real-time feedback.',
        date: date,
        time: time,
        status: SessionStatus.awaitingLink,
        avatarColor: tutor.avatarColor,
        initials: tutor.initials,
        meetingPlatform: platform,
      ),
    );
    notifyListeners();
  }

  void publishMeetingLink({
    required String sessionId,
    required String platform,
    required String link,
  }) {
    final index = _sessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) return;
    _sessions[index] = _sessions[index].copyWith(
      status: SessionStatus.confirmed,
      meetingPlatform: platform,
      meetingLink: link,
    );
    notifyListeners();
  }
}
