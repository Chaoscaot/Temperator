import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pool_temp_app/src/provider/temperature.dart';

class LoadingScreen extends HookConsumerWidget {
  const LoadingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(baseUrlProvider);

    useEffect(() {
      if (url.isNotEmpty) {
        Future.delayed(Duration.zero, () {
          context.go("/");
        });
      }
      return null;
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
