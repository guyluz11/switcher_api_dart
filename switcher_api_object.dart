import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crclib/crclib.dart';

class SwitcherApiObject {
  SwitcherApiObject({
    required this.deviceType,
    required this.deviceId,
    required this.switcherIp,
    required this.switcherName,
    this.deviceState = SwitcherDeviceState.cantGetState,
    this.devicePass = '00000000',
    this.phoneId = '0000',
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

    final List<String> messageBuffer = intListToHex(data);

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
  String? statusSocket;
  String? lastShutdownRemainingSecondsValue;

  Socket? _socket = null;

  var pSession = null;

  static const P_SESSION = '00000000';
  static const P_KEY = '00000000000000000000000000000000';

  static const STATUS_EVENT = 'status';
  static const READY_EVENT = 'ready';
  static const ERROR_EVENT = 'error';
  static const STATE_CHANGED_EVENT = 'state';

  static const SWITCHER_UDP_IP = '0.0.0.0';
  static const SWITCHER_UDP_PORT = 20002;

  static const String OFF = '0';
  static const String ON = '1';

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

  Future<void> turnOn({int duration = 0}) async {
    String offCommand = ON + '00' + _timerValue(duration);

    await _runPowerCommand(offCommand);
  }

  Future<void> turnOff() async {
    String offCommand = OFF + '00' + '00000000';
    await _runPowerCommand(offCommand);
  }

  Future<void> _runPowerCommand(String commandType) async {
    pSession = await _login();

    var data = "fef05d0002320102" +
        pSession +
        "340001000000000000000000" +
        _getTimeStamp() +
        "00000000000000000000f0fe" +
        deviceId +
        "00" +
        phoneId +
        "0000" +
        devicePass +
        "000000000000000000000000000000000000000000000000000000000106000" +
        commandType;

    data = await _crcSignFullPacketComKey(data, P_KEY);

    Socket socket = await getSocket();
    socket.add(hexStringToDecimalList(data));
    // Uint8List dataFromDevice = await socket.first;
    // print(dataFromDevice);
  }

  /// Used for sending actions to the device
  void sendState({required SwitcherDeviceState command, int minutes = 0}) {
    _getFullState();
  }

  /// Used for sending the get state packaet to the device.
  /// Returns a tuple of hex timestamp, session id and an instance of SwitcherStateResponse
  Future<String> _getFullState() async {
    return _login();
  }

  /// Used for sending the login packet to the device.
  Future<String> _login() async {
    if (pSession != null) return pSession;

    try {
      String data = 'fef052000232a100${P_SESSION}340001000000000000000000'
          '${_getTimeStamp()}00000000000000000000f0fe1c00${this.phoneId}0000'
          '${this.devicePass}'
          '00000000000000000000000000000000000000000000000000000000';

      data = await _crcSignFullPacketComKey(data, P_KEY);
      _socket = await getSocket();
      if (_socket == null) {
        throw 'Error';
      }

      _socket!.add(hexStringToDecimalList(data));

      Uint8List firstData = await _socket!.first;
      var result_session =
          substrLikeInJavaScript(intListToHex(firstData).join(), 16, 8);
      print('First element of the stream is $result_session');

      return result_session;
    } catch (error) {
      log = 'login failed due to an error $error';
      print(log);
      pSession = 'B';
    }
    return pSession;
  }

  static Future<String> _crcSignFullPacketComKey(
      String pData, String pKey) async {
    List<int> bufferHex = hexStringToDecimalList(pData);

    String crc = intListToHex(packBigEndian(
            int.parse(Crc16XmodemWith0x1021().convert(bufferHex).toString())))
        .join();

    pData = pData +
        substrLikeInJavaScript(crc, 6, 2) +
        substrLikeInJavaScript(crc, 4, 2);

    crc = substrLikeInJavaScript(crc, 6, 2) +
        substrLikeInJavaScript(crc, 4, 2) +
        getUtf8Encoded(pKey);

    crc = intListToHex(packBigEndian(int.parse(Crc16XmodemWith0x1021()
            .convert(hexStringToDecimalList(crc))
            .toString())))
        .join();

    pData = pData +
        substrLikeInJavaScript(crc, 6, 2) +
        substrLikeInJavaScript(crc, 4, 2);

    print(substrLikeInJavaScript('000094a6', 4, 2));

    return pData;
  }

  static String _getTimeStamp() {
    int timeInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    List<int> timeInBytes = packLittleEndian(timeInSeconds);

    String inHex = intListToHex(timeInBytes).join();

    return inHex;
  }

  /// Same as Buffer.from(value, 'hex') in JavaScript
  static List<int> hexStringToDecimalList(String hex) {
    List<int> decimalIntList = [];
    String twoNumbers = '';

    for (int i = 0; i < hex.length; i++) {
      if (twoNumbers == '') {
        twoNumbers = twoNumbers + hex[i];
        continue;
      } else {
        twoNumbers = twoNumbers + hex[i];
        decimalIntList.add(int.parse(twoNumbers, radix: 16));
        twoNumbers = '';
      }
    }
    return decimalIntList;
  }

  // static List<String> decimalStringToDecimalStringList(String decimal) {
  //   List<String> decimalIntList = [];
  //   String twoNumbers = '';
  //
  //   for (int i = 0; i < decimal.length; i++) {
  //     if (twoNumbers == '') {
  //       twoNumbers = twoNumbers + decimal[i];
  //
  //       continue;
  //     } else {
  //       twoNumbers = twoNumbers + decimal[i];
  //
  //       decimalIntList.add(twoNumbers);
  //       twoNumbers = '';
  //     }
  //   }
  //   return decimalIntList;
  // }

  /// Convert number to unsigned integer as little-endian sequence of bytes
  /// Same as struct.pack('<I', value) in JavaScript
  static List<int> packLittleEndian(int valueToConvert) {
    ByteData sendValueBytes = ByteData(8);

    try {
      sendValueBytes.setUint64(0, valueToConvert, Endian.little);
    } on UnsupportedError {
      sendValueBytes.setUint32(0, valueToConvert, Endian.little);
    }

    Uint8List timeInBytes = sendValueBytes.buffer.asUint8List();
    timeInBytes = timeInBytes.sublist(0, timeInBytes.length - 4);

    return timeInBytes;
  }

  /// Convert number to unsigned integer as big-endian sequence of bytes
  /// Same as struct.pack('>I', value) in JavaScript
  static List<int> packBigEndian(int valueToConvert) {
    ByteData sendValueBytes = ByteData(8);

    try {
      sendValueBytes.setUint64(0, valueToConvert, Endian.big);
    } on UnsupportedError {
      sendValueBytes.setUint32(0, valueToConvert, Endian.big);
    }

    Uint8List timeInBytes = sendValueBytes.buffer.asUint8List();
    timeInBytes = timeInBytes.sublist(4);

    return timeInBytes;
  }

  /// Convert list of bytes/integers into their hex 16 value with padding 2 of 0
  /// Same as .toString('hex'); in JavaScript
  static List<String> intListToHex(List<int> bytes) {
    final List<String> messageBuffer = [];

    for (final int unit8 in bytes) {
      messageBuffer.add(unit8.toRadixString(16).padLeft(2, '0'));
    }
    return messageBuffer;
  }

  /// Generate hexadecimal representation of the current timestamp.
  /// Return: Hexadecimal representation of the current unix time retrieved by ``time.time``.
  String currentTimestampToHexadecimal() {
    String currentTimeSinceEpoch =
        DateTime.now().millisecondsSinceEpoch.toString();
    String currentTimeRounded =
        currentTimeSinceEpoch.substring(0, currentTimeSinceEpoch.length - 3);
    print(currentTimeRounded);

    int currentTimeInt = int.parse(currentTimeRounded);

    // TODO: Undestand what is pack("<I", currentTimeInt) in python and continue
    // Packed binary_timestamp = Packed(currentTimeInt);
    // print(binary_timestamp);

    return currentTimeInt.toRadixString(16).padLeft(2, '0');
  }

  /// Sign the packets with the designated crc key.
  /// Return: The calculated and signed packet.
  String signPacketWithCrcKey(String hexPacket) {
    List<int> binaryPacket = hexDecimalStringToDecimalList(hexPacket);

    int result =
        int.parse(Crc16XmodemWith0x1021().convert(binaryPacket).toString());

    print(intListToHex(packLittleEndian(result)));

    print('');
    print('bin $result');
    return 'a';
  }

  /// Convert Hexadecimal String (example FE) to Decimal list (will be 254).
  /// Called in python unhexlify.
  List<int> hexDecimalStringToDecimalList(String hexDecimalString) {
    List<int> binaryPacket = [];

    for (int i = 0; i <= hexDecimalString.length - 2; i += 2) {
      final hex = hexDecimalString.substring(i, i + 2);

      final number = int.parse(hex, radix: 16);
      binaryPacket.add(number);
    }
    return binaryPacket;
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

  /// Substring like in JavaScript
  /// If first index is bigger than second index than it will cut until the
  /// first and will get the second index number of characters from there
  static String substrLikeInJavaScript(
      String text, int firstIndex, int secondIndex) {
    String tempText = text;
    if (firstIndex > secondIndex) {
      tempText = tempText.substring(firstIndex);
      tempText = tempText.substring(0, secondIndex);
    } else {
      tempText = tempText.substring(firstIndex, secondIndex);
    }
    return tempText;
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

  /// Same as Buffer.from(value) in javascript
  /// Not to be confused with Buffer.from(value, 'hex')
  static String getUtf8Encoded(String list) {
    List<int> encoded = utf8.encode(list);

    return intListToHex(encoded).join();
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

  Future<Socket> getSocket() async {
    if (_socket != null) {
      return _socket!;
    }

    try {
      Socket socket = await _connect(switcherIp, port);
      print('connected');

      // Uint8List firstData = await socket.first;
      // print('firstData is $firstData');
      // listen to the received data event stream

      // socket.listen((List<int> event) {
      //   print('Got massage on socket');
      //   print(utf8.decode(event));
      // })
      //   ..onDone(() {
      //     print('On Done');
      //   })
      //   ..onError((e) {
      //     print('On Error $e');
      //   });

      // await Future.delayed(Duration(seconds: 20));
      return socket;
    } catch (e) {
      _socket = null;
      print('Error connecting to socket $e');
      throw e;
    }
  }

  Future<Socket> _connect(String ip, int port) async {
    print('ip:$ip port: $port');
    Socket a = await Socket.connect(ip, port);
    return a;
  }

  String _timerValue(int minutes) {
    if (minutes == 0)
      return "00000000"; // when duration set to zero, Switcher sends regular on command
    var seconds = minutes * 60;
    return intListToHex(packLittleEndian(seconds)).join();
  }
}

class Crc16XmodemWith0x1021 extends ParametricCrc {
  Crc16XmodemWith0x1021()
      : super(16, 0x1021, 0x1021, 0x0000,
            inputReflected: false, outputReflected: false);
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
