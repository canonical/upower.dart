import 'package:upower/upower.dart';

void main(List<String> arguments) async {
  var client = UPowerClient();
  await client.connect();

  if (arguments.isNotEmpty) {
    var brightness = int.parse(arguments[0]);
    var maxBrightness = await client.kbdBacklight.getMaxBrightness();
    if (brightness >= 0 && brightness <= maxBrightness) {
      await client.kbdBacklight.setBrightness(brightness);
    } else {
      print('Brightness level must in range [0, $maxBrightness]');
    }
  } else {
    print('Missing brightness value');
  }

  await client.close();
}
