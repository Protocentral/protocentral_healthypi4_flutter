import 'package:flutter/material.dart';

class hPi4Global {
  static const String UUID_SERV_DIS = "0000180a-0000-1000-8000-00805f9b34fb";
  static const String UUID_SERV_BATT = "0000180f-0000-1000-8000-00805f9b34fb";
  static const String UUID_SERV_HR = "0000180d-0000-1000-8000-00805f9b34fb";
  static const String UUID_SERV_SPO2 = "00001822-0000-1000-8000-00805f9b34fb";
  static const String UUID_SERV_HRV = "cd5c7491-4448-7db8-ae4c-d1da8cba36d0";

  static const String UUID_CHAR_HRV = "cd5ca86f-4448-7db8-ae4c-d1da8cba36d0";

  static const String UUID_SERVICE_CMD = "01bf7492-970f-8d96-d44d-9023c47faddc";
  static const String UUID_CHAR_CMD = "01bf1527-970f-8d96-d44d-9023c47faddc";
  static const String UUID_CHAR_CMD_DATA =
      "01bf1528-970f-8d96-d44d-9023c47faddc";

  static const String UUID_ECG_SERVICE = "00001122-0000-1000-8000-00805f9b34fb";

  static const String UUID_ECG_CHAR = "00001424-0000-1000-8000-00805f9b34fb";

  static const String UUID_SERV_STREAM_2 =
      "cd5c7491-4448-7db8-ae4c-d1da8cba36d0";
  static const String UUID_STREAM_2 = "01bf1525-970f-8d96-d44d-9023c47faddc";

  static const String UUID_CHAR_HR = "00002a37-0000-1000-8000-00805f9b34fb";
  static const String UUID_SPO2_CHAR = "00002a5e-0000-1000-8000-00805f9b34fb";
  //static const String UUID_RR_CHAR      = "00002a6e-0000-1000-8000-00805f9b34fb";
  static const String UUID_TEMP_CHAR = "00002a6e-0000-1000-8000-00805f9b34fb";

  static const String UUID_CHAR_HIST = "01bf1525-970f-8d96-d44d-9023c47faddc";
  static const String UUID_CHAR_ACT = "000000a2-0000-1000-8000-00805f9b34fb";
  static const String UUID_CHAR_BATT = "00002a19-0000-1000-8000-00805f9b34fb";
  static const String UUID_DIS_FW_REVISION =
      "00002a26-0000-1000-8000-00805f9b34fb";
  static const String UUID_SERV_HEALTH_THERM =
      "00001809-0000-1000-8000-00805f9b34fb";

  static const TextStyle eventStyle =
      TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle cardTextStyle =
      TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white);
  static const TextStyle cardValueTextStyle =
      TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.white);

  static const TextStyle cardBlackTextStyle =
      TextStyle(fontSize: 20, color: Colors.black);

  static const TextStyle eventsWhite =
      TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white);

  static const Color hpi4Color = Color(0xFF125871);

  static String hpi4AppVersion = "";
  static String hpi4AppBuildNumber = "";
}

/// Sample time series data type.
class HRSeries {
  final DateTime time;
  final int hr;

  HRSeries(this.time, this.hr);
}

/// Sample linear data type.
class ECGPoint {
  final int time;
  final double voltage;
  //final String labelValue;
  ECGPoint(this.time, this.voltage);
}
