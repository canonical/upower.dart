import 'package:upower/upower.dart';

void main() async {
  var client = UPowerClient();
  await client.connect();
  client.displayDevice.propertiesChanged.listen((properties) {
    if (properties.contains('State')) {
      print('System power state changed to ${client.displayDevice.state}.');
    }
  });
  print('System power state is currently ${client.displayDevice.state}.');
}
