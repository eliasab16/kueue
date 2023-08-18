import 'dart:math';

import 'package:faker/faker.dart';

abstract class Helpers {
  static final random = Random();
  static final courses = ['CS61', 'CS120', 'MATH21B', 'PSY1', 'STAT110', 'CS20'];
  static final topics = ['Pset Office Hours', 'Professor OH', 'Section'];

  static String randomPictureUrl() {
    final randomInt = random.nextInt(1000);
    return 'https://picsum.photos/seed/$randomInt/300/300';
  }

  static DateTime randomDate() {
    final random = Random();
    final currentDate = DateTime.now();
    return currentDate.subtract(Duration(seconds: random.nextInt(200000)));
  }

  static int randomNumber() {
    return random.nextInt(40);
  }

  static String randomCourse() {
    final index = random.nextInt(6);
    return courses[index];
  }

  static String randomTopic() {
    final index = random.nextInt(3);
    return topics[index];
  }

  static bool randomStatus() {
    return random.nextBool();
  }

  static List<String> randomHosts() {
    final count = random.nextInt(3);
    final List<String> hosts = [];
    for (int i = 0; i <= count; i++) {
      hosts.add(faker.person.name());
    }

    return hosts;
  }
}