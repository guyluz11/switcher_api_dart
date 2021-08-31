import 'dart:convert' show utf8;
import 'dart:io';
import 'dart:typed_data';

class SwitcherApiObject {
  SwitcherApiObject({
    required this.deviceType,
    required this.deviceId,
    required this.switcherIp,
    required this.switcherName,
    this.deviceState = SwitcherDeviceState.cantGetState,
    this.devicePass = '00000000',
    this.phoneId = '0000',
    this.pSession,
    this.statusSocket,
    this.log,
    this.port = 9957,
    this.lastShutdownRemainingSecondsValue,
    required this.macAddress,
    required this.powerConsumption,
    this.remainingTimeForExecution,
  });

  factory SwitcherApiObject.createWithBytes(Datagram datagram) {
    final Uint8List data = datagram.data;

    final List<String> messageBuffer = [];

    for (final int unit8 in data) {
      messageBuffer.add(unit8.toRadixString(16).padLeft(2, '0'));
    }

    final List<String> hexSeparatedLetters = [];

    for (final String hexValue in messageBuffer) {
      hexValue.runes.forEach((element) {
        hexSeparatedLetters.add(String.fromCharCode(element));
      });
    }

    if (!isSwitcherMessage(data, hexSeparatedLetters)) {
      print('Not a switcher message arrived to here');
    }

    final SwitcherDevicesTypes sDeviceType = getDeviceType(messageBuffer);
    final String deviceId = getDeviceId(hexSeparatedLetters);
    final SwitcherDeviceState switcherDeviceState =
        getDeviceState(hexSeparatedLetters);
    // String switcherIp = getDeviceIp(hexSeparatedLetters);
    final String switcherIp = datagram.address.address;
    final String switcherMac = getMac(hexSeparatedLetters);
    final String powerConsumption = getPowerConsumption(hexSeparatedLetters);
    final String getRemaining =
        getRemainingTimeForExecution(hexSeparatedLetters);
    final String switcherName = getDeviceName(data);
    final String lastShutdownRemainingSecondsValue =
        shutdownRemainingSeconds(hexSeparatedLetters);

    return SwitcherApiObject(
        deviceType: sDeviceType,
        deviceId: deviceId,
        switcherIp: switcherIp,
        deviceState: switcherDeviceState,
        switcherName: switcherName,
        macAddress: switcherMac,
        lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
        powerConsumption: powerConsumption,
        remainingTimeForExecution: getRemaining);
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
  String? log;
  String? pSession;
  String? statusSocket;
  String? lastShutdownRemainingSecondsValue;

  static bool isSwitcherMessage(
      Uint8List data, List<String> hexSeparatedLetters) {
    // Verify the broadcast message had originated from a switcher device.
    return hexSeparatedLetters.sublist(0, 4).join() == 'fef0' &&
        data.length == 165;
  }

  static SwitcherDevicesTypes getDeviceType(List<String> messageBuffer) {
    SwitcherDevicesTypes sDevicesTypes = SwitcherDevicesTypes.notRecognized;

    final String hexModel = messageBuffer.sublist(75, 76)[0].toString();

    if (hexModel == '0f') {
      sDevicesTypes = SwitcherDevicesTypes.switcherMini;
    } else if (hexModel == 'a8') {
      sDevicesTypes = SwitcherDevicesTypes.switcherPowerPlug;
    } else if (hexModel == '0b') {
      sDevicesTypes = SwitcherDevicesTypes.switcherTouch;
    } else if (hexModel == 'a7') {
      sDevicesTypes = SwitcherDevicesTypes.switcherV2Esp;
    } else if (hexModel == 'a1') {
      sDevicesTypes = SwitcherDevicesTypes.switcherV2qualcomm;
    } else if (hexModel == '17') {
      sDevicesTypes = SwitcherDevicesTypes.switcherV4;
    } else {
      print('New device type? hexModel:$hexModel');
    }

    return sDevicesTypes;
  }

  static String getDeviceIp(List<String> hexSeparatedLetters) {
    // Extract the IP address from the broadcast message.
    // TODO: Fix function to return ip and not hexIp
    final List<String> hexIp = hexSeparatedLetters.sublist(152, 160);
    // int ipAddressInt = int.parse(hexIp.sublist(6, 8).join() + hexIp.sublist(4, 6).join() + hexIp.sublist(2, 4).join() + hexIp.sublist(0, 2).join());
    // int ipAddressStringInt = int.parse(hexIp.sublist(6, 8).join()) + int.parse(hexIp.sublist(4, 6).join()) + int.parse(hexIp.sublist(2, 4).join()) + int.parse(hexIp.sublist(0, 2).join());
    // int(hex_ip[6:8] + hex_ip[4:6] + hex_ip[2:4] + hex_ip[0:2], 16)
    return hexIp.toString();
  }

  static String getPowerConsumption(List<String> hexSeparatedLetters) {
    final List<String> hex_power_consumption =
        hexSeparatedLetters.sublist(270, 278);

    // return int.parse(hex_power_consumption.sublist(2, 4).join()) + int(hex_power_consumption.sublist(0, 2).join());
    return hex_power_consumption.join();
  }

  /// Extract the time remains for the current execution.
  static String getRemainingTimeForExecution(List<String> hexSeparatedLetters) {
    final List<String> hex_power_consumption =
        hexSeparatedLetters.sublist(294, 302);
    try {
      final int sum = int.parse(hex_power_consumption.sublist(6, 8).join()) +
          int.parse(hex_power_consumption.sublist(4, 6).join()) +
          int.parse(hex_power_consumption.sublist(2, 4).join()) +
          int.parse(hex_power_consumption.sublist(0, 2).join());

      // TODO: complete the calculation of the remaining time
      return sum.toString();
    } catch (e) {
      return hex_power_consumption.join();
    }
  }

  static String getMac(List<String> hexSeparatedLetters) {
    final String macNoColon =
        hexSeparatedLetters.sublist(160, 172).join().toUpperCase();
    final String macAddress = '${macNoColon.substring(0, 2)}:'
        '${macNoColon.substring(2, 4)}:${macNoColon.substring(4, 6)}:'
        '${macNoColon.substring(6, 8)}:${macNoColon.substring(8, 10)}:'
        '${macNoColon.substring(10, 12)}';

    return macAddress;
  }

  static String getDeviceName(List<int> data) {
    return utf8.decode(data.sublist(42, 74));
  }

  static String shutdownRemainingSeconds(List<String> hexSeparatedLetters) {
    final String hexAutoShutdownVal =
        hexSeparatedLetters.sublist(310, 318).join();
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
    SwitcherDeviceState switcherDeviceState = SwitcherDeviceState.cantGetState;

    String hexModel = '';

    hexSeparatedLetters.sublist(266, 270).forEach((item) {
      hexModel += item.toString();
    });

    if (hexModel == '0100') {
      switcherDeviceState = SwitcherDeviceState.on;
    } else if (hexModel == '0000') {
      switcherDeviceState = SwitcherDeviceState.off;
    } else {
      print('Switcher state is not recognized: $hexModel');
    }
    return switcherDeviceState;
  }
}

enum SwitcherDeviceState {
// """Enum class representing the device's state."""
//
// ON = "0100", "on"
// OFF = "0000", "off"
  cantGetState,
  on,
  off,
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
  notRecognized,
  switcherMini,
  switcherPowerPlug,
  switcherTouch,
  switcherV2Esp,
  switcherV2qualcomm,
  switcherV4,
}
