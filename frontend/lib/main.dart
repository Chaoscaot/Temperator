import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:pool_temp_app/src/app.dart';

void main() async {
  Intl.defaultLocale = Platform.localeName;
  await initializeDateFormatting(Intl.defaultLocale, null);

  runApp(const ProviderScope(child: PoolTemperaturApp()));
}
