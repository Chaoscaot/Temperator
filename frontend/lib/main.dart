import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pool_temp_app/src/app.dart';

void main() async {
  runApp(const ProviderScope(child: PoolTemperaturApp()));
}
