import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ffi';
import 'package:get/get.dart';
import 'package:wrma_com/serial_comm.dart';

// ignore: non_constant_identifier_names
RxList<double> gSWLTB = List<double>.filled(20, 0.00).obs;

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
    final sendFlag = TcpIpCOMMCtrl.to.sendFlag;
    final mainCMD = TcpIpCOMMCtrl.to.mainCmd;
    return MaterialApp(
      title: 'Com_Test',
      home: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
            // ignore: prefer_const_constructors
            title: Text('Com_Test'),
            actions: [
              ElevatedButton(
                  onPressed: () {
                    mainCMD.value = TCPcmd.T;
                    sendFlag(true);
                    // ignore: avoid_print, unnecessary_brace_in_string_interps
                    // print("T CLICK ${mainCMD}");
                  },
                  child: const Text("START")),
              SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () {
                    mainCMD.value = TCPcmd.P;
                    sendFlag(true);
                    // ignore: avoid_print, unnecessary_brace_in_string_interps
                    // print("P CLICK ${mainCMD}");
                  },
                  child: const Text("STOP")),
              SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () {
                    mainCMD.value = TCPcmd.V;
                    sendFlag(true);
                    // ignore: avoid_print, unnecessary_brace_in_string_interps
                    // print("T CLICK ${mainCMD}");
                  },
                  child: const Text("Get OES Data")),
              SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () {
                    mainCMD.value = TCPcmd.R;
                    sendFlag(true);
                    // ignore: avoid_print, unnecessary_brace_in_string_interps
                    // print("R CLICK ${mainCMD}");
                  },
                  child: const Text("GWLTB")),
              SizedBox(width: 10),
              ElevatedButton(
                  onPressed: () {
                    mainCMD.value = TCPcmd.S;
                    sendFlag(true);
                    // ignore: avoid_print, unnecessary_brace_in_string_interps
                    // print("S CLICK ${mainCMD}");
                  },
                  child: const Text("T")),
              SizedBox(width: 650),
            ],
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
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [],
          ),
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
                    print(" pointNum[0] ${pointNum[0]}, v : $v");
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
                    print(" pointNum[1] ${pointNum[1]}, v : $v");
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
                  child: const Text("SC")),
              // TextButton(
              //   child: Text('Show alert'),
              //   onPressed: () {
              //     showAlertDialog(context);
              //   },
              // ),
            ],
          ),
          Row(
            children: [
              // ignore: sized_box_for_whitespace
              Container(
                width: 50,
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
              Container(
                width: 50,
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
              ElevatedButton(
                  onPressed: () {
                    mainCMD.value = TCPcmd.Q;
                    sendFlag(true);
                    // ignore: avoid_print, unnecessary_brace_in_string_interps
                    // print("Q CLICK ${mainCMD}");
                  },
                  child: const Text("SI")),
            ],
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
                    labelText: "Set WLT 1",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gSWLTB[0] = double.parse(v);
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
                    labelText: "Set WLT 2",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gSWLTB[1] = double.parse(v);
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
                    labelText: "Set WLT 3",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gSWLTB[2] = double.parse(v);
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
                    labelText: "Set WLT 4",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gSWLTB[3] = double.parse(v);
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
                    labelText: "Set WLT 5",
                    labelStyle: TextStyle(fontSize: 10),
                  ),
                  onChanged: (v) {
                    if (v.isNotEmpty) gSWLTB[4] = double.parse(v);
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
                  child: const Text("SWLTB")),
            ],
          ),
          Row(
              // children: [ListView()],
              )
        ],
      ),
    );
  }
}
