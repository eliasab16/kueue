import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kueue/helpers.dart';
import 'package:kueue/models/session_data.dart';
import 'package:kueue/screens/session_screen.dart';

class SessionsPage extends StatefulWidget {
  const SessionsPage({super.key});

  @override
  State<SessionsPage> createState() => _SessionsPageState();
}

class _SessionsPageState extends State<SessionsPage> {
  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverList(
          delegate: SliverChildBuilderDelegate(
            _delegate,
            childCount: 4,  
          )
        )
      ],
    );
  }

  Widget _delegate(BuildContext context, int index) {
    return _SessionPreview(
      sessionData: SessionData(
        id: "EcRTyaIXgVZ5cZ9sF6kW",
        course: Helpers.randomCourse(),
        topic: Helpers.randomTopic(),
        hosts: Helpers.randomHosts(),
        time: Helpers.randomDate(),
        active: Helpers.randomStatus(),
        attendees: Helpers.randomNumber(),
        )
      );
  }
}

class _SessionPreview extends StatelessWidget {
  const _SessionPreview({
    required this.sessionData,
  });

  final SessionData sessionData;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator
          .of(context)
          .push(SessionScreen.routeWithSessionId(sessionId: sessionData.id), // Pass the actual session ID
        );
      },
      child: Card(
        child: Container(
          height: 100,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: Colors.grey,
                width: 0.2,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      "${sessionData.course}: ",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      )
                    ),
                    Text(
                      sessionData.topic
                    )
                  ],
                ),
                Row(
                  children: [
                    const Icon(
                      CupertinoIcons.person_crop_circle,
                      size: 18,
                    ),
                    const Padding(padding: EdgeInsets.only(left: 5)),
                    Text(
                      sessionData.hosts.length == 1 ? "Instructor: " : "Instructors: ",
                    ),
                    Flexible(
                      child: Text(
                          overflow: TextOverflow.ellipsis,
                          sessionData.hosts.join(", "),
                        ),
                    ),
                  ],
                ),
                Container(
                  child: 
                  sessionData.active ?
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.person_3,
                      ),
                      const Padding(padding: EdgeInsets.only(left: 5)),
                      Text(sessionData.attendees > 0 ? "${sessionData.attendees} students online" : "There is no one here yet!")
                    ],
                  ) :
                  Row(
                    children: [
                      const Icon(
                        CupertinoIcons.time,
                        size: 18,
                      ),
                      const Padding(padding: EdgeInsets.only(left: 5)),
                      _ScheduledTimeFormat(time: sessionData.time)
                    ],
                  )
                ),
              ],
            )
          )
        )
      ),
    );
  }
}

class _ScheduledTimeFormat extends StatelessWidget {
  const _ScheduledTimeFormat({
    required this.time,
  });

  final DateTime time;

  @override
  Widget build(BuildContext context) {
    return isToday(time) ? 
        Text("Scheduled for today at ${time.hour}:${time.minute}") :
        Text("Scheduled for ${time.day}/${time.month}/${time.year} at ${time.hour}:${time.minute}");
  }

  bool isToday(DateTime dateTime) {
    final now = DateTime.now();
    return dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day;
  }
}