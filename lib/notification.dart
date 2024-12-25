
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notificatin/main.dart';
import 'package:local_notificatin/notification_page.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static String?
      pendingPayload; // Temporary storage for payload when app is not ready

  static Future<void> init() async {
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    final DarwinInitializationSettings iOSInitializationSettings =
        DarwinInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: iOSInitializationSettings,
    );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
    );

    // Handle notification that launched the app
    final NotificationAppLaunchDetails? notificationAppLaunchDetails =
        await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

    if (notificationAppLaunchDetails?.didNotificationLaunchApp ?? false) {
      final String? payload =
          notificationAppLaunchDetails!.notificationResponse?.payload;
      if (payload != null) {
        pendingPayload = payload; // Store payload temporarily
      }
    }

    // Request permission for notifications (Android)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    // Request permission for notifications (iOS)
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  } //END OF INITIALIZATION

  /// Schedule daily notifications, looping through the Dua list indefinitely.
  // static Future<void> scheduleDailyDuaNotification(
  //     List<DetailsDuaModel> duaList) async {
  //   const int daysToSchedule = 5; // Number of days to schedule at a time.
  //   final tz.TZDateTime baseTime =
  //       tz.TZDateTime.now(tz.local); // Current local time.
  //   const int hour = 23; // Time for notifications (11 PM).
  //   const int minute = 0;

  //   for (int day = 0; day < daysToSchedule; day++) {
  //     // Circularly iterate through the Dua list.
  //     final dua = duaList[day % duaList.length]; // Loop through the Dua list.
  //     final tz.TZDateTime tzScheduledTime = tz.TZDateTime(
  //       tz.local,
  //       baseTime.year,
  //       baseTime.month,
  //       baseTime.day,
  //       hour,
  //       minute,
  //     ).add(Duration(days: day)); // Offset for each day.

  //     final payload = jsonEncode(dua.toJson());
  //     const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //       android: AndroidNotificationDetails(
  //         'daily_dua_channel',
  //         'Daily Dua',
  //         channelDescription: 'Receive daily reminders with today’s Dua.',
  //         importance: Importance.high,
  //         priority: Priority.high,
  //       ),
  //       iOS: DarwinNotificationDetails(),
  //     );

  //     await flutterLocalNotificationsPlugin.zonedSchedule(
  //       dua.id, // Use the Dua ID as the unique notification ID.
  //       'Daily Reminder',
  //       'Today’s Dua: ${dua.title}',
  //       tzScheduledTime,
  //       platformChannelSpecifics,
  //       uiLocalNotificationDateInterpretation:
  //           UILocalNotificationDateInterpretation.absoluteTime,
  //       payload: payload,
  //       matchDateTimeComponents:
  //           DateTimeComponents.dateAndTime, // Specific date and time.
  //       androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //     );
  //   }

  //   // Automatically reschedule the next batch after the current batch ends.
  //   Future.delayed(Duration(days: daysToSchedule), () {
  //     scheduleDailyDuaNotification(duaList);
  //   });
  // }

  // /// Helper to reschedule the next batch of notifications
  // static Future<void> _scheduleNextBatch(
  //     List<DetailsDuaModel> duaList, int daysToSchedule, int startId) async {
  //   // Wait until the last scheduled notification triggers (e.g., after `daysToSchedule`)
  //   await Future.delayed(Duration(days: daysToSchedule - 1), () async {
  //     await scheduleDailyDuaNotification(duaList);
  //   });
  // }

  /// Schedule the next batch of notifications.
// static Future<void> _scheduleNextBatch(
//     List<DetailsDuaModel> duaList, int daysToSchedule, int lastNotificationId) async {
//   // Calculate the starting day for the next batch.
//   Future.delayed(Duration(days: daysToSchedule), () async {
//     // Call the method again to schedule the next batch.
//     scheduleDailyDuaNotification(duaList);
//   });
// }

  /// Handle notification click
  static Future<void> _onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    final payload = notificationResponse.payload;

    if (payload != null) {
      _handleNotificationPayload(payload);
    }
  }

  /// Handle notification payload
  static void _handleNotificationPayload(String payload) {
    try {
      final duaData = jsonDecode(payload);
      

      if (navigatorKey.currentState != null) {
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => MyHomePage(title: 'home',),
          ),
        );
      } else {
        pendingPayload =
            payload; // Store payload if navigation stack is not ready
      }
    } catch (e) {
      print('Error handling notification payload: $e');
      navigatorKey.currentState
          ?.push(MaterialPageRoute(builder: (contex) => NotificationPage()));
    }
  }

  /// Process any pending payload after app is ready
  static void handlePendingPayload() {
    if (pendingPayload != null) {
      _handleNotificationPayload(pendingPayload!);
      pendingPayload = null; // Clear the payload after handling
    }
  }

  /// Schedule notification
  // static Future<void> reminderSchedulNotification(
  //     int id, DetailsDuaModel dua, TimeOfDay timeOfDay) async {
  //   final now = DateTime.now();
  //   final scheduledDate = DateTime(
  //       now.year, now.month, now.day, timeOfDay.hour, timeOfDay.minute);

  //   final firstNotificationTime = scheduledDate.isBefore(now)
  //       ? scheduledDate.add(Duration(days: 1))
  //       : scheduledDate;

  //   const NotificationDetails platformChannelSpecifics = NotificationDetails(
  //     android: AndroidNotificationDetails(
  //       'reminder_channel',
  //       'Reminder Notification',
  //       importance: Importance.high,
  //       priority: Priority.high,
  //     ),
  //     iOS: DarwinNotificationDetails(),
  //   );

  //   final tz.TZDateTime tzFirstNotificationTime =
  //       tz.TZDateTime.from(firstNotificationTime, tz.local);
  //   final payload = jsonEncode(dua.toJson());
  //   await flutterLocalNotificationsPlugin.zonedSchedule(
  //     id,
  //     dua.title,
  //     dua.arabicContext,
  //     tzFirstNotificationTime,
  //     platformChannelSpecifics,
  //     uiLocalNotificationDateInterpretation:
  //         UILocalNotificationDateInterpretation.absoluteTime,
  //     payload: payload,
  //     matchDateTimeComponents: DateTimeComponents.time,
  //     androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  //   );
  // }

  static Future<void> dailySchedulNotification() async {
  // Set the desired time for the notification
  const int targetHour = 11; // 11 AM
  const int targetMinute = 0;

  // Get the current date and time
  final now = DateTime.now();
  final scheduledDate = DateTime(
    now.year,
    now.month,
    now.day,
    targetHour,
    targetMinute,
  );

  // Adjust to the next day if the time has already passed
  final firstNotificationTime = scheduledDate.isBefore(now)
      ? scheduledDate.add(const Duration(days: 1))
      : scheduledDate;

  // Notification details
  const NotificationDetails platformChannelSpecifics = NotificationDetails(
    android: AndroidNotificationDetails(
      'reminder_channel',
      'Reminder Notification',
      importance: Importance.high,
      priority: Priority.high,
    ),
    iOS: DarwinNotificationDetails(),
  );

  // Convert to timezone-aware time
  final tz.TZDateTime tzFirstNotificationTime =
      tz.TZDateTime.from(firstNotificationTime, tz.local);

  // Payload for notification
  final payload = jsonEncode('payload');

  // Schedule the notification
  await flutterLocalNotificationsPlugin.zonedSchedule(
    0,
    'Daily Reminder',
    'This is your daily reminder at 11:00 AM.',
    tzFirstNotificationTime,
    platformChannelSpecifics,
    uiLocalNotificationDateInterpretation:
        UILocalNotificationDateInterpretation.absoluteTime,
    payload: payload,
    matchDateTimeComponents: DateTimeComponents.time,
    androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
  );
}

  /// Cancel notification
  static Future<void> cancelNotification(int notificationId) async {
    await flutterLocalNotificationsPlugin.cancel(notificationId);
  }
}
