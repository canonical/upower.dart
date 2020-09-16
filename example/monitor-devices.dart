import 'package:dbus/dbus.dart';
import 'package:upower/upower.dart';

void main() async {
  var systemBus = DBusClient.system();
  var client = UPowerClient(systemBus);
  await client.connect();
  client.deviceAdded.listen((device) {
    print('Device ${device.nativePath} (${device.type}) added.');
  });
  client.deviceRemoved.listen((device) {
    print('Device ${device.nativePath} (${device.type}) removed.');
  });
  print('Current devices:');
  for (var device in client.devices) {
    print('  ${device.nativePath} (${device.type})');
  }
}
