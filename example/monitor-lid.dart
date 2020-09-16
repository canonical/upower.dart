import 'package:dbus/dbus.dart';
import 'package:upower/upower.dart';

void main() async {
  var systemBus = DBusClient.system();
  var client = UPowerClient(systemBus);
  await client.connect();
  client.propertiesChanged.listen((properties) {
    if (properties.contains('LidIsClosed')) {
      print('Lid is closed: ${client.lidIsClosed}');
    }
  });
  print('Lid is closed: ${client.lidIsClosed}');
}
