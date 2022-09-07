import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wrma_com/serial_comm.dart';
import 'package:window_manager/window_manager.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

// ignore: non_constant_identifier_names
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  Get.put(TcpIpCOMMCtrl());
  TcpIpCOMMCtrl.to.init();

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitleBarStyle(
      TitleBarStyle.normal,
      windowButtonVisibility: true,
    );
    await windowManager.setSize(const Size(1920, 1020));
    await windowManager.setMinimumSize(const Size(1920, 1020));
    await windowManager.center();
    await windowManager.focus();
    await windowManager.show();
    await windowManager.setPreventClose(false);
    await windowManager.setSkipTaskbar(false);
  });

  runApp(MyApp());
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Com_Test',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,

            // ignore: prefer_const_constructors
            title: Text('Com_Test'),
          ),
          body: const MyLayout()),
    );
  }
}

class MyLayout extends StatefulWidget {
  const MyLayout({Key? key}) : super(key: key);

  @override
  State<MyLayout> createState() => _MyLayout();
}

// ignore: use_key_in_widget_constructors
class _MyLayout extends State<MyLayout> {
  TextEditingController idT =
      TextEditingController(text: "EQRCP,EQSTEP,GlassID");
  TextEditingController chU = TextEditingController(text: "1,2,3,4,5,6,7,8");
  TextEditingController intervalIntegrarionQ =
      TextEditingController(text: "200,100");
  TextEditingController lowHighW = TextEditingController(
      text:
          "162.06,170.42,162.79,180.15,163.52,180.89,164.25,190.62,164.98,200.35,165.72,210.08,166.45,230.82,167.18,240.55,167.92,250.28,168.65,260.02,169.38,270.75,170.12,280.48,170.85,290.22,171.59,300.95,172.32,310.69,173.06,320.42,173.79,330.16,174.52,340.89,175.26,350.63,176.56,400.36");
  @override
  Widget build(BuildContext context) {
    final sendFlag = TcpIpCOMMCtrl.to.sendFlag;
    final mainCMD = TcpIpCOMMCtrl.to.mainCmd;
    final pointNum = TcpIpCOMMCtrl.to.pointNum;
    final ginterval = TcpIpCOMMCtrl.to.interval;
    final gintegration = TcpIpCOMMCtrl.to.integration;
    final gwlLHTable = TcpIpCOMMCtrl.to.wlLHTable;
    final eqrcp = TcpIpCOMMCtrl.to.eqRcp;
    final eqstep = TcpIpCOMMCtrl.to.eqStep;
    final glassid = TcpIpCOMMCtrl.to.glassId;
    List<String> wlTemp = List.empty();
    List<String> intervalTemp = List.empty();
    List<String> channelTemp = List.empty();
    List<String> idlTemp = List.empty();

    return Obx(
      () => Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.P;
                      sendFlag(true);
                    },
                    child: const Text("STOP : P")),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.V;
                      sendFlag(true);
                    },
                    child: const Text("Get OES Data : V")),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.R;
                      sendFlag(true);
                    },
                    child: const Text("All Wl Data Request : R")),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.S;
                      TcpIpCOMMCtrl.to.tdata.value = DateTime.now();
                      sendFlag(true);
                    },
                    child: const Text("Time Sync : S")),
                const SizedBox(width: 20, height: 20),
                SizedBox(
                  width: 200,
                  height: 25,
                  child: TextFormField(
                    controller: idT,
                    // ignore: prefer_const_constructors
                    style: TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    // ignore: prefer_const_constructors
                    decoration: InputDecoration(
                      labelText: "RN, SN, GID",
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                    onChanged: (v) {
                      String temp = v.toString();
                      idlTemp = temp.split(",").toList();
                      if (idlTemp.last == "") {
                        idlTemp.removeLast();
                      }
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                  ),
                ),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.T;
                      if (idlTemp.length != 3) return;
                      if (idlTemp.length == 3) {
                        eqrcp.value = idlTemp[0];
                        eqstep.value = idlTemp[1];
                        glassid.value = idlTemp[2];
                        sendFlag(true);
                      }
                    },
                    child: const Text("Process START : T")),
                const SizedBox(width: 20, height: 20),
                SizedBox(
                  width: 100,
                  height: 25,
                  child: TextFormField(
                    controller: chU,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "ChN",
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    onChanged: (v) {
                      if (v != "") {
                        String temp = v;
                        channelTemp = temp.split(",").toList();
                        if (channelTemp.last == "") {
                          channelTemp.removeLast();
                        }
                      }
                    },
                    inputFormatters: [LengthLimitingTextInputFormatter(15)],
                  ),
                ),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.U;
                      if (channelTemp.isEmpty) return;
                      if (channelTemp.length > 8) return;
                      pointNum.clear();
                      if (channelTemp.length == 8) {
                        // ignore: avoid_function_literals_in_foreach_calls
                        channelTemp.forEach((e) {
                          pointNum.add(int.parse(e));
                        });
                      } else {
                        // ignore: avoid_function_literals_in_foreach_calls
                        channelTemp.forEach((e) {
                          pointNum.add(int.parse(e));
                        });
                        for (int i = 0; i < 8 - channelTemp.length; i++) {
                          pointNum.add(int.parse("0"));
                        }
                      }
                      sendFlag(true);
                    },
                    child: const Text("Channel Setting : U")),
                const SizedBox(width: 20, height: 20),
                SizedBox(
                  width: 100,
                  height: 25,
                  child: TextFormField(
                    controller: intervalIntegrarionQ,
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "I, I",
                      labelStyle: TextStyle(fontSize: 12),
                    ),
                    onChanged: (v) {
                      if (v != "") {
                        String temp = v;
                        intervalTemp = temp.split(",").toList();
                        if (intervalTemp.last == "") {
                          intervalTemp.removeLast();
                        }
                      }
                    },
                    inputFormatters: [LengthLimitingTextInputFormatter(9)],
                  ),
                ),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.Q;
                      if (intervalTemp.length == 2) {
                        ginterval.value = int.parse(intervalTemp[0]);
                        gintegration.value = int.parse(intervalTemp[1]);
                      }
                      sendFlag(true);
                    },
                    child: const Text("Interval, Integration Setting : Q")),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            Row(children: [
              SizedBox(
                width: 1700,
                height: 25,
                child: TextFormField(
                  controller: lowHighW,
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "WL LH Value",
                    labelStyle: TextStyle(fontSize: 12),
                  ),
                  onChanged: (v) {
                    if (v != "") {
                      String temp = v;
                      wlTemp = temp.split(",").toList();
                      if (wlTemp.last == "") {
                        wlTemp.removeLast();
                      }
                    }
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(279),
                  ],
                ),
              ),
              const SizedBox(width: 20, height: 20),
              ElevatedButton(
                  onPressed: () {
                    mainCMD.value = TCPcmd.W;
                    gwlLHTable.clear();
                    for (int i = 0; i < wlTemp.length; i++) {
                      gwlLHTable.add(double.parse(wlTemp[i]));
                    }
                    if (gwlLHTable.length != 40) {
                      for (int i = 0; i < 40 - wlTemp.length; i++) {
                        gwlLHTable.add(double.parse("0.0"));
                      }
                    }
                    sendFlag(true);
                  },
                  child: const Text("WL Setting : W")),
            ]),
            const Divider(height: 5),
            // ignore: prefer_const_literals_to_create_immutables
            Row(children: [
              const Text("Response"),
              const SizedBox(width: 20, height: 20),
              Text(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  "Rcv Cmd : ${TcpIpCOMMCtrl.to.cmdConfirm.value}"),
              const SizedBox(width: 20, height: 20),
              Text(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  "Rcv Error Code ${TcpIpCOMMCtrl.to.errorConfirm.value}"),
              const SizedBox(width: 20, height: 20),
              Text(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  "Rcv 시간 :  ${TcpIpCOMMCtrl.to.getTimeMain.value}"),
              const SizedBox(width: 20, height: 20),
              Text(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  "Rcv channel :  ${TcpIpCOMMCtrl.to.getChannelMain.value}"),
            ]),
            const SizedBox(width: 10, height: 10),
            Row(
              children: [
                Text(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    "Rcv All WL Table ${TcpIpCOMMCtrl.to.wlTableMain}"),
              ],
            ),
            const SizedBox(width: 10, height: 10),
            Row(
              children: [
                Text(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    "Rcv Range Low Hight ${TcpIpCOMMCtrl.to.wLLowHighTableMain}"),
              ],
            ),
            const SizedBox(width: 10, height: 10),
            Row(
              children: [
                Text(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    "Rcv Intensity :  ${TcpIpCOMMCtrl.to.intensityMain}"),
              ],
            ),
            const SizedBox(width: 10, height: 10),
            //chart
            Row(children: const [
              SizedBox(width: 10, height: 10),
              SizedBox(
                width: 450,
                height: 350,
                child: ChartSample(
                  index: 0,
                  channel: "1",
                ),
              ),
              SizedBox(width: 10, height: 10),
              SizedBox(
                  width: 450,
                  height: 350,
                  child: ChartSample(
                    index: 1,
                    channel: "2",
                  )),
              SizedBox(width: 10, height: 10),
              SizedBox(
                  width: 450,
                  height: 350,
                  child: ChartSample(
                    index: 2,
                    channel: "3",
                  )),
              SizedBox(width: 10, height: 10),
              SizedBox(
                  width: 450,
                  height: 350,
                  child: ChartSample(
                    index: 3,
                    channel: "4",
                  )),
            ]),
            const SizedBox(width: 10, height: 10),
            Row(children: const [
              SizedBox(width: 10, height: 10),
              SizedBox(
                  width: 450,
                  height: 350,
                  child: ChartSample(
                    index: 4,
                    channel: "5",
                  )),
              SizedBox(width: 10, height: 10),
              SizedBox(
                  width: 450,
                  height: 350,
                  child: ChartSample(
                    index: 5,
                    channel: "6",
                  )),
              SizedBox(width: 10, height: 10),
              SizedBox(
                  width: 450,
                  height: 350,
                  child: ChartSample(
                    index: 6,
                    channel: "7",
                  )),
              SizedBox(width: 10, height: 10),
              SizedBox(
                  width: 450,
                  height: 350,
                  child: ChartSample(
                    index: 7,
                    channel: "8",
                  )),
            ]),
          ],
        ),
      ),
    );
  }
}

class ChartSample extends StatelessWidget {
  const ChartSample({
    Key? key,
    required this.index,
    required this.channel,
  }) : super(key: key);

  final int index;
  final String channel;
  @override
  Widget build(BuildContext context) {
    return Obx(() => LineChart(LineChartData(
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                reservedSize: 50,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
                reservedSize: 50,
              ),
            ),
            topTitles: AxisTitles(
              axisNameWidget: Text("$channel Chart"),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 10,
              ),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: false,
              ),
            ),
          ),
          minX: 0,
          minY: 0,

          lineTouchData: LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            distanceCalculator: (touchPoint, spotPixelCoordinates) {
              // 정확한 spot 찾기
              final x = (touchPoint.dx - spotPixelCoordinates.dx).abs();
              final y = (touchPoint.dy - spotPixelCoordinates.dy).abs();
              final spot = math.sqrt(x * x + y * y);
              return spot;
            },
            mouseCursorResolver:
                (FlTouchEvent event, LineTouchResponse? touchResponse) {
              // 마우스 Hover 커서 변경
              return touchResponse == null || touchResponse.lineBarSpots == null
                  ? MouseCursor.defer
                  : SystemMouseCursors.click;
            },
            touchTooltipData: LineTouchTooltipData(
              tooltipMargin: 0,
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipRoundedRadius: 4,
              maxContentWidth: 600,
              tooltipBgColor: Colors.black,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((LineBarSpot touchedSpot) {
                  const textStyle =
                      TextStyle(fontSize: 14, color: Colors.white);
                  final y = touchedSpot.y;
                  final str = '$y';
                  return LineTooltipItem(str, textStyle,
                      textAlign: TextAlign.center);
                }).toList();
              },
            ),
            touchSpotThreshold: 10,
            getTouchLineEnd: (barData, spotIndex) => 0,
          ),
          lineBarsData: createFullSeries(index), //
        )));
  }

  List<LineChartBarData> createFullSeries(int index) {
    List<LineChartBarData> rt = [];
    if (TcpIpCOMMCtrl.to.fullSeries[index].isNotEmpty) {
      for (var i = 0; i < 20; i++) {
        rt.add(
          LineChartBarData(
            spots: TcpIpCOMMCtrl.to.fullSeries[index][i],
            // color: ,
            barWidth: 1,
            dotData: FlDotData(
              show: false,
            ),
          ),
        );
      }
    }
    return rt;
  }
}
