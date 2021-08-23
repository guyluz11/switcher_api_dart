import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

void main(List args) {
  // final String myHexKey = 167.toRadixString(16);

  // 192.168.31.206
  RawDatagramSocket.bind(InternetAddress.anyIPv4, 20002)
      .then((RawDatagramSocket socket) {
    print('UDP Echo ready to receive');
    print('${socket.address.address}:${socket.port}');
    print('');

    socket.listen((RawSocketEvent e) {
      Datagram? d = socket.receive();
      print('Received socket');
      if (d == null) return;

      SwitcherDevicesTypes sDeviceType = getDeviceType(d.data);
      // SwitcherDeviceState switcherDeviceState = getDeviceState(d.data);

      print('Data: ${d.data}');
      print('Datagram from ${d.address.address}:${d.port}: type: $sDeviceType '
          'state:');
      // print('Datagram from ${d.address.address}:${d.port}: type: $sDeviceType '
      //     'state: $switcherDeviceState');
      print('utf8: ${utf8.decode(d.data)}');

      print('');
      String message = String.fromCharCodes(d.data).trim();

      socket.send(message.codeUnits, d.address, d.port);
    });
  });
}

SwitcherDevicesTypes getDeviceType(Uint8List data) {
  SwitcherDevicesTypes sDevicesTypes = SwitcherDevicesTypes.NotRecognized;
  String hex_model = data.sublist(75, 76)[0].toRadixString(16);

  if ('a7' == hex_model) {
    sDevicesTypes = SwitcherDevicesTypes.Switcher_V2_esp;
  }

  return sDevicesTypes;
}

SwitcherDeviceState getDeviceState(Uint8List data) {
  SwitcherDeviceState switcherDeviceState = SwitcherDeviceState.CantGetState;
  String hex_model = data.sublist(266, 270)[0].toRadixString(16);

  if (hex_model == 'on') {
    switcherDeviceState = SwitcherDeviceState.ON;
  } else if (hex_model == 'off') {
    switcherDeviceState = SwitcherDeviceState.OFF;
  }
  return switcherDeviceState;
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