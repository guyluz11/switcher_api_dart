import 'dart:io';
import 'dart:typed_data';

import 'dart:convert' show utf8;


class SwitcherEntity {


  SwitcherEntity({required this.deviceType, required this.deviceId,
    required this.switcherIp, required this.switcherName, this.socket,
    this.deviceState = SwitcherDeviceState.CantGetState,
    this.devicePass = '00000000', this.phoneId = '0000', this.pSession,
    this.statusSocket ,this.log, this.port = 9957,
    this.lastShutdownRemainingSecondsValue, required this.macAddress,
    required this.powerConsumption,
    this.remainingTimeForExecution,
  });

  factory SwitcherEntity.CreateWithBytes(Datagram datagram){
    Uint8List data = datagram.data;

    List<String> messageBuffer = [];

    for (int a in data) {
      messageBuffer.add(a.toRadixString(16).padLeft(2, '0'));
    }

    List<String> hexSeparatedLetters = [];

    for (String hexValue in messageBuffer) {
      hexValue.runes.forEach((element) {
        hexSeparatedLetters.add(String.fromCharCode(element));
      });
    }


    if(!isSwitcherMessage(data, hexSeparatedLetters)){
      print('Not a switcher message arrived to here');
    }


    SwitcherDevicesTypes sDeviceType = getDeviceType(messageBuffer);
    String deviceId = getDeviceId(hexSeparatedLetters);
    SwitcherDeviceState switcherDeviceState = getDeviceState(hexSeparatedLetters);
    // String switcherIp = getDeviceIp(hexSeparatedLetters);
    String switcherIp = datagram.address.address;
    String switcherMac = getMac(hexSeparatedLetters);
    String powerConsumption = getPowerConsumption(hexSeparatedLetters);
    String getRemaining = getRemainingTimeForExecution(hexSeparatedLetters);
    String switcherName = getDeviceName(data);
    String lastShutdownRemainingSecondsValue = shutdownRemainingSeconds(hexSeparatedLetters);

    return SwitcherEntity(deviceType: sDeviceType, deviceId: deviceId,
      switcherIp: switcherIp, deviceState: switcherDeviceState,
      switcherName: switcherName, macAddress: switcherMac,
      lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
      powerConsumption: powerConsumption,
      remainingTimeForExecution: getRemaining
    );
  }

  String deviceId;
  String switcherIp;
  SwitcherDevicesTypes deviceType;
  SwitcherDeviceState deviceState;
  int port;
  String switcherName;
  String phoneId;
  String powerConsumption;
  String devicePass;
  String macAddress;
  String? remainingTimeForExecution;
  String? socket;
  String? log;
  String? pSession;
  String? statusSocket;
  String? lastShutdownRemainingSecondsValue;



  static bool isSwitcherMessage(Uint8List data, List<String> hexSeparatedLetters) {

    // Verify the broadcast message had originated from a switcher device.
    return hexSeparatedLetters.sublist(0, 4).join() == 'fef0' && data.length == 165;
  }

  static SwitcherDevicesTypes getDeviceType(List<String> message_buffer) {
    SwitcherDevicesTypes sDevicesTypes = SwitcherDevicesTypes.NotRecognized;

    String hex_model = message_buffer.sublist(75, 76)[0].toString();

    if ('a7' == hex_model) {
      sDevicesTypes = SwitcherDevicesTypes.Switcher_V2_esp;
    } else {
      print('Cant find type $hex_model');
    }

    return sDevicesTypes;
  }

  static String getDeviceIp(List<String> hexSeparatedLetters) {
    // Extract the IP address from the broadcast message.
    // TODO: Fix function to return ip and not hexIp
    List<String> hexIp = hexSeparatedLetters.sublist(152, 160);
    // int ipAddressInt = int.parse(hexIp.sublist(6, 8).join() + hexIp.sublist(4, 6).join() + hexIp.sublist(2, 4).join() + hexIp.sublist(0, 2).join());
    // int ipAddressStringInt = int.parse(hexIp.sublist(6, 8).join()) + int.parse(hexIp.sublist(4, 6).join()) + int.parse(hexIp.sublist(2, 4).join()) + int.parse(hexIp.sublist(0, 2).join());
    // int(hex_ip[6:8] + hex_ip[4:6] + hex_ip[2:4] + hex_ip[0:2], 16)
    return hexIp.toString();
  }

  static String getPowerConsumption(List<String> hexSeparatedLetters) {
    List<String> hex_power_consumption = hexSeparatedLetters.sublist(270, 278);

    // return int.parse(hex_power_consumption.sublist(2, 4).join()) + int(hex_power_consumption.sublist(0, 2).join());
    return hex_power_consumption.join();
  }

  /// Extract the time remains for the current execution.
  static String getRemainingTimeForExecution(List<String> hexSeparatedLetters) {
    List<String> hex_power_consumption = hexSeparatedLetters.sublist(294, 302);
    try {
      int sum =
          int.parse(hex_power_consumption.sublist(6, 8).join()) +
              int.parse(hex_power_consumption.sublist(4, 6).join()) +
              int.parse(hex_power_consumption.sublist(2, 4).join()) +
              int.parse(hex_power_consumption.sublist(0, 2).join());

      // TODO: complete the calculation of the remaining time
      return sum.toString();
    }
    catch (e) {
      return hex_power_consumption.join();
    }
  }

  static String getMac(List<String> hexSeparatedLetters) {
    String macNoColon = hexSeparatedLetters.sublist(160, 172).join().toUpperCase();
    String macAddress = '${macNoColon.substring(0, 2)}:'
        '${macNoColon.substring(2, 4)}:${macNoColon.substring(4, 6)}:'
        '${macNoColon.substring(6, 8)}:${macNoColon.substring(8, 10)}:'
        '${macNoColon.substring(10, 12)}';

    return macAddress;
  }

  static String getDeviceName(List<int> data) {
    return utf8.decode(data.sublist(42, 74));
  }

  static String shutdownRemainingSeconds(List<String> hexSeparatedLetters) {
    String hexAutoShutdownVal = hexSeparatedLetters.sublist(310, 318).join();
    // TODO: Complete the code from python
    // int int_auto_shutdown_val_secs = int.parse(
    //   hexAutoShutdownVal.substring(6, 8)
    // + hexAutoShutdownVal.substring(4, 6)
    // + hexAutoShutdownVal.substring(2, 4)
    // + hexAutoShutdownVal.substring(0, 2),
    // 16,
    // );
    // seconds_to_iso_time(int_auto_shutdown_val_secs)
    // """Convert seconds to iso time.
    //
    // Args:
    //     all_seconds: the total number of seconds to convert.
    //
    // Return:
    //     A string representing the converted iso time in %H:%M:%S format.
    //     e.g. "02:24:37".
    //
    // """
    // minutes, seconds = divmod(int(all_seconds), 60)
    // hours, minutes = divmod(minutes, 60)
    //
    // return datetime.time(hour=hours, minute=minutes, second=seconds).isoformat()
    return hexAutoShutdownVal;
  }

  // /// Not sure what is this but it is exist in other switcher programs
  // static String inetNtoa(List<String> hexSeparatedLetters) {
  //   // extract to utils https://stackoverflow.com/a/21613691
  //
  //   // JavascriptCode
  //   // var a = ((num >> 24) & 0xFF) >>> 0;
  //   // var b = ((num >> 16) & 0xFF) >>> 0;
  //   // var c = ((num >> 8) & 0xFF) >>> 0;
  //   // var d = (num & 0xFF) >>> 0;
  // }

  static String getDeviceId(List<String> hexSeparatedLetters) {
    return hexSeparatedLetters.sublist(36, 42).join();
  }

  static SwitcherDeviceState getDeviceState(List<String> hexSeparatedLetters) {
    SwitcherDeviceState switcherDeviceState = SwitcherDeviceState.CantGetState;


    String hex_model = '';

    hexSeparatedLetters.sublist(266, 270).forEach((item){
      hex_model += item.toString();
    });


    if (hex_model == '0100') {
      switcherDeviceState = SwitcherDeviceState.ON;
    } else if (hex_model == '0000') {
      switcherDeviceState = SwitcherDeviceState.OFF;
    }
    else{
      print('Hex is not recognized: $hex_model');
    }
    return switcherDeviceState;
  }
}


enum SwitcherDeviceState {
// """Enum class representing the device's state."""
//
// ON = "0100", "on"
// OFF = "0000", "off"
  CantGetState,
  ON,
  OFF,
}

enum SwitcherDevicesTypes {
  // """Enum for relaying the type of the switcher devices."""
  //
  // MINI = "Switcher Mini", "0f", DeviceCategory.WATER_HEATER
  // POWER_PLUG = "Switcher Power Plug", "a8", DeviceCategory.POWER_PLUG
  // TOUCH = "Switcher Touch", "0b", DeviceCategory.WATER_HEATER
  // V2_ESP = "Switcher V2 (esp)", "a7", DeviceCategory.WATER_HEATER
  // V2_QCA = "Switcher V2 (qualcomm)", "a1", DeviceCategory.WATER_HEATER
  // V4 = "Switcher V4", "17", DeviceCategory.WATER_HEATER
  //
  NotRecognized,
  Switcher_Mini,
  Switcher_Power_Plug,
  Switcher_Touch,
  Switcher_V2_esp,
  Switcher_V2_qualcomm,
  Switcher_V4,
}


