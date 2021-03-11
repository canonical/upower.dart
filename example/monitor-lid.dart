import 'package:upower/upower.dart';

void main() async {
  var client = UPowerClient();
  await client.connect();
  client.propertiesChanged.listen((properties) {
    if (properties.contains('LidIsClosed')) {
      print('Lid is closed: ${client.lidIsClosed}');
    }
  });
  print('Lid is closed: ${client.lidIsClosed}');
}
