import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class OfflineScreen extends HookConsumerWidget {
  const OfflineScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Offline"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.wifi_off,
              size: 100,
            ),
            Text(
              "No internet connection",
              style: TextStyle(fontSize: 20),
            ),
          ],
        ),
      ),
    );
  }
}
