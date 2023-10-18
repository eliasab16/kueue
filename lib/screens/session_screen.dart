import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import '../app.dart';

typedef ChangeStatusCallback = Future<void> Function(DocumentReference userRef, bool newStatus);
typedef DequeueCallback = Future<void> Function(DocumentReference userRef);


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
    updateSessionData(sessionData_);
  }

  void setupSessionStream() {
    final doc = FirebaseFirestore.instance.collection('sessions').doc(widget.sessionId);

    doc.snapshots().listen((snapshot) {
      final sessionData_ = snapshot.data() as Map<String, dynamic>;
      updateSessionData(sessionData_);
    });
  }

  void updateSessionData(Map<String, dynamic> sessionData_) {
      final sessionQueue = sessionData_['queue'] as List<dynamic>;
      final inProgressList_ = <dynamic>[];
      final inQueueList_ = <dynamic>[];
      final List<dynamic> hosts = sessionData_['hosts'] as List<dynamic>;
      final List<String> hostDisplayNames_ = hosts.map((host) => host['display_name'] as String).toList();

      // we need to separate students into in-progress and in-queue
      for (final item in sessionQueue) {
        if (item['queue_status'] == true) {
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
    }

  //******** */
  //******** */
  Future<void> changeStudentQueueStatus(DocumentReference userRef, bool newStatus) async {
    dynamic result;
    try {
      final sessionData_ = sessionData;
      for (final user in sessionData_['queue']) {
        final iterUserRef = user['user_ref'] as DocumentReference;
        if (iterUserRef.path == userRef.path) {
          user['queue_status'] = newStatus;
          break;
        }
      }

      updateSessionData(sessionData_);

      result =
        await FirebaseFunctions.instance.httpsCallable('changeStudentQueueStatus').call(
          {
          'documentId': widget.sessionId, // Replace with the actual document ID
          'userRef': userRef.path,
          'newStatus': newStatus,
          }
        );
        // perform same update locally for instant changes - rather than wait for database changes
    } on FirebaseFunctionsException catch (error) {
      // TODO: handle errors appropriately
      logger.d('Error: ${error.code} ${error.message}');
    }
  }

  Future<void> dequeueStudent(DocumentReference userRef) async {
    try {
      final updatedQueue = List<Map<String, dynamic>>.from(sessionData['queue']);

      for (int i = 0; i < updatedQueue.length; i++) {
        final user = updatedQueue[i];
        final iterUserRef = user['user_ref'] as DocumentReference;
        if (iterUserRef.path == userRef.path) {
          updatedQueue.removeAt(i);
          break;
        }
      }

      // no need to call updateSessionData since we're just removing items, no sorting is needed
      sessionData['queue'] = updatedQueue;

      final result =
        await FirebaseFunctions.instance.httpsCallable('deleteStudentFromQueue').call(
          {
            'documentId': widget.sessionId,
            'userRef': userRef,
          }
        );
    } on FirebaseFunctionsException catch (error) {
      logger.d('Error: ${error.code} ${error.message}');
    }
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
                UsersList(
                  usersList: inProgressList,
                  ranked: false,
                  dequeueStudent: dequeueStudent,
                  changeStudentQueueStatus: changeStudentQueueStatus,
                  )
              ],
            ),
            Column(
              children: [
                const Text("In queue:"),
                UsersList(
                  usersList: inQueueList,
                  ranked: true,
                  dequeueStudent: dequeueStudent,
                  changeStudentQueueStatus: changeStudentQueueStatus,)
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
    required this.changeStudentQueueStatus,
    required this.dequeueStudent
  });

  final List usersList;
  final bool ranked;
  final ChangeStatusCallback changeStudentQueueStatus;
  final DequeueCallback dequeueStudent;

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
        
              return StudentTile(
                index: index,
                ranked: ranked,
                userRef: userRef,
                displayName: displayName,
                dequeueStudent: dequeueStudent,
                changeStudentQueueStatus: changeStudentQueueStatus,
                );
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
    required this.userRef,
    required this.changeStudentQueueStatus,
    required this.dequeueStudent
  });

  final int index;
  final bool ranked;
  final DocumentReference userRef;
  final String displayName;
  final ChangeStatusCallback changeStudentQueueStatus;
  final DequeueCallback dequeueStudent;

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
                    onPressed: () async {
                      await dequeueStudent(userRef);
                    },
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
                    onPressed: () async {
                      changeStudentQueueStatus(userRef, ranked);
                    },
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
