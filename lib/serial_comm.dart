// ignore_for_file: constant_identifier_names, unrelated_type_equality_checks
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ffi';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'dart:developer' as dvlp;
import 'package:wrma_com/main.dart';

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
  Rx<int> errorCode = 0.obs;
  static RxList<String> gch = RxList.empty();
  static RxList<double> wlLow = RxList.empty();
  static RxList<double> wlHigh = RxList.empty();
  static Rx<String> eqRcp = "EQRCP".obs;
  static Rx<String> eqStep = "EQSTEP".obs;
  static Rx<String> glassId = "GlassID".obs;
  static DateTime tdata = DateTime.now();

  static List<double> nlistWaveLength = [];
  static DateTime sndtime = DateTime.now();
  static DateTime rcvtime = DateTime.now();
  static TCPcmd sendOldCMD = TCPcmd.NONE;
  static TCPcmd rcvCmd = TCPcmd.NONE;

  Future<void> init() async {
    TcpIpCOMMIsolateStart();
  }

  // ignore: non_constant_identifier_names
  TcpIpCOMMIsolateStart() async {
    ReceivePort sndPort = ReceivePort(); // isolate port
    // main => isolate로 보낼 데이터
    TcpIpCOMMhIsolateSendData data = TcpIpCOMMhIsolateSendData(
        ip: hostname,
        port: port,
        sendPort: sndPort.sendPort, // isolate로 보낼 port
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

    isolate = await Isolate.spawn(TcpIpCOMMIsolateRcv, data);

    // main rcv
    // isolate => main : main이 받는다
    sndPort.listen((data) async {
      if (data is SendPort) {
        isoSendPort = data;
      }

      if (data is TcpIpCOMMIsolateReceiveData) {
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
            errorcode: errorCode.value,
            eqrcp: eqRcp.value,
            eqstep: eqStep.value,
            glassid: glassId.value,
            wLLowTable: wlLow,
            wLHighTable: wlHigh,
            pointNo: pointNum,
            dataTime: tdata,
            intervalTime: interval.value,
            integrationTime: integration.value,
            checkflag: List<bool>.filled(10, false),
          ));
          // print("MainThread => Isolate ${mainCmd}");
          // print("interval: $ginterval");
          // print("ch: $gch");
          // print("SWLTB: $gSWLTB");
          sendFlag(false);
        }
      },
    );
  }

  // isolate
  static void TcpIpCOMMIsolateRcv(TcpIpCOMMhIsolateSendData iSD) async {
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
        print("rcvCmd ${rcvCmd}, cmd : ${utf8.decode(data)}");
        // 데이터 받아서 처리하는 함수
        CommCheckValidity(rcvCmd, data);
        // Timer.periodic(Duration(seconds: 1), (timer) {
        //   socket.write(utf8.encode('asdf'));
        // });
      });
    } on SocketException catch (ex) {
      print(ex.message);
    }

    // isolate rcv
    // main => isolate : isolate가 받는다.
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
            print("V : ${buf}");
            socket.write(buf);
            buf.clear();
            break;
          case TCPcmd.T:
            String t = "T";
            buf.addAll(t.codeUnits);
            final length = eqRcp.value.length +
                eqStep.value.length +
                glassId.value.length +
                2;
            buf.add(length);
            buf.addAll(eqRcp.value.codeUnits);
            buf.addAll([0x2C]);
            buf.addAll(eqStep.value.codeUnits);
            buf.addAll([0x2C]);
            buf.addAll(glassId.value.codeUnits);
            // Uint8List sendData = Uint8List.fromList(buf);
            print("T : ${buf}");
            socket.write(buf);
            buf.clear();
            break;
          case TCPcmd.W:
            // 작업 해야함
            String w = "W";
            buf.addAll(w.codeUnits);
            print("W : ${buf}");
            socket.write(buf);
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
            String dateTime = DateFormat(patten).format(tdata);
            print("dateTime : ${dateTime}");
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
            // 예외처리 보완해야함
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
              print("tempLength : ${tempLength}");
              buf.add(tempLength);
              temp.forEach((e) {
                buf.addAll(e.codeUnits);
              });
            }
            print("U : ${buf}");
            socket.write(buf);
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

    debounce(readbytecnt, (v) {
      if (readbytecnt.value <= 0) return;
      // Uint8List data = iserialPort.read(readbytecnt.value);
      // CommCheckValidity(sendOldCMD, data);

      readbytecnt(0);
    }, time: Duration(milliseconds: 3));

    // Socket socket = await Socket.connect('10.1.0.10', 8000);
    //
    // print('connected');

    // isolate send 필요
    // isolate => main : main 받는다
    // OES 에서 CMD 주는거 처리 및 reply Data 처리 후 Isolate Send!
    // debounce(readbytecnt, (v) {
    //   if (readbytecnt.value <= 0) return;
    //   Uint8List data = iserialPort.read(readbytecnt.value);
    //   print("serial Data Receive");
    //   iserialPort.write(
    //       // CommMakeReplyData(rxcmdreply(CommCheckValidity(data))),
    //       CommMakeReplyData(CommCheckValidity(data)),
    //       timeout: 0); // timeout: 0 = infinity
    //   readbytecnt(0);

    //   if (ReceivedCMD.value == COMMcmd.NONE) return;
    //   iSD.sendPort.send(SerialCOMMIsolateReceiveData(
    //       sendPort: rcvport.sendPort,
    //       data: SerialCOMMReceiveDataComponent(
    //           CMD: ReceivedCMD.value,
    //           scData: SCData,
    //           siData: SIData,
    //           swltbData: SWLTBData)));
    //   print("isolate send!!");
    //   ReceivedCMD(COMMcmd.NONE);
    // }, time: Duration(milliseconds: 3)); // => time : 3ms Data가 짤려왔을시의 대기시간.

    // Data 보내는 곳
    // socket send
    // add => utf8변환필요
    // socket.write쓰면 uint8List 바로 간다.
    // bool datasend = true;
    // String a = "A";
    // Uint8List b = Uint8List(3);
    // b.add(int.parse(a));
    // if (datasend == true) {
    //   // socket.add(CommMakeSendData(data));
    //   socket.write(a);
    // }
    // socket.write(utf8.encode('asdf'));

    // Timer.periodic(Duration(seconds: 1), (timer) {
    //   socket.write(utf8.encode('asdf'));
    // });
    // wait 5 seconds
    // await Future.delayed(Duration(seconds: 5));

    // .. and close the socket
    // socket.close();
  }

  static Uint8List CommMakeSendData(TCPcmd cmd) {
    List<int> buf = []; // Data 만들기용
    buf.add(0x02); // stx

    switch (cmd) {
      case TCPcmd.T:
        buf.addAll("STT".codeUnits);
        buf.add(0x10); //dle
        break;
      case TCPcmd.P:
        buf.addAll("STP".codeUnits);
        buf.add(0x10); //dle
        break;
      case TCPcmd.R:
        buf.addAll("GWLTB".codeUnits);
        buf.add(0x10); //dle
        break;
      case TCPcmd.S:
        buf.addAll("T".codeUnits);
        buf.add(0x10); //dle
        buf.addAll(DateFormat('yyyyMMddHHmmss')
            .format(DateTime.now())
            .toString()
            .codeUnits);
        break;
      case TCPcmd.W:
        buf.addAll("SWLTB".codeUnits);
        buf.add(0x10); //dle
        String s = '';
        var cnt = 0;
        var f = NumberFormat('0000.00');
        wlLow.forEach((v) {
          if (v != 0) {
            s += f.format(v);
            s += ',';
            cnt++;
          }
        });

        buf.addAll(Uint8List(2)
          ..buffer
              .asByteData()
              .setInt16(0, cnt, Endian.big)); // length [high,low]
        buf.addAll(s.codeUnits); // Data (format = [0000.00,0000.00])
        buf.removeLast(); // Last ',' Remove
        break;
      case TCPcmd.Q:
        buf.addAll("SI".codeUnits);
        buf.add(0x10); //dle

        var f = NumberFormat('0000');
        // buf.addAll(f.format(interval.value).codeUnits);

        break;
      case TCPcmd.U:
        buf.addAll("SC".codeUnits);
        buf.add(0x10); //dle

        var cnt = 0;
        String s = '';
        gch.forEach((v) {
          if (v != 0) {
            s += v.toString();
            cnt++;
          }
        });

        buf.addAll(Uint8List(1)..buffer.asByteData().setInt8(0, cnt)); // length
        buf.addAll(s.codeUnits);
        break;
      default:
    }
    buf.add(0x03); // etx
    Uint8List sndbuf = Uint8List.fromList(buf);
    dvlp.log("$sndbuf");
    return sndbuf;
  }

  static TCPcmdreply CommCheckValidity(TCPcmd cmd, Uint8List data) {
    List<int> rcvbuf = []; // Data 처리용
    List<int> sndbuf = []; // Data 만들기용
    // Uint8List cmds;
    // cmds = Uint8List.fromList(rcvbuf);
    // print("cmds, $cmds");
    rcvbuf.clear();
    rcvbuf.addAll(data);
    print("rcvbuf, $rcvbuf");
    int buf = data[0];
    switch (buf) {
      case 0x56:
        rcvCmd = TCPcmd.V;
        break;
      case 0x54:
        rcvCmd = TCPcmd.T;
        break;
      case 0x57:
        rcvCmd = TCPcmd.W;
        break;
      case 0x50:
        rcvCmd = TCPcmd.P;
        break;
      case 0x52:
        rcvCmd = TCPcmd.R;
        break;
      case 0x53:
        rcvCmd = TCPcmd.S;
        break;
      case 0x51:
        rcvCmd = TCPcmd.Q;
        break;
      case 0x55:
        rcvCmd = TCPcmd.U;
        break;
      // case COMMcmd.NONE:
      //   break;
    }

    switch (rcvCmd) {
      case TCPcmd.V:
        try {} catch (e) {}
        break;
      case TCPcmd.T:
        break;
      case TCPcmd.W:
        break;
      case TCPcmd.P:
        break;
      case TCPcmd.Q:
        break;
      case TCPcmd.U:
        if (rcvbuf[0] == 0x06) sendOldCMD = TCPcmd.NONE;
        break;
      case TCPcmd.R:
        try {
          if (rcvbuf[0] != 0x06) break; // ack check
          rcvbuf.removeAt(0);

          int length = sndbuf[0]; // take length
          rcvbuf.removeAt(0);

//length 에따른 문자열 길이 Check , ([XXXX.XX] = 7) + (length - ',')
          if (rcvbuf.length != (7 * length) + (length - 1)) break;

          String ss;
          nlistWaveLength.clear();
          for (int i = 0; i < length; i++) {
            // ',' 을 찾아서 있으면 List 삭제하면서 진행 , 없으면 마지막이므로 삭제필요 X
            if (rcvbuf.indexOf(44) != -1) {
              ss = String.fromCharCodes(rcvbuf
                  .take(rcvbuf.indexOf(44))); // ',' 이전 ASCII 를 가져가서 String으로 만듬
              nlistWaveLength.add(double.parse(ss)); // String -> double
              rcvbuf.removeRange(0, rcvbuf.indexOf(44) + 1);
            } else {
              ss = String.fromCharCodes(rcvbuf);
              nlistWaveLength.add(double.parse(ss));
            }
            print('$nlistWaveLength');
          }

          sendOldCMD = TCPcmd.NONE;
        } catch (e) {
          sendOldCMD = TCPcmd.NONE;
          return TCPcmdreply.ERROR;
        }

        break;
      case TCPcmd.S:
        try {
          if (rcvbuf[0] != 0x06) break; // ack check
          rcvbuf.removeAt(0);

          var s = '';
          rcvbuf.forEach((e) {
            s += String.fromCharCode(e);
          }); // ASCII -> String 변환

          // yyyyMMdd + 'T' + HHmmss 형태여야 parsing 가능
          tdata = DateTime.parse(s.substring(0, 8) + 'T' + s.substring(8));

          sendOldCMD = TCPcmd.NONE;
        } catch (e) {
          sendOldCMD = TCPcmd.NONE;
          return TCPcmdreply.ERROR;
        }

        break;
      case TCPcmd.NONE:
        break;
    }
    return TCPcmdreply.NONE;
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
  List<double>? wLLowTable;
  List<double>? wLHighTable;
  List<int>? pointNo;
  DateTime? dataTime;
  int? intervalTime;
  int? integrationTime;
  List<bool>? checkflag;
  TcpIpCOMMSendDataComponent({
    required this.cmd,
    this.errorcode,
    this.eqrcp,
    this.eqstep,
    this.glassid,
    this.wLLowTable,
    this.wLHighTable,
    this.pointNo,
    this.dataTime,
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
  // String ip;
  // int port;
  int? interval;
  List<double>? wlTable;
  List<bool>? checkflag;

  TcpIpCOMMReceiveDataComponent({
    required this.cmd,
    // required this.ip,
    // required this.port,
    this.interval,
    this.wlTable,
    this.checkflag,
  });
}
