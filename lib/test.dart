import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_sliders/sliders.dart';
import 'package:wr_ui/controller/range_slider_ctrl.dart';
import 'package:wr_ui/main.dart';
import 'package:wr_ui/service/start_stop.dart';
import 'package:wr_ui/view/custom_widget/range_slider_widget.dart';
import 'package:wr_ui/view/right_side_menu/save_ini.dart';

enum TCPcmd { NONE, V, T, W, P, R, S, Q, U }

/// V = Intensity Data Request
/// T = Process Start
/// W = Wavelength Setting
/// P = Process Stop
/// R = All Wavelength Data Request
/// S = Time Synchronization
/// Q = Time Setting
/// U = Point No Setting
enum TCPcmdreply { NONE, ACK, ERROR }

bool tcpSendReq = false; // 추후 Monitoring Start 로 대체
RxBool isolatesendflag = false.obs;
RxBool intensitysendflag = false.obs;

class TcpIpCOMMCtrl extends GetxController {
  static TcpIpCOMMCtrl get to => Get.find();
  late Isolate isolate;
  SendPort? isendPort;
  static List<double> nlistWaveTable = [];
  static List<double> WLLowTable = []; // 근사값 처리 후 Data
  static List<double> WLHighTable = []; // 근사값 처리 후 Data
  static List<double> nWLLowTable = []; // EQ에서 받은 Data (근사값 처리 전)
  static List<double> nWLHighTable = []; // EQ에서 받은 Data (근사값 처리 전)
  static int intervalTime = 0;
  static int integrationTime = 0;
  static List<String> pointNo = [];
  static DateTime tdata = DateTime.now();
  static TCPcmd receivedCMD = TCPcmd.NONE;
  static int errorcode = 0;
  static String eqrcp = '';
  static String eqstep = '';
  static String eqglassid = '';
  static List<bool> checkflag = [
    false, // [0] Wave Length Setting Flag
    false, // [1] Time Data Setting Flag
    false, // [2] Point No Setting Flag
    false, // [3] Time Synchronization Flag
  ];
  static List<int> intensity = [];
  static int pointno = 0;
  static late ServerSocket serverSocket;
  static late Socket clientSocket;
  String hostname = '10.1.0.10';
  int port = 8000;

  Future<void> init() async {
    TcpIpCOMMIsolateStart();
  }

  TcpIpCOMMIsolateStart() async {
    ReceivePort rcvPort = ReceivePort();
    TcpIpCOMMhIsolateSendData data = TcpIpCOMMhIsolateSendData(
        sendPort: rcvPort.sendPort,
        data: TcpIpCOMMSendDataComponent(
            ip: hostname,
            port: port,
            interval: 100,
            wlTable: listWavelength,
            intensity: intensity,
            sendflag: intensitysendflag,
            gettime: DateTime.now(),
            pointno: 0));

    isolate = await Isolate.spawn(TcpIpCOMMIsolateRcv, data);

    rcvPort.listen((data) async {
      if (data is SendPort) {
        isendPort = data;
        isolatesendflag(true);
      } else if (data is TcpIpCOMMIsolateReceiveData) {
        checkflag = data.data.checkflag;
        print(
            'Receive Data CMD :${data.data.cmd} , errorcode :${data.data.errorcode}');
        if (data.data.errorcode != 0) return;
        switch (data.data.cmd) {
          case TCPcmd.V:
            tcpSendReq = true;
            print("Main Thread Intensity Data Request");
            break;
          case TCPcmd.T:
            MonitoringStart();
            print("Main Thread Process Start");
            print(
                'Main Thread EQRCP :${data.data.eqrcp} , EQSTEP :${data.data.eqstep} , GlassID :${data.data.glassid}');
            break;
          case TCPcmd.W:
            print('Main Thread Set Wavelength Low :${data.data.WLLowTable}');
            print('Main Thread Set Wavelength High :${data.data.WLHighTable}');
            WLLowTable = data.data.WLLowTable;
            WLHighTable = data.data.WLHighTable;

            // RangeSlider 가 20개가 아닐경우 20개로 만듬.
            if (RangeCtrl.to.rsModels.length <= 20) {
              var length = RangeCtrl.to.rsModels.length;
              for (var i = 0; i < 20 - length; i++) {
                RangeCtrl.to.addModelCount();
              }
            }

            for (var i = 0; i < 20; i++) {
              RangeCtrl.to.rsModels[i].vStart.value = WLLowTable[i];
              RangeCtrl.to.rsModels[i].vEnd.value = WLHighTable[i];

              RangeCtrl.to.rsModels[i].sIndex.value =
                  listWavelength.indexOf(WLLowTable[i]);
              RangeCtrl.to.rsModels[i].eIndex.value =
                  listWavelength.indexOf(WLHighTable[i]);
              RangeCtrl.to.rsModels[i].rv.value = SfRangeValues(
                  listWavelength.indexOf(WLLowTable[i]),
                  listWavelength.indexOf(WLHighTable[i]));
            }

            break;
          case TCPcmd.P:
            MonitoringStop();
            print("Main Thread Process Stop");
            break;
          case TCPcmd.R:
            print("Main Thread All Wavelength Request");
            break;
          case TCPcmd.S:
            print('Main Thread Time Data :${data.data.Tdata}');
            break;
          case TCPcmd.Q:
            iniController.to.intervalTime.value = data.data.intervalTime;
            iniController.to.integrationTime.value = data.data.integrationTime;
            print(
                'Main Thread interval time :${data.data.intervalTime} , integration time :${data.data.integrationTime}');
            break;
          case TCPcmd.U:
            if (iniController.to.channelFlow.length != 8) {
              print('ChannelFlow Length 가 8 이아니면 안되지!');
              return;
            }
            for (var i = 0; i < 8; i++) {
              iniController.to.channelFlow[i] = data.data.pointNo[i];
            }
            print('Main Thread Point No :${data.data.pointNo}');
            break;
          default:
        }
      }
    });

    ever(isolatesendflag, (v) {
      if (v == true) {
        isendPort?.send(TcpIpCOMMSendDataComponent(
            ip: hostname,
            port: port,
            interval: 100,
            wlTable: listWavelength,
            intensity: intensity,
            sendflag: intensitysendflag,
            gettime: DateTime.now(),
            pointno: pointno));
      }
      isolatesendflag(false);
    });
    isolatesendflag.refresh();
  }

  static void TcpIpCOMMIsolateRcv(TcpIpCOMMhIsolateSendData iSD) async {
    var rcvport = ReceivePort();
    iSD.sendPort.send(rcvport.sendPort);
    final ip = iSD.data.ip;
    final port = iSD.data.port;

    nlistWaveTable = iSD.data.wlTable;

    final serverSocket = await ServerSocket.bind(ip, port);
    print(
        'TCP server started at ${serverSocket.address}:${serverSocket.port}.');

    rcvport.listen((data) async {
      if (data is TcpIpCOMMSendDataComponent) {
        nlistWaveTable = data.wlTable;

        if (data.sendflag.value) {
          List<int> buf = [];
          String ss = '';
          for (var i = 0; i < data.intensity.length; i++) {
            ss += data.intensity[i].toString() + ',';
          }
          buf.addAll(ss.codeUnits);
          buf.removeLast();
          buf.insert(0, data.pointno);
          buf.insertAll(
              0,
              DateFormat('yyMMddhhmmssSSS')
                  .format(data.gettime)
                  .toString()
                  .codeUnits);

          var length = buf.length;
          buf.insertAll(0, [0x56, 0x06, length]);

          Uint8List sendbuf = Uint8List.fromList(buf);
          // 소켓연결되었는지 여부 추가해야함.
          clientSocket.add(sendbuf);
        }
      }
    });

    try {
      serverSocket.listen((Socket socket) {
        clientSocket = socket;
        print(
            'New TCP client ${clientSocket.address.address}:${clientSocket.port} connected.');
        clientSocket.listen((Uint8List data) {
          if (data.length > 0 && data.first == 10) return;
          Uint8List senddata;
          // 이거 두개의 다른 차이점은 무엇일까??
          // socket.add(utf8.encode("Echo: ")); // add 시 utf8.encode 로 변환필요
          // socket.write('asdf); // write 시 그냥 string 사용가능

          senddata = CommMakeReplyData(CommCheckValidity(data));
          if (senddata.length != 0) {
            clientSocket.add(senddata);
          }

          if (receivedCMD == TCPcmd.NONE) return;
          iSD.sendPort.send(TcpIpCOMMIsolateReceiveData(
              sendPort: rcvport.sendPort,
              data: TcpIpCOMMReceiveDataComponent(
                  cmd: receivedCMD,
                  errorcode: errorcode,
                  eqrcp: eqrcp,
                  eqstep: eqstep,
                  glassid: eqglassid,
                  WLLowTable: WLLowTable,
                  WLHighTable: WLHighTable,
                  pointNo: pointNo,
                  Tdata: tdata,
                  intervalTime: intervalTime,
                  integrationTime: integrationTime,
                  checkflag: checkflag)));
          receivedCMD = TCPcmd.NONE;
          errorcode = 0;
        }, onError: (error) {
          print(
              'Error for client ${clientSocket.address.address}:${clientSocket.port}.');
        }, onDone: () {
          print(
              'Connection to client ${clientSocket.address.address}:${clientSocket.port} done.');
        });
      });
    } on SocketException catch (ex) {
      print(ex.message);
    }
  }

  static TCPcmdreply CommCheckValidity(Uint8List data) {
    List<int> buf = []; // 지지고볶고할 List
    List<int> oribuf = []; // Original List
    var cmdlength = 0;
    var cmddata = '';
    buf.addAll(data);
    oribuf.addAll(data);

    print('$buf');

    // Received Data 에서 첫번째를 추출
    final cmdstr = String.fromCharCode(buf[0]);
    buf.removeAt(0);

    receivedCMD = TCPcmd.values.firstWhere(
        (e) => e.toString() == 'TCPcmd.' + cmdstr,
        orElse: () => TCPcmd.NONE);

    if (receivedCMD == TCPcmd.NONE) {
      errorcode = 0; // Command 를 알수없으므로 무응답.
      return TCPcmdreply.ERROR;
    }

    if (buf.length == 0) {
      errorcode = 1; // Command 만 들어오고 뒤에 Data가 없을때.
      return TCPcmdreply.ERROR;
    }

    switch (receivedCMD) {
      case TCPcmd.V: // Intensity Data Request
        print('22222');
        cmdlength = buf[0];
        buf.removeAt(0);

        cmddata = String.fromCharCodes(buf);
        if (cmdlength == 7 && cmddata == 'OESDATA') {
          return TCPcmdreply.ACK;
        }
        errorcode = 1; // Invalid message format
        break;
      case TCPcmd.T: // Process Start
        print('33333');
        cmdlength = buf[0];
        buf.removeAt(0);

        // Data 길이 확인.
        if (cmdlength == buf.length) {
          // "EQRCP,EQSTEP,GLASSID" <<== 형태로 들어옴.
          var buf_1 = String.fromCharCodes(buf).split(',');
          if (buf_1.length == 3) {
            eqrcp = buf_1[0];
            eqstep = buf_1[1];
            eqglassid = buf_1[2];

            if (!checkflag[0]) errorcode = 2; // Wave Length Setting Check
            if (!checkflag[1]) errorcode = 3; // Time Data Setting Check
            if (!checkflag[2]) errorcode = 4; // Point No Setting Check
            if (!checkflag[3]) errorcode = 5; // Time Sync Setting Check
            if (errorcode != 0) return TCPcmdreply.ERROR;

            return TCPcmdreply.ACK;
          }
        }

        errorcode = 1;
        break;
      case TCPcmd.W: // Wavelength Setting
        print('44444');
        cmdlength = buf[0];
        buf.removeAt(0);

        // Data 길이 확인.
        if (cmdlength == buf.length) {
          // "wavelow1,wavehigh1,...,wavelow20,wavehigh20" <<== 형태로 들어옴.
          var buf_1 = String.fromCharCodes(buf).split(',');
          if (buf_1.length == 40) {
            nWLHighTable.clear();
            nWLLowTable.clear();
            for (var i = 0; i < buf_1.length / 2; i++) {
              nWLLowTable.add(double.parse(buf_1[i * 2]));
              nWLHighTable.add(double.parse(buf_1[i * 2 + 1]));
            }
            return TCPcmdreply.ACK;
          }
        }
        errorcode = 1;
        break;
      case TCPcmd.P: // Process Stop
        print('55555');
        cmdlength = buf[0];

        if (cmdlength == 0) {
          return TCPcmdreply.ACK;
        }

        errorcode = 1;
        break;
      case TCPcmd.R: // All Wavelength Data Request
        print('66666');
        cmdlength = buf[0];

        if (cmdlength == 0) {
          return TCPcmdreply.ACK;
        }

        errorcode = 1;
        break;
      case TCPcmd.S: // Time Synchronization
        print('77777');
        cmdlength = buf[0];
        buf.removeAt(0);

        // Data 길이 확인. (yymmddhhMMssSSS = 15글자)
        if (cmdlength == buf.length && cmdlength == 0x0f) {
          var s = String.fromCharCodes(buf);
          tdata = DateTime.parse('20' +
              s.substring(0, 6) +
              'T' +
              s.substring(6, 12) +
              '.' +
              s.substring(12));
          return TCPcmdreply.ACK;
        }
        errorcode = 1;
        break;
      case TCPcmd.Q: // Time Setting
        print('88888');
        cmdlength = buf[0];
        buf.removeAt(0);

        // Data 길이 확인
        if (cmdlength == buf.length) {
          var buf_1 = String.fromCharCodes(buf).split(',');
          // Interval Time . Integration Time 맞게 가져왔는지 확인.
          if (buf_1.length == 2) {
            intervalTime = int.parse(buf_1[0]);
            integrationTime = int.parse(buf_1[1]);

            if (intervalTime < 90 || 9999 < intervalTime) {
              errorcode = 7; // interval time range error
              break;
            }
            if (integrationTime < 50 || 9999 < integrationTime) {
              errorcode = 8; // integration time range error
              break;
            }

            if (intervalTime < integrationTime + 40) {
              errorcode = 9; // Formula Error
              break;
            }

            return TCPcmdreply.ACK;
          }
        }
        errorcode = 1;
        break;
      case TCPcmd.U: // Point No Setting
        print('99999');
        cmdlength = buf[0];
        buf.removeAt(0);

        // Data 길이 확인
        if (cmdlength == buf.length) {
          // String 변환 후 List로 나누기
          var buf_1 = String.fromCharCodes(buf).split(',');
          // 나눠진 List 를 다시 숫자만 CharCode 로 변환 (0~8숫자인지 확인하기위해)
          var buf_2 = buf_1.reduce((v, e) => v + e).codeUnits.toList();
          // ',' 이 길이랑 맞게 들어왔는지 그리고 배열에 String 1글자만 들어갔는지 확인
          if (buf_2.length == (cmdlength / 2 + 1).toInt()) {
            pointNo.clear();

            for (var i = 0; i < buf_2.length; i++) {
              if (i == 0 && buf_2[i] == 48) {
                errorcode = 10; // first point no , can't be 0
                break;
              }
              if (buf_2[i] < 48 || buf_2[i] > 56) {
                errorcode = 11; // Point No Range Error
                break;
              }
              // error code 가 없을시 Data add
              pointNo.add(String.fromCharCode(buf_2[i]));
            }

            // data.length 가 8개가 안되면 강제로 0써서 채워줌.
            if (pointNo.length < 8) {
              var addList = List.filled(8 - pointNo.length, '0');
              pointNo.addAll(addList);
            }

            return TCPcmdreply.ACK;
          }
        }

        errorcode = 1;
        break;

      case TCPcmd.NONE:
        print('여기를 타면 안되지!');
        break;
    }
    return TCPcmdreply.ERROR;
  }

  static Uint8List CommMakeReplyData(TCPcmdreply cmdtype) {
    List<int> buf = []; // Data 만들기용
    print('Command Reply Data : $cmdtype , CMD Type : $receivedCMD');
    switch (cmdtype) {
      case TCPcmdreply.ACK:
        if (receivedCMD == TCPcmd.V) {
          // V Message 는 다른곳에서 보내는걸로
          break;
        } else if (receivedCMD == TCPcmd.T) {
          buf.addAll([0x54, 0x06, 0x00]);
          break;
        } else if (receivedCMD == TCPcmd.W) {
          // Setting Array 초기화.
          WLLowTable.clear();
          WLHighTable.clear();
          if (nWLLowTable.length != nWLHighTable.length) print('이게 말이 되나???');

          // 근사값 찾는것 시작.
          for (var i = 0; i < nWLLowTable.length; i++) {
            if (nWLLowTable[i] != 0.0)
              WLLowTable.add(
                  findApproximationValue(nlistWaveTable, nWLLowTable[i]));
            else
              WLLowTable.add(0);
            if (nWLHighTable[i] != 0.0)
              WLHighTable.add(
                  findApproximationValue(nlistWaveTable, nWLHighTable[i]));
            else
              WLHighTable.add(0);
          }

          String ss = '';
          // WLLow1,WLHigh1,WLLow2,WLHigh2 ... 형태의 String 으로 만들기.
          for (var i = 0; i < WLLowTable.length; i++) {
            ss += WLLowTable[i].toString() +
                ',' +
                WLHighTable[i].toString() +
                ',';
          }

          buf.addAll(ss.codeUnits); // send buffer 에 넣고
          buf.removeLast(); // 마지막 ',' 삭제
          buf.insertAll(
              0, [0x57, 0x06, buf.length]); // cmd code , ack , length 넣기.

          checkflag[0] = true;
          break;
        } else if (receivedCMD == TCPcmd.P) {
          buf.addAll([0x50, 0x06, 0x00]);
          break;
        } else if (receivedCMD == TCPcmd.R) {
          nlistWaveTable.forEach((v) {
            var s = v.toString() + ',';
            buf.addAll(s.codeUnits);
          });
          buf.removeLast(); // 마지막 ',' 삭제
          buf.insertAll(
              0,
              Uint8List(2)
                ..buffer
                    .asByteData()
                    .setInt16(0, buf.length, Endian.big)); // length [high,low]
          buf.insertAll(0, [0x52, 0x06]); // cmd code , ack 넣기.
          break;
        } else if (receivedCMD == TCPcmd.S) {
          buf.addAll([0x50, 0x06, 0x00]);
          checkflag[3] = true;
          break;
        } else if (receivedCMD == TCPcmd.Q) {
          buf.addAll([0x51, 0x06, 0x00]);
          checkflag[1] = true;
          break;
        } else if (receivedCMD == TCPcmd.U) {
          buf.addAll([0x55, 0x06, 0x00]);
          checkflag[2] = true;
          break;
        } else {
          print('reply ACK else 부분!!!!');
          break;
        }
      case TCPcmdreply.ERROR:
        if (receivedCMD == TCPcmd.V)
          buf.add(0x56);
        else if (receivedCMD == TCPcmd.T)
          buf.add(0x54);
        else if (receivedCMD == TCPcmd.W)
          buf.add(0x57);
        else if (receivedCMD == TCPcmd.P)
          buf.add(0x50);
        else if (receivedCMD == TCPcmd.R)
          buf.add(0x52);
        else if (receivedCMD == TCPcmd.S)
          buf.add(0x53);
        else if (receivedCMD == TCPcmd.Q)
          buf.add(0x51);
        else if (receivedCMD == TCPcmd.U) buf.add(0x55);

        buf.addAll([0x15, errorcode]);
        print('reply nak message!!! $buf');
        break;
      case TCPcmdreply.NONE:
        print('reply message 가 None 으로 빠졌어!!!!');
        break;
    }

    Uint8List sndbuf = Uint8List.fromList(buf);
    return sndbuf;
  }
}

class TcpIpCOMMhIsolateSendData {
  SendPort sendPort;
  TcpIpCOMMSendDataComponent data;
  TcpIpCOMMhIsolateSendData({
    required this.sendPort,
    required this.data,
  });
}

class TcpIpCOMMSendDataComponent {
  String ip;
  int port;
  int interval;
  List<double> wlTable;
  List<int> intensity;
  RxBool sendflag;
  DateTime gettime;
  int pointno;
  TcpIpCOMMSendDataComponent({
    required this.ip,
    required this.port,
    required this.interval,
    required this.wlTable,
    required this.intensity,
    required this.sendflag,
    required this.gettime,
    required this.pointno,
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
  int errorcode;
  String eqrcp;
  String eqstep;
  String glassid;
  List<double> WLLowTable;
  List<double> WLHighTable;
  List<String> pointNo;
  DateTime Tdata;
  int intervalTime;
  int integrationTime;
  List<bool> checkflag;
  TcpIpCOMMReceiveDataComponent({
    required this.cmd,
    required this.errorcode,
    required this.eqrcp,
    required this.eqstep,
    required this.glassid,
    required this.WLLowTable,
    required this.WLHighTable,
    required this.pointNo,
    required this.Tdata,
    required this.intervalTime,
    required this.integrationTime,
    required this.checkflag,
  });
}
