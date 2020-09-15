import 'package:dbus/dbus.dart';
import 'package:upower/upower.dart';

void main() async {
  var systemBus = DBusClient.system();
  var client = UPowerClient(systemBus);
  await client.connect();
  print('Running UPower ${client.daemonVersion}');
  print('System state: ${client.displayDevice.state}');
  print('Devices:');
  for (var device in client.devices) {
    print('  ${device.type} ${device.percentage}%');
  }
  client.close();
  await systemBus.close();
}
