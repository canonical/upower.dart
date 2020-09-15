[![Pub Package](https://img.shields.io/pub/v/upower.svg)](https://pub.dev/packages/upower)

Provides a client to connect to [UPower](https://upower.freedesktop.org/) - the service that does power management on Linux.

```dart
import 'package:dbus/dbus.dart';
import 'package:upower/upower.dart';

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
```
