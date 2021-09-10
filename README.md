[![Pub Package](https://img.shields.io/pub/v/upower.svg)](https://pub.dev/packages/upower)
[![codecov](https://codecov.io/gh/canonical/upower.dart/branch/main/graph/badge.svg?token=3B9G8DAWF5)](https://codecov.io/gh/canonical/upower.dart)

Provides a client to connect to [UPower](https://upower.freedesktop.org/) - the service that does power management on Linux.

```dart
import 'package:upower/upower.dart';

var client = UPowerClient();
await client.connect();
print('Running UPower ${client.daemonVersion}');
print('System state: ${client.displayDevice.state}');
print('Devices:');
for (var device in client.devices) {
  print('  ${device.type} ${device.percentage}%');
}
await client.close();
```

## Contributing to upower.dart

We welcome contributions! See the [contribution guide](CONTRIBUTING.md) for more details.
