import 'dart:async';
import 'dart:convert';
import 'dart:io';

main() async {
  Socket socket = await Socket.connect('192.168.31.206', 9957);
  print('connected');

  // listen to the received data event stream
  socket.listen((List<int> event) {
    print(utf8.decode(event));
  });

  // send hello
  socket.add(utf8.encode('hello'));

  // wait 5 seconds
  await Future.delayed(Duration(seconds: 5));

  // .. and close the socket
  socket.close();
}
