import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ffi';
import 'package:get/get.dart';
import 'package:wrma_com/serial_comm.dart';

// ignore: non_constant_identifier_names

DateTime sndtime = DateTime.now();
DateTime rcvtime = DateTime.now();

final DynamicLibrary wgsFunction = DynamicLibrary.open("WGSFunction.dll");
late int Function(int a) serialConnect;
void main() async {
  Get.put(TcpIpCOMMCtrl());
  TcpIpCOMMCtrl.to.init();

  runApp(MyApp());
}

// ignore: use_key_in_widget_constructors
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // final sendFlag = TcpIpCOMMCtrl.to.sendFlag;
    // final mainCMD = TcpIpCOMMCtrl.to.mainCmd;
    return GetMaterialApp(
      title: 'Com_Test',
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            // ignore: prefer_const_constructors
            title: Text('Com_Test'),
          ),
          body: MyLayout()),
    );
  }
}

// ignore: use_key_in_widget_constructors
class MyLayout extends StatelessWidget {
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
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("P CLICK ${mainCMD}");
                    },
                    child: const Text("STOP : P")),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.V;
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("T CLICK ${mainCMD}");
                    },
                    child: const Text("Get OES Data : V")),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.R;
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("R CLICK ${mainCMD}");
                    },
                    child: const Text("All Wl Data Request : R")),
                const SizedBox(width: 20, height: 20),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.S;
                      TcpIpCOMMCtrl.to.tdata.value = DateTime.now();
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("S CLICK ${mainCMD}");
                    },
                    child: const Text("Time Sync : S")),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            Row(children: [
              // ignore: sized_box_for_whitespace
              SizedBox(
                width: 400,
                height: 25,
                child: TextFormField(
                  // ignore: prefer_const_constructors
                  style: TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  // ignore: prefer_const_constructors
                  decoration: InputDecoration(
                    labelText: "RcP Name, StepName, GlassID",
                    labelStyle: const TextStyle(fontSize: 12),
                  ),
                  onChanged: (v) {
                    String temp = v;
                    idlTemp = temp.split(",").toList();
                    if (idlTemp.last == "") {
                      idlTemp.removeLast();
                    }
                    // print("glassid ${glassid.value}, v : $v");
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
                    idlTemp.clear();
                    // ignore: avoid_print, unnecessary_brace_in_string_interps
                    // print("T CLICK ${mainCMD}");
                  },
                  child: const Text("Process START : T")),
            ]),
            const SizedBox(width: 20, height: 20),
            Row(
              children: [
                // ignore: sized_box_for_whitespace
                Container(
                  width: 400,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Channel Number",
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
                      pointNum.clear();
                      if (channelTemp.length == 8) {
                        // ignore: avoid_function_literals_in_foreach_calls
                        channelTemp.forEach((e) {
                          pointNum.add(int.parse(e));
                        });
                        channelTemp.clear();
                      } else if (channelTemp.length < 8) {
                        // ignore: avoid_function_literals_in_foreach_calls
                        channelTemp.forEach((e) {
                          pointNum.add(int.parse(e));
                        });
                        for (int i = 0; i < 8 - channelTemp.length; i++) {
                          pointNum.add(int.parse("0"));
                        }
                        channelTemp.clear();
                      } else {
                        channelTemp.clear();
                        return;
                      }
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("U CLICK ${mainCMD}");
                    },
                    child: const Text("Channel Setting : U")),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            Row(
              children: [
                SizedBox(
                  width: 400,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Interval, Integration",
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
                        sendFlag(true);
                      }
                      // print("Q CLICK ${mainCMD}");
                      if (intervalTemp.isNotEmpty) intervalTemp.clear();
                    },
                    child: const Text("Interval, Integration Setting : Q")),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            // ignore: sized_box_for_whitespace
            Row(children: [
              SizedBox(
                width: 1700,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "WL Value",
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
              // ignore: sized_box_for_whitespace
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
                    if (wlTemp.isNotEmpty) wlTemp.clear();
                    sendFlag(true);
                  },
                  child: const Text("WL Setting : W")),
            ]),
            const SizedBox(width: 20, height: 20),
            const Divider(),
            // ignore: prefer_const_literals_to_create_immutables
            Row(children: [
              const Text("Respond"),
            ]),
            const SizedBox(width: 20, height: 20),
            Row(
              children: [
                const SizedBox(width: 20, height: 20),
                Text("Cmd : ${TcpIpCOMMCtrl.to.cmdConfirm.value}"),
                const SizedBox(width: 20, height: 20),
                Text("Error Code ${TcpIpCOMMCtrl.to.errorConfirm.value}"),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            Row(
              children: [
                const SizedBox(width: 20, height: 20),
                Text("Wl Table ${TcpIpCOMMCtrl.to.wlTableMain}"),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            Row(
              children: [
                const SizedBox(width: 20, height: 20),
                Text("Wl LowHight ${TcpIpCOMMCtrl.to.wLLowHighTableMain}"),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            Row(
              children: [
                const SizedBox(width: 20, height: 20),
                Text("받아온 시간 :  ${TcpIpCOMMCtrl.to.getTimeMain.value}"),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            Row(
              children: [
                const SizedBox(width: 20, height: 20),
                Text("받아온 channel :  ${TcpIpCOMMCtrl.to.getChannelMain.value}"),
              ],
            ),
            const SizedBox(width: 20, height: 20),
            Row(
              children: [
                const SizedBox(width: 20, height: 20),
                Text("받아온 Intensity :  ${TcpIpCOMMCtrl.to.intensityMain}"),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
