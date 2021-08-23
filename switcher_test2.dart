import 'dart:convert';
import 'dart:io';

main() {
  RawDatagramSocket.bind(InternetAddress.anyIPv4, 20002)
      .then((RawDatagramSocket udpSocket) {
    udpSocket.broadcastEnabled = true;
    udpSocket.listen((e) {
      print('STOP on listen');

      Datagram? dg = udpSocket.receive();
      if (dg != null) {
        print('received ${dg.data}');
      }
    });
    List<int> data = utf8.encode('TEST');
    // var DESTINATION_ADDRESS=InternetAddress("x.y.z.255");
    //
    // udpSocket.send(data, DESTINATION_ADDRESS, 8889);
  });
}
