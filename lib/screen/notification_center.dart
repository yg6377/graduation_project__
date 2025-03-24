import 'package:flutter/material.dart';

class NotificationScreen extends StatelessWidget {
  // 예시로 알림 리스트를 받는 형태
  final List<String> notifications;

  const NotificationScreen({
    Key? key,
    required this.notifications,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    bool hasNotifications = notifications.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text("Notification"),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // 뒤로가기
          },
        ),
      ),
      body: hasNotifications
          ? ListView.builder(
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text(notifications[index]),
          );
        },
      )
          : Center(
        child: Text("there's no notification"),
      ),
    );
  }
}
