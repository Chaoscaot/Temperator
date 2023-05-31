import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pool_temp_app/src/provider/router.dart';

class PoolTemperaturApp extends HookConsumerWidget {
  const PoolTemperaturApp({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: "Pool Temperature",
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorSchemeSeed: Colors.blue[500]),
      darkTheme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          colorSchemeSeed: Colors.blue[500]),
      debugShowCheckedModeBanner: false,
    );
  }
}
