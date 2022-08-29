// ignore_for_file: constant_identifier_names, unrelated_type_equality_checks
import 'dart:async';
// import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

enum TCPcmd {
  NONE, // normal
  V, // intensity get
  T, // process start
  W, // Range setting
  P, // Stop
  R, // All waveLength 파장값
  S, // timesync
  Q, // interval, integration setting
  U, // channel moving
}

enum TCPcmdreply { NONE, ACK, ERROR }

class TcpIpCOMMCtrl extends GetxController {
  static TcpIpCOMMCtrl get to => Get.find();
  late Isolate isolate;
  SendPort? isoSendPort;
  String hostname = '192.168.1.6';
  int port = 8000;
  Rx<TCPcmd> mainCmd = TCPcmd.NONE.obs;
  RxBool sendFlag = false.obs;
  RxList<int> pointNum = List.filled(8, 0).obs;
  Rx<int> interval = 100.obs;
  Rx<int> integration = 100.obs;
  RxList<double> wlLHTable = List.filled(40, 0.00).obs;
  Rx<DateTime> tdata = DateTime.now().obs;
  Rx<String> eqRcp = "EQRCP".obs;
  Rx<String> eqStep = "EQSTEP".obs;
  Rx<String> glassId = "GlassID".obs;
  Rx<String> cmdConfirm = "0".obs;
  Rx<String> errorConfirm = "0".obs;
  RxList<double> wlTableMain = RxList.empty();
  RxList<double> wLLowHighTableMain = RxList.empty();
  RxList<int> intensityMain = RxList.empty();
  Rx<DateTime> getTimeMain = DateTime.now().obs;
  Rx<int> getChannelMain = 0.obs;

  static TCPcmd rcvCmd = TCPcmd.NONE;
  static int errorCode = 0;
  static int intervalRcv = 0;
  static DateTime getTime = DateTime.now();
  static List<double> wlTable = [];
  static List<double> wLLowHighTable = [];
  static List<int> intensity = [];
  static bool flagRcv = false;
  static int channelNumber = 0;
  static List<bool> checkflag = [false, false, false, false];

  static RxList<String> gch = RxList.empty();
  static List<double> nlistWaveLength = [];
  static DateTime rcvtime = DateTime.now();

  Future<void> init() async {
    TcpIpCOMMIsolateStart();
  }

  // ignore: non_constant_identifier_names
  TcpIpCOMMIsolateStart() async {
    ReceivePort rcvPort = ReceivePort(); // isolate port
    // main => isolate로 보낼 데이터
    TcpIpCOMMhIsolateSendData data = TcpIpCOMMhIsolateSendData(
        ip: hostname,
        port: port,
        sendPort: rcvPort.sendPort, // isolate로 보낼 port
        data: TcpIpCOMMSendDataComponent(
          cmd: TCPcmd.NONE,
        ));

    isolate = await Isolate.spawn(tcpIpCOMMIsolateRcv, data);

    // main rcv
    // isolate => main : main이 받는다
    rcvPort.listen((data) async {
      // print("main rcv : ${data.data}");
      if (data is SendPort) {
        isoSendPort = data;
      }

      if (data is TcpIpCOMMIsolateReceiveData) {
        cmdConfirm.value = data.data.cmd.toString();
        errorConfirm.value = data.data.errorcode.toString();
        switch (data.data.cmd) {
          case TCPcmd.V:
            intensityMain.clear();
            getTimeMain.value = data.data.getTime!;
            getChannelMain.value = data.data.channelnum!;
            data.data.intensity?.forEach((e) => intensityMain.add(e));
            break;
          case TCPcmd.T:
            break;
          case TCPcmd.W:
            wLLowHighTableMain.clear();
            data.data.wLLowHighTable?.forEach((e) => wLLowHighTableMain.add(e));
            break;
          case TCPcmd.P:
            break;
          case TCPcmd.R:
            wlTableMain.clear();
            data.data.wlTable?.forEach((v) => wlTableMain.add(v));
            break;
          case TCPcmd.S:
            break;
          case TCPcmd.Q:
            break;
          case TCPcmd.U:
            break;
          default:
        }
      }
    });

    // main send
    // main => isolate 던진다.
    // TcpIpCOMMSendDataComponent
    ever(
      sendFlag,
      (v) {
        if (v == true) {
          isoSendPort?.send(TcpIpCOMMSendDataComponent(
            cmd: mainCmd.value,
            eqrcp: eqRcp.value,
            eqstep: eqStep.value,
            glassid: glassId.value,
            wLLowHighTable: wlLHTable,
            pointNo: pointNum,
            dateTime: tdata.value,
            intervalTime: interval.value,
            integrationTime: integration.value,
            checkflag: List<bool>.filled(10, false),
          ));
          sendFlag(false);
        }
      },
    );
  }

  // isolate
  static void tcpIpCOMMIsolateRcv(TcpIpCOMMhIsolateSendData iSD) async {
    var rcvport = ReceivePort(); // isolate 받는 포트
    iSD.sendPort.send(rcvport.sendPort); // main 이랑 isolate 연결
    final ip = iSD.ip;
    final port = iSD.port;

    // Server랑 연결
    Socket socket = await Socket.connect(ip, port);
    // ignore: avoid_print
    print(
        'TCP client started connecting state : ${socket.address}:${socket.port}.');

    try {
      // listen to the received data event stream

      // socket listen
      socket.listen((Uint8List data) {
        // ignore: avoid_print
        List<int> rcvbuf = []; // Data 처리용
        var ackNak = 0;
        rcvbuf.clear();
        rcvbuf.addAll(data);
        final cmdstr = String.fromCharCode(rcvbuf[0]);
        rcvCmd = TCPcmd.values.firstWhere(
            (e) => e.toString() == 'TCPcmd.$cmdstr',
            orElse: () => TCPcmd.NONE);
        rcvbuf.removeAt(0); // cmd 자르기
        ackNak = rcvbuf[0];
        rcvbuf.removeAt(0); // ack/nak 자르기
        switch (rcvCmd) {
          case TCPcmd.V:
            // intensity data main 으로 작업 필요
            if (ackNak == 0x06) {
              int tempLength = rcvbuf[0];
              rcvbuf.removeAt(0); // length 지우기
              if (tempLength == rcvbuf.length) {
                List<String> tempbuf = String.fromCharCodes(rcvbuf).split(',');
                // print("tempbuf : ${tempbuf}");
                // ignore: prefer_interpolation_to_compose_strings
                getTime = DateTime.parse('20' +
                    tempbuf[0].substring(0, 6) +
                    'T' +
                    tempbuf[0].substring(6, 12) +
                    '.' +
                    tempbuf[0].substring(12));
                tempbuf.removeAt(0); // tempbuf의 날짜 지우기
                tempbuf.removeAt(0); // tempbuf의 channel num 지우기
                for (int i = 0; i < 16; i++) {
                  rcvbuf.removeAt(0); // 날짜 지우기
                }
                channelNumber = rcvbuf[0];
                rcvbuf.removeAt(0); // channel num 지우기
                intensity.clear();
                // ignore: avoid_function_literals_in_foreach_calls
                tempbuf.forEach((e) => intensity.add(int.parse(e)));
                tempbuf.clear();
              }
              // print("V");
            } else {
              errorCode = rcvbuf[0];
            }
            rcvbuf.clear();
            break;
          case TCPcmd.T:
            // 완료
            if (ackNak == 0x06) {
              errorCode = rcvbuf[0];
              // print("T");
            } else {
              errorCode = rcvbuf[0];
            }
            rcvbuf.clear();
            break;
          case TCPcmd.W:
            // waveLength low high 받아야함
            if (ackNak == 0x06) {
              List<int> tempNum = [];
              List<int> tempLength = [];
              tempNum.add(rcvbuf[0]);
              tempNum.add(rcvbuf[1]);
              Uint8List tempTotalLength = Uint8List.fromList(tempNum);
              tempLength.add(tempTotalLength.buffer.asByteData().getInt16(0));
              tempNum.clear();
              rcvbuf.removeAt(0);
              rcvbuf.removeAt(0);
              wLLowHighTable.clear();
              if (tempLength[0] == rcvbuf.length) {
                var buf_1 = String.fromCharCodes(rcvbuf).split(',');
                // ignore: avoid_function_literals_in_foreach_calls
                buf_1.forEach((e) => wLLowHighTable.add(double.parse(e)));
                buf_1.clear();
              }
              tempLength.clear();
            } else {
              errorCode = rcvbuf[0];
            }
            rcvbuf.clear();
            break;
          case TCPcmd.P:
            // 완료
            if (ackNak == 0x06) {
              errorCode = rcvbuf[0];
              // print("V");
            } else {
              errorCode = rcvbuf[0];
            }
            rcvbuf.clear();
            break;
          case TCPcmd.R:
            if (ackNak == 0x06) {
              List<int> tempNum = [];
              List<int> tempLength = [];
              tempNum.add(rcvbuf[0]);
              tempNum.add(rcvbuf[1]);
              Uint8List tempTotalLength = Uint8List.fromList(tempNum);
              tempLength.add(tempTotalLength.buffer.asByteData().getInt16(0));
              tempNum.clear();
              rcvbuf.removeAt(0);
              rcvbuf.removeAt(0);
              wlTable.clear();
              if (tempLength[0] == rcvbuf.length) {
                var buf_1 = String.fromCharCodes(rcvbuf).split(',');
                // ignore: avoid_function_literals_in_foreach_calls
                buf_1.forEach((e) => wlTable.add(double.parse(e)));
                buf_1.clear();
              }
              tempLength.clear();
            } else {
              errorCode = rcvbuf[0];
            }
            rcvbuf.clear();
            break;
          case TCPcmd.S:
            if (ackNak == 0x06) {
              errorCode = rcvbuf[0];
              // print("S");
            } else {
              errorCode = rcvbuf[0];
            }
            rcvbuf.clear();
            break;
          case TCPcmd.Q:
            if (ackNak == 0x06) {
              errorCode = rcvbuf[0];
              // print("Q");
            } else {
              errorCode = rcvbuf[0];
            }
            rcvbuf.clear();
            break;
          case TCPcmd.U:
            if (ackNak == 0x06) {
              errorCode = rcvbuf[0];
              // print("U");
            } else {
              errorCode = rcvbuf[0];
            }
            rcvbuf.clear();
            break;
          case TCPcmd.NONE:
            break;
        }
        if (rcvCmd == TCPcmd.NONE) return;
        iSD.sendPort.send(TcpIpCOMMIsolateReceiveData(
            sendPort: rcvport.sendPort,
            data: TcpIpCOMMReceiveDataComponent(
              cmd: rcvCmd,
              errorcode: errorCode,
              interval: intervalRcv,
              channelnum: channelNumber,
              getTime: getTime,
              wlTable: wlTable,
              wLLowHighTable: wLLowHighTable,
              intensity: intensity,
              sendflag: flagRcv,
              checkflag: checkflag,
            )));
        rcvCmd = TCPcmd.NONE;
        errorCode = 0;
        rcvbuf.clear();
      });
    } on SocketException catch (ex) {
      // ignore: avoid_print
      print(ex.message);
    }

    // isolate rcv
    // main => isolate : isolate가 받고 Socket write
    rcvport.listen((data) async {
      // print("isolate rcv  ${data.cmd}");
      if (data is TcpIpCOMMSendDataComponent) {
        if (data.cmd == TCPcmd.NONE) return;
        List<int> buf = [];
        switch (data.cmd) {
          case TCPcmd.V:
            String v = "V";
            buf.addAll(v.codeUnits);
            buf.addAll([0x07]);
            String oes = "OESDATA";
            buf.addAll(oes.codeUnits);
            socket.write(buf);
            print("V : ${buf}");
            buf.clear();
            break;
          case TCPcmd.T:
            String t = "T";
            buf.addAll(t.codeUnits);
            final int eqrcp = data.eqrcp?.length as int;
            final int eqstep = data.eqstep?.length as int;
            final int glassid = data.glassid?.length as int;
            final length = eqrcp + eqstep + glassid + 2;
            buf.add(length);
            buf.addAll(data.eqrcp.toString().codeUnits);
            buf.addAll([0x2C]);
            buf.addAll(data.eqstep.toString().codeUnits);
            buf.addAll([0x2C]);
            buf.addAll(data.glassid.toString().codeUnits);
            socket.write(buf);
            print("T : ${buf}");
            buf.clear();
            break;
          case TCPcmd.W:
            String w = "W";
            buf.addAll(w.codeUnits);
            List<String> temp = [];
            data.wLLowHighTable?.forEach((e) {
              temp.add(e.toString());
              temp.add(",");
            });
            temp.removeLast();
            List<int> tempbuf = [];
            // ignore: avoid_function_literals_in_foreach_calls
            temp.forEach((e) {
              tempbuf.addAll(e.codeUnits);
            });
            temp.clear();
            buf.insertAll(
                1,
                Uint8List(2)
                  ..buffer
                      .asByteData()
                      .setInt16(0, tempbuf.length, Endian.big));
            // ignore: avoid_function_literals_in_foreach_calls
            tempbuf.forEach((e) {
              buf.add(e);
            });
            socket.write(buf);
            tempbuf.clear();
            print("W : ${buf}");
            buf.clear();
            break;
          case TCPcmd.P:
            String p = "P";
            buf.addAll(p.codeUnits);
            buf.addAll([0x00]);
            socket.write(buf);
            print("P : ${buf}");
            buf.clear();
            break;
          case TCPcmd.R:
            String r = "R";
            buf.addAll(r.codeUnits);
            buf.addAll([0x00]);
            socket.write(buf);
            print("R : ${buf}");
            buf.clear();
            break;
          case TCPcmd.S:
            String s = "S";
            buf.addAll(s.codeUnits);
            buf.addAll([0x0f]);
            String patten = "yyMMddHHmmssSSS";
            DateTime tempTime = data.dateTime!;
            String dateTime = DateFormat(patten).format(tempTime);
            buf.addAll(dateTime.codeUnits);
            socket.write(buf);
            print("S : ${buf}");
            buf.clear();
            break;
          case TCPcmd.Q:
            String q = "Q";
            buf.addAll(q.codeUnits);
            String sendInterval = data.intervalTime.toString();
            String sendIntegration = data.integrationTime.toString();
            final length = sendInterval.length + sendIntegration.length + 1;
            buf.add(length);
            buf.addAll(sendInterval.codeUnits);
            buf.addAll([0x2C]);
            buf.addAll(sendIntegration.codeUnits);
            socket.write(buf);
            print("Q : ${buf}");
            buf.clear();
            break;
          case TCPcmd.U:
            // ignore: prefer_is_empty
            if (data.pointNo != null && data.pointNo?.length != 0) {
              String u = "U";
              buf.addAll(u.codeUnits);
              List<String> temp = [];
              data.pointNo?.forEach((e) {
                temp.add(e.toString());
                temp.add(",");
              });
              temp.removeLast();
              final tempLength = temp.length;
              // print("tempLength : ${tempLength}");
              buf.add(tempLength);
              // ignore: avoid_function_literals_in_foreach_calls
              temp.forEach((e) {
                buf.addAll(e.codeUnits);
              });
              socket.write(buf);
              temp.clear();
            }
            // ignore: avoid_print
            print("U : $buf");
            buf.clear();
            break;
          default:
        }
      }
    });
  }
}

class TcpIpCOMMhIsolateSendData {
  SendPort sendPort;
  String ip;
  int port;
  TcpIpCOMMSendDataComponent data;
  TcpIpCOMMhIsolateSendData({
    required this.ip,
    required this.port,
    required this.sendPort,
    required this.data,
  });
}

class TcpIpCOMMSendDataComponent {
  TCPcmd cmd;
  int? errorcode;
  String? eqrcp;
  String? eqstep;
  String? glassid;
  List<double>? wLLowHighTable;
  List<int>? pointNo;
  DateTime? dateTime;
  int? intervalTime;
  int? integrationTime;
  List<bool>? checkflag;
  TcpIpCOMMSendDataComponent({
    required this.cmd,
    this.errorcode,
    this.eqrcp,
    this.eqstep,
    this.glassid,
    this.wLLowHighTable,
    this.pointNo,
    this.dateTime,
    this.intervalTime,
    this.integrationTime,
    this.checkflag,
  });
}

class TcpIpCOMMIsolateReceiveData {
  SendPort sendPort;
  TcpIpCOMMReceiveDataComponent data;
  TcpIpCOMMIsolateReceiveData({
    required this.sendPort,
    required this.data,
  });
}

class TcpIpCOMMReceiveDataComponent {
  TCPcmd cmd;
  int? errorcode;
  int? interval;
  int? channelnum;
  DateTime? getTime;
  List<double>? wlTable;
  List<double>? wLLowHighTable;
  List<int>? intensity;
  bool? sendflag;
  List<bool>? checkflag;

  TcpIpCOMMReceiveDataComponent({
    required this.cmd,
    this.errorcode,
    this.interval,
    this.channelnum,
    this.getTime,
    this.wlTable,
    this.wLLowHighTable,
    this.intensity,
    this.sendflag,
    this.checkflag,
  });
}
