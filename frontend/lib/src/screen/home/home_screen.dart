import 'package:draw_graph/draw_graph.dart';
import 'package:draw_graph/models/feature.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:pool_temp_app/src/provider/temperature.dart';
import 'package:intl/intl.dart';

class HomeScreen extends HookConsumerWidget {
  HomeScreen({
    Key? key,
  }) : super(key: key);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(deviceIdProvider);

    if (device.isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (device.hasError) {
      return Center(child: Text(device.asError!.error.toString()));
    }

    final currentTemp = ref.watch(currentTempProvider(device.asData!.value));

    if (currentTemp.hasError) {
      return Center(child: Text(currentTemp.asError!.error.toString()));
    }

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
              child: const FittedBox(
                child: Text("Pool Temperatur"),
              ),
            ),
            ListTile(
              title: const Text("Start"),
              onTap: () {
                Navigator.of(context).pop();
              },
            ),
            const Spacer(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Pool Wählen"),
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
                },
              )
            ],
            /*

             */
            iconTheme: const IconThemeData(color: Colors.white),
            backgroundColor: Theme.of(context).primaryColor,
            expandedHeight: 400,
            flexibleSpace: FlexibleSpaceBar(
              background: currentTemp.isLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).cardColor,
                      ),
                    )
                  : FittedBox(
                      child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                              "${(currentTemp.value!.waterTemp * 100).roundToDouble() / 100} C°",
                              style: const TextStyle(color: Colors.white))),
                    ),
              title: const Text(
                "Pool Temperatur",
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
                chartData.when(
                  data: (data) {
                    final dates = data
                        .map((e) => DateTime.fromMillisecondsSinceEpoch(e.time))
                        .toList();
                    print(dates);
                    final maxWaterTemp = data
                        .map((e) => e.waterTemp)
                        .reduce((a, b) => a > b ? a : b);
                    final maxOutsideTemp = data
                        .map((e) => e.outsideTemp)
                        .reduce((a, b) => a > b ? a : b);

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8.0, vertical: 16),
                      child: Column(
                        children: [
                          LineGraph(
                            features: [
                              Feature(
                                title: "Außen Temperatur",
                                color: Colors.red,
                                data: data
                                    .map((e) => e.outsideTemp / maxOutsideTemp)
                                    .toList(),
                              ),
                              Feature(
                                title: "Pool Temperatur",
                                color: Colors.blue,
                                data: data
                                    .map((e) => e.waterTemp / maxWaterTemp)
                                    .toList(),
                              ),
                            ],
                            size: const Size(double.infinity, 400),
                            labelY: [
                              "0",
                              "${(maxWaterTemp * 0.25).round()}",
                              "${(maxWaterTemp * 0.5).round()}",
                              "${(maxWaterTemp * 0.75).round()}",
                              "${maxWaterTemp.round()}"
                            ],
                            labelX: dates
                                .map((e) => DateFormat("HH:mm").format(e))
                                .toList(),
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
                                title: "Luftfeuchtigkeit",
                                color: Colors.blue,
                              ),
                            ],
                            size: const Size(double.infinity, 400),
                            labelX: dates
                                .map((e) => DateFormat("HH:mm").format(e))
                                .toList(),
                            labelY: const [
                              "0",
                              "20",
                              "40",
                              "60",
                              "80",
                              "100",
                            ],
                            showDescription: true,
                          )
                        ],
                      ),
                    );
                  },
                  error: (err, stack) => Text(err.toString()),
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
