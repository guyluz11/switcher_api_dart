import 'dart:io';
import 'dart:typed_data';

import 'switcher_entity.dart';


void main(List args) async {
  print('Start');
  getDevices().listen((event) {
    print('One more $event');
  });

  while (true) {
    await Future.delayed(Duration(seconds: 1));
  }
}


Stream<int?> getDevices() async* {
  // final String myHexKey = 167.toRadixString(16);

  // 192.168.31.206


  final RawDatagramSocket socket =
      await RawDatagramSocket.bind(InternetAddress.anyIPv4, 20002);

    print('UDP Echo ready to receive');
    print('${socket.address.address}:${socket.port}');
    print('');


  await for(final a in socket){
    Datagram? d = socket.receive();
    print('Received socket');
    if (d == null) continue;

    SwitcherEntity switcherEntity = SwitcherEntity.CreateWithBytes(d);

    print('');
    print('Datagram from ${switcherEntity.switcherIp}:${switcherEntity.port}, type: ${switcherEntity.deviceType}, '
        // 'id: $deviceId, ');
    'id: ${switcherEntity.deviceId}, state: ${switcherEntity.deviceState}');
    // print('utf8: ${utf8.decode(d.data)}');

  };

}
