// ignore_for_file: constant_identifier_names, unrelated_type_equality_checks
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
// import 'dart:developer' as dvlp;
// import 'package:wrma_com/main.dart';

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

  static TCPcmd rcvCmd = TCPcmd.NONE;
  static int errorCode = 0;
  static int intervalRcv = 0;
  static DateTime getTime = DateTime.now();
  static List<double> wlTable = [];
  static List<double> wLLowHighTable = [];
  static List<int> intensity = [];
  static bool flagRcv = false;
  static List<bool> checkflag = [false, false, false, false];

  static RxList<String> gch = RxList.empty();
  static List<double> nlistWaveLength = [];
  static DateTime rcvtime = DateTime.now();
  // static DateTime sndtime = DateTime.now();
  // static TCPcmd sendOldCMD = TCPcmd.NONE;

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
          // errorcode: errorCode.value,
          // eqrcp: eqRcp.value,
          // eqstep: eqStep.value,
          // glassid: glassId.value,
          // wLLowTable: wlLow,
          // wLHighTable: wlHigh,
          // pointNo: pointNum,
          // dataTime: tdata,
          // intervalTime: interval.value,
          // integrationTime: integration.value,
          // checkflag: List<bool>.filled(10, false),
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
        // print("TcpIpCOMMIsolateReceiveData: ${data.data.cmd}");
        // print("TcpIpCOMMIsolateReceiveData: ${data.data.errorcode}");
        cmdConfirm.value = data.data.cmd.toString();
        errorConfirm.value = data.data.errorcode.toString();

        switch (data.data.cmd) {
          case TCPcmd.V:

            /// main 작동 함수
            break;
          case TCPcmd.T:
            break;
          case TCPcmd.W:
            break;
          case TCPcmd.P:
            break;
          case TCPcmd.R:
            wlTableMain.clear();
            data.data.wlTable?.forEach((v) => wlTableMain.add(v));
            print("wlTableMain ${wlTableMain}");
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
          // print("MainThread => Isolate ${mainCmd}");
          // print("interval: $ginterval");
          // print("ch: $gch");
          // print("SWLTB: $wlLow");
          // print("SWLTB: $wlHigh");
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

    RxInt readbytecnt = 0.obs;
    Rx<TCPcmdreply> rxcmdreply = TCPcmdreply.NONE.obs;
    List<double> nWLLowTable = [];
    List<double> nWLHighTable = [];

    // Server랑 연결
    Socket socket = await Socket.connect(ip, port);
    print(
        'TCP client started connecting state : ${socket.address}:${socket.port}.');

    try {
      // print(
      //     'New TCP server ${socket.address.address}:${socket.port} connected.');
      // listen to the received data event stream

      // socket listen
      socket.listen((Uint8List data) {
        // ignore: avoid_print
        // print("rcvCmd $rcvCmd, cmd : ${utf8.decode(data)}");
        List<int> rcvbuf = []; // Data 처리용
        // List<int> sndbuf = []; // Data 만들기용
        // Uint8List cmds;
        // cmds = Uint8List.fromList(rcvbuf);
        // print("cmds, $cmds");
        var ackNak = 0;
        rcvbuf.clear();
        rcvbuf.addAll(data);
        final cmdstr = String.fromCharCode(rcvbuf[0]);
        print("cmdstr: ${cmdstr}");
        rcvCmd = TCPcmd.values.firstWhere(
            (e) => e.toString() == 'TCPcmd.' + cmdstr,
            orElse: () => TCPcmd.NONE);
        rcvbuf.removeAt(0); // cmd 자르기
        ackNak = rcvbuf[0];
        rcvbuf.removeAt(0); // ack/nak 자르기
        print("rcvCmd: ${rcvCmd}");
        switch (rcvCmd) {
          case TCPcmd.V:
            // intensity data main 으로 작업 필요
            if (ackNak == 0x06) {
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
              int length = rcvbuf[0];
              rcvbuf.removeAt(0);
              wLLowHighTable.clear();
              if (length == rcvbuf.length) {
                var buf_1 = String.fromCharCodes(rcvbuf).split(',');
                buf_1.forEach((e) => wLLowHighTable.add(double.parse(e)));
                buf_1.clear();
              }
              print("W length : ${length}");
              print("W ${rcvbuf}");
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
                buf_1.removeLast();
                buf_1.forEach((e) => wlTable.add(double.parse(e)));
                // print("wlTable : ${wlTable}");
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
        // 데이터 받아서 처리하는 함수
        // Uint8List senddata;
        // CommCheckValidity(data);
        // List<int> buf = [];
        // buf.addAll(data);
        // print("buf ${buf}");
        // Uint8List sndbuf = Uint8List.fromList(buf);
        // senddata = sndbuf;
        // rcvCmd = TCPcmd.T;
        // print("senddata ${senddata}");
        // if (senddata.length != 0) {
        //   socket.add(senddata);
        // }
        if (rcvCmd == TCPcmd.NONE) return;
        iSD.sendPort.send(TcpIpCOMMIsolateReceiveData(
            sendPort: rcvport.sendPort,
            data: TcpIpCOMMReceiveDataComponent(
              cmd: rcvCmd,
              errorcode: errorCode,
              interval: intervalRcv,
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
        // Timer.periodic(Duration(seconds: 1), (timer) {
        //   socket.write(utf8.encode('asdf'));
        // });
      });
    } on SocketException catch (ex) {
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
            print("V : $buf");
            socket.write(buf);
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
            // Uint8List sendData = Uint8List.fromList(buf);
            print("T : ${buf}");
            socket.write(buf);
            buf.clear();
            break;
          case TCPcmd.W:
            String w = "W";
            buf.addAll(w.codeUnits);
            // print("asdqwd : ${data.wLLowHighTable}");
            List<String> temp = [];
            data.wLLowHighTable?.forEach((e) {
              temp.add(e.toString());
              temp.add(",");
            });
            temp.removeLast();
            List<int> tempbuf = [];
            temp.forEach((e) {
              tempbuf.addAll(e.codeUnits);
            });
            int? tempLength = tempbuf.length;
            buf.add(tempLength);
            tempbuf.forEach((e) {
              buf.add(e);
            });
            print("W : ${buf}");
            socket.write(buf);
            temp.clear();
            tempbuf.clear();
            buf.clear();
            break;
          case TCPcmd.P:
            String p = "P";
            buf.addAll(p.codeUnits);
            buf.addAll([0x00]);
            print("P : ${buf}");
            socket.write(buf);
            buf.clear();
            break;
          case TCPcmd.R:
            String r = "R";
            buf.addAll(r.codeUnits);
            buf.addAll([0x00]);
            print("R : ${buf}");
            socket.write(buf);
            buf.clear();
            break;
          case TCPcmd.S:
            String s = "S";
            buf.addAll(s.codeUnits);
            buf.addAll([0x0f]);
            String patten = "yyMMddHHmmssSSS";
            DateTime tempTime = data.dateTime!;
            String dateTime = DateFormat(patten).format(tempTime);
            // print("dateTime : ${dateTime}");
            buf.addAll(dateTime.codeUnits);
            print("S : ${buf}");
            socket.write(buf);
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
            print("Q : ${buf}");
            socket.write(buf);
            buf.clear();
            break;
          case TCPcmd.U:
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

        // sendData = Uint8List.fromList(buf);
        //ack 받는것 대기.
        // iserialPort.write(CommMakeSendData(data.cmd));
        // sendOldCMD = data.cmd;
      }
    });

    // debounce(readbytecnt, (v) {
    //   if (readbytecnt.value <= 0) return;

    //   readbytecnt(0);
    // }, time: Duration(milliseconds: 3));
  }

  // static TCPcmdreply CommCheckValidity(Uint8List data) {

  //   return TCPcmdreply.NONE;
  // }

  // static Uint8List CommMakeReplyData(TCPcmdreply cmdtype) {
  //   List<int> buf = []; // Data 만들기용
  //   print('Command Reply Data : $cmdtype , CMD Type : $rcvCmd');
  //   // switch (cmdtype) {
  //   //   case TCPcmdreply.ACK:
  //   //     if (receivedCMD == TCPcmd.V) {
  //   //       // V Message 는 다른곳에서 보내는걸로
  //   //       break;
  //   //     } else if (receivedCMD == TCPcmd.T) {
  //   //       buf.addAll([0x54, 0x06, 0x00]);
  //   //       break;
  //   //     } else if (receivedCMD == TCPcmd.W) {
  //   //       // Setting Array 초기화.
  //   //       WLLowTable.clear();
  //   //       WLHighTable.clear();
  //   //       if (nWLLowTable.length != nWLHighTable.length) print('이게 말이 되나???');

  //   //       // 근사값 찾는것 시작.
  //   //       for (var i = 0; i < nWLLowTable.length; i++) {
  //   //         if (nWLLowTable[i] != 0.0)
  //   //           WLLowTable.add(
  //   //               findApproximationValue(nlistWaveTable, nWLLowTable[i]));
  //   //         else
  //   //           WLLowTable.add(0);
  //   //         if (nWLHighTable[i] != 0.0)
  //   //           WLHighTable.add(
  //   //               findApproximationValue(nlistWaveTable, nWLHighTable[i]));
  //   //         else
  //   //           WLHighTable.add(0);
  //   //       }

  //   //       String ss = '';
  //   //       // WLLow1,WLHigh1,WLLow2,WLHigh2 ... 형태의 String 으로 만들기.
  //   //       for (var i = 0; i < WLLowTable.length; i++) {
  //   //         ss += WLLowTable[i].toString() +
  //   //             ',' +
  //   //             WLHighTable[i].toString() +
  //   //             ',';
  //   //       }

  //   //       buf.addAll(ss.codeUnits); // send buffer 에 넣고
  //   //       buf.removeLast(); // 마지막 ',' 삭제
  //   //       buf.insertAll(
  //   //           0, [0x57, 0x06, buf.length]); // cmd code , ack , length 넣기.

  //   //       checkflag[0] = true;
  //   //       break;
  //   //     } else if (receivedCMD == TCPcmd.P) {
  //   //       buf.addAll([0x50, 0x06, 0x00]);
  //   //       break;
  //   //     } else if (receivedCMD == TCPcmd.R) {
  //   //       nlistWaveTable.forEach((v) {
  //   //         var s = v.toString() + ',';
  //   //         buf.addAll(s.codeUnits);
  //   //       });
  //   //       buf.removeLast(); // 마지막 ',' 삭제
  //   //       buf.insertAll(
  //   //           0,
  //   //           Uint8List(2)
  //   //             ..buffer
  //   //                 .asByteData()
  //   //                 .setInt16(0, buf.length, Endian.big)); // length [high,low]
  //   //       buf.insertAll(0, [0x52, 0x06]); // cmd code , ack 넣기.
  //   //       break;
  //   //     } else if (receivedCMD == TCPcmd.S) {
  //   //       buf.addAll([0x50, 0x06, 0x00]);
  //   //       checkflag[3] = true;
  //   //       break;
  //   //     } else if (receivedCMD == TCPcmd.Q) {
  //   //       buf.addAll([0x51, 0x06, 0x00]);
  //   //       checkflag[1] = true;
  //   //       break;
  //   //     } else if (receivedCMD == TCPcmd.U) {
  //   //       buf.addAll([0x55, 0x06, 0x00]);
  //   //       checkflag[2] = true;
  //   //       break;
  //   //     } else {
  //   //       print('reply ACK else 부분!!!!');
  //   //       break;
  //   //     }
  //   //   case TCPcmdreply.ERROR:
  //   //     if (receivedCMD == TCPcmd.V)
  //   //       buf.add(0x56);
  //   //     else if (receivedCMD == TCPcmd.T)
  //   //       buf.add(0x54);
  //   //     else if (receivedCMD == TCPcmd.W)
  //   //       buf.add(0x57);
  //   //     else if (receivedCMD == TCPcmd.P)
  //   //       buf.add(0x50);
  //   //     else if (receivedCMD == TCPcmd.R)
  //   //       buf.add(0x52);
  //   //     else if (receivedCMD == TCPcmd.S)
  //   //       buf.add(0x53);
  //   //     else if (receivedCMD == TCPcmd.Q)
  //   //       buf.add(0x51);
  //   //     else if (receivedCMD == TCPcmd.U) buf.add(0x55);

  //   //     buf.addAll([0x15, errorcode]);
  //   //     print('reply nak message!!! $buf');
  //   //     break;
  //   //   case TCPcmdreply.NONE:
  //   //     print('reply message 가 None 으로 빠졌어!!!!');
  //   //     break;
  //   // }

  //   Uint8List sndbuf = Uint8List.fromList(buf);
  //   return sndbuf;
  // }
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
    this.getTime,
    this.wlTable,
    this.wLLowHighTable,
    this.intensity,
    this.sendflag,
    this.checkflag,
  });
}
