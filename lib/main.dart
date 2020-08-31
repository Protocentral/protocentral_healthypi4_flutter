import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:package_info/package_info.dart';
import 'package:progress_dialog/progress_dialog.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:syncfusion_flutter_core/core.dart';

import 'globals.dart';

import 'package:charts_flutter/flutter.dart' as charts;
import 'package:permission_handler/permission_handler.dart';

import 'package:flutter_ble_lib/flutter_ble_lib.dart';

void main() async {
  SyncfusionLicense.registerLicense(
      "NT8mJyc2IWhia31ifWN9ZmRoYmF8YGJ8ampqanNiYmlmamlmanMDHmgyIDskOj0TMDohMCY6JzYwJyB9MDw+");
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HealthyPi 4',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomeScreen(title: 'HealthyPi 4'),
    );
  }
}

class SizeConfig {
  static MediaQueryData _mediaQueryData;
  static double screenWidth;
  static double screenHeight;
  static double blockSizeHorizontal;
  static double blockSizeVertical;

  void init(BuildContext context) {
    _mediaQueryData = MediaQuery.of(context);
    screenWidth = _mediaQueryData.size.width;
    screenHeight = _mediaQueryData.size.height;
    blockSizeHorizontal = screenWidth / 100;
    blockSizeVertical = screenHeight / 100;
  }
}

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  BleManager bleManager = BleManager();
  Peripheral peripheral;

  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey();

  var hpi4Connected = false;
  var hpi4Discovered = false;

  bool mtuSet = false;

  StreamSubscription monitoringBatteryStreamSubscription;
  StreamSubscription monitoringHRStreamSubscription;
  StreamSubscription monitoringSPO2StreamSubscription;
  StreamSubscription monitoringHRVRespStreamSubscription;
  StreamSubscription monitoringTempStreamSubscription;
  StreamSubscription monitoringECGStreamSubscription;
  StreamSubscription monitoringPPGStreamSubscription;

  double ecgLSBMultiplier = 0.2;

  int _globalBatteryLevel = 50;
  int _batteryState = 1;

  int globalHeartRate = 0;
  int globalSpO2 = 0;
  int globalRespRate = 0;
  double globalTemp = 0;

  List<int> globalHistogram = new List<int>(12);

  ProgressDialog prDFU;
  bool dfuRunning = false;
  int globalDFUProgress = 0;
  int globalFWVersion = 0;

  List<ECGPoint> ecgData = new List<ECGPoint>();
  List<ECGPoint> ppgData = new List<ECGPoint>();

  int ecgDataCounter = 0;
  int ppgDataCounter = 0;

  StreamSubscription ecgListener;
  StreamSubscription ppgRRListener;

  PermissionStatus permStatus;

  Stopwatch _runTimeStopWatch = new Stopwatch();

  String hPi4CurrentDeviceName = " ";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 0) {
      stopECGPPG();
    } else {
      startECGPPG();
    }
  }

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((PackageInfo packageInfo) {
      hPi4Global.hpi4AppVersion = packageInfo.version;
      hPi4Global.hpi4AppBuildNumber = packageInfo.buildNumber;
    });

    hPi4StartBLE();
  }

  Future<void> _checkPermissions() async {
    if (Platform.isAndroid) {
      permStatus = await Permission.locationWhenInUse.status;

      if (permStatus.isUndetermined) {
        print("Permission not received");
        //Permission.location.request();
        await Permission.locationWhenInUse.request();
      }
      while (!await Permission.locationWhenInUse.isGranted) {
        await Permission.locationWhenInUse.request();
      }
    }
  }

  void hPi4StartBLE() async {
    await _checkPermissions();

    bleManager = BleManager();
    await bleManager.createClient();
  }

  Widget _buildHome() {
    return Column(children: <Widget>[
      _buildConnectionBlock(),
      _buildMainGrid(),
    ]);
  }

  Widget _buildPageContent() {
    if (_selectedIndex == 0) {
      return _buildHome();
    } else {
      return _buildLivePage();
    }
  }

  Widget _buildCharts() {
    return Column(
      children: <Widget>[
        SizedBox(
          height: 20,
        ),
        Container(
          height: SizeConfig.blockSizeVertical * 35,
          width: SizeConfig.blockSizeHorizontal * 95,
          child: SfCartesianChart(
            backgroundColor: Colors.black,
            plotAreaBorderWidth: 0,
            primaryXAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 0), isVisible: false),
            primaryYAxis: NumericAxis(
                axisLine: AxisLine(width: 0),
                majorTickLines: MajorTickLines(size: 0),
                isVisible: false),
            series: <ChartSeries>[
              FastLineSeries<ECGPoint, num>(
                  color: Colors.green,
                  dataSource: ecgData,
                  xValueMapper: (ECGPoint sales, _) => sales.time,
                  yValueMapper: (ECGPoint sales, _) => sales.voltage,
                  width: 2,
                  animationDuration: 0),
            ],
          ),
        ),
        SizedBox(
          height: 20,
        ),
        Container(
          height: SizeConfig.blockSizeVertical * 35,
          width: SizeConfig.blockSizeHorizontal * 95,
          child: SfCartesianChart(
            backgroundColor: Colors.black,
            plotAreaBorderWidth: 0,
            primaryXAxis: NumericAxis(
                majorGridLines: MajorGridLines(width: 0), isVisible: false),
            primaryYAxis: NumericAxis(
                axisLine: AxisLine(width: 0),
                majorTickLines: MajorTickLines(size: 0),
                isVisible: false),
            series: <ChartSeries>[
              FastLineSeries<ECGPoint, num>(
                  color: Colors.yellow,
                  dataSource: ppgData,
                  xValueMapper: (ECGPoint sales, _) => sales.time,
                  yValueMapper: (ECGPoint sales, _) => sales.voltage,
                  width: 2,
                  animationDuration: 0),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildButtonBar() {
    return ButtonBar(
      children: [
        MaterialButton(
          color: hPi4Global.hpi4Color,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.play_arrow,
                color: Colors.white,
              ),
              Text("Start Live",
                  style: new TextStyle(fontSize: 14.0, color: Colors.white)),
            ],
          ),
          onPressed: () async {
            startECGPPG();
          },
        ),
        MaterialButton(
          color: hPi4Global.hpi4Color,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.stop,
                color: Colors.white,
              ),
              Text("Stop Live", style: new TextStyle(color: Colors.white)),
            ],
          ),
          onPressed: () async {},
        ),
      ],
    );
  }

  void _startMonitoringECG(Stream<Uint8List> characteristicUpdates) async {
    await monitoringECGStreamSubscription?.cancel();
    monitoringECGStreamSubscription = characteristicUpdates.listen(
      (value) {
        ByteData ecgByteData = Uint8List.fromList(value).buffer.asByteData(0);
        Int16List ecgList = ecgByteData.buffer.asInt16List();

        /*print("Received ECG Packet: " +
            ecgList.toString() +
            " L: " +
            ecgList.length.toString());
            */

        //print("ECG Counter: " + ecgDataCounter.toString());

        ecgList.forEach((element) {
          setState(() {
            ecgData.add(ECGPoint(ecgDataCounter++, (element.toDouble())));
          });

          if (ecgDataCounter >= 64 * 6) {
            ecgData.removeAt(0);
          }
        });
        //print("ECG Data recd: " + value.toString());
      },
      onError: (error) {
        print("Error while monitoring data characteristic \n$error");
      },
      cancelOnError: true,
    );
  }

  void _startMonitoringPPG(Stream<Uint8List> characteristicUpdates) async {
    await monitoringPPGStreamSubscription?.cancel();
    monitoringPPGStreamSubscription = characteristicUpdates.listen(
      (value) {
        ByteData ecgByteData = Uint8List.fromList(value).buffer.asByteData(0);
        Int16List ppgList = ecgByteData.buffer.asInt16List();

        /*print("Received ECG Packet: " +
            ecgList.toString() +
            " L: " +
            ecgList.length.toString());
            */

        //print("ECG Counter: " + ecgDataCounter.toString());

        ppgList.forEach((element) {
          setState(() {
            ppgData.add(ECGPoint(ppgDataCounter++, (element.toDouble())));
          });

          if (ppgDataCounter >= 64 * 6) {
            ppgData.removeAt(0);
          }
        });
        //print("ECG Data recd: " + value.toString());
      },
      onError: (error) {
        print("Error while monitoring data characteristic \n$error");
      },
      cancelOnError: true,
    );
  }

  void startECGPPG() {
    print("Starting ECG monitoring");

    _startMonitoringECG(peripheral
        .monitorCharacteristic(
            hPi4Global.UUID_ECG_SERVICE, hPi4Global.UUID_ECG_CHAR,
            transactionId: "monitorECG")
        .map((characteristic) => characteristic.value));

    _startMonitoringPPG(peripheral
        .monitorCharacteristic(
            hPi4Global.UUID_SERV_STREAM_2, hPi4Global.UUID_STREAM_2,
            transactionId: "monitorPPG")
        .map((characteristic) => characteristic.value));
  }

  void stopECGPPG() async {
    print("Stopping ECG monitoring");

    await bleManager.cancelTransaction("monitorECG");
    await bleManager.cancelTransaction("monitorPPG");

    if (monitoringECGStreamSubscription != null) {
      monitoringECGStreamSubscription.cancel();
    }

    if (monitoringPPGStreamSubscription != null) {
      monitoringPPGStreamSubscription.cancel();
    }
  }

  Widget _buildLivePage() {
    return Column(children: <Widget>[
      //_buildConnectionBlock(),
      Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: <Widget>[
            _buildCharts(),
            //_buildButtonBar(),
          ],
        ),
      ),
    ]);
  }

  Widget _buildMainGrid() {
    return Expanded(
      child: GridView.count(
        primary: false,
        padding: const EdgeInsets.all(20),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        crossAxisCount: 2,
        children: <Widget>[
          Card(
            color: Colors.green[700],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.favorite_border, color: Colors.white),
                        Text(
                            'Heartrate', //: 0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                            style: hPi4Global.cardTextStyle),
                      ],
                    ),
                    Text(
                        globalHeartRate
                            .toString(), //: 0x${service.uuid.toString().toUpperCase().substring(4, 8)}',
                        style: hPi4Global.cardValueTextStyle),
                    Text("bpm", style: hPi4Global.cardTextStyle),
                  ]),
            ),
          ),
          Card(
            color: Colors.yellow[800],
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.directions_run, color: Colors.white),
                      Text('SpO2', style: hPi4Global.cardTextStyle),
                    ],
                  ),
                  Text(globalSpO2.toString(),
                      style: hPi4Global.cardValueTextStyle),
                  //Text("30",style: cardValueTextStyle),
                  Text("%", style: hPi4Global.cardTextStyle),
                ],
              ),
            ),
          ),
          Card(
            color: Colors.blue,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.view_stream, color: Colors.white),
                      Text('Respiration', style: hPi4Global.cardTextStyle),
                    ],
                  ),
                  Text(globalRespRate.toString(),
                      style: hPi4Global.cardValueTextStyle),
                  Text("bpm", style: hPi4Global.cardTextStyle),
                ],
              ),
            ),
          ),
          Card(
            color: Colors.black54,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.view_stream, color: Colors.white),
                      Text('Temperature', style: hPi4Global.cardTextStyle),
                    ],
                  ),
                  Text(globalTemp.toStringAsPrecision(3),
                      style: hPi4Global.cardValueTextStyle),
                  Text("\u00b0 C", style: hPi4Global.cardTextStyle),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void hPi4ConnectPeripheral(ScanResult scanResult) async {
    //Connect to peripheral
    peripheral = scanResult.peripheral;
    peripheral
        .observeConnectionState(
            emitCurrentValue: true, completeOnDisconnect: true)
        .listen((connectionState) {
      print(
          "Peripheral ${scanResult.peripheral.identifier} connection state is $connectionState");
    });

    await peripheral.connect();

    await peripheral.isConnected();
    setState(() {
      hpi4Connected = true;
    });

    //_updateConnectProgress(true, "");

    await peripheral.discoverAllServicesAndCharacteristics();

    hPi4CurrentDeviceName = scanResult.peripheral.name;

    await peripheral.requestMtu(200);

    // Read DIS and set FW Revision
    /*CharacteristicWithValue readValue = await peripheral.readCharacteristic(
        hPi4Global.UUID_SERV_DIS, hPi4Global.UUID_DIS_FW_REVISION);

    String fwrevstring = String.fromCharCodes(readValue.value);
    print("FW Rev: " + fwrevstring);

    setState(() {
      if (fwrevstring != null) {
        //globalFWVersion = fwrevstring;
      }
    });
    */

    List<Service> services = await peripheral.services();
    print("BLE Services: " + services.toString());

    _startMonitoringBattery(peripheral
        .monitorCharacteristic(
            hPi4Global.UUID_SERV_BATT, hPi4Global.UUID_CHAR_BATT,
            transactionId: "monitorBattery")
        .map((characteristic) => characteristic.value));

    _startMonitoringHR(peripheral
        .monitorCharacteristic(hPi4Global.UUID_SERV_HR, hPi4Global.UUID_CHAR_HR,
            transactionId: "monitorHR")
        .map((characteristic) => characteristic.value));

    _startMonitoringHRVResp(peripheral
        .monitorCharacteristic(
            hPi4Global.UUID_SERV_HRV, hPi4Global.UUID_CHAR_HRV,
            transactionId: "monitorHRVResp")
        .map((characteristic) => characteristic.value));

    _startMonitoringSPO2(peripheral
        .monitorCharacteristic(
            hPi4Global.UUID_SERV_SPO2, hPi4Global.UUID_SPO2_CHAR,
            transactionId: "monitorSPO2")
        .map((characteristic) => characteristic.value));

    _startMonitoringTemp(peripheral
        .monitorCharacteristic(
            hPi4Global.UUID_SERV_HEALTH_THERM, hPi4Global.UUID_TEMP_CHAR,
            transactionId: "monitorTemp")
        .map((characteristic) => characteristic.value));
  }

  void _startMonitoringBattery(Stream<Uint8List> characteristicUpdates) async {
    await monitoringBatteryStreamSubscription?.cancel();
    monitoringBatteryStreamSubscription = characteristicUpdates.listen(
      (value) {
        print("Battery: ${value} %");
        setState(() {
          _globalBatteryLevel = value[0];
        });
      },
      onError: (error) {
        print("Error while monitoring battery characteristic \n$error");
      },
      cancelOnError: true,
    );
  }

  void _startMonitoringHR(Stream<Uint8List> characteristicUpdates) async {
    await monitoringHRStreamSubscription?.cancel();
    monitoringHRStreamSubscription = characteristicUpdates.listen(
      (value) {
        if (value != null && value.length > 0) {
          setState(() {
            globalHeartRate = value[1];
          });
        }
      },
      onError: (error) {
        print("Error while monitoring battery characteristic \n$error");
      },
      cancelOnError: true,
    );
  }

  void _startMonitoringHRVResp(Stream<Uint8List> characteristicUpdates) async {
    await monitoringHRVRespStreamSubscription?.cancel();
    monitoringHRVRespStreamSubscription = characteristicUpdates.listen(
      (value) {
        if (value != null && value.length > 0) {
          //print("HRV Received:" + value.toList().toString());
          print("Respiration rate recd:" + value[10].toString());
          setState(() {
            globalRespRate = value[10];
          });
        }
      },
      onError: (error) {
        print("Error while monitoring HRV characteristic \n$error");
      },
      cancelOnError: true,
    );
  }

  void _startMonitoringSPO2(Stream<Uint8List> characteristicUpdates) async {
    await monitoringSPO2StreamSubscription?.cancel();
    monitoringSPO2StreamSubscription = characteristicUpdates.listen(
      (value) {
        if (value != null && value.length > 0) {
          setState(() {
            globalSpO2 = value[1];
          });
        }
      },
      onError: (error) {
        print("Error while monitoring SPO2 characteristic \n$error");
      },
      cancelOnError: true,
    );
  }

  void _startMonitoringTemp(Stream<Uint8List> characteristicUpdates) async {
    await monitoringTempStreamSubscription?.cancel();
    monitoringTempStreamSubscription = characteristicUpdates.listen(
      (value) {
        if (value != null && value.length > 0) {
          setState(() {
            Uint8List u8list = Uint8List.fromList(value);
            globalTemp = ((toInt16(u8list, 0).toDouble()) * 0.01);
          });
        }
      },
      onError: (error) {
        print("Error while monitoring temp characteristic \n$error");
      },
      cancelOnError: true,
    );
  }

  int toInt16(Uint8List byteArray, int index) {
    ByteBuffer buffer = byteArray.buffer;
    ByteData data = new ByteData.view(buffer);
    int short = data.getInt16(index, Endian.little);
    return short;
  }

  void hPi4OnDisconnect() async {
    if (monitoringBatteryStreamSubscription != null) {
      monitoringBatteryStreamSubscription.cancel();
    }
    if (monitoringHRStreamSubscription != null) {
      monitoringHRStreamSubscription.cancel();
    }
    if (monitoringSPO2StreamSubscription != null) {
      monitoringSPO2StreamSubscription.cancel();
    }
    if (monitoringTempStreamSubscription != null) {
      monitoringTempStreamSubscription.cancel();
    }

    if (monitoringECGStreamSubscription != null) {
      monitoringECGStreamSubscription.cancel();
    }

    if (monitoringPPGStreamSubscription != null) {
      monitoringPPGStreamSubscription.cancel();
    }

    if (monitoringHRVRespStreamSubscription != null) {
      monitoringHRVRespStreamSubscription.cancel();
    }

    await bleManager.cancelTransaction("monitorBattery");
    await bleManager.cancelTransaction("monitorHR");
    await bleManager.cancelTransaction("monitorSPO2");
    await bleManager.cancelTransaction("monitorTemp");
    await bleManager.cancelTransaction("monitorECG");
    await bleManager.cancelTransaction("monitorPPG");
    await bleManager.cancelTransaction("monitorHRVResp");

    print("BLE disconnecting... ");
    await peripheral.disconnectOrCancelConnection();
    setState(() {
      hpi4Connected = false;
    });
  }

  String displayText = "--";
  StreamSubscription<ScanResult> _scanSubscription;

  void hPi4OnStartScan() async {
    setState(() {
      /*_logTimerLastTriggered = DateTime.now().toString();
      _logScanResults = "";
      _logDeviceConnected = "";*/
    });

    if (_scanSubscription != null) {
      _scanSubscription.cancel();
    }

    //await bleManager.stopPeripheralScan();

    print("Scan starting...");
    //_updateConnectProgress(false, "Looking for devices...");
    setState(() {
      displayText = "Looking for devices...";
    });
    _scanSubscription = bleManager
        .startPeripheralScan(
            //uuids: [
            //"00001122-0000-1000-8000-00805f9b34fb",
            //],
            )
        .listen((scanResult) async {
      //uuids: [PatchGlobal.UUID_SERVICE_CMD]
      //Scan one peripheral and stop scanning
      print(
          "Scanned Peripheral ${scanResult.peripheral.name}, RSSI ${scanResult.rssi}");

      //_updateConnectProgress(
      //    false, "Connecting to device " + scanResult.peripheral.name + "...");
      if (scanResult.peripheral.name != null) {
        if (scanResult.peripheral.name.toUpperCase().contains("HEALTHY")) {
          _scanSubscription.cancel();
          bleManager.stopPeripheralScan();
          setState(() {
            displayText =
                "Connecting to device " + scanResult.peripheral.name + "...";
          });
          await Future.delayed(Duration(seconds: 3));
          hPi4ConnectPeripheral(scanResult);
        }
      }
    });
  }

  Widget showConnectedDevices() {
    if (hpi4Connected == true) {
      return Column(children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text("Connected to: " + hPi4CurrentDeviceName,
              style: new TextStyle(fontSize: 22.0, color: Colors.green[800])),
        ),
        Padding(
          padding: const EdgeInsets.all(1.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              SizedBox(
                height: 25.0,
                width: 75.0,
                child: CustomPaint(
                  painter:
                      _BatteryLevelPainter(_globalBatteryLevel, _batteryState),
                  child:
                      _batteryState == 1 ? Icon(Icons.flash_on) : Container(),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Material(
                    //Wrap with Material
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0)),
                    elevation: 18.0,
                    color: hPi4Global.hpi4Color,
                    clipBehavior: Clip.antiAlias, // Add This
                    child: MaterialButton(
                      color: hPi4Global.hpi4Color,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            Icons.close,
                            color: Colors.white,
                          ),
                          Text("Disconnect",
                              style: new TextStyle(
                                  fontSize: 14.0, color: Colors.white)),
                        ],
                      ),
                      onPressed: () {
                        //hPi4OnDisconnect(device);
                        hPi4OnDisconnect();
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ]);
    } else {
      return Container();
    }
  }

  Widget showScanResults() {
    if (hpi4Connected == false) {
      return Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                MaterialButton(
                  minWidth: 100.0,
                  color: hPi4Global.hpi4Color,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.refresh,
                        color: Colors.white,
                      ),
                      Text('Scan & Connect',
                          style: new TextStyle(
                              fontSize: 18.0, color: Colors.white)),
                    ],
                  ),
                  onPressed: () {
                    hPi4OnStartScan();
                  },
                ),
              ],
            ),
          ),
        ],
      );
    }
    return Container();
  }

  Widget _buildConnectionBlock() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              showConnectedDevices(),
              //_buildServiceStream(),
              showScanResults(),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                  "Ver: " + hPi4Global.hpi4AppVersion,
                  style: new TextStyle(fontSize: 12),
                ),
              ),
            ]),
      ),
    );
  }

  Widget _getBottomStatusBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 0, 32, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.max,
            children: <Widget>[
              RaisedButton(
                onPressed: () async {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) {
                            return _buildLivePage();
                          },
                          fullscreenDialog: true));
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Text(
                        'Visualize waveforms',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                      Icon(
                        Icons.show_chart,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
                color: Colors.green[600],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    return Scaffold(
      backgroundColor: Colors.grey[300],
      key: _scaffoldKey,
      appBar: AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        backgroundColor: hPi4Global.hpi4Color,
        title: Center(
            child: Image.asset('assets/hpi4_proto_top_logo.png',
                fit: BoxFit.fitHeight)),
      ),
      body: Container(
        color: Colors.black87,
        child: Center(
          child: _buildPageContent(),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: hPi4Global.hpi4Color,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            title: Text('Home'),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            title: Text('Waveforms'),
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.green[400],
        unselectedItemColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _BatteryLevelPainter extends CustomPainter {
  final int _batteryLevel;
  final int _batteryState;

  _BatteryLevelPainter(this._batteryLevel, this._batteryState);

  @override
  void paint(Canvas canvas, Size size) {
    Paint getPaint(
        {Color color = Colors.black,
        PaintingStyle style = PaintingStyle.stroke}) {
      return Paint()
        ..color = color
        ..strokeWidth = 1.0
        ..style = style;
    }

    final double batteryRight = size.width - 4.0;

    final RRect batteryOutline = RRect.fromLTRBR(
        0.0, 0.0, batteryRight, size.height, Radius.circular(3.0));

    // Battery body
    canvas.drawRRect(
      batteryOutline,
      getPaint(),
    );

    // Battery nub
    canvas.drawRect(
      Rect.fromLTWH(batteryRight, (size.height / 2.0) - 5.0, 4.0, 10.0),
      getPaint(style: PaintingStyle.fill),
    );

    // Fill rect
    canvas.clipRect(Rect.fromLTWH(
        0.0, 0.0, batteryRight * _batteryLevel / 100.0, size.height));

    Color indicatorColor;
    if (_batteryLevel < 15) {
      indicatorColor = Colors.red;
    } else if (_batteryLevel < 30) {
      indicatorColor = Colors.orange;
    } else {
      indicatorColor = Colors.green;
    }

    canvas.drawRRect(
        RRect.fromLTRBR(0.5, 0.5, batteryRight - 0.5, size.height - 0.5,
            Radius.circular(3.0)),
        getPaint(style: PaintingStyle.fill, color: indicatorColor));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    final _BatteryLevelPainter old = oldDelegate as _BatteryLevelPainter;
    return old._batteryLevel != _batteryLevel ||
        old._batteryState != _batteryState;
  }
}
