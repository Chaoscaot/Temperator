import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pool_temp_app/src/messages/message.dart';
import 'package:pool_temp_app/src/provider/temperature.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupScreen extends HookConsumerWidget {
  const SetupScreen({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devices = ref.watch(devicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(drawerPoolSelect()),
      ),
      body: devices.when(
          data: (data) {
            return ListView(
              children: [
                for (var device in data)
                  ListTile(
                    title: Text(device.name),
                    onTap: () async {
                      SharedPreferences prefs =
                          await ref.read(prefsProvider.future);
                      await prefs.setString("device", device.id);
                      GoRouter.of(context).go("/");
                    },
                  )
              ],
            );
          },
          error: (err, stack) => Text(err.toString()),
          loading: () => const LinearProgressIndicator()),
    );
  }
}
