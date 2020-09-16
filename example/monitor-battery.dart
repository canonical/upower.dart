import 'package:dbus/dbus.dart';
import 'package:upower/upower.dart';

void main() async {
  var systemBus = DBusClient.system();
  var client = UPowerClient(systemBus);
  await client.connect();
  client.propertiesChanged.listen((properties) {
    if (properties.contains('OnBattery')) {
      print('On battery: ${client.onBattery}');
    }
  });
  print('On battery: ${client.onBattery}');
}
