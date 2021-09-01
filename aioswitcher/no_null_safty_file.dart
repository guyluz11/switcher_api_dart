import 'package:crclib/catalog.dart';
import 'package:crclib/crclib.dart';

class NoNullSaftyMethods {
  static String getCrc16CcittTrue(List<int> listOfNumbers) {
    CrcValue a = Crc16GeniBus().convert(listOfNumbers);
    CrcValue b = Crc16Gsm().convert(listOfNumbers);
    CrcValue c = Crc16Ibm3740().convert(listOfNumbers);
    CrcValue d = Crc16IbmSdlc().convert(listOfNumbers);
    CrcValue e = Crc16IsoIec144433A().convert(listOfNumbers);
    CrcValue f = Crc16Kermit().convert(listOfNumbers);
    CrcValue g = Crc16Mcrf4xx().convert(listOfNumbers);
    CrcValue h = Crc16Riello().convert(listOfNumbers);
    CrcValue j = Crc16SpiFujitsu().convert(listOfNumbers);
    CrcValue l = Crc16Tms37157().convert(listOfNumbers);
    CrcValue m = Crc16Xmodem().convert(listOfNumbers);

    return a.toString();
  }
}
