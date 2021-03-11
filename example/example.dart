import 'package:upower/upower.dart';

void main() async {
  var client = UPowerClient();
  await client.connect();
  print('Running UPower ${client.daemonVersion}');
  print('System state: ${client.displayDevice.state}');
  print('Devices:');
  for (var device in client.devices) {
    print('  ${device.type} ${device.percentage}%');
  }
  await client.close();
}
