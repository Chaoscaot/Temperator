import 'dart:async';
import 'dart:math';

import 'package:animations/animations.dart';
import 'package:dio/dio.dart';
import 'package:draw_graph/draw_graph.dart';
import 'package:draw_graph/models/feature.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pool_temp_app/src/provider/temperature.dart';
import 'package:intl/intl.dart';
import 'package:pool_temp_app/src/messages/message.dart';
import 'package:pool_temp_app/src/screen/misc/error_screen.dart';
import 'package:pool_temp_app/src/types/api.dart';

class HomeScreen extends HookConsumerWidget {
  HomeScreen({
    super.key,
  });

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTemp = useState(0);
    final lastSelectedTemp = useState(0);

    final currentTemp = ref.watch(currentTempProvider);

    if (currentTemp.hasError) {
      debugPrint(currentTemp.error.toString());
      final error = ErrorObject(
        error: currentTemp.error.toString(),
        stackTrace: (currentTemp.error as DioException).stackTrace.toString(),
        onRetry: (context) {
          ref.invalidate(currentTempProvider);
        },
      );
      return ErrorScreen(errorObject: error);
    }

    final chartData = ref.watch(chartDataProvider);

    return Scaffold(
      drawerEnableOpenDragGesture: true,
      key: _scaffoldKey,
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
              ),
              child: FittedBox(
                child: Text(drawerHeader()),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(drawerStart()),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(drawerPoolSelect()),
              onTap: () {
                Navigator.of(context).pop();
                GoRouter.of(context).push("/init");
              },
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                _scaffoldKey.currentState?.openDrawer();
              },
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  ref.invalidate(currentTempProvider);
                  ref.invalidate(chartDataProvider);
                },
              )
            ],
            iconTheme: IconThemeData(
                color: Theme.of(context).appBarTheme.foregroundColor),
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
            expandedHeight: 400,
            primary: true,
            flexibleSpace: FlexibleSpaceBar(
              background: currentTemp.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).cardColor,
                      ),
                    )
                  : SafeArea(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: GestureDetector(
                            onHorizontalDragEnd: (e) {
                              if (e.primaryVelocity! > 0) {
                                if (selectedTemp.value > 0) {
                                  lastSelectedTemp.value = selectedTemp.value;
                                  selectedTemp.value = selectedTemp.value - 1;
                                }
                              } else {
                                if (selectedTemp.value < 2) {
                                  lastSelectedTemp.value = selectedTemp.value;
                                  selectedTemp.value = selectedTemp.value + 1;
                                }
                              }
                            },
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 48),
                                  child: SegmentedButton(
                                    segments: [
                                      ButtonSegment(
                                        icon: const Icon(Icons.water),
                                        value: 0,
                                        label: Text(pool()),
                                      ),
                                      ButtonSegment(
                                        icon: const Icon(Icons.thermostat),
                                        value: 1,
                                        label: Text(outside()),
                                      ),
                                      ButtonSegment(
                                        icon: const Icon(Icons.wb_cloudy),
                                        value: 2,
                                        label: Text(humidity()),
                                      ),
                                    ],
                                    onSelectionChanged: (value) {
                                      lastSelectedTemp.value =
                                          selectedTemp.value;
                                      selectedTemp.value = value.first;
                                    },
                                    style: ButtonStyle(
                                      textStyle: MaterialStateProperty.all(
                                        TextStyle(
                                            color: Theme.of(context)
                                                .appBarTheme
                                                .foregroundColor,
                                            fontSize: 10),
                                      ),
                                    ),
                                    selected: {selectedTemp.value},
                                  ),
                                ),
                                const Spacer(),
                                PageTransitionSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, primaryAnimation,
                                      secondaryAnimation) {
                                    final anim = primaryAnimation.drive(
                                      Tween<Offset>(
                                        begin: Offset(
                                            (-2 *
                                                    (lastSelectedTemp.value -
                                                        selectedTemp.value))
                                                .toDouble(),
                                            0),
                                        end: Offset.zero,
                                      ),
                                    );
                                    final anim2 = secondaryAnimation.drive(
                                      Tween<Offset>(
                                        end: Offset(
                                            (2 *
                                                    (lastSelectedTemp.value -
                                                        selectedTemp.value))
                                                .toDouble(),
                                            0),
                                        begin: Offset.zero,
                                      ),
                                    );
                                    return SlideTransition(
                                      position: anim,
                                      child: SlideTransition(
                                        position: anim2,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: IndexedStack(
                                    key: ValueKey(selectedTemp.value),
                                    index: selectedTemp.value,
                                    alignment: Alignment.center,
                                    children: [
                                      Text(
                                          "${NumberFormat.decimalPatternDigits(decimalDigits: 1).format(currentTemp.value!.waterTemp ?? 0)} C°",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .appBarTheme
                                                  .foregroundColor,
                                              fontSize: 64)),
                                      Text(
                                          "${NumberFormat.decimalPatternDigits(decimalDigits: 1).format(currentTemp.value!.outsideTemp ?? 0)} C°",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .appBarTheme
                                                  .foregroundColor,
                                              fontSize: 64)),
                                      Text(
                                          "${NumberFormat.decimalPatternDigits(decimalDigits: 1).format(currentTemp.value!.humidity ?? 0)} %",
                                          style: TextStyle(
                                              color: Theme.of(context)
                                                  .appBarTheme
                                                  .foregroundColor,
                                              fontSize: 64)),
                                    ],
                                  ),
                                ),
                                Text(
                                    DateFormat.yMd().add_Hm().format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            currentTemp.value!.time)),
                                    style: TextStyle(
                                        color: Theme.of(context)
                                            .appBarTheme
                                            .foregroundColor,
                                        fontSize: 16)),
                                const Spacer(),
                              ],
                            ),
                          )),
                    ),
              title: Text(
                title(),
                style: TextStyle(
                    color: Theme.of(context).appBarTheme.foregroundColor),
              ),
            ),
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(
                bottom: Radius.circular(20),
              ),
            ),
            elevation: 2,
          ),
          SliverList(
            delegate: SliverChildListDelegate(
              [
                _PumpWidget(currentTemp: currentTemp),
                chartData.when(
                  data: (data) {
                    if (data.length < 2) {
                      return Center(child: Text(graphNoData()));
                    }

                    final dates = data
                        .map((e) => DateTime.fromMillisecondsSinceEpoch(e.time))
                        .toList();
                    final maxWaterTemp = data
                        .map((e) => e.waterTemp)
                        .reduce((a, b) => a > b ? a : b);
                    final maxOutsideTemp = data
                        .map((e) => e.outsideTemp)
                        .reduce((a, b) => a > b ? a : b);

                    final maxAll = max(maxWaterTemp, maxOutsideTemp);

                    final reducedTimes = (dates.length / 6).ceil();
                    final formattedDates = <String>[];
                    var counter = 0;
                    for (var i = 0; i < dates.length; i++) {
                      if (counter == 0) {
                        formattedDates.add(DateFormat.Hm().format(dates[i]));
                      } else {
                        formattedDates.add("");
                      }
                      counter++;
                      if (counter >= reducedTimes) {
                        counter = 0;
                      }
                    }

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 16),
                      child: Column(
                        children: [
                          LineGraph(
                            features: [
                              Feature(
                                title: outsideTemperature(),
                                color: Colors.red,
                                data: data
                                    .map((e) => e.outsideTemp / maxAll)
                                    .toList(),
                              ),
                              Feature(
                                title: poolTemperature(),
                                color: Colors.blue,
                                data: data
                                    .map((e) => e.waterTemp / maxAll)
                                    .toList(),
                              ),
                            ],
                            size: const Size(double.infinity, 400),
                            labelY: [
                              "0",
                              "${NumberFormat.decimalPatternDigits(decimalDigits: 0).format((maxAll * 0.25))} C°",
                              "${NumberFormat.decimalPatternDigits(decimalDigits: 0).format((maxAll * 0.50))} C°",
                              "${NumberFormat.decimalPatternDigits(decimalDigits: 0).format((maxAll * 0.75))} C°",
                              "${NumberFormat.decimalPatternDigits(decimalDigits: 0).format(maxAll)} C°",
                            ],
                            labelX: formattedDates,
                            showDescription: true,
                          ),
                          const SizedBox(
                            height: 16,
                          ),
                          LineGraph(
                            features: [
                              Feature(
                                data:
                                    data.map((e) => e.humidity / 100).toList(),
                                title: humidity(),
                                color: Colors.blue,
                              ),
                            ],
                            size: const Size(double.infinity, 400),
                            labelX: formattedDates,
                            labelY: [
                              for (var i = 0; i <= 100; i += 20)
                                NumberFormat.percentPattern().format(i / 100),
                            ],
                            showDescription: true,
                          )
                        ],
                      ),
                    );
                  },
                  error: (err, stack) => throw err,
                  loading: () => const LinearProgressIndicator(),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _PumpWidget extends HookConsumerWidget {
  const _PumpWidget({
    super.key,
    required this.currentTemp,
  });

  final AsyncValue<CurrentTemperature> currentTemp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pumpLoading = useState(false);

    final counter = useState(0);

    useEffect(() {
      final timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        counter.value++;
      });
      return timer.cancel;
    }, []);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.cyclone),
                          Text(
                            "Pool Pumpe",
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 8,
                      ),
                      if (currentTemp.valueOrNull?.pump ?? false)
                        Text(
                          "Laufzeit: ${_printDuration(DateTime.now().difference(
                            DateTime.fromMillisecondsSinceEpoch(
                                    currentTemp.valueOrNull?.lastPumpToggle ??
                                        0,
                                    isUtc: false)
                                .subtract(DateTime.now().timeZoneOffset),
                          ))}",
                        )
                      else
                        const Text("Pumpe ist ausgeschaltet"),
                      const SizedBox(
                        height: 8,
                      ),
                      FilledButton.tonalIcon(
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(
                              currentTemp.valueOrNull?.pump ?? false
                                  ? Colors.green
                                  : Colors.red),
                        ),
                        onPressed: pumpLoading.value
                            ? null
                            : () async {
                                pumpLoading.value = true;
                                await ref.read(repositoryProvider).togglePump();
                                ref.invalidate(currentTempProvider);
                                await ref.read(currentTempProvider.future);
                                pumpLoading.value = false;
                              },
                        icon: const Icon(Icons.power_settings_new),
                        label: Text(
                          "Pumpenstatus ändern",
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
            if (pumpLoading.value)
              LinearProgressIndicator()
            else
              const SizedBox(
                height: 4,
              ),
          ],
        ),
      ),
    );
  }
}

String _printDuration(Duration duration) {
  String negativeSign =
      duration.isNegative && duration.inSeconds > 1 ? '-' : '';
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60).abs());
  String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60).abs());
  return "$negativeSign${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}
