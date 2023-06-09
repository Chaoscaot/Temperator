import 'dart:math';

import 'package:animations/animations.dart';
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

class HomeScreen extends HookConsumerWidget {
  HomeScreen({
    Key? key,
  }) : super(key: key);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTemp = useState(0);
    final lastSelectedTemp = useState(0);

    final device = ref.watch(deviceIdProvider);

    if (device.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (device.hasError) {
      final error = ErrorObject(
        error: device.error.toString(),
        stackTrace: StackTrace.current.toString(),
        onRetry: (context) {
          ref.invalidate(deviceIdProvider);
        },
      );
      return ErrorScreen(errorObject: error);
    }

    final currentTemp = ref.watch(currentTempProvider(device.asData!.value));

    if (currentTemp.hasError) {
      final error = ErrorObject(
        error: currentTemp.error.toString(),
        stackTrace: StackTrace.current.toString(),
        onRetry: (context) {
          ref.invalidate(currentTempProvider(device.asData!.value));
        },
      );
      return ErrorScreen(errorObject: error);
    }

    final status = ref.watch(deviceStatusProvider(device.asData!.value));
    final chartData = ref.watch(chartDataProvider(device.asData!.value));

    return Scaffold(
      drawerEnableOpenDragGesture: true,
      key: _scaffoldKey,
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
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
                  ref.invalidate(currentTempProvider(device.asData!.value));
                  ref.invalidate(chartDataProvider(device.asData!.value));
                  ref.invalidate(deviceStatusProvider(device.asData!.value));
                },
              )
            ],
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Theme.of(context).primaryColor,
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
                                        const TextStyle(
                                            color: Colors.white, fontSize: 10),
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
                                    children: [
                                      Text(
                                          "${NumberFormat.decimalPatternDigits(decimalDigits: 1).format(currentTemp.value!.waterTemp)} C°",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 64)),
                                      Text(
                                          "${NumberFormat.decimalPatternDigits(decimalDigits: 1).format(currentTemp.value!.outsideTemp)} C°",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 64)),
                                      Text(
                                          "${NumberFormat.decimalPatternDigits(decimalDigits: 1).format(currentTemp.value!.humidity)} %",
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 64)),
                                    ],
                                  ),
                                ),
                                Text(
                                    DateFormat.yMd().add_Hm().format(
                                        DateTime.fromMillisecondsSinceEpoch(
                                            currentTemp.value!.time)),
                                    style: const TextStyle(
                                        color: Colors.white70, fontSize: 16)),
                                const Spacer(flex: 1),
                                Row(
                                  children: [
                                    status.when(data: (data) {
                                      return IconButton(
                                        onPressed: () {
                                          showDialog(
                                            context: context,
                                            builder: (context) {
                                              return AlertDialog(
                                                title: Text(
                                                    "Status: ${data.status}"),
                                                content: Text(DateFormat.yMd()
                                                    .add_Hm()
                                                    .format(DateTime
                                                        .fromMillisecondsSinceEpoch(
                                                            data.time))),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: const Text("OK"),
                                                  )
                                                ],
                                              );
                                            },
                                          );
                                        },
                                        icon: Icon(
                                          data.status == "ok"
                                              ? (DateTime.fromMillisecondsSinceEpoch(
                                                              data.time)
                                                          .difference(
                                                              DateTime.now())
                                                          .inMinutes >
                                                      20
                                                  ? Icons.question_mark
                                                  : Icons.check_circle_outline)
                                              : Icons.error_outline,
                                          color: data.status == "ok"
                                              ? (DateTime.fromMillisecondsSinceEpoch(
                                                              data.time)
                                                          .difference(
                                                              DateTime.now())
                                                          .inMinutes >
                                                      20
                                                  ? Colors.grey
                                                  : Colors.green)
                                              : Colors.red,
                                        ),
                                      );
                                    }, error: (err, stack) {
                                      return IconButton(
                                        onPressed: () {
                                          context.push(
                                            "/error",
                                            extra: ErrorObject(
                                              error: err.toString(),
                                              stackTrace: stack.toString(),
                                              onRetry: (context) {
                                                context.pop();
                                              },
                                            ),
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.warning_amber_outlined,
                                          color: Colors.red,
                                        ),
                                      );
                                    }, loading: () {
                                      return const IconButton(
                                        onPressed: null,
                                        icon: Icon(
                                          Icons.refresh_outlined,
                                          color: Colors.white,
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ],
                            ),
                          )),
                    ),
              title: Text(title()),
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
                chartData.when(
                  data: (data) {
                    if (data.isEmpty) {
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
