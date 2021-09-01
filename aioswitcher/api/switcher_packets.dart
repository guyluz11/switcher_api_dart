class SwitcherPackets {
  ///Switcher integration TCP socket API packet formats.///

// weekdays sum, start-time timestamp, end-time timestamp
  static String SCHEDULE_CREATE_DATA_FORMAT = '01{}01{}{}';

  static String NO_TIMER_REQUESTED = '00000000';

  static String NON_RECURRING_SCHEDULE = '00';

// format values are local session id, timestamp
  static String REQUEST_FORMAT =
      '{}340001000000000000000000{}00000000000000000000f0fe';

  static String PAD_74_ZEROS = '0' * 74;

// format value just timestamp (initial session id is '00000000')
  static String LOGIN_PACKET = 'fef052000232a10000000000' +
      REQUEST_FORMAT.substring(2) +
      '1c' +
      PAD_74_ZEROS;

// format values are local session id, timestamp, device id
  static String GET_STATE_PACKET = 'fef0300002320103' + REQUEST_FORMAT + '{}00';

// format values are local session id, timestamp, device id, command, timer
  static String SEND_CONTROL_PACKET = 'fef05d0002320102' +
      REQUEST_FORMAT +
      '{}' +
      PAD_74_ZEROS +
      '0106000{}00{}';

// format values are local session id, timestamp, device id, auto-off seconds
  static String SET_AUTO_OFF_SET_PACKET =
      'fef05b0002320102' + REQUEST_FORMAT + '{}' + PAD_74_ZEROS + '040400{}';

// format values are local session id, timestamp, device id, name
  static String UPDATE_DEVICE_NAME_PACKET =
      'fef0740002320202' + REQUEST_FORMAT + '{}' + PAD_74_ZEROS + '{}';

// format values are local session id, timestamp, device id
  static String GET_SCHEDULES_PACKET =
      'fef0570002320102' + REQUEST_FORMAT + '{}' + PAD_74_ZEROS + '060000';

// format values are local session id, timestamp, device id, schedule id
  static String DELETE_SCHEDULE_PACKET =
      'fef0580002320102' + REQUEST_FORMAT + '{}' + PAD_74_ZEROS + '0801000{}';

// format values are local session id, timestamp, device id,
// schedule data =
//                   (on_off + week + timstate + start_time + end_time)
  static String CREATE_SCHEDULE_PACKET =
      'fef0630002320102' + REQUEST_FORMAT + '{}' + PAD_74_ZEROS + '030c00ff{}';
}
