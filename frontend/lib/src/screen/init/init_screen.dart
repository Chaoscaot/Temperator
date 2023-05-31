import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
        title: const Text("Pool Wählen"),
      ),
      body: devices.when(
          data: (data) {
            return ListView(
              children: [
                for (var device in data)
                  ListTile(
                    title: Text(device.name),
                    onTap: () async {
                      final router = GoRouter.of(context);
                      SharedPreferences prefs =
                          await ref.read(prefsProvider.future);
                      prefs.setString("device", device.id);
                      prefs.reload();
                      router.go("/");
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
