import 'package:upower/upower.dart';

void main() async {
  var client = UPowerClient();
  await client.connect();
  client.propertiesChanged.listen((properties) {
    if (properties.contains('OnBattery')) {
      print('On battery: ${client.onBattery}');
    }
  });
  print('On battery: ${client.onBattery}');
}
