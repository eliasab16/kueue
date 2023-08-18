import 'package:flutter/material.dart';

@immutable
class SessionData {
  const SessionData(
    {
      required this.id,
      required this.course,
      required this.topic,
      required this.hosts,
      required this.time,
      required this.active,
      required this.attendees
    }
  );

  final String id;
  final String course;
  final String topic;
  final List<String> hosts;
  final DateTime time;
  final bool active;
  final int attendees;
}