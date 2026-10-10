import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/skill_models.dart';

class SkillSharingStore extends ChangeNotifier {
  SkillSharingStore() : _auth = null, _firestore = null;

  SkillSharingStore.withFirebase(this._auth, this._firestore);

  static final SkillSharingStore instance = SkillSharingStore.withFirebase(
    FirebaseAuth.instance,
    FirebaseFirestore.instance,
  );

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _requestsSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _offersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sentOffersSub;
  bool _remoteStarted = false;
  String? _activeUserId;

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

  final List<TutorOffer> _receivedOffers = <TutorOffer>[];
  final List<TutorOffer> _sentOffers = <TutorOffer>[];

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

  List<SkillSession> get sessions {
    if (!_remoteStarted) return List<SkillSession>.unmodifiable(_sessions);
    final accepted = <SkillSession>[
      ..._receivedOffers
          .where((offer) => offer.status == SkillRequestStatus.accepted)
          .map((offer) => _sessionFromOffer(offer, canPublishLink: true)),
      ..._sentOffers
          .where((offer) => offer.status == SkillRequestStatus.accepted)
          .map((offer) => _sessionFromOffer(offer, canPublishLink: false)),
    ];
    return List<SkillSession>.unmodifiable(accepted);
  }
  List<TutorOffer> get receivedOffers =>
      List<TutorOffer>.unmodifiable(_receivedOffers);
  List<TutorOffer> get sentOffers => List<TutorOffer>.unmodifiable(_sentOffers);
  String? get currentUserId => _auth?.currentUser?.uid;

  bool isOwnRequest(SkillRequest request) =>
      request.ownerId != null && request.ownerId == currentUserId;

  List<TutorOffer> offersForRequest(String requestId) => _receivedOffers
      .where((offer) => offer.requestId == requestId)
      .toList(growable: false);

  TutorOffer? sentOfferForRequest(String requestId) {
    for (final offer in _sentOffers) {
      if (offer.requestId == requestId) return offer;
    }
    return null;
  }

  Future<void> initializeRemote() async {
    if (_auth == null || _firestore == null) return;
    final user = _auth.currentUser;
    if (user == null) return;
    if (_remoteStarted && _activeUserId == user.uid) return;
    await _requestsSub?.cancel();
    await _offersSub?.cancel();
    await _sentOffersSub?.cancel();
    _remoteStarted = true;
    _activeUserId = user.uid;
    requests.clear();
    _receivedOffers.clear();
    _sentOffers.clear();
    _offeredRequestIds.clear();
    notifyListeners();

    _requestsSub = _firestore
        .collection('skill_requests')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
          requests
            ..clear()
            ..addAll(snapshot.docs.map(_requestFromDocument));
          notifyListeners();
        });
    _sentOffersSub = _firestore
        .collection('skill_offers')
        .where('senderId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          _sentOffers
            ..clear()
            ..addAll(snapshot.docs.map(_offerFromDocument));
          _offeredRequestIds
            ..clear()
            ..addAll(
              snapshot.docs
                  .map((doc) => _nullableText(doc.data()['requestId']))
                  .whereType<String>(),
            );
          notifyListeners();
        });
    _offersSub = _firestore
        .collection('skill_offers')
        .where('recipientId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) {
          _receivedOffers
            ..clear()
            ..addAll(snapshot.docs.map(_offerFromDocument));
          notifyListeners();
        });
  }

  bool isSaved(String id) => _savedRequestIds.contains(id);
  bool hasOffered(String id) => _offeredRequestIds.contains(id);

  void toggleSaved(String id) {
    if (!_savedRequestIds.add(id)) _savedRequestIds.remove(id);
    notifyListeners();
  }

  Future<void> sendOffer(SkillRequest request) async {
    if (isOwnRequest(request)) {
      throw StateError('You cannot send an offer to your own request.');
    }
    final user = _auth?.currentUser;
    if (user == null || _firestore == null || request.ownerId == null) {
      _offeredRequestIds.add(request.id);
      notifyListeners();
      return;
    }

    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data();
    final name = _firstText(<dynamic>[
      data?['fullName'],
      user.displayName,
      user.email,
      'EduPro member',
    ]);
    final role = _firstText(<dynamic>[
      data?['professionalTitle'],
      data?['role'],
      'Skill tutor',
    ]);
    final offerId = '${request.id}_${user.uid}';
    await _firestore.collection('skill_offers').doc(offerId).set({
      'requestId': request.id,
      'requestTitle': request.title,
      'requestDescription': request.description,
      'senderId': user.uid,
      'recipientId': request.ownerId,
      'senderName': name,
      'senderTitle': role,
      'profileImageUrl': _nullableText(data?['profileImageUrl']) ?? user.photoURL,
      'recipientName': request.requester,
      'recipientProfileImageUrl': request.profileImageUrl,
      'message': 'I would like to join your ${request.title} skill session.',
      'available': '${formatDateForStorage(request.date)} • ${request.time}',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
    _offeredRequestIds.add(request.id);
    notifyListeners();
  }

  Future<void> addSkillRequest({
    required String title,
    required String description,
    required List<String> tags,
    required DateTime date,
    required String time,
    required SkillLevel level,
  }) async {
    final user = _auth?.currentUser;
    if (user == null || _firestore == null) {
      throw StateError('Please sign in before adding a skill request.');
    }
    final profile = await _firestore.collection('users').doc(user.uid).get();
    final data = profile.data();
    await _firestore.collection('skill_requests').add({
      'ownerId': user.uid,
      'requester': _firstText(<dynamic>[
        data?['fullName'],
        user.displayName,
        user.email,
        'EduPro member',
      ]),
      'role': _firstText(<dynamic>[
        data?['professionalTitle'],
        data?['role'],
        'Student',
      ]),
      'profileImageUrl': _nullableText(data?['profileImageUrl']) ?? user.photoURL,
      'title': title.trim(),
      'description': description.trim(),
      'tags': tags,
      'date': Timestamp.fromDate(date),
      'time': time,
      'level': level.name,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> acceptOffer({
    required TutorOffer offer,
    required DateTime date,
    required String time,
    required String platform,
  }) async {
    final user = _auth?.currentUser;
    if (user == null || _firestore == null) {
      addScheduledSession(
        tutor: offer,
        date: date,
        time: time,
        platform: platform,
      );
      return;
    }
    if (offer.senderId == user.uid || offer.recipientId != user.uid) {
      throw StateError('Only the request owner can accept this offer.');
    }
    await _firestore.collection('skill_offers').doc(offer.id).update({
      'status': 'accepted',
      'scheduledDate': Timestamp.fromDate(date),
      'scheduledTime': time,
      'meetingPlatform': platform,
      'meetingLink': FieldValue.delete(),
      'acceptedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> rejectOffer(TutorOffer offer) async {
    final user = _auth?.currentUser;
    if (user == null || _firestore == null) return;
    if (offer.senderId == user.uid || offer.recipientId != user.uid) {
      throw StateError('Only the skill owner can reject this request.');
    }
    await _firestore.collection('skill_offers').doc(offer.id).update({
      'status': 'rejected',
      'scheduledDate': FieldValue.delete(),
      'scheduledTime': FieldValue.delete(),
      'meetingPlatform': FieldValue.delete(),
      'meetingLink': FieldValue.delete(),
      'rejectedAt': FieldValue.serverTimestamp(),
    });
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
        profileImageUrl: tutor.profileImageUrl,
        meetingPlatform: platform,
      ),
    );
    notifyListeners();
  }

  Future<void> publishMeetingLink({
    required String sessionId,
    required String platform,
    required String link,
  }) async {
    final user = _auth?.currentUser;
    if (user != null && _firestore != null) {
      TutorOffer? offer;
      for (final item in _receivedOffers) {
        if (item.id == sessionId) {
          offer = item;
          break;
        }
      }
      if (offer == null || offer.recipientId != user.uid) {
        throw StateError('Only the skill owner can publish the meeting link.');
      }
      if (offer.status != SkillRequestStatus.accepted) {
        throw StateError('A meeting link can only be added after acceptance.');
      }
      await _firestore.collection('skill_offers').doc(sessionId).update({
        'meetingPlatform': platform,
        'meetingLink': link.trim(),
        'linkPublishedAt': FieldValue.serverTimestamp(),
      });
      return;
    }
    final index = _sessions.indexWhere((session) => session.id == sessionId);
    if (index == -1) return;
    _sessions[index] = _sessions[index].copyWith(
      status: SessionStatus.confirmed,
      meetingPlatform: platform,
      meetingLink: link,
    );
    notifyListeners();
  }

  SkillRequest _requestFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final requester = _firstText(<dynamic>[data['requester'], 'EduPro member']);
    final createdAt = data['createdAt'];
    return SkillRequest(
      id: document.id,
      ownerId: _nullableText(data['ownerId']),
      requester: requester,
      role: _firstText(<dynamic>[data['role'], 'Student']),
      title: _firstText(<dynamic>[data['title'], 'Skill request']),
      description: _firstText(<dynamic>[data['description'], '']),
      tags: (data['tags'] as List<dynamic>? ?? const <dynamic>[])
          .whereType<String>()
          .toList(),
      date: data['date'] is Timestamp
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      time: _firstText(<dynamic>[data['time'], 'Time not specified']),
      level: SkillLevel.values.firstWhere(
        (level) => level.name == data['level'],
        orElse: () => SkillLevel.beginner,
      ),
      postedAgo: createdAt is Timestamp
          ? _postedAgo(createdAt.toDate())
          : 'Posted now',
      avatarColor: const Color(0xFFB9DCE8),
      initials: _initials(requester),
      profileImageUrl: _nullableText(data['profileImageUrl']),
    );
  }

  TutorOffer _offerFromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    final name = _firstText(<dynamic>[data['senderName'], 'EduPro member']);
    final statusName = _nullableText(data['status']) ?? 'pending';
    return TutorOffer(
      id: document.id,
      requestId: _nullableText(data['requestId']),
      senderId: _nullableText(data['senderId']),
      recipientId: _nullableText(data['recipientId']),
      name: name,
      title: _firstText(<dynamic>[data['senderTitle'], 'Skill tutor']),
      rating: 0,
      reviews: 0,
      sessions: 0,
      message: _firstText(<dynamic>[data['message'], 'I would like to help.']),
      available: _firstText(<dynamic>[data['available'], 'To be arranged']),
      price: 0,
      tags: const <String>[],
      avatarColor: const Color(0xFFB9DCE8),
      initials: _initials(name),
      profileImageUrl: _nullableText(data['profileImageUrl']),
      status: SkillRequestStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => SkillRequestStatus.pending,
      ),
      requestTitle: _nullableText(data['requestTitle']),
      requestDescription: _nullableText(data['requestDescription']),
      recipientName: _nullableText(data['recipientName']),
      recipientProfileImageUrl: _nullableText(
        data['recipientProfileImageUrl'],
      ),
      scheduledDate: data['scheduledDate'] is Timestamp
          ? (data['scheduledDate'] as Timestamp).toDate()
          : null,
      scheduledTime: _nullableText(data['scheduledTime']),
      meetingPlatform: _nullableText(data['meetingPlatform']),
      meetingLink: _nullableText(data['meetingLink']),
    );
  }

  SkillSession _sessionFromOffer(
    TutorOffer offer, {
    required bool canPublishLink,
  }) {
    final person = canPublishLink
        ? offer.name
        : offer.recipientName ?? 'Skill owner';
    final profileImageUrl = canPublishLink
        ? offer.profileImageUrl
        : offer.recipientProfileImageUrl;
    return SkillSession(
      id: offer.id,
      title: offer.requestTitle ?? 'Skill Session',
      person: person,
      description: offer.requestDescription ?? offer.message,
      date: offer.scheduledDate ?? DateTime.now(),
      time: offer.scheduledTime ?? 'Time not specified',
      status: offer.meetingLink == null
          ? SessionStatus.awaitingLink
          : SessionStatus.confirmed,
      avatarColor: offer.avatarColor,
      initials: _initials(person),
      meetingPlatform: offer.meetingPlatform ?? 'Online',
      meetingLink: offer.meetingLink,
      profileImageUrl: profileImageUrl,
      canPublishLink: canPublishLink,
    );
  }

  String _postedAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.inMinutes < 1) return 'Posted now';
    if (difference.inHours < 1) return 'Posted ${difference.inMinutes}m ago';
    if (difference.inDays < 1) return 'Posted ${difference.inHours}h ago';
    return 'Posted ${difference.inDays}d ago';
  }

  String _initials(String name) => name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .take(2)
      .map((part) => part[0].toUpperCase())
      .join();

  String _firstText(List<dynamic> values) {
    for (final value in values) {
      final text = _nullableText(value);
      if (text != null) return text;
    }
    return '';
  }

  String? _nullableText(dynamic value) {
    if (value is String && value.trim().isNotEmpty) return value.trim();
    return null;
  }

  String formatDateForStorage(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  @override
  void dispose() {
    _requestsSub?.cancel();
    _offersSub?.cancel();
    _sentOffersSub?.cancel();
    super.dispose();
  }
}
