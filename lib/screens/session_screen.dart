import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../app.dart';

class SessionScreen extends StatefulWidget {
  static Route routeWithSessionId({required String sessionId}) {
    return MaterialPageRoute(
      builder: (context) => SessionScreen(sessionId: sessionId),
    );
  }

  const SessionScreen({
    super.key,
    required this.sessionId  
  });

  final String sessionId;

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  List<dynamic> inProgressList = [];
  List<dynamic> inQueueList = [];
  Map<String, dynamic> sessionData = {};
  List<String> hostDisplayNames = [];


  @override
  void initState() {
    super.initState();
    fetchInitialSessionData();
    setupSessionStream();
  }

  Future<void> fetchInitialSessionData() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('sessions')
        .doc(widget.sessionId)
        .get();

    final sessionData_ = snapshot.data() as Map<String, dynamic>;
    final sessionQueue = sessionData_['queue'] as List<dynamic>;
    final inProgressList_ = <dynamic>[];
    final inQueueList_ = <dynamic>[];
    final List<dynamic> hosts = sessionData_['hosts'] as List<dynamic>;
    final List<String> hostDisplayNames_ = hosts.map((host) => host['display_name'] as String).toList();

    // we need to separate students into in-progress and in-queue
    for (final item in sessionQueue) {
      if (item['help_in_progress'] == true) {
        inProgressList_.add(item);
      } else {
        inQueueList_.add(item);
      }
    }

    inQueueList_.sort((a, b) =>
        (a['joining_time'] as Timestamp)
            .compareTo(b['joining_time'] as Timestamp));

    setState(() {
      inProgressList = inProgressList_;
      inQueueList = inQueueList_;
      sessionData = sessionData_;
      hostDisplayNames = hostDisplayNames_;
    });
  }

  void setupSessionStream() {
    final doc = FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);

    doc.snapshots().listen((snapshot) {
      final sessionData_ = snapshot.data() as Map<String, dynamic>;
      final sessionQueue = sessionData_['queue'] as List<dynamic>;
      final inProgressList_ = <dynamic>[];
      final inQueueList_ = <dynamic>[];
      final List<dynamic> hosts = sessionData_['hosts'] as List<dynamic>;
      final List<String> hostDisplayNames_ = hosts.map((host) => host['display_name'] as String).toList();

      // we need to separate students into in-progress and in-queue
      for (final item in sessionQueue) {
        if (item['help_in_progress'] == true) {
          inProgressList_.add(item);
        } else {
          inQueueList_.add(item);
        }
      }

      // Sort the queue data by timestamp
      inQueueList_.sort((a, b) =>
          (a['joining_time'] as Timestamp)
              .compareTo(b['joining_time'] as Timestamp));

      setState(() {
        inProgressList = inProgressList_;
        inQueueList = inQueueList_;
        sessionData = sessionData_;
        hostDisplayNames = hostDisplayNames_;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 179, 34, 53),
        title: sessionData.isNotEmpty ? Text(sessionData['course_name']) : const Text("Queue"),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          )
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            padding: const EdgeInsets.only(bottom: 20),
            child: Column(
              children: [
                sessionData.isNotEmpty 
                    ? Text(
                      sessionData['topic'],
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                      ),  
                    ) 
                    : const Text(""),
                sessionData.isNotEmpty
                    ? Text(
                      hostDisplayNames.join(", "),
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                      ),  
                    )
                    : const Text("")
              ],
            ),
          ),
        ),
      ),
      body:
        Column(
          children: [
            Column(
              children: [
                const Text("In progress:"),
                inProgressList.isNotEmpty
                  ? UsersList(usersList: inProgressList, ranked: false)
                  : const Center(child: CircularProgressIndicator()),
              ],
            ),
            Column(
              children: [
                const Text("In queue:"),
                inQueueList.isNotEmpty
                  ? UsersList(usersList: inQueueList, ranked: true)
                  : const Center(child: CircularProgressIndicator()),
              ],
            ),
          ],
        ),
      );
  }
}

class UsersList extends StatelessWidget {
  const UsersList({
    super.key,
    required this.usersList,
    required this.ranked,
  });

  final List usersList;
  final bool ranked;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(left: 15, right: 15),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: ranked ? const Radius.circular(20) : Radius.zero,
            top: ranked ? Radius.zero : const Radius.circular(20)
          )
        ),
      color: const Color.fromARGB(255, 227, 226, 226),
      child: Padding(
        padding: ranked 
            ? const EdgeInsets.only(top: 15, bottom: 80, left: 8, right: 8) 
            : const EdgeInsets.only(top: 50, bottom: 15, left: 8, right: 8),
        child: ListView.builder(
            shrinkWrap: true,
            itemCount: usersList.length,
            itemBuilder: (context, index) {
              final user = usersList[index];
              final userRef = user['user_ref'] as DocumentReference;
              final displayName = user['display_name'] as String;
        
              return StudentTile(index: index, ranked: ranked, displayName: displayName);
            },
          ),
      ),
    );
  }
}

class StudentTile extends StatelessWidget {
  const StudentTile({
    super.key,
    required this.index,
    required this.ranked,
    required this.displayName,
  });

  final int index;
  final bool ranked;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(25)),
      ),
      child: Row(
        children: [
          ranked 
            ? Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                "${index+1}",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
            : Container(),
          const SizedBox(width: 16),
          Expanded(
            child: ListTile(
              title: Text(displayName),
              subtitle: const Text("Topic: question 3.a"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextButton(
                    onPressed: () => logger.d("student removed"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 188, 188, 188),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16),
                      padding: const EdgeInsets.all(12),
                      shape: const CircleBorder(),
                    ),
                    child: const Text("X"),
                  ),
                  TextButton(
                    onPressed: () => logger.d("student picked"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 188, 188, 188),
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(fontSize: 16),
                      padding: const EdgeInsets.all(12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: ranked ? const Text("Pick") : const Text("Queue"),
                  ),
                ],
              )
            ),
          ),
        ],
      ),
    );
  }
}
