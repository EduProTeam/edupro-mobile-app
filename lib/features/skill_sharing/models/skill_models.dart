import 'package:flutter/material.dart';

enum SkillLevel { beginner, intermediate, advanced }

enum SessionStatus { confirmed, awaitingLink, completed }

@immutable
class SkillRequest {
  const SkillRequest({
    required this.id,
    required this.requester,
    required this.role,
    required this.title,
    required this.description,
    required this.tags,
    required this.date,
    required this.time,
    required this.level,
    required this.postedAgo,
    required this.avatarColor,
    required this.initials,
    this.recommended = false,
  });

  final String id;
  final String requester;
  final String role;
  final String title;
  final String description;
  final List<String> tags;
  final DateTime date;
  final String time;
  final SkillLevel level;
  final String postedAgo;
  final Color avatarColor;
  final String initials;
  final bool recommended;
}

@immutable
class TutorOffer {
  const TutorOffer({
    required this.id,
    required this.name,
    required this.title,
    required this.rating,
    required this.reviews,
    required this.sessions,
    required this.message,
    required this.available,
    required this.price,
    required this.tags,
    required this.avatarColor,
    required this.initials,
    this.recommended = false,
  });

  final String id;
  final String name;
  final String title;
  final double rating;
  final int reviews;
  final int sessions;
  final String message;
  final String available;
  final int price;
  final List<String> tags;
  final Color avatarColor;
  final String initials;
  final bool recommended;
}

@immutable
class SkillSession {
  const SkillSession({
    required this.id,
    required this.title,
    required this.person,
    required this.description,
    required this.date,
    required this.time,
    required this.status,
    required this.avatarColor,
    required this.initials,
    this.meetingPlatform = 'Google Meet',
    this.meetingLink,
  });

  final String id;
  final String title;
  final String person;
  final String description;
  final DateTime date;
  final String time;
  final SessionStatus status;
  final Color avatarColor;
  final String initials;
  final String meetingPlatform;
  final String? meetingLink;

  SkillSession copyWith({
    SessionStatus? status,
    String? meetingPlatform,
    String? meetingLink,
  }) {
    return SkillSession(
      id: id,
      title: title,
      person: person,
      description: description,
      date: date,
      time: time,
      status: status ?? this.status,
      avatarColor: avatarColor,
      initials: initials,
      meetingPlatform: meetingPlatform ?? this.meetingPlatform,
      meetingLink: meetingLink ?? this.meetingLink,
    );
  }
}
