import 'dart:async';
import 'dart:developer';
import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:forground_app/pages/first_task_handler.dart';
import 'package:notification_listener_service/notification_listener_service.dart';

// The callback function should always be a top-level function.

void startCallback() {
  FlutterForegroundTask.setTaskHandler(FirstTaskHandler());
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  ReceivePort? _receivePort;

  Future<void> _initForegroundTask() async {
    await FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'notification_channel_id',
        channelName: 'Foreground Notification',
        channelDescription:
            'This notification appears when the foreground service is running.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        iconData: const NotificationIconData(
          resType: ResourceType.mipmap,
          resPrefix: ResourcePrefix.ic,
          name: 'launcher',
        ),
        buttons: [
          const NotificationButton(id: 'sendButton', text: 'Send'),
          const NotificationButton(id: 'testButton', text: 'Test'),
        ],
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        autoRunOnBoot: true,
        allowWifiLock: true,
      ),
      printDevLog: true,
    );
  }

  Future<bool> _startForegroundTask() async {
    // You can save data using the saveData function.
    await FlutterForegroundTask.saveData(key: 'customData', value: 'hello');

    ReceivePort? receivePort;
    if (await FlutterForegroundTask.isRunningService) {
      receivePort = await FlutterForegroundTask.restartService();
    } else {
      receivePort = await FlutterForegroundTask.startService(
        notificationTitle: 'Foreground Service is running',
        notificationText: 'Tap to return to the app',
        callback: startCallback,
      );
    }

    if (receivePort != null) {
      _receivePort = receivePort;
      _receivePort?.listen((message) {
        log("$message");

        log("message recieved: $message");
        if (message is DateTime) {
          log('receive timestamp: $message');
        } else if (message is int) {
          log('receive updateCount: $message');
        }
      });

      return true;
    }

    return false;
  }

  Future<bool> _stopForegroundTask() async {
    return await FlutterForegroundTask.stopService();
  }

  @override
  void initState() {
    super.initState();
    _initForegroundTask();
  }

  @override
  void dispose() {
    _receivePort?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: WithForegroundTask(
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Flutter Foreground Task'),
            centerTitle: true,
          ),
          body: _buildContentView(),
        ),
      ),
    );
  }

  Widget _buildContentView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildTestButton('request Permission', onPressed: () async {
            await NotificationListenerService.requestPermission();
          }),
          _buildTestButton('start listening', onPressed: _startForegroundTask),
          _buildTestButton('stop', onPressed: _stopForegroundTask),
        ],
      ),
    );
  }

  Widget _buildTestButton(String text, {VoidCallback? onPressed}) {
    return SizedBox(
      width: 200,
      child: ElevatedButton(
        child: Text(text),
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(primary: const Color(0xFF587C8F)),
      ),
    );
  }
}
