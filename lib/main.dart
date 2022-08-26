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
                      mainCMD.value = TCPcmd.T;
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("T CLICK ${mainCMD}");
                    },
                    child: const Text("START")),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.P;
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("P CLICK ${mainCMD}");
                    },
                    child: const Text("STOP")),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.V;
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("T CLICK ${mainCMD}");
                    },
                    child: const Text("Get OES Data")),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.R;
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("R CLICK ${mainCMD}");
                    },
                    child: const Text("All Wl Data Request")),
                const SizedBox(width: 10),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.S;
                      TcpIpCOMMCtrl.to.tdata.value = DateTime.now();
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("S CLICK ${mainCMD}");
                    },
                    child: const Text("Time Sync")),
                const SizedBox(width: 10),
                Text("Cmd : ${TcpIpCOMMCtrl.to.cmdConfirm.value}"),
                const SizedBox(width: 10),
                Text("Error Code ${TcpIpCOMMCtrl.to.errorConfirm.value}"),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(children: [
              // ignore: sized_box_for_whitespace
              Container(
                width: 80,
                height: 25,
                child: TextFormField(
                  // ignore: prefer_const_constructors
                  style: TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  // ignore: prefer_const_constructors
                  decoration: InputDecoration(
                    labelText: "EQ RCP Name",
                    labelStyle: const TextStyle(fontSize: 8),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) eqrcp.value = v;
                    // print("eqrcp ${eqrcp.value}, v : $v");
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(5),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  // ignore: prefer_const_constructors
                  style: TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  // ignore: prefer_const_constructors
                  decoration: InputDecoration(
                    labelText: "EQ Step Name",
                    labelStyle: const TextStyle(fontSize: 8),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) eqstep.value = v;
                    // print("eqrcp ${eqstep.value}, v : $v");
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(5),
                  ],
                ),
              ),
              const SizedBox(
                width: 10,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  // ignore: prefer_const_constructors
                  style: TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  // ignore: prefer_const_constructors
                  decoration: InputDecoration(
                    labelText: "GlassID",
                    labelStyle: const TextStyle(fontSize: 8),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) glassid.value = v;
                    // print("glassid ${glassid.value}, v : $v");
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(5),
                  ],
                ),
              ),
            ]),
            Row(
              children: [
                // ignore: sized_box_for_whitespace
                Container(
                  width: 30,
                  height: 25,
                  child: TextFormField(
                    // ignore: prefer_const_constructors
                    style: TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    // ignore: prefer_const_constructors
                    decoration: InputDecoration(
                      labelText: "Ch1",
                      labelStyle: const TextStyle(fontSize: 8),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) pointNum[0] = int.parse(v);
                      if (v.isEmpty) pointNum[0] = int.parse("0");
                      // print(" pointNum[0] ${pointNum[0]}, v : $v");
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 30,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Ch2",
                      labelStyle: TextStyle(fontSize: 8),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) pointNum[1] = int.parse(v);
                      if (v.isEmpty) pointNum[1] = int.parse("0");
                      // print(" pointNum[1] ${pointNum[1]}, v : $v");
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 30,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Ch3",
                      labelStyle: TextStyle(fontSize: 8),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) pointNum[2] = int.parse(v);
                      if (v.isEmpty) pointNum[2] = int.parse("0");
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 30,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Ch4",
                      labelStyle: TextStyle(fontSize: 8),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) pointNum[3] = int.parse(v);
                      if (v.isEmpty) pointNum[3] = int.parse("0");
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 30,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Ch5",
                      labelStyle: TextStyle(fontSize: 8),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) pointNum[4] = int.parse(v);
                      if (v.isEmpty) pointNum[4] = int.parse("0");
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 30,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Ch6",
                      labelStyle: TextStyle(fontSize: 8),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) pointNum[5] = int.parse(v);
                      if (v.isEmpty) pointNum[5] = int.parse("0");
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 30,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Ch7",
                      labelStyle: TextStyle(fontSize: 8),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) pointNum[6] = int.parse(v);
                      if (v.isEmpty) pointNum[6] = int.parse("0");
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 30,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Ch8",
                      labelStyle: TextStyle(fontSize: 8),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) pointNum[7] = int.parse(v);
                      if (v.isEmpty) pointNum[7] = int.parse("0");
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(1)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 10,
                ),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.U;
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("U CLICK ${mainCMD}");
                    },
                    child: const Text("Channel Setting")),
                // TextButton(
                //   child: Text('Show alert'),
                //   onPressed: () {
                //     showAlertDialog(context);
                //   },
                // ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              children: [
                // ignore: sized_box_for_whitespace
                Container(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Interval",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) ginterval.value = int.parse(v);
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Integration",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gintegration.value = int.parse(v);
                    },
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4)
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                ElevatedButton(
                    onPressed: () {
                      mainCMD.value = TCPcmd.Q;
                      sendFlag(true);
                      // ignore: avoid_print, unnecessary_brace_in_string_interps
                      // print("Q CLICK ${mainCMD}");
                    },
                    child: const Text("Interval Setting")),
              ],
            ),

            const SizedBox(
              height: 20,
            ),
            // ignore: sized_box_for_whitespace
            Row(children: [
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 1",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[0] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              // ignore: sized_box_for_whitespace
              Container(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 2",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[2] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              // ignore: sized_box_for_whitespace
              Container(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 3",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[4] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 4",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[6] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 5",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[8] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 6",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[10] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 7",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[12] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 8",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[14] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 9",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[16] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 10",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[18] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),

              ElevatedButton(
                  onPressed: () {
                    mainCMD.value = TCPcmd.W;
                    sendFlag(true);
                    // ignore: avoid_print, unnecessary_brace_in_string_interps
                    // print("W CLICK ${mainCMD}");
                  },
                  child: const Text("WL Setting")),
            ]),

            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 1",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[1] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 2",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[3] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 3",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[5] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 4",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[7] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 5",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[9] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 6",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[11] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 7",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[13] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 8",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[15] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 9",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[17] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 10",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[19] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
              ],
            ),
            Row(children: [
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 11",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[20] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              // ignore: sized_box_for_whitespace
              Container(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 12",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[22] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              // ignore: sized_box_for_whitespace
              Container(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 13",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[24] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 14",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[26] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 15",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[28] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 16",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[30] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 17",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[32] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 18",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[34] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 19",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[36] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
              SizedBox(
                width: 80,
                height: 25,
                child: TextFormField(
                  style: const TextStyle(
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.end,
                  decoration: const InputDecoration(
                    labelText: "Set Low WL 20",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gwlLHTable[38] = double.parse(v);
                  },
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(6),
                    FilteringTextInputFormatter.allow(
                        RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                  ],
                ),
              ),
              const SizedBox(
                width: 20,
              ),
            ]),
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 11",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[21] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 12",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[23] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                // ignore: sized_box_for_whitespace
                Container(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 13",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[25] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 14",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[27] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 15",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[29] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 16",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[31] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 17",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[33] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 18",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[35] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 19",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[37] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
                const SizedBox(
                  width: 20,
                ),
                SizedBox(
                  width: 80,
                  height: 25,
                  child: TextFormField(
                    style: const TextStyle(
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.end,
                    decoration: const InputDecoration(
                      labelText: "Set High WL 20",
                      labelStyle: TextStyle(fontSize: 10),
                    ),
                    onChanged: (v) {
                      if (v.isNotEmpty) gwlLHTable[39] = double.parse(v);
                    },
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'(\d{0,3})?(\d\.?\d{0,3})')),
                    ],
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
