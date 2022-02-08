import 'package:upower/upower.dart';

void main() async {
  var client = UPowerClient();
  await client.connect();
  client.kbdBacklight.brightnessChangedWithSource.listen((change) {
    print(
        'Keyboard brightness changed to ${change.brightness} by ${change.source}');
  });
  print('Keyboard brightness is ${await client.kbdBacklight.getBrightness()}');
}
